shinyUI(
    
    dashboardPage(
        
        dashboardHeader(title = "Airbnb Analytics", color = "blue", inverted = T),
        
        dashboardSidebar(color = "orange",
                         
                         sidebar_menu(
                             
                             menu_item(text = "Overview", icon = icon("eye"), tabName = "overview"),
                             menu_item(text = "Room Listing", icon =  icon("bed"), tabName = "listing"),
                             menu_item(text = "Host", icon = icon("user"), tabName = "host")
                             
                             )
                         
                         ),
                  
                  dashboardBody(
                      
                      tab_items(
                          
                          # Overview ---------
                          tab_item(tabName = "overview", 
                                   
                                   fluidRow(
                                       
                                       column(width = 13,
                                              box(title = "Overview", color = "orange", 
                                                  width = 16, title_side = "top left", collapsible = F,
                                                  h2("Airbnb Bangkok, Thailand"),
                                                  HTML("Airbnb, Inc. is an American company that operates an online marketplace for lodging, primarily homestays for vacation rentals, and tourism activities.<br><br>
                                                       On this dashboard you can explore information regarding the host and room listings available in Bangkok, Central Thailand, Thailand. 
                                                       All data is sourced from publicly available information from <a href = 'http://insideairbnb.com/get-the-data.html'  target='_blank'>the Airbnb site.</a>
                                                       All monetary values are presented in local currency (Thailand Baht or THB)."
                                                       )
                                                  )
                                              ),
                                       
                                       column(width = 3,
                                              HTML(paste("<a href = https://www.airbnb.com/ target='_blank'>" , img(src = "airbnb-logo.png", height = "175" ), "</a>") )
                                              )
                                       ),
                                   
                                   fluidRow(
                                       
                                       value_box("Number of Room Listing", 
                                                 number(n_listing, big.mark = ","), width = 5,
                                                 icon = icon("blue bed"), size = "small"
                                                 ),
                                       value_box("Number of Host", width = 6,
                                                 number(n_host, big.mark = ","), 
                                                 icon("teal user"), size = "small"
                                                 ),
                                       value_box("Total Reviews", width = 5,
                                                 number(n_review, big.mark = ","), 
                                                 icon("orange comment"), size = "small"
                                                 )
                                       
                                       ),
                                   
                                   leafletOutput("map_output", height = 600)
                                   
                                   
                                   ),
                          
                          
                          # Room Listing -------
                          tab_item(tabName = "listing",
                                   
                                   fluidRow(
                                       
                                       column(width = 8,
                                              box(title = "Room Listing", color = "orange", 
                                                  width = 16, title_side = "top left", collapsible = F,
                                                  h2("Different Room Type on Airbnb"),
                                                  HTML("Airbnb hosts can list entire homes/apartments, private or shared rooms. 
                                                       Airbnb provides <a href = https://www.airbnb.com/help/topic/1424/preparing-to-host target =  '_blank'> detailed guides</a> on how hosts could set up their places.<br><br>
                                                       Use the input below to get the top room listing and commonly provided amenities for selected categories."
                                                       ),
                                                  
                                                  br(),  br(), 
                                                  
                                                  div(style="display: inline-block; width: 49.7%;align: center;",
                                                      selectInput(inputId = "select_room", label = "Select Room Type", 
                                                                  choices = c("All", df_room_type$room_type )
                                                      )
                                                      ),
                                                  
                                                  div(style="display: inline-block;  width: 49.7%;align: center;",
                                                      selectInput(inputId = "select_cat", label = "Select Category", 
                                                                  choices = list("Price" = "price",
                                                                                 "Overal Rating" = "review_scores_rating",
                                                                                 "Number of Review" = "number_of_reviews"
                                                                  )
                                                      )
                                                      ),
                                                        
                                                  br(), br(), 
                                                  selectInput(inputId = "select_neighbour", label = "Select Neighbourhood",
                                                              choices = c("All Region", sort(df_neighbour$neighbourhood_cleansed)),
                                                              multiple = T,
                                                              selected = "All Region"
                                                              )
                                                  
                                                  )
                                              ),
                                       
                                       column(width = 8,
                                              plotlyOutput("listing_room_type")
                                              )
                                       
                                   ),
                                   
                                   fluidRow(
                                       
                                       column(width = 8,
                                              plotlyOutput("listing_top", height = 500)
                                              ),
                                       column(width = 8,
                                              plotlyOutput("listing_amenities", height = 500)
                                              )
                                       
                                   )
                                   
                                   ),
                          
                          # Host --------------------
                          tab_item(tabName = "host", 
                                   
                                   fluidRow(
                                       
                                       column(width = 6,
                                              box(title = "Host", color = "orange", 
                                                  width = 16, title_side = "top left", collapsible = F,
                                                  h2("Airbnb Host Partner"),
                                                  HTML("Airbnb hosts are required to <a href=  https://www.airbnb.com/help/article/1237/verifying-your-identity target='_blank'> confirm their identity</a> such as their name, address, phone, etc. 
                                                       <a href = https://www.airbnb.com/help/article/828/what-is-a-superhost target='_blank'>Superhosts</a> are experienced hosts 
                                                       who provide a shining example for other hosts, and extraordinary experiences for their guests.<br><br>
                                                       <b>Total earning</b> gained by hosts are calculated by the total product of their <b>listing price</b>, 
                                                       <b>number of reviews </b> to represent the number of customers, and 
                                                       the <b> minimun night</b> to represent the number of night stays."
                                                  )
                                                  ),
                                              
                                              br(),
                                              value_box(subtitle = "Superhost", 
                                                        value = number(n_superhost$frequency, big.mark = ","), 
                                                        icon = icon("orange star"), size = "tiny"
                                                        ),
                                              br(),
                                              
                                              div(style="display: inline-block; width: 49.7%;align: center;",
                                                  value_box(subtitle = "Verified Host", 
                                                            value = number(n_host_verified$frequency, big.mark = ","), 
                                                            icon = icon("green check"), size = "tiny"
                                                            )
                                                  ),
                                              div(style="display: inline-block; width: 49.7%;align: center;",
                                                  value_box(subtitle = "Unverified Host", 
                                                            value = number(n_host_non_verified$frequency, big.mark = ","), 
                                                            icon = icon("red times"), size = "tiny"
                                                            )
                                                  )
                                              
                                              ),
                                       
                                       column(width = 10,
                                              h2("Top 50 Host by Total Earning"),
                                              checkbox_input(input_id = "select_superhost", label = "Include Superhost", is_marked = T),
                                              reactableOutput("host_top")
                                              )
                                       ),
                                   
                                   fluidRow(
                                       
                                       column(width = 10,
                                              plotlyOutput("host_join", height = 500)
                                       ),
                                       column(width = 6,
                                              plotlyOutput("host_verification", height = 500)
                                       )
                                       
                                   )
                                   
                                   )
                      
                      
                  )
                  
                  
                  
                  )
    
        
)
)
