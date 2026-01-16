# File Bridge Protocol — Commands & Receipts

## Overview
This document defines the file-based communication protocol between the **App (Brain)** and the **MT5 Executor EA (Bridge)**.

**Integration Method:** File Queue Bridge (No HTTP)
- APP writes: `MQL5/Files/commands.csv`
- MT5 EA reads, executes, and writes: `MQL5/Files/receipts.csv`
- APP reads receipts and updates trade state

---

## 1) Commands File Format

### File Location
```
<MT5_DATA_FOLDER>/MQL5/Files/commands.csv
```

Typical paths:
- **Windows**: `C:\Users\<Username>\AppData\Roaming\MetaQuotes\Terminal\<ID>\MQL5\Files\commands.csv`
- **Wine/Linux**: `~/.wine/drive_c/users/<user>/AppData/Roaming/MetaQuotes/Terminal/<ID>/MQL5/Files/commands.csv`

### CSV Structure
```csv
cmd_id,timestamp,symbol,action,lot,sl,tp,magic,comment,ttl_sec
```

### Field Definitions

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `cmd_id` | int | YES | Unique command identifier | `10001` |
| `timestamp` | datetime | YES | Command generation time (UTC or local) | `2026-01-16 10:22:05` |
| `symbol` | string | YES | Trading symbol | `XAUUSD`, `EURUSD` |
| `action` | string | YES | Order action: `BUY`, `SELL`, `CLOSE` | `BUY` |
| `lot` | double | YES | Position size in lots | `0.10` |
| `sl` | double | NO | Stop Loss price (0 = none) | `2435.10` |
| `tp` | double | NO | Take Profit price (0 = none) | `2441.50` |
| `magic` | int | YES | Magic number (must match EA setting) | `4400000` |
| `comment` | string | NO | Order comment (for explainability) | `TrapSniper:78.2` |
| `ttl_sec` | int | NO | Time-to-live in seconds (0 = no expiry) | `15` |

### Example Commands

#### Open BUY position
```csv
10001,2026-01-16 10:22:05,XAUUSD,BUY,0.10,2435.10,2441.50,4400000,TrapSniper:78.2,15
```

#### Open SELL position
```csv
10002,2026-01-16 10:25:30,EURUSD,SELL,0.20,1.0950,1.0920,4400000,Breakout:NY,20
```

#### Close all positions for symbol
```csv
10003,2026-01-16 10:30:00,XAUUSD,CLOSE,0,0,0,4400000,ProtectionClose,10
```

### Action Types

| Action | Description | Required Fields |
|--------|-------------|-----------------|
| `BUY` | Open long position | symbol, lot, sl (optional), tp (optional) |
| `SELL` | Open short position | symbol, lot, sl (optional), tp (optional) |
| `CLOSE` | Close all positions matching symbol + magic | symbol, magic |

### TTL (Time-To-Live) Behavior
- If `ttl_sec > 0`: EA checks command age = `TimeCurrent() - timestamp`
- If `age > ttl_sec`: Command is marked as `EXPIRED` and skipped
- If `ttl_sec = 0`: No expiration check (command stays valid)

**Recommended TTL values:**
- Fast scalping: `5-10 seconds`
- Normal trading: `15-30 seconds`
- Position management: `60-120 seconds`

---

## 2) Receipts File Format

### File Location
```
<MT5_DATA_FOLDER>/MQL5/Files/receipts.csv
```

### CSV Structure
```csv
cmd_id,status,ticket,retcode,fill_price,message
```

### Field Definitions

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `cmd_id` | int | Matching command ID | `10001` |
| `status` | string | Execution status: `FILLED`, `REJECTED`, `EXPIRED`, `ERROR` | `FILLED` |
| `ticket` | int | Broker ticket number (0 if not filled) | `123456` |
| `retcode` | int | MT5 retcode (see MT5 documentation) | `10009` |
| `fill_price` | double | Actual fill price (0 if not filled) | `2437.20` |
| `message` | string | Human-readable message or error description | `OK` |

### Example Receipts

