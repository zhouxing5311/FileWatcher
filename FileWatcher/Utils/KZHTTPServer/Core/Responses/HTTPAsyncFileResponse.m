#import "HTTPAsyncFileResponse.h"
#import "HTTPConnection.h"

#import <unistd.h>
#import <fcntl.h>

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

// Log levels : off, error, warn, info, verbose
// Other flags: trace

#define NULL_FD  -1

/**
 * Architecure overview:
 * 
 * HTTPConnection will invoke our readDataOfLength: method to fetch data.
 * We will return nil, and then proceed to read the data via our readSource on our readQueue.
 * Once the requested amount of data has been read, we then pause our readSource,
 * and inform the connection of the available data.
 * 
 * While our read is in progress, we don't have to worry about the connection calling any other methods,
 * except the connectionDidClose method, which would be invoked if the remote end closed the socket connection.
 * To safely handle this, we do a synchronous dispatch on the readQueue,
 * and nilify the connection as well as cancel our readSource.
 * 
 * In order to minimize resource consumption during a HEAD request,
 * we don't open the file until we have to (until the connection starts requesting data).
**/

@implementation HTTPAsyncFileResponse

- (id)initWithFilePath:(NSString *)fpath forConnection:(HTTPConnection *)parent
{
	if ((self = [super init]))
	{
		
		connection = parent; // Parents retain children, children do NOT retain parents
		
		fileFD = NULL_FD;
		filePath = [fpath copy];
		if (filePath == nil)
		{
			
			return nil;
		}
		
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL];
		if (fileAttributes == nil)
		{
			
			return nil;
		}
		
		fileLength = (UInt64)[[fileAttributes objectForKey:NSFileSize] unsignedLongLongValue];
		fileOffset = 0;
		
		aborted = NO;
		
		// We don't bother opening the file here.
		// If this is a HEAD request we only need to know the fileLength.
	}
	return self;
}

- (void)abort
{
	
	[connection responseDidAbort:self];
	aborted = YES;
}

- (void)processReadBuffer
{
	// This method is here to allow superclasses to perform post-processing of the data.
	// For an example, see the HTTPDynamicFileResponse class.
	// 
	// At this point, the readBuffer has readBufferOffset bytes available.
	// This method is in charge of updating the readBufferOffset.
	// Failure to do so will cause the readBuffer to grow to fileLength. (Imagine a 1 GB file...)
	
	// Copy the data out of the temporary readBuffer.
	data = [[NSData alloc] initWithBytes:readBuffer length:readBufferOffset];
	
	// Reset the read buffer.
	readBufferOffset = 0;
	
	// Notify the connection that we have data available for it.
	[connection responseHasAvailableData:self];
}

- (void)pauseReadSource
{
	if (!readSourceSuspended)
	{
		
		readSourceSuspended = YES;
		dispatch_suspend(readSource);
	}
}

- (void)resumeReadSource
{
	if (readSourceSuspended)
	{
		
		readSourceSuspended = NO;
		dispatch_resume(readSource);
	}
}

- (void)cancelReadSource
{
	
	dispatch_source_cancel(readSource);
	
	// Cancelling a dispatch source doesn't
	// invoke the cancel handler if the dispatch source is paused.
	
	if (readSourceSuspended)
	{
		readSourceSuspended = NO;
		dispatch_resume(readSource);
	}
}

