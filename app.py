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


# Set up routes
@app.route("/")
@app.route("/index")
@app.route("/index.html")
def index():
    return render_template("index.html")

# Set up api routes
@app.route("/api/v1/census")
def censusAllYears():
    # print(db.census_by_county.find())
    censusdata = dumps(db.census_by_county.find({},{'Unnamed: 0': 0, '_id': 0}))
    # print(censusdata)
    return jsonify(json.loads(censusdata))


@app.route("/api/v1/census/year/<year>")
def censusByYear(year):
    result = dumps(db.census_by_county.find({},{
        year+'IN':1, 
        year+'OUT':1, 
        year+'NET':1,
        year+'RENT':1,
        year+'MED_INC':1,
        'County': 1,
        'Lat': 1,
        'Lon': 1,
        'NAME': 1, 
        '_id':0
    }))
    return jsonify(json.loads(result))

@app.route("/api/v1/choropleth")
def choro_dict():
    result = dumps(db.choropleth_master.find({}))
    return jsonify(json.loads(result))

if __name__ == '__main__':
    app.run(debug=True)