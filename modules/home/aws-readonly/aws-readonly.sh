#!/usr/bin/env bash

set -euo pipefail

deny() {
  printf 'aws-readonly: %s\n' "$1" >&2
  exit 64
}

if [[ $# -lt 4 ]]; then
  deny "the wrapper configuration is incomplete"
fi

profile_map_path=$1
home_path=$2
profile_map_helper=$3
response_filter=$4
shift 4

while IFS= read -r variable; do
  if [[ "$variable" == AWS_* ]]; then
    deny "AWS environment overrides are not allowed"
  fi
done < <(compgen -e)

if [[ $# -lt 6 || "$1" != "--environment" || "$3" != "--profile" ]]; then
  deny "name --environment and --profile before the service and operation"
fi

environment=$2
if [[ ! "$environment" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]{0,63}$ ]]; then
  deny "the environment label must use simple letters, digits, dots, underscores, or hyphens"
fi

profile=$4
if [[ ! "$profile" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*-readonly$ ]]; then
  deny "the profile must end with -readonly"
fi

profile_lower=$(printf '%s' "$profile" | tr '[:upper:]' '[:lower:]')
case "$profile_lower" in
  *admin*|*default*)
    deny "default and administrative profiles are not allowed"
    ;;
esac

service=$5
operation=$6
shift 6
argument_count=$#
arguments=()
if [[ $argument_count -gt 0 ]]; then
  arguments=("$@")
fi

case "$service $operation" in
  "sts get-caller-identity")
    allowed_options=(--region)
    ;;
  "ec2 describe-instances")
    allowed_options=(--region --filters --instance-ids)
    ;;
  "ec2 describe-vpcs")
    allowed_options=(--region --filters --vpc-ids)
    ;;
  "ec2 describe-subnets")
    allowed_options=(--region --filters --subnet-ids --vpc-id)
    ;;
  "cloudformation list-stacks")
    allowed_options=(--region --stack-status-filter)
    ;;
  "s3api list-buckets")
    allowed_options=(--region --bucket-region --continuation-token)
    ;;
  "rds describe-db-instances")
    allowed_options=(--region --db-instance-identifier --filters --max-records --marker)
    ;;
  "logs describe-log-groups")
    allowed_options=(--region --log-group-name-prefix)
    ;;
  "logs filter-log-events")
    allowed_options=(--region --log-group-name --start-time --end-time --filter-pattern --limit --messages)
    ;;
  "lambda get-function-configuration")
    allowed_options=(--region --function-name --qualifier)
    ;;
  *)
    deny "service and operation are not in the read-only allowlist"
    ;;
esac

allowed_list=" ${allowed_options[*]} "
option_names=()
option_values=()
include_log_messages=false

