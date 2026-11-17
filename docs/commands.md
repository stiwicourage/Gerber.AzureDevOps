# Azure DevOps command reference

Requires PowerShell 7.4, Gerber Core 0.2.1-preview02 and approved/enabled
Gerber.AzureDevOps. Namespace identity is `ado`; Core supplies its parent menus.

## Reports

`/ado agents list` lists BUILD and DEPLOY pools/agents, retaining ordering,
versions/status and report formatting. `/ado list team-members` lists the
selected project's teams/members. These are GET/report workflows, not mutations.
Use the shared continue prompt after a report; recoverable failures return to Gerber.
The former `/ado list agents` route is removed without an alias;
`/ado list team-members` is unchanged.

## Agent pool updates

`/ado agents update` requires an interactive terminal. Select one or more
self-hosted BUILD/DEPLOY pools using Space, then Apply. Hosted pools, pools with
unknown hosting metadata, and empty pools are omitted. Nothing is preselected;
an empty selection cannot Apply.

Each pool occupies one checkbox row, with no status/version description beneath it:

```text
[ ] BUILD | EESSIBuild #51 | 11 agent registrations
```

Line breaks in names are flattened for display, and long picker labels are clipped
to the terminal width. Selection still uses the original pool ID. Confirmation
shows the collection and one type/name/ID/registration-count row per pool, with
shared explanations once and the Confirm prompt. It does not list individual
agents or their names, versions, status, enabled/work/pending state or OS.
Use `/ado agents list` separately to inspect those details.
Result receipts use compact formatting; distinct result explanations appear once
below the totals rather than on every pool row.
Per-pool progress appends a short step count without overwriting earlier receipts.
Unusually long names or metadata can still wrap in previews/results so important
identity and diagnostic details are not silently discarded.

Review the collection, pool identities and registration counts in the combined
preview. Confirmation defaults to **Cancel**. The entire pool is affected,
including offline/disabled agents. Unknown enabled/work/pending state is not
proof that an agent is idle or current. ADO chooses the version, which may
cross a major version. Refresh is asynchronous, normally after current jobs;
offline agents and completion times are not guaranteed.

Before sending, Gerber rereads pool eligibility and membership. A changed
snapshot requires another preview and confirmation; an ineligible pool aborts.
This is not an atomic membership lock: the pool API can include registrations
added after the last read.

Gerber sends at most one refresh POST per selected pool, sequentially, without
retries or deployment-group fallback. The collection-scoped messages route uses
the configured pool API base with preview revision 1: for example,
`api-version=7.1-preview.1` or `6.0-preview.1`; an explicitly configured preview
version is preserved. Ordinary inventory GET versions are unchanged.
The request sends literal JSON `null` with JSON Accept/Content-Type headers,
matching the SDK refresh operation rather than an empty form-typed POST.
It sends neither an individual `agentId` query nor a target-version/message object.
`RequestAccepted` means only
HTTP acceptance, not an installed version. Pool-local rejections such as
403/404 allow remaining requests; 401 stops the batch. Timeout, connection
loss and ambiguous responses become `OutcomeUnknown` and stop remaining
requests as `NotAttempted`. Do not blindly retry an unknown outcome.
For rejected requests, an available JSON `message` field is shown after credential
redaction, control/line-separator removal and truncation to 160 characters.
Other response fields, raw bodies and exception details are not displayed.
HTTP 400 remains `RequestFailed`; its reason can distinguish API/version/body
rejection from pool-specific constraints. The server's supported preview version
and actual refresh acceptance still require user-side live verification.
Esc/Cancel before Apply sends nothing. During an applied batch, Ctrl-C or Esc
stops further POSTs after the in-flight request settles or times out. Already
accepted receipts remain visible, and Enter returns to Gerber without terminating
the host. Accepted requests cannot be recalled. Use `/ado agents list` later to
check versions.

The configured PAT and pool role need permission to read and manage the selected
Agent Pools; ask the administrator for least-privilege access, not broader tokens.
Never paste credentials into chat or configuration. BUILD and DEPLOY refresh
acceptance and actual installation still need a separately authorized disposable
pilot; deployment-group IDs are not pool IDs and are never substituted.

Version-policy update/upgrade commands are deliberately unavailable: the public
refresh contract has no documented target-version argument. For illustration,
patch from 4.250.1 would choose 4.250.2 and minor would choose 4.251.0 among stable
candidates 4.250.2, 4.251.0 and 5.0.0. Those are deferred policy rules, **not**
promises about `/ado agents update`. No downloads, host installation, enabled-state
changes, SSH, restarts or pipelines are performed.

`/ado branch find` prompts for a branch path and scans repositories, retaining
per-repository failure reporting and normalized `refs/heads/` handling.

## Repository creation

`/ado repository create` prompts for project, template, new repository name and team.
It previews the provisioning plan before confirmation. Apply creates the repository,
imports the template, handles RAW content and initial commit substitutions,
and configures default/searchable/reviewer/build-validation policies and pipeline
settings through the existing operation chain. Failures remain visible and recoverable.
Cancel performs no provisioning mutation. Esc backs out through template/project selection.

## Branch mutations

`/ado branch set-default` previews aligned, missing and qualifying repositories before
changing default branches. `/ado branch set-searchable` retains Replace/Merge policy
behavior, desired branch scopes, default-branch exclusion and create/update routing.
Apply confirms the displayed plan; Cancel returns to branch input.

## Pipeline tags

`/ado pipelines tags` offers sorted `delete` and `update` actions.
`/ado pipelines tags delete` asks for the current tag, lists matching runs and lets
you select runs before confirmation. `/ado pipelines tags update` also asks for the
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
