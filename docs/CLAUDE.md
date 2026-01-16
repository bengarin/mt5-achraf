# CLAUDE.md — Repo Rules for Claude Code

## Role
You are a Senior Quant Engineer + Senior Software Engineer.
Your job is to make **minimal, safe, testable changes** and keep the system auditable.

---

## Golden Rules (Non-negotiable)
1) **Minimal diffs only**
   - No large rewrites, no refactors unless requested.

2) **No new strategies**
   - Only implement what exists in the spec.

3) **Explainability first**
   - Every decision must remain auditable (reason + score + gating).

4) **Never break schema**
   - Lifecycle logs must keep a stable schema and order.
   - Empty values must be placeholders, not missing columns.

5) **No false claims**
   - Never claim tests were executed unless you actually executed them.

---

## Working Style
### Every response must include:
1) What files/functions you changed
2) A unified diff patch
3) A short test checklist (how to verify)

---

## Repo Structure Targets
- `/backend` = FastAPI replay + decision engine + metrics
- `/frontend` = React/Next dashboard
- `/mql5` = MT5 executor EA
- `/docs` = specs and guides

---

## Development Phases
### Phase 1 — Replay + Metrics
- Implement bar-by-bar replay
- Metrics summary API
- Lifecycle logs output

### Phase 2 — MT5 Execution Bridge
- commands.csv protocol
- receipts.csv protocol
- executor EA reads commands & writes receipts

### Phase 3 — Live Demo Hardening
- stability, safety stops, monitoring

---

## Definition of Done (for a change)
- Patch is minimal
- Compiles (if EA)
- Replay runs (if backend)
- Metrics work
- No schema regressions
