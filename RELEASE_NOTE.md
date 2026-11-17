# Release notes

## [Unreleased]

### Added

- `/ado agents update` selects multiple self-hosted BUILD/DEPLOY pools for
  pool-wide refresh. Review the combined preview; confirmation defaults to Cancel.
  ADO chooses the version, possibly changing major; requests run asynchronously.
  Receipts do not prove installation. Hosted and empty pools are omitted.
  Ctrl-C during a batch preserves accepted receipts and returns to Gerber after
  the in-flight request settles or times out, without sending further requests.
  Pool selection is one checkbox row per pool, without status/version sublines;
  confirmation lists only pool identities/counts and shared warnings, not agents.
  Refresh follows the preview messages/JSON `null` request contract. HTTP 400 and
  other rejections show the sanitized JSON server reason when available, limited
  to 160 characters; raw response diagnostics and credentials are not displayed.

### Changed

- **Breaking:** use `/ado agents list` instead of `/ado list agents`; no alias is
  retained. `/ado list team-members` is unchanged.

### Deprecated

### Removed

### Fixed

### Security

## [0.3.0] - 2026-11-11

## [0.2.3] - 2026-11-11

### Added

- Agent list shows the operating system of each agent.

### Changed

- **Breaking:** commands moved under `/ado`. Migration:

| Old | New |
| --- | --- |
| `/list ado-agents` | `/ado list agents` |
| `/list ado-team-members` | `/ado list team-members` |
| `/repository create` | `/ado repository create` |
| `/branch find`, `set-searchable`, `set-default` | `/ado branch find`, `set-searchable`, `set-default` |
| `/pipelines tags`, `delete`, `update` | `/ado pipelines tags`, `delete`, `update` |

## [0.2.2] - 2026-11-10

## [0.2.1] - 2026-11-10

## [0.2.0] - 2026-11-10

### Added

- Initial release of the Azure DevOps plugin for Gerber. See `CHANGELOG.md` for details.
