//+------------------------------------------------------------------+
//|                                                  GoldEA_Pro.mq5  |
//|                          Gold EA Professional v2.0               |
//|           Expert Advisor pour Trading XAUUSD (Gold)              |
//+------------------------------------------------------------------+
#property copyright "Gold EA Professional"
#property link      ""
#property version   "2.00"
#property description "Expert Advisor professionnel pour le trading de l'or (XAUUSD)"
#property description "Utilise ATR pour calculer SL/TP dynamiques"
#property description "Inclut la vérification des paramètres SL/TP"
#property strict

//+------------------------------------------------------------------+
//| Includes                                                         |
//+------------------------------------------------------------------+
#include "Include/Logger.mqh"
#include "Include/RiskManager.mqh"
#include "Include/TradeExecutor.mqh"

//+------------------------------------------------------------------+
//| Input Parameters - PARAMÈTRES DE RISQUE (CORRIGÉS)               |
//+------------------------------------------------------------------+
input group "=== PARAMÈTRES SL/TP (CRITIQUES) ==="
input double   InpSLMultiplier = 1.50;           // Multiplicateur SL (×ATR) - CORRECT: 1.5
input double   InpTPMultiplier = 3.00;           // Multiplicateur TP (×ATR) - CORRECT: 3.0

input group "=== PARAMÈTRES DE RISQUE ==="
input double   InpRiskPercent = 1.0;             // Risque par trade (%)
input double   InpMaxDailyDrawdown = 5.0;        // Drawdown max journalier (%)
input int      InpMaxPositions = 3;              // Nombre max de positions

input group "=== PARAMÈTRES ATR ==="
input int      InpATRPeriod = 14;                // Période ATR
input ENUM_TIMEFRAMES InpATRTimeframe = PERIOD_CURRENT; // Timeframe ATR

input group "=== PARAMÈTRES DE TRADING ==="
input ulong    InpMagicNumber = 123456;          // Magic Number
input int      InpSlippage = 30;                 // Slippage (points)
input double   InpLotSize = 0.01;                // Taille de lot fixe
input bool     InpUseAutoLot = true;             // Utiliser lot automatique

input group "=== PARAMÈTRES DE SESSION ==="
input int      InpTradingStartHour = 8;          // Heure de début (serveur)
input int      InpTradingEndHour = 20;           // Heure de fin (serveur)
input bool     InpTradeOnMonday = true;          // Trader le lundi
input bool     InpTradeOnTuesday = true;         // Trader le mardi
input bool     InpTradeOnWednesday = true;       // Trader le mercredi
input bool     InpTradeOnThursday = true;        // Trader le jeudi
input bool     InpTradeOnFriday = true;          // Trader le vendredi

input group "=== PARAMÈTRES DE STRATÉGIE ==="
input int      InpRSIPeriod = 14;                // Période RSI
input int      InpRSIOverbought = 70;            // Niveau RSI suracheté
input int      InpRSIOversold = 30;              // Niveau RSI survendu
input int      InpMAPeriodFast = 20;             // Période MA rapide
input int      InpMAPeriodSlow = 50;             // Période MA lente
input bool     InpUseBreakoutStrategy = true;    // Activer stratégie breakout
input bool     InpUseTrendStrategy = true;       // Activer stratégie tendance

input group "=== PARAMÈTRES DE LOGGING ==="
input bool     InpEnableLogging = true;          // Activer le logging CSV
input int      InpLogLevel = 2;                  // Niveau de log (0-3)
input bool     InpEnableParameterVerification = true; // Activer vérification SL/TP

input group "=== PARAMÈTRES AVANCÉS ==="
input bool     InpUseTrailingStop = false;       // Utiliser trailing stop
input double   InpTrailingStopATR = 1.0;         // Trailing stop (×ATR)
input double   InpBreakevenATR = 0.5;            // Breakeven (×ATR)

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CLogger        g_Logger;           // Instance du logger
CRiskManager   g_RiskManager;      // Instance du gestionnaire de risque
CTradeExecutor g_TradeExecutor;    // Instance de l'exécuteur de trades

