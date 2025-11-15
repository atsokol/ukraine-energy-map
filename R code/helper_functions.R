
# Function to get data thru NBU website API
get_exchange_rate_date_range_currency <- function(start, end, currency) {
  base_url <- "https://bank.gov.ua/NBU_Exchange/exchange_site?"
  url <- paste0(base_url, "start=", start, "&end=", end, "&valcode=", currency, "&sort=exchangedate&order=desc&json")
  
  #loop over the sequence of dates
  rate <- fromJSON(url, simplifyDataFrame = TRUE) |> 
    select(date = exchangedate, rate) |> 
    mutate(date = as.Date(date, format = "%d.%m.%Y"),
           rate = if_else(rate > 1000, rate / 100, rate))
  
  return(rate)
}
