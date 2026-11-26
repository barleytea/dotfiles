#!/usr/bin/env python3

import json
import re
import sys


MAX_RESPONSE_BYTES = 2 * 1024 * 1024
LOG_GROUP_CLASSES = {"STANDARD", "INFREQUENT_ACCESS", "DELIVERY", "ESSENTIALS"}
MAX_LOG_EVENTS = 100
MAX_REDACTED_EVENTS = 20
MAX_MESSAGE_CHARS = 1024
MAX_MESSAGE_SCAN_CHARS = 65536
MAX_JSON_FRAGMENT_ATTEMPTS = 32
REDACTED = "[REDACTED]"
WITHHELD = "[REDACTED: message withheld]"

SENSITIVE_KEY_PARTS = (
    "password", "passwd", "passphrase", "secret", "token", "apikey", "accesskey",
    "credential", "authorization", "cookie", "privatekey", "sessionkey", "signingkey",
)
SENSITIVE_LABEL = (
    r"(?:aws[_ -]?secret[_ -]?access[_ -]?key|aws[_ -]?access[_ -]?key[_ -]?id|"
    r"client[_ -]?(?:secret|token)|password|passwd|passphrase|"
    r"secret(?:[_ -]?(?:access[_ -]?key|key))?|access[_ -]?token|refresh[_ -]?token|"
    r"session[_ -]?token|id[_ -]?token|token|api[_ -]?key|access[_ -]?key(?:[_ -]?id)?|"
    r"credential(?:s)?|authorization|set-cookie|cookie|private[_ -]?key|"
    r"session[_ -]?key|signing[_ -]?key)"
)
SENSITIVE_ASSIGNMENT_RE = re.compile(
    rf"(?P<prefix>(?<![A-Za-z0-9]){SENSITIVE_LABEL}(?![A-Za-z0-9])\s*(?:[:=]|\s+(?:is|was)\s+))[^\r\n]*",
    re.IGNORECASE,
)
EMPTY_SENSITIVE_VALUE_RE = re.compile(
    rf"(?<![A-Za-z0-9]){SENSITIVE_LABEL}(?![A-Za-z0-9])\s*[:=]\s*(?:[,;]|$)", re.IGNORECASE | re.MULTILINE
)
UNCLOSED_SENSITIVE_QUOTE_RE = re.compile(
    rf"(?<![A-Za-z0-9]){SENSITIVE_LABEL}(?![A-Za-z0-9])\s*[:=]\s*(['\"])(?:(?!\1)[^\r\n])*$",
    re.IGNORECASE | re.MULTILINE,
)
SUSPICIOUS_JSON_RE = re.compile(
    rf"[\"']{SENSITIVE_LABEL}[\"']\s*:", re.IGNORECASE
)
BEARER_RE = re.compile(r"(?i)\b(Bearer|Basic)\s+\S+")
AWS_KEY_RE = re.compile(r"\b(?:AKIA|ASIA)[A-Z0-9]{12,20}\b")
JWT_RE = re.compile(r"\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*(?![A-Za-z0-9_-])")
PRIVATE_KEY_MARKER_RE = re.compile(
    r"-----(?:BEGIN|END) [A-Z0-9 ]*(?:PRIVATE|SECRET) KEY(?: BLOCK)?-----"
)


class InvalidResponse(Exception):
    pass


def read_response():
    raw = sys.stdin.buffer.read(MAX_RESPONSE_BYTES + 1)
    if len(raw) > MAX_RESPONSE_BYTES:
        raise InvalidResponse
    try:
        response = json.loads(raw)
    except (UnicodeError, json.JSONDecodeError, RecursionError) as error:
        raise InvalidResponse from error
    if not isinstance(response, dict):
        raise InvalidResponse
    return response


def summarize_group(response, expected_name):
    groups = response.get("logGroups", [])
    if not isinstance(groups, list):
        raise InvalidResponse
    matches = [
        group
        for group in groups
        if isinstance(group, dict) and group.get("name", group.get("logGroupName")) == expected_name
    ]
    if len(matches) > 1:
        raise InvalidResponse
    if not matches:
        return {"found": False}

    group = matches[0]
    creation_time = group.get("creationTime")
    if type(creation_time) is not int or creation_time < 0:
        raise InvalidResponse
    summary = {
        "name": expected_name,
        "creation_time": creation_time,
        "retention_in_days": group.get("retentionInDays"),
        "stored_bytes": group.get("storedBytes"),
        "class": group.get("logGroupClass"),
    }
    for key in ("retention_in_days", "stored_bytes"):
        value = summary[key]
        if value is not None and (type(value) is not int or value < 0):
            raise InvalidResponse
    group_class = summary["class"]
    if group_class is not None and group_class not in LOG_GROUP_CLASSES:
        raise InvalidResponse
    return {"found": True, "log_group": summary}


def is_sensitive_key(key):
    normalized = re.sub(r"[^a-z0-9]", "", key.lower())
    return any(part in normalized for part in SENSITIVE_KEY_PARTS)


def redact_text(message):
    if len(message) > MAX_MESSAGE_SCAN_CHARS:
        return WITHHELD
    if EMPTY_SENSITIVE_VALUE_RE.search(message) or UNCLOSED_SENSITIVE_QUOTE_RE.search(message):
        return WITHHELD

    if PRIVATE_KEY_MARKER_RE.search(message):
        return WITHHELD

    message = redact_json_fragments(message)
    if message == WITHHELD:
        return message

    message = SENSITIVE_ASSIGNMENT_RE.sub(lambda match: match.group("prefix") + REDACTED, message)
    message = BEARER_RE.sub(lambda match: match.group(1) + " " + REDACTED, message)
    message = AWS_KEY_RE.sub(REDACTED, message)
    return JWT_RE.sub(REDACTED, message)


