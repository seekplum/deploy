FROM python:3.7-slim

MAINTAINER seekplum <1131909224m@sina.cn>

ADD requirements/requirements.txt /tmp/requirements.txt
RUN set -xe \
    && apt-get update \
    && apt-get install -y git \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone \
    && pip install -r /tmp/requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple \
    && rm -f /tmp/requirements.txt
# 1024 * 1024 * 1024 * 50
RUN git config --global http.postBuffer 53687091200
RUN git config --global --add core.compression -1
RUN git config --global user.email 1131909224@qq.com
RUN git config --global user.name seekplum
ADD . /code
WORKDIR /code
CMD ["/bin/bash", "-c", "env && gunicorn -w 2 -t 60 -b :${SERVER_PORT} --log-level debug -k gevent wsgi:app"]
