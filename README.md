# Calm-panion

A crowd-aware journey companion for sensory-sensitive commuters in Melbourne’s CBD.

## Project Overview

Calmer Commute is a web application designed to help sensory-sensitive commuters make more informed travel decisions.

Rather than considering only the shortest route, the application uses City of Melbourne open data to compare supported routes using pedestrian crowd conditions, provide explainable alerts and identify nearby candidate refuge locations.

## Onboarding Vertical Slice

The onboarding build demonstrates:

- Origin and destination entry
- A user-defined crowd threshold
- High and Low route indicators
- Comparison of supported route alternatives
- Crowd-hotspot identification
- A next-hour pedestrian crowd forecast
- Rerouting support
- Candidate refuge discovery
- Explainable recommendations
- Responsible missing-data and limitation messages

## Responsible Scope

Pedestrian crowd information is used as a proxy for one aspect of sensory load.

Calmer Commute does not make clinical, accessibility, quietness or safety guarantees. Parks, libraries and other public places are presented as candidate refuges only.

## Repository Structure

- `data/` — Raw, external and processed datasets
- `ai/` — Features, experiments and prediction models
- `backend/` — APIs and application services
- `frontend/` — Web application interface
- `database/` — Schema, migrations and seed data
- `docs/` — Architecture, governance, API and testing documentation
- `scripts/` — Reproducible ingestion and cleaning scripts
- `tests/` — Integration and acceptance tests

## Branch Strategy

- `main` — Stable and release-ready version
- `development` — Default integration branch
- `AI` — AI and forecasting
- `data` — Data engineering and governance
- `frontend` — Website interface
- `backend` — APIs and services

Changes from specialist branches are integrated into `development` through pull requests. Release-ready work is merged from `development` into `main`.

See [CONTRIBUTING.md](CONTRIBUTING.md) before making changes.

## Core Data Sources

The project uses selected City of Melbourne Open Data, including:

- Pedestrian counts per minute
- Historical pedestrian counts per hour
- Pedestrian sensor locations
- Pedestrian network information
- Public facilities and places of interest

## Product Flow

1. Choose a destination and crowd threshold
2. Compare supported routes
3. Identify crowd hotspots and trade-offs
4. Receive a next-hour warning
5. Reroute or locate a candidate refuge

## Delivery Evidence

For the onboarding vertical slice, the supporting evidence and handoff notes are documented in [docs/testing/VERTICAL_SLICE_DELIVERY.md](docs/testing/VERTICAL_SLICE_DELIVERY.md).

This file covers:

- deployment/build evidence
- repository version and branch
- setup instructions
- end-to-end test evidence
- demo screenshots / recording notes
- mentor review record
- release gate and quality criteria documentation

For traceability and release readiness, also see:

- `docs/testing/ACCEPTANCE_TRACEABILITY_MATRIX.md`
- `docs/testing/RELEASE_CRITERIA.md`
- `docs/testing/VERTICAL_SLICE_SECURITY_ASSESSMENT.md`
- `docs/testing/PRIVACY_RETENTION.md`
- `docs/testing/security-scans/`
- `.github/workflows/ci.yml`

