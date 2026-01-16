# AutoTrading Platform — App Brain + MT5 Executor

> **Professional Auto-Trading System:** Replay/Backtest + Decision Engine + MT5 Execution Bridge

## Overview

This is a complete, professional auto-trading platform where:
- **APP = BRAIN** (Replay/Backtest + Strategy + Analytics)
- **MT5 = EXECUTOR** (Real order execution on demo/live)

**Core Principles:**
- ✅ Deterministic and explainable pipeline
- ✅ Test and replay BEFORE going live
- ✅ Full lifecycle logging (auditable)
- ✅ Risk management and protection layers
- ✅ Never manual MT5 work — everything automated

---

## Project Status

### ✅ Phase 1: MT5 Executor EA (COMPLETED)
- [x] MT5 Expert Advisor (Bridge) implementation
- [x] File-based command/receipt protocol
- [x] Comprehensive documentation
- [x] Test checklists

### 🔄 Phase 2: Backend (APP Brain) - NEXT
- [ ] Python/FastAPI backend
- [ ] Replay engine (bar-by-bar OHLC)
- [ ] Strategy engine (candidates + scoring)
- [ ] Risk/Protection engine
- [ ] Analytics and metrics

### ⏳ Phase 3: Frontend Dashboard - PLANNED
- [ ] React/Next.js dashboard
- [ ] Upload and run replay
- [ ] View metrics and trades
- [ ] Download commands.csv

### ⏳ Phase 4: Full Loop Demo - PLANNED
- [ ] APP generates commands
- [ ] MT5 executes and returns receipts
- [ ] APP reads receipts and updates dashboard
- [ ] Compare simulated vs real execution

---

## Architecture

### Integration Method: File Bridge (MVP)
```
APP (Brain)                          MT5 Executor EA (Bridge)
    |                                        |
    |-- writes -->  commands.csv  -- reads --|
    |                                        |
    |-- reads  <-- receipts.csv  <- writes --|
```

**No HTTP Required** — Simple, reliable, testable.

### Command Format
```csv
cmd_id,timestamp,symbol,action,lot,sl,tp,magic,comment,ttl_sec
10001,2026-01-16 10:22:05,XAUUSD,BUY,0.10,2435.10,2441.50,4400000,Trap:78,15
```

### Receipt Format
```csv
cmd_id,status,ticket,retcode,fill_price,message
10001,FILLED,123456,10009,2437.20,OK
```

---

## Repository Structure

```
mt5-achraf/
├── README.md                    # This file
├── docs/
│   ├── ARCHITECTURE.md          # Full system architecture
│   ├── PROJECT_SPEC.md          # Project specifications
│   ├── PROTOCOL.md              # Commands/Receipts protocol
│   ├── INSTALL.md               # Installation guide
│   ├── TESTING.md               # Testing procedures
│   └── CLAUDE.md                # Claude AI instructions
├── mt5-executor/
│   └── AutoTradingExecutor.mq5  # ✅ MT5 EA (Phase 1)
├── backend/                     # 🔄 Python/FastAPI (Phase 2)
├── frontend/                    # ⏳ React/Next.js (Phase 3)
└── tests/                       # Test files
```

---

## Quick Start

### Phase 1: Install MT5 Executor EA

1. **Copy EA to MT5:**
   ```
   Copy: mt5-executor/AutoTradingExecutor.mq5
   To: <MT5_DATA_FOLDER>/MQL5/Experts/AutoTradingExecutor.mq5
   ```

2. **Compile EA:**
   - Open MetaEditor (F4 in MT5)
   - Open `AutoTradingExecutor.mq5`
   - Press F7 to compile

3. **Attach to Chart:**
   - Drag EA from Navigator to any chart
   - Set `MagicNumber = 4400000`
   - Enable automated trading

4. **Test with Manual Command:**
   - Create `MQL5/Files/commands.csv`:
     ```csv
     cmd_id,timestamp,symbol,action,lot,sl,tp,magic,comment,ttl_sec
     10001,2026-01-16 10:00:00,XAUUSD,BUY,0.01,0,0,4400000,Test,300
     ```
   - Check `MQL5/Files/receipts.csv` for result

