# Load required packages
library(readr)
library(jsonlite)
library(httr)
library(dplyr)
library(tidyr)
library(lubridate)
library(ggplot2)
library(leaflet)
library(RColorBrewer)
library(geosphere)
library(scales)
library(ggridges)
library(viridis)
library(stringr)

# 1. Data Import
# Dataset-1: Transjakarta - Public Transportation Transaction - Kaggle
dfTransjakarta180kRows <- read_csv("dfTransjakarta180kRows.csv")

# Dataset-2: Transjakarta DKI Jakarta Location Data - SatuData Jakarta
# Define the URL
url <- "https://ws.jakarta.go.id/gateway/DataPortalSatuDataJakarta/1.0/satudata?kategori=dataset&tipe=detail&url=data-lokasi-transjakarta-dki-jakarta"

# Fetch JSON from the live web
response <- GET(url)
content_json <- content(response, as = "text", encoding = "UTF-8")

# Parse JSON
json_data <- fromJSON(content_json)

# Extract the 'data' field
halte_df <- json_data$data

# Rename columns to English
halte_df <- halte_df %>%
  rename(
    corridor = koridor,
    route = rute_koridor,
    stop_name = nama_halte,
    stop_location = lokasi_halte,
    built_year = dibangun_tahun,
    notes = keterangan,
    data_period = periode_data
  )



write.csv(
  trans_df_stop,         # your data frame
  file      = "trans_df_stop.csv",  # output filename (in your working dir)
  row.names = FALSE    # don’t include the automatic row-number column
)






trips      <- read_csv("trans_df_stop.csv")
halte_meta <- read_csv("halte_df_clean.csv")

# normalize halte_meta to UPPER
halte_meta_uc <- halte_meta %>%
  mutate(stop_name_uc = str_to_upper(stop_name))

halte_meta_uc <- halte_meta_uc %>%
  distinct(stop_name_uc, .keep_all = TRUE)

trips2 <- trips %>%
  mutate(
    tapIn_uc  = str_to_upper(tapInStopsName),
    tapOut_uc = str_to_upper(tapOutStopsName)
  ) %>%
  left_join(
    halte_meta_uc %>% select(stop_name_uc, built_year, notes),
    by = c("tapIn_uc" = "stop_name_uc")
  ) %>%
  rename(
    tapIn_built_year = built_year,
    tapIn_notes      = notes
  ) %>%
  left_join(
    halte_meta_uc %>% select(stop_name_uc, built_year, notes),
    by = c("tapOut_uc" = "stop_name_uc")
  ) %>%
  rename(
    tapOut_built_year = built_year,
    tapOut_notes      = notes
  ) %>%
  select(-tapIn_uc, -tapOut_uc)



write.csv(
  trips2,         # your data frame
  file      = "trips2",  # output filename (in your working dir)
  row.names = FALSE    # don’t include the automatic row-number column
)

























# 2. Data Wrangling and Checking
# A) Consistent Corridor Data
# Dataset-1
corridor_data <- dfTransjakarta180kRows %>%
  select(corridorID, corridorName) %>%
  distinct() %>%
  arrange(as.numeric(corridorID))

# Lookup Table
corridor_lookup <- dfTransjakarta180kRows %>%
  filter(!is.na(corridorID), !is.na(corridorName)) %>%
  filter(grepl("^[0-9]+$", corridorID)) %>%
  distinct(corridorID, corridorName) %>%
  arrange(as.numeric(corridorID))

# Lookup Table
busstop_lookup <- dfTransjakarta180kRows %>%
  filter(!is.na(tapInStopsName), !is.na(tapOutStopsName)) %>%
  filter(grepl("^[0-9]+$", c(tapInStopsName,tapOutStopsName))) %>%
  distinct(tapInStopsName, tapOutStopsName) %>%
  arrange(as.numeric(corridorID))

# Fill in Missing Value
trans_df_corridor <- dfTransjakarta180kRows %>%
  left_join(corridor_lookup, by = "corridorID", suffix = c("", "_from_lookup")) %>%
  mutate(corridorName = if_else(is.na(corridorName), corridorName_from_lookup, corridorName)) %>%
  select(-corridorName_from_lookup)

