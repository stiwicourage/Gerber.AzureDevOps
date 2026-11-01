from __future__ import annotations

import json
from core_test_support import (
    assert_http_request, assert_no_secret_leak, seed_credential_state, strict_http_fixture,
)

ADO_PAT = "terminal-ado-pat"
PAT_IDENTIFIER = "gerber:plugin:a468dee5-c7a0-43e4-ae88-bb19158fe679:ado:terminal:pat"


def seed_ado_state(context) -> None:
    root = context.app.runtime_paths.scenario_root
    (root / "GerberCore.json").write_text(json.dumps({
        "schemaVersion": 1,
        "plugins": {"approved": ["a468dee5-c7a0-43e4-ae88-bb19158fe679"]},
    }), encoding="utf-8")
    (root / "Gerber.AzureDevOps.json").write_text(json.dumps({
        "ado": {"defaultProfile": "terminal", "profiles": {
            "terminal": {"projectUrl": "https://dev.azure.com/terminal/TerminalProject"},
        }},
    }), encoding="utf-8")
    seed_credential_state(context.app.runtime_paths.credential_state_path, {PAT_IDENTIFIER: ADO_PAT})
    context.app.register_sensitive_value(ADO_PAT)
