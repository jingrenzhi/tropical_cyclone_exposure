# Scripts for Figure2, Figure ED2, Figure ED3 and Figure ED8
#
# Require:
#   - Population and person-days exposure, computed from script_Figure2.py
################################################################################


library(ggplot2)
library(pracma)
library(scales)

# set result path
result_path = './results/total_pop_exp/'


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#           part1: load data
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

total_exp_landfall <- do.call(rbind,
                              lapply(
                                list.files(
                                  path = result_path,
                                  pattern = "*.csv",
                                  full.names = TRUE
                                ),
                                read.csv
                              ))
year_cut = 2002
total_exp_landfall = subset(total_exp_landfall, year >= year_cut)

# reformat data
total_exp_landfall = dcast(setDT(total_exp_landfall),
                           year + wind_cutoff ~ landfall_cutoff,
                           value.var = 'total_pop')
names(total_exp_landfall)[names(total_exp_landfall) == '12h'] <-
  'land_12h'
names(total_exp_landfall)[names(total_exp_landfall) == '6h'] <-
  'land_6h'
names(total_exp_landfall)[names(total_exp_landfall) == 'all'] <-
  'land_all'


# LOESS fitting with degree = 1 and span = 1
df <- as.data.frame(matrix(nrow = 0, ncol = 5))
year_seq = 0.01
degree = 1
span = 1
wlist = c('ts', 'cat1', 'cat3')
for (id in (c(1, 2, 3))) {
  data = total_exp_landfall[total_exp_landfall$wind_cutoff == wlist[id], ]
  # LOESS
  land_12h_model <-
    loess(land_12h ~ year, data, degree = degree, span = span)
  land_12h_pred = predict(land_12h_model, data.frame(year = seq(year_cut, 2019, year_seq)), se = TRUE)$fit
  land_6h_model <-
    loess(land_6h ~ year, data, degree = degree, span = span)
  land_6h_pred = predict(land_6h_model, data.frame(year = seq(year_cut, 2019, year_seq)), se = TRUE)$fit
  land_all_model <-
    loess(land_all ~ year, data, degree = degree, span = span)
  land_all_pred = predict(land_all_model, data.frame(year = seq(year_cut, 2019, year_seq)), se = TRUE)$fit
  
  df = rbind(df,
             data.frame(
               year = seq(year_cut, 2019, year_seq),
               wlist[id],
               land_12h_pred,
               land_6h_pred,
               land_all_pred
             ))
}
names(df) <-
  c('year',
    'wind_cutoff',
    'land_12h_pred',
    'land_6h_pred',
    'land_all_pred')


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#           part2: plot (Tropical Storms)
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

df$wind_cutoff = factor(df$wind_cutoff, levels = c('ts', 'cat1' , 'cat3'))
ggplot(data = df[df$wind_cutoff == 'ts',]) +
  geom_point(
    data = total_exp_landfall[total_exp_landfall$wind_cutoff == 'ts', ],
    aes(x = year, y = land_12h),
    color = "#5773c0",
    alpha = 0.5,
    size = 3
  ) +
  geom_line(aes(x = year, y = land_12h_pred),
            linewidth = 1.5,
            color = "#5773c0") +
  geom_line(
    aes(x = year, y = land_6h_pred),
    linetype = 'dashed',
    linewidth = 0.75,
    color = "#5773c0"
  ) +
  geom_line(
    aes(x = year, y = land_all_pred),
    linetype = 'dotted',
    linewidth = 0.75,
    color = "#5773c0"
  ) +
  scale_y_continuous(
    limit = c(2.8e8, 10e8),
    breaks = c(3e8, 6e8, 9e8),
    labels = c('300',  '600', '900')
  )  +
  theme_classic() + theme(text = element_text(size = 20), legend.position = 'bottom') +
  xlim(2002, 2020) +
  xlab('') + ylab('')


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#           part2: plot (Category 1)
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ggplot(data = df[df$wind_cutoff == 'cat1',]) +
  geom_line(aes(x = year, y = land_12h_pred),
            linewidth = 1.5,
            color = "#7da7ea") +
  geom_point(
    data = total_exp_landfall[total_exp_landfall$wind_cutoff == 'cat1', ],
    aes(x = year, y = land_12h),
    color = "#7da7ea",
    alpha = 0.5,
    size = 3
  ) +
  geom_line(
    aes(x = year, y = land_6h_pred),
    linetype = 'dashed',
    linewidth = 0.75,
    color = "#7da7ea"
  ) +
  geom_line(
    aes(x = year, y = land_all_pred),
    linetype = 'dotted',
    linewidth = 0.75,
    color = "#7da7ea"
  ) +
  scale_y_continuous(
    limit = c(1.2e7, 21.7e7),
    breaks = c(5e7, 10e7, 15e7, 20e7),
    labels = c('050', '100', '150', '200')
  )  +
  theme_classic() + theme(text = element_text(size = 20), legend.position = 'bottom') +
  xlim(2002, 2020) +
  xlab('') + ylab('')


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#           part3: plot (Category 3)
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ggplot(data = df[df$wind_cutoff == 'cat3',]) +
  geom_line(aes(x = year, y = land_12h_pred),
            linewidth = 1.5,
            color = "#edb144") +
  geom_point(
    data = total_exp_landfall[total_exp_landfall$wind_cutoff == 'cat3', ],
    aes(x = year, y = land_12h),
    color = "#edb144",
    alpha = 0.5,
    size = 3
  ) +
  geom_line(
    aes(x = year, y = land_6h_pred),
    linetype = 'dashed',
    linewidth = 0.75,
    color = "#edb144"
  ) +
  geom_line(
    aes(x = year, y = land_all_pred),
    linetype = 'dotted',
    linewidth = 0.75,
    color = "#edb144"
  ) +
  labs(x = "year", y = "population exposure (mi)") +
  scale_y_continuous(
    limit = c(0.2e5, 10e6),
    breaks = c(1e6, 4e6, 7e6, 10e6),
    labels = c('001', '004', '007', '010')
  )  +
  theme_classic() + theme(text = element_text(size = 20), legend.position = 'bottom') + xlim(2002, 2020) +
  xlab('') + ylab('')