trans_df_corridor <- trans_df_corridor %>%
  left_join(corridor_lookup, by = "corridorName", suffix = c("", "_from_lookup2")) %>%
  mutate(corridorID = if_else(is.na(corridorID), corridorID_from_lookup2, corridorID)) %>%
  select(-corridorID_from_lookup2)

trans_df_corridor <- trans_df_corridor %>%
  filter(grepl("^[0-9]+$", corridorID)) %>%
  select(corridorID, corridorName) %>%
  distinct() %>%
  arrange(as.numeric(corridorID))

# Filter only the corridorID = [1,14]
trans_df_corridor <- trans_df_corridor %>%
  filter(grepl("^[0-9]+$", corridorID))

# Dataset-2
halte_df_clean <- halte_df %>%
  mutate(corridor = as.numeric(gsub("Koridor ", "", corridor)))

# B) Consistent Bus Stops Data
# Dataset-1
# Tap-in lookup table
tapin_lookup <- trans_df_corridor %>%
  filter(!is.na(tapInStops), !is.na(tapInStopsName)) %>%
  distinct(tapInStops, tapInStopsName)

tapin_lookup %>%
  count(tapInStops) %>%
  filter(n > 1) # duplicated stop ID with multiple names

tapin_lookup %>%
  count(tapInStopsName) %>%
  filter(n > 1)  # duplicated stop name with multiple stop IDs

# Tap-out lookup table
tapout_lookup <- trans_df_corridor %>%
  filter(!is.na(tapOutStops), !is.na(tapOutStopsName)) %>%
  distinct(tapOutStops, tapOutStopsName)

tapout_lookup %>%
  count(tapOutStops) %>%
  filter(n > 1)

tapout_lookup %>%
  count(tapOutStopsName) %>%
  filter(n > 1)

# View only the Duplicate Cases
dukuh_atas_cases <- trans_df_corridor %>%
  filter(tapInStopsName == "Dukuh Atas 2" | tapOutStopsName == "Dukuh Atas 2")

# Frequency Table for "Dukuh Atas 2" duplicated cases
tapin_combinations <- dukuh_atas_cases %>%
  count(corridorID, tapInStopsName, tapInStops, sort = TRUE)

tapout_combinations <- dukuh_atas_cases %>%
  count(corridorID, tapOutStopsName, tapOutStops, sort = TRUE)

# Combine and Most Frequent Lookup table
# Combine tapIn and tapOut into one long format
stops_combined <- trans_df_corridor %>%
  filter(!is.na(corridorID)) %>%
  select(corridorID, stopName = tapInStopsName, stopID = tapInStops) %>%
  bind_rows(
    trans_df_corridor %>%
      filter(!is.na(corridorID)) %>%
      select(corridorID, stopName = tapOutStopsName, stopID = tapOutStops)
  ) %>%
  filter(!is.na(stopName), !is.na(stopID)) %>%
  count(corridorID, stopName, stopID, sort = TRUE)

# Keep only the most frequent stopID per (corridorID, stopName)
lookup_clean <- stops_combined %>%
  group_by(corridorID, stopName) %>%
  slice_max(n, n = 1, with_ties = FALSE) %>%
  ungroup()

# Fill-in the Missing value
trans_df_stop <- trans_df_corridor %>%
  left_join(lookup_clean, by = c("corridorID", "tapInStopsName" = "stopName"), suffix = c("", "_from_lookup")) %>%
  mutate(tapInStops = if_else(is.na(tapInStops), stopID, tapInStops)) %>%
  filter(is.na(tapInStopsName) | tapInStops == stopID) %>%  # remove mismatched less frequent ones
  select(-stopID, -n)

trans_df_stop <- trans_df_stop %>%
  left_join(lookup_clean, by = c("corridorID", "tapOutStopsName" = "stopName"), suffix = c("", "_from_lookup")) %>%
  mutate(tapOutStops = if_else(is.na(tapOutStops), stopID, tapOutStops)) %>%
  filter(is.na(tapOutStopsName) | tapOutStops == stopID) %>%
  select(-stopID, -n)

# Capitalize Stops And Route Name
# Dataset-1
trans_df_stop <- trans_df_stop %>%
  mutate(
    corridorID = as.numeric(corridorID),
    corridorName = toupper(corridorName),
    tapInStopsName = toupper(tapInStopsName),
    tapOutStopsName = toupper(tapOutStopsName),
    built_year,
    notes
  )

