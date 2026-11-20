#!/usr/bin/env python3
"""原文と直した文を比べ、意味が変わったかもしれない所を一覧にする。

使い方:
    python3 check_meaning.py 原文.md 直した文.md

標準ライブラリだけで動く。出すのは「見直す候補」で、意味が変わったと決めつけるものではない。
"""
import re
import sys
import unicodedata
from collections import Counter

# 確かさ・強さの言葉。消えた・増えたを数える
MODALITY = {
    "予定": ["予定"],
    "見込み": ["見込み", "見込ん"],
    "可能性": ["可能性"],
    "かもしれない": ["かもしれ", "かも知れ"],
    "場合がある": ["場合があ", "場合がございま", "ことがあり", "ことがござ"],
    "推定": ["と見られ", "とみられ", "と考えられ", "と推定", "と思われ", "と推測"],
    "たぶん": ["たぶん", "多分", "おそらく", "恐らく"],
    "と思う": ["と思い", "と思う", "と思っ", "と考えてい", "と考えます"],
    "ような気がする": ["ような気が", "ように感じ", "気がし"],
    "つもり": ["つもり"],
    "したい": ["したい", "たいと考え", "たいです", "たいと思"],
    "必須": ["必須", "必ず", "しなければな", "なければなりませ"],
    "必要": ["必要があ", "必要がござ", "必要です", "必要となり"],
    "推奨": ["推奨", "望まし", "おすすめ", "お勧め"],
    "任意": ["任意", "必須ではあ", "必須ではな"],
    "不要": ["不要", "必要ありませ", "必要はありませ", "なくて大丈夫", "なくても大丈夫", "なくても問題"],
    "お願い": ["お願い", "ください", "いただけますでしょうか", "いただけますと幸い", "いただけますか"],
    "可能": ["できます", "可能です", "可能となって", "ことができ"],
    "未定": ["未定", "決まっていな", "決まり次第", "まだ分かって", "まだわかって", "調査中", "確認中", "検討中"],
}

# 程度や約束の言葉。消えたら出す
DEGREE = ["大幅", "抜本", "全力", "心より", "心から", "深く", "根本", "必ず", "最大", "最小", "すべて", "全て",
          "一切", "絶対", "のみ", "だけ", "限り", "以上", "以下", "未満", "超え", "まで", "約", "およそ", "頃"]

NEG = re.compile(r"(?:ない|なく|ません|ず[、。に]|ぬ|なし|無し|ではな)")
# 未対応の英字単位が続く場合も、数字は全桁読む。英字の境界は単位にだけ当てる。
# 負の数（-5℃、▲3%）は符号まで1つの値にする。数字の後ろのハイフン（電話番号、10-20）は符号にしない。
NUM = re.compile(
    r"(?:(?<![0-9０-９A-Za-z])[-−▲△])?[0-9０-９]+(?:[.,][0-9]+)?\s*"
    r"(?:(?:%|％|件|回|分|秒|時間|時|日|週|ヶ月|か月|カ月|月|年|円|万|億|"
    r"人|名|個|行|文字|字|歳|才|枚|台|本|杯|冊|部|点|倍|割|階|番|位|°C|度|℃|"
    r"TB|MB|GB|KB|ms|px|mg|kg|km|cm|mm|ml|mL|g|m|L|t)(?![A-Za-z]))?"
)
# 発信者・組織の名前と、公式らしさを出す言葉。原文に無いのに増えたら出す（なりすましや、書いていない権威の足し）。
ORG_SUFFIX = (r"銀行|信用金庫|信金|証券|生命|保険|株式会社|有限会社|市役所|区役所|町役場|村役場|役所|役場|税務署|警察署|警察|"
              r"年金機構|運営事務局|事務局|サポートセンター|カスタマーセンター|カスタマーサポート|サポート窓口|"
              r"省(?![一-龥々])|庁(?![一-龥々])")
ORG = re.compile(r"(?:株式会社|\(株\))[一-龥々ァ-ヴーA-Za-z0-9]{1,10}|[一-龥々ァ-ヴーA-Za-z0-9]{1,10}?(?:" + ORG_SUFFIX + r")")
ORG_GENERIC = {"各", "他", "当", "同", "全", "本", "都市", "地方", "主要", "大手", "一部", "ネット", "外資", "最寄り"}
AUTHORITY = ["公式", "正規", "認証済", "【重要】", "【緊急】", "重要なお知らせ", "緊急", "法的措置", "凍結", "利用停止", "アカウント停止"]


