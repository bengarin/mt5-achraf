# TrapSniperPro / Auto-Trading Platform — Complete Architecture (MT5 + App)

## 0) Goal (What we are building)
We are building a **market-grade Auto-Trading System** that supports:

- **Replay / Backtest** before any broker/live trading
- **Explainable decision flow** (deterministic + auditable)
- **Safe execution** with risk/protection gating
- **Full lifecycle logging** (40-column schema)
- **MT5 final execution** (broker connectivity)

Core principle:
> The App is the **Brain** (analysis + decision + replay), and MT5 is the **Executor** (order routing + fills + retcodes).

---

## 1) System Overview

### High-level pipeline
1. Data Ingest (OHLC or Ticks)
2. Replay / Simulation Engine
3. Market Snapshot
4. Protection Mode
5. Risk Engine (prop-style)
6. Strategy Candidates (Trap / Breakout / Reversion)
7. Soft Scoring + Penalties
8. Router (winner selection + anti-starvation)
9. Execution (simulated OR MT5 execution)
10. Trade Management
11. Close + Outcome extraction
12. Lifecycle logging + analytics

---

## 2) Components

### A) Frontend (Dashboard UI)
**Purpose:** Visualize performance, replay decisions, monitor live trading.

**Pages**
- **Home / Overview**
  - trades/day, winrate, profit factor, avg R
  - equity curve
- **Replay Runner**
  - load dataset
  - play/pause/step bar-by-bar
  - view decisions (SIGNAL/REJECT/ENTER)
- **Trades**
  - all trades table
  - filters: strategy, regime, date
- **Rejects**
  - reject distribution chart
  - bottleneck detection
- **Execution Quality**
  - retry rate
  - auto-adjust rate
  - retcode histogram
- **Protection**
  - GREEN/YELLOW/RED frequency + timeline
- **Compare Runs**
  - baseline vs new version metrics

**Tech**
- Next.js (React)
- Recharts
- Tailwind / shadcn UI

---

### B) Backend (Core Engine + API)
**Purpose:** Replay/backtest, decision making, analytics, storage, and live trade coordination.

**Core modules**
1. `data_service`
   - load OHLC CSV / parquet
   - normalize timestamps and symbols
2. `replay_engine`
   - bar-by-bar playback
   - provides "current candle" context
3. `market_snapshot`
   - spread, ATR, volatility measures
   - session detection (London/NY)
4. `regime_engine`
   - TREND_UP / TREND_DOWN / RANGE / CHOP / VOLATILE
   - regime confidence
5. `protection_engine`
   - GREEN / YELLOW / RED
   - thresholds:
     - SpreadPts
     - SpreadATRRatio
     - ATRSpikeRatio
6. `risk_engine`
   - daily/weekly/monthly limits
   - cooldown logic
   - risk multiplier and riskPctFinal
7. `strategy_engine`
   - TrapSniper
   - TrapLite
   - BreakoutLondon/NY
   - MeanReversion
   - outputs candidates with scores
8. `soft_scoring`
   - rawScore, penalty, adjustedScore
9. `router`
   - selects best candidate
   - anti-starvation fairness penalty
10. `execution_engine`
   - mode: SIMULATION or MT5
   - handles retries, retcodes, auto-adjust SL/TP
11. `trade_manager`
   - BE move
   - trail
   - time exit
   - protection close
12. `lifecycle_logger`
   - writes 40-column events
   - outputs CSV and DB
13. `metrics_engine`
   - trades/day, winrate, PF
   - by strategy, regime
   - reject distribution
   - execution quality
   - protection frequency

**API endpoints**
- `POST /datasets/upload`
- `POST /replay/run`
- `GET /replay/status`
- `GET /trades`
- `GET /metrics/summary`
- `GET /metrics/strategies`
- `GET /metrics/rejects`
- `GET /metrics/execution`
- `GET /metrics/protection`
- `POST /live/start`
- `POST /live/stop`
- `POST /orders/send` (optional)
- `GET /orders/status`

**Tech**
- FastAPI (Python)
- pandas / numpy
- PostgreSQL (prod) or SQLite (MVP)

---

### C) Executor Layer (MT5 Integration)
**Purpose:** Reliable trade execution on broker via MT5 terminal.

We support 2 integration modes:

#### Mode 1 (Recommended MVP): File Queue Bridge
- Backend writes order commands into:
  `MQL5/Files/commands.csv`
- MT5 EA reads commands and executes orders.
- EA writes receipts to:
  `MQL5/Files/receipts.csv`