# Dataset-2
halte_df_clean <- halte_df_clean %>%
  mutate(
    route = toupper(route),
    stop_name = toupper(stop_name)
  )

# Compare Stops Name in Dataset-1 and Dataset-2
# Dataset-1
# tapInStops List
tapin_corridors <- trans_df_stop %>%
  select(corridorID, corridorName, stopID = tapInStops, stopName = tapInStopsName) %>%
  filter(!is.na(stopID)) %>%
  distinct()

# tapOutStops List
tapout_corridors <- trans_df_stop %>%
  select(corridorID, corridorName, stopID = tapOutStops, stopName = tapOutStopsName) %>%
  filter(!is.na(stopID)) %>%
  distinct()

# Combine and deduplicate
combined_corridors <- bind_rows(tapin_corridors, tapout_corridors) %>%
  distinct() %>%
  arrange(stopID, corridorID)


combined_corridors <- combined_corridors %>%
  mutate(
    corridorID = as.numeric(corridorID),
    stopName = toupper(stopName)
  )

# Dataset-2
halte_corridors <- halte_df_clean %>%
  select(corridor, stop_name) %>%
  distinct() %>%
  arrange(stop_name, corridor)

# Compare: which stop names in Dataset-1 are NOT found in Dataset-2
unmatched_stops <- combined_corridors %>%
  anti_join(halte_corridors, by = c("corridorID" = "corridor", "stopName" = "stop_name")) %>%
  arrange(corridorID, stopID, stopName)

# Exclude unmatched_stops on the Dataset-1
unmatched_names <- unmatched_stops$stopName # character vector

trans_df_stop <- trans_df_stop %>%
  filter(
    !(toupper(tapInStopsName) %in% unmatched_names |
        toupper(tapOutStopsName) %in% unmatched_names)
  ) %>%
  mutate(
    tapInStopsName = toupper(tapInStopsName),
    tapOutStopsName = toupper(tapOutStopsName),
    corridorName = toupper(corridorName)
  )

# C) User Profile
# Duplicate transID
trans_df_stop %>%
  count(transID) %>%
  filter(n > 1)

# Card with several name
payCardName_by_ID <- trans_df_stop %>%
  filter(!is.na(payCardID), !is.na(payCardName)) %>%
  distinct(payCardID, payCardName) %>%  # ensure uniqueness of ID-name pair
  count(payCardID, sort = TRUE)

# Bank
payCardBank_summary <- trans_df_stop %>%
  mutate(payCardBank = if_else(is.na(payCardBank), "NA", payCardBank)) %>%
  count(payCardBank, sort = TRUE)

# Name
payCardName_na_summary <- trans_df_stop %>%
  summarise(
    total = n(),
    na_count = sum(is.na(payCardName)),
    non_na_count = sum(!is.na(payCardName))
  )

# Sex
payCardSex_summary <- trans_df_stop %>%
  mutate(payCardSex = if_else(is.na(payCardSex), "NA", payCardSex)) %>%
  count(payCardSex, sort = TRUE)

# Birth Date
birth_stats <- trans_df_stop %>%
  summarise(
    min_birth_year = min(payCardBirthDate, na.rm = TRUE),
    max_birth_year = max(payCardBirthDate, na.rm = TRUE),
    na_count = sum(is.na(payCardBirthDate))
  )

# Capitalize all the value
trans_df_stop <- trans_df_stop %>%
  mutate(
    payCardBank = toupper(payCardBank),
    payCardName = toupper(payCardName)
    )

# D) Geolocation
# Tap In Stops
tapin_location_check <- trans_df_stop %>%
  filter(!is.na(tapInStops), !is.na(tapInStopsLat), !is.na(tapInStopsLon)) %>%
  distinct(tapInStops, tapInStopsLat, tapInStopsLon) %>%
  count(tapInStops) %>%
  filter(n > 1)

# Tap Out Stops
tapout_location_check <- trans_df_stop %>%
  filter(!is.na(tapOutStops), !is.na(tapOutStopsLat), !is.na(tapOutStopsLon)) %>%
  distinct(tapOutStops, tapOutStopsLat, tapOutStopsLon) %>%
  count(tapOutStops) %>%
  filter(n > 1)

