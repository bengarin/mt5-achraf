//+------------------------------------------------------------------+
//|                                                       Logger.mqh |
//|                          Gold EA Professional v2.0 - Logger      |
//|                     Système de Logging CSV avec Vérification     |
//+------------------------------------------------------------------+
#property copyright "Gold EA Professional"
#property link      ""
#property version   "2.0"
#property strict

//+------------------------------------------------------------------+
//| Classe CLogger - Gestion complète du logging                     |
//+------------------------------------------------------------------+
class CLogger
{
private:
    // Noms des fichiers CSV
    string          m_tradesFile;
    string          m_signalsFile;
    string          m_performanceFile;
    string          m_errorsFile;
    string          m_dailyStatsFile;
    string          m_parametersVerificationFile;  // NOUVEAU: Fichier de vérification

    // Handles des fichiers
    int             m_tradesHandle;
    int             m_signalsHandle;
    int             m_performanceHandle;
    int             m_errorsHandle;
    int             m_dailyStatsHandle;
    int             m_paramsVerifyHandle;          // NOUVEAU: Handle vérification

    // Configuration
    bool            m_enabled;
    int             m_logLevel;
    bool            m_paramVerificationEnabled;    // NOUVEAU: Activation vérification

    // Statistiques internes
    int             m_totalLogsWritten;
    int             m_errorsCount;

    // Méthodes privées
    string          GetTimestamp();
    bool            WriteToFile(int handle, string line);
    void            EnsureHeaderWritten(int handle, string header, string filename);

public:
    // Constructeur / Destructeur
                    CLogger();
                   ~CLogger();

    // Initialisation
    bool            Init(string prefix = "GoldEA_", bool enabled = true, int logLevel = 2);
    void            Deinit();

    // Configuration
    void            SetEnabled(bool enabled) { m_enabled = enabled; }
    void            SetLogLevel(int level) { m_logLevel = level; }
    void            EnableParameterVerification(bool enable) { m_paramVerificationEnabled = enable; }

    // Méthodes de logging existantes
    void            LogTrade(int tradeNum, string action, double price, double sl, double tp,
                            double lots, int ticket, string comment = "");
    void            LogSignal(string signalType, double strength, string conditions, bool executed);
    void            LogPerformance(double balance, double equity, double drawdown,
                                  int totalTrades, int winTrades, double profitFactor);
    void            LogError(int errorCode, string errorMsg, string context);
    void            LogDailyStats(string date, int trades, double profit, double maxDD,
                                 int wins, int losses);

    // NOUVELLE MÉTHODE: Vérification des paramètres SL/TP
    void            LogParametersVerification(int tradeNumber,
                                             double inputSLMultiplier,
                                             double inputTPMultiplier,
                                             double atrValue,
                                             double entryPrice,
                                             double actualSLPrice,
                                             double actualTPPrice);

    // Utilitaires
    void            LogMessage(int level, string message);
    void            FlushAll();
    int             GetTotalLogs() { return m_totalLogsWritten; }
    int             GetErrorCount() { return m_errorsCount; }
};

//+------------------------------------------------------------------+
//| Constructeur                                                      |
//+------------------------------------------------------------------+
CLogger::CLogger()
{
    m_enabled = false;
    m_logLevel = 2;
    m_paramVerificationEnabled = true;
    m_totalLogsWritten = 0;
    m_errorsCount = 0;

    m_tradesHandle = INVALID_HANDLE;
    m_signalsHandle = INVALID_HANDLE;
    m_performanceHandle = INVALID_HANDLE;
    m_errorsHandle = INVALID_HANDLE;
    m_dailyStatsHandle = INVALID_HANDLE;
    m_paramsVerifyHandle = INVALID_HANDLE;
}

//+------------------------------------------------------------------+
//| Destructeur                                                       |
//+------------------------------------------------------------------+
CLogger::~CLogger()
{
    Deinit();
}

