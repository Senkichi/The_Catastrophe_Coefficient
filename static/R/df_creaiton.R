setwd('D:/Programs/GitHub/The_Catastrophe_Coefficient/static/data')

require(tcltk)

require(sqldf)
require(rgdal)
require(raster)
require(parallel)
require(landscapeAnalysis)
require(sp)

grep_by <- function(x, pattern=NULL){
  x[grepl(as.character(x), pattern = pattern)]
}
#' hidden function that grabs all "<a href" patterns in an HTML node tree
parse_hrefs <- function(url=NULL){
  return(as.character(rvest::html_nodes(
    xml2::read_html(url), "a"
  )))
}

parse_url <- function(x=NULL){
  return(unlist(lapply(
    strsplit(x, split = "\""),
    FUN = function(x) x[which(grepl(x, pattern = "zip$"))]
  )))
}

#' web scraping interface that parses out full-path URL's for 30 arc-second
#' (900m) worldclim data.
#' @export
scrape_worldclim <- function(base_url="http://worldclim.org/cmip5_30s",
                             models=NULL, # two-letter codes for CMIP model
                             climate=FALSE,
                             bioclim=FALSE,
                             start_of_century=FALSE,
                             mid_century=FALSE,
                             end_of_century=FALSE,
                             scen_45=FALSE,
                             scen_85=FALSE,
                             res="30s",
                             formats="bi"
){
  # fetch and parse index.html
  hrefs_future <- parse_hrefs(url = base_url)
  hrefs_current <- parse_hrefs("http://worldclim.org/current")
  hrefs_final <- vector() # "final" URL's fetch-list
  # greppable user parameters for models to fetch
  time_periods <- vector()
  climate_sets <- vector()
  scenarios    <- vector()
  resolutions  <- res
  # grep across time aggregations (handle "current" last, it is it's own query)
  if (start_of_century){
    time_periods <- append(time_periods,"cur")
  }
  if (mid_century){
    time_periods <- append(time_periods,"50[.]zip")
  }
  if (end_of_century){
    time_periods <- append(time_periods,"70[.]zip")
  }
  hrefs_future <- grep_by(
    hrefs_future,
    pattern = paste(time_periods, collapse = "|")
  )
  # grep across raw climate / bioclim
  if (bioclim){
    climate_sets <- append(climate_sets, "bi.[0-9]")
  }
  if (climate){
    # not implemented -- do some digging
    climate_sets <- append(climate_sets, "tn.[0-9]")
  }
  hrefs_future <- grep_by(
    hrefs_future,
    pattern = paste(climate_sets, collapse = "|")
  )
  # grep across emissions scenarios
  if (scen_45){
    scenarios <- append(scenarios,"/..45")
  }
  if (scen_85){
    scenarios <- append(scenarios,"/..85")
  }
  if(length(scenarios)==0){
    hrefs_future <- grep_by(
      hrefs_future,
      pattern = "cur"
    )
  } else {
    hrefs_future <- grep_by(
      hrefs_future,
      pattern = paste(scenarios, collapse = "|")
    )
  }
  # assume our hrefs into hrefs_final and check for "current" hrefs, if needed
  hrefs_final <- hrefs_future
  
  # grep across resolutions
  if(!is.null(resolutions)){
    hrefs_final <- grep_by(
      hrefs_final,
      pattern = paste(resolutions, collapse = "|")
    )
  }
  # grep across file formats - temporarily disabled, not working as intended
  #if (!is.null(formats)){
  # hrefs_final <- grep_by(
  #   hrefs_final,
  #  pattern = paste(
  #  paste(formats, str_extract_all(time_periods, pattern = "[[0-9]]{2}") ,".zip", sep = ""),
  #  collapse = "|"
  #   )
  # )
  #}
  # grep across GCMs
  if (!is.null(models[1])){
    hrefs_final <- grep_by(
      hrefs_final,
      pattern = paste(paste("/", tolower(models), sep = ""), collapse = "[0-9]|")
    )
  } else if (is.null(models)){
    warning("no CMIP5 models specified by user")
  }
  
  # append "current" climate if it was requested
  if (start_of_century){
    # append bioclim and/or original climate variables to final fetch-list
    if (bioclim){
      hrefs_final <- append(
        hrefs_final,
        grep_by(hrefs_current, pattern = "/bi.[0-9]")
      )
    }
    if (climate){
      hrefs_final <- append(
        hrefs_final,
        grep_by(hrefs_current,
                pattern ="/tmax.[0-9]|/tmean.[0-9]|/tmin.[0-9]|/prec_")
      )
    }
  }
  # return URLs to user
  return(unlist(lapply(hrefs_final, FUN = parse_url)))
}

