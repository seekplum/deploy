# -*- coding: utf-8 -*-


from scratte.factory import create_app
from scratte.settings import config

app = create_app(config)

if __name__ == '__main__':
    app.run(host=config.SERVER_HOST, port=config.SERVER_PORT, threaded=True)
