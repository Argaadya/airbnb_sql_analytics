library(shiny)
library(shiny.semantic)
library(semantic.dashboard)

library(plotly)
library(glue)
library(scales)
library(leaflet)
library(ggthemes)
library(reactable)

library(RMySQL)
library(tidyverse)
library(lubridate)
library(padr)

mydb <- dbConnect(MySQL(),
                  host = "db4free.net", # write "localhost" if you use a localhost
                  port = 3306,
                  user = "your_name",
                  password = "your_password",
                  dbname = "your_database"
                  )

# Number of Listing ---------
res <- dbSendQuery(mydb, 
                   "SELECT COUNT(*) as freq 
                   FROM listing"
                   )
n_listing <- fetch(res) %>% 
  pull(freq)

dbClearResult(res)

# Number of Host -----
res <- dbSendQuery(mydb, 
                   "SELECT COUNT(*) as freq 
                   FROM host_info"
)
n_host <- fetch(res) %>% 
  pull(freq)

dbClearResult(res)

# Number of Review ----------
res <- dbSendQuery(mydb, 
                   "SELECT SUM(number_of_reviews) as freq 
                   FROM listing"
)
n_review <- fetch(res) %>% 
  pull(freq)
dbClearResult(res)


# Get different room type
res <- dbSendQuery(mydb, 
                  "SELECT DISTINCT room_type 
                  FROM listing")
df_room_type <- fetch(res)
dbClearResult(res)

# Get different neighbourhood
res <- dbSendQuery(mydb, 
                   "SELECT DISTINCT neighbourhood_cleansed
                   FROM listing")
df_neighbour <- fetch(res)
dbClearResult(res)

# Number of Superhost
res <- dbSendQuery(mydb,
                   "SELECT COUNT(*) as frequency
                   FROM host_info
                   WHERE host_is_superhost = 1
                   "
)

n_superhost <- fetch(res, n = -1)
dbClearResult(res)

# Number of Verified Host
res <- dbSendQuery(mydb,
                   "SELECT COUNT(*) as frequency
                   FROM host_info
                   WHERE host_identity_verified = 1
                   "
                   )

n_host_verified <- fetch(res, n = -1)
dbClearResult(res)

# Number of Non-Verified Host
res <- dbSendQuery(mydb,
                   "SELECT COUNT(*) as frequency
                   FROM host_info
                   WHERE NOT host_identity_verified = 1
                   "
)

n_host_non_verified <- fetch(res, n = -1)
dbClearResult(res)

# Data for Map --------
res <- dbSendQuery(mydb,
                   "SELECT name, listing_url, latitude, longitude, price, review_scores_rating, number_of_reviews, listing.host_id, host_info.host_name
                   FROM listing
                   LEFT JOIN host_info
                   ON listing.host_id = host_info.host_id"
)

df_map <- fetch(res, n = -1) %>% 
  replace_na(list(description = "No Description",
                  review_scores_rating = "No Rating Yet"
  )
  )

dbClearResult(res)