#' fetch and unpack missing worldclim climate data
#' @export
worldclim_fetch_and_unpack <- function(urls=NULL, exdir="climate_data"){
  if(!dir.exists(exdir)){
    dir.create(exdir)
  }
  existing_files <- list.files(exdir, full.names=T)
  climate_zips <- unlist(lapply(
    strsplit(urls,split="/"),
    FUN = function(x) return(x[length(x)])
  ))
  if(sum(grepl(existing_files, pattern=paste(climate_zips,collapse="|")) ) != length(climate_zips) ){
    cat(" -- fetching missing climate data\n")
    # strip the existing files so we only match against the filename
    fn_existing_files <- unlist(lapply(strsplit(
      existing_files,
      split="/"
    ),
    FUN=function(x) return(x[length(x)])
    ))
    missing_files <- which(!(climate_zips %in% fn_existing_files))
    for(i in missing_files){
      download.file(
        urls[i],
        destfile=file.path(paste(
          exdir,
          climate_zips[i],
          sep = "/")
        )
      )
    }
  }
  # check for existing rasters in exdir and unpack if none found
  # also check zips against existing raster files, unpack zips which haven't beeen unpacked
  existing_files <- list.files(exdir, pattern="bil$|tif$")
  existing_zips <- list.files(exdir, pattern="zip$")
  already_unzipped <- grep_by(existing_zips, pattern = "^^[^_|[0-0]]+")
  if (sum(length(existing_zips)) != sum(length(already_unzipped))) {
    cat(" -- unpacking climate data\n")
    for(i in existing_zips[!(existing_zips %in% already_unzipped)]){
      unzip(file.path(
        paste(paste(getwd(), exdir, sep = "/"),
              i,
              sep="/")
      ),
      exdir=paste(getwd(),
                  exdir,
                  sep = "/")
      )
    }
  } else {
    warning("found existing rasters in the exdir -- leaving existing files")
  }
}

