# Changelog

All notable changes to this project will be documented in this file and **UNRELEASED** changes will be included in the next **stable** release!
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [0.2.1] - 2026-11-10

## [0.2.0] - 2026-11-10

### Added

- Extracted Azure DevOps reports, repository provisioning, branch policies, pipelines,
  work-item helpers and native REST retry/pagination/RAW handling.
- Nine registered product paths retain their original Core root names.
- Local built-boundary, dependency lifecycle and isolated product PTY validation.

### Changed

- Product state uses plugin-bound `Gerber.AzureDevOps.json`, retaining legacy ADO
  profile shape and unknown fields; Core owns file migration.
- PAT access uses GUID-owned logical Secrets paths; no automatic legacy credential access.
- Minimum Gerber Core version is `0.2.1-preview02`; plugin version and GUID are unchanged.

### Removed

- Hello scaffolding and dependency on the removed Core Ado API.

