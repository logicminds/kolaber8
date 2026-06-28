# Ledger notifier setup (GitHub to Telegram)

This guide documents how a Kolaber8 exchange ledger notifier is wired up, and how to build or rebuild one. The reference instance sends a Telegram direct message to each exchange participant whenever the ledger is appended.

## What it does

A GitHub Action sends Telegram direct messages whenever a watched file in a repo changes. It runs entirely in GitHub Actions, with no server and no always-on host. In the reference instance it watches `exchange/ledger.md` and DMs a short summary of the newest packet to each configured recipient.

## Reference instance

- Repo: `logicminds/exchange`
- Workflow file: `.github/workflows/ledger-notify.yml` (the canonical copy lives in that repo)
- Trigger: push to `main` that changes `exchange/ledger.md`
- Behavior: parses the newest ledger packet (id, from, state) and DMs a short summary to each chat id
- Recipients: configured through the `TELEGRAM_CHAT_IDS` secret
- Secrets owner: repository admin

## One-time setup

1. Create the bot in Telegram: message BotFather, run `/newbot`, and save the bot token.
2. Get each recipient's chat id: have each person send the bot any message once, then open `https://api.telegram.org/bot<TOKEN>/getUpdates` and copy the numeric id from each chat object.
3. Add repository secrets under Settings, then Secrets and variables, then Actions:
   - `TELEGRAM_BOT_TOKEN`: the bot token from BotFather.
   - `TELEGRAM_CHAT_IDS`: comma-separated chat ids, no spaces.
4. Add the workflow file at `.github/workflows/ledger-notify.yml`, committing it through the GitHub web UI (see the scope gotcha below).
5. Open a pull request and merge to `main`. The workflow arms only once it is on `main`.
6. Test it: the lowest-risk check is to temporarily set `TELEGRAM_CHAT_IDS` to a single id, add a `workflow_dispatch` trigger, run it from the Actions tab, then restore the original values.

## Gotchas (the parts that cost time)

- The token used for commits must hold both `repo` and `workflow` scopes. Without `workflow`, any write under `.github/workflows/` fails with a 404.
- There is no UI to manage, re-auth, or remove the connector used for automated commits. The reliable workaround for the missing workflow scope is to commit the workflow file through the GitHub web UI rather than through the connection.
- Never put the bot token in chat, a pull request, or the ledger. It lives only in repository secrets. Rotate it immediately if it is ever exposed.
- Each recipient must message the bot first. Telegram silently refuses to deliver DMs to anyone who has not started the bot.
- The notifier goes live only after the pull request merges to `main`. Because the trigger is path-filtered to `exchange/ledger.md`, the merge commit itself does not fire it; the first notification is the next change to the watched file.
- If you edit the workflow YAML programmatically, the GitHub Actions expression syntax (a dollar sign followed by double curly braces) is easy to corrupt. Edit carefully and compare against the canonical workflow file.

## Rebuilding after a token rotation

If the bot token is rotated, update the `TELEGRAM_BOT_TOKEN` secret with the new value. No workflow change is needed. Confirm each recipient has messaged the current bot at least once, or delivery will silently fail.
