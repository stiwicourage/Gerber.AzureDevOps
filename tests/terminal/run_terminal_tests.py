from __future__ import annotations

import argparse
import importlib.util
from pathlib import Path
import sys
import time

PLUGIN_ROOT = Path(__file__).resolve().parents[2]
CORE_ROOT = PLUGIN_ROOT.parent / "GerberCore"
CORE_TERMINAL = CORE_ROOT / "tests/terminal"
sys.path.insert(0, str(CORE_TERMINAL))
support_spec = importlib.util.spec_from_file_location(
    "core_test_support", CORE_TERMINAL / "scenarios/core_mission_support.py",
)
support = importlib.util.module_from_spec(support_spec)
sys.modules["core_test_support"] = support
support_spec.loader.exec_module(support)
sys.path.insert(0, str(Path(__file__).resolve().parent))

# Load the general test runner, not its scenario package or product code.
runner_spec = importlib.util.spec_from_file_location("core_terminal_runner", CORE_TERMINAL / "run_terminal_tests.py")
runner = importlib.util.module_from_spec(runner_spec)
sys.modules[runner_spec.name] = runner
runner_spec.loader.exec_module(runner)

from framework.gerber_app import GerberTerminalApp  # noqa: E402
from framework.scenario_registry import SCENARIO_REGISTRY  # noqa: E402


class AdoTerminalApp(GerberTerminalApp):
    def interrupt(self) -> None:
        # Send the terminal's Ctrl-C byte; do not inject a PowerShell exception.
        self._require_session().send_text("\x03")

    def _build_harness_arguments(self, *, enable_synthetic_plugin: bool) -> list[str]:
        arguments = super()._build_harness_arguments(enable_synthetic_plugin=False)
        index = arguments.index("-File") + 1
        arguments[index] = str(PLUGIN_ROOT / "tests/terminal/fixtures/TestHarness.ps1")
        return arguments + ["-PluginRoot", str(PLUGIN_ROOT)]

    def _build_module_path(self, *, enable_synthetic_plugin: bool) -> str:
        import os
        return os.pathsep.join((str(PLUGIN_ROOT / "dist"), super()._build_module_path(enable_synthetic_plugin=False)))


def parse_options():
    parser = argparse.ArgumentParser()
    parser.add_argument("--core-artifact-root", default=str(CORE_ROOT / "dist"))
    parser.add_argument("--suite-timeout-seconds", type=int, default=1800)
    parser.add_argument("--scenario-id")
    options = parser.parse_args()
    if Path(options.core_artifact_root).resolve() != CORE_ROOT / "dist":
        parser.error("The reused test boundary requires the current Core checkout dist artifact.")
    return parser, options


def select_scenarios(parser, options):
    selected = [item for item in SCENARIO_REGISTRY if options.scenario_id is None or item.id == options.scenario_id]
    if not selected:
        parser.error("No product scenarios matched.")
    return selected


def assert_product_coverage(selected):
    covered = {command for item in selected for command in item.commands}
    required = {
        "list ado-agents", "list ado-team-members", "repository create", "branch find",
        "branch set-searchable", "branch set-default", "pipelines tags delete", "pipelines tags update",
    }
    if not required.issubset(covered):
        raise AssertionError(f"Uncovered product paths: {sorted(required - covered)}")


def main() -> int:
    parser, options = parse_options()
    args = argparse.Namespace(
        gerber_root=str(CORE_ROOT), artifact_root=str(PLUGIN_ROOT / "artifacts/terminal"),
        category=None, scenario_id=options.scenario_id, keep_success_artifacts=True,
        suite_timeout_seconds=options.suite_timeout_seconds,
    )
    runner.GerberTerminalApp = AdoTerminalApp
    context = runner.create_runner_context(args)
    selected = select_scenarios(parser, options)
    results = runner.run_scenario_list(context, selected)
    for result in results:
        print(f"[{result.status}] {result.id}: {result.failure or ''}")
    if options.scenario_id is None:
        assert_product_coverage(selected)
    print(f"Product PTY: {sum(item.status == 'passed' for item in results)}/{len(results)} scenarios; artifacts: {context.run_root}")
    return 0 if all(item.status == "passed" for item in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
