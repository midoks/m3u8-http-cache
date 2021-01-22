# coding:utf-8

import sys
import io
import os
import time
import shutil
import uuid
import m3u8

# from urllib.parse import urljoin

reload(sys)
sys.setdefaultencoding('utf-8')


from datetime import timedelta

from flask import Flask
from flask import render_template
from flask import make_response
from flask import Response
from flask import session
from flask import request
from flask import redirect
from flask import url_for
from flask_caching import Cache
from flask_session import Session

sys.path.append(os.getcwd() + "/class/core")
sys.path.append(os.getcwd() + "/class/ctr")
sys.path.append("/usr/local/lib/python2.7/site-packages")

import requests
from threading import Thread

import common

app = Flask(__name__, template_folder='templates/default')
# app.config['UPLOAD_FOLDER'] = '/Users/midoks/go/src/github.com/midoks/vms/tmp'
# app.config.version = config_api.config_api().getVersion()
# app.config['SECRET_KEY'] = os.urandom(24)
# app.secret_key = uuid.UUID(int=uuid.getnode()).hex[-12:]
app.config['SECRET_KEY'] = uuid.UUID(int=uuid.getnode()).hex[-12:]
app.config['PERMANENT_SESSION_LIFETIME'] = timedelta(days=31)
cache = Cache(config={'CACHE_TYPE': 'simple'})
cache.init_app(app, config={'CACHE_TYPE': 'simple'})


# socketio
from flask_socketio import SocketIO, emit, send
socketio = SocketIO()
socketio.init_app(app)


common.init()


# 取数据对象
def get_input_data(data):
    pdata = common.dict_obj()
    for key in data.keys():
        pdata[key] = str(data[key])
    return pdata


def funConvert(fun):
    block = fun.split('_')
    func = block[0]
    for x in range(len(block) - 1):
        suf = block[x + 1].title()
        func += suf
    return func


def publicObject(toObject, func, action=None, get=None):
    name = funConvert(func) + 'Api'
    try:
        if hasattr(toObject, name):
            efunc = 'toObject.' + name + '()'
            data = eval(efunc)
            return data
    except Exception as e:
        data = {'code': -1, 'msg': '访问异常:' + str(e) + '!', "status": False}
        return common.getJson(data)


@app.before_request
def before_request():
    pass


@app.after_request
def apply_caching(response):
    response.headers[
        "project_url"] = "https://github.com/midoks/m3u8-http-cache"
    return response


# from flask_cors import CORS
# CORS(app, resources=r'/cache/*')

import urlparse


def get_ts_url(url):
    m3u8_obj = m3u8.loads(url)
    base_uri = m3u8_obj.base_uri
    v = []
    for seg in m3u8_obj.segments:
        v.append(seg.uri)
    return v


def async(f):
    def wrapper(*args, **kwargs):
        thr = Thread(target=f, args=args, kwargs=kwargs)
        thr.start()
    return wrapper


def download2(url, file_path):
    # 第一次请求是为了得到文件总大小
    r1 = request.get(url, stream=True, verify=False)
    total_size = int(r1.headers['Content-Length'])

    # 这重要了，先看看本地文件下载了多少
    if os.path.exists(file_path):
        temp_size = os.path.getsize(file_path)  # 本地已经下载的文件大小
    else:
        temp_size = 0
    # 显示一下下载了多少
    print(temp_size)
    print(total_size)
    # 核心部分，这个是请求下载时，从本地文件已经下载过的后面下载
    headers = {'Range': 'bytes=%d-' % temp_size}
    # 重新请求网址，加入新的请求头的
    r = requests.get(url, stream=True, verify=False, headers=headers)

    # 下面写入文件也要注意，看到"ab"了吗？
    # "ab"表示追加形式写入文件
    with open(file_path, "ab") as f:
        for chunk in r.iter_content(chunk_size=1024):
            if chunk:
                temp_size += len(chunk)
                f.write(chunk)
                f.flush()

                ###这是下载实现进度显示####
                done = int(50 * temp_size / total_size)
                sys.stdout.write("\r[%s%s] %d%%" % (
                    '█' * done, ' ' * (50 - done), 100 * temp_size / total_size))
                sys.stdout.flush()
    print()  # 避免上面\r 回车符


@async
def donwload(url, path):
    if not os.path.exists(path):
        c = common.httpGet(url)
        common.writeFile(path, c)
    else:

        if os.path.getsize(path) < 1024:
            print(path, os.path.getsize(path))
            c = common.httpGet(url)
            common.writeFile(path, c)


@app.route('/', methods=['GET'])
def index(path=None, format=None, filename=None):
    return 'hello world'


@app.route('/cache', methods=['GET'])
def cache(path=None, format=None, filename=None):

    url = request.args.get('url', '').encode('utf-8')
    parsed_tuple = urlparse.urlparse(url)

    path_dir = 'cache/' + parsed_tuple.netloc + \
        os.path.dirname(parsed_tuple.path)
    common.mkdir_p(path_dir)

    filepath, tmpfilename = os.path.split(url)
    shotname, extension = os.path.splitext(tmpfilename)

    filename = path_dir + '/' + tmpfilename
    # print(filepath, tmpfilename, shotname, extension)
    # print(filename)
    if os.path.exists(filename):
        # print()
        if os.path.getsize(filename) < 1024:
            print(filename, os.path.getsize(filename))
            c = common.httpGet(url)
            common.writeFile(path, c)

        c = common.readFile(filename)
    else:
        c = common.httpGet(url)
        common.writeFile(filename, c)

    if extension == '.m3u8':
        ts_urls = get_ts_url(c)
        for index, ts_url in enumerate(ts_urls):
            fpath = path_dir + '/' + ts_url
            furl = filepath + '/' + ts_url
            donwload(furl, fpath)
    return c
