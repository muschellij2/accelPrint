#' Example sample dataset
#'
#' A dataset included in accelPrint to illustrate usage.
#'
#' @format A data frame with N rows and M columns:
#' \describe{
#'   \item{x}{Numeric. X-axis value.}
#'   \item{y}{Numeric. Y-axis value.}
#'   \item{z}{Numeric. Z-axis value.}
#'   \item{time}{POSIXct. Time stamp.}
#' }
#' @source Simulated data or citation if applicable
"sample_df"

#' Example accelerometry dataset
#'
#' A dataset included in accelPrint to illustrate usage.
#' Raw 100 Hz accelerometry data from one subject is downloaded from Physionet https://physionet.org/content/accelerometry-walk-climb-drive/1.0.0/raw_accelerometry_data/
#' The first 5 minutes are provided as an example
#'
#' @format A data frame with N rows and M columns:
#' \describe{
#'   \item{time}{POSIXct. Time stamp.}
#'   \item{x}{Numeric. X-axis value in g}
#'   \item{y}{Numeric. Y-axis value in g}
#'   \item{z}{Numeric. Z-axis value in g}
#' }
#' @source Karas, M., Urbanek, J., Crainiceanu, C., Harezlak, J., & Fadel, W. (2021). Labeled raw accelerometry data captured during walking, stair climbing and driving (version 1.0.0). PhysioNet. https://doi.org/10.13026/51h0-a262.
"raw_accel"

#' Example walking accelerometry dataset
#'
#' A dataset included in accelPrint to illustrate usage.
#' This dataset is the result of running the get_walking function on raw_accel
#'
#' @format A data frame with N rows and M columns:
#' \describe{
#'   \item{time}{POSIXct. Time stamp.}
#'   \item{x}{Numeric. X-axis value in g}
#'   \item{y}{Numeric. Y-axis value in g}
#'   \item{z}{Numeric. Z-axis value in g}
#'   \item{second}{POSIXct. Time stamp in seconds}
#'   \item{bout_seconds}{Numeric, number of seconds in walking bout}
#' }
#' @source Karas, M., Urbanek, J., Crainiceanu, C., Harezlak, J., & Fadel, W. (2021). Labeled raw accelerometry data captured during walking, stair climbing and driving (version 1.0.0). PhysioNet. https://doi.org/10.13026/51h0-a262.
"walking_data"
