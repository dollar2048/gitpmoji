# GITPMOJI

AI for your git commits: emojis, commit messages from the diff, and code ratings.

It is a `prepare-commit-msg` git hook, so it works with any git client or IDE.

## Install

In your project directory run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/dollar2048/gitpmoji/main/install.sh)
```

The installer asks:
- **Where to install.** Press Enter for `.gitpmoji/` (recommended, all files in it are git-ignored), or type `.` for the project root (`.gitpmoji.env` is then added to `.gitignore`).
- **API key, base URL, model.** If you have global values (in `~/.gitpmoji.env` or exported in your shell), leave the answer empty to use them.

Then test it:

```bash
.gitpmoji/gpt.sh -e
```

## Usage

Write your commit message as usual and add a marker at the end:

| Marker | What happens |
|--------|--------------|
| `~`    | adds an emoji |
| `~~`   | adds an AI commit message from the staged diff |
| `~~~`  | adds an AI commit message and an emoji |
| `*`    | adds a rating of the change (use alone or after a marker: `~*`, `~~*`, `~~~*`) |

Without a marker, the message stays as it is.

Example: `Fix login crash~` → `🪲 Fix login crash`

![Commit examples](https://github.com/user-attachments/assets/f69ff571-e304-41c1-baec-7d53219bd756)

See more in the [commit history](https://github.com/dollar2048/gitpmoji/commits/main/) of this repo.

## Assess a diff

```bash
git diff | .gitpmoji/gpt.sh -d -a
```

It rates cleanliness, structure, readability and complexity, from 1 to 10.

![Assessment example](https://github.com/user-attachments/assets/7c190fd8-cfc3-4302-b44c-6cfd16a95329)

Run `.gitpmoji/gpt.sh -h` for all options.

## Configuration

Settings live in `.gitpmoji.env` next to `gpt.sh`. The file made by the installer loads the global `~/.gitpmoji.env` first, so local values win. Commented-out lines (`#export ...`) mean the global value is used.

```bash
export GITPMOJI_API_KEY="your_openai_api_key"            # required, https://platform.openai.com/account/api-keys
export GITPMOJI_API_BASE_URL="https://api.openai.com/v1" # optional, any OpenAI-compatible API
export GITPMOJI_API_MODEL="gpt-4o"                       # optional, default gpt-4o
export GITPMOJI_PREFIX_RX="TICKET-[0-9]\{1,5\} \{0,1\}"  # optional, sed regex: emoji goes after this prefix
export GITPMOJI_MULTILINE_COMMIT="false"                 # optional, "true" for a multi-line AI message
```

Newer reasoning models (o-series, gpt-5 and later) are detected on their own. Rarely needed:
- `GITPMOJI_API_PARAMS_STYLE` — `auto` (default), `legacy` or `new`, to force the request style
- `GITPMOJI_REASONING_TOKENS` — extra token budget for reasoning models (default `2000`)

## Manual setup

1. Install `jq`: `brew install jq` or `apt-get install jq`
2. Put `gpt.sh` and `prepare-commit-msg.sh` in `.gitpmoji/`, run `chmod +x` on them, and create `.gitpmoji/.gitpmoji.env` (see above).
3. Link the hook:
   ```bash
   ln -sf ../../.gitpmoji/prepare-commit-msg.sh .git/hooks/prepare-commit-msg
   ```

To uninstall, remove `.git/hooks/prepare-commit-msg` and `.gitpmoji/`.

## License

[LICENSE](LICENSE)
