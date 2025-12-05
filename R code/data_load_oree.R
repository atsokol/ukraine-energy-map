library(httr)
library(readxl)
library(dplyr)
library(tidyr)
library(purrr)
library(readr)
library(lubridate)

base_url <- "https://www.oree.com.ua/index.php/pricectr/get_file"

download_month <- function(month_date,
                           market_type = "DAM",
                           zone = "IPS") {
  
  price_date <- format(month_date, "%m.%Y")   # e.g. "12.2025"
  message("Downloading ", price_date, " (", market_type, ", ", zone, ")")
  
  resp <- POST(
    base_url,
    body   = list(
      price_date  = price_date,
      market_type = market_type,
      zone        = zone
    ),
    encode = "form"
  )
  stop_for_status(resp)
  
  tf <- tempfile(fileext = ".xls")
  writeBin(content(resp, "raw"), tf)
  
  # ---- READ XLS WITH GIVEN STRUCTURE ----
  # Row 1: skip
  # Row 2: colnames
  # Row 3: skip
  # Row 4+: data (days in col 1, hours in cols 2..)
  
  wide_raw <- read_xls(
    tf,
    col_names = FALSE,  # we’ll promote row manually
    skip      = 1       # skip row 1
  )
  
  # Promote first row to header (original row 2)
  colnames(wide_raw) <- as.character(unlist(wide_raw[1, ]))
  
  # Drop this header row and next row (original row 3)
  wide <- wide_raw[-c(1, 2), ]
  
  # First column: day of month
  wide <- wide %>%
    rename(day = 1) %>%
    mutate(day = as.integer(day)) %>%
    filter(!is.na(day))
  
  # Extract year and month from "MM.YYYY"
  ym <- strsplit(price_date, ".", fixed = TRUE)[[1]]
  mm <- as.integer(ym[1])
  yy <- as.integer(ym[2])
  
  # Identify hour columns: everything except 'day'
  hour_cols <- setdiff(names(wide), "day")
  
  # 👉 Force all hour columns to numeric to avoid type mixing
  wide <- wide %>%
    mutate(
      across(all_of(hour_cols),
             ~ suppressWarnings(as.numeric(.)))
    )
  
  # Long format: date, hour, price
  long <- wide %>%
    pivot_longer(
      cols      = all_of(hour_cols),
      names_to  = "hour",
      values_to = "price"
    ) %>%
    mutate(
      hour = as.integer(hour),
      date = as.Date(sprintf("%04d-%02d-%02d", yy, mm, day))
    ) %>%
    select(date, hour, price) %>%
    arrange(date, hour)
  
  long
}

start_month <- as.Date("2020-01-01")
end_month   <- as.Date(format(Sys.Date(), "%Y-%m-01"))
month_seq   <- seq(start_month, end_month, by = "month")

prices_long <- map_dfr(
  month_seq,
  ~ tryCatch(
    download_month(.x, market_type = "DAM", zone = "IPS"),
    error = function(e) {
      warning("Failed for ", format(.x, "%m.%Y"), ": ", e$message)
      NULL
    }
  )
)

write_csv(prices_long, "data/outputs/DAM prices hourly OREE.csv")