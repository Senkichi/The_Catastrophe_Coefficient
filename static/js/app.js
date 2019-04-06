
var	year = d3.select("#year").node().value;
var	model = d3.select("#model").node().value;
var	algorithm = d3.select("#algorithm").node().value;

var url = "./static/data/dummy_data.json"

//var url = `api/v1.0/${year}/${model}/${algorithm}`

var baseLayer = L.tileLayer("https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token={accessToken}", {
  attribution: "Map data &copy; <a href=\"https://www.openstreetmap.org/\">OpenStreetMap</a> contributors, <a href=\"https://creativecommons.org/licenses/by-sa/2.0/\">CC-BY-SA</a>, Imagery © <a href=\"https://www.mapbox.com/\">Mapbox</a>",
  maxZoom: 18,
  id: "mapbox.streets-basic",
  accessToken: API_KEY
});




d3.json(url, function(data) {
  // Once we get a response, send the data.features object to the createFeatures function
	createFeatures({max: 200,min: 0,data});
})

function createFeatures(sourceData) {


  // Add circles to map
var cfg = {
  // radius should be small ONLY if scaleRadius is true (or small radius is intended)
  // if scaleRadius is false it will be the constant radius used in pixels
  "radius": 0.1,
  "maxOpacity": .8, 
  // scales the radius based on map zoom
  "scaleRadius": true, 
  // if set to false the heatmap uses the global maximum for colorization
  // if activated: uses the data maximum within the current map boundaries 
  //   (there will always be a red spot with useLocalExtremas true)
  "useLocalExtrema": false,
  // which field name in your data represents the latitude - default "lat"
  latField: 'lat',
  // which field name in your data represents the longitude - default "lng"
  lngField: 'lng',
  // which field name in your data represents the data value - default "value"
  valueField: 'Prediction'
};

var heatmapLayer = new HeatmapOverlay(cfg);

var map = L.map("map", {
    center: [36.7783, -119.4179],
    zoom: 6,
	layers: [baseLayer, heatmapLayer]
  });


/*   var Legend = L.Control.extend({  
  options: {
    position: 'bottomright'
  },

  onAdd: function (map) {
    var legend = L.DomUtil.create('div', 'map-legend', L.DomUtil.get('map'));

    // here we can fill the legend with colors, strings and whatever
	
	
	
    return legend;
  }
}); */


heatmapLayer.setData(sourceData);
};


