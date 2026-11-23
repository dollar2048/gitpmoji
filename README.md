# GITPMOJI

AI emojis, commit messages and ratings for your git commits. Works with any git client.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/dollar2048/gitpmoji/main/install.sh)
```

Test it:

```bash
.gitpmoji/gpt.sh -e
```

## Usage

Add a marker at the end of your commit message:

| You type | Commit becomes |
|----------|----------------|
| `~`                  | `🪲` (only a random emoji, there is no text to match) |
| `~~`                 | `Refresh expired auth token` |
| `~~~`                | `🪲 Refresh expired auth token` |
| `*`                  | `⭐⭐⭐⭐⭐⭐⭐💩💩💩` |
| `Fix login crash`    | `Fix login crash` (no change) |
| `Fix login crash~`   | `🪲 Fix login crash` |
| `Fix login crash~~`  | `Fix login crash Refresh expired auth token` |
| `Fix login crash~~~` | `🪲 Fix login crash Refresh expired auth token` |
| `Fix login crash*`   | `Fix login crash`<br>`⭐⭐⭐⭐⭐⭐⭐💩💩💩` |
| `Fix login crash~~~*`| `🪲 Fix login crash Refresh expired auth token`<br>`⭐⭐⭐⭐⭐⭐⭐💩💩💩` |
| `TICKET-42 Fix login crash~` ¹ | `TICKET-42 🪲 Fix login crash` |
| `TICKET-42~~~` ¹     | `TICKET-42 🪲 Refresh expired auth token` |

`~` emoji · `~~` AI message from staged changes · `~~~` both · `*` rating, can follow any marker

¹ with `GITPMOJI_PREFIX_RX="TICKET-[0-9]\{1,5\} \{0,1\}"` the emoji goes after the ticket

## Settings

In `.gitpmoji/.gitpmoji.env` (or global `~/.gitpmoji.env`):

```bash
export GITPMOJI_API_KEY="sk-..."                         # required
export GITPMOJI_API_MODEL="gpt-4o"                       # optional
export GITPMOJI_API_BASE_URL="https://api.openai.com/v1" # optional
export GITPMOJI_PREFIX_RX="TICKET-[0-9]\{1,5\} \{0,1\}"  # optional
export GITPMOJI_MULTILINE_COMMIT="false"                 # optional
```

## License

[LICENSE](LICENSE)
