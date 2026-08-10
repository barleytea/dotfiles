# ダッシュボードのローカル情報（時刻・温度・メモリ・ディスク・稼働時間）
#
# eww 側で整形処理をしないよう、表示に使う文字列はここで完成させる。
# ネットワークには一切触らないので必ず成功する。

readonly WEEKDAYS=(日 月 火 水 木 金 土)

# CPU 温度。hwmon の番号はブート間で安定しないのでセンサ名で引く
cpu_temp='--'
for hwmon in /sys/class/hwmon/hwmon*; do
    [ -r "$hwmon/name" ] || continue
    case "$(cat "$hwmon/name")" in
        k10temp | coretemp | zenpower) ;;
        *) continue ;;
    esac
    [ -r "$hwmon/temp1_input" ] || continue
    cpu_temp="$(awk '{ printf "%d", $1 / 1000 }' "$hwmon/temp1_input")"
    break
done

# /proc/meminfo の単位は kB
mem_label="$(awk '
    /^MemTotal:/     { total = $2 }
    /^MemAvailable:/ { avail = $2 }
    END {
        used = total - avail
        printf "%.1f / %.1f GiB (%d%%)", used / 1048576, total / 1048576,
               (total > 0 ? used * 100 / total : 0)
    }' /proc/meminfo)"

uptime_label="$(awk '{
    days = int($1 / 86400)
    hours = int(($1 % 86400) / 3600)
    minutes = int(($1 % 3600) / 60)
    if (days > 0) { printf "%d日%d時間", days, hours } else { printf "%d時間%d分", hours, minutes }
}' /proc/uptime)"

# 監視対象のマウントポイントは Nix 側から空白区切りで渡される。
# 存在しないマウントは df が stderr に出すだけで他は正常に出力される
read -ra disk_targets <<<"$DASHBOARD_DISKS"
disks_json="$(df -B1 -P "${disk_targets[@]}" 2>/dev/null |
    awk 'NR > 1 {
        gib = $4 / 1073741824
        if (gib >= 1024) { printf "%s\t%.2f TiB\t%s\n", $6, gib / 1024, $5 }
        else { printf "%s\t%.1f GiB\t%s\n", $6, gib, $5 }
    }' |
    jq -Rsc 'split("\n")
             | map(select(length > 0) | split("\t"))
             | map({ mount: .[0], freeLabel: .[1], usedPerc: .[2] })')"
[ -n "$disks_json" ] || disks_json='[]'

dow="$(date '+%w')"

jq -nc \
    --arg time "$(date '+%H:%M')" \
    --arg dateLabel "$(date '+%Y年%-m月%-d日')（${WEEKDAYS[dow]}）" \
    --argjson now "$(date '+%s')" \
    --arg cpuTemp "$cpu_temp" \
    --arg memLabel "$mem_label" \
    --arg uptime "$uptime_label" \
    --argjson disks "$disks_json" \
    '{
        time: $time,
        dateLabel: $dateLabel,
        now: $now,
        cpuTemp: $cpuTemp,
        memLabel: $memLabel,
        uptime: $uptime,
        disks: $disks
     }'
