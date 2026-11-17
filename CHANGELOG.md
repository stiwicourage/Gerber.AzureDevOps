# Changelog

All notable changes to this project will be documented in this file and **UNRELEASED** changes will be included in the next **stable** release!
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `/ado agents update`: explicit multi-pool selection for self-hosted BUILD/DEPLOY
  pools, combined snapshot preview, Cancel-default confirmation and revalidation.
  Requests are sequential, not retried and report partial/unknown outcomes.
  ADO chooses the version (including possible major changes); acceptance is not installation.
  Ctrl-C during a batch preserves accepted receipts and returns to Gerber, stopping
  further requests after the in-flight request settles or times out.
  The picker shows one row per pool without status/version descriptions.
  Confirmation also shows one identity/count row per pool, never individual agents.
  Receipts are compact; shared explanations are shown once each.
  Refresh uses the preview messages route and explicit JSON `null`/JSON headers.
  HTTP 400 and other rejections include a sanitized, one-line JSON server message
  when available, truncated to 160 characters without exposing raw diagnostics.

### Changed

- **Breaking:** `/ado agents list` replaces `/ado list agents` without an alias.
  `/ado list team-members` and existing agent-report formatting are unchanged.

### Deprecated

### Removed

### Fixed

### Security

## [0.3.0] - 2026-11-11

### Added

- `/ado list agents` now shows the operating system of each agent (`Windows`, `Linux`,
  `macOS`, the raw description when unrecognized, or `unknown`).

### Changed

- **Breaking:** all commands moved under the `/ado` namespace and the old paths no longer work:
  `list ado-agents` -> `ado list agents`, `list ado-team-members` -> `ado list team-members`,
  `repository create` -> `ado repository create`, `branch find|set-searchable|set-default` ->
  `ado branch ...`, `pipelines tags [delete|update]` -> `ado pipelines tags [delete|update]`.

## [0.2.3] - 2026-11-11

### Added

- `/ado list agents` now shows the operating system of each agent (`Windows`, `Linux`,
  `macOS`, the raw description when unrecognized, or `unknown`).

### Changed

- **Breaking:** all commands moved under the `/ado` namespace and the old paths no longer work:
  `list ado-agents` -> `ado list agents`, `list ado-team-members` -> `ado list team-members`,
  `repository create` -> `ado repository create`, `branch find|set-searchable|set-default` ->
  `ado branch ...`, `pipelines tags [delete|update]` -> `ado pipelines tags [delete|update]`.

## [0.2.2] - 2026-11-10

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
