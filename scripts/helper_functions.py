import numpy as np
import math
import pandas as pd
import os
import time
import pickle
import geopandas as gpd
import rasterio
import itertools

from scipy import interpolate
from osgeo import gdal, osr, ogr  # Python bindings for GDAL
from rasterio.mask import mask
from shapely.geometry import mapping
from multiprocessing import Pool  # Parallel computing

# worldpop extent and resolution specification
wp_xmin = -180.0012
wp_xmax = 179.9987  # worldpop data extent
wp_ymin = -71.99208
wp_ymax = 84.00792
wp_extent = [wp_xmin, wp_ymin, wp_xmax, wp_ymax]  # Define the data extent (min.lon, min.lat, max.lon, max.lat)
wp_dimensions = [18720, 43200]  # latitude, longitude
wp_lon = np.linspace(wp_xmin, wp_xmax, wp_dimensions[1])
wp_lat = np.linspace(wp_ymin, wp_ymax, wp_dimensions[0])
wp_yres = (wp_lat[-1] - wp_lat[0]) / (len(wp_lat) - 1)
wp_xres = (wp_lon[-1] - wp_lon[0]) / (len(wp_lon) - 1)

# global world data
data = gpd.read_file("./data/misc/gadm_410.gpkg")

# tropical cyclone wind cutoff list
wind_cutoff_list = ['td', 'ts', 'cat1', 'cat2', 'cat3', 'cat4', 'cat5']

# shapefile for all continents/countries
world_shp = gpd.read_file("./data/misc/world_countries_2020/world_countries_2020.shp")
world_continent_shp = gpd.read_file("./data/misc/world_continent/Continents.shp")

# relative deprivation index: specification",
# 30 arc-second (~1 km) pixel, float, 100 represents the highest and 0 the lowest
rdi_xmin = -180.0
rdi_xmax = 179.8
rdi_ymin = -56.0
rdi_ymax = 82.18
rdi_dimensions = [16580, 43178]  # height, width\n",
# tc_layer = [[[]] * wp_dimensions[1]] * wp_dimensions[0] # 18720*43200 (lat*lon)
rdi_lon = np.linspace(rdi_xmin, rdi_xmax, rdi_dimensions[1])
rdi_lat = np.linspace(rdi_ymin, rdi_ymax, rdi_dimensions[0])
rdi_yres = (rdi_lat[-1] - rdi_lat[0]) / (len(rdi_lat) - 1)
rdi_xres = (rdi_lon[-1] - rdi_lon[0]) / (len(rdi_lon) - 1)

global_mask = rasterio.open('./data/misc/global_mask.tif')

# dirs:
path_pop = "./data/worldpop/worldpop_all"
path_pop_age_gender = "./data/worldpop/worldpop_age_gender"
path_dur = "./data/tc/duration/"  # file path for tropical cyclone durations


def get_continent_indices():
    """
    Obtain the indices corresponding to each continent within the WorldPop resolution.
    Returns:
        Generates a dictionary where each continent serves as the key,
        while the corresponding values denote the indices associated
    """
    continent_indices = {}
    geomslist = world_continent_shp.geometry.values
    for i in range(len(geomslist)):
        continent_name = world_continent_shp.CONTINENT[i]
        continent_geoms = [mapping(geomslist[i])]
        out_image, out_transform = mask(global_mask, continent_geoms)
        out_image = np.squeeze(out_image)
        if np.sum(out_image) == 0 or len(out_image.shape) == 1:
            continue
        row, col = np.where(out_image == 1)  # extract the row, columns of the valid values
        # filtered_data = np.extract(out_image != no_data, out_image) # extract the values of the masked array
        if continent_name not in continent_indices:
            continent_indices[continent_name] = [(row, col)]
        else:
            print('continent already added')
        print(f'added: continent ={continent_name}, i = {i}')
    with open(f'./data/misc/continent_indices.pkl', 'wb') as fs:
        pickle.dump(continent_indices, fs)
    return None


def get_country_indices():
    """
    Obtain the indices corresponding to each country within the WorldPop resolution.
    Returns:
        Generates a dictionary where each country serves as the key, while the corresponding values denote the indices
        associated with each country.
    """
    country_indices = {}
    geomslist = world_shp.geometry.values
    for i in range(len(geomslist)):
        country_name = world_shp.CNTRY_NAME[i]
        country_geoms = [mapping(geomslist[i])]
        out_image, out_transform = mask(global_mask, country_geoms)
        out_image = np.squeeze(out_image)
        if np.sum(out_image) == 0 or len(out_image.shape) == 1:
            continue
        row, col = np.where(out_image == 1)  # extract the row, columns of the valid values
        # filtered_data = np.extract(out_image != no_data, out_image) # extract the values of the masked array
        if country_name not in country_indices:
            country_indices[country_name] = [(row, col)]
        else:
            print('country already added')
        print(f'added: country ={country_name}, i = {i}')
    with open(f'./data/misc/country_indices.pkl', 'wb') as fs:
        pickle.dump(country_indices, fs)
    return None


