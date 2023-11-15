# Scripts for Figure ED5
#
# Require:
#   - Country specific relative deprivation index, computed from script_FigureED5.py
################################################################################


library(ggplot2)
library(pracma)
library(scales)



# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#           part1: load data
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

country_exposed = read.csv('./results/country_rdi_exp_unexp_2010_2019.csv')
country_list = unique(subset(country_exposed$country))
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


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#           panel (A):  9 heavily exposed countries/regions
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
selected_country = subset(
  country_rdi,
  country %in% c(
    'China',
    'Japan',
    'United States',
    'Taiwan',
    'Philippines',
    'India',
    'South Korea',
    'Bangladesh',
    'Mexico'
  )
)

options(repr.plot.width = 12, repr.plot.height = 8)
ggplot(selected_country, aes(x = rdi)) +
  geom_histogram(binwidth = 5,
                 fill = "lightblue",
                 color = "black") +
  xlim(0, 100) +
  facet_wrap(~ country, scales = "free") +
  theme_classic() + theme(text = element_text(size = 20)) +
  labs(x = "RDI", y = "Frequency", title = "Distribution of RDI")


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#           panel (B):  countries/regions removed in the RDI analyses
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

selected_small_regions = c(
  'Turks & Caicos Is.',
  'St. Kitts & Nevis',
  'Virgin Is.',
  'Samoa',
  'St. Vincent & the Grenadines',
  'Guadeloupe' ,
  'British Virgin Is.',
  'Martinique',
  'Micronesia',
  'Mayotte',
  'Wallis & Futuna',
  'Reunion',
  'American Samoa (Eastern Samoa)',
  'French Polynesia',
  'Macau (China)',
  'Hong Kong (China)',
  'New Caledonia',
  'Northern Mariana Is.',
  'Fiji',
  'Vanuatu'
)

selected_country = subset(country_rdi,
                          country %in% selected_small_regions)

options(repr.plot.width = 12, repr.plot.height = 8)
ggplot(selected_country, aes(x = rdi)) +
  geom_histogram(binwidth = 5,
                 fill = "lightblue",
                 color = "black") +
  xlim(0, 100) +
  facet_wrap(~ country, scales = "free", ncol = 5) +
  theme_classic() + theme(text = element_text(size = 20),
                          strip.text = element_text(size = 12)) +
  labs(x = "RDI", y = "Frequency", title = "Distribution of RDI")
