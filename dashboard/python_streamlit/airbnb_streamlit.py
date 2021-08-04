import streamlit as st
import streamlit_folium
import folium
from PIL import Image
import datetime

import pandas as pd
import numpy as np

import plotly.express as px

# Connect MySQL
import mysql.connector

now = str(datetime.datetime.now())
print( now )

@st.cache(allow_output_mutation=True, hash_funcs={"_thread.RLock": lambda _: None})
def connect_db():
    
    return( mysql.connector.connect(host = "db4free.net",
                                port = 3306,
                                user = "username",
                                password = "password",
                                database = "database_name"
                                )
    )

mydb = connect_db()
mydb.ping(reconnect=True, attempts=3, delay=2)
print("DB Connected")

# Number of Listing --------------
query = """
SELECT COUNT(*) as freq 
FROM listing
"""

n_listing = pd.read_sql(query, mydb)
n_listing = n_listing['freq'][0]

# Number of Host --------------
query = """
SELECT COUNT(*) as freq 
FROM host_info
"""

n_host = pd.read_sql(query, mydb)
n_host = n_host['freq'][0]

# Total Reviews --------------
query = """
SELECT SUM(number_of_reviews) as freq 
FROM listing
"""

n_review = pd.read_sql(query, mydb)
n_review = n_review['freq'][0]

# Number of Superhost --------------
query = """
SELECT COUNT(*) as frequency
FROM host_info
WHERE host_is_superhost = 1
"""

n_superhost = pd.read_sql(query, mydb)
n_superhost = n_superhost['frequency'][0]

# Number of Verified Host --------------
query = """
SELECT COUNT(*) as frequency
FROM host_info
WHERE host_identity_verified = 1
"""

n_verified = pd.read_sql(query, mydb)
n_verified = n_verified['frequency'][0]

# Number of Unverified Host --------------
query = """
SELECT COUNT(*) as frequency
FROM host_info
WHERE host_identity_verified = 0
"""

n_non_verified = pd.read_sql(query, mydb)
n_non_verified = n_non_verified['frequency'][0]

# Room Type ------------
query = """
SELECT DISTINCT room_type 
FROM listing
"""

list_room_type = pd.read_sql(query, mydb)
list_room_type = list_room_type.room_type
list_room = ["All"]
list_room.extend(list_room_type)

# Neighbourhood ----------------
query = """
SELECT DISTINCT neighbourhood_cleansed 
FROM listing
"""

list_neighbour = pd.read_sql(query, mydb)
list_neighbour.sort_values('neighbourhood_cleansed', inplace = True)
list_neighbour = list_neighbour.neighbourhood_cleansed
list_area = ["All Region"]
list_area.extend(list_neighbour)

title_image = Image.open("img/airbnb-logo.png")
bed_image = Image.open("img/bed.png")
host_image = Image.open("img/host.png")
bag_image = Image.open("img/bag.png")
star_image = Image.open("img/star.png")
check_image = Image.open("img/check.png")
wrong_image = Image.open("img/wrong.png")

# Layout ------------

## Side bar ----------

side_col1, side_col2, side_col3 = st.sidebar.beta_columns([1,6,1])

side_col2.title("Airbnb Analytics")
side_col2.image(title_image, width = 200)

menu_select = st.sidebar.selectbox("", ["Overview", "Room Listing", "Host"])

