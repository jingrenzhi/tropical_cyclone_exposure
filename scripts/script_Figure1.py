"""
Data preparation for Figure 1. This script includes two steps:

1. compute gridded total person-day exposure during 2002-2019
    - function get_total_person_day_exposure()

2. Calculate the total person-day exposure for each administrative area in each country.
    - function get_total_person_day_exposure()
"""

from helper_functions import *

PROCESSER_COUNT = 8

# load global admin borders
data = gpd.read_file("./data/misc/gadm_410.gpkg")

# load exposed country list; data in this table is generated with script_Figure4.py
country_exposed_list_df = pd.read_csv('./misc/supplementary_table1.csv')
country_exposed_list = country_exposed_list_df['country'].to_list()


def get_total_person_day_exposure():
    """
    Get gridded total person-day exposure between the years 2002 and 2019
    """
    total_person_days = np.zeros(wp_dimensions)
    for year in range(2019, 2001, -1):
        print(f'start: year  = {year}')
        # compute yearly person day exposure
        exp_map = calc_tot_exp_person_day(year, 'ts_12h')
        total_person_days = total_person_days + exp_map
    total_person_days = total_person_days / 18
    save_numpy_to_tif(total_person_days, './results/total_person_days_2002_2019.tif', 'float')


def extract_country_person_day(country: str):
    """
    Calculate the total person-day exposure for each administrative area in each country
    Args:
        country - country name
    Returns:
        Save person_day_exposure of each administrative area in each country as file: person_day_{country}_full.shp.zip
    """
    if country == 'Mexico':
        country = 'México'
    country = country.replace("Is.", "Islands")
    country_data = data.loc[(data['COUNTRY'] == country),]
    # load total person_day exposure (.tif file)
    total_duration = gdal.Open(f'./results/total_person_days_2002_2019.tif')
    total_duration = np.array(total_duration.GetRasterBand(1).ReadAsArray())
    total_duration[total_duration == 0] = np.nan
    # start computing
    country_data['avg_person_days'] = 0
    geomslist = country_data.geometry.values  # a list of multipolygons for each administrative area
    for i in range(len(geomslist)):
        region_geoms = [mapping(geomslist[i])]
        out_image, out_transform = mask(global_mask, region_geoms)
        out_image = np.squeeze(out_image)
        if np.sum(out_image) == 0 or len(out_image.shape) == 1:
            continue
        row, col = np.where(out_image == 1)  # extract the row, columns of the valid values
        grid_person_days = total_duration[row, col]
        if np.nansum(grid_person_days) == 0 or np.isnan(np.nansum(grid_person_days)):
            print(f'no exposure: country = {country}, i = {i}/{len(geomslist)}')
            continue
        else:
            country_data['avg_person_days'].iloc[i] = np.nansum(grid_person_days) / len(row)
            print(f'processing: country = {country}, i = {i}/{len(geomslist)}')
    country_person_day_gdf = country_data[['UID', 'NAME_0', 'NAME_1', 'NAME_2', 'NAME_3', 'NAME_4', 'NAME_5',
                                           'COUNTRY', 'CONTINENT', 'geometry', 'avg_person_days']]
    country_person_day_gdf.to_file(f'/data/region_person_day_method3/person_day_{country}_full.shp.zip')
    country_person_day_gdf = country_data[
        country_data['avg_person_days'] != 0][['UID', 'NAME_0', 'NAME_1', 'NAME_2', 'NAME_3', 'NAME_4', 'NAME_5',
                                               'COUNTRY', 'CONTINENT', 'geometry', 'avg_person_days']]
    if country_person_day_gdf.shape[0] != 0:
        country_person_day_gdf.to_file(f'./results/region_person_day/person_day_{country}.shp.zip')


def run_parallel_process(operation, input, pool):
    pool.map(operation, input)


def parallel_compute_person_day(input_index):
    country = country_exposed_list[input_index]
    if '/' in country:
        print('country name not valid')
    elif os.path.isfile(f'./results/region_person_day/person_day_{country}.shp.zip'):
        print(f'already exist: country={country}')
    else:
        print(f'start: country={country}')
        extract_country_person_day(country)
        print(f'saved shp file: country={country}')


def main():
    processes_pool = Pool(PROCESSER_COUNT)
    arg = range(len(country_exposed_list))
    get_total_person_day_exposure()
    run_parallel_process(parallel_compute_person_day, arg, processes_pool)


if __name__ == '__main__':
    main()
