#!/usr/bin/env python3

import json
import os
from pathlib import Path
import re
import stat
import sys


PROFILE_NAME = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.-]*-readonly$")
ENVIRONMENT_NAME = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.-]{0,63}$")
ACCOUNT_ID = re.compile(r"^[0-9]{12}$")
ROLE_NAME = re.compile(r"^[A-Za-z0-9+=,.@_-]{1,64}$")
ASSUMED_ROLE_ARN = re.compile(
    r"^arn:[A-Za-z0-9-]+:sts::([0-9]{12}):assumed-role/([A-Za-z0-9+=,.@_-]{1,64})/[A-Za-z0-9+=,.@_-]{1,64}$"
)
MAX_CONFIG_BYTES = 65536


class InvalidMapping(Exception):
    pass


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise InvalidMapping
        result[key] = value
    return result


def validate_profile_name(profile):
    if not isinstance(profile, str) or not PROFILE_NAME.fullmatch(profile):
        raise InvalidMapping
    lowered = profile.lower()
    if "admin" in lowered or "default" in lowered:
        raise InvalidMapping


def read_profile_mapping(path, home_path, environment, profile):
    validate_profile_name(profile)
    if not isinstance(environment, str) or not ENVIRONMENT_NAME.fullmatch(environment):
        raise InvalidMapping
    config_path = Path(path)
    home = Path(home_path)
    if not config_path.is_absolute() or not home.is_absolute():
        raise InvalidMapping
    try:
        home_info = home.lstat()
    except OSError as error:
        raise InvalidMapping from error
    if not stat.S_ISDIR(home_info.st_mode) or stat.S_ISLNK(home_info.st_mode):
        raise InvalidMapping
    if home_info.st_uid != os.geteuid() or stat.S_IMODE(home_info.st_mode) & 0o022:
        raise InvalidMapping

    try:
        relative_path = config_path.relative_to(home)
    except ValueError as error:
        raise InvalidMapping from error
    if not relative_path.parts or any(part in {".", ".."} for part in relative_path.parts):
        raise InvalidMapping
    current_directory = home
    for part in relative_path.parts[:-1]:
        current_directory = current_directory / part
        try:
            directory = current_directory.lstat()
        except OSError as error:
            raise InvalidMapping from error
        if (
            not stat.S_ISDIR(directory.st_mode)
            or stat.S_ISLNK(directory.st_mode)
            or directory.st_uid != os.geteuid()
            or stat.S_IMODE(directory.st_mode) & 0o022
        ):
            raise InvalidMapping

    no_follow = getattr(os, "O_NOFOLLOW", None)
    if no_follow is None:
        raise InvalidMapping
    try:
        descriptor = os.open(config_path, os.O_RDONLY | no_follow)
        with os.fdopen(descriptor, "rb") as config_file:
            config = os.fstat(config_file.fileno())
            if (
                not stat.S_ISREG(config.st_mode)
                or config.st_uid != os.geteuid()
                or stat.S_IMODE(config.st_mode) & 0o022
                or config.st_size > MAX_CONFIG_BYTES
            ):
                raise InvalidMapping
            raw_config = config_file.read(MAX_CONFIG_BYTES + 1)
            if len(raw_config) > MAX_CONFIG_BYTES:
                raise InvalidMapping
        root = json.loads(raw_config.decode("utf-8"), object_pairs_hook=unique_object)
    except (OSError, UnicodeError, json.JSONDecodeError, InvalidMapping) as error:
        raise InvalidMapping from error
    if not isinstance(root, dict) or set(root) != {"version", "profiles"}:
        raise InvalidMapping
    if type(root["version"]) is not int or root["version"] != 1:
        raise InvalidMapping
    profiles = root["profiles"]
    if not isinstance(profiles, dict) or not profiles:
        raise InvalidMapping

    mapped_environments = set()
    for name, mapping in profiles.items():
        validate_profile_name(name)
        if not isinstance(mapping, dict) or set(mapping) != {"environment", "account_id", "role_name"}:
            raise InvalidMapping
        mapped_environment = mapping["environment"]
        if not isinstance(mapped_environment, str) or not ENVIRONMENT_NAME.fullmatch(mapped_environment):
            raise InvalidMapping
        if mapped_environment in mapped_environments:
            raise InvalidMapping
        mapped_environments.add(mapped_environment)
        if not isinstance(mapping["account_id"], str) or not ACCOUNT_ID.fullmatch(mapping["account_id"]):
            raise InvalidMapping
        role = mapping["role_name"]
        if not isinstance(role, str) or not ROLE_NAME.fullmatch(role):
            raise InvalidMapping
        lowered_role = role.lower()
        if "admin" in lowered_role or "default" in lowered_role:
            raise InvalidMapping

    if profile not in profiles:
        raise InvalidMapping
    mapping = profiles[profile]
    if mapping["environment"] != environment:
        raise InvalidMapping
    return mapping


def verify_identity(expected_json, identity_json):
    expected = json.loads(expected_json, object_pairs_hook=unique_object)
    if not isinstance(expected, dict) or set(expected) != {"environment", "account_id", "role_name"}:
        raise InvalidMapping
    if not isinstance(expected["environment"], str) or not ENVIRONMENT_NAME.fullmatch(expected["environment"]):
        raise InvalidMapping
    if not isinstance(expected["account_id"], str) or not ACCOUNT_ID.fullmatch(expected["account_id"]):
        raise InvalidMapping
    if not isinstance(expected["role_name"], str) or not ROLE_NAME.fullmatch(expected["role_name"]):
        raise InvalidMapping
    identity = json.loads(identity_json, object_pairs_hook=unique_object)
    if not isinstance(identity, dict):
        raise InvalidMapping
    account = identity.get("Account")
    arn = identity.get("Arn")
    if not isinstance(account, str) or not ACCOUNT_ID.fullmatch(account):
        raise InvalidMapping
    if not isinstance(arn, str):
        raise InvalidMapping
    match = ASSUMED_ROLE_ARN.fullmatch(arn)
    if not match:
        raise InvalidMapping
    arn_account, arn_role = match.groups()
    if account != expected["account_id"] or arn_account != expected["account_id"]:
        raise InvalidMapping
    if arn_role != expected["role_name"]:
        raise InvalidMapping


def main():
    try:
        if len(sys.argv) == 6 and sys.argv[1] == "lookup":
            mapping = read_profile_mapping(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
            print(json.dumps(mapping, separators=(",", ":")))
            return 0
        if len(sys.argv) == 3 and sys.argv[1] == "verify":
            verify_identity(sys.argv[2], sys.stdin.read(MAX_CONFIG_BYTES))
            return 0
    except (InvalidMapping, json.JSONDecodeError, RecursionError, TypeError, ValueError):
        pass

    print("aws-readonly: trusted profile mapping or caller identity is invalid", file=sys.stderr)
    return 64


if __name__ == "__main__":
    sys.exit(main())
