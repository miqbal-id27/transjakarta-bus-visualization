# Data Dictionary

## `docs/data/bus_stop_network.json`

Contains the spatial network structure used by the D3 map.

Top-level fields:

- `nodes`: bus stop records.
- `edges`: inter-stop connection records.

Node fields:

| Field | Description |
|---|---|
| `id` | Bus stop identifier |
| `name` | Bus stop name |
| `lat` | Latitude |
| `lon` | Longitude |
| `built_year` | Bus stop construction year, when available |
| `remarks` | Infrastructure/access remarks, when available |
| `corridor` | Corridor identifier and route description |

Edge fields:

| Field | Description |
|---|---|
| `source` | Source bus stop ID |
| `target` | Target bus stop ID |
| `weight` | Connection weight used for visual thickness |

Current file summary: **287 nodes**, **1231 edges**, **14 corridors**.

## `docs/data/bus_stop_timeseries.json`

Daily trip-count summary by stop.

| Field | Description |
|---|---|
| `id` | Bus stop name or stop identifier used for chart matching |
| `date` | Date of observation |
| `weekday` | Weekday/weekend category |
| `count` | Trip count |

Current file summary: **5202 rows**, covering **2023-04-01 to 2023-04-30**.

## `docs/data/bus_stop_population.json`

Demographic summary by stop.

| Field | Description |
|---|---|
| `id` | Bus stop name or stop identifier used for chart matching |
| `age_grp` | Age group |
| `sex` | Sex category |
| `pop` | Count used for population pyramid |

Current file summary: **1155 rows**.

## `docs/data/jakarta-simplified-topo.json`

Simplified Jakarta boundary in TopoJSON format used as the base map.
