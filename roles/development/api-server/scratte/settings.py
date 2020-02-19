# -*- coding: utf-8 -*-

import os


class FlaskConfig(object):
    SECRET_KEY = "meizhe_proxy"
    SESSION_TYPE = "filesystem"
    DEBUG = True


class LocalConfig(FlaskConfig):
    METHODS = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD"]
    BLOG_REMOTE = os.environ.get("BLOG_REMOTE", "https://github.com/seekplum/seekplum.github.io.git")
    BLOG_ROOT = os.environ.get("BLOG_ROOT", "/tmp/seekplum.github.io")
    SERVER_HOST = os.environ.get("SERVER_HOST", "0.0.0.0")
    SERVER_PORT = os.environ.get("SERVER_PORT", 8099)
    LOG_REQUEST = os.environ.get("LOG_REQUEST", "no").lower() == "yes"

    LOGGING_INI = "logging_debug.ini"


config = LocalConfig()
