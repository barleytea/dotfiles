#!/usr/bin/env python3

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "tests" / "fixtures"
WRAPPER = ROOT / "aws-readonly.sh"
PROFILE_MAP_HELPER = ROOT / "profile_map.py"
RESPONSE_FILTER = ROOT / "response_filter.py"
GUARD = ROOT / "guard.py"
FAKE_AWS = ROOT / "tests" / "fake-bin" / "aws"
MERGE_HOOKS = ROOT.parent / "codex" / "merge-hooks.sh"
MERGE_CLAUDE_SETTINGS = ROOT.parent / "claude" / "config" / "merge-settings.sh"
CODEX_RULES = ROOT.parent / "codex" / "rules" / "aws-readonly.rules"
CLAUDE_SETTINGS = ROOT.parent / "claude" / "config" / "settings.json"
DEFAULT_PROFILE_MAP = {
    "version": 1,
    "profiles": {
        "team-dev-readonly": {
            "environment": "dev",
            "account_id": "123456789012",
            "role_name": "ReadOnlyRole",
        }
    },
}
VALID_PROFILE = "team-dev-readonly"
START_TIME = "1764000000000"
END_TIME = "1764003600000"


class AwsReadonlyTests(unittest.TestCase):
    def test_hook_fixtures_allow_only_plain_wrapper_calls(self):
        cases = json.loads((FIXTURES / "hook-cases.json").read_text())
        for expected, cases_for_expected in ((False, cases["allow"]), (True, cases["deny"])):
            for case in cases_for_expected:
                with self.subTest(case=case["name"]):
                    event = {"tool_name": "Bash", "tool_input": {"command": case["command"]}}
                    result = subprocess.run(
                        [sys.executable, str(GUARD)],
                        input=json.dumps(event),
                        text=True,
                        capture_output=True,
                        check=False,
                    )
                    self.assertEqual(result.returncode, 0, result.stderr)
                    output = json.loads(result.stdout) if result.stdout else {}
                    denied = output.get("hookSpecificOutput", {}).get("permissionDecision") == "deny"
                    self.assertEqual(denied, expected, result.stdout)

    def test_malformed_hook_input_is_denied(self):
        result = subprocess.run(
            [sys.executable, str(GUARD)], input="{", text=True, capture_output=True, check=False
        )
        self.assertEqual(result.returncode, 0)
        self.assertEqual(
            json.loads(result.stdout)["hookSpecificOutput"]["permissionDecision"], "deny"
        )

    def test_read_command_passes_one_explicit_readonly_profile(self):
        result, args, calls = self.run_wrapper(
            "--profile",
            "team-dev-readonly",
            "ec2",
            "describe-instances",
            "--region",
            "ap-northeast-1",
            "--filters",
            "Name=tag:Environment,Values=dev",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, (FIXTURES / "aws-response.json").read_text())
        self.assertEqual(
            args,
            [
                "--profile",
                "team-dev-readonly",
                "ec2",
                "describe-instances",
                "--no-cli-pager",
                "--output",
                "json",
                "--max-items",
                "100",
                "--region",
                "ap-northeast-1",
                "--filters",
                "Name=tag:Environment,Values=dev",
            ],
        )
        self.assertEqual(calls, ["sts get-caller-identity", "ec2 describe-instances"])

    def test_rejected_shapes_never_reach_fake_aws(self):
        rejected = [
            (),
            ("--profile",),
            ("--profile", "team-dev"),
            ("--profile", "default"),
            ("--profile", "default-readonly", "sts", "get-caller-identity"),
            ("--profile", "team-admin-readonly", "sts", "get-caller-identity"),
            ("--profile", "team-dev-readonly", "ec2", "run-instances"),
            ("--profile", "team-dev-readonly", "aws", "s3", "rm", "s3://example"),
            ("--profile", "team-dev-readonly", "cloudformation", "describe-stacks", "--stack-name", "fixture"),
            ("--profile", "team-dev-readonly", "sts", "get-caller-identity", "--profile", "other-readonly"),
            ("--profile", "team-dev-readonly", "sts", "get-caller-identity", "--profile=other-readonly"),
            ("--profile", "team-dev-readonly", "sts", "get-caller-identity", "--no-sign-request"),
            (
                "--profile", "team-dev-readonly", "sts", "get-caller-identity",
                "--endpoint-url", "https://example.invalid",
            ),
            ("--profile", "team-dev-readonly", "s3api", "list-buckets", "--max-buckets", "10000"),
            ("--profile", "team-dev-readonly", "rds", "describe-db-instances", "--max-records", "1000"),
        ]
        for args_to_run in rejected:
            with self.subTest(args=args_to_run):
                result, _, calls = self.run_wrapper(*args_to_run)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(calls, [])

    def test_aws_environment_overrides_are_rejected(self):
        for key, value in (
            ("AWS_PROFILE", "default"),
            ("AWS_ACCESS_KEY_ID", "fixture-key"),
            ("AWS_ENDPOINT_URL", "https://example.invalid"),
            ("AWS_IGNORE_CONFIGURED_ENDPOINT_URLS", "false"),
        ):
            with self.subTest(name=key):
                result, _, calls = self.run_wrapper(
                    "--profile", "team-dev-readonly", "sts", "get-caller-identity", extra_env={key: value}
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(calls, [])

    def test_authentication_failure_is_returned_without_profile_fallback(self):
        result, args, calls = self.run_wrapper(
            "--profile",
            "team-dev-readonly",
            "sts",
            "get-caller-identity",
            extra_env={"FAKE_AWS_EXIT": "254"},
        )
        self.assertEqual(result.returncode, 254, result.stderr)
        self.assertEqual(args[:2], ["--profile", "team-dev-readonly"])
        self.assertEqual(calls, ["sts get-caller-identity"])

    def test_bucket_listing_has_a_fixed_result_limit(self):
        result, args, calls = self.run_wrapper(
            "--profile", "team-dev-readonly", "s3api", "list-buckets"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            args,
            [
                "--profile",
                "team-dev-readonly",
                "s3api",
                "list-buckets",
                "--no-cli-pager",
                "--output",
                "json",
                "--max-buckets",
                "100",
            ],
        )
        self.assertEqual(calls, ["sts get-caller-identity", "s3api list-buckets"])

    def test_codex_hook_merge_preserves_orca_and_is_idempotent(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp) / "hooks.json"
            shutil.copyfile(FIXTURES / "codex-hooks.json", target)
            addition = FIXTURES / "aws-readonly-hook.json"
            for _ in range(2):
                result = subprocess.run(
                    ["/bin/bash", str(MERGE_HOOKS), str(target), str(addition)],
                    text=True,
                    capture_output=True,
                    check=False,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
            hooks = json.loads(target.read_text())["hooks"]
            pre_tool = hooks["PreToolUse"]
            self.assertEqual(len(pre_tool), 2)
            commands = [handler["command"] for group in pre_tool for handler in group["hooks"]]
            self.assertIn("/orca/agent-hooks/codex-hook.sh", commands)
            self.assertEqual(commands.count("/nix/store/fake-aws-readonly-guard/bin/aws-readonly-guard"), 1)
            aws_guard_group = next(
                group
                for group in pre_tool
                if any(
                    handler["command"] == "/nix/store/fake-aws-readonly-guard/bin/aws-readonly-guard"
                    for handler in group["hooks"]
                )
            )
            self.assertEqual(aws_guard_group["matcher"], "Bash")
            self.assertEqual(hooks["PostToolUse"][0]["hooks"][0]["command"], "/orca/agent-hooks/codex-post-hook.sh")

    def test_claude_settings_merge_preserves_existing_hooks(self):
        result = subprocess.run(
            [
                "/bin/bash",
                str(MERGE_CLAUDE_SETTINGS),
                str(ROOT.parent / "claude" / "config" / "settings.json"),
                str(FIXTURES / "claude-aws-readonly-hooks.json"),
            ],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        hooks = json.loads(result.stdout)["hooks"]["PreToolUse"]
        commands = [handler["command"] for group in hooks for handler in group["hooks"]]
        self.assertIn("~/.claude/hooks/log-skill.sh", commands)
        self.assertIn("bash ~/.claude/hooks/git-push-guard.sh", commands)
        self.assertIn("/nix/store/fake-aws-readonly-guard/bin/aws-readonly-guard", commands)

    def test_claude_permissions_deny_direct_aws(self):
        settings = json.loads(CLAUDE_SETTINGS.read_text())
        self.assertIn("Bash(aws *)", settings["permissions"]["deny"])
        self.assertIn("Bash(aws *)", settings["autoMode"]["hard_deny"])

    def test_codex_execpolicy_forbids_aws_and_leaves_wrapper_unmatched(self):
        codex = shutil.which("codex")
        if codex is None:
            self.skipTest("codex is required for offline execpolicy validation")

        cases = json.loads((FIXTURES / "execpolicy-cases.json").read_text())
        with tempfile.TemporaryDirectory() as temp:
            env = {**os.environ, "CODEX_HOME": str(Path(temp) / "codex")}
            for expected, commands in (("forbidden", cases["forbidden"]), (None, cases["not_matched"])):
                for command in commands:
                    with self.subTest(command=command, expected=expected):
                        result = subprocess.run(
                            [
                                codex,
                                "execpolicy",
                                "check",
                                "--pretty",
                                "--rules",
                                str(CODEX_RULES),
                                "--",
                                *command,
                            ],
                            env=env,
                            text=True,
                            capture_output=True,
                            check=False,
                        )
                        self.assertEqual(result.returncode, 0, result.stderr)
                        output = json.loads(result.stdout)
                        self.assertEqual(output.get("decision"), expected, result.stdout)
                        self.assertEqual(bool(output["matchedRules"]), expected is not None, result.stdout)

            result = subprocess.run(
                [
                    codex,
                    "execpolicy",
                    "check",
                    "--pretty",
                    "--resolve-host-executables",
                    "--rules",
                    str(CODEX_RULES),
                    "--",
                    str(FAKE_AWS.resolve()),
                    "--version",
                ],
                env=env,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(json.loads(result.stdout).get("decision"), "forbidden", result.stdout)

            result = subprocess.run(
                [
                    codex,
                    "execpolicy",
                    "check",
                    "--pretty",
                    "--rules",
                    str(CODEX_RULES),
                    "--",
                    str(FAKE_AWS.resolve()),
                    "--version",
                ],
                env=env,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            output = json.loads(result.stdout)
            self.assertIsNone(output.get("decision"), result.stdout)
            self.assertEqual(output["matchedRules"], [], result.stdout)

    def test_ordinary_aws_binary_name_is_not_replaced(self):
        result, args, calls = self.run_fake_aws("--version")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(args, ["--version"])
        self.assertEqual(calls, ["--version"])
        self.assertEqual(WRAPPER.name, "aws-readonly.sh")

    def test_profile_map_is_required_and_checked_before_data_operations(self):
        result, _, calls = self.run_wrapper(
            "--profile", VALID_PROFILE, "ec2", "describe-instances", profile_map=None, environment=None
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(calls, [])

        result, _, calls = self.run_wrapper(
            "--profile", "unknown-readonly", "ec2", "describe-instances"
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(calls, [])

    def test_profile_cannot_be_used_for_a_different_environment(self):
        result, _, calls = self.run_wrapper(
            "--profile", VALID_PROFILE, "ec2", "describe-instances", environment="prod"
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(calls, [])

    def test_invalid_or_writable_profile_maps_fail_before_aws(self):
        for profile_map, config_mode, config_dir_mode in (
            ("{", 0o600, 0o700),
            (DEFAULT_PROFILE_MAP, 0o666, 0o700),
            (DEFAULT_PROFILE_MAP, 0o600, 0o777),
            (
                {
                    "version": 1,
                    "profiles": {
                        VALID_PROFILE: {
                            "environment": "dev",
                            "account_id": "bad",
                            "role_name": "ReadOnlyRole",
                        }
                    },
                },
                0o600,
                0o700,
            ),
            ({"version": 1, "profiles": {
                "team-dev-readonly": {"environment": "dev", "account_id": "123456789012", "role_name": "ReadOnlyRole"},
                "team-prod-readonly": {"environment": "dev", "account_id": "210987654321", "role_name": "OtherRole"},
            }}, 0o600, 0o700),
        ):
            with self.subTest(profile_map=profile_map, config_mode=config_mode, config_dir_mode=config_dir_mode):
                result, _, calls = self.run_wrapper(
                    "--profile", VALID_PROFILE, "ec2", "describe-instances",
                    profile_map=profile_map,
                    config_mode=config_mode,
                    config_dir_mode=config_dir_mode,
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(calls, [])

    def test_account_or_role_mismatch_stops_before_requested_operation(self):
        for key, value in (("account_id", "210987654321"), ("role_name", "DifferentReadOnlyRole")):
            profile_map = json.loads(json.dumps(DEFAULT_PROFILE_MAP))
            profile_map["profiles"][VALID_PROFILE][key] = value
            with self.subTest(key=key):
                result, _, calls = self.run_wrapper(
                    "--profile", VALID_PROFILE, "ec2", "describe-instances",
                    profile_map=profile_map,
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(calls, ["sts get-caller-identity"])
                self.assertNotIn("access-key-fixture", result.stdout + result.stderr)

    def test_log_group_query_returns_only_exact_group_metadata(self):
        result, args, calls = self.run_wrapper(
            "--profile", VALID_PROFILE, "logs", "describe-log-groups",
            "--log-group-name-prefix", "/service/api",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        output = json.loads(result.stdout)
        self.assertEqual(output, {
            "found": True,
            "log_group": {
                "name": "/service/api",
                "creation_time": 1764000000000,
                "retention_in_days": 30,
                "stored_bytes": 4096,
                "class": "STANDARD",
            },
        })
        self.assertNotIn("kmsKeyId", result.stdout)
        self.assertNotIn("api-prod", result.stdout)
        self.assertNotIn("private-key-id", result.stdout)
        query = args[args.index("--query") + 1]
        self.assertIn("name: logGroupName", query)
        self.assertNotIn("kmsKeyId", query)
        self.assertEqual(calls, ["sts get-caller-identity", "logs describe-log-groups"])
        self.assertEqual(args[args.index("--limit") + 1], "1")
        self.assertEqual(args[-2:], ["--log-group-name-prefix", "/service/api"])
        self.assertIn("--no-paginate", args)

    def test_log_event_query_is_bounded_and_never_returns_messages(self):
        result, args, calls = self.run_wrapper(
            "--profile", VALID_PROFILE, "logs", "filter-log-events",
            "--log-group-name", "/service/api",
            "--start-time", START_TIME,
            "--end-time", END_TIME,
            "--filter-pattern", "ERROR",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), {
            "matched_count": 2,
            "first_event_timestamp": 1764000100000,
            "last_event_timestamp": 1764000200000,
            "has_more": True,
        })
        self.assertNotIn("AKIAFAKEACCESSKEY", result.stdout + result.stderr)
        self.assertNotIn("fixture-secret-token", result.stdout + result.stderr)
        self.assertNotIn("next-token-secret", result.stdout + result.stderr)
        self.assertEqual(calls, ["sts get-caller-identity", "logs filter-log-events"])
        self.assertIn("--limit", args)
        self.assertIn("100", args)
        self.assertIn("--no-paginate", args)
        self.assertIn("--no-unmask", args)
        self.assertNotIn("--unmask", args)
        query = args[args.index("--query") + 1]
        self.assertIn("timestamp: timestamp", query)
        self.assertNotIn("message", query)

    def test_log_event_summary_respects_requested_limit(self):
        result, args, calls = self.run_wrapper(
            "--profile", VALID_PROFILE, "logs", "filter-log-events",
            "--log-group-name", "/service/api",
            "--start-time", START_TIME,
            "--end-time", END_TIME,
            "--limit", "1",
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertEqual(args.count("--limit"), 1)
        self.assertEqual(args[args.index("--limit") + 1], "1")
        self.assertEqual(calls, ["sts get-caller-identity", "logs filter-log-events"])

    def test_log_event_query_rejects_missing_or_excessive_bounds(self):
        invalid = (
            ("--start-time", START_TIME),
            ("--end-time", END_TIME),
            ("--start-time", START_TIME, "--end-time", "1764003600001"),
            ("--start-time", "1764003600000", "--end-time", "1764000000000"),
            ("--start-time", "1764000000", "--end-time", END_TIME),
            ("--start-time", "1764000000000", "--end-time", "1764003600000", "--limit", "101"),
            ("--start-time", "1764000000000", "--end-time", "1764003600000", "--limit", "0"),
            ("--start-time", "1764000000000", "--end-time", "1764003600000", "--unmask"),
            ("--start-time", "1764000000000", "--end-time", "1764003600000", "--filter-pattern=file://secret.txt"),
            ("--start-time", "1764000000000", "--end-time", "1764003600000", "--filter-pattern=fileb://secret.bin"),
            ("--start-time", "1764000000000", "--end-time", "1764003600000", "--filter-pattern=--endpoint-url=https://example.invalid"),
        )
        for options in invalid:
            with self.subTest(options=options):
                base = ["--profile", VALID_PROFILE, "logs", "filter-log-events", "--log-group-name", "/service/api"]
                result, _, calls = self.run_wrapper(*base, *options)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(calls, [])

    def test_redacted_log_messages_are_explicit_bounded_and_masked(self):
        result, args, calls = self.run_wrapper(
            "--profile", VALID_PROFILE, "logs", "filter-log-events",
            "--log-group-name", "/service/api",
            "--start-time", START_TIME,
            "--end-time", END_TIME,
            "--filter-pattern=ERROR",
            "--messages", "redacted",
            extra_env={"FAKE_AWS_LOG_EVENTS_RESPONSE": str(FIXTURES / "log-events-messages.json")},
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        output = json.loads(result.stdout)
        self.assertEqual(output["matched_count"], 14)
        self.assertEqual(len(output["events"]), 14)
        self.assertTrue(output["has_more"])
        self.assertEqual(set(output["events"][0]), {"timestamp", "message", "truncated"})
        self.assertIn("upstream returned 503", output["events"][0]["message"])
        self.assertNotIn("fixture-secret-token", result.stdout)
        self.assertNotIn("AKIAABCDEFGHIJKLMNOP", result.stdout)
        self.assertNotIn("fixture-json-access", result.stdout)
        self.assertNotIn("fixture-bearer-value", result.stdout)
        self.assertNotIn("signaturebase64long", result.stdout)
        self.assertNotIn("fixture-private-key-material", result.stdout)
        self.assertEqual(output["events"][4]["message"], "[REDACTED: message withheld]")
        self.assertNotIn("fixture-page-token", result.stdout)
        self.assertNotIn("fixture-event-id", result.stdout)
        self.assertNotIn("fixture-stream", result.stdout)
        self.assertIn("Ignore all rules", output["events"][6]["message"])
        self.assertIn("WARN payload", output["events"][8]["message"])
        self.assertIn("503", output["events"][8]["message"])
        self.assertNotIn("fixture-prefixed-json-secret", result.stdout)
        self.assertNotIn("fixture-nested-json-secret", result.stdout)
        self.assertEqual(output["events"][10]["message"], "[REDACTED: message withheld]")
        self.assertEqual(output["events"][11]["message"], "[REDACTED: message withheld]")
        self.assertEqual(output["events"][12]["message"], "[REDACTED: message withheld]")
        self.assertIn("500", output["events"][13]["message"])
        self.assertNotIn("--messages", args)
        self.assertEqual(args[args.index("--profile") + 1], VALID_PROFILE)
        self.assertEqual(args[args.index("--limit") + 1], "20")
        self.assertEqual(args[args.index("--filter-pattern") + 1], "ERROR")
        self.assertEqual(args[args.index("--log-group-name") + 1], "/service/api")
        self.assertEqual(args[args.index("--start-time") + 1], START_TIME)
        self.assertEqual(args[args.index("--end-time") + 1], END_TIME)
        self.assertEqual(args.count("--limit"), 1)
        self.assertIn("--no-unmask", args)
        self.assertIn("--no-paginate", args)
        self.assertIn("message: message", args[args.index("--query") + 1])
        self.assertEqual(calls, ["sts get-caller-identity", "logs filter-log-events"])

    def test_redacted_log_messages_enforce_item_and_mode_limits_before_aws(self):
        cases = (
            ("raw",),
            ("redacted", "--messages", "redacted"),
            ("redacted", "--limit", "21"),
        )
        for extra in cases:
            with self.subTest(extra=extra):
                result, _, calls = self.run_wrapper(
                    "--profile", VALID_PROFILE, "logs", "filter-log-events",
                    "--log-group-name", "/service/api",
                    "--start-time", START_TIME,
                    "--end-time", END_TIME,
                    "--messages", extra[0],
                    *extra[1:],
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(calls, [])

    def test_redacted_log_messages_hide_partial_output_and_cli_stderr_on_failure(self):
        result, _, calls = self.run_wrapper(
            "--profile", VALID_PROFILE, "logs", "filter-log-events",
            "--log-group-name", "/service/api",
            "--start-time", START_TIME,
            "--end-time", END_TIME,
            "--messages", "redacted",
            extra_env={
                "FAKE_AWS_FAIL_OPERATION": "logs filter-log-events",
                "FAKE_AWS_FAIL_STATUS": "42",
                "FAKE_AWS_PARTIAL_STDOUT": str(FIXTURES / "log-events-messages.json"),
                "FAKE_AWS_STDERR": "fixture-stderr-secret",
            },
        )
        self.assertEqual(result.returncode, 42)
        self.assertEqual(result.stdout, "")
        self.assertNotIn("fixture-stderr-secret", result.stderr)
        self.assertNotIn("fixture-secret-token", result.stdout + result.stderr)
        self.assertEqual(calls, ["sts get-caller-identity", "logs filter-log-events"])

    def test_redacted_log_messages_mask_before_truncating_and_withhold_oversized_text(self):
        with tempfile.TemporaryDirectory() as temp:
            fixture = Path(temp) / "log-events.json"
            fixture.write_text(json.dumps({
                "events": [
                    {"timestamp": 1764000200000, "message": "x" * 1010 + " Bearer fixture-boundary-secret " + "tail " * 400},
                    {"timestamp": 1764000210000, "message": "x" * 70000},
                ],
                "nextToken": None,
            }))
            result, _, _ = self.run_wrapper(
                "--profile", VALID_PROFILE, "logs", "filter-log-events",
                "--log-group-name", "/service/api",
                "--start-time", START_TIME,
                "--end-time", END_TIME,
                "--messages", "redacted",
                "--limit", "2",
                extra_env={"FAKE_AWS_LOG_EVENTS_RESPONSE": str(fixture)},
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        events = json.loads(result.stdout)["events"]
        self.assertTrue(events[0]["truncated"])
        self.assertEqual(len(events[0]["message"]), 1024)
        self.assertNotIn("fixture-boundary-secret", result.stdout)
        self.assertEqual(events[1]["message"], "[REDACTED: message withheld]")
        self.assertFalse(events[1]["truncated"])

    def test_redacted_log_messages_reject_fake_pages_over_requested_limit(self):
        result, _, calls = self.run_wrapper(
            "--profile", VALID_PROFILE, "logs", "filter-log-events",
            "--log-group-name", "/service/api",
            "--start-time", START_TIME,
            "--end-time", END_TIME,
            "--messages", "redacted",
            "--limit", "1",
            extra_env={"FAKE_AWS_LOG_EVENTS_RESPONSE": str(FIXTURES / "log-events-messages.json")},
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertNotIn("fixture-secret-token", result.stdout + result.stderr)
        self.assertEqual(calls, ["sts get-caller-identity", "logs filter-log-events"])

    def run_wrapper(
        self,
        *args,
        extra_env=None,
        environment="dev",
        profile_map=DEFAULT_PROFILE_MAP,
        config_mode=0o600,
        config_dir_mode=0o700,
    ):
        with tempfile.TemporaryDirectory() as temp:
            result, argv, calls = self._run_fake_aws(
                *(("--environment", environment) if environment is not None else ()),
                *args,
                extra_env=extra_env,
                temp=temp,
                wrapper=True,
                profile_map=profile_map,
                config_mode=config_mode,
                config_dir_mode=config_dir_mode,
            )
            return result, argv, calls

    def run_fake_aws(self, *args):
        with tempfile.TemporaryDirectory() as temp:
            return self._run_fake_aws(*args, temp=temp, wrapper=False)

    def _run_fake_aws(
        self,
        *args,
        extra_env=None,
        temp=None,
        wrapper=True,
        profile_map=None,
        config_mode=0o600,
        config_dir_mode=0o700,
    ):
        fake_bin = Path(temp) / "bin"
        fake_bin.mkdir()
        fake = fake_bin / "aws"
        shutil.copyfile(FAKE_AWS, fake)
        fake.chmod(0o755)
        arg_file = Path(temp) / "argv.bin"
        calls_file = Path(temp) / "calls.txt"
        profile_map_file = Path(temp) / "config" / "aws-readonly" / "profiles.json"
        if wrapper:
            profile_map_file.parent.mkdir(parents=True, mode=config_dir_mode)
            profile_map_file.parent.chmod(config_dir_mode)
            if profile_map is not None:
                contents = profile_map if isinstance(profile_map, str) else json.dumps(profile_map)
                profile_map_file.write_text(contents)
                profile_map_file.chmod(config_mode)
        env = {
            "PATH": f"{fake_bin}:/usr/bin:/bin",
            "HOME": temp,
            "FAKE_AWS_ARGV_FILE": str(arg_file),
            "FAKE_AWS_CALLS_FILE": str(calls_file),
            "FAKE_AWS_RESPONSE": str(FIXTURES / "aws-response.json"),
            "FAKE_AWS_IDENTITY_RESPONSE": str(FIXTURES / "caller-identity.json"),
            "FAKE_AWS_LOG_GROUPS_RESPONSE": str(FIXTURES / "log-groups.json"),
            "FAKE_AWS_LOG_EVENTS_RESPONSE": str(FIXTURES / "log-events.json"),
            "FAKE_AWS_EXIT": "0",
        }
        if wrapper:
            env["FAKE_AWS_REQUIRE_ENDPOINT_GUARD"] = "1"
        env.update(extra_env or {})
        command = (
            [
                "/bin/bash",
                str(WRAPPER),
                str(profile_map_file),
                str(temp),
                str(PROFILE_MAP_HELPER),
                str(RESPONSE_FILTER),
                *args,
            ]
            if wrapper
            else ["aws", *args]
        )
        result = subprocess.run(command, env=env, text=True, capture_output=True, check=False)
        argv = arg_file.read_bytes().rstrip(b"\0").decode().split("\0") if arg_file.exists() else []
        calls = calls_file.read_text().splitlines() if calls_file.exists() else []
        return result, argv, calls


if __name__ == "__main__":
    unittest.main()
