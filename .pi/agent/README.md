# Pi config

This directory contains the Git-tracked parts of `~/.pi/agent`.

Tracked here:
- `settings.json`
- `extensions/`

Do not put secrets or runtime data in this repo. Keep `~/.pi/agent/auth.json` and
`~/.pi/agent/sessions/` local only.

Current machine symlinks:
- `~/.pi/agent/settings.json` -> `~/git/self/dotfiles/.pi/agent/settings.json`
- `~/.pi/agent/extensions` -> `~/git/self/dotfiles/.pi/agent/extensions`
