# Upstream

- Repository: https://github.com/AnIT012/nihongo
- Skill version: 2.3.1
- Commit: `c6566777c54751ed6c9bc1666190ed5f2f3a9276`
- License: MIT (`LICENSE`)

This directory vendors the upstream `nihongo/` skill directory. Update this copy deliberately and review upstream changes before deployment.

The shared Home Manager module links this skill into Claude's skill directory on macOS and NixOS. The `agent-skills` mise task copies it into `~/.agents/skills/` on both systems.
