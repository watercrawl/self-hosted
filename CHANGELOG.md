# Changelog

All notable changes to this project will be documented in this file.

## [v0.2.0] - 2025-01-15

### Added
- Added Playwright service for web automation
- Added Redis data volume for persistence
- Added support for configurable Docker images through environment variables
- Added playwright.env.example template

### Changed
- Updated Docker Compose configuration to use environment variables for image versions
- Modified frontend Dockerfile to use configurable image from environment
- Updated environment templates with new variables
- Enhanced install script to handle missing environment variables

### Infrastructure
- Added configurable image versions for all services:
  - WATER_CRAWL_BACKEND_IMAGE
  - WATER_CRAWL_FRONTEND_IMAGE
  - NEGINX_IMAGE
  - MINIO_IMAGE
  - POSTGRES_IMAGE
  - REDIS_IMAGE
  - PLAYWRIGHT_IMAGE