- (BOOL)openFileAndSetupReadSource
{
	
	fileFD = open([filePath UTF8String], (O_RDONLY | O_NONBLOCK));
	if (fileFD == NULL_FD)
	{
		
		return NO;
	}
	
	
	readQueue = dispatch_queue_create("HTTPAsyncFileResponse", NULL);
	readSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, fileFD, 0, readQueue);
	
	
	dispatch_source_set_event_handler(readSource, ^{
		
		
		// Determine how much data we should read.
		// 
		// It is OK if we ask to read more bytes than exist in the file.
		// It is NOT OK to over-allocate the buffer.
		
        unsigned long long _bytesAvailableOnFD = dispatch_source_get_data(self->readSource);
		
        UInt64 _bytesLeftInFile = self->fileLength - self->readOffset;
		
		NSUInteger bytesAvailableOnFD;
		NSUInteger bytesLeftInFile;
		
		bytesAvailableOnFD = (_bytesAvailableOnFD > NSUIntegerMax) ? NSUIntegerMax : (NSUInteger)_bytesAvailableOnFD;
		bytesLeftInFile    = (_bytesLeftInFile    > NSUIntegerMax) ? NSUIntegerMax : (NSUInteger)_bytesLeftInFile;
		
        NSUInteger bytesLeftInRequest = self->readRequestLength - self->readBufferOffset;
		
		NSUInteger bytesLeft = MIN(bytesLeftInRequest, bytesLeftInFile);
		
		NSUInteger bytesToRead = MIN(bytesAvailableOnFD, bytesLeft);
		
		// Make sure buffer is big enough for read request.
		// Do not over-allocate.
		
        if (self->readBuffer == NULL || bytesToRead > (self->readBufferSize - self->readBufferOffset))
		{
            self->readBufferSize = bytesToRead;
			self->readBuffer = reallocf(self->readBuffer, (size_t)bytesToRead);
			
			if (self->readBuffer == NULL)
			{
				
				[self pauseReadSource];
				[self abort];
				
				return;
			}
		}
		
		// Perform the read
		
		
		ssize_t result = read(self->fileFD, self->readBuffer + self->readBufferOffset, (size_t)bytesToRead);
		
		// Check the results
		if (result < 0)
		{
			
			[self pauseReadSource];
			[self abort];
		}
		else if (result == 0)
		{
			
			[self pauseReadSource];
			[self abort];
		}
		else // (result > 0)
		{
			
			self->readOffset += result;
			self->readBufferOffset += result;
			
			[self pauseReadSource];
			[self processReadBuffer];
		}
		
	});
	
	int theFileFD = fileFD;
	#if !OS_OBJECT_USE_OBJC
	dispatch_source_t theReadSource = readSource;
	#endif
	
	dispatch_source_set_cancel_handler(readSource, ^{
		
		// Do not access self from within this block in any way, shape or form.
		// 
		// Note: You access self if you reference an iVar.
		
		
		#if !OS_OBJECT_USE_OBJC
		dispatch_release(theReadSource);
		#endif
		close(theFileFD);
	});
	
	readSourceSuspended = YES;
	
	return YES;
}

- (BOOL)openFileIfNeeded
{
	if (aborted)
	{
		// The file operation has been aborted.
		// This could be because we failed to open the file,
		// or the reading process failed.
		return NO;
	}
	
	if (fileFD != NULL_FD)
	{
		// File has already been opened.
		return YES;
	}
	
	return [self openFileAndSetupReadSource];
}	

- (UInt64)contentLength
{
	
	return fileLength;
}

- (UInt64)offset
{
	
	return fileOffset;
}

- (void)setOffset:(UInt64)offset
{
	
	if (![self openFileIfNeeded])
	{
		// File opening failed,
		// or response has been aborted due to another error.
		return;
	}
	
	fileOffset = offset;
	readOffset = offset;
	
	off_t result = lseek(fileFD, (off_t)offset, SEEK_SET);
	if (result == -1)
	{
		
		[self abort];
	}
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
	
	if (data)
	{
		NSUInteger dataLength = [data length];
		
		
		fileOffset += dataLength;
		
		NSData *result = data;
		data = nil;
		
		return result;
	}
	else
	{
		if (![self openFileIfNeeded])
		{
			// File opening failed,
			// or response has been aborted due to another error.
			return nil;
		}
		
		dispatch_sync(readQueue, ^{
			
			NSAssert(self->readSourceSuspended, @"Invalid logic - perhaps HTTPConnection has changed.");
			
			self->readRequestLength = length;
			[self resumeReadSource];
		});
		
		return nil;
	}
}

- (BOOL)isDone
{
	BOOL result = (fileOffset == fileLength);
	
	
	return result;
}

- (NSString *)filePath
{
	return filePath;
}

- (BOOL)isAsynchronous
{
	
	return YES;
}

- (void)connectionDidClose
{
	
	if (fileFD != NULL_FD)
	{
		dispatch_sync(readQueue, ^{
			
			// Prevent any further calls to the connection
			self->connection = nil;
			
			// Cancel the readSource.
			// We do this here because the readSource's eventBlock has retained self.
			// In other words, if we don't cancel the readSource, we will never get deallocated.
			
			[self cancelReadSource];
		});
	}
}

- (void)dealloc
{
	
	#if !OS_OBJECT_USE_OBJC
	if (readQueue) dispatch_release(readQueue);
	#endif
	
	if (readBuffer)
		free(readBuffer);
}

@end