# E) Transaction Data
# TapIn Missing
tapin_mismatch <- trans_df_stop %>%
  mutate(
    tapInStops_is_na = is.na(tapInStops),
    tapInStopsName_is_na = is.na(tapInStopsName)
  ) %>%
  count(tapInStops_is_na, tapInStopsName_is_na)

# TapOut Missing
tapout_mismatch <- trans_df_stop %>%
  mutate(
    tapOutStops_is_na = is.na(tapOutStops),
    tapOutStopsName_is_na = is.na(tapOutStopsName)
  ) %>%
  count(tapOutStops_is_na, tapOutStopsName_is_na)

# List The Missing Data
missing_tapout_rows <- trans_df_stop %>%
  filter(is.na(tapOutStops) & is.na(tapOutStopsName))

missing_summary <- missing_tapout_rows %>%
  mutate(tapInDate = as.Date(tapInTime)) %>%
  count(corridorID, tapInDate, sort = TRUE)

# Drop Missing Data
trans_df_cleaned <- trans_df_stop %>%
  filter(!(is.na(tapOutStops) & is.na(tapOutStopsName)))

# F) Extended Data Wrangling
# Trip Duration
trans_df_cleaned <- trans_df_cleaned %>%
  mutate(
    tapInTime = as.POSIXct(tapInTime, format = "%Y-%m-%d %H:%M:%S"),
    tapOutTime = as.POSIXct(tapOutTime, format = "%Y-%m-%d %H:%M:%S"),
    trip_duration = as.numeric(difftime(tapOutTime, tapInTime, units = "mins"))
  )

time_violations <- trans_df_cleaned %>%
  filter(is.na(trip_duration) | trip_duration <= 0)

summary(trans_df_cleaned$trip_duration)

# Stop Sequences
trans_df_cleaned <- trans_df_cleaned %>%
  mutate(
    trip_sequences = as.numeric(difftime(stopEndSeq, stopStartSeq))
  )

seq_violations <- trans_df_cleaned %>%
  filter(is.na(trip_sequences) | trip_sequences <= 0)


write.csv(
  trans_df_cleaned, 
  file = "trans_df_cleaned.csv",     # path/filename you want to write
  row.names = FALSE         # omit the row numbers column
)


# 3. Data Exploration
# Question 1
# 1.1 Weekday vs. Weekend (Time Series - Line Plot)
# Step 1: Extract hour and classify weekday/weekend
trans_time_series <- trans_df_cleaned %>%
  mutate(
    tapInTime = as.POSIXct(tapInTime, format = "%Y-%m-%d %H:%M:%S"),
    hour = hour(tapInTime),
    day = weekdays(tapInTime),
    day_type = if_else(day %in% c("Saturday", "Sunday"), "Weekend", "Weekday")
  )

# Step 2: Count number of trips per hour per date and day_type
trip_counts <- trans_time_series %>%
  mutate(date = as.Date(tapInTime)) %>%
  group_by(date, hour, day_type) %>%
  summarise(trips = n(), .groups = "drop")

# Step 3: Calculate average and IQR of trips per hour by day_type
trip_summary <- trip_counts %>%
  group_by(hour, day_type) %>%
  summarise(
    avg_trips = mean(trips),
    lower = quantile(trips, 0.25),
    upper = quantile(trips, 0.75),
    .groups = "drop"
  )

# Step 4: Plot
ggplot(trip_summary, aes(x = hour, y = avg_trips, color = day_type, fill = day_type)) +
  geom_line(size = 1.2) +
  geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.2, color = NA) +
  labs(
    title = "Average Hourly Trip Count: Weekday vs. Weekend",
    subtitle = "With Interquartile Range (IQR) Bands",
    x = "Hour of Day",
    y = "Average Number of Trips",
    color = "Day Type",
    fill = "Day Type"
  ) +
  scale_x_continuous(breaks = seq(0, 23, 1)) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(size = 18, face = "bold", margin = margin(b = 10)),
    plot.subtitle = element_text(size = 11, margin = margin(b = 15)),
    axis.title.x = element_text(margin = margin(t = 12)),
    axis.title.y = element_text(margin = margin(r = 12)),
    plot.margin = margin(15, 15, 15, 15)  # Top, right, bottom, left
  )

