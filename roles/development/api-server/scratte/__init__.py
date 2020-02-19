# -*- coding: utf-8 -*-

import six

if six.PY2:
    import sys

    reload(sys)
    sys.setdefaultencoding("utf8")
