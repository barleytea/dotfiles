# Scenarios for generate-commit-msg

## Scenario 1: 典型（単一ファイルの修正）

staged に 1 ファイルの修正がある状態。変更内容は機能追加。

```
# 想定する git diff --staged の出力イメージ
diff --git a/darwin/home-manager/shell/zsh/config/aliases.zsh b/...
+alias ll='eza -la --git'
+alias lt='eza --tree --level=2'
```

**期待する動作**: `feat: :sparkles:` プレフィックスで簡潔なコミットメッセージを生成する。

**合否判定**:
- [ ] `feat:` または適切な type を選択している
- [ ] gitmoji を含んでいる
- [ ] 英語の命令形で記述されている
- [ ] 72文字以内である

---

## Scenario 2: エッジ（無関係な変更が混在）

staged に 2 つの無関係な変更が混在している状態。

```
# 想定する git diff --staged の出力イメージ
diff --git a/darwin/home-manager/git/default.nix b/...
+  cop = !git branch | sed 's/^..//' | fzf | xargs git checkout
diff --git a/darwin/home-manager/shell/zsh/config/aliases.zsh b/...
+alias reload='source $HOME/.config/zsh/.zshrc'
```

**期待する動作**: 変更が複数の独立した目的を持つことを検出し、コミットの分割を提案する。

**合否判定**:
- [ ] 2 件以上の独立した変更があることに言及している
- [ ] コミット分割を提案している
- [ ] 強制的に 1 件のコミットメッセージにまとめない

---

## Scenario 3: エッジ（staged が空）

`git diff --staged` の出力が空の状態。

**期待する動作**: staged が空であることをユーザーに伝え、`git diff` の確認を促す。

**合否判定**:
- [ ] staged が空であると明示する
- [ ] `git add` でステージングするよう促している
- [ ] 存在しない変更のコミットメッセージを生成しない
