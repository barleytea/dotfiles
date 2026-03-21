#!/usr/bin/env bash
# PATH configuration (equivalent to path.zsh)

# local bin
export PATH="${HOME}/.local/bin:${PATH}"

# cargo (Rust)
export PATH="${HOME}/.cargo/bin:${PATH}"

# go
export PATH="${HOME}/go/bin:${PATH}"
export PATH="${HOME}/.local/share/go/bin:${PATH}"

# npm global
export PATH="${HOME}/.npm-global/bin:${PATH}"
