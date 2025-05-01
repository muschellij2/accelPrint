testthat::test_that("compute_grid_cells returns correct structure", {
  # Simulate 2 seconds of 80Hz data
  set.seed(123)
  sim_data <- data.frame(
    time = seq.POSIXt(from = as.POSIXct("2020-01-01 00:00:00"),
                      by = 1/80, length.out = 160),
    x = rnorm(160),
    y = rnorm(160),
    z = rnorm(160)
  )

  result <- compute_grid_cells(data = sim_data, lag = c(0.1, 0.15), cell_size = 0.25)

  expect_s3_class(result, "data.frame")
  expect_true("second" %in% names(result))
  expect_gt(ncol(result), 3)
})
