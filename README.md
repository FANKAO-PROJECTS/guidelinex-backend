# GuideScope Backend - API Service

This is the core API service for the GuideScope Discovery Platform, responsible for ingesting, indexing, and serving clinical guideline data.

## 🛠️ Technology Stack
- **Framework**: Spring Boot 4.0.1
- **Language**: Java 17
- **Database**: PostgreSQL (Structured data)
- **Search Engine**: Hibernate Search + Lucene (Full-text search)
- **Monitoring**: Spring Boot Actuator

## 📂 Key Architecture
- `com.guidescope.controller`: REST API Endpoints (Search, Autocomplete, Capabilities)
- `com.guidescope.model`: JPA Entities for Clinical Guidelines
- `com.guidescope.repository`: Data access layer
- `com.guidescope.service`: Business logic for search and indexing

## 🚀 Getting Started
This service is designed to be run as part of the GuideScope monorepo.
- **Prerequisites**: JDK 17, Docker (for Database)
- **Execution**: Use the scripts in the root `/scripts/` directory:
  - `run-backend.ps1` (Windows)
  - `./run-backend.sh` (Linux/macOS)

## 📡 API Endpoints
- `GET /search`: Unified search interface with filters.
- `GET /search/autocomplete`: Fast, partial-match title search.
- `GET /search/capabilities`: Dynamic discovery of available filter values.
- `GET /actuator/health`: System health status.

---
Part of the [GuideScope](..) platform.