#' return a RasterStack of worldclim data, parsed by flags and/or pattern
#' @export
build_worldclim_stack <- function(vars=NULL,
                                  time=NULL,
                                  bioclim=F,
                                  climate=F,
                                  pattern=NULL,
                                  bounding=NULL){
  all_vars <- list.files(
    paste(getwd(),"climate_data", sep = "/"),
    pattern="bil$|tif$",
    full.names=T
  )
  climate_flags <- vector()
  if(grepl(tolower(time), pattern="cur")){
    # current climate data are always .bil files
    all_vars <- grep_by(all_vars, pattern="bil$")
  } else if(grepl(as.character(time),pattern="50")){
    all_vars <- grep_by(all_vars, pattern=".50.")
  } else if(grepl(as.character(time),pattern="70")){
    all_vars <- grep_by(all_vars, pattern=".70.")
  }
  if(bioclim){
    climate_flags <- append(climate_flags,"bio")
  }
  if(climate){
    climate_flags <- append(climate_flags,"tm.*._|prec")
  }
  
  all_vars <- grep_by(
    all_vars,
    pattern=paste(climate_flags, collapse = "|")
  )
  
  if (!is.null(vars)){
    # parse out weird worldclim var formating (differs by time scenario)
    if(grepl(tolower(time), pattern="cur")){
      v <- unlist(lapply(
        strsplit(all_vars,split="/"),
        FUN=function(x) x[length(x)]
      ))
      v <- lapply(
        strsplit(v,split="_"),
        FUN=function(x) x[length(x)]
      )
      v <- as.numeric(gsub(
        v,
        pattern = ".bil",
        replacement = ""
      ))
      all_vars <- all_vars[ v %in% vars ]
    } else if (grepl(tolower(time), pattern = "50|70")){
      split <- gsub(as.character(time), pattern = "20", replacement = "")
      v <- unlist(lapply(
        strsplit(all_vars, split = "/"),
        FUN = function(x) x[length(x)]
      ))
      v <- lapply(
        strsplit(v,split=split),
        FUN=function(x) x[length(x)]
      )
      v <- as.numeric(gsub(v, pattern=".tif", replacement = ""))
      all_vars <- all_vars[ v %in% vars ]
    }
  }
  # any final custom grep strings passed?
  if(!is.null(pattern)){
    all_vars <- grep_by(all_vars, pattern=pattern)
  }
  # stack and sort our variables before returning the stack to the user
  all_vars <- raster::stack(all_vars)
  if(!is.null(bounding)){
    all_vars <- crop(all_vars, extent(bounding))
  }
  heuristic <- function(x){
    sum(which(letters %in% unlist(strsplit(x[1], split="")))) +
      as.numeric(x[2])
  }
  return(
    all_vars[[
      names(all_vars)[
        order(unlist(lapply(
          strsplit(names(all_vars), split="_"),
          FUN=heuristic)
        ))
        ]
      ]]
  )
}


crop_and_combine <- function(worldclim,
                             landfire,
                             parallel = F,
                             bounds = NULL,
                             bio_raster){
  if((!is.null(bounds))&(is.character(bounds))){
    world_stack <- readOGR(bounds)
  } else if((!is.null(bounds))&(inherits(bounds, "Spatial"))){
    bounds <- bounds
  } 
  if(is.character(landfire)){
    landfire_stack <- stack(landfire)
  } else if(inherits(landfire, "Raster")){
    landfire_stack <- landfire
  } else {
    landfire_stack <- raster::stack(gsub(list.files(
      "landfire_data",
      pattern = "ovr$",
      recursive = T,
      full.names = T
    ),
    pattern = "[.]...",
    replacement = ""
    ))
    NAvalue(landfire_stack) <- -9999
  }
  if((!is.null(bounds))&(!compareCRS(projection(landfire_stack), projection(bounds)))){
    bounds <- spTransform(bounds, projection(landfire_stack))
  }
  if(!is.null(bounds)){
    landfire_stack <- crop(landfire_stack, bounds)
  }
  if(is.character(worldclim)){
    world_stack <- stack(worldclim)
  } else if(inherits(worldclim, "Raster")){
    world_stack <- worldclim
  } else {
    world_stack <- worldclim_stack(bioclim = T, time = "cur", bounding = bounds)
  }
  if((!is.null(bounds))&(!compareCRS(projection(world_stack), projection(bounds)))){
    bounds <- spTransform(bounds, projection(world_stack))
  }
  if(!is.null(bounds)){
    world_stack <- crop(world_stack, bounds)
  }
  if(parallel){
    cl <- detectCores()
    beginCluster(cl-1)
    on.exit(returnCluster())
    if((!compareCRS(projection(landfire_stack), projection(world_stack)))|(!landfire_stack@extent==world_stack@extent)){
      landfire_stack <- raster::projectRaster(
        from=landfire_stack, 
        crs=sp::CRS(raster::projection(world_stack)
        ))
      landfire_stack <- raster::resample(
        landfire_stack, 
        world_stack, 
        method='ngb'
      )
    }
    if((!compareCRS(projection(bio_raster), projection(world_stack)))|(!bio_raster@extent==world_stack@extent)){
      bio_raster <- raster::projectRaster(
        from=bio_raster, 
        crs=sp::CRS(raster::projection(world_stack)
        ))
      bio_raster <- raster::resample(
        bio_raster, 
        world_stack, 
        method='ngb'
      )
    }
  } else {
    if((!compareCRS(projection(landfire_stack), projection(world_stack)))|(!landfire_stack@extent==world_stack@extent)){
      landfire_stack <- raster::projectRaster(
        from=landfire_stack, 
        crs=sp::CRS(raster::projection(world_stack)
        ))
      landfire_stack <- raster::resample(
        landfire_stack, 
        world_stack, 
        method='ngb'
      )
    }
    if((!compareCRS(projection(bio_raster), projection(world_stack)))|(!bio_raster@extent==world_stack@extent)){
      bio_raster <- raster::projectRaster(
        from=bio_raster, 
        crs=sp::CRS(raster::projection(world_stack)
        ))
      bio_raster <- raster::resample(
        bio_raster, 
        world_stack, 
        method='ngb'
      )
    }
  }
  final_stack <- stack(world_stack, landfire_stack, bio_raster, quick = T)
} 


