---
name: gerber-plugin-api
description: Safely exercise Gerber public UI, JSON configuration, secrets, HTTP diagnostics and clipboard boundaries
---

# Use the public Gerber API

Read [AGENTS.md](../../../AGENTS.md) before host integration.

1. Run `./scripts/Test-PluginBoundary.ps1` against the current local built Core.
   Inspect its public API inventory; do not rely on an installed stale Core.
2. Invoke supplied `UI`, `Configuration`, `Secrets`, `Http` and `Clipboard`
   scriptblocks with `&`. There is no Core `Ado` capability.
3. Keep native ADO REST and domain validation in this plugin. JSON Read/Save is
   module-bound by Core; use GUID-owned secret logical paths and preserve lazy
   readiness, profile selection, cancellation and noninteractive errors.
4. Use `New-AdoModuleHandler` to capture the API and a module-bound invocation.
   Bare closures may lose plugin-private function lookup. Do not access Core
   module scope, source or script variables in production.
5. Stub operations in units and verify normal discovery, callback execution and
   import-versus-activation using the actual built Core/plugin boundary.
6. Run the complete approved `./run.ps1` loop. Preserve GET/mutation distinction,
   retry/RAW handling and no-secret-output assertions. Request explicit missing
   capability signatures rather than inventing APIs or private-import workarounds.

The static boundary is not a sandbox; manually review computed command targets.
