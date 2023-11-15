"""
Data preparation for Figure ED1 (continent exposure).

This script computes total population exposure for each continent.

Requirements:
    1. continent_indices.pkl
    2. global gridded population data from worldpop
    3. gridded duration of tropical cyclone exposure
"""

from helper_functions import *

wind_cutoff_list = ['ts_12h']

# load continent indices
with open(f'./data/misc/continent_indices.pkl', 'rb') as f:
    continent_indices = pickle.load(f)
continent_list = list(continent_indices.keys())


def compute_continent_exposure():
    exp_pop_data = []
    for wind_stat in wind_cutoff_list:
        for year in range(2019, 2001, -1):
            exp_map = calc_tot_exp_pop(year, wind_stat)
            total_pop_exp = np.nansum(exp_map)
            exp_pop_data.append([year, wind_stat, 'all', total_pop_exp])
            for continent in continent_list:
                continent_pop_exp = np.nansum(
                    exp_map[continent_indices[continent][0][0], continent_indices[continent][0][1]])
                exp_pop_data.append([year, wind_stat, continent, continent_pop_exp])
            print(f'finish: year = {year}, wind_cutoff = {wind_stat}')
    exposure_df = pd.DataFrame(exp_pop_data, columns=['year', 'wind_cutoff', 'continent', 'pop_exp'])
    exposure_df.to_csv('./results/exposure_population_data.csv', index=False)


def main():
    compute_continent_exposure()


if __name__ == '__main__':
    main()
