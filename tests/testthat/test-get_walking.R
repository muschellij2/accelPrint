testthat::test_that("get_walking", {
  # Simulate 120 seconds of 80Hz data
  set.seed(123)
  sim_data <- data.frame(
    time = seq.POSIXt(from = as.POSIXct("2020-01-01 00:00:00"),
                      by = 1/80, length.out = 120 * 80),
    x = rnorm(160),
    y = rnorm(160),
    z = rnorm(160)
  )

  result <- get_walking(data = sim_data, parallel = TRUE)

  expect_s3_class(result, "data.frame")
  expect_true("second" %in% names(result))
  expect_gt(ncol(result), 1)
})
