# Testing Guide — MT5 Executor EA & AutoTrading Platform

## Overview
This document provides comprehensive testing procedures for the **MT5 Executor EA (Bridge)** and the full **AutoTrading Platform**.

**Testing Philosophy:**
- Test small, test often
- Always test on **demo account** first
- Document all test results
- Never skip safety tests

---

## Test Levels

1. **Static Tests** - Code compilation and validation
2. **Unit Tests** - Individual components in isolation
3. **Integration Tests** - APP + EA communication
4. **Strategy Tester Tests** - MT5 offline simulation
5. **Demo Account Tests** - Real broker environment (demo)
6. **Stress Tests** - High load and edge cases
7. **Production Readiness** - Final validation before live

---

## Phase 1: MT5 Executor EA Testing

### Static Tests (Compilation)

#### Test 1.1: Compile EA Without Errors

**Steps:**
1. Open MetaEditor (F4 in MT5)
2. Open `AutoTradingExecutor.mq5`
3. Press F7 to compile
4. Check **Errors** tab

**Expected Result:**
```
0 error(s), 0 warning(s)
AutoTradingExecutor.ex5 created successfully
```

**Status:** [ ] PASS / [ ] FAIL

**Notes:**
- If warnings appear, document them
- Warnings are acceptable if not critical

---

#### Test 1.2: Attach EA to Chart

**Steps:**
1. Open any chart (e.g., XAUUSD M1)
2. Drag `AutoTradingExecutor` from Navigator → Expert Advisors
3. Set `MagicNumber = 4400000`
4. Enable "Allow automated trading"
5. Click OK

**Expected Result:**
- EA appears in top-right corner with smiley face 😊
- Experts log shows initialization message:
  ```
  ========================================
  AutoTradingExecutor EA initialized
  Magic Number: 4400000
  ...
  ========================================
  ```

**Status:** [ ] PASS / [ ] FAIL

---

### Unit Tests (File Operations)

#### Test 2.1: Read Valid Command (BUY)

**Preconditions:**
- EA running on chart
- `EnableDebugLogs = true`

**Steps:**
1. Create `MQL5/Files/commands.csv`:
   ```csv
   cmd_id,timestamp,symbol,action,lot,sl,tp,magic,comment,ttl_sec
   10001,2026-01-16 10:00:00,XAUUSD,BUY,0.01,2435.00,2445.00,4400000,TestBuy,300
   ```
2. Wait 3-5 seconds
3. Check Experts log

**Expected Result:**
- Log shows: `Executing command 10001: BUY XAUUSD 0.01 lots`
- `receipts.csv` created with entry:
  ```csv
  cmd_id,status,ticket,retcode,fill_price,message
  10001,FILLED,<ticket>,10009,<price>,OK
  ```
  OR (if market closed):
  ```csv
  10001,REJECTED,0,10018,0.0,Retcode: 10018 - Market closed
  ```

**Status:** [ ] PASS / [ ] FAIL

**Actual Fill Price:** ______________________

**Actual Ticket:** ______________________

---

#### Test 2.2: Read Valid Command (SELL)

**Steps:**
1. Clear `commands.csv` (or append new line):
   ```csv
   10002,2026-01-16 10:05:00,EURUSD,SELL,0.02,1.0950,1.0920,4400000,TestSell,300
   ```
2. Wait 3-5 seconds
3. Check Experts log and `receipts.csv`

**Expected Result:**
- Receipt for `cmd_id=10002` with `status=FILLED` or `REJECTED`

**Status:** [ ] PASS / [ ] FAIL

---

#### Test 2.3: Close Command

**Preconditions:**
- At least one open position exists (from Test 2.1 or 2.2)

**Steps:**
1. Check open positions in MT5 (Toolbox → Trade tab)
2. Note symbol and magic number
3. Create close command:
   ```csv
   10003,2026-01-16 10:10:00,XAUUSD,CLOSE,0,0,0,4400000,TestClose,60
   ```
4. Wait 3-5 seconds

**Expected Result:**
- Position(s) closed
- Receipt shows:
  ```csv
  10003,FILLED,0,10009,0.0,Closed N position(s)
  ```

**Status:** [ ] PASS / [ ] FAIL

**Positions Closed:** ______________________

---

#### Test 2.4: Duplicate Command Prevention

**Steps:**
1. Create command:
   ```csv
   10004,2026-01-16 10:15:00,XAUUSD,BUY,0.01,0,0,4400000,TestDuplicate,300
   ```
2. Wait until receipt appears
3. **Do NOT delete or clear commands.csv**
4. Wait another 10 seconds

**Expected Result:**
- Only **ONE** receipt for `cmd_id=10004`
- Experts log shows: `Command 10004 already processed, skipping`

**Status:** [ ] PASS / [ ] FAIL

---

#### Test 2.5: TTL Expiration

