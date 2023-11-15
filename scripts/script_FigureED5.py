"""
Data preparation for Figure ED5 (within-country rdi distribution).

The function extract_country_rdi_distribution() saves Relative Deprivation Index of all grids for each exposed country

Requirements:
    1. country_rdi_exp_unexp_2010_2019.csv, computed from script_Figure4.py
    2. global gridded relative deprivation index (https://sedac.ciesin.columbia.edu/data/set/povmap-grdi-v1)
"""

from helper_functions import *

# load country indices
with open(f'./data/misc/country_indices.pkl', 'rb') as f:
    country_indices = pickle.load(f)

# load global gridded relative deprivation data
povrdi = gdal.Open('./data/misc/povmap-grdi-v1_high_res_global_flip.tif')
povrdi = np.array(povrdi.GetRasterBand(1).ReadAsArray()).astype(float)
povrdi = np.flip(povrdi, axis=0)  # flip rdi map to be consistent with duration data


def extract_country_rdi_distribution():
    country_rdi = pd.read_csv('./results/country_rdi_exp_unexp_2010_2019.csv')
    country_list = country_rdi['country'].unique()
    for country in country_list:
        print(f'processing country: country = {country}')
        if '/' in country:
            continue
        grid_rdi = povrdi[country_indices[country][0][0], country_indices[country][0][1]]
        grid_rdi = grid_rdi[~np.isnan(grid_rdi)]
        np.savetxt(f'./results/country_rdi_distribution/rdi_{country}.csv', grid_rdi,
                   delimiter=',')


def main():
    extract_country_rdi_distribution()


if __name__ == '__main__':
    main()
