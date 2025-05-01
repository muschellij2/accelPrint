#' Generate Grid Cell Predictors from Accelerometry Data
#'
#' This function processes raw accelerometry data and creates predictors
#' using a grid-based approach with optional lagging.
#'
#' @importFrom dplyr mutate select ungroup group_by count sym n filter count pull lag
#' @importFrom lubridate floor_date
#' @importFrom assertthat assert_that
#' @importFrom tidyr drop_na pivot_wider
#' @importFrom stats time
#' @importFrom purrr map_dfr
#'
#' @param data A data frame with accelerometry values (e.g., x, y, z, and time)
#' @param cell_size Size of each grid cell in whatever units you're using
#' @param lags vector of lag values in seconds
#' @param max_vm maximum vector magnitude for grid cells to be calculated on
#' @param sample_rate optional specification of sample rate (samples per sec), if not specified will be inferred
#' @return A data frame of predictors derived from the grid
#' @export
#'
compute_grid_cells = function(data, lags, cell_size = 0.25, max_vm = 3, sample_rate = NULL) {

  x = y = z = second = vm = NULL
  second = cut_sig = cut_lagsig = cell = NULL
  rm(list = c("x",
              "y",
              "z",
              "second",
              "vm",
              "second",
              "cut_sig",
              "cut_lagsig",
              "cell"))

  # check that data is a data frame
  assertthat::assert_that(
    is.data.frame(data),
    msg = "Data must be a data frame."
  )

  # check that the max VM is a multiple of the grid cell size, if not, adjust max VM
  if (max_vm %% cell_size != 0) {
    multiples = ceiling(max_vm / cell_size)
    max_vm = cell_size * multiples
    warning(sprintf(
      "Max VM is not a multiple of the grid cell size. Adjusted max VM to: %s",
      max_vm
    ))
  }

  # check that lags are less than 1
  assertthat::assert_that(all(lags < 1) & all(lags > 0), msg = "Lags must be positive and less than 1 second")

  # make column names lowercase
  colnames(data) <- tolower(colnames(data))

  # check for time column
  time_col <- colnames(data)[grepl("time", colnames(data))]
  assertthat::assert_that(length(time_col) == 1, msg = "Data must have exactly one column containing 'time'.")
  data <- data %>% dplyr::rename(time = !!dplyr::sym(time_col))

  # check for x,y,z columns in data
  assertthat::assert_that(all(c("x", "y", "z") %in% colnames(data)), msg = "Data must contain x, y, and z columns (case-insensitive).")

  # check for vm column, if it doesn't exist, create it
  if (!"vm" %in% colnames(data)) {
    data <- data %>%
      dplyr::mutate(vm = sqrt(x^2 + y^2 + z^2))
  }

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

  # lags are lag (in seconds) * samples per second
  lags_samples = lags * sample_rate

  # check that lags are integers, if not, round them
  if(!all(lags_samples%%1 == 0)){
    lags_samples = round(lags_samples, 0)
    warning(sprintf(
      "Some lags multiplied by sample rate were not integers. Rounded to: %s",
      paste(lags_samples, collapse = ", ")
    ))
  }

  assertthat::assert_that(
    all(lags_samples < sample_rate),
    msg = "Lags mutliplied by sample rate must be less than sample rate."
  )

  # filter out seconds that don't have the full # of samples
  data <- data %>%
    dplyr::group_by(second) %>%
    dplyr::mutate(n = dplyr::n()) %>%
    dplyr::filter(n == sample_rate) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      cut_sig = cut(
        vm,
        breaks = seq(0, max_vm, by = cell_size),
        include.lowest = TRUE
      ))

  assertthat::assert_that(
    nrow(data) > 0,
    msg = "No complete seconds found in data. Please check your sample rate and data."
  )


  result =
    purrr::map_dfr(.x = lags_samples,
            .f = function(lag){
              data %>%
                dplyr::group_by(second) %>%
                dplyr::mutate(cut_lagsig = dplyr::lag(cut_sig, n = lag)) %>%   # for each second, calculate vm and lagged vm
                dplyr::ungroup() %>%
                tidyr::drop_na() %>% # count # points in each "grid cell"
                dplyr::count(second, cut_sig, cut_lagsig, .drop = FALSE) %>%
                dplyr::mutate(cell = paste0(cut_sig, "_", cut_lagsig, "_", lag)) %>%
                dplyr::select(n, second, cell)

            })
  res =
    result %>%
    tidyr::pivot_wider(names_from = cell, values_from = n)
  return(res)
}

