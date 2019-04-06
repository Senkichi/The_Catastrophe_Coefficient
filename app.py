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

mongo = PyMongo(app, uri="mongodb://root:ucbmongodb@35.184.4.63:27017/weather")
conn = 'mongodb://root:ucbmongodb@35.184.4.63:27017'
client = pymongo.MongoClient(conn)
db = client.weather


# Set up routes
@app.route("/")
@app.route("/index")
@app.route("/index.html")
def index():
    return render_template("index.html")

@app.route("/2050h")
@app.route('/2050h.html')
def harsh_2050():
	return render_template("2050h.html")

@app.route("/2070m")
@app.route('/2070m.html')
def harsh_2070():
	return render_template("2070m.html")

# Set up api routes
@app.route("/api/v1/<year>/<severity>/<algorithm>")
def firePrediction(year,severity,algorithm):
    print("reached the API")
    collection_name = severity + '_' +algorithm + '_' + year
    predictionData = dumps(db[collection_name].find({},{'_id': 0,'x':1,'y':1,'prediction':1}))
    print(predictionData)
    return jsonify(json.loads(predictionData))


if __name__ == '__main__':
    app.run(debug=True)