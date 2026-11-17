from __future__ import annotations

import json
from itertools import permutations

from framework.scenario_registry import ScenarioMetadata, scenario
from .ado_mission import COLLECTION_URI, _start_ado_scenario
from .core_mission_support import ADO_PAT, assert_no_secret_leak, strict_http_fixture


def _read_entries(path, query, value):
    return [
        {"method": "Get", "uri": f"{COLLECTION_URI}_apis/distributedtask/{path}?{'&'.join(parts)}",
         "response": {"value": value}}
        for parts in permutations(query)
    ]


def agent_update_fixture(*, empty=False, status=202, timeout=False):
    entries = []
    for kind, pool_id in (("automation", 11), ("deployment", 22)):
        pools = [] if empty else [{"id": pool_id, "name": f"{kind} pool", "isHosted": False}]
        pools += [{"id": 33, "name": "Hosted excluded", "isHosted": True},
                  {"id": 44, "name": "Empty excluded", "isHosted": False},
                  {"id": 55, "name": "Unknown excluded"}]
        entries += _read_entries("pools", ("api-version=7.1", f"poolType={kind}"), pools)
        agents = [{"id": 7, "name": f"agent-{pool_id}", "version": "4.250.1", "status": "offline",
                   "enabled": False, "assignedRequest": {"requestId": 2}, "pendingUpdate": {"currentState": "queued"}}]
        query = ("api-version=7.1", "includeCapabilities=false", "includeAssignedRequest=true")
        entries += _read_entries(f"pools/{pool_id}/agents", query, agents)
        entries.append(_refresh_entry(pool_id, status if pool_id == 11 else 202, timeout and pool_id == 11))
    entries += _read_entries("pools/44/agents", query, [])
    return strict_http_fixture(entries)


def _refresh_entry(pool_id, status, timeout):
    entry = {"method": "Post", "uri": f"{COLLECTION_URI}_apis/distributedtask/pools/{pool_id}/messages?api-version=7.1-preview.1",
             "statusCode": status, "response": {}}
    if timeout:
        entry["error"] = {"type": "timeout", "message": "Synthetic uncertain refresh."}
    return entry


def _open_update(context, fixture=None, expected_count=2):
    _start_ado_scenario(context, fixture or agent_update_fixture())
    context.app.type("/ado agents update")
    context.app.press("ENTER")
    context.app.wait_for_text("Agent pools")
    events = [json.loads(line) for line in context.app.prompt_trace_text().splitlines() if line.strip()]
    opened = next(item["Data"] for item in events if item["Event"] == "checkbox-open")
    assert opened["SelectedCount"] == 0 and opened["ItemCount"] == expected_count, opened


def _select_pools(context, count=2):
    for index in range(count):
        if index:
            context.app.press("DOWN")
        context.app.press("SPACE")
    context.app.press("ENTER")
    context.app.wait_for_text("Confirm")
    context.app.wait_for_text("major")


def _apply(context):
    context.app.press("UP")
    context.app.press("ENTER")


def _assert_posts(context, expected):
    requests = context.app.http_state()["requests"]
    posts = [item for item in requests if item["method"].lower() == "post"]
    assert [item["uri"].split("/pools/")[1].split("/")[0] for item in posts] == expected, requests
    assert all(not item["body"] for item in posts), posts
    assert_no_secret_leak(context.app, ADO_PAT)


UPDATE_METADATA = ScenarioMetadata(
    commands=("ado agents update",), workflows=("agents:refresh",),
    coverage=("dispatch", "navigation", "rendering"),
)


@scenario("ado-agents-update-success", title="Explicit BUILD and DEPLOY refresh", categories=("ado",),
          metadata=UPDATE_METADATA)
def agent_update_success(context):
    _open_update(context)
    _select_pools(context)
    _apply(context)
    context.app.wait_for_text("RequestAccepted: 2")
    _assert_posts(context, ["11", "22"])


