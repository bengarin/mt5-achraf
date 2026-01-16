# Installation Guide — AutoTrading Platform

## Overview
This guide covers installation of:
1. **MT5 Executor EA** (Bridge)
2. **Backend** (Python/FastAPI) - Phase 2
3. **Frontend** (React/Next.js) - Phase 3

---

## Prerequisites

### For MT5 Executor EA
- **MetaTrader 5** terminal installed
- Demo or live trading account
- Basic understanding of MT5 navigation

### For Backend (Phase 2+)
- **Python 3.9+**
- **pip** package manager
- **PostgreSQL** or **SQLite** (MVP)

### For Frontend (Phase 3+)
- **Node.js 18+**
- **npm** or **yarn**

---

## Part 1: MT5 Executor EA Installation

### Step 1: Locate MT5 Data Folder

#### Windows
1. Open MetaTrader 5
2. Click **File → Open Data Folder**
3. This opens: `C:\Users\<Username>\AppData\Roaming\MetaQuotes\Terminal\<TERMINAL_ID>\`

#### Linux/Wine
1. Navigate to: `~/.wine/drive_c/users/<username>/AppData/Roaming/MetaQuotes/Terminal/<TERMINAL_ID>/`

**Important:** Each MT5 installation has a unique `<TERMINAL_ID>` hash. Make sure you're using the correct one.

---

### Step 2: Copy EA to MT5

1. **Navigate to the MQL5/Experts folder:**
   ```
   <MT5_DATA_FOLDER>/MQL5/Experts/
   ```

2. **Copy the EA file:**
   - Source: `mt5-achraf/mt5-executor/AutoTradingExecutor.mq5`
   - Destination: `<MT5_DATA_FOLDER>/MQL5/Experts/AutoTradingExecutor.mq5`

   **Example (Windows):**
   ```
   Copy from: C:\Projects\mt5-achraf\mt5-executor\AutoTradingExecutor.mq5
   Copy to: C:\Users\YourName\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\AutoTradingExecutor.mq5
   ```

---

### Step 3: Compile the EA

1. **Open MetaEditor:**
   - In MT5, press `F4` or click **Tools → MetaQuotes Language Editor**

2. **Open the EA:**
   - In MetaEditor Navigator (left panel), expand **Experts**
   - Double-click **AutoTradingExecutor.mq5**

3. **Compile:**
   - Press `F7` or click **Compile** button
   - Check the **Errors** tab at bottom
   - You should see: `0 error(s), 0 warning(s)`
   - A compiled file `AutoTradingExecutor.ex5` is created

**Troubleshooting Compilation Errors:**
- Ensure MQL5 version is up-to-date (**Tools → Options → Update**)
- Check for syntax errors in the code
- Restart MetaEditor if needed

---

### Step 4: Attach EA to Chart

1. **Open a chart:**
   - In MT5, open a chart for any symbol (e.g., XAUUSD)
   - Timeframe doesn't matter (EA runs on timer)

2. **Open Navigator:**
   - Press `Ctrl+N` or **View → Navigator**

3. **Attach EA:**
   - Expand **Expert Advisors** section
   - Find **AutoTradingExecutor**
   - Drag and drop onto the chart

4. **Configure EA settings:**
   - A settings dialog appears

   **Inputs tab:**
   ```
   MagicNumber = 4400000          (match your APP config)
   CheckIntervalSeconds = 2        (how often to check commands.csv)
   MaxProcessedCommands = 10000    (memory limit for processed IDs)
   EnableDebugLogs = true          (recommended for testing)
   CommandsFile = commands.csv
   ReceiptsFile = receipts.csv
   ```

   **Common tab:**
   - ✅ **Allow automated trading**
   - ✅ **Allow DLL imports** (not needed, but safe)
   - ✅ **Allow external experts imports** (optional)

5. **Click OK**

6. **Verify EA is running:**
   - Check top-right corner of chart
   - You should see: **AutoTradingExecutor** with a smiley face 😊
   - If you see a sad face 😞, click it to re-enable automated trading

---

### Step 5: Verify File Access

1. **Open Experts log:**
   - In MT5, click **View → Toolbox**
   - Go to **Experts** tab
   - Look for initialization message:
     ```
     ========================================
     AutoTradingExecutor EA initialized
     Magic Number: 4400000
     Check Interval: 2 seconds
     Commands File: commands.csv
     Receipts File: receipts.csv
     ========================================
     ```

2. **Check MQL5/Files folder:**
   - Navigate to: `<MT5_DATA_FOLDER>/MQL5/Files/`
   - This folder should exist (created automatically by MT5)
   - If it doesn't exist, create it manually

---

### Step 6: Test with Manual Command

Create a test command file to verify EA is reading correctly:

1. **Navigate to:**
   ```
   <MT5_DATA_FOLDER>/MQL5/Files/
   ```

2. **Create `commands.csv`:**
   ```csv
   cmd_id,timestamp,symbol,action,lot,sl,tp,magic,comment,ttl_sec
   99999,2026-01-16 10:00:00,XAUUSD,BUY,0.01,0,0,4400000,TestCommand,300
   ```

3. **Wait 2-5 seconds** (CheckIntervalSeconds)

4. **Check Experts log:**
   - You should see:
     ```
     Executing command 99999: BUY XAUUSD 0.01 lots
     ```

5. **Check for `receipts.csv`:**
   - Should be created in `MQL5/Files/`
   - Open it and verify content:
     ```csv
     cmd_id,status,ticket,retcode,fill_price,message
     99999,FILLED,123456,10009,2437.50,OK
     ```
   - **OR** (if demo account not logged in or market closed):
     ```csv
     99999,REJECTED,0,10018,0.0,Retcode: 10018 - Market closed
     ```

**Important:** If using a **demo account**, ensure you're logged in and the market is open for testing.

---

## Part 2: Backend Installation (Phase 2)

*This section will be completed in Phase 2.*

### Quick Start (Future)

1. **Install dependencies:**
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

2. **Configure MT5 file path:**
   - Edit `backend/config.py`
   - Set `MT5_FILES_PATH` to your `<MT5_DATA_FOLDER>/MQL5/Files/`

3. **Run backend:**
   ```bash
   python -m uvicorn app.main:app --reload
   ```

4. **Access API:**
   - Swagger docs: `http://localhost:8000/docs`

