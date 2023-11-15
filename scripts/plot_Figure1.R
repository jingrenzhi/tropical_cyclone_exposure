library(sf)
library(sp)
library(tidyverse)
library(ggplot2)
library(pracma)
library(scales)
library("MetBrewer")

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#           part1: load data
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


wgs84 <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
robinproj = "+proj=robin +over"

# load world map and transform it to the Robinson projection
world_shp <-
  st_read("./data/misc/world_countries_2020.shp")
world_shp_robin = st_transform(
  world_shp,
  "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"
)
world_shp_robin = as.data.frame(world_shp_robin)

# load historical tropical cyclone tracks and transform to the Robinson projection
tcdata = read_csv('./data/misc/ibtracs_data_1989_2019.csv')
tcdata = tcdata[(tcdata$year >= 2002), c('sid', 'tclon', 'tclat', 'max_wind')]
tcdata84 <-
  sp::SpatialPoints(tcdata[, c('tclon', 'tclat')], proj4string = CRS(wgs84))
x <- spTransform(tcdata84, "+proj=robin +over")
tcdata_robin = cbind(tcdata$sid, tcdata$max_wind, as.data.frame(x))
colnames(tcdata_robin) = c('sid', 'max_wind', 'tclon', 'tclat')

# define six subregions
subregion_country = list(
  list(
    c(
      "Bermuda",
      "Canada",
      "United States",
      "Nicaragua",
      "México",
      "Guatemala",
      "Belize",
      "Honduras",
      "El Salvador",
      "Costa Rica"
    ),
    c(-102,-65),
    c(10, 50)
  ),
  # Northern America
  list(
    c(
      "Anguilla",
      "Aruba",
      "Barbados",
      "British Virgin Islands",
      # Caribbean
      "Cayman Islands",
      "Cuba",
      "Dominica",
      "Dominican Republic",
      "Grenada",
      "Guadeloupe",
      "Haiti",
      "Jamaica",
      "Martinique",
      "Montserrat",
      "Puerto Rico",
      "Bonaire, Sint Eustatius and Saba",
      "Saint Kitts and Nevis",
      "Saint Lucia",
      "Saint Vincent and the Grenadines",
      "Trinidad and Tobago",
      "Turks and Caicos Islands",
      "Virgin Islands, U.S."
    ),
    # Southern America
    c(-90,-60),
    c(15, 25)
  ),
  list(
    c("Bangladesh", "India", "Sri Lanka", "Myanmar"),
    c(65, 98),
    c(5, 27)
  ),
  # Southern Asia
  list(c("China", "Taiwan"),  c(105, 125),  c(15, 43)),
  # Eastern Asia: China
  list(c("Japan",
         "North Korea", "South Korea"), c(124, 145), c(30, 55)),
  # Eastern Asia: Japan/Korea
  list(
    c(
      "Cambodia",
      "Indonesia",
      "Laos",
      "Malaysia",
      "Myanmar",
      "Philippines",
      "Singapore",
      "Thailand",
      "Timor-Leste",
      "Vietnam"
    ),
    c(115, 130),
    c(5, 20)
  )
) # Southern-East Asia

# create subregion polygons and transform to the Robinson projection
subregion_box = data.frame()
for (i in 1:length(subregion_country)) {
  subregion_box = rbind(
    subregion_box,
    c(
      i,
      subregion_country[[i]][[2]][1],
      subregion_country[[i]][[3]][1],
      subregion_country[[i]][[2]][2],
      subregion_country[[i]][[3]][2]
    )
  )
  
}
colnames(subregion_box) <- c("id", "xmin", "ymin", "xmax", "ymax")

subregion_box_poly = list()
for (i in 1:nrow(subregion_box)) {
  subregion_box_poly = rbind(subregion_box_poly, rbind(
    c(i, subregion_box[i,]$xmin, subregion_box[i,]$ymin),
    c(i, subregion_box[i,]$xmin, subregion_box[i,]$ymax),
    c(i, subregion_box[i,]$xmax, subregion_box[i,]$ymax),
    c(i, subregion_box[i,]$xmax, subregion_box[i,]$ymin)
  ))
}

