#!/usr/bin/env bash
set -euo pipefail

LEDGER="exchange/ledger.md"
REMOTE="origin"
BRANCH="main"
LAST_SEEN_FILE=".kep-last-seen"

# Fetch remote without merging
git fetch "$REMOTE" "$BRANCH" >/dev/null 2>&1 || {
    echo "❌ Failed to fetch $REMOTE/$BRANCH"
    exit 1
}

# Extract packet ids and senders. Reads from file arg or stdin.
list_packets() {
    if [[ $# -gt 0 ]]; then
        awk '
            /^id: /      { id = $2 }
            /^from: /    { from = $2 }
            id && from  { print id, from; id = ""; from = "" }
        ' "$1"
    else
        awk '
            /^id: /      { id = $2 }
            /^from: /    { from = $2 }
            id && from  { print id, from; id = ""; from = "" }
        '
    fi
}

# Highest packet id as a number, regardless of padding
max_packet_num() {
    list_packets "$1" \
        | sed 's/^p-0*//' \
        | awk '{ print $1 }' \
        | sort -n \
        | tail -n 1 \
        || echo "0"
}

LOCAL_LAST=$(max_packet_num "$LEDGER" || echo "0")
REMOTE_LAST=$(max_packet_num <(git show "$REMOTE/$BRANCH:$LEDGER") || echo "0")

# If the human has a personal review watermark, use it. Otherwise fall back to
# the local ledger baseline ("everything already pulled is considered seen").
if [[ -f "$LAST_SEEN_FILE" ]]; then
    LAST_SEEN=$(cat "$LAST_SEEN_FILE" 2>/dev/null || echo "0")
    MODE="review watermark"
else
    LAST_SEEN=$LOCAL_LAST
    MODE="local ledger baseline"
fi

if [[ -z "$LAST_SEEN" ]]; then
    LAST_SEEN=0
fi

if [[ "$REMOTE_LAST" -le "$LAST_SEEN" ]]; then
    echo "✅ No new KEP packets on $REMOTE/$BRANCH."
    echo "   Last seen: p-$LAST_SEEN (mode: $MODE). Local ledger: p-$LOCAL_LAST."
    exit 0
fi

# List remote packets not yet seen
echo "📥 New KEP packet(s) on $REMOTE/$BRANCH since p-$LAST_SEEN:"
git show "$REMOTE/$BRANCH:$LEDGER" | list_packets | while read -r id sender; do
    num=$(echo "$id" | sed 's/^p-0*//')
    if [[ "$num" -gt "$LAST_SEEN" ]]; then
        printf "  - %s from %s\n" "$id" "$sender"
    fi
done

# Update marker if interactive
if [[ -t 0 ]]; then
    read -r -p "Mark p-$REMOTE_LAST as personally seen? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "$REMOTE_LAST" > "$LAST_SEEN_FILE"
        echo "✅ Updated $LAST_SEEN_FILE to p-$REMOTE_LAST"
    fi
else
    echo "💡 Run interactively to update $LAST_SEEN_FILE, or: echo $REMOTE_LAST > $LAST_SEEN_FILE"
fi