#### Successful BUY order
```csv
10001,FILLED,123456,10009,2437.20,OK
```

#### Rejected order (insufficient margin)
```csv
10002,REJECTED,0,10019,0.0,Retcode: 10019 - Insufficient funds
```

#### Expired command
```csv
10003,EXPIRED,0,0,0.0,Command expired (age: 45s, TTL: 15s)
```

#### Close action successful
```csv
10004,FILLED,0,10009,0.0,Closed 2 position(s)
```

#### Error (symbol not available)
```csv
10005,ERROR,0,0,0.0,Symbol not found or not available: XAUUSD
```

### Status Types

| Status | Description | When Used |
|--------|-------------|-----------|
| `FILLED` | Order executed successfully | Retcode = 10009 (DONE) |
| `REJECTED` | Order rejected by broker | Invalid parameters, no money, market closed |
| `EXPIRED` | Command TTL expired before execution | Age > TTL |
| `ERROR` | System error (not broker rejection) | Symbol not found, file errors, invalid action |

### Common MT5 Retcodes

| Retcode | Constant | Description |
|---------|----------|-------------|
| 10004 | TRADE_RETCODE_REQUOTE | Requote |
| 10006 | TRADE_RETCODE_REJECT | Request rejected |
| 10007 | TRADE_RETCODE_CANCEL | Request canceled by trader |
| 10008 | TRADE_RETCODE_PLACED | Order placed |
| 10009 | TRADE_RETCODE_DONE | Request completed |
| 10010 | TRADE_RETCODE_DONE_PARTIAL | Only partial filled |
| 10011 | TRADE_RETCODE_ERROR | Request processing error |
| 10013 | TRADE_RETCODE_INVALID | Invalid request |
| 10014 | TRADE_RETCODE_INVALID_VOLUME | Invalid volume |
| 10015 | TRADE_RETCODE_INVALID_PRICE | Invalid price |
| 10016 | TRADE_RETCODE_INVALID_STOPS | Invalid SL or TP |
| 10017 | TRADE_RETCODE_TRADE_DISABLED | Trading disabled |
| 10018 | TRADE_RETCODE_MARKET_CLOSED | Market closed |
| 10019 | TRADE_RETCODE_NO_MONEY | Insufficient funds |
| 10020 | TRADE_RETCODE_PRICE_CHANGED | Price changed |
| 10021 | TRADE_RETCODE_PRICE_OFF | No prices |
| 10027 | TRADE_RETCODE_INVALID_FILL | Invalid order filling type |
| 10028 | TRADE_RETCODE_CONNECTION | No connection with trade server |

