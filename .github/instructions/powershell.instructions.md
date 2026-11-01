---
applyTo: "src/**/*.ps1"
---

# PowerShell plugin source

Follow [AGENTS.md](../../AGENTS.md). Target the declared PowerShell 7.4 minimum.
Keep one exported function per matching file in `src/public/`; put handler
factories and definitions in `src/private/`. Never hand-edit `dist/`.

For registrations, preserve `Get-GerberPlugin`'s manifest-matching GUID and
`ado` namespace identity and the nine existing paths under generic Core roots.
Register leaf paths without a leading slash. Capture the supplied public API and
a plugin-module-bound invocation rather than relying on a bare closure.
Preserve `$false` continue semantics, Escape/back and UI stream/output behavior.
Test the direct leaf and parent menu route; never call private Core functions.

Run `./scripts/Test-PluginBoundary.ps1` before Nova build/tests. Inspect the
current built Core public inventory with `(Test-GerberPluginBoundary -Path .).PublicApi`.
Resolve diagnostics through supported operations or request a new public
capability, never private imports or Core session-state access. Manually review
computed dependencies: the static check is not a PowerShell sandbox.
