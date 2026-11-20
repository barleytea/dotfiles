#!/usr/bin/env python3
"""直した文のうち、意味が変わったかもしれない文だけを原文の文に戻す。

使い方:
    python3 revert_broken.py 原文.md 直した文.md 出力.md [--request 依頼.md]

--request には、ユーザーの依頼文を保存したファイルを渡す。変更する項目と操作を
確認できた編集（番号の伏字化、指定された日時への変更など）は、そのまま残す。

check_meaning.py と同じ基準で原文と直した文を比べ、候補が出た所について、
原文の該当する文と、直した文の中でいちばん近い文を探し、その文を原文の文に置き換える。
原文の文が直した文から丸ごと消えている時は、近い位置に原文の文を差し込む。
候補が無くなるか、それ以上減らなくなるまで繰り返す（最大6回）。

標準ライブラリだけで動く。戻した文は一覧で出す。
"""
import difflib
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from check_meaning import check, norm, MODALITY, NEG, NUM, CONTENT  # noqa: E402

SENT = re.compile(r"[^。！？!?\n]+[。！？!?]?")


def spans(text):
    return [(m.start(), m.end(), m.group()) for m in SENT.finditer(text) if m.group().strip()]


def sim(a, b):
    return difflib.SequenceMatcher(None, norm(a), norm(b)).ratio()


def is_heading(t):
    return bool(re.match(r"\s*#+\s", t)) or (len(t.strip()) < 25 and not re.search(r"[。！？!?]$", t.strip()) and t.strip().startswith("**"))


def best(sent, cands):
    """cands の中で sent にいちばん近いものの番号と近さ。見出しの行は相手にしない。"""
    scores = [0.0 if is_heading(c[2]) else sim(sent, c[2]) for c in cands]
    if not scores:
        return None, 0.0
    i = max(range(len(scores)), key=scores.__getitem__)
    return i, scores[i]


def owner_of(S, D):
    """原文の各文が、直した文のどの文に当たるか。近さが同じなら、同じ位置の文を選ぶ
    （担当や時刻を入れ替えた2文を、片方の文にまとめて戻さないため）。"""
    out = []
    for k, s in enumerate(S):
        best_i, best_sc = None, -1.0
        for i, d in enumerate(D):
            if is_heading(d[2]):
                continue
            pos = 1 - abs(k / max(len(S) - 1, 1) - i / max(len(D) - 1, 1))
            sc = sim(s[2], d[2]) + 0.05 * pos
            if sc > best_sc:
                best_i, best_sc = i, sc
        out.append(best_i)
    return out


def words_of(item):
    """候補の行から、原文の文を探すための手がかりの語を取り出す。"""
    m = re.match(r"\[(数値・日時|曜日|コード|URL)\] 原文にあって直した文で減ったもの: (.*)", item)
    if m:
        return [x.strip() for x in m.group(2).split(", ") if x.strip()], "lost"
    m = re.match(r"\[確かさ・強さ\] 「(.+?)」の言い方が(減った|増えた)", item)
    if m:
        return MODALITY[m.group(1)], ("lost" if m.group(2) == "減った" else "added")
    m = re.match(r"\[程度・約束\] 「(.+?)」が減った", item)
    if m:
        return [m.group(1)], "lost"
    m = re.match(r"\[(数値・日時|曜日|コード|URL)\] 直した文で増えたもの: (.*)", item)
    if m:
        return [x.strip() for x in m.group(2).split(", ") if x.strip()], "added"
    if item.startswith("[否定]"):
        return None, "neg"
    m = re.match(r"\[組み合わせ\] 「(.+?)」", item)
    if m:
        return [m.group(1)], "pair"
    m = re.match(r"\[消えた中身\] 中身の言葉が半分以上見当たらない文: (.*)", item)
    if m:
        return m.group(1), "gone"
    return None, None


PREFIX = re.compile(r"^\s*(?:\*\*[^*\n]+\*\*[:：]?\s*|[-*・]\s+|#+\s+|\d+[.)]\s+)")