int            g_atrHandle;        // Handle de l'indicateur ATR
int            g_rsiHandle;        // Handle de l'indicateur RSI
int            g_maFastHandle;     // Handle MA rapide
int            g_maSlowHandle;     // Handle MA lente

int            g_totalTrades;      // Compteur de trades
int            g_winTrades;        // Compteur de trades gagnants
int            g_lossTrades;       // Compteur de trades perdants

double         g_lastATR;          // Dernière valeur ATR
datetime       g_lastBarTime;      // Temps de la dernière barre traitée

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
    // === AFFICHAGE DES PARAMÈTRES CRITIQUES ===
    Print("========================================");
    Print("Gold EA Professional v2.0 - INITIALISATION");
    Print("========================================");
    Print("PARAMÈTRES SL/TP CONFIGURÉS:");
    Print("  SL Multiplier: ", InpSLMultiplier, " × ATR");
    Print("  TP Multiplier: ", InpTPMultiplier, " × ATR");
    Print("  R:R Ratio cible: ", DoubleToString(InpTPMultiplier / InpSLMultiplier, 2));
    Print("========================================");

    // Vérification des paramètres SL/TP
    if(InpSLMultiplier <= 0 || InpTPMultiplier <= 0)
    {
        Print("ERREUR: Multipliers SL/TP doivent être > 0");
        return INIT_PARAMETERS_INCORRECT;
    }

    // Vérification du symbole
    if(StringFind(_Symbol, "XAU") < 0 && StringFind(_Symbol, "GOLD") < 0)
    {
        Print("AVERTISSEMENT: Ce EA est optimisé pour XAUUSD/GOLD");
    }

    // Initialiser le Logger
    if(!g_Logger.Init("GoldEA_", InpEnableLogging, InpLogLevel))
    {
        Print("ERREUR: Impossible d'initialiser le logger");
        return INIT_FAILED;
    }
    g_Logger.EnableParameterVerification(InpEnableParameterVerification);

    // Initialiser le Risk Manager
    if(!g_RiskManager.Init(InpRiskPercent, InpMaxDailyDrawdown, InpMaxPositions))
    {
        Print("ERREUR: Impossible d'initialiser le gestionnaire de risque");
        return INIT_FAILED;
    }

    // Initialiser le Trade Executor
    if(!g_TradeExecutor.Init(InpMagicNumber, InpSlippage, 3))
    {
        Print("ERREUR: Impossible d'initialiser l'exécuteur de trades");
        return INIT_FAILED;
    }

    // Créer les handles d'indicateurs
    g_atrHandle = iATR(_Symbol, InpATRTimeframe, InpATRPeriod);
    if(g_atrHandle == INVALID_HANDLE)
    {
        Print("ERREUR: Impossible de créer l'indicateur ATR");
        return INIT_FAILED;
    }

    g_rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE);
    if(g_rsiHandle == INVALID_HANDLE)
    {
        Print("ERREUR: Impossible de créer l'indicateur RSI");
        return INIT_FAILED;
    }

    g_maFastHandle = iMA(_Symbol, PERIOD_CURRENT, InpMAPeriodFast, 0, MODE_EMA, PRICE_CLOSE);
    g_maSlowHandle = iMA(_Symbol, PERIOD_CURRENT, InpMAPeriodSlow, 0, MODE_EMA, PRICE_CLOSE);

    if(g_maFastHandle == INVALID_HANDLE || g_maSlowHandle == INVALID_HANDLE)
    {
        Print("ERREUR: Impossible de créer les indicateurs MA");
        return INIT_FAILED;
    }

    // Initialiser les variables
    g_totalTrades = 0;
    g_winTrades = 0;
    g_lossTrades = 0;
    g_lastATR = 0;
    g_lastBarTime = 0;

    // Logger l'initialisation
    g_Logger.LogMessage(1, "EA initialisé avec succès");
    g_Logger.LogMessage(1, "SL=" + DoubleToString(InpSLMultiplier, 2) + "×ATR | TP=" +
                          DoubleToString(InpTPMultiplier, 2) + "×ATR | R:R=" +
                          DoubleToString(InpTPMultiplier/InpSLMultiplier, 2));

    Print("Gold EA Professional v2.0 - Prêt à trader");

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Libérer les indicateurs
    if(g_atrHandle != INVALID_HANDLE) IndicatorRelease(g_atrHandle);
    if(g_rsiHandle != INVALID_HANDLE) IndicatorRelease(g_rsiHandle);
    if(g_maFastHandle != INVALID_HANDLE) IndicatorRelease(g_maFastHandle);
    if(g_maSlowHandle != INVALID_HANDLE) IndicatorRelease(g_maSlowHandle);

    // Logger les statistiques finales
    g_Logger.LogMessage(1, "EA arrêté - Trades: " + IntegerToString(g_totalTrades) +
                          " | Wins: " + IntegerToString(g_winTrades) +
                          " | Losses: " + IntegerToString(g_lossTrades));

    // Fermer le logger
    g_Logger.Deinit();

    Print("Gold EA Professional v2.0 - Arrêt propre");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
    // Vérifier si nouvelle barre
    datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    if(currentBarTime == g_lastBarTime)
        return;  // Pas de nouvelle barre

    g_lastBarTime = currentBarTime;

    // Vérifier les conditions de trading
    if(!IsTradingAllowed())
        return;

    // Mettre à jour l'ATR
    double atr[];
    ArraySetAsSeries(atr, true);
    if(CopyBuffer(g_atrHandle, 0, 0, 1, atr) <= 0)
    {
        g_Logger.LogError(GetLastError(), "Impossible de lire l'ATR", "OnTick");
        return;
    }
    g_lastATR = atr[0];

    // Vérifier si on peut ouvrir de nouvelles positions
    if(!g_RiskManager.CanOpenNewPosition())
    {
        return;
    }

    // Analyser le signal
    int signal = AnalyzeSignal();

    // Exécuter le trade si signal
    if(signal != 0)
    {
        ExecuteTrade(signal);
    }

    // Gérer les positions ouvertes
    ManageOpenPositions();
}