# Menu Host
#if button_host:
if menu_select == "Host":
    st.title("Host")
    st.markdown("""
            Airbnb hosts are required to [confirm their identity](https://www.airbnb.com/help/article/1237/verifying-your-identity) such as their name, address, phone, etc. 
            [Superhosts](https://www.airbnb.com/help/article/828/what-is-a-superhost) are experienced hosts who provide a shining example for other hosts, and extraordinary experiences for their guests.
            """)

    # Valuebox --------
    vbox1, vbox2, vbox3, vbox4, vbox5, vbox6 = st.beta_columns([2.5, 6 , 2.5, 6 , 2.5, 6])

    vbox1.image(star_image)
    vbox2.markdown( "**{:,}".format(int(n_superhost)) + "**\n\n Superhost")

    vbox3.image(check_image)
    vbox4.markdown( "**{:,}".format(int(n_verified)) + "**\n\n Verified Host")

    vbox5.image(wrong_image)
    vbox6.markdown( "**{:,}".format(int(n_non_verified)) + "**\n\n Unverified Host")

    st.markdown("""
    ## Top 10 Host by Total Earning
    **Total earning** gained by hosts are calculated by the total product of their **listing price**, 
    **number of reviews** to represent the number of customers, and  the **minimun night** to represent the number of night stays.
    """)

    include_superhost = st.checkbox("Include Superhost")
    if include_superhost:
        query = """SELECT listing.host_id, host_info.host_name, host_info.host_since,  host_info.host_is_superhost, host_info.host_identity_verified, COUNT(*) as number_of_listing, SUM( price * number_of_reviews * minimum_nights ) as earning, host_info.host_url
                FROM listing
                LEFT JOIN host_info
                ON listing.host_id = host_info.host_id
                WHERE host_info.host_since IS NOT NULL
                GROUP BY listing.host_id
                ORDER BY earning DESC
                LIMIT 10"""
    else:
        query = """SELECT listing.host_id, host_info.host_name, host_info.host_since,  host_info.host_is_superhost, host_info.host_identity_verified, COUNT(*) as number_of_listing, SUM( price * number_of_reviews * minimum_nights ) as earning, host_info.host_url
                FROM listing
                LEFT JOIN host_info
                ON listing.host_id = host_info.host_id
                WHERE host_info.host_is_superhost = 0 AND host_info.host_since IS NOT NULL
                GROUP BY listing.host_id
                ORDER BY earning DESC
                LIMIT 10"""
    
    df_top_host = pd.read_sql(query, mydb)
    df_top_host.replace({'host_is_superhost': {1:'\u2714', 0:'\u274c'}, 'host_identity_verified': {1:'\u2714', 0:'\u274c'}}, inplace = True)
    df_top_host.columns = ['Host ID', 'Host Name', 'Host Since', 'Superhost', 'Identity Verified', 'Listing Count', 'Total Earning', 'Host URL']
    st.table(df_top_host)
    
    query = """
    SELECT MONTH(host_since) as month, YEAR(host_since) as year,  COUNT(*) as frequency
    FROM host_info
    WHERE host_since IS NOT NULL
    GROUP BY month, year
    """

    df_timeline = pd.read_sql(query, mydb)
    df_timeline.sort_values(['year', 'month'], inplace = True)
    df_timeline['day'] = 1
    df_timeline['date'] = [datetime.date(year=x[1].year, month=x[1].month, day=x[1].day) for x in df_timeline.iterrows()]
    
    st.markdown("""
    ## Monthly Number of Host Joined
    """)    
    st.plotly_chart( px.line(df_timeline, x = 'date', y = 'frequency') )

    query = """
        SELECT host_id, host_name, host_verifications, host_identity_verified
        FROM host_info
        WHERE host_identity_verified IS NOT NULL AND host_verifications IS NOT NULL
        """

    df_verif = pd.read_sql(query, mydb)
    # Remove missing verification
    df_verif = df_verif[ df_verif.host_verifications.isna() == False]
    df_verif.reset_index(drop = True, inplace = True)

    list_verify = []
    for i in range(df_verif.shape[0]):
        verify_i = df_verif.host_verifications[i].split(", ")
        list_verify.extend(verify_i)
    
    df_verify = pd.DataFrame(list_verify, columns = {"verified_info"})
    
    # Create frequency dataframe
    df_viz = pd.DataFrame(df_verify.value_counts('verified_info'))
    df_viz.reset_index(inplace = True)
    df_viz.rename(columns = {0:"freq"}, inplace = True)

    # Create ratio column
    df_viz['ratio'] = df_viz.freq/df_verif.shape[0]*100
    df_viz['parent'] = [ '' for m in range(df_viz.shape[0]) ]

    st.markdown("""
    ## Commonly Given Verification Identity
    """)
    
    st.plotly_chart( px.treemap(df_viz, names= 'verified_info', values = 'freq', parents = 'parent') )

