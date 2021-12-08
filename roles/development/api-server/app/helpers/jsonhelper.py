# -*- coding: utf-8 -*-

import json
import logging
import datetime

from flask import Response

logger = logging.getLogger(__name__)


class JsonEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, (datetime.datetime, datetime.date)):
            return obj.strftime("%Y-%m-%d %H:%M:%S")
        try:
            r = json.JSONEncoder.default(self, obj)
            return r
        except TypeError:
            return str(obj)


def jsonify_ret(*args, **kwargs):
    """jsonify with support for MongoDB ObjectId
    """
    response = json.dumps(dict(*args, **kwargs), cls=JsonEncoder)
    return Response(response, mimetype='application/json')


def successful_ret(data=None, msg=None, code=0):
    """success response
    """
    msg = msg or ""
    data = data or {}
    return jsonify_ret(success=True, code=code, data=data, msg=msg)


def failure_ret(code=-1, msg=None):
    """failure response
    """
    msg = msg or ""
    return jsonify_ret(success=False, code=code, msg=msg)