# 1.2. Heatmaps of Demand: Hour vs. Day of Week
# Step 1: Classify and summarize trips by hour, date, and weekday
heatmap_data_grouped <- trans_df_cleaned %>%
  mutate(
    tapInTime = as.POSIXct(tapInTime),
    date = as.Date(tapInTime),
    hour = hour(tapInTime),
    weekday = weekdays(tapInTime),
    day_type = if_else(weekday %in% c("Saturday", "Sunday"), "Weekend", "Weekday"),
    weekday = factor(weekday, levels = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"))
  ) %>%
  group_by(day_type, weekday, date, hour) %>%
  summarise(daily_trips = n(), .groups = "drop") %>%
  group_by(day_type, weekday, hour) %>%
  summarise(avg_trips = mean(daily_trips), .groups = "drop")

# Step 2: Normalize avg_trips within each day_type group
heatmap_normalized <- heatmap_data_grouped %>%
  group_by(day_type) %>%
  mutate(scaled_trips = avg_trips / max(avg_trips)) %>%
  ungroup()

# Step 3: Plot
ggplot(heatmap_normalized, aes(x = hour, y = weekday, fill = scaled_trips)) +
  geom_tile(color = "white", linewidth = 0.4) +
  scale_fill_gradientn(
    colours = c("#deebf7", "#9ecae1", "#3182bd", "#feb24c", "#f03b20"),
    name = "Proportional Demand",
    labels = scales::percent_format(accuracy = 1)
  ) +
  labs(
    title = "Proportional Heatmap of Transjakarta Demand",
    subtitle = "Trip Frequency Relative to Peak Demand (Weekdays vs. Weekends Scaled Separately)",
    x = "Hour of Day",
    y = "Day of Week"
  ) +
  scale_x_continuous(breaks = seq(0, 23, 1)) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(size = 18, face = "bold", margin = margin(b = 8)),
    plot.subtitle = element_text(size = 11, margin = margin(b = 12)),
    axis.title.x = element_text(margin = margin(t = 10)),
    axis.title.y = element_text(margin = margin(r = 10)),
    plot.margin = margin(15, 15, 15, 15)
  )

# 1.3. Map-Based Demand Analysis
library(dplyr)         # for select(), rename(), group_by(), summarise(), %>%  
library(RColorBrewer)  # for brewer.pal()  
library(leaflet)       # for leaflet(), addProviderTiles(), addCircleMarkers(), colorFactor(), providers, addLegend()  

# Step 1: Create a vibrant color palette (max 12 unique vibrant colors for 12 corridors)
corridors <- sort(unique(as.numeric(trans_df_cleaned$corridorID)))
pal <- colorFactor(palette = brewer.pal(n = 12, name = "Paired"), domain = corridors)

# Step 2: Calculate total demand per stop (tapIn + tapOut combined), keeping corridorID
stop_demand <- trans_df_cleaned %>%
  select(corridorID, tapInStops, tapInStopsName, tapInStopsLat, tapInStopsLon) %>%
  rename(stopID = tapInStops, stopName = tapInStopsName, lat = tapInStopsLat, lon = tapInStopsLon) %>%
  bind_rows(
    trans_df_cleaned %>%
      select(corridorID, tapOutStops, tapOutStopsName, tapOutStopsLat, tapOutStopsLon) %>%
      rename(stopID = tapOutStops, stopName = tapOutStopsName, lat = tapOutStopsLat, lon = tapOutStopsLon)
  ) %>%
  filter(!is.na(stopID), !is.na(lat), !is.na(lon), !is.na(corridorID)) %>%
  group_by(corridorID, stopID, stopName, lat, lon) %>%
  summarise(demand = n(), .groups = "drop")

# Step 3: Plot the map (circles only, no messy lines)
leaflet(stop_demand) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%  # Grayscale map
  addCircleMarkers(
    lng = ~lon,
    lat = ~lat,
    radius = ~sqrt(demand) * 1.5,  # Increase circle size
    color = ~pal(corridorID),
    stroke = TRUE,
    weight = 1,
    fillOpacity = 0.85,
    popup = ~paste0(
      "<b>", stopName, "</b><br>",
      "Corridor: ", corridorID, "<br>",
      "Total Trips: ", demand
    ),
    popupOptions = popupOptions(direction = "right")
  ) %>%
  addLegend(
    "bottomright",
    pal = pal,
    values = ~corridorID,
    title = "Corridor ID",
    opacity = 1
  )