@scenario("ado-agents-update-default-cancel", title="Agent refresh defaults to Cancel", categories=("ado",),
          metadata=UPDATE_METADATA)
def agent_update_default_cancel(context):
    _open_update(context)
    _select_pools(context)
    context.app.press("ENTER")
    context.app.wait_for_prompt()
    _assert_posts(context, [])


@scenario("ado-agents-update-empty-selection", title="No agent pool is preselected", categories=("ado",),
          metadata=UPDATE_METADATA)
def agent_update_empty_selection(context):
    _open_update(context)
    context.app.press("ENTER")
    context.app.wait_for_text("Select at least one pool")
    _assert_posts(context, [])
    context.app.press("ESCAPE")
    context.app.wait_for_prompt()


@scenario("ado-agents-update-empty", title="Hosted and empty pools are omitted", categories=("ado",),
          metadata=UPDATE_METADATA)
def agent_update_empty(context):
    _start_ado_scenario(context, agent_update_fixture(empty=True))
    context.app.type("/ado agents update")
    context.app.press("ENTER")
    context.app.wait_for_text("No eligible self-hosted")
    _assert_posts(context, [])


@scenario("ado-agents-update-partial", title="Pool-local 403 allows other confirmed pools", categories=("ado",),
          metadata=UPDATE_METADATA)
def agent_update_partial(context):
    _open_update(context, agent_update_fixture(status=403))
    _select_pools(context)
    _apply(context)
    context.app.wait_for_text("RequestFailed: 1")
    context.app.wait_for_text("RequestAccepted: 1")
    _assert_posts(context, ["11", "22"])


def _bad_request_deploy_fixture():
    entries = _read_entries("pools", ("api-version=7.1", "poolType=automation"), [])
    pools = [{"id": 38, "name": "eessi-autotest", "isHosted": False},
             {"id": 44, "name": "eessi-other", "isHosted": False}]
    entries += _read_entries("pools", ("api-version=7.1", "poolType=deployment"), pools)
    for pool in pools:
        query = ("api-version=7.1", "includeCapabilities=false", "includeAssignedRequest=true")
        entries += _read_entries(f"pools/{pool['id']}/agents", query, [{"id": 7, "name": "hidden-agent"}])
        post = _refresh_entry(pool["id"], 400, False)
        post["response"] = {"message": f"Preview API required.\r\npat={ADO_PAT}", "stackTrace": "private server stack"}
        entries.append(post)
    return strict_http_fixture(entries)


@scenario("ado-agents-update-bad-request", title="DEPLOY HTTP 400 exposes sanitized server guidance",
          categories=("ado", "recovery"), metadata=UPDATE_METADATA)
def agent_update_bad_request(context):
    _open_update(context, _bad_request_deploy_fixture())
    _select_pools(context)
    _apply(context)
    context.app.wait_for_text("RequestFailed: 2")
    snapshot = context.app.wait_for_text("Preview API required.")
    assert "private server stack" not in snapshot.text and ADO_PAT not in snapshot.text, snapshot.text
    _assert_posts(context, ["38", "44"])
    context.app.press("ENTER")
    context.app.wait_for_prompt()


@scenario("ado-agents-update-timeout", title="Unknown refresh stops without retries", categories=("ado",),
          metadata=UPDATE_METADATA)
def agent_update_timeout(context):
    _open_update(context, agent_update_fixture(timeout=True))
    _select_pools(context)
    _apply(context)
    context.app.wait_for_text("OutcomeUnknown: 1")
    context.app.wait_for_text("NotAttempted: 1")
    _assert_posts(context, ["11"])


@scenario("ado-agents-update-escape", title="Esc from pool selection sends nothing", categories=("ado",),
          metadata=UPDATE_METADATA)
def agent_update_escape(context):
    _open_update(context)
    context.app.press("ESCAPE")
    context.app.wait_for_prompt()
    _assert_posts(context, [])


