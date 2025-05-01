#' Generate Grid Cell Predictors from Accelerometry Data
#'
#' This function processes raw accelerometry data and creates predictors
#' using a grid-based approach with optional lagging.
#'
#' @importFrom dplyr mutate select ungroup group_by count sym n filter count lag rename join_by inner_join
#' @importFrom lubridate floor_date
#' @importFrom assertthat assert_that
#' @importFrom stats time
#' @importFrom adept segmentWalking
#' @importFrom adeptdata stride_template
#' @importFrom parallelly availableCores
#' @importFrom data.table rleid
#'
#' @param data A data frame with accelerometry values (e.g., x, y, z, and time)
#' @param sample_rate optional specification of sample rate (samples per sec), if not specified will be inferred
#' @param template_list optional list of template with which to perform walking segmentation, if not specified will be all left wrist templates from adeptdata package
#' @param parallel logical. If TRUE, will run in parallel using all available cores
#' @param cores number of cores to use for parallel processing. If NULL and parallel is TRUE will use all available cores
#' @param sample_rate optional specification of sample rate (samples per sec), if not specified will be inferred
#' @param sim_min ADEPT parameter sim_MIN, default 0.6
#' @param dur_min ADEPT parameter dur_MIN, default 0.8
#' @param dur_max ADEPT parameter dur_MAX, default 1.4
#' @param ptp_r_min ADEPT parameter ptp_r_MIN, default 0.5
#' @param ptp_r_max ADEPT parameter ptp_r_MAX, default 2
#' @param vmc_r_min ADEPT parameter vmc_r_MIN, default 0.05
#' @param vmc_r_max ADEPT parameter vmc_r_MAX, default 0.5
#' @param mean_abs_diff_med_p_max ADEPT parameter mean_abs_diff_med_p_MAX, default 0.7
#' @param mean_abs_diff_med_t_max ADEPT parameter mean_abs_diff_med_t_MAX, default 0.2
#' @param mean_abs_diff_dur_max ADEPT parameter mean_abs_diff_dur_MAX, default 0.3
#' @return A data frame of sub-second data from walking bouts only
#' @export
#'
get_walking = function(data,
                       sample_rate = NULL,
                       template_list = NULL,
                       parallel = FALSE,
                       cores = NULL,
                       sim_min = 0.6,
                       dur_min = 0.8,
                       dur_max = 1.4,
                       ptp_r_min = 0.5,
                       ptp_r_max = 2,
                       vmc_r_min = 0.05,
                       vmc_r_max = 0.5,
                       mean_abs_diff_med_p_max = 0.7,
                       mean_abs_diff_med_t_max = 0.2,
                       mean_abs_diff_dur_max = 0.3

) {
  second = x = y = z = is_walking_i = NULL
  T_i = tau_i = steps = timediff = ltwosec = n_seconds = NULL
  rm(list = c("second",
              "x",
              "y",
              "z",
              "is_walking_i",
              "T_i",
              "tau_i",
              "steps",
              "timediff",
              "ltwosec",
              "n_seconds"))
  # check that data is a data frame
  assertthat::assert_that(
    is.data.frame(data),
    msg = "Data must be a data frame."
  )

  if(!is.null(cores)) cores = round(cores, 0)
  # make sure cores is number not sure how to do this exactly
  assertthat::assert_that(is.null(cores) || is.numeric(cores),
                          msg = "Cores must be NULL or numeric")
  # assertthat::assert_that(if(!is.null(cores)){is.numeric(cores)}, msg = "Cores must be NULL or numeric")
  # make column names lowercase
  colnames(data) <- tolower(colnames(data))

  # check for time column
  time_col <- colnames(data)[grepl("time", colnames(data))]
  assertthat::assert_that(length(time_col) == 1, msg = "Data must have exactly one column containing 'time'.")
  data <- data %>% dplyr::rename(time = !!dplyr::sym(time_col))

  # check for x,y,z columns in data
  assertthat::assert_that(all(c("x", "y", "z") %in% colnames(data)), msg = "Data must contain x, y, and z columns (case-insensitive).")


  # add seconds column
  data <- data %>%
    dplyr::mutate(second = lubridate::floor_date(time, unit = "seconds"))


  # infer sample rate if not provided
  # see if there's an attribute (if gt3x file)
  if(is.null(sample_rate)) {
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

  # check that sample rate is integer
  assertthat::assert_that(sample_rate%%1 == 0, msg = "Sample rate must be an integer.")

  ### need to add some checks?
  # if no templates provided, use left wrist templates
  if(is.null(template_list)){
    all_wrist_templates = adeptdata::stride_template$left_wrist
    template_list = do.call(rbind, all_wrist_templates)
    template_list = apply(template_list, 1, identity, simplify = FALSE)
  }

  if(is.null(cores) & parallel){
    message(sprintf("Parallel processing is enabled, but cores are not specified. Using all available cores (%s) ", parallelly::availableCores()))
    cores = parallelly::availableCores()
  }
  if(!is.null(cores) & !parallel){
    message("Parallel processing is not enabled, but cores are specified. Ignoring cores.")
    cores = NULL
  }
  if(!is.null(cores) && cores > parallelly::availableCores()){
    message(sprintf("Number of cores specified (%s) is greater than available cores (%s). Using all available cores.", cores, parallelly::availableCores()))
    cores = NULL
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
    mean_abs_diff_dur_MAX = mean_abs_diff_dur_max)

  message("ADEPT completed")

  step_result = walk_out %>%
    # all steps where walking == 0 are set to zero!
    dplyr::filter(is_walking_i == 1) %>%
    dplyr::mutate(steps = 2 / (T_i / sample_rate))

  if(nrow(step_result) == 0){
    message("No steps detected.")
    return(data.frame())
  }

  steps_bysecond = data %>%
      dplyr::mutate(tau_i = dplyr::row_number()) %>%
      dplyr::left_join(step_result, by = dplyr::join_by(tau_i)) %>%
      dplyr::mutate(
        steps = ifelse(is.na(steps), 0, steps),
        second = lubridate::floor_date(time, unit = "seconds")) %>%
      dplyr::group_by(second) %>%
      dplyr::summarize(steps = sum(steps), .groups = "drop")

    bouts = steps_bysecond %>%
      dplyr::select(second) %>%
      dplyr::distinct() %>%
      dplyr::mutate(timediff = as.numeric(difftime(second, dplyr::lag(second, n = 1), units = "secs")),
             ltwosec = (timediff <= 2)*1,
             rleid = data.table::rleid(ltwosec)) %>%
      dplyr::filter(ltwosec == 1) %>%
      dplyr::group_by(rleid) %>%
      dplyr::mutate(n_seconds = dplyr::n(),
             start = min(second),
             end = max(second)) %>%
      dplyr::ungroup() %>%
      dplyr::filter(n_seconds >= 10) %>%
      dplyr::select(second, bout_seconds = n_seconds)

    if(nrow(bouts) ==0){
      message("No bouts of at least 10s in length detected")
      return(data.frame())
    }


    subsecond_return =
      data %>%
      dplyr::inner_join(bouts, by = dplyr::join_by("second"))
    return(subsecond_return)



}