**Steps:**
1. Create command with **short TTL** and **old timestamp**:
   ```csv
   10005,2020-01-01 00:00:00,XAUUSD,BUY,0.01,0,0,4400000,ExpiredTest,10
   ```
2. Wait 3-5 seconds

**Expected Result:**
- Receipt shows:
  ```csv
  10005,EXPIRED,0,0,0.0,Command expired (age: <large>s, TTL: 10s)
  ```

**Status:** [ ] PASS / [ ] FAIL

---

#### Test 2.6: Magic Number Mismatch

**Steps:**
1. Create command with **wrong magic number**:
   ```csv
   10006,2026-01-16 10:20:00,XAUUSD,BUY,0.01,0,0,9999999,WrongMagic,300
   ```
2. Wait 3-5 seconds

**Expected Result:**
- Receipt shows:
  ```csv
  10006,REJECTED,0,0,0.0,Magic number mismatch (expected: 4400000, got: 9999999)
  ```

**Status:** [ ] PASS / [ ] FAIL

---

#### Test 2.7: Invalid Symbol

**Steps:**
1. Create command with **non-existent symbol**:
   ```csv
   10007,2026-01-16 10:25:00,FAKESYM,BUY,0.01,0,0,4400000,InvalidSymbol,300
   ```
2. Wait 3-5 seconds

**Expected Result:**
- Receipt shows:
  ```csv
  10007,ERROR,0,0,0.0,Symbol not found or not available: FAKESYM
  ```

**Status:** [ ] PASS / [ ] FAIL

---

#### Test 2.8: Invalid Action

**Steps:**
1. Create command with **invalid action**:
   ```csv
   10008,2026-01-16 10:30:00,XAUUSD,INVALID,0.01,0,0,4400000,BadAction,300
   ```
2. Wait 3-5 seconds

**Expected Result:**
- Receipt shows:
  ```csv
  10008,ERROR,0,0,0.0,Unknown action: INVALID
  ```

**Status:** [ ] PASS / [ ] FAIL

---

### Integration Tests (Strategy Tester)

#### Test 3.1: Run EA in Strategy Tester

**Purpose:** Test EA offline without broker connection

**Steps:**
1. Open **Strategy Tester** (Ctrl+R or View → Strategy Tester)
2. Select:
   - Expert Advisor: `AutoTradingExecutor`
   - Symbol: `XAUUSD`
   - Period: `M1` (1 minute)
   - Date range: Last 7 days
   - Execution: Every tick
3. In **Inputs** tab, set:
   - `MagicNumber = 4400000`
   - `CheckIntervalSeconds = 1`
   - `EnableDebugLogs = true`
4. Click **Start**

**Expected Result:**
- Tester runs without errors
- EA initializes successfully
- Check **Journal** tab for logs

**Status:** [ ] PASS / [ ] FAIL

**Notes:**
- Strategy Tester uses simulated ticks, not real broker data
- Use this to validate logic without risking real orders

---

#### Test 3.2: Simulate Commands During Strategy Tester

**Note:** Strategy Tester does NOT allow real-time file writes by external apps. This test validates that the EA CAN read commands.csv if it exists before the test starts.

**Steps:**
1. **Before starting tester**, create:
   `MQL5/Files/commands.csv`:
   ```csv
   cmd_id,timestamp,symbol,action,lot,sl,tp,magic,comment,ttl_sec
   20001,2026-01-15 10:00:00,XAUUSD,BUY,0.01,0,0,4400000,TesterBuy,3600
   ```
2. Run Strategy Tester (same settings as Test 3.1)
3. Check **Journal** tab for execution logs

**Expected Result:**
- EA reads and processes command
- Receipt written to `receipts.csv`

**Status:** [ ] PASS / [ ] FAIL

**Limitations:**
- Commands must be pre-created before tester starts
- Real integration testing requires demo account (next section)

---

### Demo Account Tests (Live Broker)

#### Test 4.1: Execute BUY Order on Demo

**Preconditions:**
- MT5 logged into **demo account**
- Market is open
- Symbol has sufficient margin

**Steps:**
1. Create command:
   ```csv
   30001,<current_timestamp>,XAUUSD,BUY,0.01,0,0,4400000,DemoBuy,60
   ```
   (Replace `<current_timestamp>` with actual time: `YYYY-MM-DD HH:MM:SS`)
2. Wait 3-5 seconds
3. Check:
   - MT5 Toolbox → Trade tab (open positions)
   - `receipts.csv`

**Expected Result:**
- Position opened in MT5 Trade tab
- Receipt shows `status=FILLED` with valid ticket number
- Fill price is close to current market price

**Status:** [ ] PASS / [ ] FAIL

**Fill Price:** ______________________
**Ask Price (at time):** ______________________
**Slippage (pips):** ______________________

---

