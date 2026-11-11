# Gerber.AzureDevOps

Azure DevOps product commands for Gerber Core, targeting **PowerShell 7.4** and
**Gerber Core 0.2.1-preview02 or later**, through Plugin API v1.

## Commands

The extraction retains the existing paths; commands are not grouped under `/ado`.
Both the returned plugin descriptor's `Namespace` and built manifest's
`PrivateData.Gerber.Namespace` explicitly remain `ado`. This is identity metadata,
not an added `/ado` command or a restored hello route.

| Path | Purpose |
| --- | --- |
| `/ado list agents` | List BUILD and DEPLOY agents. |
| `/ado list team-members` | List teams and their members. |
| `/ado repository create` | Create and configure a repository from a template. |
| `/ado branch find` | Search repositories for a branch. |
| `/ado branch set-searchable` | Standardize searchable-branch policies. |
| `/ado branch set-default` | Standardize default branches. |
| `/ado pipelines tags` | Open the tag submenu. |
| `/ado pipelines tags delete` | Delete a tag from selected tagged runs. |
| `/ado pipelines tags update` | Replace a tag on selected tagged runs. |

See [command reference](docs/commands.md) for prompts, previews and cancellation.
Native REST, reports, repository provisioning, policies, work items,
retry/pagination and RAW-file handling belong to this module, not Core.

## Configuration and credentials

Core binds `Configuration.Read/Save` to `Gerber.AzureDevOps.json`, alongside its
selected `GerberCore.json`. The plugin cannot supply another module name or path.
`GERBER_CONFIG_PATH` selects an explicit absolute **Core file**, not a plugin file.
Core owns legacy `config.json` migration and rejects destination conflicts rather
than silently overwriting them. Plugin JSON retains `{ "ado": ... }`, profile
field casing, default selection and unknown fields.

Credentials use the plugin GUID-owned namespace:
`gerber:plugin:a468dee5-c7a0-43e4-ae88-bb19158fe679:ado:<profile>:pat`.
Old `gerber:ado:*` credentials are not read, migrated or deleted automatically.
Re-enter the PAT through normal interactive readiness setup when requested.
Noninteractive missing-PAT use fails without prompting. Never put PATs in JSON.

Core's required dependency may import this module before approval. Import is
not approval or activation: unknown, declined and disabled plugins expose no
product leaves. Import and registration perform no product operations.

## Develop and validate

Read [AGENTS.md](AGENTS.md). Use local built artifacts, not an installed stale Core:

```powershell
./run.ps1 -CoreArtifactRoot ../GerberCore/dist -SuiteTimeoutSeconds 1800
```

The wrapper runs analyzer, Nova build, units, built integration, Core's public
boundary validator and the complete isolated product PTY suite. Coordinate Core
artifact rebuilds because Core now declares this plugin as a dependency.
No global installation or local publication is required.

PTY fixtures use test-owned homes/configuration, fake GUID credentials and
strict REST mocks; never point them at live ADO or customer resources.
Failures and retained success traces are under `artifacts/terminal/runs/`.
Coverage is written to `artifacts/coverage.xml`; the unchanged unit threshold is 90%.

Permanent native Ctrl-C scenarios cover an unfinished branch action and a secure
PAT prompt. On the validated PowerShell 7.6.9 host, synchronous console readers
remain blocked after SIGINT until another key releases them. The scenarios submit
that unfinished input and require termination before REST, credential mutation or
configuration changes. They prove pending native cancellation, not immediate
Ctrl-C responsiveness; improving the generic host reader belongs to Core.

Nova owns generated `dist/Gerber.AzureDevOps` artifacts. The source identity stays
version `0.1.0`, GUID `a468dee5-c7a0-43e4-ae88-bb19158fe679`, API `1`,
and canonical PSGallery URI `https://www.powershellgallery.com/api/v2`.
Publishing, installation, versioning and Git mutations require separate authorization.
