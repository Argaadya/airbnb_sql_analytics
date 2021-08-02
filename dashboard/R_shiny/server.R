mydb <- dbConnect(MySQL(),
                  host = "db4free.net", # write "localhost" if you use a localhost
                  port = 3306,
                  user = "your_name",
                  password = "your_password",
                  dbname = "your_database"
                  )


shinyServer(function(input, output,session) {


    # Leaflet --------------
    output$map_output <- renderLeaflet({
        
        popup <- paste0("<b>", df_map$name, "</b><br>",
                        "Host Name: <b>", df_map$host_name, "</b><br>",
                        "Price: THB <b>", number(df_map$price, big.mark = ","), "</b><br>",
                        "Review Scores Rating: <b>", df_map$review_scores_rating , "</b><br>",
                        "Number of Reviews: <b>", number(df_map$number_of_reviews, big.mark = ","), "</b><br>",
                        "<a href=", df_map$listing_url, " target='_blank'> Click for more info</a>"
                        )
        
        leaflet(data = df_map) %>% 
            addTiles() %>% 
            addMarkers(lng = ~longitude,
                       lat = ~latitude, 
                       popup = popup, 
                       clusterOptions = markerClusterOptions()
                       )
    })
    
    # Top Room Type ------------
    output$listing_room_type <- renderPlotly({
        
        res <- dbSendQuery(mydb,
                           "SELECT room_type, COUNT(*) as frequency, AVG(price) as mean_price
                           FROM listing
                           GROUP BY room_type
                           ORDER BY COUNT(*) DESC"
                           )
        
        out_db <- fetch(res) %>% 
            mutate(room_type = ifelse(room_type == "Entire home/apt", "Entire home/apartment", room_type))
        
        dbClearResult(res)
        
        plot_ly(data = out_db, 
                labels = ~room_type, values = ~frequency) %>% 
            add_pie(hole = 0.6, 
                    hovertemplate = paste0("<b>", out_db$room_type, "</b><br>",
                                           "Number of Listing: ", number(out_db$frequency, big.mark = ','), "<br>",
                                           "Average Price/Night : ",  number(out_db$mean_price, big.mark = ',', prefix = 'THB '),
                                           "<extra></extra>"
                                           )
                    ) %>% 
            layout(title = "<b>Room Type by Number of Listing</b>") %>% 
            config(displayModeBar = F)
        
    })
    
    
    
    # Change input Tab 2--------------
    ## If user select all region, other choices will be omitted
    
    observeEvent(input$select_neighbour, {
        
        if (length(input$select_neighbour) > 1 & "All Region" == input$select_neighbour[1]) {
            
            input_area <- input$select_neighbour[ input$select_neighbour != "All Region"]
            
            updateSelectInput(session,
                              inputId = "select_neighbour", label = "Select Neighbourhood",
                              choices = c("All Region", sort(df_neighbour$neighbourhood_cleansed)),
                              selected = input_area
            )
        } else if(length(input$select_neighbour) > 1 & "All Region" != input$select_neighbour[1] & "All Region" %in% input$select_neighbour){ # All region is selected but not as the first one
            
            updateSelectInput(session,
                              inputId = "select_neighbour", label = "Select Neighbourhood",
                              choices = c("All Region", sort(df_neighbour$neighbourhood_cleansed)),
                              selected = "All Region"
            )
            
        }
        
        
        
    })
    
    # Top Listing ----------------
    output$listing_top <- renderPlotly({
        
        # User select all for select room type and select neighbourhood
        if (input$select_room == "All" & ("All Region" %in% input$select_neighbour | length(input$select_neighbour) ==0)) {
            query <- paste0("SELECT name, AVG(price) as price, AVG(review_scores_rating) as review_scores_rating, AVG(number_of_reviews) as number_of_reviews, host_info.host_name
                           FROM listing
                           LEFT JOIN host_info
                           ON listing.host_id = host_info.host_id
                           WHERE review_scores_rating IS NOT NULL AND number_of_reviews > 10
                           GROUP BY name, host_info.host_name
                           ORDER BY ", input$select_cat ," DESC
                           LIMIT 10
                            ")
        } else if(input$select_room != "All" & ("All Region" %in% input$select_neighbour | length(input$select_neighbour) ==0)) { # user select all region but specific room type
            
            query <- paste0("SELECT name, AVG(price) as price, AVG(review_scores_rating) as review_scores_rating, AVG(number_of_reviews) as number_of_reviews, host_info.host_name
                           FROM listing
                           LEFT JOIN host_info
                           ON listing.host_id = host_info.host_id
                           WHERE room_type = '", input$select_room,"' AND review_scores_rating IS NOT NULL AND number_of_reviews > 10
                           GROUP BY name, host_info.host_name
                           ORDER BY ", input$select_cat ," DESC
                           LIMIT 10
                            ")
        } else if(input$select_room == "All" & !("All Region" %in% input$select_neighbour)){ # User select all room type but specific neighbourhood 
            
            input_area <- input$select_neighbour %>%  
                paste0("'", ., "'") %>% 
                paste(collapse = ", ")
            
            query <- paste0("SELECT name, AVG(price) as price, AVG(review_scores_rating) as review_scores_rating, AVG(number_of_reviews) as number_of_reviews, host_info.host_name
                           FROM listing
                           LEFT JOIN host_info
                           ON listing.host_id = host_info.host_id
                           WHERE neighbourhood_cleansed IN(",  input_area ,") AND review_scores_rating IS NOT NULL AND number_of_reviews > 10
                           GROUP BY name, host_info.host_name
                           ORDER BY ", input$select_cat ," DESC
                           LIMIT 10
                            ")
            
        } else {
            
            input_area <- df_neighbour$neighbourhood_cleansed %>% 
                head(3) %>% 
                paste0("'", ., "'") %>% 
                paste(collapse = ", ")
            
            query <- paste0("SELECT name, AVG(price) as price, AVG(review_scores_rating) as review_scores_rating, AVG(number_of_reviews) as number_of_reviews, host_info.host_name
                           FROM listing
                           LEFT JOIN host_info
                           ON listing.host_id = host_info.host_id
                           WHERE room_type = '", input$select_room,"' AND neighbourhood_cleansed IN(",  input_area ,") AND review_scores_rating IS NOT NULL AND number_of_reviews > 10
                           GROUP BY name, host_info.host_name
                           ORDER BY ", input$select_cat ," DESC
                           LIMIT 10
                            ")
            
        }

        res <- dbSendQuery(mydb, query)
        out_db <- fetch(res) 
        dbClearResult(res)
        
        clean_input <- input$select_cat %>% 
            str_replace_all("_", " ") %>% 
            str_to_title()
            
        out_db <- out_db %>% 
            mutate(popup = glue("<b>{name}</b>
                                Host: {host_name}
                                Price: THB {number(price, big.mark = ',')}
                                Rating: {round(review_scores_rating, 3)}
                                Number of Reviews: {number(number_of_reviews, big.mark = ',')}
                                ")) 
        
        p <- out_db %>% 
            ggplot(aes(x = out_db[, input$select_cat], 
                       y = name %>% reorder(out_db[ , input$select_cat]),
                       fill = out_db[, input$select_cat],
                       text = popup
                       )
                   ) +
            geom_col(width = 0.75) +
            scale_x_continuous(labels = number_format(big.mark = ",")) +
            scale_fill_gradient(low = "dodgerblue4", high = "skyblue") +
            labs(x = clean_input,
                 y = NULL,
                 title = "Top 10 Room Listing"
                 ) +
            theme_pander() +
            theme(axis.text.y = element_text(size = 8)
                  )
        
        ggplotly(p, tooltip = "text") %>% 
            config(displayModeBar = F) %>% 
            hide_colorbar()
        
    })
    
    # Top Amenities -----------
    output$listing_amenities <- renderPlotly({
        
        if (input$select_room == "All" & ("All Region" %in% input$select_neighbour | length(input$select_neighbour) ==0)) {
            query <- "SELECT amenities FROM listing"
        } else if (input$select_room != "All" & ("All Region" %in% input$select_neighbour | length(input$select_neighbour) ==0)){
            query <- paste0("SELECT amenities FROM listing
                             WHERE room_type = '", input$select_room,"'"
                            )
        } else if(input$select_room == "All" & !("All Region" %in% input$select_neighbour)){
            input_area <- input$select_neighbour %>%  
                paste0("'", ., "'") %>% 
                paste(collapse = ", ")
            
            query <- paste0("SELECT amenities FROM listing
                             WHERE neighbourhood_cleansed IN(",  input_area , ")"
                            )
        } else {
            input_area <- input$select_neighbour %>%  
                paste0("'", ., "'") %>% 
                paste(collapse = ", ")
            
            query <- paste0("SELECT amenities FROM listing
                             WHERE neighbourhood_cleansed IN(",  input_area , ") AND room_type = '", input$select_room, "'"
                            )
        }
        
        res <- dbSendQuery(mydb, query)
        
        out_db <- fetch(res, n = -1)
        dbClearResult(res)
        
        list_amenities <- map(out_db$amenities, function(x) x %>% strsplit(", ") %>% unlist() ) %>% 
            unlist()
        
        df_amenities <- data.frame(amenities = list_amenities) %>% 
            count(amenities, name = "frequency") %>% 
            mutate(n_data = nrow(out_db),
                   ratio = frequency/nrow(out_db),
                   text_amenities = amenities %>% 
                       str_replace_all(" ", "\n")
                   )
        
        plot_ly(
            data = df_amenities,
            type = "treemap",
            labels = ~text_amenities,
            parents = "", 
            hovertemplate = paste0("<b>", df_amenities$amenities, "</b><br>",
                                   "Number of Listing with This Amenities: ", number(df_amenities$frequency, big.mark = ","), " (", percent(df_amenities$ratio, accuracy = 0.1), ")<br>",
                                   "<extra></extra>"
                                   ),
            values = ~frequency
            )  %>% 
            layout(title = "<b>Commonly Provided Amenities</b>") %>% 
            config(displayModeBar = F)

    })
    
    
    # Host Join Timeline -----------
    output$host_join <- renderPlotly({
        
        query <- "SELECT MONTHNAME(host_since) as month, YEAR(host_since) as year,  COUNT(*) as frequency
        FROM host_info
        WHERE host_since IS NOT NULL
        GROUP BY month, year"
        
        res <- dbSendQuery(mydb, query)
        out_db <- fetch(res) 
        dbClearResult(res)
        
        p <- out_db %>% 
            mutate(date = paste0(year, "-", month, "-1") %>% 
                       ymd()
            ) %>% 
            pad(interval = "month",
                start_val = ymd( paste0(min(.$year), "-1-1") )
                ) %>% 
            mutate(month = month(date, label = T, abbr = F),
                   year = year(date)
                   ) %>% 
            replace_na(list(frequency = 0)) %>% 
            
            ggplot(aes(x = year,
                       y = month,
                       fill = frequency, 
                       text = glue("Year: {year}
                         Month: {month}
                         Number of Host Joined: {frequency}")
                       )
                   ) +
            geom_tile(color = "white") +
            scale_x_continuous(breaks = seq(2000, 2025, 2) ) +
            theme_pander() +
            scale_fill_viridis_c(option = "B") +
            labs(x = "Year",
                 y = NULL,
                 fill = "Frequency",
                 title = "Number of Host Joined Over Time")
        
        ggplotly(p, tooltip = "text") %>% 
            config(displayModeBar = F) 
        
    })
    
    # Top Host Earning ------------------------
    output$host_top <- renderReactable({
        
        if (input$select_superhost == T) {
            
            query <- "SELECT listing.host_id, host_info.host_name, host_info.host_since,  host_info.host_is_superhost, host_info.host_identity_verified, COUNT(*) as number_of_listing, SUM( price * number_of_reviews * minimum_nights ) as earning, host_info.host_url
                FROM listing
                LEFT JOIN host_info
                ON listing.host_id = host_info.host_id
                WHERE host_info.host_since IS NOT NULL
                GROUP BY listing.host_id
                ORDER BY earning DESC
                LIMIT 50"
        } else {
            
            query <- "SELECT listing.host_id, host_info.host_name, host_info.host_since,  host_info.host_is_superhost, host_info.host_identity_verified, COUNT(*) as number_of_listing, SUM( price * number_of_reviews * minimum_nights ) as earning, host_info.host_url
                FROM listing
                LEFT JOIN host_info
                ON listing.host_id = host_info.host_id
                WHERE host_info.host_is_superhost = 0 AND host_info.host_since IS NOT NULL
                GROUP BY listing.host_id
                ORDER BY earning DESC
                LIMIT 50"
        }
        
        res <- dbSendQuery(mydb, query)
        out_db <- fetch(res) 
        dbClearResult(res)
        
        reactable(out_db, 
                  striped = T, highlight = T,
                  columns = list(host_id = colDef(name = "Host ID",),
                                 host_name = colDef(name = "Host Name",
                                                    cell = function(value, index){
                                                        url <- sprintf("%s", out_db[index, "host_url"])
                                                        tags$a(href = url, value)
                                                    }
                                                    ),
                                 host_since = colDef(name = "Host Since"),
                                 number_of_listing = colDef(name = "Number of Listing", minWidth = 100,
                                                            style = list(fontFamily = "monospace")
                                                            ),
                                 earning = colDef(name = "Total Earning", 
                                                  format = colFormat(separators = T),
                                                  style = list(fontFamily = "monospace")
                                                  ),
                                 host_is_superhost = colDef(name = "Superhost",
                                                            minWidth = 100,
                                                            cell = function(value, index){
                                                                if (value == 0) "\u2718" else "\u2713"
                                                            }
                                                            ),
                                 host_identity_verified = colDef(name = "Identity Verified",
                                                                 minWidth = 100,
                                                                 cell = function(value, index){
                                                                     if (value == 0) "\u2718" else "\u2713"
                                                                 }
                                                                 ),
                                 host_url = colDef(show = F)
                  )
                  
        )
        
    })
    
    # Commonly Identified Information -------------------------
    output$host_verification <- renderPlotly({
        
        res <- dbSendQuery(mydb,
                           "SELECT host_id, host_name, host_verifications, host_identity_verified
                           FROM host_info
                           WHERE host_identity_verified IS NOT NULL AND host_verifications IS NOT NULL
                           "
        )
        
        out_db <- fetch(res, n = -1)
        dbClearResult(res)
        
        out_db <- out_db %>% 
            mutate(host_verifications = tolower(host_verifications))
        
        list_verification <- map(out_db$host_verifications, function(x) x %>% strsplit(", ") %>% unlist() ) %>% 
            unlist()
        
        df_verify <- data.frame(verification = list_verification) %>% 
            count(verification, name = "frequency") %>% 
            mutate(n_data = nrow(out_db),
                   ratio = frequency/nrow(out_db),
                   verification = verification %>% 
                       str_replace_all("_", " ") %>% 
                       str_to_title(),
                   text_verification = verification %>% 
                       str_replace_all(" ", "\n")
                   )
        
        plot_ly(
            data = df_verify,
            type = "treemap",
            labels = ~text_verification,
            parents = "", 
            hovertemplate = paste0("<b>", df_verify$verification, "</b><br>",
                                   "Number of Host with This Identity Information: ", number(df_verify$frequency, big.mark = ","), " (", percent(df_verify$ratio, accuracy = 0.1), ")<br>",
                                   "<extra></extra>"
            ),
            values = ~frequency
        )  %>% 
            layout(title = "<b>Commonly Given Verification Identity</b>") %>% 
            config(displayModeBar = F)
        
        
    })
    
    
})
