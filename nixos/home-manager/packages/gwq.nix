{
  buildGoModule,
  fetchFromGitHub,
  git,
  go,
  go_1_27 ? null,
  installShellFiles,
  lib,
  makeWrapper,
  tmux,
}:

let
  buildGoModule' = buildGoModule.override {
    go = if go_1_27 != null then go_1_27 else go;
  };
in
buildGoModule' rec {
  pname = "gwq";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "d-kuro";
    repo = "gwq";
    rev = "v${version}";
    hash = "sha256-X1qkQUEhBqhMvdStN2YMj7nmqHWpO//y6afrBdAmVUI=";
  };

  vendorHash = "sha256-4K01Xf1EXl/NVX1loQ76l1bW8QglBAQdvlZSo7J4NPI=";

  subPackages = [ "cmd/gwq" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/d-kuro/gwq/internal/cmd.version=v${version}"
  ];

  nativeBuildInputs = [
    installShellFiles
    makeWrapper
  ];

  postInstall = ''
    wrapProgram $out/bin/gwq \
      --prefix PATH : ${lib.makeBinPath [git tmux]}

    export HOME=$TMPDIR
    $out/bin/gwq completion bash > gwq.bash
    $out/bin/gwq completion fish > gwq.fish
    $out/bin/gwq completion zsh > gwq.zsh

    installShellCompletion --cmd gwq \
      --bash gwq.bash \
      --fish gwq.fish \
      --zsh gwq.zsh
  '';

  meta = {
    description = "Git worktree manager with fuzzy finder interface";
    homepage = "https://github.com/d-kuro/gwq";
    changelog = "https://github.com/d-kuro/gwq/releases/tag/v${version}";
    license = lib.licenses.asl20;
    mainProgram = "gwq";
    platforms = lib.platforms.unix;
  };
}
