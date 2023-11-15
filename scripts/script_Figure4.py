"""
Data preparation for Figure 4 (country rdi), Figure 5 (rdi trend), Figure ED6 (sensitivity test for country rdi) and
Figure ED7 (sensitivity test for rdi trend).

The function compute_country_rdi() calculate the relative deprivation index (rdi) for both the exposed and unexposed
populations across all countries that have been exposed to tropical cyclones in 2002-2019.

Requirements:
    1. country_indices.pkl, computed from helper_functions.py
    2. global gridded relative deprivation index (https://sedac.ciesin.columbia.edu/data/set/povmap-grdi-v1)
    3. global gridded population dataset from worldpop
    4. global gridded tropical cyclone exposure data
"""

from helper_functions import *

with open(f'./data/misc/country_indices.pkl', 'rb') as f:
    country_indices = pickle.load(f)
country_list = list(country_indices.keys())

# load global gridded relative deprivation data
povrdi = gdal.Open('./data/misc/povmap-grdi-v1_high_res_global.tif')
povrdi = np.array(povrdi.GetRasterBand(1).ReadAsArray()).astype(float)
povrdi = np.flip(povrdi, axis=0)  # flip rdi map to be consistent with duration data

# load global population data at 2015
worldpop = gdal.Open(f'{path_pop}/ppp_2015_1km_Aggregated.tif')
worldpop = np.array(worldpop.GetRasterBand(1).ReadAsArray())
worldpop = np.round(worldpop)
# Due to potential float read errors, set arbitrarily large or small values to NaN
worldpop[worldpop <= 0] = np.NAN
worldpop[worldpop >= 1e10] = np.NAN

wind_cutoff_list = ['ts_12h', 'cat1_12h', 'cat2_12h', 'cat3_12h', 'cat4_12h', 'cat5_12h']


def compute_country_rdi():
    rdi_data = []
    for thres in wind_cutoff_list:
        # load tropical cyclone duration exposure
        duration = get_multiple_year_exposure(2010, 2019, thres)
        for country in country_list:
            print(f'processing country: country = {country}')
            grid_population = worldpop[country_indices[country][0][0], country_indices[country][0][1]]
            grid_tc_duration = duration[country_indices[country][0][0], country_indices[country][0][1]]
            grid_rdi = povrdi[country_indices[country][0][0], country_indices[country][0][1]]
            if np.sum(grid_tc_duration) == 0:
                continue
            total_popultaion = np.nansum(grid_population)
            if total_popultaion == 0:
                continue
            # compute population-averaged rdi for each country
            total_avg_rdi = weighted_avg(grid_rdi, grid_population)
            # compute total number of exposed population
            exposed_population = np.nansum(grid_population[grid_tc_duration > 0])
            if exposed_population == 0:
                continue
            # compute total number of unexposed population
            unexposed_population = np.nansum(grid_population[grid_tc_duration == 0])
            # compute population-averaged rdi for exposed population
            exposed_avg_rdi = weighted_avg(grid_rdi[grid_tc_duration > 0], grid_population[grid_tc_duration > 0])
            # compute population-averaged rdi for unexposed population
            unexposed_avg_rdi = weighted_avg(grid_rdi[grid_tc_duration == 0], grid_population[grid_tc_duration == 0])
            # prepare data row
            country_data = [country, thres,
                            total_popultaion, exposed_population, unexposed_population,
                            total_avg_rdi, exposed_avg_rdi, unexposed_avg_rdi]
            rdi_data.append(country_data)
    rdi_df = pd.DataFrame(rdi_data, columns=['country', 'wind_cutoff', 'total_pop', 'exposed_pop', 'unexposed_pop',
                                             'avg_rdi', 'exposed_avg_rdi', 'unexposed_avg_rdi'])
    rdi_df.to_csv('./results/country_rdi_exp_unexp_2010_2019.csv',
                  index=False)


def main():
    compute_country_rdi()


if __name__ == '__main__':
    main()
