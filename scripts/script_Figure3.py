"""
Data preparation for Figure 3 (age distribution for exposed population) and Figure ED4 (unexposed population,
sensitivity test for age distribution).

This script calculates the age and gender distribution of exposed/unexposed population.
For exposed population: extract_age_gender_exposed_population()
For unexposed population: extract_age_gender_unexposed_population()

Requirements:
    1. continent_indices.pkl
    2. age and gender structures from worldpop in 2002-2019
    3. global gridded tropical cyclone exposure data
"""

from helper_functions import *

PROCESSER_COUNT = 10  # number of parallel computing cores

# load continent indices
with open(f'./data/misc/continent_indices.pkl', 'rb') as f:
    continent_indices = pickle.load(f)
continent_list = list(continent_indices.keys())

# generate arg list for parallel computing:
year_list = np.arange(2019, 1999, -1)
age_list = np.append([0, 1], np.arange(5, 85, 5))
wind_cutoff_list = ['ts']
gender_list = ['m', 'f']
arg_list = list(itertools.product(year_list, wind_cutoff_list, age_list, gender_list))


def extract_age_gender_exposed_population(year: int, wind_stat: str, age: int, gender: str):
    """
    Calculates age and gender distribution of populations exposed to Tropical Storm
    Args:
        wind_stat: wind intensity threshold; options are: 'ts', 'cat1', 'cat2', 'cat3', 'cat4', 'cat5'
        age: age group
        gender: options are 'f', 'm'
    """
    age_gender_pop_data = []
    wp = gdal.Open(f'{path_pop_age_gender}/global_{gender}_{age}_{year}_1km.tif')
    wp = np.array(wp.GetRasterBand(1).ReadAsArray())
    wp = np.round(wp)
    # Due to potential float read errors, set arbitrarily large or small values to 0
    wp[wp <= 0] = 0
    wp[wp >= 1e10] = 0
    # load tropical cyclone exposure
    wd = gdal.Open(f'{path_dur}/duration_{year}_{wind_stat}.tif')
    wd = np.array(wd.GetRasterBand(1).ReadAsArray())
    wd = wd.astype('float32')
    wd = np.flip(wd, axis=0)
    wd[wd <= 0] = 0
    for duration_cutoff in [1, 2]:  # assuming different limit of sustained winds over land
        wd_duration = wd >= duration_cutoff
        exp_map = np.multiply(wd_duration, wp)
        total_pop_exp = np.nansum(exp_map)
        age_gender_pop_data.append([year, wind_stat, duration_cutoff, 'all', age, gender, total_pop_exp])
        for continent in continent_list:
            continent_pop_exp = np.nansum(
                exp_map[continent_indices[continent][0][0], continent_indices[continent][0][1]])
            age_gender_pop_data.append([year, wind_stat, duration_cutoff, continent, age, gender, continent_pop_exp])
    exposure_df = pd.DataFrame(age_gender_pop_data,
                               columns=['year', 'wind_cutoff', 'duration', 'continent', 'age', 'gender', 'pop_exp'])
    exposure_df.to_csv(f'./results/age_gender_exp/age_gender_exposure_{year}_{wind_stat}_{age}_{gender}.csv',
                       index=False)


def extract_age_gender_unexposed_population(year: int, wind_stat: str, age: int, gender: str):
    """
    Same with extract_age_gender_exposed_population(), but for unexposed population
    """
    age_gender_unexp_pop_data = []
    wp = gdal.Open(f'{path_pop_age_gender}/global_{gender}_{age}_{year}_1km.tif')
    wp = np.array(wp.GetRasterBand(1).ReadAsArray())
    wp = np.round(wp)
    # Due to potential float read errors, set arbitrarily large or small values to 0
    wp[wp <= 0] = 0
    wp[wp >= 1e10] = 0
    # load tropical cyclone exposure
    wd = gdal.Open(f'{path_dur}/duration_{year}_{wind_stat}.tif')
    wd = np.array(wd.GetRasterBand(1).ReadAsArray())
    wd = wd.astype('float32')
    wd = np.flip(wd, axis=0)
    wd[wd <= 0] = 0
    wd = wd == 0
    exp_map = np.multiply(wd, wp)
    total_pop_unexp = np.nansum(exp_map)
    age_gender_unexp_pop_data.append([year, wind_stat, 'all', age, gender, total_pop_unexp])
    for continent in continent_list:
        continent_pop_unexp = np.nansum(exp_map[continent_indices[continent][0][0], continent_indices[continent][0][1]])
        age_gender_unexp_pop_data.append([year, wind_stat, continent, age, gender, continent_pop_unexp])
    # print(f'finish: year = {year}, wind_cutoff = {wind_stat}, duration_cutoff = {duration_cutoff}')

    unexposure_df = pd.DataFrame(age_gender_unexp_pop_data,
                                 columns=['year', 'wind_cutoff', 'continent', 'age', 'gender', 'pop_exp'])
    unexposure_df.to_csv(f'./results/age_gender_unexp/age_gender_unexposed_{year}_{wind_stat}_{age}_{gender}.csv',
                         index=False)


def run_parallel_process(operation, input, pool):
    pool.map(operation, input)


def get_age_gender_exposure(input_index):
    year = arg_list[input_index][0]
    wind_stat = arg_list[input_index][1]
    age = arg_list[input_index][2]
    gender = arg_list[input_index][3]
    if os.path.isfile(f'./results/age_gender_exp/age_gender_exposure_{year}_{wind_stat}_{age}_{gender}.csv'):
        print(f'already exist: year = {year}, wind={wind_stat}, age = {age}, gender = {gender}')
    else:
        extract_age_gender_exposed_population(year, wind_stat, age, gender)
        print(f'saved csv file: year = {year}, wind={wind_stat}, age = {age}, gender = {gender}')


def main():
    processes_pool = Pool(PROCESSER_COUNT)
    arg = range(len(arg_list))
    run_parallel_process(get_age_gender_exposure, arg, processes_pool)


if __name__ == '__main__':
    main()
