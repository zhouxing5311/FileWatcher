#import "HTTPFileResponse.h"
#import "HTTPConnection.h"

#import <unistd.h>
#import <fcntl.h>

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

// Log levels : off, error, warn, info, verbose
// Other flags: trace

#define NULL_FD  -1


@implementation HTTPFileResponse

- (id)initWithFilePath:(NSString *)fpath forConnection:(HTTPConnection *)parent
{
	if((self = [super init]))
	{
		
		connection = parent; // Parents retain children, children do NOT retain parents
		
		fileFD = NULL_FD;
		filePath = [[fpath copy] stringByResolvingSymlinksInPath];
		if (filePath == nil)
		{
			
			return nil;
		}
		
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
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

- (BOOL)openFile
{
	
	fileFD = open([filePath UTF8String], O_RDONLY);
	if (fileFD == NULL_FD)
	{
		
		[self abort];
		return NO;
	}
	
	
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
	
	return [self openFile];
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
	
	off_t result = lseek(fileFD, (off_t)offset, SEEK_SET);
	if (result == -1)
	{
		
		[self abort];
	}
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
	
	if (![self openFileIfNeeded])
	{
		// File opening failed,
		// or response has been aborted due to another error.
		return nil;
	}
	
	// Determine how much data we should read.
	// 
	// It is OK if we ask to read more bytes than exist in the file.
	// It is NOT OK to over-allocate the buffer.
	
	UInt64 bytesLeftInFile = fileLength - fileOffset;
	
	NSUInteger bytesToRead = (NSUInteger)MIN(length, bytesLeftInFile);
	
	// Make sure buffer is big enough for read request.
	// Do not over-allocate.
	
	if (buffer == NULL || bufferSize < bytesToRead)
	{
		bufferSize = bytesToRead;
		buffer = reallocf(buffer, (size_t)bufferSize);
		
		if (buffer == NULL)
		{
			
			[self abort];
			return nil;
		}
	}
	
	// Perform the read
	
	
	ssize_t result = read(fileFD, buffer, bytesToRead);
	
	// Check the results
	
	if (result < 0)
	{
		
		[self abort];
		return nil;
	}
	else if (result == 0)
	{
		
		[self abort];
		return nil;
	}
	else // (result > 0)
	{
		
		fileOffset += result;
		
		return [NSData dataWithBytes:buffer length:result];
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

- (void)dealloc
{
	
	if (fileFD != NULL_FD)
	{
		
		close(fileFD);
	}
	
	if (buffer)
		free(buffer);
	
}

@end
