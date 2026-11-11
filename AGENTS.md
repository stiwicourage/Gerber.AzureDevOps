# Gerber.AzureDevOps development guide

## Product and ownership

This is an independently built PowerShell 7.4 product plugin for Gerber Core
0.2.1-preview02 or later. Integrate only through Plugin API v1 supplied to
`Get-GerberPlugin -Gerber $Gerber`. Native Azure DevOps logic belongs here.
Do not call private Core commands, dot-source Core source, access Core module
scope/script variables, or depend on another product plugin in production.
Test-owned built-module probes are integration evidence, not a production adapter.

This guide is canonical. `CLAUDE.md` and `.github/copilot-instructions.md` are
bridges; scoped instructions, agents and skills must stay consistent with it.
`project.json`, `src/public`, `src/private`, resources, tests and docs are authored.
Nova generates `dist/`; do not hand-edit generated modules or manifests.
`docs/schema` is schema tooling, not generated command help.

Keep `Manifest.GUID` `a468dee5-c7a0-43e4-ae88-bb19158fe679`, version `0.1.0`,
`PrivateData.Gerber.ApiVersion` `1`, namespace identity `ado`, and the canonical
PSGallery repository declaration stable unless separately authorized.
The descriptor `Namespace` and manifest `PrivateData.Gerber.Namespace` both
declare `ado`; the registered command paths live under that `ado` namespace.

## Command registration and module binding

`Get-PluginCommandDefinitionList` owns these exact paths without leading slashes:
`ado list agents`, `ado list team-members`, `ado repository create`, `ado branch find`,
`ado branch set-searchable`, `ado branch set-default`, `ado pipelines tags`,
`ado pipelines tags delete`, `ado pipelines tags update`.
All paths sit under the `ado` namespace. Core creates the missing `ado`,
`ado list`, `ado branch`, `ado repository` and `ado pipelines` containers; this
plugin owns the product leaves. Do not restore hello scaffolding or the former
top-level paths (`list ado-agents`, `list ado-team-members`, `repository create`,
`branch ...`, `pipelines tags ...`).

Definitions contain `Name`, `Description`, `Handler` and `Subcommands`.
`New-AdoModuleHandler` captures the supplied API and a plugin-module-bound
invocation. A bare `.GetNewClosure()` can lose private function lookup;
preserve the bound invocation and test execution across the built-module boundary.
Return `$false` to continue Gerber; `$true` requests exit. Preserve arguments,
sorting, defaults, Esc/Ctrl-C/pipeline-stop recovery and continue behavior.
Import and registration must not read config, credentials or ADO.

## Public Plugin API v1

Operations are scriptblocks invoked with `&`, not object methods or cmdlets.
The context exposes `UI`, `Configuration`, `Secrets`, `Http` and `Clipboard`;
there is **no Core Ado capability**.

| Capability | Contract used by this plugin |
| --- | --- |
| Configuration | `Read()` returns JSON data or null when absent; `Save(value)` atomically stores valid JSON. Core binds the registered module name and destination. |
| Secrets | `Test(path)`, `GetText(path)`, `Set(path, value)`, `Remove(path)` use one logical string-array argument. |
| Http | `GetConfiguration()` supplies connection/operation timeout seconds; `GetTransportFailureHint(exception)` and `IsTimeoutFailure(exception)` provide generic diagnostics, not ADO transport/authentication. |
| Clipboard | `CopyText(value)` copies through the host boundary. |
| UI navigation | `ReadSubcommand(name, command, table, autoSelectFirstSuggestionOnSubmit=false)`, `WaitForContinue()`, `ShowTextBlock(title, text)`, `ShowMenuError(message)`. |
| UI input | `ReadCommand(prompt, suggestionMode, inputMode, promptContext, trimResult)`, `ReadSecretText(prompt)`, `ReadSecureValue(prompt)`, numbered/checkbox/confirmation prompt operations. Verify their request shapes before changing adapters. |
| UI feedback | `StartScreen(name)`, `WriteScreenLine(text)`, `WritePromptTrace(eventName, data)`, `WriteProgressBar(current, total, prefix, overwritePreviousRender)`, `WriteStyledPromptText(text, style)`, `GetPromptColorPair()`. |
| UI state | `IsInteractive()`, `IsEscapeException(exception)`, `GetEscapeException()`. |

Use existing plugin-local adapters to translate former names into these public
operations. Prompt contexts and confirmation options are plain plugin-owned data.
Styling forwards a Style object, not a guessed role string. If another capability
is needed, request an explicit signature rather than reaching into Core.

Plugin configuration is `Gerber.AzureDevOps.json`, retaining `{ ado: ... }`.
Core selects/binds the path and owns legacy file migration. Preserve unknown
fields, profile casing and default selection. Never save PATs in configuration.
Invoke secrets with a logical path:

```powershell
$path = @('ado', $profileName, 'pat')
$pat = & $Gerber.Secrets.GetText $path
```

Storage is GUID-owned. Do not read, migrate or delete old `gerber:ado:*`
credentials automatically. Native REST belongs here and obtains credentials
lazily through Secrets. Missing PATs fail without prompts in noninteractive use.
This in-process API is not a sandbox; never log secrets.

## Tests and quality

Follow source-mirrored Pester conventions. Establish intended red tests for
behavior changes, or green characterization before refactoring. Preserve original
error, stream, mutation and output assertions when parameterizing duplicated tests.
Mock external systems and destructive operations; never use live ADO/real credentials.

Use `Invoke-NovaTest` and `Test-NovaBuild`, not direct Pester. Built integration
must prove callback binding, normal discovery and import-versus-activation lifecycle.
Dependency import is not Loaded/Active registration; unknown/declined/disabled
cases must expose no product leaves. PTY product scenarios live in this plugin.
Only general test-owned Core runner/framework/fakes may be reused, never private
Core production source or another product's fixtures.

Run the approved loop against current local Core artifacts:

```powershell
./run.ps1 -CoreArtifactRoot ../GerberCore/dist -SuiteTimeoutSeconds 1800
```

The analyzer runs first and treats every finding as failure. Keep 90% unit
coverage and target CodeScene **10.0 for every touched supported code/test/helper**.
Review new code around SIG maintainability; refactor in small measured steps.
Report unsupported formats or unavailable repository-level measurement honestly.
Git writes are not authorized for this extraction. Git metadata may already exist;
do not create, remove or modify it as part of implementation or qualification.

Update README, command reference, public comment-based help and changelog with
behavior changes. Normalize authored changed text to one trailing newline.
Record exact commands, before/after results and residual gates. Do not claim ready
with unresolved failures, missing evidence or unmet health targets. Git writes,
installation, publication and release operations require explicit authorization.
