
//var url = "./api/v1/census"

var url = "../data/beta_frame.json"


var map = L.map("map", {
    center: [
      36.7783, -119.4179
    ],
    zoom: 6,
  });



L.tileLayer("https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token={accessToken}", {
  attribution: "Map data &copy; <a href=\"https://www.openstreetmap.org/\">OpenStreetMap</a> contributors, <a href=\"https://creativecommons.org/licenses/by-sa/2.0/\">CC-BY-SA</a>, Imagery © <a href=\"https://www.mapbox.com/\">Mapbox</a>",
  maxZoom: 18,
  id: "mapbox.streets-basic",
  accessToken: API_KEY
}).addTo(map);

var group1 = L.featureGroup();
var	yearSelect = d3.select("#year").node().value;
var	typeSelect = d3.select("#dataType").node().value;
var geojson

//initial draw
d3.json(url, function(data) {
  // Once we get a response, send the data.features object to the createFeatures function

	createFeatures(data);
})

// Perform a GET request to the query URL



function createFeatures(sourceData) {

var unshelled = sourceData[0]
var selectConcat = String(yearSelect.concat(typeSelect))


geojson = L.choropleth(unshelled, {

  // Define what  property in the features to use
  valueProperty: selectConcat,

  // Set color scale
  scale: ["#ffffb2", "#b10026"],

  // Number of breaks in step range
  steps: 10,

  // q for quartile, e for equidistant, k for k-means
  mode: "q",
  style: {
    // Border color
    color: "#fff",
    weight: 1,
    fillOpacity: 0.8
  }
}).addTo(map)
}


d3.json(url, function(data) {
  // Once we get a response, send the data.features object to the createFeatures function

 d3.select("#year").on("change",function(){

	yearSelect = d3.select("#year").node().value;
	console.log(yearSelect);
	group1.clearLayers()
	createFeatures(data);

	})
})

d3.json(url, function(data) {
  // Once we get a response, send the data.features object to the createFeatures function


 d3.select("#dataType").on("change",function(){

	typeSelect = d3.select("#dataType").node().value;;
	console.log(typeSelect)
	group1.clearLayers()
	createFeatures(data);

	})
})