---

## Part 3: Frontend Installation (Phase 3)

*This section will be completed in Phase 3.*

### Quick Start (Future)

1. **Install dependencies:**
   ```bash
   cd frontend
   npm install
   ```

2. **Configure API endpoint:**
   - Edit `frontend/.env.local`
   - Set `NEXT_PUBLIC_API_URL=http://localhost:8000`

3. **Run frontend:**
   ```bash
   npm run dev
   ```

4. **Access dashboard:**
   - Open browser: `http://localhost:3000`

---

## Configuration Reference

### MT5 EA Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `MagicNumber` | 4400000 | Unique identifier for this EA instance |
| `CheckIntervalSeconds` | 2 | How often to check commands.csv (in seconds) |
| `MaxProcessedCommands` | 10000 | Maximum command IDs to track in memory |
| `EnableDebugLogs` | true | Print detailed logs to Experts tab |
| `CommandsFile` | commands.csv | Input file name |
| `ReceiptsFile` | receipts.csv | Output file name |

### Recommended Settings

**For Testing/Development:**
- `CheckIntervalSeconds = 1` (faster response)
- `EnableDebugLogs = true` (detailed logging)

**For Production:**
- `CheckIntervalSeconds = 2-5` (balance between speed and CPU usage)
- `EnableDebugLogs = false` (reduce log clutter)
- `MagicNumber = unique per strategy` (e.g., 4400001, 4400002)

---

## File Paths Quick Reference

