library(jsonlite)
library(httr)
library(readr)
library(lubridate)
library(dplyr)

source("R code/helper_functions.R")

headers <- c(
  Authorization = paste("Token", Sys.getenv("ENERGYMAP_KEY"))
)

base_url <- "https://energy-map.info/api/v1/resources/"
uuid <- "c6218b35-ce7e-45c2-925e-5c8e6f5eb9fb" #uuid ресурсу
full_url <- paste0(base_url, uuid, "/download/")
params <- list(
  format = "csv", 
  language = "uk" 
)

#GET-запит
response <- GET(full_url, add_headers(headers), query = params)

#дані у форматі data.frame
price_dam <- read.csv(text = rawToChar(response$content))

write_csv(price_dam, "data/outputs/DAM_prices.csv")

dates <- c(ymd("2018/01/01"), Sys.Date()) |> format("%Y%m%d")

# Get data and convert to xts object
fx <- get_exchange_rate_date_range_currency(dates[1],dates[2], 'EUR') %>% 
  as_tibble()

write_csv(fx, "data/outputs/UAHEUR_rate.csv")