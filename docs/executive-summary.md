# Executive Summary

## Project Title

**Transjakarta: Jakarta Public Bus Interconnectivity and Coverage**

## Purpose

This project analyzes Jakarta's Transjakarta bus network from three perspectives: spatial interconnectivity, temporal demand, and rider demographic coverage. The aim is to help transport stakeholders identify high-demand bus stops, understand weekday/weekend travel behavior, and support future service or infrastructure improvements.

## Business Context

Jakarta's public transport system serves a dense and growing metropolitan area. Because demand is expected to increase over time, decision makers need accessible tools to evaluate whether current stops and routes can support passenger needs.

## Data Used

The analysis combines:

1. **Transjakarta transaction data** — trip records, tap-in/tap-out stops, timestamps, corridors, user demographics, and payment fields.
2. **Official bus stop location data** — corridor name, route, bus stop name, location, built year, data period, and infrastructure remarks.
3. **Jakarta TopoJSON boundary data** — simplified geographic outline for spatial visualization.

## Method Summary

The data was processed in R, cleaned for corridor and stop consistency, aggregated into analysis tables, and exported to lightweight JSON files. The final visualization was built in D3.js so users can interact directly with a map, select bus stops, and compare supporting charts.

## Final Output

The final product is a browser-based interactive visualization with:

- a Jakarta bus stop network map,
- corridor-colored bus stops and links,
- hover tooltips,
- dropdown bus stop filtering,
- weekday vs weekend trend comparison,
- population pyramid for age/sex distribution,
- stop-level drill-down and reset behavior.

## Main Value

The project translates technical data preparation into a decision-friendly interface. It helps users move from a city-wide view into a specific bus stop, making the analysis more useful for executives, planners, and non-technical stakeholders.
