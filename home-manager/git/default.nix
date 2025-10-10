{ pkgs, ... }:

let

gitConfig = ''
  [core]
    excludesFile = ~/.config/git/ignore
    editor = nvim
    longpaths = true

  [user]
    name = barleytea
    email = barleytea362@gmail.com

  [init]
    defaultBranch = main

  [ghq]
    root = ~/git_repos/

${if pkgs.stdenv.isLinux then ''
  [credential]
    helper =
    helper = !${pkgs.git-credential-manager}/bin/git-credential-manager

  [credential "https://github.com"]
    provider = github

  [credential "https://gist.github.com"]
    provider = github
'' else if pkgs.stdenv.isDarwin then ''
  [credential]
    helper = osxkeychain
'' else ""}

  [alias]
# ---- 基本操作 ----
# ステータス一覧
  ss = status
# ブランチ一覧
  br = branch
# ブランチ名変更
  brm = branch -m
# ブランチ削除 (安全)
  brd = branch -d
# 強制ブランチ削除
  brdd = branch -D
# checkout
  co = checkout
# 新規ブランチ作成 checkout
  cob = checkout -b
# fzf でブランチ選択 checkout
  cop = !git branch | sed 's/^..//' | fzf | xargs git checkout
# switch
  sw = switch
# 新規ブランチ作成 switch
  swc = switch -c
# 追加 (パス指定)
  ad = add
# 追跡ファイル変更一括追加
  adu = add -u
# 追跡ファイル変更を対話選別
  adup = add -u -p
# コミット作成
  ci = commit
# マージ
  mg = merge
# チェリーピック
  cp = cherry-pick
# 標準ログ
  lg = log
# 1 行ログ
  lgo = log --oneline
# 変更ファイル種別付き 1 行
  lgn = log --name-status --oneline
# 空の初期コミット
  fi = commit --allow-empty -m "Initial commit"

# ---- Commit Log ----
# グラフ + 装飾 + 短縮ハッシュ
  gl = log --graph --decorate --oneline --abbrev-commit
# 全ブランチ込み gl
  gla = log --graph --decorate --oneline --abbrev-commit --all
# fuller 形式
  glf = log --pretty=fuller
# cherry 判定付き重複除外視点
  glc = log --graph --decorate --oneline --cherry
# 新しい順
  glr = log --reverse --oneline
# 差分統計
  gls = log --stat --summary
# 直近 1 コミットパッチ
  gldiff = log -p -n 1
# 直近 2 件
  gl2 = log -n 2 --graph --decorate --oneline
# タグ強調シンプル
  gtag = log --decorate --tags --simplify-by-decoration --oneline
# mainとの差分一覧
  gmain = log main..HEAD --oneline --decorate --graph

# 直前との差分レンジ
  glhead = log HEAD~1..HEAD --oneline --decorate
# 1 つ前コミット単体
  glprev = log HEAD~1 --oneline --decorate
# 変更ファイル名のみ
  glname = log --name-only --oneline
# 行数統計簡易
  glstat = log --oneline --shortstat

# 作者別コミット数
  gwho = shortlog -sn
# 総コミット数
  gcount = rev-list --count HEAD
# 直近1ヶ月作者ランキング
  gtop = !git shortlog -sn --since="1 month ago"
# 全履歴簡略 (装飾 oneline)
  ghist = log --graph --decorate --simplify-by-decoration --all --pretty=oneline

# greflog: 相対時刻付き reflog
  greflog = reflog --date=relative --pretty='format:%C(auto)%h %gd %Cgreen%cr %Cblue%an %Creset%s'

# fzf でコミット選択し短縮ハッシュ
  glfzf = !git log --color=always --decorate=short --graph --pretty=format:'%C(auto)%h%d %s %Cgreen(%cr %an)' | fzf --ansi --no-sort --reverse --tiebreak=index --preview 'echo {} | grep -oE "^[a-f0-9]{7}" | xargs -I{} git show --color=always {}' | grep -oE '^[a-f0-9]{7}'
# 選択コミット表示
  gshow = !f(){ git show $(git glfzf); }; f

  [pager]
    diff = delta
    log = delta
    reflog = delta
    show = delta

  [delta]
    enable = true
    syntax-theme = Dracula
    side-by-side = true
'';

gitIgnore = ''
  mcp.json
  .cursor/rules/
  .cursorrules
  .clinerules
  .local.memo.md
  .local_memos/
  .idea/
  .vscode/
  *.log
  node_modules/
  .tool-versions
  __debug*
  copilot-instructions.md
  .ai/
  .kiro/
  .DS_Store
'';

in {
  home.file.".config/git/config".text = gitConfig;
  home.file.".config/git/ignore".text = gitIgnore;
}