def fit(orig, place):
    """原文の文を戻す時、行頭の見出し・箇条書きの記号は、置き換える先に合わせる。"""
    body = PREFIX.sub("", orig, count=1).strip()
    m = PREFIX.match(place)
    return (m.group(0) if m else "") + body


def has(s, ws):
    s = norm(s)
    return any(w in s for w in ws)


# 依頼文の読み方。値が依頼に出てくるだけでは「変えてよい」にしない。
# その値が出てくる依頼の文に、変える指示があり、残す・変えない指示が無い時だけ、頼まれた直しとみなす。
KEEP = re.compile(r"維持|そのまま|元のまま|変更しない|変えない|変えず|変更せず|残して|残す|保持|しないで|せずに|(?:変える|変更する|直す|修正する)必要(?:は|が)(?:ない|ありません)")
CHANGE = re.compile(r"変更|変え|置き換|置換|書き換|直して|伏せ|非公開|マスク|隠|にして|にする|に修正|削除|消して|消す|外して|除いて|取り除")
MASK = re.compile(r"[［\[【〔(（][^］\]】〕)）]{1,12}[］\]】〕)）]|[●○＊*×Xx]{2,}")
MASK_WORDS = re.compile(r"伏せ|伏字|非公開|マスク|隠|黒塗り|置き換")
MASK_PLAIN = r"非公開|伏せ字|伏字|非表示|秘匿"   # 括弧なしで書かれた伏字
EMAIL = r"[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+"
PHONE = r"\+?[0-9０-９]{2,4}[-－‐][0-9０-９]{2,4}[-－‐][0-9０-９]{3,4}|[0-9０-９]{10,11}"
VALUE = re.compile(EMAIL + "|" + PHONE)
PHONE_MASK = r"[0-9０-９*＊●×]{2,4}[-－‐][0-9０-９*＊●×]{2,4}[-－‐][0-9０-９*＊●×]{3,4}"
# 14:00 のようなコロンの時刻は、1つの値として扱う（14 と :00 に分けない）。
CLOCK = r"[0-9０-９]{1,2}[:：][0-9０-９]{2}(?![0-9０-９])"
TOKEN = re.compile("|".join([PHONE_MASK, MASK.pattern, MASK_PLAIN, EMAIL, PHONE, CLOCK, NUM.pattern, r"[\s\S]"]))
AFTER_VALUE = re.compile(r"^(?:まで|宛て|宛|へ|に)")
DELETE = re.compile(r"削除|消して|消す|外して|除いて|取り除")
REDACT = re.compile(r"伏せ|伏字|非公開|マスク|隠|黒塗り")


def req_clauses(request):
    return [s for s in re.split(r"[。！？!?\n、，,]", norm(request)) if s.strip()]


def allowed(w, request):
    """依頼の中で、値 w を変えるよう頼まれているか。分からない時は頼まれていない扱い。"""
    w = norm(w).strip()
    if not w or not request:
        return False
    hit = [s for s in req_clauses(request) if w in s]
    if not hit:
        return False
    return all(not KEEP.search(s) for s in hit) and any(CHANGE.search(s) for s in hit)


def is_mask(seg):
    seg = seg.strip()
    partial = re.fullmatch(PHONE_MASK, seg) and re.search(r"[*＊●×]{2,}", seg)
    return bool(seg) and bool(MASK.fullmatch(seg) or re.fullmatch(MASK_PLAIN, seg) or partial)


def label_of(before):
    """値の直前にある項目名（電話番号は〜 の「電話番号」）。無ければ空。"""
    before = re.split(r"[、。！？!?\n]", norm(before))[-1]
    m = re.match(r"(.+?)(?:は|が|:)", before)
    if m:
        return m.group(1).strip()
    words = CONTENT.findall(before[-12:])
    return words[-1] if words else ""


