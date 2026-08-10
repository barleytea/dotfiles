# 生活情報ダッシュボード用データ取得
#
# 各データソースは独立に失敗させる（errexit を無効にしてある）。
# 失敗したセクションは出力に現れず、前回の JSON の値がそのまま生き残る。
# これによりネットワーク断や API 仕様変更でダッシュボードが空にならない。

readonly UA="dotfiles-dashboard/1.0 (+https://github.com/barleytea/dotfiles)"
readonly CURL_OPTS=(
    --fail --silent --show-error --location --compressed
    --user-agent "$UA" --max-time 10 --retry 1 --retry-delay 3
)

work="$(mktemp -d)" || exit 1
trap 'rm -rf "$work"' EXIT

readonly sections="$work/sections.json"
printf '{}' >"$sections"

warn() {
    printf 'WARN: %s\n' "$*" >&2
}

# get <name> <url> — 取得結果を $work/<name> に落とす
get() {
    if curl "${CURL_OPTS[@]}" --output "$work/$1" -- "$2"; then
        return 0
    fi
    warn "fetch failed: $1"
    return 1
}

# add <key> <jq の引数...> — jq の出力を sections.json の <key> に格納する
add() {
    local key="$1"
    shift
    local fragment
    if ! fragment="$(jq -c "$@" 2>"$work/jq.err")"; then
        warn "parse failed: $key: $(tr '\n' ' ' <"$work/jq.err")"
        return 1
    fi
    if [ -z "$fragment" ] || [ "$fragment" = null ]; then
        warn "parse empty: $key"
        return 1
    fi
    jq -c --arg k "$key" --argjson v "$fragment" '. + {($k): $v}' "$sections" >"$sections.new" &&
        mv -f "$sections.new" "$sections"
}

# 週間予報の曜日ラベルと祝日の基準日に使う。
# ロケールに依存しないよう曜日名は自前で引く（時刻の整形は dashboard-live が担当）
readonly WEEKDAYS='["日","月","火","水","木","金","土"]'
today="$(date '+%Y-%m-%d')"
today_dow="$(date '+%w')"
readonly today today_dow

# ------------------------------------------------------------------- 1. 天気
# 天気状態の真実の源は Open-Meteo の WMO weather_code 一本に絞り、
# アイコンと日本語ラベルのマッピング表をこの 1 箇所だけに持つ。
# アイコンは Nerd Font の Weather Icons (U+E300 台。Hack Nerd Font に収録済み)を
# \u エスケープで書き、リポジトリに私用領域の生グリフを置かない
readonly WMO='{
    "0":  {"icon":"\ue30d","label":"晴"},
    "1":  {"icon":"\ue30c","label":"晴"},
    "2":  {"icon":"\ue302","label":"晴時々曇"},
    "3":  {"icon":"\ue313","label":"曇"},
    "45": {"icon":"\ue314","label":"霧"},
    "48": {"icon":"\ue314","label":"霧氷"},
    "51": {"icon":"\ue31c","label":"霧雨"},
    "53": {"icon":"\ue31c","label":"霧雨"},
    "55": {"icon":"\ue31c","label":"強い霧雨"},
    "56": {"icon":"\ue31c","label":"着氷性の霧雨"},
    "57": {"icon":"\ue31c","label":"着氷性の霧雨"},
    "61": {"icon":"\ue31a","label":"弱い雨"},
    "63": {"icon":"\ue319","label":"雨"},
    "65": {"icon":"\ue318","label":"強い雨"},
    "66": {"icon":"\ue319","label":"着氷性の雨"},
    "67": {"icon":"\ue319","label":"着氷性の雨"},
    "71": {"icon":"\ue31b","label":"弱い雪"},
    "73": {"icon":"\ue31b","label":"雪"},
    "75": {"icon":"\ue31b","label":"強い雪"},
    "77": {"icon":"\ue31b","label":"霧雪"},
    "80": {"icon":"\ue31a","label":"にわか雨"},
    "81": {"icon":"\ue31a","label":"にわか雨"},
    "82": {"icon":"\ue318","label":"激しいにわか雨"},
    "85": {"icon":"\ue31b","label":"にわか雪"},
    "86": {"icon":"\ue31b","label":"強いにわか雪"},
    "95": {"icon":"\ue31e","label":"雷雨"},
    "96": {"icon":"\ue315","label":"雷雨・雹"},
    "99": {"icon":"\ue315","label":"雷雨・雹"}
}'
readonly WMO_UNKNOWN='{"icon":"\ue37b","label":"—"}'
readonly DIRS16='["北","北北東","北東","東北東","東","東南東","南東","南南東",
                  "南","南南西","南西","西南西","西","西北西","北西","北北西"]'