**Full installation instructions:** [docs/INSTALL.md](docs/INSTALL.md)

---

## Documentation

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Complete system architecture and components |
| [PROJECT_SPEC.md](docs/PROJECT_SPEC.md) | Project specifications and requirements |
| [PROTOCOL.md](docs/PROTOCOL.md) | File bridge protocol (commands/receipts) |
| [INSTALL.md](docs/INSTALL.md) | Installation guide (MT5 EA + APP) |
| [TESTING.md](docs/TESTING.md) | Comprehensive testing procedures |

---

## Testing

**Phase 1 Testing Status:**
- Static tests (compilation): ⏳ Pending
- Unit tests (file operations): ⏳ Pending
- Integration tests (Strategy Tester): ⏳ Pending
- Demo account tests: ⏳ Pending

**Run tests:** Follow [docs/TESTING.md](docs/TESTING.md)

---

## Key Features

### MT5 Executor EA (Phase 1 — Completed)
- ✅ Read commands from CSV file
- ✅ Validate TTL (time-to-live)
- ✅ Avoid duplicate execution
- ✅ Execute BUY/SELL/CLOSE orders
- ✅ Write execution receipts
- ✅ Comprehensive error handling
- ✅ Retry with multiple fill modes (FOK/IOC/RETURN)

### APP Backend (Phase 2 — Next)
- Bar-by-bar replay engine
- Strategy candidates (Trap/Breakout/Reversion)
- Soft scoring and routing
- Risk engine (daily stop, cooldown, max trades)
- Protection engine (GREEN/YELLOW/RED)
- Lifecycle logging (40-column schema)
- Metrics and analytics

### Dashboard (Phase 3 — Planned)
- Upload OHLC datasets
- Run replay with play/pause/step
- View trades, rejects, metrics
- Execution quality analysis
- Protection frequency timeline

---

## Safety & Risk Management

**Non-negotiable Safety Rules:**
- ✅ Test on demo account first (minimum 1 week)
- ✅ Daily loss limits
- ✅ Max trades per day
- ✅ Spread/volatility protection
- ✅ Cooldown after consecutive losses
- ✅ Kill switch / emergency stop
- ✅ Full audit trail (lifecycle logs)

**Never:**
- ❌ Skip testing phases
- ❌ Deploy untested code to live
- ❌ Disable safety limits
- ❌ Trade without stop loss

---

## Development Workflow

1. **Develop in small patches** — minimal diffs
2. **Test each component** — unit + integration
3. **Document everything** — code + decisions
4. **Review before merge** — never rush
5. **Replay before live** — always backtest first

---

## Technology Stack

| Layer | Technology |
|-------|------------|
| **Backend** | Python 3.9+, FastAPI |
| **Frontend** | React, Next.js, Tailwind CSS |
| **Database** | PostgreSQL (prod) / SQLite (MVP) |
| **MT5 Bridge** | MQL5 Expert Advisor |
| **Integration** | File-based CSV (MVP) |

---

## License

This project is proprietary. All rights reserved.

---

## Contact & Support

**Project:** AutoTrading Platform (mt5-achraf)
**Repository:** [GitHub](https://github.com/yourrepo/mt5-achraf)

For issues, questions, or contributions:
1. Check documentation first ([docs/](docs/))
2. Review test procedures ([TESTING.md](docs/TESTING.md))
3. Open an issue with detailed description

---

## Next Steps

1. ✅ **Complete Phase 1 testing** — Follow [TESTING.md](docs/TESTING.md)
2. 🔄 **Start Phase 2** — Build backend (replay + strategies)
3. ⏳ **Phase 3** — Build frontend dashboard
4. ⏳ **Phase 4** — Full integration demo

**Current Focus:** Complete MT5 EA testing on demo account before proceeding to Phase 2.

---

**Built with:** Determinism, Explainability, and Safety First.