//+------------------------------------------------------------------+
//| Initialisation du logger                                          |
//+------------------------------------------------------------------+
bool CLogger::Init(string prefix = "GoldEA_", bool enabled = true, int logLevel = 2)
{
    m_enabled = enabled;
    m_logLevel = logLevel;

    if(!m_enabled)
        return true;

    // Définir les noms de fichiers
    string dateStr = TimeToString(TimeCurrent(), TIME_DATE);
    StringReplace(dateStr, ".", "");

    m_tradesFile = prefix + "trades_" + dateStr + ".csv";
    m_signalsFile = prefix + "signals_" + dateStr + ".csv";
    m_performanceFile = prefix + "performance_" + dateStr + ".csv";
    m_errorsFile = prefix + "errors_" + dateStr + ".csv";
    m_dailyStatsFile = prefix + "daily_stats_" + dateStr + ".csv";
    m_parametersVerificationFile = prefix + "parameters_verification_" + dateStr + ".csv";

    // Ouvrir les fichiers
    m_tradesHandle = FileOpen(m_tradesFile, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
    m_signalsHandle = FileOpen(m_signalsFile, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
    m_performanceHandle = FileOpen(m_performanceFile, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
    m_errorsHandle = FileOpen(m_errorsFile, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
    m_dailyStatsHandle = FileOpen(m_dailyStatsFile, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
    m_paramsVerifyHandle = FileOpen(m_parametersVerificationFile, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');

    // Vérifier l'ouverture
    if(m_tradesHandle == INVALID_HANDLE ||
       m_signalsHandle == INVALID_HANDLE ||
       m_performanceHandle == INVALID_HANDLE ||
       m_errorsHandle == INVALID_HANDLE ||
       m_dailyStatsHandle == INVALID_HANDLE ||
       m_paramsVerifyHandle == INVALID_HANDLE)
    {
        Print("LOGGER ERROR: Failed to open one or more log files");
        return false;
    }

    // Écrire les en-têtes
    EnsureHeaderWritten(m_tradesHandle,
        "Timestamp,TradeNumber,Action,Price,SL,TP,Lots,Ticket,Comment",
        m_tradesFile);

    EnsureHeaderWritten(m_signalsHandle,
        "Timestamp,SignalType,Strength,Conditions,Executed",
        m_signalsFile);

    EnsureHeaderWritten(m_performanceHandle,
        "Timestamp,Balance,Equity,Drawdown,TotalTrades,WinTrades,ProfitFactor",
        m_performanceFile);

    EnsureHeaderWritten(m_errorsHandle,
        "Timestamp,ErrorCode,ErrorMessage,Context",
        m_errorsFile);

    EnsureHeaderWritten(m_dailyStatsHandle,
        "Date,Trades,Profit,MaxDrawdown,Wins,Losses",
        m_dailyStatsFile);

    // NOUVEAU: En-tête pour la vérification des paramètres
    EnsureHeaderWritten(m_paramsVerifyHandle,
        "Timestamp,TradeNumber,Input_SL_Multiplier,Input_TP_Multiplier,ATR_Value,Entry_Price,Actual_SL_Price,Actual_TP_Price,SL_Distance_Pips,TP_Distance_Pips,Calculated_SL_Multiplier,Calculated_TP_Multiplier,RR_Ratio,Match_Status",
        m_parametersVerificationFile);

    Print("LOGGER: Initialized successfully - Files created with prefix: ", prefix);
    return true;
}

//+------------------------------------------------------------------+
//| Fermeture du logger                                               |
//+------------------------------------------------------------------+
void CLogger::Deinit()
{
    if(m_tradesHandle != INVALID_HANDLE) { FileClose(m_tradesHandle); m_tradesHandle = INVALID_HANDLE; }
    if(m_signalsHandle != INVALID_HANDLE) { FileClose(m_signalsHandle); m_signalsHandle = INVALID_HANDLE; }
    if(m_performanceHandle != INVALID_HANDLE) { FileClose(m_performanceHandle); m_performanceHandle = INVALID_HANDLE; }
    if(m_errorsHandle != INVALID_HANDLE) { FileClose(m_errorsHandle); m_errorsHandle = INVALID_HANDLE; }
    if(m_dailyStatsHandle != INVALID_HANDLE) { FileClose(m_dailyStatsHandle); m_dailyStatsHandle = INVALID_HANDLE; }
    if(m_paramsVerifyHandle != INVALID_HANDLE) { FileClose(m_paramsVerifyHandle); m_paramsVerifyHandle = INVALID_HANDLE; }

    Print("LOGGER: Deinitialized - Total logs written: ", m_totalLogsWritten);
}

//+------------------------------------------------------------------+
//| Obtenir le timestamp actuel                                       |
//+------------------------------------------------------------------+
string CLogger::GetTimestamp()
{
    return TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
}

//+------------------------------------------------------------------+
//| Écrire une ligne dans un fichier                                  |
//+------------------------------------------------------------------+
bool CLogger::WriteToFile(int handle, string line)
{
    if(handle == INVALID_HANDLE)
        return false;

    FileWriteString(handle, line + "\n");
    FileFlush(handle);
    m_totalLogsWritten++;
    return true;
}

//+------------------------------------------------------------------+
//| S'assurer que l'en-tête est écrit                                 |
//+------------------------------------------------------------------+
void CLogger::EnsureHeaderWritten(int handle, string header, string filename)
{
    if(handle != INVALID_HANDLE)
    {
        FileWriteString(handle, header + "\n");
        FileFlush(handle);
    }
}

//+------------------------------------------------------------------+
//| Logger un trade                                                   |
//+------------------------------------------------------------------+
void CLogger::LogTrade(int tradeNum, string action, double price, double sl, double tp,
                       double lots, int ticket, string comment = "")
{
    if(!m_enabled || m_tradesHandle == INVALID_HANDLE)
        return;

    string line = StringFormat("%s,%d,%s,%.5f,%.5f,%.5f,%.2f,%d,%s",
        GetTimestamp(), tradeNum, action, price, sl, tp, lots, ticket, comment);

    WriteToFile(m_tradesHandle, line);

    if(m_logLevel >= 2)
        Print("TRADE LOG: ", action, " #", tradeNum, " @ ", price, " SL:", sl, " TP:", tp);
}

//+------------------------------------------------------------------+
//| Logger un signal                                                  |
//+------------------------------------------------------------------+
void CLogger::LogSignal(string signalType, double strength, string conditions, bool executed)
{
    if(!m_enabled || m_signalsHandle == INVALID_HANDLE)
        return;

    string line = StringFormat("%s,%s,%.2f,%s,%s",
        GetTimestamp(), signalType, strength, conditions, executed ? "YES" : "NO");

    WriteToFile(m_signalsHandle, line);
}

//+------------------------------------------------------------------+
//| Logger la performance                                             |
//+------------------------------------------------------------------+
void CLogger::LogPerformance(double balance, double equity, double drawdown,
                             int totalTrades, int winTrades, double profitFactor)
{
    if(!m_enabled || m_performanceHandle == INVALID_HANDLE)
        return;

    string line = StringFormat("%s,%.2f,%.2f,%.2f,%d,%d,%.2f",
        GetTimestamp(), balance, equity, drawdown, totalTrades, winTrades, profitFactor);

    WriteToFile(m_performanceHandle, line);
}

//+------------------------------------------------------------------+
//| Logger une erreur                                                 |
//+------------------------------------------------------------------+
void CLogger::LogError(int errorCode, string errorMsg, string context)
{
    if(!m_enabled || m_errorsHandle == INVALID_HANDLE)
        return;

    string line = StringFormat("%s,%d,%s,%s",
        GetTimestamp(), errorCode, errorMsg, context);

    WriteToFile(m_errorsHandle, line);
    m_errorsCount++;

    Print("ERROR LOG: [", errorCode, "] ", errorMsg, " - Context: ", context);
}

//+------------------------------------------------------------------+
//| Logger les statistiques journalières                              |
//+------------------------------------------------------------------+
void CLogger::LogDailyStats(string date, int trades, double profit, double maxDD,
                            int wins, int losses)
{
    if(!m_enabled || m_dailyStatsHandle == INVALID_HANDLE)
        return;

    string line = StringFormat("%s,%d,%.2f,%.2f,%d,%d",
        date, trades, profit, maxDD, wins, losses);

    WriteToFile(m_dailyStatsHandle, line);
}

//+------------------------------------------------------------------+
//| NOUVELLE FONCTION: Logger la vérification des paramètres SL/TP   |
//+------------------------------------------------------------------+
void CLogger::LogParametersVerification(int tradeNumber,
                                        double inputSLMultiplier,
                                        double inputTPMultiplier,
                                        double atrValue,
                                        double entryPrice,
                                        double actualSLPrice,
                                        double actualTPPrice)
{
    if(!m_enabled || !m_paramVerificationEnabled || m_paramsVerifyHandle == INVALID_HANDLE)
        return;

    // Calculer les distances en pips (pour Gold, 1 pip = 0.1 point = $0.10)
    double pointValue = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double slDistance = MathAbs(entryPrice - actualSLPrice);
    double tpDistance = MathAbs(actualTPPrice - entryPrice);

    // Convertir en pips (pour XAUUSD: 1 pip = 0.01)
    double pipSize = 0.01;  // Pour Gold/XAUUSD
    double slDistancePips = slDistance / pipSize;
    double tpDistancePips = tpDistance / pipSize;

    // Calculer les multipliers réels basés sur ATR
    double calculatedSLMultiplier = 0.0;
    double calculatedTPMultiplier = 0.0;
    double rrRatio = 0.0;

    if(atrValue > 0)
    {
        calculatedSLMultiplier = slDistance / atrValue;
        calculatedTPMultiplier = tpDistance / atrValue;
    }

    if(slDistance > 0)
    {
        rrRatio = tpDistance / slDistance;
    }

    // Déterminer le statut de correspondance (tolérance de 5%)
    string matchStatus = "ERROR";
    double slTolerance = inputSLMultiplier * 0.05;
    double tpTolerance = inputTPMultiplier * 0.05;

    bool slMatch = MathAbs(calculatedSLMultiplier - inputSLMultiplier) <= slTolerance;
    bool tpMatch = MathAbs(calculatedTPMultiplier - inputTPMultiplier) <= tpTolerance;

    if(slMatch && tpMatch)
    {
        matchStatus = "OK";
    }
    else if(slMatch)
    {
        matchStatus = "TP_ERROR";
    }
    else if(tpMatch)
    {
        matchStatus = "SL_ERROR";
    }
    else
    {
        matchStatus = "BOTH_ERROR";
    }

    // Construire la ligne CSV
    string line = StringFormat("%s,%d,%.2f,%.2f,%.5f,%.5f,%.5f,%.5f,%.1f,%.1f,%.2f,%.2f,%.2f,%s",
        GetTimestamp(),
        tradeNumber,
        inputSLMultiplier,
        inputTPMultiplier,
        atrValue,
        entryPrice,
        actualSLPrice,
        actualTPPrice,
        slDistancePips,
        tpDistancePips,
        calculatedSLMultiplier,
        calculatedTPMultiplier,
        rrRatio,
        matchStatus);

    WriteToFile(m_paramsVerifyHandle, line);

    // Afficher un avertissement si les paramètres ne correspondent pas
    if(matchStatus != "OK")
    {
        Print("!!! PARAMETER MISMATCH DETECTED !!!");
        Print("Trade #", tradeNumber, " - Status: ", matchStatus);
        Print("  Input SL Mult: ", inputSLMultiplier, " | Calculated: ", DoubleToString(calculatedSLMultiplier, 2));
        Print("  Input TP Mult: ", inputTPMultiplier, " | Calculated: ", DoubleToString(calculatedTPMultiplier, 2));
        Print("  Expected R:R: ", DoubleToString(inputTPMultiplier/inputSLMultiplier, 2),
              " | Actual R:R: ", DoubleToString(rrRatio, 2));

        // Logger également comme erreur
        LogError(9999, "Parameter mismatch: " + matchStatus,
                 "Trade #" + IntegerToString(tradeNumber));
    }
    else if(m_logLevel >= 2)
    {
        Print("PARAM VERIFY: Trade #", tradeNumber, " - OK | SL:",
              DoubleToString(calculatedSLMultiplier, 2), "x | TP:",
              DoubleToString(calculatedTPMultiplier, 2), "x | R:R:",
              DoubleToString(rrRatio, 2));
    }
}

//+------------------------------------------------------------------+
//| Logger un message général                                         |
//+------------------------------------------------------------------+
void CLogger::LogMessage(int level, string message)
{
    if(!m_enabled || level > m_logLevel)
        return;

    string levelStr = "";
    switch(level)
    {
        case 0: levelStr = "ERROR"; break;
        case 1: levelStr = "WARN"; break;
        case 2: levelStr = "INFO"; break;
        case 3: levelStr = "DEBUG"; break;
        default: levelStr = "TRACE";
    }

    Print("[", levelStr, "] ", GetTimestamp(), " - ", message);
}

//+------------------------------------------------------------------+
//| Forcer l'écriture de tous les buffers                            |
//+------------------------------------------------------------------+
void CLogger::FlushAll()
{
    if(m_tradesHandle != INVALID_HANDLE) FileFlush(m_tradesHandle);
    if(m_signalsHandle != INVALID_HANDLE) FileFlush(m_signalsHandle);
    if(m_performanceHandle != INVALID_HANDLE) FileFlush(m_performanceHandle);
    if(m_errorsHandle != INVALID_HANDLE) FileFlush(m_errorsHandle);
    if(m_dailyStatsHandle != INVALID_HANDLE) FileFlush(m_dailyStatsHandle);
    if(m_paramsVerifyHandle != INVALID_HANDLE) FileFlush(m_paramsVerifyHandle);
}

//+------------------------------------------------------------------+