subregion_box_poly = as.data.frame(subregion_box_poly)
colnames(subregion_box_poly) <- c("id", "lon", "lat")

subregion_polygon_robin_1 <-
  st_transform(
    subset(subregion_box_poly, id == 1) %>%
      st_as_sf(coords = c("lon", "lat"), crs = wgs84) %>% st_combine() %>% st_cast("POLYGON"),
    "+proj=robin +over"
  )
subregion_polygon_robin_2 <-
  st_transform(
    subset(subregion_box_poly, id == 2) %>%
      st_as_sf(coords = c("lon", "lat"), crs = wgs84) %>% st_combine() %>% st_cast("POLYGON"),
    "+proj=robin +over"
  )
subregion_polygon_robin_3 <-
  st_transform(
    subset(subregion_box_poly, id == 3) %>%
      st_as_sf(coords = c("lon", "lat"), crs = wgs84) %>% st_combine() %>% st_cast("POLYGON"),
    "+proj=robin +over"
  )
subregion_polygon_robin_4 <-
  st_transform(
    subset(subregion_box_poly, id == 4) %>%
      st_as_sf(coords = c("lon", "lat"), crs = wgs84) %>% st_combine() %>% st_cast("POLYGON"),
    "+proj=robin +over"
  )
subregion_polygon_robin_5 <-
  st_transform(
    subset(subregion_box_poly, id == 5) %>%
      st_as_sf(coords = c("lon", "lat"), crs = wgs84) %>% st_combine() %>% st_cast("POLYGON"),
    "+proj=robin +over"
  )
subregion_polygon_robin_6 <-
  st_transform(
    subset(subregion_box_poly, id == 6) %>%
      st_as_sf(coords = c("lon", "lat"), crs = wgs84) %>% st_combine() %>% st_cast("POLYGON"),
    "+proj=robin +over"
  )


# load global person-day exposure shapefiles (post-processed data from script_Figure1.py)
# The shapes of person-day exposure are strongly linked to the tracks of tropical cyclones. 
# To ensure a seamless exposure map that is not influenced by individual events, we employ the average of 
# exposures identified through three wind modeling approaches to create this map, see Methods to 
# get more information about the three modeling approaches.

country_list = list.files(path = "./results/region_person_day/",
                          pattern = "\\_full.shp.zip$",
                          full.names = TRUE)
shapefile_list <- lapply(country_list, read_sf)
all_country <- do.call(rbind, shapefile_list)
all_country_robin = st_transform(all_country, "+proj=robin +over")



# create bounding box and transform it to the Robinson projection
bounding_box = rbind(
  c(-181,-91),
  cbind(rep(-181, 500), linspace(-91, 91, 500)),
  c(-181, 91),
  cbind(linspace(-181, 181, 500), rep(91, 500)),
  c(181, 91),
  cbind(rep(181, 500), linspace(91,-91, 500)),
  c(181,-91),
  cbind(linspace(181,-181, 500), rep(-91, 500))
)
bounding_box = as.data.frame(bounding_box)
colnames(bounding_box) <- c("lon", "lat")
bounding_polygon <-
  st_as_sf(bounding_box, coords = c("lon", "lat"), crs = wgs84) %>% #4326
  st_combine() %>%
  st_cast("POLYGON")