✅ No HTTP allowlist issues  
✅ Works with Strategy Tester  
✅ Easy to debug  

#### Mode 2: Python MetaTrader5 API
- Backend (Python) connects to running MT5 terminal.
- Executes trades via MetaTrader5 package.

✅ Fast  
✅ Less code inside EA  
⚠️ Needs MT5 running and logged-in on same machine

---

## 3) Command Protocol (App → MT5 Executor)

### commands.csv (minimal required fields)
| Field | Example | Notes |
|------|---------|------|
| cmd_id | 10001 | unique |
| timestamp | 2026-01-16 10:22:05 | UTC/local |
| symbol | XAUUSD | |
| action | BUY / SELL / CLOSE | |
| lot | 0.10 | risk engine output |
| sl | 2435.10 | optional |
| tp | 2441.50 | optional |
| magic | 4400000 | EA magic |
| comment | TrapSniper:78.2 | explainability |
| ttl_sec | 15 | command expiry |

### receipts.csv (MT5 → App)
| Field | Example |
|------|---------|
| cmd_id | 10001 |
| status | FILLED / REJECTED / ERROR |
| ticket | 123456 |
| retcode | 10009 |
| fill_price | 2437.20 |
| retries | 1 |
| auto_adjusted | 0/1 |
| adjust_reason | SL;TP;VOL; |
| message | broker message |

---

## 4) Lifecycle Logging (40-column schema)

All events must emit **exactly 40 columns in the same order**:
- SIGNAL
- REJECT
- ROUTER
- ENTER
- MANAGE
- CLOSE

**CSV schema must remain stable.**
Docs must follow code.

*(The canonical schema is maintained in the CSV guide file.)*

---

## 5) Replay / Backtest Flow (App)

Replay mode steps:
1. Load dataset (OHLC)
2. Iterate bar-by-bar
3. Build market snapshot
4. Apply protection + risk gating
5. Generate candidates per strategy
6. Score + route winner
7. Simulate execution (spread model + SL/TP)
8. Manage trade state and close
9. Emit lifecycle logs
10. Produce metrics report

---

## 6) Live Auto-Trading Flow (MT5 Execution)

Live mode steps:
1. Backend receives real-time feed (poll OHLC or ticks)
2. Decision engine runs at each bar close (or defined interval)
3. Backend issues command → commands.csv
4. MT5 Executor EA reads command → sends order
5. Receipts returned → receipts.csv
6. Backend updates trade state and logs ENTER/MANAGE/CLOSE
7. Dashboard updates + alerts

---

## 7) Safety / Risk Guardrails (Non-negotiable)
- daily loss limit
- weekly loss limit
- monthly DD cap
- cooldown after consecutive losses
- max trades/day
- max positions
- spread/ATR protection (RED blocks entries)
- kill switch (manual stop)

---

## 8) Testing Strategy

### Phase A — Static checks
- compile MT5 EA with zero errors
- validate command parsing logic
- validate CSV schema

### Phase B — Replay validation (App)
- run replay on historical datasets
- verify metrics consistency
- verify lifecycle logs stable

### Phase C — Demo live validation
- connect to demo account
- run 1–2 days
- compare execution slippage and retcodes

### Phase D — Production readiness
- 1+ month stable run on demo
- only then live small risk

---

## 9) Repo Structure (Recommended)
repo-root/
mql5/
experts/
AppExecutorEA.mq5
include/
files/ # generated csv (ignored by git)
backend/
app/
main.py
core/
data_service.py
replay_engine.py
snapshot.py
regime.py
protection.py
risk.py
strategies/
router.py
execution.py
manager.py
logger.py
metrics.py
api/
routes.py
requirements.txt
frontend/
(Next.js app)
docs/
ARCHITECTURE.md
PROJECT_SPEC.md
CSV_GUIDE.md
tools/
analyze_trapsniper_csv_FINAL.py

---

## 10) Development Rules (Claude/AI rules)
- Always produce minimal diffs
- Always preserve schema
- Never claim runtime tests unless executed
- Always return:
  - patch/diff
  - test checklist
  - file/function touched

---

## 11) MVP Deliverables
1) Replay engine runs OHLC dataset → outputs logs + metrics
2) commands.csv generated from replay
3) MT5 Executor EA executes commands → receipts.csv
4) Dashboard shows trades + performance + rejects + protection

---

## 12) Success Metrics
- stable schema (40 cols)
- reproducible replay results
- no execution regressions (retcodes tracked)
- explainability: every entry/reject has a reason
- controllable DD with prop-style risk engine