def orgs(text):
    out = Counter()
    for m in ORG.finditer(text):
        w = m.group(0)
        head = re.sub("(?:" + ORG_SUFFIX + ")$", "", w)
        if head and head not in ORG_GENERIC:
            out[w] += 1
    return out


WEEK = re.compile(r"[月火水木金土日]曜日?|[（(][月火水木金土日][）)]")
CODE = re.compile(r"`[^`\n]+`")
URL = re.compile(r"https?://\S+")
SENT = re.compile(r"[^。！？!?\n]+[。！？!?]?")
CONTENT = re.compile(r"[一-龥々]{2,}|[ァ-ヴー]{3,}|[A-Za-z][A-Za-z0-9_\-./]{2,}")


def norm(s):
    s = unicodedata.normalize("NFKC", s)
    s = s.replace("```", "\n")
    s = re.sub(r"(?<![0-9])([0-9]{1,2}):00(?![0-9])", r"\1時", s)
    s = re.sub(r"(?<![0-9])([0-9]{1,2}):([0-9]{2})(?![0-9])", r"\1時\2分", s)
    # 午前・午後の時刻は24時間表記にそろえる（午後3時 と 15時 を同じものとして扱う）
    s = re.sub(r"午後([0-9]{1,2})時", lambda m: f"{int(m.group(1)) % 12 + 12}時", s)
    s = re.sub(r"午前([0-9]{1,2})時", lambda m: f"{int(m.group(1)) % 12}時", s)
    return s


# 程度の言葉のうち、別の語の一部として出てくるものを外す（いただけ、お疲れさまで、など）
DEGREE_SKIP = {"だけ": ["いただけ", "頂け"], "まで": ["さまで", "様で"], "約": ["予約", "契約", "要約", "節約", "規約", "約束"],
               "限り": [], "以上": ["以上です", "以上となります", "以上、"], "以下": ["以下のとおり", "以下の通り", "以下をご", "以下に"]}


def count_degree(text, w):
    n = text.count(w)
    for skip in DEGREE_SKIP.get(w, []):
        if w in skip:
            n -= text.count(skip)
    return n


def count_markers(text, table):
    return {k: sum(text.count(w) for w in ws) for k, ws in table.items()}


# 組み合わせの照合。「Aは〜」の節ごとに、Aと組になっている人名・数値・否定が、
# 直した文で別の組に移っていないかを見る（担当や時刻の入れ替わり、否定の入れ替わり）。
CLAUSE = re.compile(r"[^、。！？!?\n]+")
TOPIC_ONE = re.compile(r"\s*(?:(?:また|なお|ただし|そして)、?)?([^\s、。はが]{1,12})(?:は|が)")
NAME = re.compile(r"[一-龥々ァ-ヴー]{1,6}(?:さん|様|氏|くん|君|先生|部長|課長)")
NOT_TOPIC = {"で", "に", "と", "も", "それ", "これ", "あれ", "ここ", "今"}


def topic_of(c):
    """節の頭の「Aは」「Bが」を順に拾い、話題の鍵にする（本番では旧版は → 本番で/旧版）。
    人名や数字の入った語は、話題ではなく組になる値なので鍵に入れない。"""
    parts, pos = [], 0
    while len(parts) < 3:
        m = TOPIC_ONE.match(c, pos)
        if not m:
            break
        w = m.group(1)
        pos = m.end()
        if w in NOT_TOPIC or NAME.fullmatch(w) or re.search(r"[0-9０-９]", w):
            break
        parts.append(w)
    return "/".join(parts), (parts[-1] if parts else "")


def clauses(text):
    out = []
    for c in CLAUSE.findall(text):
        key, shown = topic_of(c)
        if not key:
            continue
        out.append(dict(topic=key, shown=shown, text=c, nums=[x.strip() for x in NUM.findall(c)],
                        names=NAME.findall(c), neg=bool(NEG.search(c))))
    return out


