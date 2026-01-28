//+------------------------------------------------------------------+
//|                                                  RiskManager.mqh |
//|                      Gold EA Professional v2.0 - Risk Manager    |
//|                  Gestion des Risques et Calcul des Lots          |
//+------------------------------------------------------------------+
#property copyright "Gold EA Professional"
#property link      ""
#property version   "2.0"
#property strict

//+------------------------------------------------------------------+
//| Classe CRiskManager - Gestion des risques                        |
//+------------------------------------------------------------------+
class CRiskManager
{
private:
    // Paramètres de risque
    double          m_riskPercent;          // Risque par trade (%)
    double          m_maxDailyDrawdown;     // Drawdown max journalier (%)
    int             m_maxPositions;         // Nombre max de positions
    double          m_minLotSize;           // Taille de lot minimum
    double          m_maxLotSize;           // Taille de lot maximum
    double          m_lotStep;              // Pas de lot

    // Statistiques journalières
    double          m_dailyStartBalance;
    double          m_dailyProfit;
    double          m_dailyDrawdown;
    datetime        m_lastResetDate;

    // État
    bool            m_tradingAllowed;
    string          m_lastError;

public:
    // Constructeur / Destructeur
                    CRiskManager();
                   ~CRiskManager();

    // Initialisation
    bool            Init(double riskPercent, double maxDD, int maxPos);
    void            ResetDaily();

    // Configuration
    void            SetRiskPercent(double risk) { m_riskPercent = MathMax(0.1, MathMin(risk, 10.0)); }
    void            SetMaxDailyDrawdown(double maxDD) { m_maxDailyDrawdown = maxDD; }
    void            SetMaxPositions(int maxPos) { m_maxPositions = maxPos; }

    // Calculs
    double          CalculateLotSize(double slDistance, string symbol);
    double          CalculateSLPrice(double entryPrice, double atr, double multiplier, bool isBuy);
    double          CalculateTPPrice(double entryPrice, double atr, double multiplier, bool isBuy);

    // Vérifications
    bool            CanOpenNewPosition();
    bool            CheckDailyDrawdown();
    bool            ValidateSLTP(double entry, double sl, double tp, bool isBuy);

    // Getters
    double          GetRiskPercent() { return m_riskPercent; }
    double          GetDailyDrawdown() { return m_dailyDrawdown; }
    bool            IsTradingAllowed() { return m_tradingAllowed; }
    string          GetLastError() { return m_lastError; }

    // Mise à jour
    void            UpdateDailyStats(double profit);
};

//+------------------------------------------------------------------+
//| Constructeur                                                      |
//+------------------------------------------------------------------+
CRiskManager::CRiskManager()
{
    m_riskPercent = 1.0;
    m_maxDailyDrawdown = 5.0;
    m_maxPositions = 3;
    m_minLotSize = 0.01;
    m_maxLotSize = 100.0;
    m_lotStep = 0.01;

    m_dailyStartBalance = 0;
    m_dailyProfit = 0;
    m_dailyDrawdown = 0;
    m_lastResetDate = 0;

    m_tradingAllowed = true;
    m_lastError = "";
}

//+------------------------------------------------------------------+
//| Destructeur                                                       |
//+------------------------------------------------------------------+
CRiskManager::~CRiskManager()
{
}

//+------------------------------------------------------------------+
//| Initialisation                                                    |
//+------------------------------------------------------------------+
bool CRiskManager::Init(double riskPercent, double maxDD, int maxPos)
{
    m_riskPercent = MathMax(0.1, MathMin(riskPercent, 10.0));
    m_maxDailyDrawdown = MathMax(1.0, MathMin(maxDD, 50.0));
    m_maxPositions = MathMax(1, MathMin(maxPos, 10));

    // Obtenir les infos du symbole pour les lots
    m_minLotSize = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    m_maxLotSize = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    m_lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

    // Initialiser les stats journalières
    m_dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    m_lastResetDate = TimeCurrent();

    Print("RISK MANAGER: Initialized - Risk:", m_riskPercent, "% | MaxDD:", m_maxDailyDrawdown,
          "% | MaxPos:", m_maxPositions);
    Print("RISK MANAGER: Lot constraints - Min:", m_minLotSize, " Max:", m_maxLotSize,
          " Step:", m_lotStep);

    return true;
}

//+------------------------------------------------------------------+
//| Réinitialisation journalière                                      |
//+------------------------------------------------------------------+
void CRiskManager::ResetDaily()
{
    MqlDateTime now;
    TimeToStruct(TimeCurrent(), now);

    MqlDateTime last;
    TimeToStruct(m_lastResetDate, last);

    // Reset si nouveau jour
    if(now.day != last.day || now.mon != last.mon || now.year != last.year)
    {
        m_dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        m_dailyProfit = 0;
        m_dailyDrawdown = 0;
        m_tradingAllowed = true;
        m_lastResetDate = TimeCurrent();

        Print("RISK MANAGER: Daily reset - New balance baseline:", m_dailyStartBalance);
    }
}

