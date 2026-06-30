# Kolaber8 Exchange

Kolaber8 is a small protocol for exchanging ideas between two people whose AI systems run in separate workspaces. It gives both AIs a shared, append-only ledger so they can build on each other's thinking without either side leaking its private context.

The core idea: your AI stays in its own workspace, you decide what gets shared, and only deliberately pushed packets cross the boundary into the shared `exchange/ledger.md`.

## What this repo is

- `skills/kolaber8/SKILL.md` — the canonical skill definition that tells an AI how to push and receive packets.
- `exchange/ledger.md` — the shared ledger, one YAML packet per entry, append-only. Created automatically on the first push if it does not already exist.
- `README.md` — this file.
- `AGENTS.md` — load instructions for agents operating in this repo.
- `.agents/skills/kolaber8/.personas/` — where you keep your persona files, created on first exchange or copied from examples. Local-only and never committed.

## Why use it

If you and a collaborator each use Claude (or another AI assistant) to explore a product, strategy, or design, kolaber8 lets you compare notes without copy-pasting context into chat threads. Each side keeps its own private workspace. The ledger becomes the shared record of what each side has contributed and where the idea stands.

## How it works

1. **Private thinking.** Each AI works inside its own workspace.
2. **Human decides to share.** You tell your AI "ready to share."
3. **Packet gets written.** Your AI packages the chosen content into a YAML packet and appends it to the ledger.
4. **Other side reads it.** Your collaborator's AI pulls the latest packet and brings it into its own workspace.
5. **Reply in kind.** The exchange continues by appending more packets.

## Packet format

Each packet is one YAML document. Packets are separated by a line containing only `---`.

```yaml
id: p-1
thread_id: t-1
turn: 1
from: alice
in_reply_to: []
new:
  - "Idea: use a CRDT for real-time collaborative editing."
builds_on: []
rejected: []
open_questions:
  - "Do we need offline support?"
state: "Exploring architecture options for a sync engine."
status: exploring
```

### Fields

| Field | Purpose |
|-------|---------|
| `id` | Unique packet id, e.g. `p-1`. |
| `thread_id` | Groups related packets, e.g. `t-1`. |
| `turn` | Sequence number in the thread. |
| `from` | Sending system or person. |
| `in_reply_to` | Packet ids this responds to. |
| `new` | New contributions this turn. |
| `builds_on` | Prior idea ids this extends. |
| `rejected` | Dropped branches, each with a reason. |
| `open_questions` | Directed asks for the other side. |
| `state` | Current shared snapshot of the idea. |
| `status` | `exploring`, `converging`, or `promote-candidate`. |

## Setup

The portable unit is a tagged `skills/kolaber8/SKILL.md`, copied into each harness so it activates on the trigger phrases below. The install steps differ per harness.

### Claude Code and other skills.sh harnesses

Install with the skills CLI:

```
npx skills add logicminds/kolaber8
```

Path caveat: the skills.sh CLI installs to `~/.agents/skills/` while Claude Code reads from `~/.claude/skills/`, so a freshly installed skill can be invisible until you symlink it (or point the CLI at the claude-code target). Verify the skill actually loads in a fresh session before relying on it; see the current skills.sh docs for the exact flow.

### Notion

Notion installs a skill as a workspace page, not via the CLI:

1. Copy the contents of `skills/kolaber8/SKILL.md` into a new Notion page.
2. Register it via Settings > Notion AI > Skills > Add a Skill (or from the page menu: Use with AI > Use as AI Skill).

Updates are manual: re-paste on each new tag. Put the tag in the page title (for example `Kolaber8 Exchange Protocol - v0.2`) so the installed version stays auditable.

### Manual / other harnesses

For any harness without a CLI path, add the contents of `skills/kolaber8/SKILL.md` to your project or global instructions (for example `CLAUDE.md` or a Cursor rule) and arrange for it to activate on the trigger phrases below.

### Custom implementation

The portable unit is the contract, not the code. As long as both sides emit and read the packet format and respect the append-only ledger, the systems interoperate while each keeps its own inner loop.

## Usage

### PUSH — send your thinking

Trigger phrases:

- "ready to share"
- "push this to <name>"

The AI then:

1. **Curate.** Lists signal vs noise and asks you to confirm what crosses.
2. **Safety scan.** Flags private or sensitive material before it leaves your workspace.
3. **Decontextualize.** Rewrites the selected content as a self-contained, neutral artifact.
4. **Package.** Fills the packet slots, including `in_reply_to` and `builds_on` from the ledger.
5. **Rebase.** Fetches the latest remote state before appending.
6. **Append.** Adds the packet to the ledger, commits, and pushes on your confirmation.

### RECEIVE — read the other side

Trigger phrases:

- "ingest <name>'s turn"
- "what did <name> send"

The AI then:

1. Reads the latest packets since your last turn.
2. Brings `new`, `builds_on`, and `open_questions` into its own inner loop.
3. Respects `rejected` entries and does not re-raise them without a new reason.
4. Summarizes the inbound content and suggests response options.

### Persona-based digests (optional)

If `.agents/skills/kolaber8/.personas/<human-name>.md` exists, the harness can translate an inbound packet into a role-weighted digest in `exchange/.kolaber8/digests/<packet-id>.md`. Persona files are local-only and never cross the boundary.

Example persona frontmatter:

```yaml
role: "CEO"
background: "founded the company; non-technical"
style: "terse, concrete, no jargon"
attention:
  - business impact
  - risks
  - action items
output_format: "executive summary"
```

The Markdown body should include:

- `## What I care about`
- `## What I already know`
- `## What I want to skip`
- `## How I like to be asked follow-ups`

If no persona exists, the harness can propose a starter or run a short interview to build one.

## Rules

- The ledger is append-only. Never edit or delete a prior packet.
- Only deliberately pushed packets cross the boundary — nothing automatic.
- Always rebase before appending, so inbound packets are included first.
- Never commit persona files to the shared repository.
- Surface questionable content during the safety scan and wait for human approval.

## Repository layout

```
.
├── README.md
├── AGENTS.md
├── exchange/                 # created automatically on first push
│   └── ledger.md             # shared ledger, append-only
└── skills/
    └── kolaber8/
        └── SKILL.md          # skill definition
```

A fresh clone contains `README.md`, `AGENTS.md`, and `skills/`; the `exchange/` directory and ledger are created on the first push.

## Status

Reference implementation of the kolaber8 protocol. Skill version `v0.1`.

## License

MIT