def get_multiple_year_exposure(year_start: int, year_to: int, windstat: str):
    """
    Obtain the grid cells that were exposed to a certain level of wind intensity over multiple years.
    
    Args:
        year_start, year_to - the initial and final years for computing this exposure.
        windstat - a string to indicate wind intensity level; options are:
            'ts': tropical storm
            s'cat1', 'cat2', 'cat3', 'cat4', 'cat5': Category 1-5 tropical cyclones

    Returns:
        duration_multi_year - 2d array of dimension [18720, 43200] of 0/1 represents whether the grid was exposed
    """
    duration_multi_year = np.zeros(wp_dimensions)
    for year in np.arange(year_start, year_to + 1):
        duration = gdal.Open(f'{path_dur}/duration_{year}_{windstat}.tif')
        duration = np.array(duration.GetRasterBand(1).ReadAsArray()).astype(float)
        duration = np.flip(duration, axis=0)
        duration_multi_year[duration >= 1] = 1
        print(f'finished get multiple year exposure: year = {year}')
    return duration_multi_year


def save_numpy_to_tif(data, output_tif_file: str, tiftype: str):
    """
    Save 2D numpy array to tif file

    Args: 
        data: 2D numpy array
        output_tif_file: a string represents the output file path and name
        tiftype: a string represents the data type, options are:
            'int': tif file will be saved in 16-bit integer (Int 16) format.
            'float': tif file will be saved in 32-bit floating point (Float 32)  format.
    """
    driver = gdal.GetDriverByName('GTiff')
    # Get dimensions
    nlines = data.shape[0]
    ncols = data.shape[1]
    if tiftype == 'int':
        data_type = gdal.GDT_Byte  # gdal.GDT_Int16
    elif tiftype == 'float':
        data_type = gdal.GDT_Float32  # gdal.GDT_Float32,
    else:
        print('Error: invalid data type!')
    # Create a temp grid
    grid_data_temp = output_tif_file.split('.')[0] + '_temp'
    grid_data = driver.Create(grid_data_temp, ncols, nlines, 1, data_type)  # , options)
    # Write data for each bands
    grid_data.GetRasterBand(1).WriteArray(data)
    # Lat/Lon WSG84 Spatial Reference System
    srs = osr.SpatialReference()
    srs.ImportFromProj4('+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs')
    # Setup projection and geo-transform
    grid_data.SetProjection(srs.ExportToWkt())
    grid_data.SetGeoTransform(get_geo_transform(wp_extent, nlines, ncols))
    # Save to .gif file
    driver.CreateCopy(output_tif_file, grid_data, 0)
    driver = None
    grid_data = None
    os.remove(grid_data_temp)
    return None


def get_geo_transform(extent, nlines, ncols):
    """
    Define the extent and resolution of tif file, use with function save_numpy_to_tif()
    """
    resx = (extent[2] - extent[0]) / ncols
    resy = (extent[3] - extent[1]) / nlines
    return [extent[0], resx, 0, extent[3], 0, -resy]


def weighted_avg(A, weights):
    """
    Compute weighted average of A 
    Args:
        A -  m*1 vector to be computed
        weights -  m*1 vector of weights
    Returns:
        weighted average of A after removing nans
    """
    return np.nansum(A * weights) / np.nansum((~np.isnan(A)) * weights)


def calc_tot_exp_pop(year: int, windstat: str):
    """
    Determine the total population exposure to a specific tropical cyclone intensity in a particular year.

    Args: 
    year - Year for which the exposure is to be calculated.
    windstat - a string to indicate wind intensity level; options are: 
        'ts': tropical storm
        'cat1', 'cat2', 'cat3', 'cat4', 'cat5': Category 1-5 tropical cyclones

    Returns:
        exp_map: a number represents the total population exposure 
    """
    wp = gdal.Open(f'{path_pop}/ppp_{year}_1km_Aggregated.tif')
    wp = np.array(wp.GetRasterBand(1).ReadAsArray())
    wp = np.round(wp)
    # Due to potential float read errors, set arbitrarily large or small values to 0
    wp[wp <= 0] = 0
    wp[wp >= 1e10] = 0
    wd = gdal.Open(f'{path_dur}/duration_{year}_{windstat}.tif')
    wd = np.array(wd.GetRasterBand(1).ReadAsArray())
    wd = wd.astype('float32')
    wd = np.flip(wd, axis=0)
    wd[wd <= 0] = 0
    wd[wd >= 1] = 1
    exp_map = np.multiply(wd, wp)
    return exp_map


def calc_tot_exp_person_day(year: int, windstat: str):
    """
    Determine the total person-days exposure to a specific tropical cyclone intensity in a particular year.

    Args: 
    year - Year for which the exposure is to be calculated.
    windstat - a string to indicate wind intensity level; options are: 
        'ts': tropical storm
        'cat1', 'cat2', 'cat3', 'cat4', 'cat5': Category 1-5 tropical cyclones

    Returns:
        exp_map: a number represents the total population exposure 
    """
    wp = gdal.Open(f'{path_pop}/ppp_{year}_1km_Aggregated.tif')
    wp = np.array(wp.GetRasterBand(1).ReadAsArray())
    wp = np.round(wp)
    # Due to potential float read errors, set arbitrarily large or small values to 0
    wp[wp <= 0] = 0
    wp[wp >= 1e10] = 0
    wd = gdal.Open(f'{path_dur}/duration_{year}_{windstat}.tif')
    wd = np.array(wd.GetRasterBand(1).ReadAsArray())
    wd = wd.astype('float32')
    wd = np.flip(wd, axis=0)
    wd[wd <= 0] = 0
    wd = wd / 8  # duration data is provided with a temporal resolution of 3 hours
    exp_map = np.multiply(wd, wp)
    return exp_map