# 1.4. Route Efficiency Index
# Step 1: Calculate average duration, distance, and efficiency
route_efficiency <- trans_df_cleaned %>%
  filter(!is.na(corridorID), !is.na(tapInStopsLat), !is.na(tapOutStopsLat),
         !is.na(tapInTime), !is.na(tapOutTime)) %>%
  mutate(
    corridorID = as.numeric(corridorID),
    duration_min = as.numeric(difftime(tapOutTime, tapInTime, units = "mins")),
    distance_km = distHaversine(
      cbind(tapInStopsLon, tapInStopsLat),
      cbind(tapOutStopsLon, tapOutStopsLat)
    ) / 1000
  ) %>%
  filter(duration_min > 0, distance_km > 0) %>%
  group_by(corridorID) %>%
  summarise(
    avg_duration = mean(duration_min),
    avg_distance = mean(distance_km),
    efficiency_index = avg_duration / avg_distance,
    .groups = "drop"
  ) %>%
  mutate(corridorID = factor(corridorID, levels = sort(unique(corridorID))))

# Step 2: Assign corridor colors
corridor_colors <- brewer.pal(12, "Paired")[1:length(unique(route_efficiency$corridorID))]

# Step 3: Scaling duration and distance to match bar height
max_eff <- max(route_efficiency$efficiency_index)
max_dur <- max(route_efficiency$avg_duration)
max_dist <- max(route_efficiency$avg_distance)

route_efficiency <- route_efficiency %>%
  mutate(
    scaled_duration = (avg_duration / max_dur) * max_eff,
    scaled_distance = (avg_distance / max_dist) * max_eff
  )

# Step 4: Plot
ggplot(route_efficiency, aes(x = corridorID)) +
  geom_col(aes(y = efficiency_index, fill = corridorID), width = 0.6) +
  
  # Line + Points for Avg. Duration
  geom_line(aes(y = scaled_duration, group = 1, color = "Avg. Duration"),
            linetype = "dashed", size = 1.2) +
  geom_point(aes(y = scaled_duration, color = "Avg. Duration"), shape = 16, size = 2.5) +
  
  # Line + Points for Avg. Distance
  geom_line(aes(y = scaled_distance, group = 1, color = "Avg. Distance"),
            linetype = "solid", size = 1.2) +
  geom_point(aes(y = scaled_distance, color = "Avg. Distance"), shape = 16, size = 2.5) +
  
  # Colors
  scale_fill_manual(values = corridor_colors) +
  scale_color_manual(
    name = NULL,
    values = c("Avg. Duration" = "black", "Avg. Distance" = "gray40")
  ) +
  
  # Axes
  scale_y_continuous(
    name = "Route Efficiency Index (min/km)",
    sec.axis = sec_axis(~ . * max_dur / max_eff, name = "")
  ) +
  
  # Labels
  labs(
    title = "Route Efficiency Index by Corridor",
    subtitle = "Including Average Trip Duration and Distance",
    x = "Corridor ID",
    fill = "Corridor"
  ) +
  
  # Theme
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(size = 18, face = "bold", margin = margin(b = 14)),
    plot.subtitle = element_text(size = 13, margin = margin(b = 16)),
    axis.title.x = element_text(margin = margin(t = 14)),
    axis.title.y = element_text(margin = margin(r = 14)),
    axis.title.y.right = element_text(margin = margin(l = 14)),
    legend.position = "bottom",
    legend.box = "vertical",
    legend.spacing.y = unit(4, "pt"),
    legend.title = element_text(face = "bold"),
    legend.text = element_text(size = 10),
    legend.box.just = "center",
    legend.margin = margin(t = 8),
    legend.key.height = unit(0.5, "lines"),
    legend.key.width = unit(0.5, "lines"),
    legend.box.spacing = unit(5, "pt")
  ) +
  
  # Legends in one line
  guides(
    fill = guide_legend(nrow = 1, title.position = "top", title.hjust = 0.5),
    color = guide_legend(
      override.aes = list(linetype = c("dashed", "solid"), shape = 16),
      nrow = 1
    )
  )

