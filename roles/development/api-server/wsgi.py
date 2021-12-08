# -*- coding: utf-8 -*-


from app.factory import create_app
from app.settings import config

app = create_app(config)

if __name__ == '__main__':
    app.run(host=config.SERVER_HOST, port=config.SERVER_PORT, threaded=True)
