#!/usr/bin/env python3

import json
import re
import shlex
import sys


AWS_COMMAND = re.compile(r"(?<![A-Za-z0-9_.-])(?:aws-readonly|aws)(?![A-Za-z0-9_.-])", re.IGNORECASE)
AWS_ENVIRONMENT = re.compile(r"(?<![A-Za-z0-9_])AWS_[A-Za-z0-9_]+\b")
SHELL_META = re.compile(r"[\r\n;&|<>`$\\]")
WRAPPER = "~/.local/bin/aws-readonly"


def denial(reason):
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }


def should_deny(command):
    if not AWS_COMMAND.search(command) and not AWS_ENVIRONMENT.search(command):
        return None
    if SHELL_META.search(command):
        return "AWS commands must be one simple wrapper invocation"
    try:
        arguments = shlex.split(command, posix=True)
    except ValueError:
        return "AWS command could not be parsed safely"
    if not arguments or arguments[0] != WRAPPER:
        return "Use only ~/.local/bin/aws-readonly for AWS CLI access"
    return None


def main():
    try:
        event = json.load(sys.stdin)
        command = event["tool_input"]["command"]
        if not isinstance(command, str):
            raise TypeError("command is not a string")
        reason = should_deny(command)
        if reason:
            print(json.dumps(denial(reason)))
    except Exception:
        print(json.dumps(denial("AWS command could not be inspected safely")))


if __name__ == "__main__":
    main()