### Windows
```
MT5 Data Folder:
C:\Users\<Username>\AppData\Roaming\MetaQuotes\Terminal\<TERMINAL_ID>\

EA Source:
...\MQL5\Experts\AutoTradingExecutor.mq5

Commands/Receipts:
...\MQL5\Files\commands.csv
...\MQL5\Files\receipts.csv
```

### Linux/Wine
```
MT5 Data Folder:
~/.wine/drive_c/users/<username>/AppData/Roaming/MetaQuotes/Terminal/<TERMINAL_ID>/

EA Source:
.../MQL5/Experts/AutoTradingExecutor.mq5

Commands/Receipts:
.../MQL5/Files/commands.csv
.../MQL5/Files/receipts.csv
```

---

## Troubleshooting

### EA Not Running

**Symptom:** Sad face icon on chart

**Solutions:**
1. Click the sad face icon to re-enable automated trading
2. Check **Tools → Options → Expert Advisors**:
   - ✅ Enable automated trading
3. Restart MT5

---

### Commands Not Being Executed

**Symptom:** EA running, but commands.csv not processed

**Check:**
1. **File path correct?**
   - Verify `commands.csv` is in `MQL5/Files/` folder
   - Not in `MQL5/Experts/` or root

2. **File format correct?**
   - CSV must be comma-separated
   - Check for extra spaces or tabs
   - Ensure header line is present (optional but recommended)

3. **Magic number match?**
   - Command `magic` field must match EA `MagicNumber` setting

4. **TTL expired?**
   - Check command timestamp vs current time
   - Set higher TTL (e.g., 300 seconds) for testing

5. **Check Experts log:**
   - Look for error messages
   - Enable `EnableDebugLogs = true`

---

### No Receipts File Created

**Symptom:** `receipts.csv` not appearing

**Check:**
1. **MQL5/Files folder exists?**
   - Create manually if missing

2. **File permissions?**
   - On Linux/Wine, check folder write permissions
   - Run: `chmod 777 MQL5/Files/` (for testing only)

3. **EA has processed any commands?**
   - Receipts are only written after a command is processed
   - Create a test command (see Step 6 above)

---

### Compilation Errors

**Symptom:** Errors in MetaEditor when compiling

**Common Issues:**
- **Syntax Error:** Check line numbers in error message
- **Outdated MQL5:** Update MT5 terminal
- **Copy-paste issues:** Ensure no hidden characters

**Solution:**
- Copy EA source code again from repository
- Use a text editor that supports UTF-8 (e.g., VS Code, Notepad++)

---

### Market Closed / No Prices

**Symptom:** Receipt shows `REJECTED, retcode=10018, Market closed`

**Explanation:**
- Forex market is closed on weekends
- Some instruments have limited trading hours

**Solution:**
- Test during market hours (Monday-Friday)
- Use Strategy Tester for offline testing (see TESTING.md)

---

## Security Checklist

Before going live:

- [ ] Change default magic number (use unique per strategy)
- [ ] Test on demo account for at least 1 week
- [ ] Set proper lot sizes (start with minimum)
- [ ] Enable risk limits in APP (Phase 2)
- [ ] Monitor Experts log regularly
- [ ] Backup EA settings and configuration
- [ ] Document your magic number mapping
- [ ] Test kill switch / emergency stop

---

## Next Steps

After successful installation:

1. **Run tests** (see TESTING.md)
2. **Integrate with APP** (Phase 2)
3. **Run replay/backtest** (Phase 2)
4. **Validate execution quality** (Phase 4)
5. **Deploy to production** (after 1+ month demo testing)

---

## Support

If you encounter issues not covered here:

1. Check **TESTING.md** for test procedures
2. Review **PROTOCOL.md** for command/receipt format
3. Check MT5 Experts log for detailed error messages
4. Verify all paths and permissions
5. Test with minimal command (low TTL, 0.01 lot)

---

## Summary

✅ EA installed and compiled
✅ EA attached to chart and running
✅ File access verified
✅ Test command executed successfully
✅ Receipts file created

**Your MT5 Executor Bridge is ready for integration!**

Next: Proceed to **TESTING.md** for comprehensive testing procedures.
