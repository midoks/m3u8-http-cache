#!/bin/bash
# chkconfig: 2345 55 25
# description: app Cloud Service

### BEGIN INIT INFO
# Provides:          bt
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts app
# Description:       starts the app
### END INIT INFO


PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
app_path={$SERVER_PATH}


app_task_start(){
    NAME="$1"
    FILE_NAME="$1.py"
    isStart=$(ps aux |grep "${FILE_NAME}" |grep -v grep|awk '{print $2}')
    if [ "$isStart" == '' ];then
            echo -e "Starting ${NAME}... \c"
            echo "" > $app_path/logs/${NAME}.log
            cd $app_path
            nohup python -u task/${NAME}.py >> $app_path/logs/${NAME}.log 2>&1 & 
            sleep 0.1
            isStart=$(ps aux |grep "${FILE_NAME}"|grep -v grep|awk '{print $2}')
            if [ "$isStart" == '' ];then
                    echo -e "\033[31mfailed\033[0m"
                    echo '------------------------------------------------------'
                    tail -n 20 $app_path/logs/${NAME}.log
                    echo '------------------------------------------------------'
                    echo -e "\033[31mError: ${NAME} service startup failed.\033[0m"
                    return;
            fi
            echo -e "\033[32mdone\033[0m"
    else
            echo "Starting ${NAME}... ${NAME} (pid $isStart) already running"
    fi
}


app_task_f_start(){
    NAME="$1"
    FILE_NAME="$1.py"

    echo -e "Starting ${NAME}... \c"
    echo "" > $app_path/logs/${NAME}.log
    cd $app_path
    nohup python -u task/${NAME}.py >> $app_path/logs/${NAME}.log 2>&1 & 
    sleep 0.1
    isStart=$(ps aux |grep "${FILE_NAME}"|grep -v grep|awk '{print $2}')
    if [ "$isStart" == '' ];then
            echo -e "\033[31mfailed\033[0m"
            echo '------------------------------------------------------'
            tail -n 20 $app_path/logs/${NAME}.log
            echo '------------------------------------------------------'
            echo -e "\033[31mError: ${NAME} service startup failed.\033[0m"
            return;
    fi
    echo -e "\033[32mdone\033[0m"
 
}

app_task_stop()
{
    NAME="$1"
    FILE_NAME="$1.py"

    echo -e "Stopping ${NAME}... \c";
    arr=$(ps aux | grep "${NAME}" |grep -v grep|awk '{print $2}')
    for p in ${arr[@]}
    do
        kill -9 $p &>/dev/null
    done

    echo -e "\033[32mdone\033[0m"
}

app_task_status()
{
    NAME="$1"
    FILE_NAME="$1.py"

    isStart=$(ps aux |grep "${FILE_NAME}" |grep -v grep|awk '{print $2}')
    if [ "$isStart" != '' ];then
            echo "\033[32m${NAME}(pid $isStart) already running\033[0m"
    else
            echo "\033[31m${NAME} not running\033[0m"
    fi
}


app_start(){
	isStart=`ps -ef|grep 'm3u8cache:app' |grep -v grep|awk '{print $2}'`
    echo "" > $app_path/logs/error.log
	if [ "$isStart" == '' ];then
            echo -e "Starting m3u8cache... \c"
            cd $app_path && gunicorn -c setting.py m3u8cache:app
            port=$(cat ${app_path}/data/port.pl)
            isStart=""
            while [[ "$isStart" == "" ]];
            do
                echo -e ".\c"
                sleep 0.2
                isStart=$(lsof -n -P -i:$port|grep LISTEN|grep -v grep|awk '{print $2}'|xargs)
                let n+=1
                if [ $n -gt 15 ];then
                    break;
                fi
            done
            if [ "$isStart" == '' ];then
                    echo -e "\033[31mfailed\033[0m"
                    echo '------------------------------------------------------'
                    tail -n 20 ${app_path}/logs/error.log
                    echo '------------------------------------------------------'
                    echo -e "\033[31mError: m3u8cache service startup failed.\033[0m"
                    return;
            fi
            echo -e "\033[32mdone\033[0m"
    else
            echo "Starting m3u8cache... app(pid $(echo $isStart)) already running"
    fi
}



app_stop()
{

    echo -e "Stopping m3u8cache... \c";
    arr=`ps aux|grep 'm3u8cache:app'|grep -v grep|awk '{print $2}'`
	for p in ${arr[@]}
    do
            kill -9 $p
    done
    
    if [ -f $pidfile ];then
    	rm -f $pidfile
    fi
    echo -e "\033[32mdone\033[0m"
}

app_status()
{
        isStart=$(ps aux|grep 'gunicorn -c setting.py m3u8cache:app'|grep -v grep|awk '{print $2}')
        if [ "$isStart" != '' ];then
                echo -e "\033[32mm3u8cache (pid $(echo $isStart)) already running\033[0m"
        else
                echo -e "\033[31mm3u8cache not running\033[0m"
        fi
}


app_reload()
{
	isStart=$(ps aux|grep 'm3u8cache:app'|grep -v grep|awk '{print $2}')
    
    if [ "$isStart" != '' ];then
    	echo -e "Reload m3u8cache... \c";
	    arr=`ps aux|grep 'm3u8cache:app'|grep -v grep|awk '{print $2}'`
		for p in ${arr[@]}
        do
                kill -9 $p
        done
        cd $app_path && gunicorn -c setting.py m3u8cache:app
        isStart=`ps aux|grep 'm3u8cache:app'|grep -v grep|awk '{print $2}'`
        if [ "$isStart" == '' ];then
                echo -e "\033[31mfailed\033[0m"
                echo '------------------------------------------------------'
                tail -n 20 $app_path/logs/error.log
                echo '------------------------------------------------------'
                echo -e "\033[31mError: m3u8cache service startup failed.\033[0m"
                return;
        fi
        echo -e "\033[32mdone\033[0m"
    else
        echo -e "\033[31mvms not running\033[0m"
        mw_start
    fi
}


error_logs()
{
	tail -n 100 $app_path/logs/error.log
}

case "$1" in
    'start') app_start;;
    'stop') app_stop;;
    'reload') app_reload;;
    'restart') 
        app_stop
        sleep 2
        app_start;;
    'status') app_status;;
    'logs') error_logs;;
    'default')
        cd $app_path
        port=$(cat $app_path/data/port.pl)
        password=$(cat $app_path/data/default.pl)
        if [ -f $app_path/data/domain.conf ];then
            address=$(cat $app_path/data/domain.conf)
        fi
        if [ -f $app_path/data/admin_path.pl ];then
            auth_path=$(cat $app_path/data/admin_path.pl)
        fi

        if [ "$address" = "" ];then
            address=$(curl -sS --connect-timeout 10 -m 60 https://www.bt.cn/Api/getIpAddress)
        fi

        echo -e "=================================================================="
        echo -e "\033[32mVMS default info!\033[0m"
        echo -e "=================================================================="
        echo  "app-URL: http://$address:$port$auth_path"
        echo -e "=================================================================="
        echo -e "username: admin"
        echo -e "password: $password"
        ;;
esac