@scenario("ado-agents-update-menu", title="Core provides agents parent navigation", categories=("ado",),
          metadata=UPDATE_METADATA)
def agent_update_menu(context):
    _start_ado_scenario(context, agent_update_fixture())
    context.app.type("/ado agents")
    context.app.press("ENTER")
    context.app.wait_for_text("update")
    context.app.type("update")
    context.app.press("ENTER")
    context.app.wait_for_text("Agent pools")
    _assert_posts(context, [])


@scenario("ado-agents-update-read-recovery", title="Agent inventory failure returns safely", categories=("ado",),
          metadata=UPDATE_METADATA)
def agent_update_read_recovery(context):
    _start_ado_scenario(context, strict_http_fixture([]))
    context.app.type("/ado agents update")
    context.app.press("ENTER")
    context.app.wait_for_text("Could not prepare agent refresh")
    context.app.press("ENTER")
    context.app.wait_for_prompt()
    _assert_posts(context, [])


@scenario("ado-agents-update-interrupt", title="Native cancellation never submits an unconfirmed refresh",
          categories=("ado", "cancellation"), metadata=UPDATE_METADATA)
def agent_update_interrupt(context):
    _open_update(context)
    _select_pools(context)
    path = context.app.runtime_paths.scenario_root / "Gerber.AzureDevOps.json"
    configuration = path.read_text(encoding="utf-8")
    context.app.interrupt()
    context.app.press("ENTER")
    context.app.wait_for_exit()
    assert path.read_text(encoding="utf-8") == configuration
    _assert_posts(context, [])


@scenario("ado-agents-update-batch-interrupt", title="Native Ctrl-C stops the batch and returns to Gerber",
          categories=("ado", "cancellation"), metadata=UPDATE_METADATA)
def agent_update_batch_interrupt(context):
    fixture = agent_update_fixture()
    next(item for item in fixture["requests"] if item["method"] == "Post")["holdForInterrupt"] = True
    _open_update(context, fixture)
    _select_pools(context)
    _apply(context)
    context.app.wait_for_text("Synthetic refresh in progress")
    context.app.interrupt()
    _assert_batch_recovered(context, ["11"])


def _assert_batch_recovered(context, expected_posts):
    context.app.wait_for_text(f"RequestAccepted: {len(expected_posts)}")
    context.app.wait_for_text("CancelledBeforeSend: 1")
    context.app.press("ENTER")
    context.app.wait_for_prompt()
    assert context.app.process_status()["isAlive"]
    _assert_posts(context, expected_posts)


def _accepted_then_interrupt_fixture():
    fixture = agent_update_fixture()
    for item in fixture["requests"]:
        if item["method"] == "Get" and "poolType=automation" in item["uri"]:
            item["response"]["value"] = item["response"]["value"] + [{"id": 66, "name": "Third pool", "isHosted": False}]
    query = ("api-version=7.1", "includeCapabilities=false", "includeAssignedRequest=true")
    fixture["requests"] += _read_entries("pools/66/agents", query, [{"id": 7, "name": "agent-66"}])
    fixture["requests"].append(_refresh_entry(66, 202, False))
    next(item for item in fixture["requests"] if "/pools/22/messages?" in item["uri"])["holdForInterrupt"] = True
    return fixture


@scenario("ado-agents-update-accepted-then-interrupt", title="Ctrl-C retains earlier accepted receipts",
          categories=("ado", "cancellation"), metadata=UPDATE_METADATA)
def agent_update_accepted_then_interrupt(context):
    _open_update(context, _accepted_then_interrupt_fixture(), expected_count=3)
    _select_pools(context, count=3)
    _apply(context)
    context.app.wait_for_text("Pool #11 automation pool: RequestAccepted")
    context.app.wait_for_text("Synthetic refresh in progress")
    context.app.interrupt()
    _assert_batch_recovered(context, ["11", "22"])