for ((index = 0; index < argument_count; index++)); do
  argument=${arguments[index]}
  if [[ "$argument" != --* ]]; then
    deny "positional arguments are not allowed"
  fi

  option=${argument%%=*}
  case "$allowed_list" in
    *" $option "*) ;;
    *) deny "option is not in the read-only allowlist: $option" ;;
  esac
  for seen_option in "${option_names[@]-}"; do
    if [[ "$seen_option" == "$option" ]]; then
      deny "an option cannot be repeated: $option"
    fi
  done
  option_names+=("$option")

  if [[ "$argument" == *=* ]]; then
    value=${argument#*=}
  else
    next_index=$((index + 1))
    if [[ $next_index -ge $argument_count ]]; then
      deny "option requires a value: $option"
    fi
    value=${arguments[next_index]}
    if [[ "$value" == --* ]]; then
      deny "option requires a value: $option"
    fi
    index=$next_index
  fi

  if [[ "$value" == --* ]]; then
    deny "option values cannot be interpreted as additional AWS options"
  fi
  if [[ -z "$value" ]]; then
    deny "option requires a value: $option"
  fi
  case "$option" in
    --region)
      if [[ ! "$value" =~ ^[a-z0-9-]+$ ]]; then
        deny "region must be a simple AWS region name"
      fi
      ;;
    --function-name)
      if [[ ${#value} -gt 64 || ! "$value" =~ ^[A-Za-z0-9_.-]+$ ]]; then
        deny "Lambda function name must be a simple name of at most 64 characters"
      fi
      ;;
    --qualifier)
      case "$value" in
        '$LATEST'|'$LATEST.PUBLISHED') ;;
        *)
          if [[ ${#value} -gt 128 || ! "$value" =~ ^[A-Za-z0-9_-]+$ ]]; then
            deny "Lambda qualifier must be a version, alias, or supported latest value"
          fi
          ;;
      esac
      ;;
    --log-group-name-prefix|--log-group-name)
      if [[ ${#value} -gt 512 || ! "$value" =~ ^[A-Za-z0-9._/#-]+$ ]]; then
        deny "log group names may contain only AWS log group name characters"
      fi
      ;;
    --start-time|--end-time)
      if [[ ! "$value" =~ ^[0-9]{13}$ ]]; then
        deny "log event times must be 13-digit epoch milliseconds"
      fi
      ;;
    --filter-pattern)
      if [[ ${#value} -gt 1024 ]]; then
        deny "filter patterns cannot exceed 1024 characters"
      fi
      filter_pattern_lower=$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')
      case "$filter_pattern_lower" in
        file://*|fileb://*) deny "filter patterns must be literal, not file references" ;;
      esac
      ;;
    --limit)
      if [[ ! "$value" =~ ^[0-9]+$ || ${#value} -gt 3 ]]; then
        deny "log event limits must be between 1 and 100"
      fi
      limit_value=$((10#$value))
      if [[ $limit_value -lt 1 || $limit_value -gt 100 ]]; then
        deny "log event limits must be between 1 and 100"
      fi
      ;;
    --messages)
      if [[ "$value" != "redacted" ]]; then
        deny "log messages require the explicit redacted mode"
      fi
      include_log_messages=true
      ;;
    --max-records)
      if [[ ! "$value" =~ ^[0-9]+$ || ${#value} -gt 3 ]]; then
        deny "--max-records must be between 20 and 100"
      fi
      record_limit=$((10#$value))
      if [[ $record_limit -lt 20 || $record_limit -gt 100 ]]; then
        deny "--max-records must be between 20 and 100"
      fi
      ;;
  esac
  option_values+=("$value")
done

option_value() {
  local requested_option=$1
  local option_index
  for ((option_index = 0; option_index < ${#option_names[@]}; option_index++)); do
    if [[ "${option_names[option_index]}" == "$requested_option" ]]; then
      printf '%s' "${option_values[option_index]}"
      return 0
    fi
  done
  return 1
}

case "$service $operation" in
  "logs describe-log-groups")
    log_group_prefix=$(option_value --log-group-name-prefix) || deny "an exact log group name is required"
    ;;
  "logs filter-log-events")
    log_group_name=$(option_value --log-group-name) || deny "an exact log group name is required"
    start_time=$(option_value --start-time) || deny "both log event time bounds are required"
    end_time=$(option_value --end-time) || deny "both log event time bounds are required"
    start_millis=$((10#$start_time))
    end_millis=$((10#$end_time))
    if [[ $start_millis -ge $end_millis || $((end_millis - start_millis)) -gt 3600000 ]]; then
      deny "the log event time window must be positive and no longer than one hour"
    fi
    if [[ "$include_log_messages" == true ]]; then
      requested_limit=$(option_value --limit || true)
      if [[ -n "$requested_limit" && $((10#$requested_limit)) -gt 20 ]]; then
        deny "redacted log message mode is limited to 20 events"
      fi
    fi
    ;;
  "lambda get-function-configuration")
    option_value --function-name >/dev/null || deny "an exact Lambda function name is required"
    ;;
esac

expected_identity=$(python3 "$profile_map_helper" lookup "$profile_map_path" "$home_path" "$environment" "$profile" 2>/dev/null) \
  || deny "the profile is not in a valid user-trusted account and role map"

aws_binary=$(type -P aws || true)
if [[ -z "$aws_binary" ]]; then
  deny "AWS CLI binary is not available; no fallback was attempted"
fi

export AWS_IGNORE_CONFIGURED_ENDPOINT_URLS=true
if identity_response=$("$aws_binary" --profile "$profile" sts get-caller-identity --no-cli-pager --output json); then
  :
else
  identity_status=$?
  exit "$identity_status"
fi
if ! printf '%s' "$identity_response" | python3 "$profile_map_helper" verify "$expected_identity" >/dev/null 2>&1; then
  deny "the caller account or assumed role does not match the trusted profile map"
fi

if [[ "$service $operation" == "sts get-caller-identity" ]]; then
  printf '%s\n' "$identity_response"
  exit 0
fi

cli_arguments=(--profile "$profile" "$service" "$operation" --no-cli-pager --output json)
case "$service $operation" in
  "s3api list-buckets") cli_arguments+=(--max-buckets 100) ;;
  "logs describe-log-groups")
    cli_arguments+=(--limit 1 --no-paginate --query '{logGroups: logGroups[].{name: logGroupName, creationTime: creationTime, retentionInDays: retentionInDays, storedBytes: storedBytes, logGroupClass: logGroupClass}}' "$@")
    "$aws_binary" "${cli_arguments[@]}" | python3 "$response_filter" describe-log-groups "$log_group_prefix"
    exit $?
    ;;
  "logs filter-log-events")
    if [[ "$include_log_messages" == true ]]; then
      cli_arguments+=(--no-paginate --no-unmask --query '{events: events[].{timestamp: timestamp, message: message}, nextToken: nextToken}')
      response_mode=filter-log-events-redacted
    else
      cli_arguments+=(--no-paginate --no-unmask --query '{events: events[].{timestamp: timestamp}, nextToken: nextToken}')
      response_mode=filter-log-events
    fi
    message_limit=$(option_value --limit || true)
    if [[ -z "$message_limit" ]]; then
      if [[ "$include_log_messages" == true ]]; then
        message_limit=20
      else
        message_limit=100
      fi
    fi
    cli_arguments+=(--limit "$message_limit")
    log_filter_arguments=()
    for ((index = 0; index < ${#option_names[@]}; index++)); do
      if [[ "${option_names[index]}" != "--messages" && "${option_names[index]}" != "--limit" ]]; then
        log_filter_arguments+=("${option_names[index]}" "${option_values[index]}")
      fi
    done
    if [[ "$include_log_messages" == true ]]; then
      if filtered_response=$("$aws_binary" "${cli_arguments[@]}" "${log_filter_arguments[@]}" 2>/dev/null | python3 "$response_filter" "$response_mode" "$message_limit"); then
        printf '%s\n' "$filtered_response"
      else
        aws_status=$?
        printf 'aws-readonly: CloudWatch Logs request failed; no event bodies were returned\n' >&2
        exit "$aws_status"
      fi
      exit 0
    fi
    cli_arguments+=("${log_filter_arguments[@]}")
    "$aws_binary" "${cli_arguments[@]}" | python3 "$response_filter" "$response_mode" "$message_limit"
    exit $?
    ;;
  "lambda get-function-configuration")
    lambda_query='{FunctionName: FunctionName, Runtime: Runtime, Handler: Handler, CodeSize: CodeSize,'
    lambda_query+=' Timeout: Timeout, MemorySize: MemorySize, LastModified: LastModified, Version: Version,'
    lambda_query+=' State: State, LastUpdateStatus: LastUpdateStatus, PackageType: PackageType, Architectures: Architectures}'
    cli_arguments+=(--query "$lambda_query")
    ;;
  *) cli_arguments+=(--max-items 100) ;;
esac
cli_arguments+=("$@")
exec "$aws_binary" "${cli_arguments[@]}"
