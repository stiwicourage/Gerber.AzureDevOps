# Azure DevOps command reference

Requires PowerShell 7.4, Gerber Core 0.2.1-preview02 and approved/enabled
Gerber.AzureDevOps. Namespace identity is `ado`; public paths remain under
the existing generic roots.

## Reports

`/list ado-agents` lists BUILD and DEPLOY pools/agents, retaining ordering,
versions/status and report formatting. `/list ado-team-members` lists the
selected project's teams/members. These are GET/report workflows, not mutations.
Use the shared continue prompt after a report; recoverable failures return to Gerber.

`/branch find` prompts for a branch path and scans repositories, retaining
per-repository failure reporting and normalized `refs/heads/` handling.

## Repository creation

`/repository create` prompts for project, template, new repository name and team.
It previews the provisioning plan before confirmation. Apply creates the repository,
imports the template, handles RAW content and initial commit substitutions,
and configures default/searchable/reviewer/build-validation policies and pipeline
settings through the existing operation chain. Failures remain visible and recoverable.
Cancel performs no provisioning mutation. Esc backs out through template/project selection.

## Branch mutations

`/branch set-default` previews aligned, missing and qualifying repositories before
changing default branches. `/branch set-searchable` retains Replace/Merge policy
behavior, desired branch scopes, default-branch exclusion and create/update routing.
Apply confirms the displayed plan; Cancel returns to branch input.

## Pipeline tags

`/pipelines tags` offers sorted `delete` and `update` actions.
`/pipelines tags delete` asks for the current tag, lists matching runs and lets
you select runs before confirmation. `/pipelines tags update` also asks for the
replacement tag. Confirmation defaults to Cancel. Delete uses DELETE; replacement
retains separate add/remove mutations and existing failure/result reporting.
Esc backs out without applying unconfirmed changes.

## Readiness and isolation

On first relevant use, the plugin reads its bound JSON and resolves the existing
default/explicit profile behavior. An explicit profile never silently falls back.
Missing interactive configuration/PAT uses the normal setup flow. Noninteractive
missing credentials/configuration fail without prompting.

The JSON document retains `{ "ado": ... }` and unknown fields in
`Gerber.AzureDevOps.json`. Core owns its placement and legacy `config.json`
migration, including conflict diagnostics. Do not set a plugin path through
`GERBER_CONFIG_PATH`; that variable selects a Core file.

PATs use `@('ado', profileName, 'pat')` through public Secrets operations and
GUID-owned storage. Old `gerber:ado:*` credentials are never accessed automatically.
Import/registration performs no operation. Dependency import before approval is
not activation, and unknown, declined or disabled plugins expose no product paths.