bounding_polygon_robin = st_transform(bounding_polygon, "+proj=robin +over")


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#     part2: global total annual person-days exposure
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p <- ggplot() +
  geom_sf(
    data = world_shp_robin,
    aes(geometry = geometry),
    fill = '#D5DADD',
    color = "white"
  )  +
  geom_path(
    data = tcdata_robin,
    aes(x = tclon, y = tclat, group = sid),
    color = 'lightblue',
    size = 0.05,
    alpha = 0.8
  ) +
  geom_sf(
    data = all_country_robin,
    aes(geometry = geometry, fill = avg_person),
    color = NA,
    linewidth = 0,
    alpha = 0.9
  )  +
  geom_sf(
    data = bounding_polygon_robin,
    aes(geometry = geometry),
    fill = NA,
    color = 'black',
    linewidth = 0.5
  )  +
  geom_sf(
    data = subregion_polygon_robin_1,
    aes(geometry = geometry),
    fill = NA,
    color = "black",
    linewidth = 0.5
  )  +
  geom_sf(
    data = subregion_polygon_robin_2,
    aes(geometry = geometry),
    fill = NA,
    color = "black",
    linewidth = 0.5
  )  +
  geom_sf(
    data = subregion_polygon_robin_3,
    aes(geometry = geometry),
    fill = NA,
    color = "black",
    linewidth = 0.5
  )  +
  geom_sf(
    data = subregion_polygon_robin_4,
    aes(geometry = geometry),
    fill = NA,
    color = "black",
    linewidth = 0.5
  )  +
  geom_sf(
    data = subregion_polygon_robin_5,
    aes(geometry = geometry),
    fill = NA,
    color = "black",
    linewidth = 0.5
  )  +
  geom_sf(
    data = subregion_polygon_robin_6,
    aes(geometry = geometry),
    fill = NA,
    color = "black",
    linewidth = 0.5
  )  +
  scale_fill_gradientn(
    colours = c(
      "#FFD223",
      "#FFAF04",
      "#FF7F06",
      "#F33D1B",
      "#CD001D",
      "#AC1751",
      '#691360'
    ),
    limit = c(1e-2, 4.5e5),
    breaks = c(1e-1, 1e0, 1e1, 1e2, 1e3, 1e4, 1e5),
    trans = "log",
    na.value = NA,
    name = "Person-Day Exposure",
    oob = squish,
    guide = guide_legend(
      keyheight = unit(3, units = "mm"),
      keywidth = unit(12, units = "mm"),
      label.position = "bottom",
      title.position = 'top',
      nrow = 2
    )
  ) +
  theme(
    # Remove title for both x and y axes
    axis.title = element_blank(),
    axis.text = element_blank(),
    plot.background = element_rect(fill = "white", color = "white"),
    panel.background = element_rect(fill = "white", color = "white"),
    legend.position = "none"
  )


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#     part3: regional plots
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


for (subplot_id in 1:length(subregion_country)) {
  country_list = list()
  
  for (country_id in 1:length(subregion_country[[subplot_id]][[1]])) {
    country_shp_file = sprintf(
      './results/region_person_day/person_day_%s_full.shp.zip',
      subregion_country[[subplot_id]][[1]][country_id]
    )
    if (file.exists(country_shp_file)) {
      country_list <- append(country_list, country_shp_file)
    }
  }
  
  shapefile_list <- lapply(country_list, read_sf)
  all_country <- do.call(rbind, shapefile_list)
  region_shp = world_shp[world_shp$CNTRY_NAME %in% subregion_country[[subplot_id]][[1]], ] # australia: 3644
  
  ggplot() +
    geom_sf(
      data = region_shp,
      aes(geometry = geometry),
      fill = '#D5DADD',
      color = NA,
      lwd = 0.1
    ) +
    geom_sf(
      data = all_country,
      aes(geometry = geometry, fill = avg_person),
      color = NA,
      size = 0,
      alpha = 0.9
    )  +
    theme_void() +
    scale_fill_gradientn(
      colours = c(
        "#FFD223",
        "#FFAF04",
        "#FF7F06",
        "#F33D1B",
        "#CD001D",
        "#AC1751",
        '#691360'
      ),
      limit = c(1e-1, 4.5e5),
      breaks = c(1e-1, 1e0, 1e1, 1e2, 1e3, 1e4, 1e5),
      trans = "log",
      na.value = NA,
      name = "Person-Day Exposure",
      oob = squish,
      guide = guide_legend(
        keyheight = unit(3, units = "mm"),
        keywidth = unit(12, units = "mm"),
        label.position = "bottom",
        title.position = 'top',
        nrow = 1
      )
    ) +
    theme(
      # Remove title for both x and y axes
      axis.title = element_blank(),
      # Axes labels are grey
      axis.text = element_blank(),
      plot.background = element_rect(fill = "white", color = "white"),
      panel.background = element_rect(fill = "white", color = "white"),
      legend.position = "bottom"
    ) +
    xlim(subregion_country[[subplot_id]][[2]]) + ylim(subregion_country[[subplot_id]][[3]])
  sprintf('finished: subplot_id = %d', subplot_id)
  
}
