#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin:/usr/local/lib/python2.7/bin



mvg_start(){
	gunicorn -c setting.py m3u8cache:app
}


mvg_start_debug(){
	# python vms_task.py &
	gunicorn -b :9000 -k gevent -w 1 m3u8cache:app
}

mvg_task_stop(){
	NAME="$1"
    FILE_NAME="$1.py"
	TLIST=`ps -ef|grep "$FILE_NAME" |grep -v grep|awk '{print $2}'`
	for i in $TLIST
	do
	    kill -9 $i
	done
}

mvg_stop()
{
	PLIST=`ps -ef|grep m3u8cache:app |grep -v grep|awk '{print $2}'`
	for i in $PLIST
	do
	    kill -9 $i
	done
}

case "$1" in
    'start') mvg_start;;
    'stop') mvg_stop;;
    'restart') 
		mvg_stop 
		mvg_start
		;;
	'debug')
		mvg_stop 
		mvg_start_debug
		;;
esac