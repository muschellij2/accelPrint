## code to prepare `sample_df` dataset goes here
library(dplyr)
options(digits.secs = 3)
sample_df = readr::read_csv(here::here("data-raw", "accel_sample.csv.gz")) %>%
  select(-time_s) %>%
  ungroup()

usethis::use_data(sample_df, overwrite = TRUE)
