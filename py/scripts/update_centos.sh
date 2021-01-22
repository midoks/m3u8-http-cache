#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

# unalias cp
# alias cp='cp -i'

if [ -d /tmp/m3u8-http-cache-master ];then
    rm -rf /tmp/m3u8-http-cache-master
fi

if [ -f /tmp/master.zip ];then
    rm -rf /tmp/master.zip
fi

wget -O /tmp/master.zip https://codeload.github.com/midoks/m3u8-http-cache/zip/master
cd /tmp && unzip /tmp/master.zip

rm -rf /www/wwwroot/m3u8/*.pyc

pip install -r /www/wwwroot/m3u8/py/requirements.txt


/usr/bin/cp -rf  /tmp/m3u8-http-cache-master/* /www/wwwroot/m3u8

cd /www/wwwroot/m3u8/py && ./scripts/init.d/m3u8 restart
cd /www/wwwroot/m3u8/py && ./scripts/init.d/m3u8 default