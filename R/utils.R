#' Mode function
#'
#' A simple mode function that returns the most frequent value.
#' @noRd
Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}
