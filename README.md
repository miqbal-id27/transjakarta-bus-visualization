# Transjakarta Public Bus Interconnectivity and Coverage

Interactive D3.js portfolio project that explores **Transjakarta bus stop interconnectivity, ridership patterns, and demographic coverage** across Jakarta.

## Live Demo

After enabling GitHub Pages, the final web project will be available at:

```text
https://miqbal-id27.github.io/transjakarta-public-bus-portfolio/
```

Replace `transjakarta-public-bus-portfolio` with your actual repository name if you use a different repo.

## Executive Summary

Jakarta's Transjakarta network is one of the most important public transport systems in Indonesia. This project investigates how bus stop usage, corridor connectivity, and rider demographics can support better transport planning decisions.

The project combines transaction-level trip data with official bus stop metadata, then transforms the cleaned data into browser-ready JSON files for an interactive D3.js visualization. The final output helps non-technical stakeholders explore the network through a map-first interface, supported by stop-level ridership trends and demographic breakdowns.

The visualization is designed for government bodies, transport planners, and state-owned company executives who need a quick way to identify bus stop demand patterns, understand user profiles, and consider which locations may require future upgrades.

## Key Questions

1. How do bus stop usage patterns and traffic volumes affect route efficiency?
2. What are the user profiles across routes, and how can this inform service improvements?
3. Which bus stops may require upgrades to accommodate increasing passenger demand?

## Final Interactive Features

- Jakarta map with Transjakarta bus stop network overlay
- Corridor-based node coloring and legend
- Pan and zoom interaction
- Hover tooltip for bus stop details
- Bus stop dropdown selector
- Weekday vs weekend ridership trend chart
- Population pyramid by age group and sex
- Click-to-filter stop-level drill-down
- Reset to city-wide overview through “All Stops”

## Dataset Summary

| File | Purpose | Records |
|---|---:|---:|
| `docs/data/bus_stop_network.json` | Bus stop nodes and inter-stop edges | 287 nodes, 1231 edges |
| `docs/data/bus_stop_timeseries.json` | Daily ridership trend by stop | 5202 rows |
| `docs/data/bus_stop_population.json` | Age/sex population breakdown by stop | 1155 rows |
| `docs/data/jakarta-simplified-topo.json` | Jakarta boundary map | TopoJSON |

Time coverage in the processed demo data: **2023-04-01 to 2023-04-30**.

## Repository Structure

```text
transjakarta-public-bus-portfolio/
├── README.md
├── GITHUB_SETUP.md
├── .gitignore
├── docs/
│   ├── index.html
│   ├── executive-summary.md
│   ├── project-process.md
│   ├── data-dictionary.md
│   └── data/
│       ├── bus_stop_network.json
│       ├── bus_stop_timeseries.json
│       ├── bus_stop_population.json
│       └── jakarta-simplified-topo.json
├── notebooks/
│   └── visualization_design_process.Rmd
├── src/
│   └── data_collection_and_eda.R
└── references/
    ├── project_proposal.pdf
    ├── data_exploration_report.pdf
    └── five_design_sheets.pdf
```

## Step-by-Step Project Workflow

### 1. Data Collection

Two main datasets were used:

- Transjakarta transaction data from Kaggle, containing trip, route, user profile, timestamp, payment, and stop information.
- Official Transjakarta bus stop location data from Satu Data Jakarta, containing corridor, route, bus stop name, location, built year, and infrastructure remarks.

### 2. Data Cleaning and EDA

The data was cleaned and explored in R. Main steps included:

- filtering relevant major corridors,
- standardizing corridor names and IDs,
- joining transaction data with bus stop metadata,
- resolving inconsistent stop IDs,
- checking user, geolocation, and transaction fields,
- aggregating trip data by hour, date, weekday/weekend, and stop,
- exploring demand patterns through time-series charts, heatmaps, map-based demand views, and route efficiency analysis.

### 3. Five Design Sheet Process

The project used a Five Design Sheet process to move from broad ideas into a focused final design:

1. **Brainstorming** — explored bar charts, line charts, flow maps, density plots, connectivity graphs, and demographic visuals.
2. **Alternative Design 1** — tested interactive map and legend-based filtering.
3. **Alternative Design 2** — tested a chart-heavy layout but found that geographic context was too important to remove.
4. **Alternative Design 3** — refined the map-first approach with zoom, hover tooltips, and filtering.
5. **Realisation** — selected a map-centered D3 design with sidebar charts for stop-level drill-down.

### 4. Implementation

The final demo was implemented using:

- **HTML/CSS/JavaScript** for the web page
- **D3.js v7** for map, network, line chart, and population pyramid rendering
- **TopoJSON Client** for converting Jakarta TopoJSON into GeoJSON
- **R / tidyverse / jsonlite** for data preparation and JSON export
- **GitHub Pages** for static web deployment

### 5. How to Access the Final Project

Local access:

```bash
cd transjakarta-public-bus-portfolio/docs
python -m http.server 8000
```

Open:

```text
http://localhost:8000
```

Online access after GitHub Pages setup:

```text
https://miqbal-id27.github.io/transjakarta-public-bus-portfolio/
```

## What Was Excluded

To keep the repository clean, this package excludes:

- raw large CSV files,
- Excel working files,
- duplicated JSON files,
- assignment brief files,
- the final implementation report PDF.

The repository keeps only files needed to understand, reproduce, and present the portfolio project.

## Tech Stack

`R` · `tidyverse` · `jsonlite` · `HTML` · `CSS` · `JavaScript` · `D3.js` · `TopoJSON` · `GitHub Pages`