def matches_target(value, label, clause):
    """項目が指定されていれば、同じ値の別項目には許可を広げない。"""
    m = re.match(r"(.+?)(?:を|は|が)", clause.strip())
    target = re.sub(r"(?:だけ|のみ)$", "", m.group(1)) if m else ""
    # 「電話番号の市外局番以外」のような部分指定も、電話番号に対する操作。
    target = re.sub(r"^(電話番号|電話|番号)の.+以外$", r"\1", target)
    if target.endswith(value) and target != value:
        prefix = target[:-len(value)].strip()
        if prefix not in ("最大", "最小", "約", "およそ"):
            target = prefix
    bare_value = re.sub(r"^(?:最大|最小|約|およそ)", "", target)
    if target and not NUM.fullmatch(bare_value) and not VALUE.fullmatch(bare_value):
        if label and target in label:
            return True
        if label and target.startswith(label):
            suffix = target[len(label):].strip()
            if suffix == value or NUM.fullmatch(suffix) or VALUE.fullmatch(suffix):
                return True
        # 「本人の電話番号」などの限定を、単なる電話番号の指定に広げない。
        if target in ("電話番号", "電話", "番号", "TEL", "tel"):
            return bool(re.fullmatch(PHONE, value))
        if target in ("メール", "メールアドレス", "アドレス", "連絡先"):
            return bool(re.fullmatch(EMAIL, value))
        return False
    return value in clause or bool(label and label in clause)


def unit_of(value):
    """値の単位（13時 なら「時」、20名 なら「名」）。数字だけなら空。"""
    return re.sub(r"[-−▲△0-9.,\s]", "", norm(value))[:1]


def destination_in(value, clause):
    """変更先として書かれた値か（単に依頼に登場する値とは区別する）。"""
    return bool(re.search(re.escape(norm(value).strip()) + r'[」』”"\]]*\s*(?:に|へ)', clause))


def value_ok(value, before, request, operation=None, new=""):
    """原文の値 value を、依頼どおりに変える・伏せる・消してよいか。
    値そのものか、その項目名が、変える指示のある依頼の節に出てくる時だけ認める。
    同じ値か項目名が、残す指示のある節に出てくる時は認めない（定員は20名を維持、など）。"""
    if not request:
        return False
    v, label = norm(value).strip(), label_of(before)
    if not v:
        return False
    clauses = req_clauses(request)
    for c in clauses:
        if KEEP.search(c) and matches_target(v, label, c):
            return False
    for c in clauses:
        if not CHANGE.search(c) or KEEP.search(c):
            continue
        if not matches_target(v, label, c):
            continue
        deletion = bool(DELETE.search(c))
        masking = bool(REDACT.search(c) or any(is_mask(t) for t in TOKEN.findall(c)))
        replacement = any(
            t.strip() != v and destination_in(t, c)
            for t in TOKEN.findall(c) if NUM.fullmatch(t) or VALUE.fullmatch(t)
        )
        if operation == "delete" and deletion:
            return True
        if operation == "mask" and masking:
            return True
        if operation == "replace" and destination_in(new, c):
            return True
        if operation is None and (deletion or masking or replacement):
            return True
    # 「14:00に変更」のように項目名が無く、変更先の値だけが書かれた依頼。
    # 同じ単位の値（時刻なら時刻）を、書かれた値に変えた時だけ認める。
    if operation == "replace" and new.strip():
        for c in clauses:
            if not CHANGE.search(c) or KEEP.search(c) or re.match(r"(.+?)(?:を|は|が)", c.strip()):
                continue
            if destination_in(new, c) and unit_of(v) and unit_of(v) == unit_of(new):
                return True
    return False


def allowed_new(seg, request, old="", before=""):
    """直した文に入った語 seg が、依頼で頼まれた置き換え（伏字など）か。
    伏字は、伏せる元の値（old）が依頼で伏せてよい物の時だけ認める。"""
    seg = seg.strip()
    if not seg or not request:
        return False
    if is_mask(seg):
        if not (MASK_WORDS.search(norm(request)) or seg in norm(request)):
            return False
        return value_ok(old, before, request, "mask") if old.strip() else False
    if old.strip() and not value_ok(old, before, request, "replace", seg):
        return False
    return allowed(seg, request) if len(seg) >= 2 else False