#### Test 4.2: Execute SELL Order on Demo

**Steps:**
1. Create command:
   ```csv
   30002,<current_timestamp>,EURUSD,SELL,0.02,0,0,4400000,DemoSell,60
   ```
2. Wait 3-5 seconds
3. Verify position opened

**Expected Result:**
- SELL position opened
- Receipt status = FILLED

**Status:** [ ] PASS / [ ] FAIL

---

#### Test 4.3: Close Positions on Demo

**Steps:**
1. Verify at least one position is open (from 4.1 or 4.2)
2. Create close command:
   ```csv
   30003,<current_timestamp>,XAUUSD,CLOSE,0,0,0,4400000,DemoClose,60
   ```
3. Wait 3-5 seconds

**Expected Result:**
- Position closed in MT5
- Receipt shows: `Closed N position(s)`

**Status:** [ ] PASS / [ ] FAIL

---

#### Test 4.4: Multiple Commands in Sequence

**Steps:**
1. Create commands file with 5 commands:
   ```csv
   cmd_id,timestamp,symbol,action,lot,sl,tp,magic,comment,ttl_sec
   40001,<timestamp>,XAUUSD,BUY,0.01,0,0,4400000,Multi1,120
   40002,<timestamp>,EURUSD,SELL,0.01,0,0,4400000,Multi2,120
   40003,<timestamp>,GBPUSD,BUY,0.01,0,0,4400000,Multi3,120
   40004,<timestamp>,XAUUSD,CLOSE,0,0,0,4400000,Multi4,120
   40005,<timestamp>,EURUSD,CLOSE,0,0,0,4400000,Multi5,120
   ```
2. Wait 10-15 seconds

**Expected Result:**
- All 5 commands processed
- 5 receipts in `receipts.csv`
- Positions opened and then closed

**Status:** [ ] PASS / [ ] FAIL

**Receipts Count:** ______________________

---

### Stress Tests

#### Test 5.1: High Volume Commands

**Purpose:** Test EA under load

**Steps:**
1. Generate 100 commands (use script or manual CSV)
2. All with unique `cmd_id`, valid timestamps, TTL=300
3. Mix of BUY/SELL/CLOSE actions
4. Wait 1-2 minutes

**Expected Result:**
- All 100 commands processed (no crashes)
- 100 receipts written
- EA continues running normally

**Status:** [ ] PASS / [ ] FAIL

**Processing Time:** ______________________ seconds

---

#### Test 5.2: Malformed CSV Lines

**Purpose:** Test EA resilience to bad data

**Steps:**
1. Create commands.csv with intentional errors:
   ```csv
   cmd_id,timestamp,symbol,action,lot,sl,tp,magic,comment,ttl_sec
   50001,2026-01-16 10:00:00,XAUUSD,BUY,0.01,0,0,4400000,Valid,300
   INVALID_LINE_HERE,,,,,,,,,
   50002,2026-01-16 10:01:00,EURUSD,SELL,0.01,0,0,4400000,Valid2,300
   ,,,,,,,,,,
   50003,2026-01-16 10:02:00,GBPUSD,BUY,0.01,0,0,4400000,Valid3,300
   ```
2. Wait 10 seconds

**Expected Result:**
- EA does NOT crash
- Valid commands (50001, 50002, 50003) are processed
- Invalid lines skipped with debug log

**Status:** [ ] PASS / [ ] FAIL

---

#### Test 5.3: Rapid Command Updates

**Purpose:** Test file read/write contention

**Steps:**
1. Write a command
2. Immediately (within 1 second) append another command
3. Repeat 10 times
4. Check receipts

**Expected Result:**
- All commands eventually processed
- No file corruption
- No missed commands

**Status:** [ ] PASS / [ ] FAIL

**Notes:**
- If issues occur, increase `CheckIntervalSeconds` or implement file locking in APP

---

### Edge Cases

#### Test 6.1: EA Restart Mid-Execution

**Steps:**
1. Create 10 commands
2. Wait until 5 receipts appear
3. Stop EA (remove from chart)
4. Wait 5 seconds
5. Re-attach EA to chart
6. Wait 10 seconds

**Expected Result:**
- Remaining 5 commands processed
- No duplicate execution of first 5 (due to in-memory tracking limitation)

**Status:** [ ] PASS / [ ] FAIL

**Notes:**
- **Known Limitation:** In-memory `processedCommands` array is cleared on restart
- To prevent duplicates across restarts, APP should archive processed commands

---

#### Test 6.2: File Deletion During Runtime

**Steps:**
1. EA running with commands processed
2. Delete `commands.csv` manually
3. Wait 10 seconds
4. Create new `commands.csv` with new commands
5. Wait 5 seconds

**Expected Result:**
- EA handles missing file gracefully (no crash)
- New commands processed after file reappears

**Status:** [ ] PASS / [ ] FAIL