//+------------------------------------------------------------------+
//| Vérifier si le trading est autorisé                              |
//+------------------------------------------------------------------+
bool IsTradingAllowed()
{
    // Vérifier l'heure
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);

    if(dt.hour < InpTradingStartHour || dt.hour >= InpTradingEndHour)
        return false;

    // Vérifier le jour
    switch(dt.day_of_week)
    {
        case 1: if(!InpTradeOnMonday) return false; break;
        case 2: if(!InpTradeOnTuesday) return false; break;
        case 3: if(!InpTradeOnWednesday) return false; break;
        case 4: if(!InpTradeOnThursday) return false; break;
        case 5: if(!InpTradeOnFriday) return false; break;
        default: return false;  // Weekend
    }

    // Vérifier si le trading automatique est activé
    if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
        return false;

    return true;
}

//+------------------------------------------------------------------+
//| Analyser le signal de trading                                    |
//+------------------------------------------------------------------+
int AnalyzeSignal()
{
    // Obtenir les valeurs des indicateurs
    double rsi[];
    double maFast[];
    double maSlow[];

    ArraySetAsSeries(rsi, true);
    ArraySetAsSeries(maFast, true);
    ArraySetAsSeries(maSlow, true);

    if(CopyBuffer(g_rsiHandle, 0, 0, 3, rsi) <= 0) return 0;
    if(CopyBuffer(g_maFastHandle, 0, 0, 3, maFast) <= 0) return 0;
    if(CopyBuffer(g_maSlowHandle, 0, 0, 3, maSlow) <= 0) return 0;

    int signal = 0;
    string signalType = "";
    string conditions = "";

    // === STRATÉGIE TENDANCE ===
    if(InpUseTrendStrategy)
    {
        // Signal BUY: MA rapide croise au-dessus de MA lente + RSI < 70
        if(maFast[1] > maSlow[1] && maFast[2] <= maSlow[2] && rsi[1] < InpRSIOverbought)
        {
            signal = 1;  // BUY
            signalType = "TREND_BUY";
            conditions = "MA Cross Up + RSI<" + IntegerToString(InpRSIOverbought);
        }
        // Signal SELL: MA rapide croise en-dessous de MA lente + RSI > 30
        else if(maFast[1] < maSlow[1] && maFast[2] >= maSlow[2] && rsi[1] > InpRSIOversold)
        {
            signal = -1;  // SELL
            signalType = "TREND_SELL";
            conditions = "MA Cross Down + RSI>" + IntegerToString(InpRSIOversold);
        }
    }

    // === STRATÉGIE BREAKOUT ===
    if(InpUseBreakoutStrategy && signal == 0)
    {
        // Obtenir les prix
        double high = iHigh(_Symbol, PERIOD_CURRENT, 1);
        double low = iLow(_Symbol, PERIOD_CURRENT, 1);
        double close = iClose(_Symbol, PERIOD_CURRENT, 1);

        // Breakout haussier: close > high + ATR
        double breakoutLevel = high + g_lastATR * 0.5;
        double breakdownLevel = low - g_lastATR * 0.5;

        double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);

        if(currentPrice > breakoutLevel && rsi[1] < 80)
        {
            signal = 1;  // BUY
            signalType = "BREAKOUT_BUY";
            conditions = "Price > High + 0.5×ATR";
        }
        else if(currentPrice < breakdownLevel && rsi[1] > 20)
        {
            signal = -1;  // SELL
            signalType = "BREAKOUT_SELL";
            conditions = "Price < Low - 0.5×ATR";
        }
    }

    // Logger le signal
    if(signal != 0)
    {
        double strength = MathAbs(rsi[1] - 50) / 50.0 * 100;  // Force relative
        g_Logger.LogSignal(signalType, strength, conditions, true);
    }

    return signal;
}

