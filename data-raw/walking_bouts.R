library(dplyr)
options(digits.secs = 3)

# download the raw data for one subject from Physionet accelerometry
data = readr::read_csv("https://physionet.org/files/accelerometry-walk-climb-drive/1.0.0/raw_accelerometry_data/id7c20ee7a.csv?download")

# take first 5 min of data and add timestamp
data = data %>%
  filter(time_s <= (5 * 60)) %>%
  mutate(time = as.POSIXct("2000-01-01 12:00:00", tz = "UTC") + lubridate::as.period(time_s, units = "seconds")) %>%
  select(time,
         x = lw_x,
         y = lw_y,
         z = lw_z)


sample_rate = NULL
template_list = NULL
parallel = TRUE
cores = NULL
sim_min = 0.6
dur_min = 0.8
dur_max = 1.4
ptp_r_min = 0.5
ptp_r_max = 2
vmc_r_min = 0.05
vmc_r_max = 0.5
mean_abs_diff_med_p_max = 0.7
mean_abs_diff_med_t_max = 0.2
mean_abs_diff_dur_max = 0.3


colnames(data) <- tolower(colnames(data))

# check for time column
time_col <- colnames(data)[grepl("time", colnames(data))]

data <- data %>% dplyr::rename(time = !!dplyr::sym(time_col))


# add seconds column
data <- data %>%
  dplyr::mutate(second = lubridate::floor_date(time, unit = "seconds"))


# infer sample rate if not provided
# see if there's an attribute (if gt3x file)
if (is.null(sample_rate)) {
  obs_per_sec =
    data %>%
    dplyr::mutate(second = lubridate::floor_date(time, unit = "seconds")) %>%
    dplyr::count(second) %>%
    dplyr::pull(n)
  sample_rate = Mode(obs_per_sec)
  message(sprintf(
    "Sample rate not provided. Inferred sample rate: %s Hz",
    sample_rate
  ))
}
if (is.null(template_list)) {
  all_wrist_templates = adeptdata::stride_template$left_wrist
  template_list = do.call(rbind, all_wrist_templates)
  template_list = apply(template_list, 1, identity, simplify = FALSE)
}

if (is.null(cores) & parallel) {
  message(
    sprintf(
      "Parallel processing is enabled, but cores are not specified. Using all available cores (%s) ",
      parallelly::availableCores()
    )
  )
  cores = parallelly::availableCores()
}



walk_out = adept::segmentWalking(
  xyz = data %>% dplyr::select(x, y, z),
  xyz.fs = sample_rate,
  template = template_list,
  run.parallel = parallel,
  run.parallel.cores = cores,
  # Optimized parameter setting
  sim_MIN = sim_min,
  dur_MIN = dur_min,
  dur_MAX = dur_max,
  ptp_r_MIN = ptp_r_min,
  ptp_r_MAX = ptp_r_max,
  vmc_r_MIN = vmc_r_min,
  vmc_r_MAX = vmc_r_max,
  mean_abs_diff_med_p_MAX = mean_abs_diff_med_p_max,
  mean_abs_diff_med_t_MAX = mean_abs_diff_med_t_max,
  mean_abs_diff_dur_MAX = mean_abs_diff_dur_max
)



step_result = walk_out %>%
  # all steps where walking == 0 are set to zero!
  dplyr::filter(is_walking_i == 1) %>%
  dplyr::mutate(steps = 2 / (T_i / sample_rate))


steps_bysecond = data %>%
  dplyr::mutate(tau_i = dplyr::row_number()) %>%
  dplyr::left_join(step_result, by = dplyr::join_by(tau_i)) %>%
  dplyr::mutate(
    steps = ifelse(is.na(steps), 0, steps),
    second = lubridate::floor_date(time, unit = "seconds")
  ) %>%
  dplyr::group_by(second) %>%
  dplyr::summarize(steps = sum(steps), .groups = "drop")

bouts = steps_bysecond %>%
  dplyr::select(second) %>%
  dplyr::distinct() %>%
  dplyr::mutate(
    timediff = as.numeric(difftime(second, dplyr::lag(second, n = 1), units = "secs")),
    ltwosec = (timediff <= 2) * 1,
    rleid = data.table::rleid(ltwosec)
  ) %>%
  dplyr::filter(ltwosec == 1) %>%
  dplyr::group_by(rleid) %>%
  dplyr::mutate(
    n_seconds = dplyr::n(),
    start = min(second),
    end = max(second)
  ) %>%
  dplyr::ungroup() %>%
  dplyr::filter(n_seconds >= 10) %>%
  dplyr::select(second, bout_seconds = n_seconds)



walking_data =
  data %>%
  dplyr::inner_join(bouts, by = dplyr::join_by("second"))

usethis::use_data(walking_data, overwrite = TRUE)

