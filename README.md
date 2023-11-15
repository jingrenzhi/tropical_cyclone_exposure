# Global Population Profile of Tropical Cyclone Exposure during 2002 and 2019


Replication materials for Jing et al. (2023).

The materials in this repository reproduce the figures, tables, and calculations appearing in the main text and extended data of the paper.

If you find meaningful errors in the code or have questions or suggestions, please contact Renzhi Jing at jingrenzhi.go@gmail.com


### Organization of repository

* **scripts**: scripts for replication of figures, tables, and calculations.
* **figures/published**: published versions of the figures.
* **figures/raw**: scripts plot_Figure*.R will generate pdf figures in this directory.
* **data/tc**: gridded high-resolution tropical cyclone exposure data 
* **data/worldpop**: high-resolution gridded population data
* **data/misc**: uncategorized data that is needed for the paper
* **results**: folder to save intermediate results 


### Data

* **data/tc**
    * ***duration*** &emsp;tropical cyclone exposure assuming up to 6 hours, 12 hours and no limit on duration of overland sustained wind. The temporal resolution is 3 hour. The files follow a structured naming convention:   
        **duration\_{year}\_{wind_level}\_{landfall}.tif**  
        For instance, a file named duration\_2002\_cat1\_12h.tif contains gridded data representing the duration that each grid endured the impact of Category 1 tropical cyclones, assuming up to 12 hours of sustained winds over land. With a temporal resolution of 3 hours, a duration value of 2 indicates that in 2002 the grid was exposed for a total of 6 hours.

* **data/worldpop**
    * ***worldpop\_total*** &emsp;high-resolution gridded population data from WorldPop, downloaded at https://hub.worldpop.org/geodata/listing?id=29. The datasets are available for each year from 2000 to 2019 with a resolution of 30 arc seconds. 

    * ***worldpop\_age\_gender*** &emsp;high-resolution gridded age and sex distributions data from Worldpop, downloaded at https://data.worldpop.org/GIS/AgeSex_structures/. Similarly, the datasets are available for each year from 2000 to 2019 with a resolution of 30 arc seconds.

* **data/misc** 
    * ***gadm_410.gpkg*** &emsp;GADM data version 4.1, providing maps and spatial data for all countries and their sub-divisions. The data is downloaded at: https://gadm.org/data.html.

    * ***world_countries_2020*** &emsp;country boundaries from IPUMS, downloaded at: https://international.ipums.org/international/gis.shtml.

    * ***world_continent*** &emsp;continent boundaries downloaded from ArcGIS Hub, downloaded at: https://hub.arcgis.com/datasets/esri::world-continents/about.

    * ***global_mask.tif*** &emsp; 2D array with the same resolution as the worldpop data, which is only used to generate a dictionary, saving the indices of the map for each country and continent.

    * ***povmap-grdi-v1_high_res_global.tif*** &emsp; high-resolution gridded relative deprivation index. The raw data is downloaded at SEDAC https://sedac.ciesin.columbia.edu/data/set/povmap-grdi-v1 with a resolution of ~1 km. We adjust the map's resolution to align with that of the Worldpop data.

    * ***supplementary_table1.csv*** &emsp; data used to generate supplementary table 1.

    * ***ibtracs_data_1989_2019.csv*** &emsp; historical tropical cyclone tracks, derived from IBTrACS dataset. The tracks are used in Figure 1.

### Scripts 
Python files calculate intermediate data that is used to generate the figures

* Script helper_functions.py includes global variables and self-defined functions. 
* Script script_Figure*.py replicate the calculations reported in the paper.


### Figures
R files (plot_Figure*.R) generate the figures in the paper and write them to figures/raw. The figures produced by these scripts will be slightly visually different than the published figures because post-processing was done in Adobe Illustrator. Published versions of the figures are available in figures/clean.

* Script plot_Figure1.R generates Figure 1.
* Script plot_Figure2.R generates Figure 2, Figure ED2, Figure ED3 and Figure ED8.
* Script plot_Figure3.R generates Figure 3, Figure ED4. 
* Script plot_Figure4.R generates Figure 4 and Figure ED6.
* Script plot_Figure5.R generates Figure 5 and Figure ED7.
* Script plot_FigureED1.R generates Figure ED1.
* Script plot_FigureED5.R generates Figure ED5.


## Code/Software
Scripts were written in Python 3.6.1 and R 4.2.3.
[Link to Dryad repo with all the replication data](https://doi.org/10.5061/dryad.76hdr7t30)


### Python packages required
* **numpy**
* **math**
* **pandas**
* **os**
* **time**
* **pickle**
* **geopandas**
* **rasterio**
* **itertools**
* **scipy**
* **osgeo**
* **shapely**
* **global_land_mask**
* **multiprocessing** for parallel computing

### R packages required
* **classInt**
* **fields**
* **lfe**
* **multcomp**
* **maptools**
* **plotrix**
* **splines**
* **tidyverse**