//+------------------------------------------------------------------+
//| Exécuter un trade                                                |
//+------------------------------------------------------------------+
void ExecuteTrade(int signal)
{
    // Obtenir le prix d'entrée
    double price = (signal > 0) ?
                   SymbolInfoDouble(_Symbol, SYMBOL_ASK) :
                   SymbolInfoDouble(_Symbol, SYMBOL_BID);

    // Calculer SL et TP avec les multipliers CORRIGÉS
    bool isBuy = (signal > 0);
    double sl = g_RiskManager.CalculateSLPrice(price, g_lastATR, InpSLMultiplier, isBuy);
    double tp = g_RiskManager.CalculateTPPrice(price, g_lastATR, InpTPMultiplier, isBuy);

    // Valider SL/TP
    if(!g_RiskManager.ValidateSLTP(price, sl, tp, isBuy))
    {
        g_Logger.LogError(0, "SL/TP validation failed", g_RiskManager.GetLastError());
        return;
    }

    // Calculer la taille du lot
    double slDistance = MathAbs(price - sl);
    double lots = InpUseAutoLot ?
                  g_RiskManager.CalculateLotSize(slDistance, _Symbol) :
                  InpLotSize;

    // Incrémenter le compteur de trades
    g_totalTrades++;

    // Préparer le commentaire
    string comment = StringFormat("GoldEA#%d|SL%.2f|TP%.2f",
                                  g_totalTrades, InpSLMultiplier, InpTPMultiplier);

    // ============================================================
    // APPEL CRITIQUE: Logger la vérification des paramètres SL/TP
    // Cette fonction vérifie que les SL/TP calculés correspondent
    // aux paramètres configurés (InpSLMultiplier, InpTPMultiplier)
    // ============================================================
    g_Logger.LogParametersVerification(
        g_totalTrades,          // Numéro du trade
        InpSLMultiplier,        // Multiplicateur SL configuré (1.50)
        InpTPMultiplier,        // Multiplicateur TP configuré (3.00)
        g_lastATR,              // Valeur ATR actuelle
        price,                  // Prix d'entrée
        sl,                     // Prix SL calculé
        tp                      // Prix TP calculé
    );

    // Exécuter le trade
    SExecutionResult result;
    if(isBuy)
    {
        result = g_TradeExecutor.ExecuteBuy(_Symbol, lots, sl, tp, comment);
    }
    else
    {
        result = g_TradeExecutor.ExecuteSell(_Symbol, lots, sl, tp, comment);
    }

    // Logger le trade
    if(result.status == EXEC_SUCCESS)
    {
        string action = isBuy ? "BUY" : "SELL";
        g_Logger.LogTrade(g_totalTrades, action, result.fillPrice, sl, tp,
                         result.fillLots, (int)result.ticket, comment);

        Print("========================================");
        Print("TRADE EXÉCUTÉ #", g_totalTrades);
        Print("  Action: ", action);
        Print("  Prix: ", result.fillPrice);
        Print("  SL: ", sl, " (", InpSLMultiplier, "×ATR)");
        Print("  TP: ", tp, " (", InpTPMultiplier, "×ATR)");
        Print("  R:R: ", DoubleToString(InpTPMultiplier/InpSLMultiplier, 2));
        Print("  ATR: ", g_lastATR);
        Print("  Lots: ", result.fillLots);
        Print("========================================");
    }
    else
    {
        g_Logger.LogError(result.retcode, result.message, "ExecuteTrade");
    }
}

