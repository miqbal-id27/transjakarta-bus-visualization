# Project Process

This document summarizes the end-to-end workflow used to build the Transjakarta interactive portfolio project.

## 1. Data Collection

### 1.1 Transjakarta Transaction Dataset

The transaction dataset contains trip-level fields such as user profile, payment card information, route/corridor, tap-in and tap-out stops, coordinates, timestamps, and payment amount.

The dataset was manually downloaded from Kaggle and imported into R for processing.

### 1.2 Transjakarta Bus Stop Location Dataset

The bus stop location dataset was collected from Satu Data Jakarta. It contains corridor names, routes, bus stop names, stop locations, built year, data period, and infrastructure remarks.

The source was retrieved through the Jakarta open-data endpoint and parsed in R using `httr` and `jsonlite`.

### 1.3 Jakarta Boundary TopoJSON

A simplified Jakarta TopoJSON file was used as the spatial base map for the final interactive visualization.

## 2. Data Cleaning and EDA

### 2.1 Corridor Cleaning

The transaction dataset and bus stop location dataset used different corridor formats. Corridor numbers were extracted and standardized so both datasets could be joined.

Main checks:

- missing corridor names,
- missing corridor IDs,
- inconsistent corridor labels,
- invalid corridor references.

A lookup table was created to correct missing or inconsistent corridor values.

### 2.2 Bus Stop Cleaning

Bus stop fields were checked for inconsistent IDs and duplicate stop names. For ambiguous cases, the most frequent valid ID was retained to improve consistency.

The data was filtered to keep only valid stops available in the official bus stop location dataset.

### 2.3 User and Transaction Checks

User profile and payment-card fields were checked for duplicates, missing values, and invalid mappings. Tap-in and tap-out fields were checked for missing values and logical trip sequence.

Trip duration and sequence were validated to avoid negative or illogical values.

### 2.4 EDA Visualizations

Exploratory visualizations included:

- weekday vs weekend hourly line chart,
- hour-by-day demand heatmap,
- stop-level demand map,
- route efficiency analysis,
- demographic profile charts.

These analyses informed which views were most important for the final interactive design.

## 3. Five Design Sheet Process

### Sheet 1 — Brainstorming

The first sheet explored a broad set of possible visuals: bar charts, line charts, pie charts, flow maps, connectivity graphs, and density plots. Ideas were grouped into user profile, connectivity/traffic, and feature categories.

### Sheet 2 — Alternative Design 1

This design explored an interactive map with legend-based filtering and time-based highlighting. It supported multi-perspective exploration but risked being too complex for non-technical stakeholders.

### Sheet 3 — Alternative Design 2

This design emphasized chart-based analysis, especially weekday/weekend and corridor-level trends. It was analytically rich but lacked enough geographic context.

### Sheet 4 — Alternative Design 3

This design moved back to a map-centered layout, adding zoom, hover tooltips, and focused filters. It improved spatial reasoning and made the interface easier for stakeholders to understand.

### Sheet 5 — Realisation

The final design selected a map-first layout with sidebar charts. Users begin from the Jakarta network map, then click or select a stop to update the trend chart and population pyramid.

## 4. Implementation

### 4.1 Data Export

R was used to create JSON files optimized for D3:

- `bus_stop_network.json`
- `bus_stop_timeseries.json`
- `bus_stop_population.json`
- `jakarta-simplified-topo.json`

### 4.2 Front-End Build

The visualization was implemented with HTML, CSS, JavaScript, D3.js, and TopoJSON Client.

The final interface contains:

- map canvas,
- Jakarta boundary layer,
- network links,
- corridor-colored nodes,
- fixed corridor legend,
- hover tooltip,
- bus stop dropdown,
- line chart,
- population pyramid.

### 4.3 Interaction Logic

Interaction rules:

- Hover over a stop to show details.
- Click a stop to update the sidebar charts.
- Select a stop from the dropdown to filter the charts.
- Select “All Stops” or click again to reset to the aggregated overview.
- Pan and zoom the map to inspect dense areas.

## 5. Accessing the Final Project

### Local Access

```bash
cd transjakarta-public-bus-portfolio/docs
python -m http.server 8000
```

Then open:

```text
http://localhost:8000
```

### GitHub Pages Access

After publishing from the `/docs` folder, the website will be available at:

```text
https://miqbal-id27.github.io/transjakarta-public-bus-portfolio/
```

Replace the repository name if you use a different GitHub repository name.
