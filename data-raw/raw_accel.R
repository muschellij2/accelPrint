library(dplyr)
options(digits.secs = 3)

# download the raw data for one subject from Physionet accelerometry
data = readr::read_csv("https://physionet.org/files/accelerometry-walk-climb-drive/1.0.0/raw_accelerometry_data/id7c20ee7a.csv?download")

# take first 5 min of data and add timestamp
raw_accel = data %>%
  filter(time_s <= (5 * 60)) %>%
  mutate(time = as.POSIXct("2000-01-01 12:00:00", tz = "UTC") + lubridate::as.period(time_s, units = "seconds")) %>%
  select(time,
         x = lw_x,
         y = lw_y,
         z = lw_z)

usethis::use_data(raw_accel, overwrite = TRUE)
