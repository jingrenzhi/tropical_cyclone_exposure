# Scripts for Figure4 and Figure ED6
#
# Require:
#   - Country specific relative deprivation index for exposed and unexposed population, computed from script_Figure4.py
#   - Country rdi distribution data is computed from script_FigureED5.py
################################################################################

library(ggplot2)
library(pracma)
library(scales)



# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#           part1: identify small regions
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

country_rdi = NULL
for (country in country_list) {
  if (grepl("/", country)) {
    next
  }
  if (country %in% c(
    'Jersey',
    'Bermuda',
    'Saba (Neth)',
    'Saint Barthelemy (France)',
    'Cook Is.',
    'Niue',
    'Saint Martin (France)',
    'Sint Eustatius (Neth)',
    'Sint Maarten (Neth)',
    'St. Pierre & Miquelon'
  )) {
    next
  }
  country_data = read.csv(
    sprintf(
      './results/country_rdi_distribution/rdi_%s.csv',
      country
    ),
    header = FALSE
  )
  country_data$country = country
  colnames(country_data) = c('rdi', 'country')
  country_rdi = rbind(country_rdi, country_data)
}
small_regions = unique(subset(
  country_rdi %>%
    group_by(country) %>%
    summarise(num_rows = n()) %>% arrange(num_rows),
  num_rows < 8000
)$country)


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#           part2: prepare rdi data
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rdi_full_df = read.csv('./results/country_rdi_exp_unexp_2010_2019.csv')
# subset data: total population >= 10000
rdi_full_df = rdi_full_df[rdi_full_df$total_pop >= 100000, ]
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
rdi = rdi[complete.cases(rdi),]

# select subset data for wind intensity Category 1
rdi_cat1 = rdi[rdi$wind_cutoff == 'cat1_12h', ]

# order by rid ratio
rdi_cat1 <- rdi_cat1[order(rdi_cat1$rdi_rate, decreasing = TRUE), ]
rdi_cat1$rdi_rate = round(rdi_cat1$rdi_rate, 2)

# subset data: remove small countries: Turks and Caicos Is., St. Kitts and Nevis, Virgin
# Is., Samoa, Vanuatu, St. Vincent and the Grenadines, Guadeloupe, British Virgin Is., Martinique,
# Micronesia, Mayotte, Wallis and Futuna, Reunion, American Samoa (Eastern Samoa), French Polynesia,
#Fiji, Macau (China), Hong Kong (China), New Caledonia, Northern Mariana Is.
rdi_cat1 = rdi_cat1[!rdi_cat1$country %in% small_regions,]


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#           part3: plot Figure 4 and Figure ED6
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

options(repr.plot.width = 10, repr.plot.height = 12)
xcoef = 35
ggplot(data = rdi_cat1,
       mapping = aes(
         x = ifelse(
           test = exposed == 'exposed_avg_rdi',
           yes = rdi,
           no = -rdi
         ),
         y = reorder(country, rdi_rate),
         fill = exposed
       )) +
  geom_col(alpha = 0.75, width = 0.75) +
  scale_x_symmetric(
    breaks = c(-100, -50, 0, 50, 100),
    name = "Population-averaged RDI",
    sec.axis = sec_axis(
      ~ . / xcoef + 1,
      name = expression("RDI Ratio"),
      breaks = c(-2, -1, 0, 1, 2, 3, 4)
    )
  ) + 
  geom_point(
    aes(
      x = (rdi_rate - 1) * xcoef,
      y = reorder(country,-rdi_rate)
    ),
    stat = "identity",
    size = 5,
    color = 'white'
  ) +
  scale_fill_manual(values = c("#FF7D58", '#93AD6F')) +
  ylab('Country/Region') +
  theme_classic() +
  theme(
    text = element_text(size = 20),
    legend.position = 'bottom',
    axis.text.x = element_text(size = 20),
    axis.title.x = element_text(size = 20),
    axis.title.y = element_text(size = 20)
  )
