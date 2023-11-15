# Scripts for Figure 5 and Figure ED7
#
# Require:
#   - Country specific relative deprivation index for exposed and unexposed population, computed from script_Figure4.py
################################################################################

library(ggplot2)

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#           part1: load data
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rdi_full_df = read.csv('./results/country_rdi_exp_unexp_2010_2019.csv')
# subset data: total population >= 10000
rdi_full_df = rdi_full_df[rdi_full_df$total_pop >= 100000,]
# compute rdi ratio between exposed and unexposed population
rdi_full_df$rdi_rate = rdi_full_df$exposed_avg_rdi / rdi_full_df$unexposed_avg_rdi

# reformat data
rdi = melt(
  rdi_full_df[c(
    'country',
    'wind_cutoff',
    'total_pop',
    'avg_rdi',
    'exposed_avg_rdi',
    'unexposed_avg_rdi',
    'rdi_rate'
  )],
  na.rm = FALSE,
  value.name = 'rdi',
  variable.name = c('exposed'),
  id = c('country', 'wind_cutoff', 'total_pop', 'avg_rdi', 'rdi_rate')
)
rdi = rdi[complete.cases(rdi), ]

# prepare data for box plot
rdi_box = rdi[c('country', 'wind_cutoff', 'rdi_rate')]
rdi_box = distinct(rdi_box)
rdi_box$wind_cutoff = factor(
  rdi_box$wind_cutoff,
  levels = c(
    'ts_12h',
    'cat1_12h',
    'cat2_12h',
    'cat3_12h',
    'cat4_12h',
    'cat5_12h'
  )
)
rdi_box = rdi_box[rdi_box$wind_cutoff != 'td_12h', ]  # remove wind level of Tropical Depression


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#           part2: plot
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

options(repr.plot.width = 10, repr.plot.height = 5)
nizami = c("#b83326",
           "#dd7867",
           "#edb144",
           "#8cc8bc",
           "#7da7ea",
           "#5773c0")

ggplot(data = rdi_box, aes(x = wind_cutoff, y = rdi_rate, color = wind_cutoff)) +
  geom_boxplot(size = 1, width = 0.6) +
  stat_summary(fun.y = mean) +
  theme_classic() +
  theme(
    axis.title.x = element_text(size = 15),
    axis.title.y = element_text(size = 18),
    legend.title = element_text(size = 15),
    legend.text = element_text(size = 18),
    axis.text.x =  element_text(size = 15),
    axis.text.y =  element_text(size = 18)
  ) +
  scale_fill_manual(values = alpha(rev(nizami), 0.75)) +
  scale_color_manual(values = alpha(rev(nizami), 0.75)) +
  ylab('RDI Ratio') + xlab('TC wind') + coord_cartesian(ylim = c(0.75, 1.8)) +
  theme(
    text = element_text(size = 20),
    axis.text.x = element_text(size = 20),
    axis.title.x = element_text(size = 20),
    axis.title.y = element_text(size = 20)
  )