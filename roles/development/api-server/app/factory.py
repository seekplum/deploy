# -*- coding: utf-8 -*-

import importlib
import pkgutil
import logging
import json
import time
import logging.config
import uuid

from datetime import datetime

from flask import Flask, Blueprint
from flask import g, request
from simplejson.errors import JSONDecodeError

from app.settings import config
from app.helpers.jsonhelper import failure_ret

APP_NAME = 'app'
PACKAGE_NAME = APP_NAME
PACKAGE_PATH = APP_NAME

logger = logging.getLogger(__name__)


def configure_logging():
    logging.config.fileConfig(config.LOGGING_INI)
    return


def configure_error_handlers(app):
    @app.errorhandler(401)
    def unauthorized(error):
        return failure_ret(msg="登录已过期，请重新登录!", code=-401)

    @app.errorhandler(403)
    def forbidden(error):
        return failure_ret(msg=str(error), code=403)

    @app.errorhandler(404)
    def page_not_found(error):
        return failure_ret(msg="{} not found".format(request.url),
                           code=404)

    @app.errorhandler(JSONDecodeError)
    def json_error(error):
        return failure_ret(code=502, msg=str(error)), 200

    @app.errorhandler(Exception)
    def all_error(error):
        return failure_ret(code=500, msg=str(error)), 200


def configure_before_handlers(app):
    @app.before_request
    def before_all_requests():
        g.ts = int(time.time() * 1000)
        g.now = datetime.now()
        # 生成唯一ID 关联请求参数和调用结果
        g.request_id = uuid.uuid4().hex
        if config.LOG_REQUEST:
            logger.info("request_id: {}, path: {}, method: {}, headers: {}, args: {}, data: {}, form: {}".format(
                g.request_id,
                request.path,
                request.method,
                # 处理参数中的中文打印乱码情况
                json.dumps({k: v for k, v in request.headers}, ensure_ascii=False),
                json.dumps(request.args.to_dict(), ensure_ascii=False),
                json.dumps(request.json or {}, ensure_ascii=False),
                json.dumps(request.form.to_dict(), ensure_ascii=False),
            ))

    @app.after_request
    def after_request_callback(resp):
        if config.LOG_REQUEST:
            logger.info("request_id: {}, response: {}".format(
                g.request_id, json.dumps(resp.json or {}, ensure_ascii=False)))
        handle_time = int(time.time() * 1000) - g.ts
        resp.headers['_t'] = str(handle_time)
        return resp


def configure_context_processors(app):
    @app.context_processor
    def load_config():
        return dict(config=app.config)


def configure_template_filters(app):
    # 全局设置, 使 truncate 与老版本行为相同
    app.jinja_env.policies['truncate.leeway'] = 0

    @app.template_filter()
    def remove_trailing_zeros(value):
        return ('%f' % value).rstrip('0').rstrip('.')


def register_blueprints(app, package_name, package_path):
    rv = []
    for _, name, _ in pkgutil.iter_modules(package_path):
        m = importlib.import_module('%s.%s' % (package_name, name))
        for item in dir(m):
            item = getattr(m, item)
            # 需要在 __init__.py 中导入
            if isinstance(item, Blueprint):
                app.register_blueprint(item)
                logging.debug("BluePrint [%s] Registered", item.name)
            rv.append(item)
    return rv


def create_app(config_=None):
    app = Flask(APP_NAME)
    # config
    app.config.from_object(config_)
    configure_logging()

    configure_error_handlers(app)
    configure_before_handlers(app)
    configure_template_filters(app)
    configure_context_processors(app)
    # register module
    register_blueprints(app, PACKAGE_NAME, [PACKAGE_PATH])
    return app