# read in fire data, currently as polugons of the fire boundaries with associated data
fire <- readOGR('../data/Wildfires_1870_2015_Great_Basin_SHAPEFILE/Wildfires_1870_2015_Great_Basin.shp')

#create a bounding box of the area of the fire dataset, to trim down the wordclim dataset later
fire_extent <- raster::extent(fire)

#turn that bounding box into a polygon
fire_extent <- as(
  fire_extent,
  'SpatialPolygons'
)


#selects only the fire data of years we are interested in
fire_century <- fire[fire@data[,'Fire_Year'] > 1970,]

#assign value of 1 to all polygons, which we will use as the presence/absence responce variable
fire_century@data[, 'presence'] <- 1

#make sure geographic proections are consistent between files
fire_century <- spTransform(fire_century, CRS("+proj=longlat +ellps=WGS84 +towgs84=0,0,0,0,0,0,0 +no_defs"))

proj4string(fire_extent) <- CRS("+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0")

fire_extent <- spTransform(fire_extent, CRS("+proj=longlat +ellps=WGS84 +towgs84=0,0,0,0,0,0,0 +no_defs"))

#get worldclim data
worldclim_fetch_and_unpack(urls = scrape_worldclim(
  bioclim=T,
  climate = T,
  start_of_century = T,
  mid_century = T,
  end_of_century = T,
  scen_45 = T,
  models = "AC"
))

#Get worldclim data for the future dataset
future_worldclim <- raster::crop(
  build_worldclim_stack(
    time=50,
    bioclim=T,
    climate = T),
  fire_extent
)

#get worldclim data for the current dataset
worldclim <- raster::crop(
  build_worldclim_stack(bioclim = T, time = "cur"),
  fire_extent)

#convert fire polygons to raster file, spatially consistent with worldclim
fire_raster <- raster::rasterize(
  fire_century,
  worldclim,
  field=c('presence')
)

#change na values to zero
fire_raster[is.na(fire_raster)] <- 0

#create a layer of centerpoints for each raster pixel, we will use these points to extract the data
#values from each stacked raster layer underneath each point to create the final dataframe
fire_points <- raster::rasterToPoints(fire_raster, spatial=T)

#extract fire data as a n length list of 1/0 values for the n pixels 
raster_frame <- raster::extract(fire_raster, fire_points)

#extract worldclim data into its own frame at the same points, then bind the fire frame and the worldclim frame together
#For analysis
worldclim_frame <- raster::extract(worldclim, fire_points)
  worldclim_frame <- cbind(worldclim_frame, raster_frame)

#export file
write.csv(worldclim_frame, 'bio_vars_frame.csv')  
