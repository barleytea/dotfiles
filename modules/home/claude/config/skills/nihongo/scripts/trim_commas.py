"""要らない読点を外す。

使い方:
    python3 trim_commas.py 書いた文.md 出力.md

外すのは、次のどちらかに当たる読点だけ。どちらも、無くても読み違えない形に限っている。
- 短い文（36字以下）で、文頭の短い語句（9字以下の「〜は」「〜で」「〜から」「〜までに」など）の後にある、その文ただ1つの読点
- 「を」の直後の読点（資料を、明日送ります）

外さないもの：定型の前置き（お手数ですが、）、文頭の接続詞（ただ、）、「Aは〜、Bは〜」の並び、
「無料で、広告も」のような2つの文のつなぎ、コードブロック・インラインコード・URLの中と、その直前の読点。
スピーチや読み上げの原稿は、読点が息継ぎの印になるので使わない。
外した読点は、標準出力に1行ずつ出す。
"""
import re
import sys

CONJ = ("ただ", "また", "なお", "まず", "そのため", "しかし", "さらに", "つまり", "一方", "そして", "でも", "それで",
        "ちなみに", "なので", "だから", "ですが", "そこで", "特に", "実は", "正直", "例えば", "たとえば")
FIXED = ("お手数ですが", "恐れ入りますが", "ご不便をおかけしますが", "申し訳ありませんが", "申し訳ございませんが",
         "ご多忙のところ恐れ入りますが", "本日はお忙しい中", "お忙しいところ", "誠に勝手ながら")
HEAD = re.compile(r"(は|では|には|とは|で|から|まで|までに|に|も)$")
# 外さない形（2026-11-18、作者の目隠し判定20問をもとに決めた）
ORDER = re.compile(r"(\d|[一二三四五六七八九十])+つ目(は|に)$|^(まず|次に|最後に)")   # 1つ目は、 の並び
CLAUSE_BEFORE = re.compile(r"(る|た|い|ない)(まで|まで|までは|うちは|ときは|時は|前は|あとは|後は)$")  # 始めるまでは、
CLAUSE_AFTER = re.compile(r"(てから|でから|たら|だら|れば|ので|ながら|つつ)[^、。]{2,}")  # 後ろに〜してから…が続く
KEEP_DE = re.compile(r"(無料|有料|簡単|可能|不要|必要|便利|安全|丁寧|元気|静か)で$")


def trim_sentence(s):
    """1文から外せる読点を外す。外した後の文と、外した理由の一覧を返す。"""
    body = s
    marks = [m.start() for m in re.finditer("、", body)]
    drop = []
    for i in marks:
        before = body[:i]
        after = body[i + 1:]
        if after.lstrip().startswith(MARK_HEAD):
            continue  # コードやURLの直前の読点は、日本語との境目の印なので残す
        if before.endswith("を"):
            drop.append((i, "「を」の後"))
            continue
        b = before.strip()
        if any(b.endswith(f) for f in FIXED) or any(b.endswith(c) for c in CONJ):
            continue
        seg = re.split(r"[、。「」（）()]", before)[-1]
        parallel = re.search(r"^[^、。]{1,12}(は|も)", after) and re.search(r"(は|も)", before[:-1] or "x")
        text_len = len(body.strip())
        if (len(marks) == 1 and not parallel and len(seg.strip()) <= 9 and text_len <= 36
                and HEAD.search(before) and not KEEP_DE.search(before)
                and not ORDER.search(before) and not CLAUSE_BEFORE.search(before) and not CLAUSE_AFTER.search(after)):
            drop.append((i, "短い文の頭の語句の後"))
    for i, _ in sorted(drop, reverse=True):
        body = body[:i] + body[i + 1:]
    return body, [r for _, r in drop]


# インラインコードとURLは、同じ長さの印に置き換えてから文に切る。
# 印で置き換えると、コードの前後で文が切れず、中の「。」「!」で文を切ることもない。
INLINE = re.compile(r"`[^`\n]*`|https?://[^\s、。）)」]+")
MARK_HEAD, MARK_BODY = "\ue000", "\ue001"
MARK = re.compile(MARK_HEAD + MARK_BODY + "*")


FENCE_OPEN = re.compile(r"^[ \t]{0,3}(`{3,}|~{3,})(.*)$")


def split_fences(text):
    """コードブロック（``` と ~~~ の囲み）とそれ以外に分ける。(コードか, 文字列) の並びを返す。
    閉じる囲みは、開いた時と同じ記号を同じ数以上並べた行。閉じていなければ最後までコード。"""
    parts, buf, fence = [], [], None
    for line in text.splitlines(keepends=True):
        body = line.rstrip("\r\n")
        if fence is None:
            m = FENCE_OPEN.match(body)
            # ``` の後ろの説明にバッククォートがあるのは、囲みではなくインラインのコード
            if m and not (m.group(1)[0] == "`" and "`" in m.group(2)):
                if buf:
                    parts.append((False, "".join(buf)))
                buf, fence = [line], m.group(1)
                continue
            buf.append(line)
        else:
            buf.append(line)
            if re.fullmatch(r"[ \t]{0,3}" + re.escape(fence[0]) + "{" + str(len(fence)) + r",}[ \t]*", body):
                parts.append((True, "".join(buf)))
                buf, fence = [], None
    if buf:
        parts.append((fence is not None, "".join(buf)))
    return parts


def trim(text):
    out, log = [], []
    for is_code, part in split_fences(text):
        if is_code:
            out.append(part)
            continue
        lines = part.split("\n")
        new_lines = []
        for line in lines:
            kept = INLINE.findall(line)
            masked = INLINE.sub(lambda m: MARK_HEAD + MARK_BODY * (len(m.group()) - 1), line)
            pieces = re.split(r"(?<=[。！？!?])", masked)
            new_pieces = []
            for p in pieces:
                head = re.match(r"^(\s*(?:#+|[-*・]|\d+[.)]|>)?\s*)", p).group(1)
                body, why = trim_sentence(p[len(head):])
                if why:
                    shown = MARK.sub("…", p.strip())
                    log.append(f"外した（{'・'.join(why)}）：{shown[:50]}")
                new_pieces.append(head + body)
            restored = iter(kept)
            new_lines.append(MARK.sub(lambda m: next(restored), "".join(new_pieces)))
        out.append("\n".join(new_lines))
    return "".join(out), log


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(2)
    text = open(sys.argv[1], encoding="utf-8").read()
    new, log = trim(text)
    with open(sys.argv[2], "w", encoding="utf-8") as f:
        f.write(new)
    print("\n".join(log) if log else "外した読点はありません。")


if __name__ == "__main__":
    main()
