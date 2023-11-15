# Scripts for Figure ED1
#
# Require:
#   - population exposure of each continent during 2002 and 2019, computed from script_FigureED1.py
################################################################################

library(ggplot2)
library(pracma)
library(scales)

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#           part1: prepare data
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

continent_exp = read_csv('./results/exposure_population_data.csv')
df <- as.data.frame(matrix(nrow = 0, ncol = 5))
year_seq = 0.01
clist = c('all', 'Africa', 'Asia', 'North America', 'Oceania',  'Europe')

# LOESS fitting with degree = 1 and span = 1
for (id in (c(1, 2, 3, 4, 5, 6))) {
  data = continent_exp[continent_exp$continent == clist[id],]
  # LOESS
  continent_model <-
    loess(pop_exp ~ year, data, degree = 1, span = 1)
  continent_model_pred = predict(continent_model, data.frame(year = seq(2002, 2019, year_seq)), se = TRUE)$fit
  df = rbind(df, data.frame(year = seq(2002, 2019, year_seq), clist[id], continent_model_pred))
}
names(df) <- c('year', 'continent',  'exposure')


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#           part2: plot
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

options(repr.plot.width = 12, repr.plot.height = 6)
df$continent = factor(df$continent,
                      levels = c('all', 'Asia', 'North America', 'Africa',  'Europe', 'Oceania'))
ggplot(data = df) +
  geom_line(aes(
    x = year,
    y = exposure,
    group = factor(continent),
    color = factor(continent)
  ),
  linewidth = 1.5) +
  labs(x = "year",
       y = "population exposure (mi)", ) +
  scale_y_log10(
    limit = c(1e5, 1e9),
    breaks = c(1e5, 1e6, 1e7, 1e8, 1e9),
    labels = c('0.1', '1', '10', '100', '1000')
  )  + scale_fill_discrete(name = 'wind threshold') +
  scale_color_manual(
    values = c(
      'all' = "black",
      'Asia' = '#ffbb44',
      'North America' = '#ee8577',
      'Africa' = '#c969a1',
      'Europe' = '#859b6c',
      'Oceania' = '#62929a'
    )
  ) +
  theme_classic() + xlim(2002, 2020) +
  theme(text = element_text(size = 22), legend.position = 'bottom')