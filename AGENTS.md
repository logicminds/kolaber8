# Agent Instructions

All agents operating in this repository MUST load the kolaber8 skill from `.agents/skills/kolaber8/SKILL.md`.

kolaber8 governs the boundary between two people's AI systems. It provides two operations:
- **PUSH**: package current thinking, append it to `exchange/ledger.md`, rebase on the remote tip, commit, and push to the user's repository when the human is ready to share.
- **RECEIVE**: read the latest packet from `exchange/ledger.md` and bring it into the current workflow.

Do not modify the kolaber8 packet format or ledger location without updating the skill file itself. Keep the skill loaded for any session that may involve cross-system collaboration.

Persona files at `.agents/skills/kolaber8/.personas/` and generated digests at `exchange/.kolaber8/digests/` are local-only state. They are gitignored by default and must never be committed or shared across the kolaber8 boundary.
