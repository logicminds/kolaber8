---
name: kolaber8
argument-hint: "[push | receive] [partner name]"
description: "Govern the boundary between two people's AI systems. Use when collaborating on an idea with another person who runs their own AI system. Two operations: PUSH (package the current thinking into a standard packet, append it to the shared ledger, commit, and push to the user's repository) and RECEIVE (read the latest packet from the shared ledger and bring it into your own workflow)."
triggers:
  - "push this to <name>"
  - "ready to share"
  - "ingest <name>'s turn"
  - "what did <name> send"
alwaysApply: true
---

# Exchange Turns Across AI Systems

**Public name:** kolaber8 Exchange Protocol (KEP).
This skill governs only the boundary between two people's AI systems. Install it in any harness (Claude Code, Codex, Cursor) or tools like notion. It does not touch your inner loop. It defines only how you PUSH a turn out and RECEIVE a turn in.

## Prime Rule

Govern only the boundary. Do not change how this system thinks or drafts internally (the inner loop). Only deliberately pushed packets cross. Nothing reaches the shared ledger automatically.

- A shared Git repo is the source of truth. Default path: `exchange/ledger.md`, append-only, lives in the user's repository.
- One packet per entry. Never edit or delete a prior packet; only append.
- To act, read the latest packets since your last turn, then append your reply.
- The skill auto-initializes `exchange/` and `ledger.md` if they do not already exist; never require the human to create them.

## Node identity

The `from` field in every packet identifies the sending node. Each node documents its own identity source in local config (e.g., harness metadata, environment variable, or a `.kolaber8/node` file). The protocol does not require a global registry; it only requires that the same node uses a stable `from` value across its packets.

## Packet Format

Every packet is one YAML block carrying these slots:

```yaml
id: p-<n>            # unique packet id
thread_id: t-<n>     # which idea-thread this belongs to
turn: <n>            # sequence number in the exchange
from: <node>         # which system / person sent it
in_reply_to: []      # packet ids this responds to
new: []              # plain strings OR typed objects with `type`, `title`, `detail`
builds_on: []        # prior idea ids this extends
rejected: []         # ideas considered and dropped, each with a reason
open_questions: []   # directed asks for the other system
state: ""            # current shared snapshot of the idea
status: exploring    # exploring | converging | promote-candidate
```

## PUSH (outbound), when the human says "ready to share"

0. **Auto-initialize.** Ensure the `exchange/` directory exists. If `exchange/ledger.md` does not exist, create it with a frontmatter header and an empty ledger. If the project is already under git, ensure the ledger is tracked. Then proceed.

1. **Curate.** List what is signal versus noise from this session; ask the human to confirm what crosses. Nothing crosses by default.
2. **Safety scan.** Check the selected content for private or sensitive material, because this push leaves the private workspace. Surface anything questionable and pause for the human's decision. Never auto-strip.
3. **Decontextualize.** Rewrite as a self-contained artifact: strip private context the other system cannot use, drop the personal or advisor voice, write in a neutral register. This is the real transform, not a grammar swap.
4. **Package.** Fill the packet slots. Set `in_reply_to` and `builds_on` from the ledger. Record dropped branches in `rejected` with reasons so the other side does not re-raise them.
5. **Rebase before push.** Fetch the latest state from the user's repository, rebase the local branch on top of the remote tip so any new inbound packets are incorporated before your packet is appended, and resolve any ledger conflicts by appending all legitimate packets in order. Never overwrite or reorder existing packets.
6. **Get explicit go-ahead before push.** After appending the packet locally, present the packaged packet to the human and wait for an explicit confirmation such as "go ahead" or "push it". Do not commit or push until that confirmation is given, even if the human previously said "ready to share" or a similar phrase. A single confirmation applies to one push only; future pushes require their own confirmation.
7. **Commit and push.** Only after explicit go-ahead, commit the ledger with a clear message and push to the user's repository.

### Per-node confirmation default

Final push confirmation is not a binding shared contract; it is a per-node policy. The recommended default is strict confirmation: the agent presents the packaged packet and waits for a single explicit human go-ahead (e.g., "go ahead" or "push it") before committing and pushing. A node may opt out of strict confirmation once its skill implementation and operator risk tolerance make auto-push acceptable, but that opt-out must be an explicit local decision, not the default.