def allowed_lost(w, src, request):
    """原文から減った値 w が、依頼で変える・伏せる・消すよう頼まれた物か。"""
    n = norm(src)
    found = []
    for m in TOKEN.finditer(n):
        if w in m.group() and (VALUE.fullmatch(m.group()) or NUM.fullmatch(m.group())):
            found.append(value_ok(m.group(), n[:m.start()], request))
    # 値のどれか一つが許可されただけでは、候補全体を消さない。
    return all(found) if found else allowed(w, request)


def tokens(text):
    return TOKEN.findall(text)


def keep_requested(orig, draft, request):
    """原文の文に戻す時も、依頼で頼まれた置き換え（伏字など）は、直した文のまま残す。
    比べるのは文字ではなく値の単位（15時、03-0000-0000）なので、15時→16時 も1つの変更として扱う。"""
    if not request:
        return orig
    A, B = tokens(orig), tokens(draft)
    sm = difflib.SequenceMatcher(None, A, B, autojunk=False)
    out = []
    for op, a1, a2, b1, b2 in sm.get_opcodes():
        old, new = "".join(A[a1:a2]), "".join(B[b1:b2])
        before = "".join(A[:a1])
        if op in ("replace", "insert") and allowed_new(new, request, old, before):
            out.append(new)
        elif op == "insert":
            continue
        elif op == "delete" and value_ok(old, before, request, "delete"):
            continue
        else:
            out.append(old)
    return "".join(out)


def strip_deleted(s, request):
    """明示的な削除対象だけを抜く。削除に伴う助詞の調整を照合するために使う。"""
    out, pos = [], 0
    for m in TOKEN.finditer(s):
        tok = m.group()
        drop = (NUM.fullmatch(tok) or VALUE.fullmatch(tok)) and value_ok(tok, s[:m.start()], request, "delete")
        if drop:
            out.append(s[pos:m.start()])
            pos = m.end()
            a = AFTER_VALUE.match(s[pos:])
            if a:
                pos += a.end()
    out.append(s[pos:])
    return "".join(out)


def requested_only(orig, draft, request):
    """直した文 draft と原文の文 orig の違いが、依頼で頼まれた直しだけか。"""
    if not request or orig.strip() == draft.strip():
        return False
    if keep_requested(orig, draft, request) == draft:
        return True
    a, b = strip_deleted(orig, request), draft
    if a == orig:
        return False
    return not check(a, b) and sim(a, b) >= 0.6


def has_requested_value(sent, request):
    """文の中に、依頼で消す・伏せるよう頼まれた値（メールアドレスや電話番号）があるか。"""
    if not request:
        return False
    n = norm(sent)
    return any(value_ok(m.group(), n[max(0, m.start() - 12):m.start()], request) for m in VALUE.finditer(n))


def requested_mask_exists(orig, drafts, request):
    """伏字以外が原文と一致する文（依頼で頼まれた直しだけの文）が、下書きに残っているか。"""
    if not request:
        return False
    return any(requested_only(orig.strip(), d.strip(), request) for _, _, d in drafts)


