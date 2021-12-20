FROM ruby:2.7.0-slim
LABEL maintainer="seekplum <1131909224m@sina.cn>"

RUN set -xe && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone && \
    sed -i -E -e 's/(deb|security).debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y make gcc g++ && \
    apt-get clean && \
    apt-get autoclean && \
    gem install \
    jekyll-paginate:1.1.0 \
    jekyll-sass-converter:2.0.1 \
    jekyll-watch:2.2.1 \
    jekyll:4.0.0 \
    rouge:3.13.0 && \
    rm -rf /usr/local/lib/ruby/gems/*/cache && \
    rm -rf /usr/local/bundle/cache

WORKDIR /opt/blog
CMD ["/bin/bash", "-c", "env && jekyll serve --trace --host=0.0.0.0 --destination _site --port 4000"]
