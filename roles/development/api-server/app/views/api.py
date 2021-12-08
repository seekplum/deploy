# -*- coding: utf-8 -*-

import os
import logging

import git
from flask import request
from flask import Blueprint

from app.helpers.jsonhelper import successful_ret
from app.settings import config

logger = logging.getLogger(__name__)

api_server = Blueprint("index", __name__, url_prefix='/api')


@api_server.route("/update/blog", methods=["POST"])
def update_blog():
    # Github的webhooks是POST请求
    if os.path.exists(config.BLOG_ROOT):
        # pull
        branch = request.values.get("branch", "master")
        logger.info("pull {}, branch: {}".format(config.BLOG_ROOT, branch))
        repo = git.Repo(config.BLOG_ROOT)
        remote = repo.remote()
        remote.pull(branch)
    else:
        # env = {"GIT_SSL_NO_VERIFY": "true"}
        kwargs = dict()
        depth = request.values.get("depth", None)
        if depth:
            kwargs.update(depth=str(depth))
        branch = request.values.get("branch", "")
        if branch:
            kwargs.update(branch=branch)
        env = None
        logger.info("clone {} to {}, env:{}, kwargs: {}".format(config.BLOG_REMOTE, config.BLOG_ROOT, env, kwargs))
        # clone
        git.Repo.clone_from(config.BLOG_REMOTE, config.BLOG_ROOT, env=env, **kwargs)
    return successful_ret(msg="update github repository success!")


@api_server.route("/", methods=config.METHODS)
@api_server.route("/<path:uri>", methods=config.METHODS)
def default_route(uri="/"):
    result = {
        "method": request.method,
        "uri": uri,
        "headers": {k: v for k, v in request.headers},
        "args": request.args.to_dict(),
        "data": request.json or {},
        "form": request.form.to_dict(),
    }
    return successful_ret(result)
