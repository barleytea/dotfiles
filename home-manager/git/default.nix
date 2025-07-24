let

gitConfig = ''
  [core]
    excludesFile = ~/.config/git/ignore
    editor = nvim

  [user]
    name = barleytea
    email = barleytea362@gmail.com

  [init]
    defaultBranch = main

  [ghq]
    root = ~/git_repos/

  [alias]
    ss = status
    br = branch
    brm = branch -m
    brd = branch -d
    brdd = branch -D
    co = checkout
    cob = checkout -b
    cop = !git branch | tr -d \\* | tr -d \\ | fzf | xargs git checkout
    sw = switch
    swc = switch -c
    ad = add
    adu = add -u
    adup = add -u -p
    ci = commit
    mg = merge
    cp = cherry-pick
    lg = log
    lgo = log --oneline
    lgn = log --name-status --oneline
    fi = commit --allow-empty -m "Initial commit"

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
