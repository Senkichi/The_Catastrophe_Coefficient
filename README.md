# Fire Prediction Project Summary

Using Worldclim climate data and historical fire data from Data.gov, we used 4 different algorithms to predict the likliehood of future fires. Our models were trained using historical climatic data, which were then applied to Worldclim predictive datasets (2040, 2070) with 2 levels of climate change severity (driven by future air pollution levels).

Heroku: https://ucbx-fire-prediction-2019.herokuapp.com/

## Extraction, Transform

- In R we extracted climate change data from:

https://catalog.data.gov/dataset/combined-wildfire-dataset-for-the-united-states-and-certain-territories-1870-2015

http://www.worldclim.org/version1

- Exported as CSV and read into python and loaded into Pandas DataFrames for the creation of our models

## Machine Learning

Four Prediction Models: 
1. Neural Network
2. Random Forest
3. KNN
4. Logistic Regression 

## Load

- Loaded our dataframe into MongoDB with PyMongo
- Hosted MongoDB in external server

## Flask App

- Created our flask app using Flask-PyMongo

## Web Template

- Used Flask’s {% %} notation to extend a layout.html file, to keep consistent navbar

## Charting

- Leaflet map with Patrick Wied's heatmap plugin showing relative fire likliehood with options to adjust the year, degree of climate change, heatmap sensitivity, and algorithm used
- Collection of charts created using Tableau 