Full list: [MQL5 Documentation - Trade Server Return Codes](https://www.mql5.com/en/docs/constants/errorswarnings/enum_trade_return_codes)

---

## 3) Integration Flow

### Step-by-Step Execution Flow

```
1. APP generates trading decision
   ↓
2. APP writes command to commands.csv
   ↓
3. MT5 EA reads commands.csv (every N seconds)
   ↓
4. EA validates:
   - cmd_id not already processed
   - TTL not expired
   - magic number matches
   ↓
5. EA executes order via OrderSend()
   ↓
6. EA writes receipt to receipts.csv
   ↓
7. APP reads receipts.csv
   ↓
8. APP updates trade state and logs
   ↓
9. APP archives or clears processed commands
```

### Duplicate Prevention
- EA maintains an in-memory array of processed `cmd_id` values
- If a command is seen again, it's skipped with debug log: `"Command X already processed"`
- Array size is configurable (default: 10,000 commands)
- When full, oldest entries are removed (FIFO)

### File Handling Best Practices

#### APP Side (Python)
```python
import csv
import os
from datetime import datetime

def write_command(cmd_id, symbol, action, lot, sl, tp, magic, comment, ttl_sec):
    commands_file = "/path/to/MQL5/Files/commands.csv"

    # Check if file exists to write header
    write_header = not os.path.exists(commands_file)

    with open(commands_file, 'a', newline='') as f:
        writer = csv.writer(f)

        if write_header:
            writer.writerow(['cmd_id', 'timestamp', 'symbol', 'action',
                           'lot', 'sl', 'tp', 'magic', 'comment', 'ttl_sec'])

        writer.writerow([cmd_id, datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                        symbol, action, lot, sl, tp, magic, comment, ttl_sec])

def read_receipts():
    receipts_file = "/path/to/MQL5/Files/receipts.csv"

    if not os.path.exists(receipts_file):
        return []

    with open(receipts_file, 'r') as f:
        reader = csv.DictReader(f)
        return list(reader)
```

#### EA Side (MQL5)
- Use `FileOpen()` with `FILE_CSV` flag
- Always close files with `FileClose()`
- Check for `INVALID_HANDLE`
- Skip header line if present
- Use `FileIsEnding()` for line iteration

---

## 4) Error Handling

### APP Responsibilities
- Validate command before writing (symbol exists, lot > 0, valid action)
- Set appropriate TTL based on market conditions
- Monitor receipts file regularly
- Handle missing or delayed receipts (retry logic)
- Archive processed commands to prevent file bloat

### EA Responsibilities
- Validate all fields before execution
- Write receipt for EVERY command (even errors)
- Use multiple fill modes (FOK → IOC → RETURN)
- Log errors to MT5 expert log
- Never crash on malformed CSV lines

### Timeout Scenarios

| Scenario | APP Action | EA Action |
|----------|------------|-----------|
| Receipt not received within 2x TTL | Retry command with new cmd_id | Continue processing |
| Command expired before EA read | Mark as stale in APP logs | Write EXPIRED receipt |
| Broker connection lost | Queue commands for later | Write ERROR receipt with retcode 10028 |
| Symbol not available | Don't write command | Write ERROR receipt |

---

## 5) Security & Safety

### Magic Number Isolation
- Each EA instance MUST have a unique magic number
- EA rejects commands with mismatched magic
- Prevents cross-contamination between strategies

### File Permissions
- Ensure MQL5/Files directory is writable by APP
- On Linux/Wine, check folder permissions
- Test write access before going live

### Atomic Operations
- EA reads entire command before execution
- EA writes receipt atomically (single FileWrite call)
- APP should use file locking if writing from multiple threads

### Command Cleanup
- APP should periodically archive old commands
- Recommended: Move processed commands to `commands_archive.csv`
- EA processes sequentially, so order is preserved

---

## 6) Testing Checklist

### Unit Tests (APP)
- [ ] Write valid BUY command
- [ ] Write valid SELL command
- [ ] Write CLOSE command
- [ ] Read receipts correctly
- [ ] Handle missing receipts file
- [ ] Parse all receipt statuses

### Unit Tests (EA)
- [ ] Read valid commands.csv
- [ ] Skip duplicate cmd_id
- [ ] Reject expired commands (TTL)
- [ ] Reject mismatched magic
- [ ] Write receipt for each command
- [ ] Handle malformed CSV lines gracefully

### Integration Tests
- [ ] APP writes command → EA executes → APP reads receipt
- [ ] Multiple commands in sequence
- [ ] Expired command handling
- [ ] Close command closes correct positions
- [ ] Retcode handling (test on demo)

### Stress Tests
- [ ] 1000+ commands in single file
- [ ] Concurrent APP writes (if applicable)
- [ ] EA restart mid-execution
- [ ] File corruption recovery

---

## 7) Future Enhancements (Post-MVP)

### Possible Improvements
- Binary protocol (faster, more compact)
- HTTP REST API (remove file dependency)
- WebSocket real-time streaming
- Command versioning (protocol v2, v3)
- Batch receipts (multiple receipts per write)
- Encryption (if running over network filesystem)

### Backward Compatibility
- Any protocol changes MUST be versioned
- EA should support multiple protocol versions
- APP should detect EA protocol version

---

## Summary
- **Simple:** CSV files, human-readable
- **Reliable:** TTL, duplicate prevention, retries
- **Safe:** Magic number isolation, validation
- **Auditable:** Full command/receipt history
- **Testable:** Easy to mock and simulate

This protocol is designed for **MVP simplicity** while maintaining **production-grade reliability**.