om_url="https://api.open-meteo.com/v1/forecast"
om_url+="?latitude=${DASHBOARD_LAT}&longitude=${DASHBOARD_LON}"
om_url+="&timezone=Asia%2FTokyo&wind_speed_unit=ms&forecast_days=7"
om_url+="&current=temperature_2m,apparent_temperature,relative_humidity_2m"
om_url+=",weather_code,wind_speed_10m,wind_direction_10m"
om_url+="&daily=weather_code,temperature_2m_max,temperature_2m_min"
om_url+=",precipitation_probability_max,sunrise,sunset"

if get openmeteo "$om_url"; then
    add weather \
        --argjson wmo "$WMO" \
        --argjson unknown "$WMO_UNKNOWN" \
        --argjson dirs "$DIRS16" \
        --argjson wd "$WEEKDAYS" \
        --argjson dow0 "$today_dow" \
        --arg place "$DASHBOARD_PLACE_LABEL" \
        '
        def look($c): ($wmo[(($c // 999) | tostring)] // $unknown);
        def dir16($d): if $d == null then "—" else $dirs[((($d + 11.25) / 22.5) | floor) % 16] end;
        def suffixed($v; $unit): if $v == null then "--" else "\($v)\($unit)" end;
        def temp($v): if $v == null then "--" else ($v | round | tostring) end;
        def hhmm($v): (($v // "") | split("T") | (.[1] // "--"));
        . as $r
        | {
            at: (now | floor),
            place: $place,
            current: {
                icon:     look($r.current.weather_code).icon,
                label:    look($r.current.weather_code).label,
                temp:     suffixed($r.current.temperature_2m; ""),
                apparent: suffixed($r.current.apparent_temperature; "℃"),
                humidity: suffixed($r.current.relative_humidity_2m; "%"),
                wind:     (if $r.current.wind_speed_10m == null then "--"
                           else "\(dir16($r.current.wind_direction_10m)) " +
                                "\(($r.current.wind_speed_10m * 10 | round) / 10)m/s"
                           end),
                pop:      suffixed((($r.daily.precipitation_probability_max // [])[0]); "%")
            },
            sunLabel: "\(hhmm((($r.daily.sunrise // [])[0]))) / \(hhmm((($r.daily.sunset // [])[0])))",
            daily: [
                range(0; ([(($r.daily.time // []) | length), 7] | min)) as $i
                | (((($r.daily.time // [])[$i]) // "") | split("-")) as $p
                | {
                    day: (if ($p | length) >= 3
                          then "\($p[1] | ltrimstr("0"))/\($p[2] | ltrimstr("0"))"
                          else "--" end),
                    dow:  ($wd[(($dow0 + $i) % 7)] // ""),
                    icon: look((($r.daily.weather_code // [])[$i])).icon,
                    max:  temp((($r.daily.temperature_2m_max // [])[$i])),
                    min:  temp((($r.daily.temperature_2m_min // [])[$i])),
                    pop:  (((($r.daily.precipitation_probability_max // [])[$i]) // "--") | tostring)
                }
            ]
          }' "$work/openmeteo"
fi

# --------------------------------------------------------- 2. 気象警報・注意報
readonly JMA_WARNINGS='{
    "02":"暴風雪警報","03":"大雨警報","04":"洪水警報","05":"暴風警報","06":"大雪警報",
    "07":"波浪警報","08":"高潮警報",
    "10":"大雨注意報","12":"大雪注意報","13":"風雪注意報","14":"雷注意報","15":"強風注意報",
    "16":"波浪注意報","17":"融雪注意報","18":"洪水注意報","19":"高潮注意報","20":"濃霧注意報",
    "21":"乾燥注意報","22":"なだれ注意報","23":"低温注意報","24":"霜注意報","25":"着氷注意報",
    "26":"着雪注意報","27":"その他の警報等",
    "32":"暴風雪特別警報","33":"大雨特別警報","35":"暴風特別警報","36":"大雪特別警報",
    "37":"波浪特別警報","38":"高潮特別警報"
}'

if get warning "https://www.jma.go.jp/bosai/warning/data/warning/${DASHBOARD_JMA_AREA}.json"; then
    add warnings \
        --argjson names "$JMA_WARNINGS" \
        --arg area "$DASHBOARD_JMA_WARNING_AREA" \
        '{
            at: (now | floor),
            items: ([
                (.areaTypes // [])[] | (.areas // [])[]
                | select($area == "" or ((.code // "") | tostring) == $area)
                | (.warnings // [])[]
                | select(((.status // "") | tostring) as $s | ($s != "解除" and $s != "なし"))
                | ((.code // "00") | tostring) as $c
                | select($c != "00")
                | ($names[$c] // "警報等(\($c))")
            ] | unique)
         }
         | .active = ((.items | length) > 0)
         | .label = (if .active
                     then "\uf071 " + (.items | join(" / "))
                     else "発表中の警報注意報はありません" end)' "$work/warning"
fi

# ------------------------------------------------------------------- 3. 地震
if get quake "https://www.jma.go.jp/bosai/quake/data/list.json"; then
    add quake \
        '{
            at: (now | floor),
            items: [
                .[0:2][]
                | {
                    at: ((((.at // .rdt) // "") | tostring)
                         | sub("^[0-9]{4}-"; "") | sub("-"; "/") | sub("T"; " ")
                         | sub("\\+09:00$"; "") | sub(":[0-9]{2}$"; "")),
                    place: (((.anm // "") | tostring) as $a | if $a == "" then "—" else $a end),
                    mag:   (((.mag // "") | tostring) as $m | if $m == "" then "" else "M\($m)" end),
                    maxi:  (((.maxi // "") | tostring) as $i | if $i == "" then "" else "震度\($i)" end)
                  }
            ]
         }' "$work/quake"
fi

# ------------------------------------------------------------------- 4. 祝日
if get holidays "https://holidays-jp.github.io/api/v1/date.json"; then
    add holiday --arg today "$today" \
        '
        def described($key; $name):
            (($key | split("-")) as $p
             | "\($p[1] | ltrimstr("0"))/\($p[2] | ltrimstr("0")) \($name)");
        . as $h
        | ($h | to_entries | map(select(.key > $today)) | sort_by(.key) | first) as $n
        | {
            at: (now | floor),
            today: (($h[$today] // "") | tostring),
            next: (if $n == null then "--"
                   else
                     (try (((($n.key | strptime("%Y-%m-%d") | mktime)
                             - ($today | strptime("%Y-%m-%d") | mktime)) / 86400) | round)
                      catch null) as $days
                     | described($n.key; $n.value)
                       + (if $days == null then "" else "（あと\($days)日）" end)
                   end)
          }
        | .active = (.today != "")
        | .label = (if .active then "本日は\(.today)" else "次の祝日 \(.next)" end)' "$work/holidays"
fi

# ------------------------------------------------------------------- 5. 為替
if get fx "https://open.er-api.com/v6/latest/USD"; then
    add fx \
        '{
            at: (now | floor),
            usdjpy: (if .rates.JPY == null then "--"
                     else ((.rates.JPY * 100 | round) / 100 | tostring) end)
         }
         | .label = "\(.usdjpy) 円"' "$work/fx"
fi

# ------------------------------------------------------------- 6. NHK ニュース
# RSS は XML なので jq では扱えず、標準ライブラリだけで済む python に任せる
parse_rss() {
    python3 - "$1" <<'PY'
import json
import sys
import xml.etree.ElementTree as ET

# RSS 2.0 / RDF どちらでも拾えるよう名前空間はワイルドカードで無視する
# （{*} ワイルドカードは iterfind/findall のみ対応。iter() では効かない）
root = ET.parse(sys.argv[1]).getroot()
items = []
for item in root.iterfind(".//{*}item"):
    title = " ".join((item.findtext("{*}title") or "").split())
    if title:
        items.append({"title": title})
    if len(items) >= 5:
        break
if not items:
    sys.exit(1)
json.dump(items, sys.stdout, ensure_ascii=False)
PY
}

if get news "https://www.nhk.or.jp/rss/news/cat0.xml"; then
    if parse_rss "$work/news" >"$work/news.json"; then
        add news '{at: (now | floor), items: .}' "$work/news.json"
    else
        warn "parse failed: news"
    fi
fi

# ------------------------------------------------------- 前回値とマージして出力
# 全ソースが死んだ回は何も書かない。meta.fetchedAt を更新してしまうと
# eww 側の「データが古い」判定が永久に発火しなくなる
section_count="$(jq -r 'keys | length' "$sections")"
if [ "${section_count:-0}" -eq 0 ]; then
    warn "all sources failed; previous data kept"
    exit 1
fi

mkdir -p -- "$(dirname -- "$DASHBOARD_DATA_FILE")" || exit 1

prev='{}'
if [ -f "$DASHBOARD_DATA_FILE" ]; then
    prev="$(jq -c '.' "$DASHBOARD_DATA_FILE" 2>/dev/null)" || prev='{}'
    [ -n "$prev" ] || prev='{}'
fi

# jq の * はオブジェクトのみ再帰マージし配列は丸ごと置換するので、
# daily や items が古い要素と混ざることはない。
# 一時ファイルは同一ディレクトリ（= 同一 FS）に作って rename する。
# これで eww が書きかけの JSON を読むことはない
# 表示用の更新時刻ラベルもここで作る。eww 側で時刻整形をしないための措置
tmp="$DASHBOARD_DATA_FILE.tmp.$$"
if jq -nc --argjson prev "$prev" --slurpfile new "$sections" \
    --arg fetchedAtLabel "$(date '+%m/%d %H:%M')" \
    '($prev * $new[0])
     | .meta = {
           fetchedAt: (now | floor),
           fetchedAtLabel: $fetchedAtLabel,
           sections: ($new[0] | keys)
       }' >"$tmp"; then
    mv -f "$tmp" "$DASHBOARD_DATA_FILE"
else
    rm -f "$tmp"
    warn "merge failed; previous data kept"
    exit 1
fi
