#!/usr/bin/env bash
# Claude Code の settings.json を base + overlay からマージして stdout に出力する。
#
# 使い方: merge-settings.sh <base.json> [overlay.json ...]
#
# マージ規則（jq の `*` 演算子と異なる点に注意）:
#   - オブジェクトは再帰的にディープマージする
#   - `hooks` 配下の配列は連結する（base のフックが overlay に潰されないようにするため）
#   - それ以外の配列は overlay 側で置換する（allow/deny や excludedCommands は overlay が全体を持つ）
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "usage: $0 <base.json> [overlay.json ...]" >&2
  exit 1
fi

jq -s '
  # 引数は値（$付き）で受ける。フィルタ引数だとネスト時に参照先がずれる
  def merge($a; $b; $inhooks):
    if ($a|type) == "object" and ($b|type) == "object" then
      reduce ($b|keys_unsorted[]) as $k ($a; .[$k] = merge($a[$k]; $b[$k]; ($inhooks or $k == "hooks")))
    elif $inhooks and ($a|type) == "array" and ($b|type) == "array" then $a + $b
    else $b end;
  reduce .[1:][] as $o (.[0]; merge(.; $o; false))
' "$@"