//+------------------------------------------------------------------+
//| Gérer les positions ouvertes                                     |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
    if(!InpUseTrailingStop)
        return;

    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(!PositionSelectByTicket(ticket))
            continue;

        // Vérifier le magic number
        if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
            continue;

        // Vérifier le symbole
        if(PositionGetString(POSITION_SYMBOL) != _Symbol)
            continue;

        // Obtenir les infos de position
        double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double currentSL = PositionGetDouble(POSITION_SL);
        double currentTP = PositionGetDouble(POSITION_TP);
        ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

        bool isBuy = (posType == POSITION_TYPE_BUY);
        double currentPrice = isBuy ?
                             SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                             SymbolInfoDouble(_Symbol, SYMBOL_ASK);

        // Trailing stop
        double trailingDistance = g_lastATR * InpTrailingStopATR;
        double newSL = 0;

        if(isBuy)
        {
            // Pour BUY: déplacer SL vers le haut
            double profitDistance = currentPrice - openPrice;
            if(profitDistance > trailingDistance)
            {
                newSL = currentPrice - trailingDistance;
                if(newSL > currentSL)
                {
                    g_TradeExecutor.ModifyPosition(ticket, newSL, currentTP);
                }
            }
        }
        else
        {
            // Pour SELL: déplacer SL vers le bas
            double profitDistance = openPrice - currentPrice;
            if(profitDistance > trailingDistance)
            {
                newSL = currentPrice + trailingDistance;
                if(newSL < currentSL)
                {
                    g_TradeExecutor.ModifyPosition(ticket, newSL, currentTP);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Trade transaction event                                          |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
    // Traiter uniquement les deals (transactions complètes)
    if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
        return;

    // Vérifier si c'est un trade de sortie
    if(trans.deal_type == DEAL_TYPE_BUY || trans.deal_type == DEAL_TYPE_SELL)
    {
        // Obtenir les infos du deal
        ulong dealTicket = trans.deal;

        if(!HistoryDealSelect(dealTicket))
            return;

        ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
        double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
        ulong magic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);

        // Vérifier le magic number
        if(magic != InpMagicNumber)
            return;

        // Compter les wins/losses
        if(entry == DEAL_ENTRY_OUT)
        {
            if(profit > 0)
                g_winTrades++;
            else if(profit < 0)
                g_lossTrades++;

            // Mettre à jour les stats de risque
            g_RiskManager.UpdateDailyStats(profit);

            // Logger la performance
            double balance = AccountInfoDouble(ACCOUNT_BALANCE);
            double equity = AccountInfoDouble(ACCOUNT_EQUITY);
            double drawdown = g_RiskManager.GetDailyDrawdown();
            double pf = (g_lossTrades > 0) ? (double)g_winTrades / g_lossTrades : g_winTrades;

            g_Logger.LogPerformance(balance, equity, drawdown, g_totalTrades, g_winTrades, pf);
        }
    }
}

//+------------------------------------------------------------------+