def compact_agent_update_fixture():
    entries = []
    query = ("api-version=7.1", "includeCapabilities=false", "includeAssignedRequest=true")
    for kind, pool_id, name, count in (("automation", 51, "EESSIBuild", 11), ("deployment", 52, "EESSIDeploy", 1)):
        pools = [{"id": pool_id, "name": name, "isHosted": False}]
        entries += _read_entries("pools", ("api-version=7.1", f"poolType={kind}"), pools)
        agents = [{"id": index + 1, "name": f"agent-{index + 1:02}", "version": "5.281.1",
                   "status": "online" if index % 2 else "offline", "enabled": False, "assignedRequest": None,
                   "pendingUpdate": {"currentState": "queued"}, "osDescription": "Linux"} for index in range(count)]
        entries += _read_entries(f"pools/{pool_id}/agents", query, agents)
        entries.append(_refresh_entry(pool_id, 202, False))
    return strict_http_fixture(entries)


def _assert_single_line_picker(context):
    snapshot = context.app.snapshot()
    rows = [index for index, line in enumerate(snapshot.lines) if "[ ]" in line]
    assert len(rows) == 2 and rows[1] == rows[0] + 1, snapshot.text
    assert "offline /" not in snapshot.text and "online /" not in snapshot.text, snapshot.text
    events = [json.loads(line) for line in context.app.prompt_trace_text().splitlines() if line.strip()]
    rendered = [item["Data"] for item in events if item["Event"] == "checkbox-render"][-1]
    assert rendered["NewRenderedLines"] == rendered["ItemCount"] + 2, rendered


def _assert_compact_result_rows(context):
    snapshot = context.app.wait_for_text("RequestAccepted: 2")
    rows = [index for index, line in enumerate(snapshot.lines) if line.startswith("Pool #")]
    assert len(rows) == 2 and rows[1] == rows[0] + 1, snapshot.text
    assert all("RequestAccepted (HTTP 202)." in snapshot.lines[index] for index in rows), snapshot.text
    assert snapshot.text.count("Request accepted; installation is asynchronous and is not verified.") == 1, snapshot.text


@scenario("ado-agents-update-compact", title="Single-line pool picker and compact preview/results at 80 columns",
          categories=("ado", "rendering"), metadata=ScenarioMetadata(
              commands=("ado agents update",), workflows=("agents:refresh",), coverage=("rendering",), viewport=(80, 40)))
def agent_update_compact(context):
    _open_update(context, compact_agent_update_fixture())
    context.app.wait_for_text("[ ] BUILD | EESSIBuild #51 | 11 agent registrations")
    _assert_single_line_picker(context)
    _select_pools(context)
    snapshot = context.app.snapshot()
    rows = [line for line in snapshot.lines if "agent registrations" in line]
    assert rows == ["BUILD | EESSIBuild #51 | 11 agent registrations",
                    "DEPLOY | EESSIDeploy #52 | 1 agent registrations"], snapshot.text
    assert not any(token in snapshot.text for token in ("agent-01", "5.281.1", "enabled=", "pending=", "Linux")), snapshot.text
    _apply(context)
    _assert_compact_result_rows(context)
    _assert_posts(context, ["51", "52"])


@scenario("ado-agents-update-long-label", title="Long and multiline pool names cannot add picker rows",
          categories=("ado", "rendering"), metadata=ScenarioMetadata(
              commands=("ado agents update",), workflows=("agents:refresh",), coverage=("rendering",), viewport=(80, 40)))
def agent_update_long_label(context):
    fixture = compact_agent_update_fixture()
    for item in fixture["requests"]:
        if item["method"] == "Get" and "poolType=automation" in item["uri"]:
            item["response"]["value"][0]["name"] = "Build\r\nPool\t" + "long-name-" * 20
    _open_update(context, fixture)
    _assert_single_line_picker(context)
    context.app.press("ESCAPE")
    context.app.wait_for_prompt()
    _assert_posts(context, [])
