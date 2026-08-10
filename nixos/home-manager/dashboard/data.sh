# dashboard-fetch が書き出した JSON を eww に渡す
#
# ファイルが無い（初回起動）場合や壊れている場合は空オブジェクトを返し、
# eww 側のフォールバックでプレースホルダを描画させる。

if payload="$(jq -c '.' -- "$DASHBOARD_DATA_FILE" 2>/dev/null)" && [ -n "$payload" ]; then
    printf '%s' "$payload"
else
    printf '{}'
fi
