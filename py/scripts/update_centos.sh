#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

# unalias cp
# alias cp='cp -i'

if [ -d /tmp/vms-main ];then
    rm -rf /tmp/vms-main
fi

if [ -f /tmp/main.zip ];then
    rm -rf /tmp/main.zip
fi

wget -O /tmp/main.zip https://codeload.github.com/midoks/m3u8-http-cache/zip/main
cd /tmp && unzip /tmp/main.zip

rm -rf /www/wwwroot/m3u8/*.pyc

pip install -r /www/wwwroot/m3u8/py/requirements.txt


/usr/bin/cp -rf  /tmp/m3u8-http-cache-main/* /www/wwwroot/m3u8

cd /www/wwwroot/m3u8/py && ./scripts/init.d/m3u8 restart
cd /www/wwwroot/m3u8/py && ./scripts/init.d/m3u8 default