//+------------------------------------------------------------------+
//| Calculer la taille du lot basée sur le risque                    |
//+------------------------------------------------------------------+
double CRiskManager::CalculateLotSize(double slDistance, string symbol)
{
    if(slDistance <= 0)
    {
        m_lastError = "Invalid SL distance";
        return m_minLotSize;
    }

    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = balance * (m_riskPercent / 100.0);

    // Valeur du tick pour le symbole
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);

    if(tickValue <= 0 || tickSize <= 0)
    {
        m_lastError = "Invalid tick value/size";
        return m_minLotSize;
    }

    // Calcul: Lot = RiskAmount / (SL_Distance / TickSize * TickValue)
    double ticksInSL = slDistance / tickSize;
    double lotSize = riskAmount / (ticksInSL * tickValue);

    // Arrondir au lot step
    lotSize = MathFloor(lotSize / m_lotStep) * m_lotStep;

    // Appliquer les limites
    lotSize = MathMax(m_minLotSize, MathMin(lotSize, m_maxLotSize));

    Print("RISK MANAGER: Calculated lot size: ", lotSize,
          " (Risk:", riskAmount, " | SL Dist:", slDistance, ")");

    return lotSize;
}

//+------------------------------------------------------------------+
//| Calculer le prix du Stop Loss                                     |
//+------------------------------------------------------------------+
double CRiskManager::CalculateSLPrice(double entryPrice, double atr, double multiplier, bool isBuy)
{
    double slDistance = atr * multiplier;
    double slPrice;

    if(isBuy)
    {
        slPrice = entryPrice - slDistance;
    }
    else
    {
        slPrice = entryPrice + slDistance;
    }

    // Normaliser au tick size
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    slPrice = MathRound(slPrice / tickSize) * tickSize;

    return slPrice;
}

//+------------------------------------------------------------------+
//| Calculer le prix du Take Profit                                   |
//+------------------------------------------------------------------+
double CRiskManager::CalculateTPPrice(double entryPrice, double atr, double multiplier, bool isBuy)
{
    double tpDistance = atr * multiplier;
    double tpPrice;

    if(isBuy)
    {
        tpPrice = entryPrice + tpDistance;
    }
    else
    {
        tpPrice = entryPrice - tpDistance;
    }

    // Normaliser au tick size
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    tpPrice = MathRound(tpPrice / tickSize) * tickSize;

    return tpPrice;
}

//+------------------------------------------------------------------+
//| Vérifier si on peut ouvrir une nouvelle position                  |
//+------------------------------------------------------------------+
bool CRiskManager::CanOpenNewPosition()
{
    ResetDaily();  // Vérifier reset journalier

    if(!m_tradingAllowed)
    {
        m_lastError = "Trading disabled (daily drawdown limit reached)";
        return false;
    }

    // Compter les positions ouvertes
    int openPositions = 0;
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionSelectByTicket(PositionGetTicket(i)))
        {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol)
                openPositions++;
        }
    }

    if(openPositions >= m_maxPositions)
    {
        m_lastError = "Maximum positions reached (" + IntegerToString(m_maxPositions) + ")";
        return false;
    }

    // Vérifier le drawdown journalier
    if(!CheckDailyDrawdown())
    {
        return false;
    }

    return true;
}

//+------------------------------------------------------------------+
//| Vérifier le drawdown journalier                                   |
//+------------------------------------------------------------------+
bool CRiskManager::CheckDailyDrawdown()
{
    double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double drawdownPercent = 0;

    if(m_dailyStartBalance > 0)
    {
        drawdownPercent = ((m_dailyStartBalance - currentBalance) / m_dailyStartBalance) * 100;
    }

    m_dailyDrawdown = drawdownPercent;

    if(drawdownPercent >= m_maxDailyDrawdown)
    {
        m_tradingAllowed = false;
        m_lastError = "Daily drawdown limit reached: " + DoubleToString(drawdownPercent, 2) + "%";
        Print("RISK MANAGER: ", m_lastError);
        return false;
    }

    return true;
}

//+------------------------------------------------------------------+
//| Valider les niveaux SL/TP                                        |
//+------------------------------------------------------------------+
bool CRiskManager::ValidateSLTP(double entry, double sl, double tp, bool isBuy)
{
    // Vérifier la distance minimale du stop
    double minStop = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);

    double slDist = MathAbs(entry - sl);
    double tpDist = MathAbs(tp - entry);

    if(slDist < minStop)
    {
        m_lastError = "SL too close to entry (min: " + DoubleToString(minStop, 2) + ")";
        return false;
    }

    if(tpDist < minStop)
    {
        m_lastError = "TP too close to entry (min: " + DoubleToString(minStop, 2) + ")";
        return false;
    }

    // Vérifier la cohérence des niveaux
    if(isBuy)
    {
        if(sl >= entry)
        {
            m_lastError = "BUY: SL must be below entry price";
            return false;
        }
        if(tp <= entry)
        {
            m_lastError = "BUY: TP must be above entry price";
            return false;
        }
    }
    else
    {
        if(sl <= entry)
        {
            m_lastError = "SELL: SL must be above entry price";
            return false;
        }
        if(tp >= entry)
        {
            m_lastError = "SELL: TP must be below entry price";
            return false;
        }
    }

    return true;
}

//+------------------------------------------------------------------+
//| Mise à jour des statistiques journalières                        |
//+------------------------------------------------------------------+
void CRiskManager::UpdateDailyStats(double profit)
{
    m_dailyProfit += profit;

    // Recalculer le drawdown
    CheckDailyDrawdown();
}

//+------------------------------------------------------------------+