def one_pass(src, dst, request="", items=None):
    """候補を1つずつ見て、戻す文を決めて置き換える。戻した記録も返す。"""
    if items is None:
        items = remaining(src, dst, request)
    if not items:
        return dst, []
    S, D = spans(src), spans(dst)
    unchanged_texts = {d[2] for d in D if not is_heading(d[2])}
    owner = owner_of(S, D)  # 原文の各文が、直した文のどの文に当たるか
    # 依頼で頼まれた直しだけの文は、戻さない（電話番号を消した文、伏せた文など）
    protected = set()
    for i, d in enumerate(D):
        ks = [k for k, o in enumerate(owner) if o == i]
        if len(ks) == 1 and requested_only(S[ks[0]][2], d[2], request):
            protected.add(i)
    replace = {}   # 直した文の番号 → 置き換える原文の文
    drop = set()   # 原文の1文を分けた片割れで、戻した文に含まれるので消す直した文
    insert = []    # (直した文の番号の後ろ, 原文の文)
    used = set()   # 戻すのに使った原文の文

    def put(i, sent):
        if i in replace or i in protected or sent in used:
            return
        # 戻した後も、消す・伏せるよう頼まれた値（メールアドレスや電話番号）が残るなら、自動では戻さない。
        # 1文を2文に分けた時など、伏せた所を引き継げない時に起きる。残っている候補として見せる（Issue #23）。
        if has_requested_value(keep_requested(sent, D[i][2], request), request):
            return
        # 原文の2文以上を1文にまとめた文なら、まとめた元の文を全部戻す（片方だけ戻して中身を落とさない）
        group = [s[2] for k, s in enumerate(S) if owner[k] == i and s[2] not in used]
        if sent not in group:
            group = [sent]
        replace[i] = "".join(group)
        used.update(group)
        # 原文の1文を直した文で2文に分けていたら、隣の片割れも消す（片方だけ戻して中身を二重にしない）
        if len(group) == 1:
            for j in (i - 1, i + 1):
                if 0 <= j < len(D) and j not in replace and j not in protected and split_part(j, sent):
                    drop.add(j)

    def split_part(j, sent):
        """直した文 j が、原文の文 sent を分けた片割れか。"""
        t = D[j][2]
        if t in unchanged_texts and any(t.strip() == x[2].strip() for x in S):
            return False
        k, _ = best(t, S)
        if k is None or S[k][2] != sent or any(o == j for o in owner):
            return False
        # 短い片割れは長い原文の文との近さが低く出るので、片割れの何割が原文の文に含まれるかで見る
        a, b = norm(t), norm(sent)
        hit = sum(m.size for m in difflib.SequenceMatcher(None, a, b).get_matching_blocks())
        return hit / max(len(a), 1) >= 0.5

    def add(p, sent):
        if sent not in used:
            insert.append((p, sent))
            used.add(sent)
    for item in items:
        ws, kind = words_of(item)
        if kind == "pair":
            # 話題の語を含む文どうしで、いちばん近い組を戻す（似た形の別の文と取り違えない）
            idx = [k for k, d in enumerate(D) if ws[0] in d[2]]
            for s in S:
                if ws[0] in s[2] and idx:
                    j, sc = best(s[2], [D[k] for k in idx])
                    if j is not None and sc >= 0.45:
                        put(idx[j], s[2])
            continue
        if kind in ("lost", "neg"):
            for s in S:
                if s[2] in unchanged_texts:
                    continue
                if kind == "lost" and not has(s[2], ws):
                    continue
                i, sc = best(s[2], D)
                if i is None or sc < 0.45:
                    continue
                if kind == "lost" and has(D[i][2], ws):
                    continue
                if kind == "neg" and len(NEG.findall(norm(s[2]))) == len(NEG.findall(norm(D[i][2]))):
                    continue
                put(i, s[2])
        elif kind == "added":
            for i, d in enumerate(D):
                if not has(d[2], ws):
                    continue
                j, sc = best(d[2], S)
                if j is not None and not has(S[j][2], ws):
                    put(i, S[j][2])
        elif kind == "gone":
            s = next((x for x in S if x[2].strip().startswith(ws[:20])), None)
            if s is None:
                continue
            # 伏字化して残っている文を、消えた文として原文のまま差し込まない。
            if requested_mask_exists(s[2], D, request):
                continue
            # 消す・伏せるよう頼まれた値を含む文は、原文のまま差し込まない（行ごと消した文、言い換えて伏せた文）。
            # 戻さずに、残っている候補として見せる。
            if has_requested_value(s[2], request):
                continue
            k = S.index(s)
            if owner[k] in protected:
                continue
            prev = best(S[k - 1][2], D)[0] if k > 0 else None
            add(prev, s[2])
    drop -= set(replace)
    if not replace and not insert:
        return dst, []
    log = []
    out, last = [], 0
    ins_after = {}
    for p, s in insert:
        ins_after.setdefault(p, []).append(s)
    if None in ins_after:
        for s in ins_after[None]:
            if s.strip() not in dst:
                out.append(PREFIX.sub("", s, count=1).strip() + "\n\n")
                log.append(f"差し込んだ：{s.strip()[:50]}")
    for i, (a, b, t) in enumerate(D):
        out.append(dst[last:a])
        if i in drop:
            log.append(f"まとめて戻した片割れを消した：{t.strip()[:30]}")
            last = b
            continue
        new = fit(keep_requested(replace[i], t, request), t) if i in replace else t
        if i in replace and new.strip() != t.strip():
            out.append(new)
            log.append(f"戻した：{t.strip()[:30]} → {new.strip()[:30]}")
        else:
            out.append(t)
        for s in ins_after.get(i, []):
            if s.strip() not in dst:
                out.append(PREFIX.sub("", s, count=1).strip())
                log.append(f"差し込んだ：{s.strip()[:50]}")
        last = b
    out.append(dst[last:])
    return "".join(out), log


