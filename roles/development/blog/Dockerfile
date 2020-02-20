FROM ruby:2.6.3
MAINTAINER seekplum <1131909224m@sina.cn>

RUN gem install \
    jekyll-paginate:1.1.0 \
    jekyll-sass-converter:2.0.1 \
    jekyll-watch:2.2.1 \
    jekyll:4.0.0 \
    rouge:3.13.0

WORKDIR /opt/blog
CMD ["/bin/bash", "-c", "env && jekyll serve --trace --host=0.0.0.0 --destination _site --port 4000"]