def redact_json_fragments(message):
    decoder = json.JSONDecoder()
    fragments = []
    markers = list(SUSPICIOUS_JSON_RE.finditer(message))
    replacements = []
    index = 0
    copy_from = 0
    attempts = 0
    while index < len(message):
        if message[index] not in "[{":
            index += 1
            continue
        attempts += 1
        if attempts > MAX_JSON_FRAGMENT_ATTEMPTS:
            return WITHHELD
        try:
            parsed, end = decoder.raw_decode(message, index)
        except (json.JSONDecodeError, RecursionError):
            index += 1
            continue
        if not isinstance(parsed, (dict, list)):
            index += 1
            continue
        try:
            replacement = json.dumps(redact_tree(parsed), ensure_ascii=False, separators=(",", ":"))
        except (RecursionError, TypeError, ValueError):
            return WITHHELD
        fragments.append((index, end, replacement))
        replacements.extend((message[copy_from:index], replacement))
        copy_from = end
        index = end

    fragment_index = 0
    for marker in markers:
        while fragment_index < len(fragments) and fragments[fragment_index][1] <= marker.start():
            fragment_index += 1
        if (
            fragment_index >= len(fragments)
            or not fragments[fragment_index][0] <= marker.start() < fragments[fragment_index][1]
        ):
            return WITHHELD
    replacements.append(message[copy_from:])
    return "".join(replacements)


def redact_tree(value):
    if isinstance(value, dict):
        redacted = {}
        for key, child in value.items():
            safe_key = redact_text(key)
            if safe_key == WITHHELD:
                safe_key = "[REDACTED KEY]"
            redacted[safe_key] = REDACTED if is_sensitive_key(key) else redact_tree(child)
        return redacted
    if isinstance(value, list):
        return [redact_tree(child) for child in value]
    if isinstance(value, str):
        return redact_text(value)
    return value


def redacted_preview(message):
    if len(message) > MAX_MESSAGE_SCAN_CHARS:
        return WITHHELD, False

    candidate = message
    already_redacted = False
    stripped = message.lstrip()
    if stripped.startswith(("{", "[")):
        try:
            parsed = json.loads(message)
        except (json.JSONDecodeError, RecursionError):
            if SUSPICIOUS_JSON_RE.search(message):
                return WITHHELD, False
        else:
            if isinstance(parsed, (dict, list)):
                try:
                    candidate = json.dumps(redact_tree(parsed), ensure_ascii=False, separators=(",", ":"))
                    already_redacted = True
                except (RecursionError, TypeError, ValueError):
                    return WITHHELD, False
            elif isinstance(parsed, str):
                candidate = parsed

    if not already_redacted:
        candidate = redact_text(candidate)
    truncated = len(candidate) > MAX_MESSAGE_CHARS
    if truncated:
        candidate = candidate[:MAX_MESSAGE_CHARS]
    return candidate, truncated


def summarize_events(response, *, include_messages=False, limit=MAX_LOG_EVENTS):
    if type(limit) is not int or limit < 1 or limit > MAX_LOG_EVENTS:
        raise InvalidResponse
    if include_messages and limit > MAX_REDACTED_EVENTS:
        raise InvalidResponse
    events = response.get("events", [])
    if not isinstance(events, list):
        raise InvalidResponse
    if len(events) > limit:
        raise InvalidResponse
    timestamps = []
    output_events = []
    for event in events:
        if (
            not isinstance(event, dict)
            or type(event.get("timestamp")) is not int
            or event["timestamp"] < 0
            or event["timestamp"] > 9_999_999_999_999
        ):
            raise InvalidResponse
        timestamps.append(event["timestamp"])
        if include_messages:
            message = event.get("message")
            if not isinstance(message, str):
                raise InvalidResponse
            preview, truncated = redacted_preview(message)
            output_events.append({
                "timestamp": event["timestamp"],
                "message": preview,
                "truncated": truncated,
            })
    token = response.get("nextToken")
    if token is not None and not isinstance(token, str):
        raise InvalidResponse
    summary = {
        "matched_count": len(events),
        "first_event_timestamp": min(timestamps) if timestamps else None,
        "last_event_timestamp": max(timestamps) if timestamps else None,
        "has_more": bool(token),
    }
    if include_messages:
        summary["events"] = output_events
    return summary


def main():
    try:
        if len(sys.argv) == 3 and sys.argv[1] == "describe-log-groups":
            output = summarize_group(read_response(), sys.argv[2])
        elif len(sys.argv) in (2, 3) and sys.argv[1] in ("filter-log-events", "filter-log-events-redacted"):
            include_messages = sys.argv[1] == "filter-log-events-redacted"
            limit = int(sys.argv[2]) if len(sys.argv) == 3 else MAX_LOG_EVENTS
            output = summarize_events(read_response(), include_messages=include_messages, limit=limit)
        else:
            raise InvalidResponse
    except (InvalidResponse, TypeError, ValueError):
        print("aws-readonly: AWS response could not be summarized safely", file=sys.stderr)
        return 65
    print(json.dumps(output, ensure_ascii=True, separators=(",", ":"), sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