else:
    # Menu Room Listing ---------------------
    #if button_listing:
    if menu_select == "Room Listing":
        st.title("Different Room Type on Airbnb")
        st.markdown("""
            Airbnb hosts can list entire homes/apartments, private or shared rooms. 
            Airbnb provides [detailed guides](https://www.airbnb.com/help/topic/1424/preparing-to-host) on how hosts could set up their places.\n\n
            The most common listing available is either entire home or apartment, followed by private room. Some hotels are also listing their room in Airbnb apparently.
            """
            )

        mydb.ping(reconnect=True, attempts=3, delay=2)
        query = """
        SELECT room_type, COUNT(*) as frequency, AVG(price) as mean_price
        FROM listing
        GROUP BY room_type
        ORDER BY COUNT(*) DESC
        """

        df_room_type = pd.read_sql(query, mydb)
        df_room_type.replace({"room_type": {"Entire home/apt":"Entire home/apartment"}}, inplace= True)

        st.plotly_chart( px.pie(df_room_type, values = 'frequency', names = 'room_type', 
                                title = '<b>Room Type by Number of Listing</b>') 
                        )

        st.markdown("Use the input below to get the top room listing and commonly provided amenities for selected categories.")

        col_in1, col_in2 = st.beta_columns([5,5])
        selected_room = col_in1.selectbox("Select Room Type", options= list_room )
        selected_category = col_in2.selectbox("Select Category", options = ["Price", "Number of Review", "Review Scores Rating"])
        selected_region = st.selectbox("Select Neighbourhood", options = list_area)

        if selected_category == "Price":
            select_cat = "price"
        else:
            if selected_category == "Number of Review":
                select_cat = "number_of_reviews"
            else: 
                select_cat = "review_scores_rating"
        
        if (selected_region == "All Region") & (selected_room == "All"):
            mydb.ping(reconnect=True, attempts=3, delay=2)
            query = """
                SELECT name, AVG(price) as price, AVG(review_scores_rating) as review_scores_rating, AVG(number_of_reviews) as number_of_reviews, host_info.host_name
                FROM listing
                LEFT JOIN host_info
                ON listing.host_id = host_info.host_id
                WHERE review_scores_rating IS NOT NULL AND number_of_reviews > 10
                GROUP BY name, host_info.host_name
                ORDER BY """ + select_cat + """ DESC
                LIMIT 10
                """

            df_top_room = pd.read_sql(query, mydb)

            query = """
            SELECT amenities, review_scores_rating, price
            FROM listing
            """

            df_query_am = pd.read_sql(query, mydb)
        else:
            if (selected_region != "All Region") & (selected_room == "All"):
                mydb.ping(reconnect=True, attempts=3, delay=2)
                query = """
                SELECT name, AVG(price) as price, AVG(review_scores_rating) as review_scores_rating, AVG(number_of_reviews) as number_of_reviews, host_info.host_name
                FROM listing
                LEFT JOIN host_info
                ON listing.host_id = host_info.host_id
                WHERE review_scores_rating IS NOT NULL AND number_of_reviews > 10 AND neighbourhood_cleansed = '""" + selected_region + """' GROUP BY name, host_info.host_name
                ORDER BY """ + select_cat + """ DESC
                LIMIT 10
                """

                df_top_room = pd.read_sql(query, mydb)

                query = """
                SELECT amenities, review_scores_rating, price
                FROM listing
                WHERE neighbourhood_cleansed = '""" + selected_region + "'"

                df_query_am = pd.read_sql(query, mydb)
            else:
                if (selected_region == "All Region") & (selected_room != "All"):
                    mydb.ping(reconnect=True, attempts=3, delay=2)
                    query = """
                    SELECT name, AVG(price) as price, AVG(review_scores_rating) as review_scores_rating, AVG(number_of_reviews) as number_of_reviews, host_info.host_name
                    FROM listing
                    LEFT JOIN host_info
                    ON listing.host_id = host_info.host_id
                    WHERE review_scores_rating IS NOT NULL AND number_of_reviews > 10 AND room_type = '""" + selected_room + """'  GROUP BY name, host_info.host_name
                    ORDER BY """ + select_cat + """ DESC
                    LIMIT 10
                    """
                    df_top_room = pd.read_sql(query, mydb)

                    query = """
                    SELECT amenities, review_scores_rating, price
                    FROM listing
                    WHERE room_type = '""" + selected_room + "'"

                    df_query_am = pd.read_sql(query, mydb)
                else:
                    mydb.ping(reconnect=True, attempts=3, delay=2)
                    query = """
                    SELECT name, AVG(price) as price, AVG(review_scores_rating) as review_scores_rating, AVG(number_of_reviews) as number_of_reviews, host_info.host_name
                    FROM listing
                    LEFT JOIN host_info
                    ON listing.host_id = host_info.host_id
                    WHERE review_scores_rating IS NOT NULL AND number_of_reviews > 10 AND room_type = '""" + selected_room + """' AND neighbourhood_cleansed = '""" + selected_region + """' GROUP BY name, host_info.host_name
                    ORDER BY """ + select_cat + """ DESC
                    LIMIT 10
                    """
                    df_top_room = pd.read_sql(query, mydb)

                    query = """
                    SELECT amenities, review_scores_rating, price
                    FROM listing
                    WHERE room_type = '""" + selected_room + """' AND neighbourhood_cleansed = '""" + selected_region + "'"

                    df_query_am = pd.read_sql(query, mydb)

        df_top_room.sort_values(select_cat, inplace = True)

        st.markdown("## Top Room Listing")
        st.plotly_chart( px.bar(df_top_room, x = select_cat, y = 'name' ))

        df_query_am.amenities = list(map(lambda x: x.lower(), df_query_am.amenities))
        list_amenities = []
        
        for i in range(df_query_am.shape[0]):
            amenities_i = df_query_am.amenities[i].split(", ")
            list_amenities.extend(amenities_i)

        df_amenities = pd.DataFrame(list_amenities, columns= {"amenities"})

        # Create frequency dataframe
        df_viz = pd.DataFrame(df_amenities.value_counts('amenities'))
        df_viz.reset_index(inplace = True)
        df_viz.rename(columns = {0:"freq"}, inplace = True)

        # Create ratio column
        df_viz['ratio'] = df_viz.freq/df_query_am.shape[0]*100
        df_viz['parent'] = [ '' for m in range(df_viz.shape[0]) ]

        st.markdown("## Commonly Provided Amenities")
        st.plotly_chart( px.treemap(df_viz, names= 'amenities', values = 'freq', parents = 'parent') )

    else: 
    # Menu Overview -----------
        st.title("Overview")
        st.markdown("""
            Airbnb, Inc. is an American company that operates an online marketplace for lodging, primarily homestays for vacation rentals, and tourism activities.\n\n
            On this dashboard you can explore information regarding the host and room listings available in Bangkok, Central Thailand, Thailand. 
            All data is sourced from publicly available information from the [Airbnb site](http://insideairbnb.com/get-the-data.html).
            All monetary values are presented in local currency (Thailand Baht or THB).
            """)


        # Valuebox --------
        vbox1, vbox2, vbox3, vbox4, vbox5, vbox6 = st.beta_columns([2.5, 6 , 2.5, 6 , 2.5, 6])

        vbox1.image(bed_image)
        vbox2.markdown( "**{:,}".format(int(n_listing)) + "**\n\n Number of Listing")

        vbox3.image(host_image)
        vbox4.markdown( "**{:,}".format(int(n_host)) + "**\n\n Number of Host")

        vbox5.image(bag_image)
        vbox6.markdown( "**{:,}".format(int(n_review)) + "**\n\n Total Reviews")

        # data for map --------------

        query = """
        SELECT id, name, listing_url, latitude, longitude, price, review_scores_rating, number_of_reviews, neighbourhood_cleansed, listing.host_id, host_info.host_name
        FROM listing
        LEFT JOIN host_info
        ON listing.host_id = host_info.host_id
        """

        df_map = pd.read_sql(query, mydb)
        df_map.fillna({'host_name': 'No Host Name', 'review_scores_rating': 'No Rating Yet', 'name': 'No Name'}, inplace = True)

        #Folium Map ------------------
        m = folium.Map(location = [df_map['latitude'].mean(), df_map['longitude'].mean()], # Bangkok coordinate
                       tiles = "Stamen Terrain" # Type of map to draw
                       )

        # Create cluster to prevent clutter and overlap
        marker_cluster = folium.plugins.MarkerCluster().add_to(m)

        for i in range(5000):      
            # Custom popup 

            popup = folium.Html("<b>"  + df_map.name[i] + "</b><br>" +\
                            "Listing ID: " + str(df_map.id[i]) + "<br>" +\
                            "Host Name: " + df_map.host_name[i] + "<br>" +\
                            "Price: THB {:,}".format(df_map.price[i]) + "<br>" +\
                            "Review Scores Rating: " + str(df_map.review_scores_rating[i]) +"<br>" +\
                            "Number of Reviews: {:,}".format(df_map.number_of_reviews[i])  +"<br>" +\
                            "<a href=" + df_map.listing_url[i] + " target='_blank'> Click for more info</a>", 
                            script = True)
            popup = folium.Popup(popup, max_width=2650)        
            
            folium.Marker(location = [df_map.latitude[i], df_map.longitude[i]], 
                        popup= popup).add_to(marker_cluster)

        streamlit_folium.folium_static(m)

print("Finished Deploying")
print("-----------------------")