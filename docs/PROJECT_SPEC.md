# PROJECT_SPEC — Auto-Trading App + MT5 Executor (Market-Grade)

## 1) Objective
Build a complete Auto-Trading platform that:
- Runs **Replay / Backtest** before broker trading
- Produces **auditable, explainable** decisions
- Supports **live auto-trading with MT5** execution
- Tracks full lifecycle logs and analytics

Core principle:
> App = Brain (analysis + replay + decision)  
> MT5 = Executor (orders + fills + retcodes)

---

## 2) Non-negotiable Rules
- No "magic AI" promises. No guaranteed profit claims.
- Deterministic and explainable pipeline.
- Minimal diffs per change, always testable.
- Always log decisions (reasons + scores + gating).

---

## 3) Scope (MVP → v1)
### MVP-1 (Replay + Metrics)
- Input: OHLC dataset (CSV)
- Replay engine bar-by-bar
- Strategy candidates → scoring → routing
- Simulated execution
- Output: lifecycle logs + metrics dashboards

### MVP-2 (Command Queue + MT5 Execution)
- Generate `commands.csv`
- MT5 Executor EA reads commands and executes
- MT5 writes `receipts.csv`
- App tracks status and produces logs

### MVP-3 (Live Demo Validation)
- Run demo account for stability
- Compare simulated vs real execution metrics

---

## 4) Decision Flow (Deterministic)
1. Market Snapshot
2. Protection Mode (GREEN/YELLOW/RED)
3. Risk Engine (daily/weekly/monthly + cooldown)
4. Regime Detection (+ confidence)
5. Strategy Candidate Generation
6. Soft Scoring + Penalties
7. Router Winner Selection (+ anti-starvation)
8. Execution (SIM or MT5)
9. Trade Management
10. Close + Outcome
11. Log + Metrics

---

## 5) Data Inputs
### Replay input (OHLC CSV minimal)
Required columns:
- timestamp
- open, high, low, close
Optional:
- volume
- spread (if available)

---

## 6) Integration Mode (MT5)
We use **File Queue Bridge** for MVP:
- App writes: `MQL5/Files/commands.csv`
- MT5 writes: `MQL5/Files/receipts.csv`

No HTTP required for MVP.

---

## 7) Logging
### Lifecycle events
- SIGNAL
- REJECT
- ROUTER
- ENTER
- MANAGE
- CLOSE

Schema goal:
- fixed columns
- stable order
- empty placeholders instead of missing fields

---

## 8) Safety Rules
- daily loss stop
- max trades/day
- max open positions
- cooldown after consecutive losses
- spread protection / volatility protection
- kill switch in UI

---

## 9) Deliverables
### Code
- backend (FastAPI)
- frontend (Next.js)
- MT5 Executor EA (mq5)

### Docs
- ARCHITECTURE.md
- PROJECT_SPEC.md
- CSV_GUIDE.md
- USER_GUIDE.md

### Reports
- replay performance report
- demo performance report

---

## 10) Quality Gates
A change is accepted only if:
- compiles (EA)
- replay runs successfully (app)
- schema remains stable
- metrics are consistent
- no new regressions
