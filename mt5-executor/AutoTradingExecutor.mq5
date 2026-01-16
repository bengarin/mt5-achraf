//+------------------------------------------------------------------+
//|                                      AutoTradingExecutor.mq5      |
//|                        AutoTrading Platform - MT5 Executor Bridge |
//|                                                                    |
//| Purpose: Read commands.csv, execute orders, write receipts.csv    |
//| Integration: File-based bridge (no HTTP)                          |
//+------------------------------------------------------------------+
#property copyright "AutoTrading Platform"
#property link      "https://github.com/yourrepo/mt5-achraf"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input int      MagicNumber = 4400000;           // EA Magic Number
input int      CheckIntervalSeconds = 2;         // How often to check commands.csv (seconds)
input int      MaxProcessedCommands = 10000;     // Max command IDs to track (prevent memory overflow)
input bool     EnableDebugLogs = true;           // Print debug logs
input string   CommandsFile = "commands.csv";    // Commands file name
input string   ReceiptsFile = "receipts.csv";    // Receipts file name

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
int processedCommands[];     // Array to track processed command IDs
int processedCount = 0;      // Count of processed commands

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   // Set timer to check commands file periodically
   EventSetTimer(CheckIntervalSeconds);

   // Resize processed commands array
   ArrayResize(processedCommands, MaxProcessedCommands);
   ArrayInitialize(processedCommands, -1);

   Print("========================================");
   Print("AutoTradingExecutor EA initialized");
   Print("Magic Number: ", MagicNumber);
   Print("Check Interval: ", CheckIntervalSeconds, " seconds");
   Print("Commands File: ", CommandsFile);
   Print("Receipts File: ", ReceiptsFile);
   Print("========================================");

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   Print("AutoTradingExecutor EA stopped. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Timer function - called every CheckIntervalSeconds               |
//+------------------------------------------------------------------+
void OnTimer()
{
   ProcessCommandsFile();
}

//+------------------------------------------------------------------+
//| Process commands.csv file                                         |
//+------------------------------------------------------------------+
void ProcessCommandsFile()
{
   // Open commands file
   int fileHandle = FileOpen(CommandsFile, FILE_READ|FILE_CSV|FILE_ANSI, ',');

   if(fileHandle == INVALID_HANDLE)
   {
      // File doesn't exist yet - this is normal during startup
      if(EnableDebugLogs && GetLastError() != 0)
         Print("No commands file found (normal if not yet created)");
      return;
   }

   // Skip header line if present
   string line = FileReadString(fileHandle);
   if(line == "cmd_id,timestamp,symbol,action,lot,sl,tp,magic,comment,ttl_sec" ||
      line == "cmd_id")
   {
      // Header detected, already skipped
   }
   else
   {
      // No header, rewind to process first line
      FileSeek(fileHandle, 0, SEEK_SET);
   }

   // Process each command line
   while(!FileIsEnding(fileHandle))
   {
      // Read command fields
      string cmd_id_str = FileReadString(fileHandle);

      // Skip empty lines
      if(StringLen(cmd_id_str) == 0)
         continue;

      int cmd_id = (int)StringToInteger(cmd_id_str);
      string timestamp_str = FileReadString(fileHandle);
      string symbol = FileReadString(fileHandle);
      string action = FileReadString(fileHandle);
      double lot = StringToDouble(FileReadString(fileHandle));
      double sl = StringToDouble(FileReadString(fileHandle));
      double tp = StringToDouble(FileReadString(fileHandle));
      int magic = (int)StringToInteger(FileReadString(fileHandle));
      string comment = FileReadString(fileHandle);
      int ttl_sec = (int)StringToInteger(FileReadString(fileHandle));

      // Validate command
      if(cmd_id <= 0)
      {
         if(EnableDebugLogs)
            Print("Invalid cmd_id: ", cmd_id_str);
         continue;
      }

      // Check if already processed
      if(IsCommandProcessed(cmd_id))
      {
         if(EnableDebugLogs)
            Print("Command ", cmd_id, " already processed, skipping");
         continue;
      }

      // Validate TTL (Time To Live)
      datetime cmd_time = StringToTime(timestamp_str);
      datetime current_time = TimeCurrent();
      int age_seconds = (int)(current_time - cmd_time);

      if(ttl_sec > 0 && age_seconds > ttl_sec)
      {
         // Command expired
         WriteReceipt(cmd_id, "EXPIRED", 0, 0, 0.0,
                     "Command expired (age: " + IntegerToString(age_seconds) + "s, TTL: " + IntegerToString(ttl_sec) + "s)");
         MarkCommandProcessed(cmd_id);

         if(EnableDebugLogs)
            Print("Command ", cmd_id, " expired (age: ", age_seconds, "s)");

         continue;
      }

      // Validate magic number
      if(magic != MagicNumber)
      {
         WriteReceipt(cmd_id, "REJECTED", 0, 0, 0.0,
                     "Magic number mismatch (expected: " + IntegerToString(MagicNumber) + ", got: " + IntegerToString(magic) + ")");
         MarkCommandProcessed(cmd_id);

         if(EnableDebugLogs)
            Print("Command ", cmd_id, " rejected: magic number mismatch");

         continue;
      }

      // Execute command
      ExecuteCommand(cmd_id, symbol, action, lot, sl, tp, magic, comment);

      // Mark as processed
      MarkCommandProcessed(cmd_id);
   }

   FileClose(fileHandle);
}

//+------------------------------------------------------------------+
//| Execute trading command                                           |
//+------------------------------------------------------------------+
void ExecuteCommand(int cmd_id, string symbol, string action, double lot,
                   double sl, double tp, int magic, string comment)
{
   if(EnableDebugLogs)
      Print("Executing command ", cmd_id, ": ", action, " ", symbol, " ", lot, " lots");

   // Normalize symbol
   if(!SymbolSelect(symbol, true))
   {
      WriteReceipt(cmd_id, "ERROR", 0, 0, 0.0, "Symbol not found or not available: " + symbol);
      return;
   }

   // Prepare trade request
   MqlTradeRequest request = {};
   MqlTradeResult result = {};

   request.magic = magic;
   request.symbol = symbol;
   request.volume = lot;
   request.comment = comment;
   request.type_filling = ORDER_FILLING_FOK;  // Fill or Kill
   request.deviation = 10;  // Max slippage in points

   // Handle different actions
   if(action == "BUY")
   {
      request.action = TRADE_ACTION_DEAL;
      request.type = ORDER_TYPE_BUY;
      request.price = SymbolInfoDouble(symbol, SYMBOL_ASK);
      request.sl = sl;
      request.tp = tp;
   }
   else if(action == "SELL")
   {
      request.action = TRADE_ACTION_DEAL;
      request.type = ORDER_TYPE_SELL;
      request.price = SymbolInfoDouble(symbol, SYMBOL_BID);
      request.sl = sl;
      request.tp = tp;
   }
   else if(action == "CLOSE")
   {
      // Close all positions with matching magic and symbol
      ClosePositionsByMagicAndSymbol(cmd_id, symbol, magic);
      return;
   }
   else
   {
      WriteReceipt(cmd_id, "ERROR", 0, 0, 0.0, "Unknown action: " + action);
      return;
   }

   // Try alternative fill modes if FOK fails
   bool success = OrderSend(request, result);

   if(!success || result.retcode != TRADE_RETCODE_DONE)
   {
      // Try IOC (Immediate or Cancel) filling
      request.type_filling = ORDER_FILLING_IOC;
      success = OrderSend(request, result);
   }

   if(!success || result.retcode != TRADE_RETCODE_DONE)
   {
      // Try RETURN filling
      request.type_filling = ORDER_FILLING_RETURN;
      success = OrderSend(request, result);
   }

   // Write receipt
   if(result.retcode == TRADE_RETCODE_DONE)
   {
      WriteReceipt(cmd_id, "FILLED", (int)result.order, (int)result.retcode,
                  result.price, "OK");

      if(EnableDebugLogs)
         Print("Order filled: ticket=", result.order, ", price=", result.price);
   }
   else
   {
      string errorMsg = "Retcode: " + IntegerToString(result.retcode) + " - " + GetRetcodeDescription(result.retcode);
      WriteReceipt(cmd_id, "REJECTED", 0, (int)result.retcode, 0.0, errorMsg);

      if(EnableDebugLogs)
         Print("Order rejected: ", errorMsg);
   }
}

//+------------------------------------------------------------------+
//| Close positions by magic number and symbol                       |
//+------------------------------------------------------------------+
void ClosePositionsByMagicAndSymbol(int cmd_id, string symbol, int magic)
{
   int totalPositions = PositionsTotal();
   int closedCount = 0;
   string message = "";

   for(int i = totalPositions - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      if(PositionGetString(POSITION_SYMBOL) == symbol &&
         PositionGetInteger(POSITION_MAGIC) == magic)
      {
         MqlTradeRequest request = {};
         MqlTradeResult result = {};

         request.action = TRADE_ACTION_DEAL;
         request.position = ticket;
         request.symbol = symbol;
         request.volume = PositionGetDouble(POSITION_VOLUME);
         request.deviation = 10;
         request.magic = magic;
         request.comment = "Close by EA";

         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         {
            request.type = ORDER_TYPE_SELL;
            request.price = SymbolInfoDouble(symbol, SYMBOL_BID);
         }
         else
         {
            request.type = ORDER_TYPE_BUY;
            request.price = SymbolInfoDouble(symbol, SYMBOL_ASK);
         }

         request.type_filling = ORDER_FILLING_FOK;
         bool success = OrderSend(request, result);

         if(!success || result.retcode != TRADE_RETCODE_DONE)
         {
            request.type_filling = ORDER_FILLING_IOC;
            success = OrderSend(request, result);
         }

         if(result.retcode == TRADE_RETCODE_DONE)
         {
            closedCount++;
         }
         else
         {
            message += "Failed to close ticket " + IntegerToString(ticket) +
                      " (retcode: " + IntegerToString(result.retcode) + "); ";
         }
      }
   }

   if(closedCount > 0)
   {
      WriteReceipt(cmd_id, "FILLED", 0, TRADE_RETCODE_DONE, 0.0,
                  "Closed " + IntegerToString(closedCount) + " position(s)");
   }
   else
   {
      WriteReceipt(cmd_id, "ERROR", 0, 0, 0.0,
                  "No matching positions found or failed to close. " + message);
   }
}

//+------------------------------------------------------------------+
//| Write receipt to receipts.csv                                     |
//+------------------------------------------------------------------+
void WriteReceipt(int cmd_id, string status, int ticket, int retcode,
                 double fill_price, string message)
{
   int fileHandle = FileOpen(ReceiptsFile, FILE_WRITE|FILE_READ|FILE_CSV|FILE_ANSI, ',');

   if(fileHandle == INVALID_HANDLE)
   {
      Print("ERROR: Cannot open receipts file for writing: ", GetLastError());
      return;
   }

   // Check if file is empty (write header)
   if(FileSize(fileHandle) == 0)
   {
      FileWrite(fileHandle, "cmd_id", "status", "ticket", "retcode", "fill_price", "message");
   }

   // Move to end of file
   FileSeek(fileHandle, 0, SEEK_END);

   // Write receipt
   FileWrite(fileHandle,
            IntegerToString(cmd_id),
            status,
            IntegerToString(ticket),
            IntegerToString(retcode),
            DoubleToString(fill_price, 5),
            message);

   FileClose(fileHandle);

   if(EnableDebugLogs)
      Print("Receipt written: cmd_id=", cmd_id, ", status=", status, ", ticket=", ticket);
}

//+------------------------------------------------------------------+
//| Check if command was already processed                           |
//+------------------------------------------------------------------+
bool IsCommandProcessed(int cmd_id)
{
   for(int i = 0; i < processedCount && i < MaxProcessedCommands; i++)
   {
      if(processedCommands[i] == cmd_id)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Mark command as processed                                         |
//+------------------------------------------------------------------+
void MarkCommandProcessed(int cmd_id)
{
   if(processedCount < MaxProcessedCommands)
   {
      processedCommands[processedCount] = cmd_id;
      processedCount++;
   }
   else
   {
      // Array full - shift left and add new one (FIFO)
      for(int i = 0; i < MaxProcessedCommands - 1; i++)
      {
         processedCommands[i] = processedCommands[i + 1];
      }
      processedCommands[MaxProcessedCommands - 1] = cmd_id;

      if(EnableDebugLogs)
         Print("Warning: Processed commands array full, removing oldest entry");
   }
}

//+------------------------------------------------------------------+
//| Get human-readable retcode description                           |
//+------------------------------------------------------------------+
string GetRetcodeDescription(int retcode)
{
   switch(retcode)
   {
      case TRADE_RETCODE_DONE: return "Request completed";
      case TRADE_RETCODE_DONE_PARTIAL: return "Request partially filled";
      case TRADE_RETCODE_REJECT: return "Request rejected";
      case TRADE_RETCODE_CANCEL: return "Request canceled";
      case TRADE_RETCODE_PLACED: return "Order placed";
      case TRADE_RETCODE_INVALID: return "Invalid request";
      case TRADE_RETCODE_INVALID_VOLUME: return "Invalid volume";
      case TRADE_RETCODE_INVALID_PRICE: return "Invalid price";
      case TRADE_RETCODE_INVALID_STOPS: return "Invalid SL/TP";
      case TRADE_RETCODE_TRADE_DISABLED: return "Trading disabled";
      case TRADE_RETCODE_MARKET_CLOSED: return "Market closed";
      case TRADE_RETCODE_NO_MONEY: return "Insufficient funds";
      case TRADE_RETCODE_PRICE_CHANGED: return "Price changed";
      case TRADE_RETCODE_PRICE_OFF: return "No prices";
      case TRADE_RETCODE_INVALID_EXPIRATION: return "Invalid expiration";
      case TRADE_RETCODE_ORDER_CHANGED: return "Order changed";
      case TRADE_RETCODE_TOO_MANY_REQUESTS: return "Too many requests";
      case TRADE_RETCODE_NO_CHANGES: return "No changes";
      case TRADE_RETCODE_SERVER_DISABLES_AT: return "Autotrading disabled by server";
      case TRADE_RETCODE_CLIENT_DISABLES_AT: return "Autotrading disabled by client";
      case TRADE_RETCODE_LOCKED: return "Request locked";
      case TRADE_RETCODE_FROZEN: return "Order/position frozen";
      case TRADE_RETCODE_INVALID_FILL: return "Invalid fill type";
      case TRADE_RETCODE_CONNECTION: return "No connection";
      case TRADE_RETCODE_ONLY_REAL: return "Only real accounts allowed";
      case TRADE_RETCODE_LIMIT_ORDERS: return "Orders limit reached";
      case TRADE_RETCODE_LIMIT_VOLUME: return "Volume limit reached";
      case TRADE_RETCODE_INVALID_ORDER: return "Invalid order";
      case TRADE_RETCODE_POSITION_CLOSED: return "Position closed";
      default: return "Unknown retcode: " + IntegerToString(retcode);
   }
}

//+------------------------------------------------------------------+