def check_pairs(a, b):
    out = []
    ca, cb = clauses(a), clauses(b)
    by_topic = {}
    for c in cb:
        by_topic.setdefault(c["topic"], []).append(c)
    all_b = b
    for c in ca:
        if c["topic"] not in by_topic:
            continue
        cands = by_topic[c["topic"]]
        # 人名・数値：原文でこの話題と組になっていた物が、直した文にあるのに、同じ話題の節には無い
        for kind, items in (("人名", c["names"]), ("数値・日時", c["nums"])):
            for x in items:
                if x in all_b and not any(x in d[{"人名": "names", "数値・日時": "nums"}[kind]] for d in cands):
                    now = "、".join(sorted({y for d in cands for y in d[{"人名": "names", "数値・日時": "nums"}[kind]]})) or "なし"
                    out.append(f"[組み合わせ] 「{c['shown']}」と組の{kind}が変わった（{x} → {now}）")
        # 否定：同じ話題の節で、否定の有無が変わった
        if all(d["neg"] != c["neg"] for d in cands):
            was, now = ("否定", "肯定") if c["neg"] else ("肯定", "否定")
            out.append(f"[組み合わせ] 「{c['shown']}」の文が{was}から{now}に変わった")
    return out


def check(src, dst):
    a, b = norm(src), norm(dst)
    out = []

    for name, pat in (("数値・日時", NUM), ("曜日", WEEK), ("コード", CODE), ("URL", URL)):
        ca, cb = Counter(m.strip() for m in pat.findall(a)), Counter(m.strip() for m in pat.findall(b))
        lost = [x for x in ca if x and cb[x] < ca[x]]
        added = [x for x in cb if x and ca[x] < cb[x]]
        if lost:
            out.append(f"[{name}] 原文にあって直した文で減ったもの: {', '.join(lost)}")
        if added:
            out.append(f"[{name}] 直した文で増えたもの: {', '.join(added)}")

    oa, ob = orgs(a), orgs(b)
    added_org = [x for x in ob if ob[x] > oa[x] and not any(x in y or y in x for y in oa)]
    lost_org = [x for x in oa if oa[x] > ob[x] and not any(x in y or y in x for y in ob)]
    if added_org:
        out.append(f"[発信者・権威] 原文に無い発信者名・組織名が増えた: {', '.join(added_org)}")
    if lost_org:
        out.append(f"[発信者・権威] 原文の発信者名・組織名が消えた: {', '.join(lost_org)}")
    added_auth = [w for w in AUTHORITY if b.count(w) > a.count(w)]
    if added_auth:
        out.append(f"[発信者・権威] 原文に無い公式らしさの言葉が増えた: {', '.join(added_auth)}")

    ma, mb = count_markers(a, MODALITY), count_markers(b, MODALITY)
    for k in MODALITY:
        if ma[k] > mb[k]:
            out.append(f"[確かさ・強さ] 「{k}」の言い方が減った（{ma[k]}→{mb[k]}）")
        elif mb[k] > ma[k] and k in ("と思う", "たぶん", "かもしれない", "推定", "必須", "不要", "可能"):
            out.append(f"[確かさ・強さ] 「{k}」の言い方が増えた（{ma[k]}→{mb[k]}）")

    for w in DEGREE:
        ca, cb = count_degree(a, w), count_degree(b, w)
        if ca > cb:
            out.append(f"[程度・約束] 「{w}」が減った（{ca}→{cb}）")

    na, nb = len(NEG.findall(a)), len(NEG.findall(b))
    if na != nb:
        out.append(f"[否定] 否定の言い方の数が変わった（{na}→{nb}）")

    bwords = set(CONTENT.findall(b))
    for s in SENT.findall(a):
        words = set(CONTENT.findall(s))
        if len(words) >= 3:
            kept = len(words & bwords) / len(words)
            if kept < 0.5:
                out.append(f"[消えた中身] 中身の言葉が半分以上見当たらない文: {s.strip()[:60]}")
    out += check_pairs(a, b)
    return out


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(2)
    src = open(sys.argv[1], encoding="utf-8").read()
    dst = open(sys.argv[2], encoding="utf-8").read()
    items = check(src, dst)
    if not items:
        print("見直す候補はありません。")
        return
    print(f"見直す候補が{len(items)}件あります。直した文の該当箇所を原文と読み比べてください。")
    for x in items:
        print("- " + x)


if __name__ == "__main__":
    main()
