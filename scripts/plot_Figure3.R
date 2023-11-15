# Script for Fig 3 and Fig ED4
#
# Require:
#   - Age distribution of exposed and unexposed population, computed from script_Figure3.py
################################################################################


library(ggplot2)
library(pracma)
library(scales)


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#           part1: load data
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ggridge_data <- do.call(rbind,
                        lapply(
                          list.files(
                            path = "./results/age_gender_exp/",
                            pattern = "*.csv",
                            full.names = TRUE
                          ),
                          read.csv
                        ))
ggridge_data = subset(
  ggridge_data,!continent %in% c('Antarctica', 'Australia', 'South America') &
    age > 0 & age <= 75 & year >= 2002
)

# compare the periods 2002-2006 with 2015- 2019
ggridge_data_yearblock = ggridge_data %>%
  mutate(year_block = case_when(
    year <= 2006 ~ "early",
    year >= 2015 ~ "late",
    year > 2006 & year < 2015 ~ "mid",
  ))
ggridge_data_yearblock = ggridge_data_yearblock[c('continent', 'age', 'gender', 'pop_exp', 'year_block')]

# calculate the probability density distribution for different age groups by dividing the population of each age group by the total population.
total_pop_group = ggridge_data_yearblock %>%
  group_by(year_block, continent) %>%
  summarise(total_pop = sum(pop_exp))
age_total_pop = ggridge_data_yearblock %>%
  group_by(year_block, continent, age) %>%
  summarise(age_total_pop = sum(pop_exp))

total_data = merge(age_total_pop,
                   total_pop_group,
                   by = c('year_block', 'continent'))
total_data$pct = total_data$age_total_pop / total_data$total_pop

total_data$continent = factor(
  total_data$continent,
  levels = c('Oceania', 'Europe', 'Africa',  'North America', 'Asia', 'all')
)
total_data$year_block = factor(total_data$year_block)


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#           part2: plot
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

options(repr.plot.width = 6, repr.plot.height = 12)
ggplot() +
  geom_density(
    data = total_data[!total_data$year_block %in% 'mid',],
    aes(
      x = age,
      y = pct * 100,
      fill = year_block,
      color = year_block
    ),
    stat = 'identity',
    size = 1
  ) +
  facet_wrap(continent ~ ., scale = 'free', ncol = 1) +
  scale_x_continuous(expand = c(0, 0)) +
  scale_fill_manual(values = c("#D55E0050", "#0072B250"),
                    labels = c('early', 'late')) +
  scale_color_manual(values = c("#D55E00", "#0072B2"), guide = "none") +
  coord_cartesian(clip = "off")  +
  labs(x = "Age",
       y = "Continent", ) +
  guides(fill = guide_legend(
    title = 'year',
    override.aes = list(
      fill = c("#D55E00A0", "#0072B2A0"),
      color = NA,
      point_color = NA
    )
  )) + theme_classic() +
  theme(text = element_text(size = 20), legend.position = 'bottom')
