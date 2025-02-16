#### Preamble ####
# Purpose: Fits a Bayesian logistic regression model to predict whether a garden is large.
# Author: Aliza Abbas Mithwani
# Date: 3 December 2024
# Contact: aliza.mithwani@mail.utoronto.ca
# License: MIT
# Pre-requisites:
# - The `tidyverse`, `rstanarm`, and `arrow` packages must be installed and loaded
# - 02-download_data.R and 03-clean_data.R must have been run
# Any other information needed? Make sure you are in the `PollinateTO` rproj

#### Workspace setup ####
library(tidyverse)
library(rstanarm)
library(arrow)

# Load dataset
PT_analysis_data <- read_parquet("./data/02-analysis_data/PT_analysis_data.parquet")


# Prepare the data
PT_analysis_data <- PT_analysis_data %>%
  mutate(is_large_garden = ifelse(estimated_garden_size > mean(estimated_garden_size, na.rm = TRUE), 1, 0)) %>% # In binary form
  mutate(
    garden_type = as.factor(garden_type),
    ward_name = as.factor(ward_name),
    is_indigenous_garden = as.factor(is_indigenous_garden),
    nia_or_en = as.factor(nia_or_en),
    year_funded = as.numeric(year_funded) # Treated as continuous
  )

# Fit a Bayesian logistic regression model using rstanarm
large_garden_model <- stan_glm(
  is_large_garden ~ garden_type * nia_or_en + year_funded + is_indigenous_garden + ward_name, # Adding interaction between garden_type and nia_or_en
  family = binomial(link = "logit"),
  data = PT_analysis_data,
  prior = normal(location = 0, scale = 2.5, autoscale = TRUE), # Stronger normal priors
  prior_intercept = normal(location = 0, scale = 2.5, autoscale = TRUE), # Stronger prior on intercept
  prior_aux = exponential(rate = 1),  # Regularizing the auxiliary parameters (error terms)
  seed = 522,
  chains = 4,  # Ensure more sampling chains
  iter = 2000  # Set enough iterations for convergence
)

#### Save model ####
saveRDS(
  large_garden_model,
  file = "./models/large_garden_model.rds"
)
