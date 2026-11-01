from pathlib import Path
import sys
import unittest
from tempfile import TemporaryDirectory
from types import SimpleNamespace

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import run_terminal_tests  # noqa: F401,E402
from framework.scenario_registry import SCENARIO_REGISTRY  # noqa: E402
from scenarios.core_mission_support import ADO_PAT, PAT_IDENTIFIER  # noqa: E402
from scenarios.repository_create_support import (  # noqa: E402
    CREATED_REPOSITORY_ID, REPOSITORY_NAME, assert_repository_create_failure_requests,
    assert_repository_create_isolation, assert_repository_create_success_requests,
    repository_create_failure_fixture, repository_create_success_fixture,
)


class FakeRepositoryApp:
    def __init__(self, root: Path) -> None:
        self.runtime_paths = type("RuntimePaths", (), {"scenario_root": root})()

    def http_state(self):
        return {"requests": [{"headers": {"Authorization": "<redacted>"}}]}

    def credential_state(self):
        return {
            "credentials": {PAT_IDENTIFIER: ADO_PAT},
            "operations": [{"operation": "Get", "service": "credentials", "account": PAT_IDENTIFIER}] * 6,
            "failures": {},
        }


class ProductScenarioTests(unittest.TestCase):
    def test_native_ctrl_c_paths_are_permanent_product_regressions(self) -> None:
        ids = {item.id for item in SCENARIO_REGISTRY}
        self.assertTrue({"ado-ctrl-c-branch-find", "ado-ctrl-c-pat-setup"}.issubset(ids))

    def test_interrupt_sends_native_ctrl_c_input_without_simulating_an_exception(self) -> None:
        sent = []
        app = run_terminal_tests.AdoTerminalApp(None)
        app._session = SimpleNamespace(send_text=sent.append)
        app.interrupt()
        self.assertEqual(["\x03"], sent)

    def test_cancellation_paths_are_part_of_the_product_suite(self) -> None:
        ids = {item.id for item in SCENARIO_REGISTRY}
        self.assertTrue({
            "ado-cancel-branch-find", "ado-cancel-branch-set-default",
            "ado-cancel-branch-set-searchable", "ado-cancel-pipelines-tags-delete",
            "ado-cancel-pipelines-tags-update", "ado-legacy-pat-untouched",
        }.issubset(ids))

    def test_product_scenarios_moved_with_the_product(self) -> None:
        ids = {item.id for item in SCENARIO_REGISTRY}
        self.assertTrue({
            "core-mission-ado-agents-success", "core-mission-ado-agents-recovery",
            "core-mission-branch-find", "core-mission-branch-set-default", "core-mission-branch-set-searchable",
            "core-mission-repository-create", "core-mission-repository-create-recovery",
            "core-mission-pipeline-tags-delete", "core-mission-pipeline-tags-update",
        }.issubset(ids))
        self.assertNotIn("core-mission-secrets-lifecycle", ids)

    def test_repository_create_success_fixture_covers_complete_provisioning_chain(self) -> None:
        requests = repository_create_success_fixture()["requests"]
        self.assertEqual(requests[3]["response"]["id"], CREATED_REPOSITORY_ID)
        self.assertEqual(requests[5]["rawContent"], "# PackageName\n")
        self.assertEqual(requests[7]["expectedBody"]["commits"][0]["changes"][0]["newContent"]["content"], f"# {REPOSITORY_NAME}\n")
        self.assertEqual(requests[-3]["expectedBody"]["settings"]["requiredReviewerIds"], ["team-core"])
        assert_repository_create_success_requests(request_log(requests))

    def test_repository_create_failure_fixture_preserves_controlled_recovery_path(self) -> None:
        requests = repository_create_failure_fixture()["requests"]
        self.assertEqual(requests[3]["error"]["message"], "Synthetic repository creation failure.")
        assert_repository_create_failure_requests(request_log(requests))

    def test_repository_create_request_assertions_reject_incomplete_chain(self) -> None:
        with self.assertRaises(AssertionError):
            assert_repository_create_success_requests(request_log(repository_create_success_fixture()["requests"])[:-1])

    def test_repository_create_isolation_accepts_only_sanitized_owned_credentials(self) -> None:
        with TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("home", "temp", "xdg-config"):
                (root / name).mkdir()
            (root / "Gerber.AzureDevOps.json").write_text(
                '{"ado":{"profiles":{"terminal":{"projectUrl":"https://dev.azure.com/terminal/TerminalProject"}}}}',
                encoding="utf-8",
            )
            assert_repository_create_isolation(FakeRepositoryApp(root))


def request_log(requests):
    return [{
        "method": item["method"], "uri": item["uri"], "body": item.get("expectedBody", {}),
        "transport": "Invoke-WebRequest" if "rawContent" in item else "Invoke-RestMethod",
    } for item in requests]
