#!/usr/bin/env python3

# 01_flask_api.py
#
# Flask api using flask_restful
#

#### libraries ----

import json
import flask
from flask import request, jsonify
from flask_cors import CORS # add this line to overcome "No 'Access-Control-Allow-Origin' header is present on the requested resource." issue
import psycopg2
import psycopg2.extras
from config import config
from gevent.pywsgi import WSGIServer

#### Initiation ----

app = flask.Flask(__name__)
CORS(app) # add this line to overcome "No 'Access-Control-Allow-Origin' header is present on the requested resource." issue # look into security configuraiton

#### source external @app.route from files ----

exec(open('py/get_child.py').read())
exec(open('py/get_weight.py').read())
exec(open('py/insert_weight.py').read())

#### house keeping ----

if __name__ == '__main__':
    # Debug/Development
    # app.run(debug=False, host='0.0.0.0', port='5000', threaded=True)
    # Production
    http_server = WSGIServer(('', 5000), app)
    http_server.serve_forever()