## RECEIVE (inbound), when a new packet is on the ledger
0. **Auto-initialize.** Ensure the `exchange/` directory exists. If `exchange/ledger.md` does not exist, create it with a frontmatter header and report that the ledger is empty.
1. **Read** the latest packet(s) since your last turn.
2. **Bring** the `new`, `builds_on`, and `open_questions` into your own inner loop as raw material; let this system process them its own way.
3. **Respect `rejected`.** Do not re-raise a dropped branch unless you have a new reason; if you do, say why.
4. **Summarize for the human, reply-block style:** what arrived (new / builds-on / rejected / open questions) and a short set of options for how to respond.

## Persona File Format

A receiver persona is a local-only file at `.agents/skills/kolaber8/.personas/<human-name>.md`. It tells the harness how to translate inbound kolaber8 packets into a digest the human can consume directly. Persona files are YAML frontmatter plus a structured Markdown body. They are local state: never commit them, never push them across the kolaber8 boundary.

### Core frontmatter fields

```yaml
role: "CEO"                          # the receiver's position
background: "founded the company; non-technical"  # what they already know or lack
style: "terse, concrete, no jargon"   # density, formality, technicality
attention:                           # what they care about most, in order
  - business impact
  - risks
  - action items
output_format: "executive summary"   # overall digest shape
```

### Structured Markdown body template

The body is not free-form prose. Use these headings so users know what to write:

- `## What I care about` — outcomes, decisions, or themes the receiver prioritizes.
- `## What I already know` — domain context the receiver has, so the digest can skip basics.
- `## What I want to skip` — categories of detail the receiver does not want expanded.
- `## How I like to be asked follow-ups` — when the digest needs clarification, how should the agent ask.

## Persona Bootstrapping

0. **Detect.** On first receive, check whether `.agents/skills/kolaber8/.personas/<human-name>.md` exists. If it does, proceed to Receive Translation.
1. **Derive a starter persona.** If the harness already knows the local human's identity (name, role, or prior context), propose a starter persona based on that identity, using `default.md` as a fallback baseline if identity is thin.
2. **Offer the starter.** Show the human the proposed persona file and ask: accept it, edit it directly, or answer a short guided interview to refine it.
3. **Interview fallback.** If the human rejects the starter or no identity is known, ask targeted questions that populate `role`, `background`, `style`, `attention`, and `output_format`.
4. **Write and confirm.** Save the file to `.agents/skills/kolaber8/.personas/<human-name>.md`, show it to the human, and proceed to Receive Translation once confirmed.

## Receive Translation

After the existing RECEIVE flow has read a packet into the inner loop, the harness may translate it into a structured, role-weighted digest for the receiving human.

0. **Locate the persona.** Read `.agents/skills/kolaber8/.personas/<human-name>.md`. If missing, run Persona Bootstrapping first.
1. **Read thread history.** Read prior packets in the same `thread_id` from `exchange/ledger.md` for continuity.
2. **Produce the digest.** Rewrite the packet's `new`, `builds_on`, `open_questions`, and `rejected` content into a structured digest with these fixed sections:
   - **Summary** — one-line framing of what arrived.
   - **What changed** — the new contributions this turn.
   - **Why it matters** — implications for the receiver's role.
   - **Action items** — anything the receiver should do or decide.
   - **Open questions** — directed asks from the packet.
   - **Risks** — concerns or dropped branches worth flagging.
3. **Weight by persona.** Use the persona's `attention` field to decide which sections to expand, condense, or omit. Use the `output_format` field to set the prose style (e.g., terse bullets, narrative, executive framing).
4. **Preserve traceability.** Include the packet's original `id`, `thread_id`, `turn`, and `from` fields in the digest.
5. **Persist the digest.** Write the digest to `exchange/.kolaber8/digests/<packet-id>.md`.
6. **Present to the human.** Show the digest as the primary view; keep the raw packet available on request.

## Adoption Note

The portable unit is this contract, not any code. Implement the steps in whatever harness you run. As long as both sides emit and read the packet format and respect the append-only ledger, the two systems interoperate while each keeps its own inner loop.