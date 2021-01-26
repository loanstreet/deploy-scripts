#!/usr/bin/env python
#
# Runs a Tornado web server with a django project
# Make sure to edit the DJANGO_SETTINGS_MODULE to point to your settings.py
#
# http://localhost:8080/hello-tornado
# http://localhost:8080

from __future__ import absolute_import, division, print_function, unicode_literals

import sys
import os
import asyncio

import tornado.httpserver
import tornado.ioloop
import tornado.web
import tornado.wsgi
from tornado.options import options, define, parse_command_line
from tornado.platform.asyncio import AsyncIOMainLoop

from django.core.wsgi import get_wsgi_application


define('port', type=int, default=8001)


def main():
    sys.path.append('django_project')  # path to your project if needed
    os.environ['DJANGO_SETTINGS_MODULE'] = 'django_project.settings'

    parse_command_line()

    wsgi_app = get_wsgi_application()
    container = tornado.wsgi.WSGIContainer(wsgi_app)
    tornado_app = tornado.web.Application([
        ('.*', tornado.web.FallbackHandler, dict(fallback=container)),
    ])

    tornado_app = tornado.web.Application([
        ('.*', tornado.web.FallbackHandler, dict(fallback=container)),
    ])

    server = tornado.httpserver.HTTPServer(tornado_app)
    server.listen(options.port)

    tornado.ioloop.IOLoop.instance().start()

    AsyncIOMainLoop().install()
    asyncio.get_event_loop().run_forever()


if __name__ == '__main__':
    main()