---

#### Test 6.3: Receipt File Full Disk

**Note:** This is hard to simulate. Document expected behavior.

**Expected Behavior:**
- If disk is full, `FileOpen()` returns `INVALID_HANDLE`
- EA logs error: `"ERROR: Cannot open receipts file for writing"`
- EA continues processing (degrades gracefully)

**Status:** [ ] DOCUMENTED

---

## Phase 2+: Full Integration Tests

*These tests will be added in Phase 2 after APP backend is developed.*

### Future Tests
- APP generates commands → EA executes → APP reads receipts
- Replay mode → command generation → MT5 execution comparison
- Live auto-trading loop stability (1+ day continuous run)
- Execution quality metrics (slippage, retcode distribution)
- Risk engine limits enforcement (max trades/day, daily loss stop)

---

## Test Summary Checklist

### Static Tests
- [ ] 1.1: EA compiles without errors
- [ ] 1.2: EA attaches to chart successfully

### Unit Tests
- [ ] 2.1: Read valid BUY command
- [ ] 2.2: Read valid SELL command
- [ ] 2.3: Close command works
- [ ] 2.4: Duplicate prevention works
- [ ] 2.5: TTL expiration works
- [ ] 2.6: Magic number mismatch rejected
- [ ] 2.7: Invalid symbol rejected
- [ ] 2.8: Invalid action rejected

### Integration Tests
- [ ] 3.1: EA runs in Strategy Tester
- [ ] 3.2: Commands processed in tester (pre-created)

### Demo Account Tests
- [ ] 4.1: BUY order executes on demo
- [ ] 4.2: SELL order executes on demo
- [ ] 4.3: Close command works on demo
- [ ] 4.4: Multiple commands in sequence

### Stress Tests
- [ ] 5.1: High volume commands (100+)
- [ ] 5.2: Malformed CSV handling
- [ ] 5.3: Rapid command updates

### Edge Cases
- [ ] 6.1: EA restart mid-execution
- [ ] 6.2: File deletion during runtime
- [ ] 6.3: Disk full behavior documented

---

## Test Results Template

```
Date: ____________________
Tester: ____________________
MT5 Build: ____________________
Account Type: [ ] Demo [ ] Live
Broker: ____________________

Total Tests: ____________________
Passed: ____________________
Failed: ____________________

Critical Issues:
1. ____________________
2. ____________________

Notes:
____________________
____________________
____________________
```

---

## Production Readiness Criteria

Before deploying to LIVE account:

- [ ] All unit tests pass (100%)
- [ ] All integration tests pass (100%)
- [ ] Demo testing completed for **minimum 1 week**
- [ ] No crashes or errors in Experts log
- [ ] Execution quality validated (slippage < X pips)
- [ ] Risk limits tested and working
- [ ] Emergency stop procedure documented
- [ ] Backup and recovery plan in place
- [ ] Monitoring and alerting configured
- [ ] Rollback plan prepared

---

## Safety Checklist

Before EVERY test on demo/live:

- [ ] Verified account type (demo vs live)
- [ ] Set appropriate lot sizes (0.01 for testing)
- [ ] Verified magic number is unique
- [ ] Checked market hours (avoid weekends)
- [ ] Enabled debug logs
- [ ] Documented test plan
- [ ] Set stop loss on manual positions (if applicable)
- [ ] Prepared to stop EA immediately if issues occur

---

## Known Limitations (Phase 1)

1. **In-memory processed commands array** - cleared on EA restart
   - **Mitigation:** APP should archive processed commands

2. **No persistent state** - EA doesn't save state to file
   - **Mitigation:** APP tracks all command statuses

3. **File-based communication latency** - 2-5 second delay
   - **Mitigation:** Acceptable for MVP; optimize in Phase 2+ if needed

4. **No command acknowledgment** - EA doesn't confirm receipt before execution
   - **Mitigation:** APP monitors receipts with timeout

5. **No batch operations** - one command at a time
   - **Mitigation:** Use multiple commands with unique cmd_id

---

## Next Steps After Testing

1. Document all test results
2. Fix any critical issues
3. Re-test failed cases
4. Proceed to **Phase 2** (Backend development)
5. Plan integration tests (APP + EA)

---

## Support

If tests fail:
1. Check **Experts log** for detailed error messages
2. Verify file paths and permissions
3. Ensure demo account is logged in
4. Check market hours (Forex closed on weekends)
5. Review **PROTOCOL.md** for command format
6. Review **INSTALL.md** for setup verification

---

## Conclusion

This testing guide ensures the **MT5 Executor EA** is:
- ✅ **Robust** - handles errors gracefully
- ✅ **Safe** - validates all inputs
- ✅ **Reliable** - executes orders correctly
- ✅ **Auditable** - logs all actions

**Complete all tests before proceeding to Phase 2.**