def requested_reference(src, dst, request):
    """対応が一対一の文だけ、許可した編集を反映した照合用の原文を作る。"""
    S, D = spans(src), spans(dst)
    # 同じ文はそのまま照合できる。変更のない長文を毎回総当たりで比較しない。
    exact = {}
    for i, (_, _, text) in enumerate(D):
        exact.setdefault(text.strip(), []).append(i)
    unchanged, matched = set(), set()
    for k, (_, _, text) in enumerate(S):
        indices = exact.get(text.strip(), [])
        if indices:
            unchanged.add(k)
            matched.add(indices.pop())
    changed = [k for k in range(len(S)) if k not in unchanged]
    drafts = [d for i, d in enumerate(D) if i not in matched]
    owners = owner_of([S[k] for k in changed], drafts)
    owner = dict(zip(changed, owners))
    out, last = [], 0
    for k, (a, b, text) in enumerate(S):
        i = owner.get(k)
        out.append(src[last:a])
        if i is not None and owners.count(i) == 1:
            draft = drafts[i][2]
            text = draft if requested_only(text, draft, request) else keep_requested(text, draft, request)
        out.append(text)
        last = b
    out.append(src[last:])
    return "".join(out)


def remaining(src, dst, request=""):
    """戻した後に残る候補。依頼で変える・伏せる・消すよう頼まれた値だけの候補は数えない。"""
    items = check(src, dst)
    if not request or not items:
        return items
    # 値の文字列だけで警告を消さず、許可された出現箇所を反映して個数を照合する。
    contextual = ("[数値・日時]", "[組み合わせ]")
    out = [item for item in check(requested_reference(src, dst, request), dst) if item.startswith(contextual)]
    for item in items:
        if item.startswith(contextual):
            continue
        ws, kind = words_of(item)
        if request and kind == "lost" and ws and all(allowed_lost(w, src, request) for w in ws):
            continue
        if request and kind == "added" and ws and all(allowed(w, request) for w in ws):
            continue
        out.append(item)
    return out


def main():
    args = sys.argv[1:]
    request = ""
    if "--request" in args:
        k = args.index("--request")
        request = open(args[k + 1], encoding="utf-8").read()
        del args[k:k + 2]
    if len(args) != 3:
        print(__doc__)
        sys.exit(2)
    src = open(args[0], encoding="utf-8").read()
    dst = open(args[1], encoding="utf-8").read()
    logs = []
    rest = remaining(src, dst, request)
    n = len(rest)
    for _ in range(6):
        new, log = one_pass(src, dst, request, rest)
        next_rest = remaining(src, new, request)
        m = len(next_rest)
        if not log or m >= n:
            break
        dst, n = new, m
        rest = next_rest
        logs += log
    with open(args[2], "w", encoding="utf-8") as f:
        f.write(dst)
    if logs:
        print(f"{len(logs)}か所を原文に戻しました。")
        for x in logs:
            print("- " + x)
    else:
        print("戻した所はありません。")
    if rest:
        print(f"残っている候補が{len(rest)}件あります（読み比べて、同じ意味ならそのままでよい）：")
        for x in rest:
            print("- " + x)


if __name__ == "__main__":
    main()
