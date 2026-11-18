if [[ -n "${SSH_TTY:-}" ]]; then
  export GPG_TTY="$(tty)"
  export GCM_CREDENTIAL_STORE=gpg
  export GCM_GITHUB_AUTHMODES=device
fi