# Question 2
# 2.1 100% Stacked Bar Chart – Gender Proportion per Corridor
# Clean and standardize gender labels
gender_prop <- trans_df_cleaned %>%
  filter(!is.na(payCardSex), !is.na(corridorID)) %>%
  mutate(
    payCardSex = case_when(
      tolower(payCardSex) %in% c("l", "male", "m") ~ "Male",
      tolower(payCardSex) %in% c("p", "female", "f") ~ "Female",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(payCardSex)) %>%
  group_by(corridorID, payCardSex) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(corridorID) %>%
  mutate(
    prop = count / sum(count),
    corridorID = factor(corridorID, levels = sort(unique(corridorID)))
  )

# Plot: Gender Proportion by Corridor
ggplot(gender_prop, aes(x = corridorID, y = prop, fill = payCardSex)) +
  geom_bar(stat = "identity", position = "fill", width = 0.7) +
  scale_fill_manual(values = c("Male" = "skyblue", "Female" = "lightcoral")) +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(
    title = "Gender Proportion per Corridor",
    x = "Corridor ID",
    y = "Proportion of Users",
    fill = "Gender"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(size = 16, face = "bold", margin = margin(b = 10)),
    axis.title.x = element_text(margin = margin(t = 10)),
    axis.title.y = element_text(margin = margin(r = 10)),
    legend.position = "top"
  )

# 2.2. Age Distribution by Corridor - Density Plot
# Step 1: Recalculate age and factor corridor
trans_df_ridge <- trans_df_cleaned %>%
  filter(!is.na(payCardBirthDate), !is.na(corridorID)) %>%
  mutate(
    age = 2023 - as.numeric(payCardBirthDate),
    corridorID = factor(corridorID, levels = sort(unique(corridorID)))  # Clean factor after filtering
  )

# Step 2: Define consistent color palette (same as Leaflet map)
corridor_colors <- brewer.pal(12, "Paired")[1:length(unique(trans_df_ridge$corridorID))]

# Step 3: Plot ridgeline with fixed color per corridor
ggplot(trans_df_ridge, aes(x = age, y = corridorID, fill = corridorID)) +
  geom_density_ridges(scale = 3, rel_min_height = 0.01, alpha = 0.9, color = "white") +
  scale_fill_manual(values = corridor_colors) +
  labs(
    title = "Age Distribution by Corridor",
    x = "User Age",
    y = "Corridor ID",
    fill = "Corridor"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(size = 16, face = "bold", margin = margin(b = 10)),
    axis.title.x = element_text(margin = margin(t = 10)),
    axis.title.y = element_text(margin = margin(r = 10)),
    legend.position = "none"  # Optional: turn off legend if visual clarity is better
  )

# 2.3. 100% Stacked Chart - Payment Method by Corridor
# Step 1: Clean and aggregate data
bank_prop <- trans_df_cleaned %>%
  filter(!is.na(payCardBank), !is.na(corridorID)) %>%
  count(corridorID, payCardBank, name = "count") %>%
  group_by(corridorID) %>%
  mutate(prop = count / sum(count)) %>%
  ungroup()

# Step 2: Plot using viridis palette
ggplot(bank_prop, aes(x = factor(corridorID), y = prop, fill = payCardBank)) +
  geom_bar(stat = "identity", position = "fill", width = 0.7) +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_viridis_d(option = "D", begin = 0, end = 0.9, direction = 1, name = "Payment Method") +
  labs(
    title = "Proportion of Payment Methods per Corridor",
    x = "Corridor ID",
    y = "Proportion of Users"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(size = 16, face = "bold", margin = margin(b = 10)),
    axis.title.x = element_text(margin = margin(t = 10)),
    axis.title.y = element_text(margin = margin(r = 10)),
    legend.position = "top"
  )

# Question 3
# STEP 1: Rank each Corridor by Total Trips
corridor_rank <- trans_df_cleaned %>%
  filter(!is.na(corridorID)) %>%
  count(corridorID, name = "total_trips") %>%
  mutate(corridor_rank = dense_rank(desc(total_trips)))

# STEP 2: Rank Each Bus Stop by Total Trips (tapIn + tapOut combined)
stop_trips <- trans_df_cleaned %>%
  filter(!is.na(tapInStops) & !is.na(tapInStopsName)) %>%
  select(stopID = tapInStops, stopName = tapInStopsName, corridorID) %>%
  bind_rows(
    trans_df_cleaned %>%
      filter(!is.na(tapOutStops) & !is.na(tapOutStopsName)) %>%
      select(stopID = tapOutStops, stopName = tapOutStopsName, corridorID)
  ) %>%
  group_by(stopID, stopName, corridorID) %>%
  summarise(trips = n(), .groups = "drop")

# STEP 3: Female > 50% per Corridor
female_flags <- trans_df_cleaned %>%
  filter(!is.na(payCardSex), !is.na(corridorID)) %>%
  mutate(sex = case_when(
    str_to_lower(payCardSex) %in% c("female", "p", "f") ~ "Female",
    str_to_lower(payCardSex) %in% c("male", "l", "m") ~ "Male",
    TRUE ~ NA_character_
  )) %>%
  group_by(corridorID, sex) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(corridorID) %>%
  mutate(prop = count / sum(count)) %>%
  filter(sex == "Female") %>%
  mutate(female_service = if_else(prop > 0.5, "Yes", "No")) %>%
  select(corridorID, female_service)

# STEP 4: Older People Corridor (>55 avg)
age_flags <- trans_df_cleaned %>%
  filter(!is.na(payCardBirthDate), !is.na(corridorID)) %>%
  mutate(age = 2023 - as.numeric(payCardBirthDate)) %>%
  group_by(corridorID) %>%
  summarise(median_age = median(age, na.rm = TRUE)) %>%
  mutate(older_access = if_else(median_age > 55, "Yes", "No")) %>%
  select(corridorID, older_access)

# STEP 5: Top Payment Methods > 25%
payment_flags <- trans_df_cleaned %>%
  filter(!is.na(corridorID), !is.na(payCardBank)) %>%
  group_by(corridorID, payCardBank) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(corridorID) %>%
  mutate(prop = count / sum(count)) %>%
  filter(prop >= 0.25) %>%
  arrange(corridorID, desc(prop)) %>%
  group_by(corridorID) %>%
  summarise(payment_methods = paste(head(payCardBank, 3), collapse = ", "))

# STEP 6: Merge All Tables
final_table <- stop_trips %>%
  left_join(corridor_rank, by = "corridorID") %>%
  left_join(female_flags, by = "corridorID") %>%
  left_join(age_flags, by = "corridorID") %>%
  left_join(payment_flags, by = "corridorID") %>%
  arrange(desc(trips))

# STEP 6.X: Add Bus Stops Rank and Corridor REI Rank
final_table <- final_table %>%
  arrange(desc(trips)) %>%
  mutate(bus_stop_rank = dense_rank(desc(trips)))

rei_rank <- route_efficiency %>%
  select(corridorID, efficiency_index) %>%
  mutate(rei_rank = dense_rank(efficiency_index))

rei_rank <- rei_rank %>%
  mutate(corridorID = as.numeric(as.character(corridorID)))

final_table <- final_table %>%
  left_join(rei_rank, by = "corridorID")

# STEP 7: Add built year and notes from dataset-2
halte_df_clean <- halte_df_clean %>%
  mutate(
    corridor = as.numeric(gsub("Koridor ", "", corridor)),
    stop_name = toupper(stop_name)
  )

# Step 8: Make sure stopName in final_table is capitalized to match
final_table <- final_table %>%
  mutate(stopName = toupper(stopName))

# Step 9: Join built_year and notes
final_table_with_info <- final_table %>%
  left_join(
    halte_df_clean %>%
      select(corridor, stop_name, built_year, notes),
    by = c("corridorID" = "corridor", "stopName" = "stop_name")
  )

# Step 10: Calculate age of the stop
final_table_with_info <- final_table_with_info %>%
  mutate(
    bus_stop_age = 2023 - as.numeric(built_year)
  )

# Step 11: Rank age: oldest = rank 1
final_table_with_info <- final_table_with_info %>%
  mutate(
    age_rank = dense_rank(desc(stop_age))  # oldest = rank 1
  )

# Step 12: Remove 'built_year' column
final_table_with_info <- final_table_with_info %>%
  select(-built_year)

# View final enriched table
head(final_table_with_info)

# Final: Export XlSX
install.packages("writexl")

# Load the package
library(writexl)

# Export to Excel
write_xlsx(final_table_with_info, path = "final_table_with_info.xlsx")
