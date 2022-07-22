#!/bin/sh
function kill_process() {
    tmp=`ps -ef | grep $1 | grep -v grep | awk '{print $2}'`
    echo ${tmp}
    for id in $tmp
    do
    kill -9 $id
    echo "killed $id"
    done
}

# 关闭上次Python服务
kill_process Python
# 开启Python服务
python -m SimpleHTTPServer 8000
