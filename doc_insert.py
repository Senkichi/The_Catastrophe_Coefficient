
from flask import Flask, render_template, jsonify
from flask_pymongo import PyMongo
from urllib.parse import quote_plus
import pymongo
import json
from bson.json_util import dumps
from flask_cors import CORS

app = Flask(__name__,template_folder='static/templates')


#allow cross origin script access so can access via js
CORS(app)

mongo = PyMongo(app, uri="mongodb://root:ucbmongodb@35.184.4.63:27017/ACS")
conn = 'mongodb://root:ucbmongodb@35.184.4.63:27017'
client = pymongo.MongoClient(conn)
db = client.ACS

