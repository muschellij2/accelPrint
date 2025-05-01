
<!-- README.md is generated from README.Rmd. Please edit that file -->

# accelPrint

<!-- badges: start -->

[![R-CMD-check](https://github.com/lilykoff/accelPrint/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/lilykoff/accelPrint/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of accelPrint is to do fingerprinting for acceleration and
walking.

## Installation

You can install the development version of accelPrint from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("lilykoff/accelPrint")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(accelPrint)
library(ggplot2)
# load example data 
data(raw_accel)
# run the get walking function
walking_bouts = accelPrint::get_walking(raw_accel, parallel = TRUE)
#> Sample rate not provided. Inferred sample rate: 100 Hz
#> Parallel processing is enabled, but cores are not specified. Using all available cores (8)
#> ADEPT completed
head(walking_bouts) 
#> # A tibble: 6 × 6
#>   time                    x      y      z second              bout_seconds
#>   <dttm>              <dbl>  <dbl>  <dbl> <dttm>                     <int>
#> 1 2000-01-01 12:00:01 0.742  0.043 -0.527 2000-01-01 12:00:01          300
#> 2 2000-01-01 12:00:01 0.719  0.07  -0.508 2000-01-01 12:00:01          300
#> 3 2000-01-01 12:00:01 0.707  0.086 -0.504 2000-01-01 12:00:01          300
#> 4 2000-01-01 12:00:01 0.703  0.066 -0.523 2000-01-01 12:00:01          300
#> 5 2000-01-01 12:00:01 0.699  0.02  -0.555 2000-01-01 12:00:01          300
#> 6 2000-01-01 12:00:01 0.703 -0.016 -0.563 2000-01-01 12:00:01          300


# run the get grid cells function on the walking bouts
# specify lags of 0.15, 0.30, 0.45 seconds and grid cell size of 0.25g 
fingerprint_predictors = compute_grid_cells(walking_bouts, 
                                            lags = c(0.15, 0.30, 0.45), 
                                            cell_size = 0.25,
                                            max_vm = 3)
#> Warning in rm(list = c("time", "x", "y", "z", "second", "vm", "second", :
#> object 'second' not found
#> Sample rate not provided. Inferred sample rate: 100 Hz

head(fingerprint_predictors) 
#> # A tibble: 6 × 433
#>   second              `[0,0.25]_[0,0.25]_15` `[0,0.25]_(0.25,0.5]_15`
#>   <dttm>                               <int>                    <int>
#> 1 2000-01-01 12:00:01                      0                        0
#> 2 2000-01-01 12:00:02                      0                        0
#> 3 2000-01-01 12:00:03                      0                        0
#> 4 2000-01-01 12:00:04                      0                        0
#> 5 2000-01-01 12:00:05                      0                        0
#> 6 2000-01-01 12:00:06                      0                        0
#> # ℹ 430 more variables: `[0,0.25]_(0.5,0.75]_15` <int>,
#> #   `[0,0.25]_(0.75,1]_15` <int>, `[0,0.25]_(1,1.25]_15` <int>,
#> #   `[0,0.25]_(1.25,1.5]_15` <int>, `[0,0.25]_(1.5,1.75]_15` <int>,
#> #   `[0,0.25]_(1.75,2]_15` <int>, `[0,0.25]_(2,2.25]_15` <int>,
#> #   `[0,0.25]_(2.25,2.5]_15` <int>, `[0,0.25]_(2.5,2.75]_15` <int>,
#> #   `[0,0.25]_(2.75,3]_15` <int>, `(0.25,0.5]_[0,0.25]_15` <int>,
#> #   `(0.25,0.5]_(0.25,0.5]_15` <int>, `(0.25,0.5]_(0.5,0.75]_15` <int>, …
```
