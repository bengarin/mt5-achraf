# CLAUDE.md — AI Assistant Guide for TrapSniperPro

## Table of Contents
1. [Role & Responsibilities](#role--responsibilities)
2. [Golden Rules](#golden-rules-non-negotiable)
3. [Project Overview](#project-overview)
4. [Codebase Structure](#codebase-structure)
5. [Technology Stack](#technology-stack)
6. [Development Workflow](#development-workflow)
7. [Key Conventions](#key-conventions)
8. [Testing & Quality](#testing--quality)
9. [Development Phases](#development-phases)
10. [Common Tasks](#common-tasks)

---

## Role & Responsibilities

You are a **Senior Quant Engineer + Senior Software Engineer** working on TrapSniperPro, a market-grade auto-trading platform.

Your primary responsibilities:
- Make **minimal, safe, testable changes**
- Keep the system **auditable and explainable**
- Preserve **schema stability** (especially 40-column lifecycle logs)
- Follow **deterministic, reproducible** development practices
- Never introduce regressions or break existing functionality

---

## Golden Rules (Non-negotiable)

### 1. Minimal Diffs Only
- No large rewrites or refactors unless explicitly requested
- Change only what's necessary to fulfill the requirement
- Preserve existing code structure and patterns
- If a function works, don't "improve" it unnecessarily

### 2. No New Strategies
- Only implement strategies that exist in PROJECT_SPEC.md
- Don't add "clever" optimizations or ML features
- The system is deterministic by design—keep it that way

### 3. Explainability First
- Every trading decision must be auditable
- Log: reason + score + gating info
- No "black box" logic
- Comments should explain *why*, not *what*

### 4. Never Break Schema
- **40-column lifecycle log schema is sacred**
- Column order must remain stable across all event types
- Use empty placeholders, never remove columns
- Events: SIGNAL, REJECT, ROUTER, ENTER, MANAGE, CLOSE
- Any schema change requires explicit approval and migration plan

### 5. No False Claims
- Never claim tests were executed unless you actually ran them
- Show actual output, not hypothetical results
- Be honest about limitations and unknowns

### 6. Every Response Must Include
For every code change, provide:
1. **Files/functions changed** (list with line numbers)
2. **Unified diff patch** (clear before/after)
3. **Test checklist** (how to verify the change works)
4. **Breaking changes** (if any, with migration path)

---

## Project Overview

### What is TrapSniperPro?

TrapSniperPro is an **automated trading system** that integrates with MetaTrader 5 (MT5) to execute trading strategies with:
- Deterministic, explainable decision-making
- Replay/backtest capabilities before live trading
- Complete audit trails with lifecycle logging
- Sophisticated risk management (prop-style limits)
- Real-time dashboards for performance monitoring

### Core Philosophy

```
App = Brain (analysis, decision-making, replay)
MT5 = Executor (order routing, fills, exchange interaction)
```

The application makes all decisions. MT5 only executes commands and reports results.

### Project Status

**Current Phase:** Phase 0 (Documentation complete, implementation pending)

The project has comprehensive architectural documentation but no code implementation yet. Your work will likely involve building the foundation from scratch following the specs.

---

## Codebase Structure

### Current Structure
```
mt5-achraf/
├── docs/                      # ✓ Complete documentation
│   ├── CLAUDE.md             # This file (AI assistant guide)
│   ├── PROJECT_SPEC.md       # Requirements and scope
│   └── ARCHITECTURE.md       # System design and architecture
├── README.md                 # ⚠️ Minimal (needs expansion)
└── .git/                     # Git repository
```

### Target Structure (To Be Implemented)
```
mt5-achraf/
├── backend/                  # Python FastAPI application
│   ├── app/
│   │   ├── main.py          # FastAPI entry point
│   │   ├── core/            # Core business logic
│   │   │   ├── data_service.py       # OHLC data loading
│   │   │   ├── replay_engine.py     # Bar-by-bar replay
│   │   │   ├── market_snapshot.py   # Spread, ATR, volatility
│   │   │   ├── regime_engine.py     # Market regime detection
│   │   │   ├── protection_engine.py # GREEN/YELLOW/RED gates
│   │   │   ├── risk_engine.py       # Prop-style risk limits
│   │   │   ├── strategy_engine.py   # Candidate generation
│   │   │   ├── soft_scoring.py      # Score + penalty calculation
│   │   │   ├── router.py            # Winner selection
│   │   │   ├── execution_engine.py  # Order execution
│   │   │   ├── trade_manager.py     # BE move, trail, exits
│   │   │   ├── lifecycle_logger.py  # 40-column event logs
│   │   │   └── metrics_engine.py    # Analytics and reporting
│   │   ├── strategies/       # Strategy implementations
│   │   │   ├── trap_sniper.py
│   │   │   ├── trap_lite.py
│   │   │   ├── breakout.py
│   │   │   └── mean_reversion.py
│   │   ├── api/              # REST API routes
│   │   │   ├── datasets.py   # Upload and manage datasets
│   │   │   ├── replay.py     # Replay control endpoints
│   │   │   ├── trades.py     # Trade queries
│   │   │   ├── metrics.py    # Analytics endpoints
│   │   │   └── live.py       # Live trading control
│   │   ├── models/           # Data models (Pydantic)
│   │   ├── db/               # Database layer
│   │   └── utils/            # Helper functions
│   ├── tests/                # Backend tests
│   ├── requirements.txt      # Python dependencies
│   └── .env.example          # Environment template
│
├── frontend/                 # Next.js React dashboard
│   ├── app/                  # Next.js 13+ app directory
│   │   ├── page.tsx          # Home/Overview
│   │   ├── replay/           # Replay runner page
│   │   ├── trades/           # Trades table
│   │   ├── rejects/          # Reject analysis
│   │   ├── execution/        # Execution quality
│   │   └── protection/       # Protection frequency
│   ├── components/           # Reusable React components
│   ├── lib/                  # Utilities and API client
│   ├── public/               # Static assets
│   ├── package.json          # Node dependencies
│   └── tailwind.config.js    # Tailwind CSS config
│
├── mql5/                     # MT5 Expert Advisor
│   ├── experts/
│   │   └── AppExecutorEA.mq5 # Main executor EA
│   ├── include/              # MQL5 libraries
│   └── files/                # CSV queue (git-ignored)
│       ├── commands.csv      # App → MT5 commands
│       └── receipts.csv      # MT5 → App receipts
│
├── tools/                    # Utilities and scripts
│   ├── analyze_trapsniper_csv_FINAL.py
│   └── data_converters/      # OHLC format converters
│
├── docs/                     # Documentation
│   ├── CLAUDE.md            # This file
│   ├── PROJECT_SPEC.md      # Requirements
│   ├── ARCHITECTURE.md      # System design
│   ├── CSV_GUIDE.md         # (To be created) CSV schemas
│   └── USER_GUIDE.md        # (To be created) End-user docs
│
├── .gitignore               # Git ignore rules
├── README.md                # Project overview
└── docker-compose.yml       # (Optional) Development environment
```

---

## Technology Stack

### Backend
| Technology | Purpose | Notes |
|-----------|---------|-------|
| **Python 3.11+** | Primary language | Type hints required |
| **FastAPI** | Web framework | Async/await patterns |
| **pandas** | OHLC data manipulation | Bar-by-bar operations |
| **numpy** | Numerical calculations | ATR, volatility, regime |
| **SQLite** | Database (MVP) | Lifecycle logs, trades |
| **PostgreSQL** | Database (production) | Future migration |
| **pydantic** | Data validation | All API models |
| **pytest** | Testing framework | >80% coverage target |

### Frontend
| Technology | Purpose | Notes |
|-----------|---------|-------|
| **Next.js 14+** | React framework | App router (not pages) |
| **TypeScript** | Type safety | Strict mode enabled |
| **Tailwind CSS** | Styling | Utility-first approach |
| **shadcn/ui** | Component library | Accessible components |
| **Recharts** | Charting | Equity curves, metrics |
| **React Query** | State management | Server state caching |

### MT5 Integration
| Technology | Purpose | Notes |
|-----------|---------|-------|
| **MQL5** | EA language | Compile with MetaEditor |
| **CSV File Queue** | App ↔ MT5 bridge | Recommended for MVP |
| **MetaTrader5 (Python)** | Alternative integration | Direct Python → MT5 |

### Development Tools
| Tool | Purpose |
|------|---------|
| **black** | Python code formatting |
| **flake8** | Python linting |
| **mypy** | Static type checking |
| **eslint** | TypeScript linting |
| **prettier** | Frontend formatting |

---

## Development Workflow

### Git Workflow

**Branch Strategy:**
- Development branch: `claude/claude-md-mkgsis83biveyb4g-4tjXf`
- ⚠️ **NEVER push to main/master directly**
- ⚠️ **All pushes must go to the Claude-prefixed branch**

**Git Commands:**
```bash
# Always push to the feature branch
git push -u origin claude/claude-md-mkgsis83biveyb4g-4tjXf

# If network errors occur, retry up to 4 times with exponential backoff
# (2s, 4s, 8s, 16s)

# Fetch specific branches
git fetch origin claude/claude-md-mkgsis83biveyb4g-4tjXf
```

**Commit Message Format:**
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

Examples:
- `feat(replay): implement bar-by-bar replay engine`
- `fix(risk): correct daily loss limit calculation`
- `docs(csv): add command protocol schema`

### Making Changes

1. **Read the relevant docs first**
   - Check PROJECT_SPEC.md for requirements
   - Check ARCHITECTURE.md for design decisions
   - Check existing code for patterns

2. **Plan before coding**
   - Understand what needs to change
   - Identify affected files
   - Consider schema implications

3. **Implement minimally**
   - Change only what's necessary
   - Follow existing patterns
   - Add type hints (Python) or types (TypeScript)

4. **Test your changes**
   - Run existing tests
   - Add new tests if needed
   - Verify manually if applicable

5. **Document your changes**
   - Update relevant docs if behavior changes
   - Add comments for complex logic
   - Update CHANGELOG if exists

### Code Review Checklist

Before considering a change complete:
- [ ] Compiles/runs without errors
- [ ] Tests pass (or new tests added)
- [ ] Schema unchanged (or migration provided)
- [ ] Type hints/types complete
- [ ] No new dependencies without justification
- [ ] Docs updated if behavior changed
- [ ] Git commit follows format
- [ ] Ready for code review

---

## Key Conventions

### 1. Lifecycle Logging (Critical!)

**40-Column Schema** - This is the most important convention in the codebase.

All lifecycle events must emit **exactly 40 columns in this exact order**:

```
timestamp, event_type, bar_idx, symbol, timeframe,
protection_mode, reason, strategy, regime, regime_confidence,
signal_direction, signal_entry, signal_sl, signal_tp, signal_score,
risk_multiplier, risk_pct_final, lot_size, spread_pts, spread_atr_ratio,
atr_spike_ratio, cooldown_active, daily_loss, weekly_loss, monthly_loss,
trades_today, open_positions, reject_code, router_winner, router_score,
ticket, action, entry_price, exit_price, sl, tp, pnl, pnl_r,
retries, auto_adjusted
```

**Event Types:**
- `SIGNAL`: Strategy generates a candidate
- `REJECT`: Gating rejects the candidate (with reject_code)
- `ROUTER`: Router selects winner from candidates
- `ENTER`: Execution enters a position
- `MANAGE`: Trade management action (BE move, trail)
- `CLOSE`: Position closes with outcome

**Rules:**
- Empty values must be placeholders (empty string or 0), never null
- Column order never changes
- Adding columns requires schema version bump
- All events share the same schema (use placeholders for unused fields)

### 2. Decision Pipeline (Deterministic)

Every trading decision follows this exact sequence:

```
1. Market Snapshot
   ↓ (spread, ATR, session detection)

2. Protection Mode
   ↓ (GREEN/YELLOW/RED based on thresholds)

3. Risk Engine
   ↓ (daily/weekly/monthly limits + cooldown)

4. Regime Detection
   ↓ (TREND_UP/TREND_DOWN/RANGE/CHOP/VOLATILE)

5. Strategy Candidates
   ↓ (TrapSniper, TrapLite, Breakout, MeanReversion)

6. Soft Scoring
   ↓ (rawScore - penalty = adjustedScore)

7. Router Selection
   ↓ (winner + anti-starvation fairness)

8. Execution Gate
   ↓ (SIM mode or MT5 commands.csv)

9. Trade Management
   ↓ (BE move, trail, time exit)

10. Close + Log
    ↓ (outcome + metrics update)
```

**Never skip steps. Never reorder. This is the contract.**

### 3. CSV Communication Protocol

**commands.csv** (App → MT5):
```csv
cmd_id,timestamp,symbol,action,lot,sl,tp,magic,comment,ttl_sec
10001,2026-01-16 10:22:05,XAUUSD,BUY,0.10,2435.10,2441.50,4400000,TrapSniper:78.2,15
```

**receipts.csv** (MT5 → App):
```csv
cmd_id,status,ticket,retcode,fill_price,retries,auto_adjusted,adjust_reason,message
10001,FILLED,123456,10009,2437.20,1,0,,Order filled
```

### 4. Protection Thresholds

```python
# GREEN: Normal trading allowed
# YELLOW: Warning, reduced risk
# RED: No new entries, close existing

thresholds = {
    "spread_pts": {"GREEN": 0.30, "RED": 0.80},
    "spread_atr_ratio": {"GREEN": 0.20, "RED": 0.50},
    "atr_spike_ratio": {"GREEN": 2.0, "RED": 3.0}
}
```

### 5. Risk Limits (Prop-Style)

```python
risk_limits = {
    "daily_loss_pct": 2.0,      # Max 2% daily loss
    "weekly_loss_pct": 5.0,     # Max 5% weekly loss
    "monthly_dd_pct": 10.0,     # Max 10% monthly drawdown
    "max_trades_per_day": 10,    # Hard limit
    "max_open_positions": 3,     # Concurrent trades
    "cooldown_after_losses": 3,  # Consecutive losses trigger cooldown
    "cooldown_duration_bars": 20 # Bars to wait after cooldown
}
```

### 6. Code Style

**Python:**
- Use `black` formatter (line length 100)
- Type hints required on all functions
- Docstrings for public functions (Google style)
- No `import *`
- Prefer composition over inheritance

```python
def calculate_atr(
    high: pd.Series,
    low: pd.Series,
    close: pd.Series,
    period: int = 14
) -> pd.Series:
    """Calculate Average True Range.

    Args:
        high: High prices series
        low: Low prices series
        close: Close prices series
        period: ATR period (default 14)

    Returns:
        ATR series with same index as input
    """
    tr = pd.DataFrame({
        'hl': high - low,
        'hc': (high - close.shift(1)).abs(),
        'lc': (low - close.shift(1)).abs()
    }).max(axis=1)

    return tr.rolling(window=period).mean()
```

**TypeScript:**
- Use `prettier` formatter
- Strict mode enabled
- Interfaces for data structures
- Functional components with hooks
- No `any` types (use `unknown` if needed)

```typescript
interface Trade {
  timestamp: string;
  symbol: string;
  action: 'BUY' | 'SELL';
  entry_price: number;
  exit_price: number;
  pnl: number;
  pnl_r: number;
  strategy: string;
}

const TradesList: React.FC<{ trades: Trade[] }> = ({ trades }) => {
  return (
    <div className="trades-container">
      {trades.map((trade, idx) => (
        <TradeCard key={idx} trade={trade} />
      ))}
    </div>
  );
};
```

**MQL5:**
- Follow MT5 naming conventions
- Input parameters at top
- Error handling for all order operations
- Log all retcodes

```mql5
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("AppExecutorEA initialized - Magic: ", MAGIC_NUMBER);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Execute buy order from command                                   |
//+------------------------------------------------------------------+
bool ExecuteBuyOrder(string symbol, double lot, double sl, double tp, int cmdId)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};

   request.action = TRADE_ACTION_DEAL;
   request.symbol = symbol;
   request.volume = lot;
   request.sl = sl;
   request.tp = tp;
   request.type = ORDER_TYPE_BUY;
   request.magic = MAGIC_NUMBER;

   if(!OrderSend(request, result))
   {
      LogReceipt(cmdId, "REJECTED", 0, result.retcode, 0.0, 0, false, "", result.comment);
      return false;
   }

   LogReceipt(cmdId, "FILLED", result.order, result.retcode, result.price, 0, false, "", "Success");
   return true;
}
```

---

## Testing & Quality

### Testing Strategy

**Phase A: Static Checks**
- Compile MQL5 EA with zero errors
- Python type checking with mypy
- Linting with flake8/eslint
- Format checking with black/prettier

**Phase B: Replay Validation**
- Run replay on historical datasets
- Verify metrics consistency across runs
- Verify lifecycle logs stable (40 columns)
- Check decision reproducibility

**Phase C: Demo Live Validation**
- Connect to demo account
- Run 1-2 days minimum
- Compare execution slippage and retcodes
- Monitor protection mode frequency

**Phase D: Production Readiness**
- 1+ month stable demo run
- All safety stops tested
- Kill switch verified
- Only then consider small live risk

### Test Coverage Requirements

- **Backend:** Aim for >80% coverage
- **Critical paths:** 100% coverage required
  - Risk engine calculations
  - Protection mode gating
  - Lifecycle logging
  - CSV protocol parsing
- **Frontend:** Component tests for critical UI
- **MQL5:** Manual testing in Strategy Tester

### Quality Gates

A change is accepted **only if**:
- ✅ Compiles (EA) or runs (Python/TypeScript)
- ✅ Existing tests pass
- ✅ New tests added for new functionality
- ✅ Schema remains stable (or migration provided)
- ✅ Metrics are consistent with previous run
- ✅ No new regressions introduced
- ✅ Docs updated if behavior changed

---

## Development Phases

### Phase 0: Foundation (Current)
**Status:** Documentation complete, implementation pending

**Deliverables:**
- ✅ PROJECT_SPEC.md
- ✅ ARCHITECTURE.md
- ✅ CLAUDE.md
- ⏳ CSV_GUIDE.md (to be created)
- ⏳ Setup backend/frontend scaffolding

### Phase 1: Replay + Metrics
**Goal:** Build the decision engine and validate with replay

**Tasks:**
1. Setup Python FastAPI backend structure
2. Implement data_service (OHLC loading)
3. Implement replay_engine (bar-by-bar)
4. Implement market_snapshot (spread, ATR)
5. Implement protection_engine (GREEN/YELLOW/RED)
6. Implement risk_engine (prop-style limits)
7. Implement regime_engine (trend/range detection)
8. Implement strategy_engine (TrapSniper + others)
9. Implement soft_scoring (score + penalty)
10. Implement router (winner selection)
11. Implement lifecycle_logger (40-column CSV)
12. Implement metrics_engine (analytics)
13. Create API endpoints (replay, metrics)
14. Build frontend dashboard (Next.js)
15. Test replay with historical data

**Definition of Done:**
- Replay runs from OHLC CSV input
- Lifecycle logs output with stable 40-column schema
- Metrics API returns trades, winrate, profit factor
- Dashboard displays equity curve and trade table
- Reproducible results across multiple runs

### Phase 2: MT5 Execution Bridge
**Goal:** Connect to MT5 for real execution

**Tasks:**
1. Implement CSV command generator
2. Create commands.csv protocol writer
3. Build MT5 Executor EA (MQL5)
4. Implement receipts.csv parser
5. Add execution_engine (retry + auto-adjust logic)
6. Implement trade_manager (BE move, trail)
7. Add live API endpoints (start/stop/status)
8. Test in MT5 Strategy Tester
9. Test on demo account

**Definition of Done:**
- App generates commands.csv
- MT5 EA reads and executes commands
- MT5 EA writes receipts.csv
- App reads receipts and updates trade state
- Lifecycle logs include ENTER/MANAGE/CLOSE events
- Retcodes tracked and reported
- Demo account test runs successfully

### Phase 3: Live Demo Hardening
**Goal:** Stability, monitoring, and safety validation

**Tasks:**
1. Add kill switch to dashboard
2. Implement alert system (loss limits breached)
3. Add execution quality monitoring
4. Test all safety stops (daily/weekly/monthly limits)
5. Test cooldown logic
6. Run extended demo (1+ week)
7. Compare replay vs demo execution metrics
8. Fix any slippage or execution issues

**Definition of Done:**
- 1+ week stable demo run
- All safety stops verified
- Kill switch works instantly
- Alerts trigger correctly
- Execution quality acceptable (retries, slippage)
- Ready for small live risk

---

## Common Tasks

### Task: Add a New Strategy

**Prerequisites:**
- Strategy defined in PROJECT_SPEC.md
- Strategy logic is deterministic
- Strategy outputs standard candidate format

**Steps:**
1. Create `backend/app/strategies/new_strategy.py`
2. Implement candidate generation function:
```python
def generate_new_strategy_candidates(
    snapshot: MarketSnapshot,
    regime: Regime,
    risk_pct: float
) -> List[Candidate]:
    """Generate candidates for NewStrategy.

    Returns list of candidates with:
    - direction (BUY/SELL)
    - entry_price
    - sl_price
    - tp_price
    - raw_score
    - reason (explainability string)
    """
    candidates = []
    # ... logic here
    return candidates
```
3. Register strategy in `strategy_engine.py`
4. Add tests in `tests/test_new_strategy.py`
5. Run replay and verify lifecycle logs include new strategy
6. Update docs if user-facing

### Task: Add a New Reject Code

**Prerequisites:**
- Reject reason is clear and actionable
- Fits into existing protection/risk gating

**Steps:**
1. Add reject code constant in `backend/app/core/constants.py`:
```python
REJECT_VOLATILITY_SPIKE = "VOLATILITY_SPIKE"
```
2. Implement gating logic in relevant engine (protection/risk)
3. Log REJECT event with new code
4. Update CSV_GUIDE.md with new reject code definition
5. Add test case for new reject scenario
6. Run replay and verify reject appears in logs

### Task: Modify the 40-Column Schema

**⚠️ WARNING: This is a breaking change!**

**Prerequisites:**
- Explicit approval from user/team
- Migration plan for existing logs
- Schema version bump

**Steps:**
1. **Stop!** Are you absolutely sure this is necessary?
2. Document the reason for schema change
3. Create migration script for old logs
4. Update lifecycle_logger.py
5. Update CSV_GUIDE.md with schema version
6. Update all parsers and readers
7. Test migration on sample data
8. Run full replay and verify new schema
9. Update dashboard to handle new columns
10. Document breaking change in CHANGELOG

### Task: Debug a Replay Issue

**Steps:**
1. Enable verbose logging
2. Run replay on small dataset (10-100 bars)
3. Check lifecycle logs for anomalies
4. Verify decision pipeline sequence
5. Check for NaN or inf values in calculations
6. Verify timestamp alignment
7. Compare with previous working replay
8. Add test case to prevent regression

### Task: Test MT5 Integration

**Steps:**
1. Compile AppExecutorEA.mq5 in MetaEditor
2. Attach EA to MT5 Strategy Tester
3. Place test commands.csv in MQL5/Files/
4. Run Strategy Tester
5. Verify receipts.csv generated
6. Check retcodes and error messages
7. Test on demo account if tester passes
8. Monitor for 1+ hour minimum

---

## Troubleshooting

### Common Issues

**Issue: Schema validation fails**
- Check column count is exactly 40
- Verify column order matches specification
- Ensure no null values (use placeholders)
- Check for extra commas or quotes in CSV

**Issue: Replay not reproducible**
- Verify timestamp sorting is consistent
- Check for random number generation (should be seeded)
- Ensure regime detection is deterministic
- Verify ATR/spread calculations match previous

**Issue: MT5 EA not reading commands**
- Check file path is MQL5/Files/ (not MT5/Files/)
- Verify CSV format (no BOM, UTF-8 encoding)
- Check ttl_sec hasn't expired
- Ensure EA is attached and running

**Issue: Risk limits not working**
- Check risk_engine.py calculations
- Verify daily/weekly/monthly tracking
- Ensure timezone consistency
- Check cooldown logic

**Issue: Protection mode stuck in RED**
- Check spread and ATR threshold calculations
- Verify market data is recent
- Check for ATR spike calculation errors
- Review protection_engine logic

---

## Resources

### Key Files to Reference
- **PROJECT_SPEC.md**: Requirements, scope, MVP phases
- **ARCHITECTURE.md**: System design, component breakdown
- **CSV_GUIDE.md**: (To be created) Detailed CSV schemas
- **CLAUDE.md**: This file (AI assistant guide)

### External Documentation
- [MetaTrader 5 MQL5 Docs](https://www.mql5.com/en/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Next.js Documentation](https://nextjs.org/docs)
- [pandas Documentation](https://pandas.pydata.org/docs/)

### Contact & Support
- For questions about requirements: Check PROJECT_SPEC.md first
- For architecture decisions: Check ARCHITECTURE.md first
- For git workflow: See Development Workflow section above
- For breaking changes: Always ask user approval first

---

## Summary: What Makes a Good Change?

A good change is:
✅ **Minimal** - Only touches what's necessary
✅ **Tested** - Includes tests and verification steps
✅ **Documented** - Updates relevant docs
✅ **Explainable** - Clear reasoning and design
✅ **Schema-safe** - Preserves lifecycle log structure
✅ **Deterministic** - Reproducible results
✅ **Auditable** - Decision trails maintained

A bad change is:
❌ Large refactors without request
❌ "Clever" optimizations that add complexity
❌ Schema modifications without approval
❌ Adding features not in spec
❌ Claiming tests passed without running them
❌ Breaking existing functionality
❌ Non-deterministic behavior

---

**Remember:** This is a market-grade trading system. Lives and money are not at stake in the traditional sense, but the system must be rock-solid, auditable, and trustworthy. Treat every change with the seriousness it deserves.

**When in doubt, ask. When unsure, test. When tempted to refactor, don't.**
