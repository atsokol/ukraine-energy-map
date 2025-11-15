library(jsonlite)
library(httr)
library(readr)
library(lubridate)
library(dplyr)

source("R code/helper_functions.R")

headers <- c(
  Authorization = paste("Token", Sys.getenv("ENERGYMAP_KEY"))
)

input_csv  <- "data/inputs/uiid codes.csv"
output_dir <- "data/outputs"

resources <- read_csv(input_csv, show_col_types = FALSE)

base_url <- "https://energy-map.info/api/v1/resources/"

for (i in seq_len(nrow(resources))) {
  this_uiid  <- resources$uiid[i]
  this_name  <- resources$file[i]
  
  full_url <- paste0(base_url, this_uiid, "/download/")
  
  params <- list(
    format   = "csv",
    language = "uk"
  )
  
  resp <- GET(full_url, add_headers(headers), query = params)
  
  # Check for HTTP errors
  if (http_error(resp)) {
    warning("Failed to download UIID ", this_uuid,
            " (HTTP ", status_code(resp), "). Skipping.")
    next
  }
  
  # Read CSV content into data.frame
  price_df <- read.csv(text = rawToChar(resp$content))
  
  # Build output path using file_name from the CSV
  out_path <- file.path(output_dir, paste0(this_name, ".csv"))
  
  write_csv(price_df, out_path)
  
  message("Saved: ", out_path)
}

# Download FX data
dates <- c(ymd("2018/01/01"), Sys.Date()) |> format("%Y%m%d")

# Get data and convert to xts object
fx <- get_exchange_rate_date_range_currency(dates[1],dates[2], 'EUR') %>% 
  as_tibble()

write_csv(fx, "data/outputs/UAHEUR_rate.csv")