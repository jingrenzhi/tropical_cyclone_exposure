"""
Data preparation for Figure 2 (main, population exposure), Figure ED2 (person-day exposure),
Figure ED3 (different modeling approaches), and Figure ED8 (relative contribution).

This script calculates the overall population exposure for each year across various levels of wind intensity,
assuming up to 6 hour, 12 hours, and no limit of sustained winds over land.

For person-days exposure, change function calc_tot_exp_pop() to function calc_tot_exp_person_day()

Requirement:
    1. global gridded population dataset from worldpop
    2. global gridded tropical cyclone exposure data
"""

from helper_functions import *

PROCESSER_COUNT = 4  # parallel computing

path_total_exp = './results/total_pop_exp/'  # path to save results

year_list = np.arange(2019, 2001, -1)
wind_cutoff_list = ['ts', 'cat1', 'cat3']
landfall_list = ['all', '6h', '12h']
arg_list = list(itertools.product(year_list, wind_cutoff_list, landfall_list))


def get_landfall_exposure(year: int, wind_stat: str, landfall_cutoff: str):
    """
    Calculates the overall population or person-days exposure for each year across various levels of wind intensity,
    assuming up to 6 hour, 12 hours, and no limit of sustained winds over land.

    Args:
        wind_stat: wind intensity threshold; options are:
            'ts', 'cat1', 'cat2', 'cat3', 'cat4', 'cat5'
        landfall_cutoff: assuming up to 6 hour, 12 hours, and no limit of sustained winds over land; options are:
            '6h', '12h', 'all'
    """
    pop_exp = []
    exp_map = calc_tot_exp_pop(year, wind_stat + '_' + landfall_cutoff)
    # for person-day exposure, change calc_tot_exp_pop to calc_tot_exp_person_day()
    total_pop_exp = np.nansum(exp_map)
    pop_exp.append([year, wind_stat, landfall_cutoff, total_pop_exp])
    exposure_df = pd.DataFrame(pop_exp, columns=['year', 'wind_cutoff', 'landfall_cutoff', 'total_pop'])
    exposure_df.to_csv(
        f'{path_total_exp}/exposure_{year}_{wind_stat}_{landfall_cutoff}.csv',
        index=False)
    print(f'finish: year = {year}, landfall_cutoff = {landfall_cutoff}, windcutoff = {wind_stat}')


def run_parallel_process(operation, input, pool):
    pool.map(operation, input)


def compute_exposure(input_index):
    year = arg_list[input_index][0]
    wind_stat = arg_list[input_index][1]
    landfall_cutoff = arg_list[input_index][2]
    if os.path.isfile(f'{path_total_exp}/exposure_{year}_{wind_stat}_{landfall_cutoff}.csv'):
        print(f'already exist: year = {year}, landfall_cutoff = {landfall_cutoff}, windcutoff = {wind_stat}')
    else:
        print(f'start computing: year = {year}, landfall_cutoff = {landfall_cutoff}, windcutoff = {wind_stat}')
        get_landfall_exposure(year, wind_stat, landfall_cutoff)
        print(f'finish computing year = {year}, wind_stat={wind_stat}')


def main():
    processes_pool = Pool(PROCESSER_COUNT)
    arg = range(len(arg_list))
    run_parallel_process(compute_exposure, arg, processes_pool)


if __name__ == '__main__':
    main()
