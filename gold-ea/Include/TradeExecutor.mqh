//+------------------------------------------------------------------+
//|                                                TradeExecutor.mqh |
//|                     Gold EA Professional v2.0 - Trade Executor   |
//|                         Exécution des Ordres de Trading          |
//+------------------------------------------------------------------+
#property copyright "Gold EA Professional"
#property link      ""
#property version   "2.0"
#property strict

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Énumération des résultats d'exécution                            |
//+------------------------------------------------------------------+
enum ENUM_EXEC_RESULT
{
    EXEC_SUCCESS,           // Exécution réussie
    EXEC_FAILED,            // Échec de l'exécution
    EXEC_INVALID_PARAMS,    // Paramètres invalides
    EXEC_NO_MONEY,          // Fonds insuffisants
    EXEC_MARKET_CLOSED,     // Marché fermé
    EXEC_RETRY_LATER        // Réessayer plus tard
};

//+------------------------------------------------------------------+
//| Structure de résultat d'exécution                                |
//+------------------------------------------------------------------+
struct SExecutionResult
{
    ENUM_EXEC_RESULT    status;
    ulong               ticket;
    double              fillPrice;
    double              fillLots;
    int                 retcode;
    string              message;
};

//+------------------------------------------------------------------+
//| Classe CTradeExecutor - Exécution des ordres                     |
//+------------------------------------------------------------------+
class CTradeExecutor
{
private:
    CTrade              m_trade;            // Objet trade MQL5
    ulong               m_magicNumber;      // Magic number
    int                 m_slippage;         // Slippage en points
    int                 m_maxRetries;       // Nombre max de tentatives

    // Statistiques
    int                 m_totalExecutions;
    int                 m_successfulExecutions;
    int                 m_failedExecutions;

    // État
    string              m_lastError;
    SExecutionResult    m_lastResult;

    // Méthodes privées
    bool                PrepareOrderRequest(MqlTradeRequest &request,
                                           string symbol, ENUM_ORDER_TYPE orderType,
                                           double lots, double price,
                                           double sl, double tp, string comment);
    bool                TryExecuteOrder(MqlTradeRequest &request, MqlTradeResult &result);
    ENUM_ORDER_TYPE_FILLING GetBestFillingMode(string symbol);

public:
    // Constructeur / Destructeur
                        CTradeExecutor();
                       ~CTradeExecutor();

    // Initialisation
    bool                Init(ulong magic, int slippage = 30, int maxRetries = 3);

    // Configuration
    void                SetMagicNumber(ulong magic);
    void                SetSlippage(int slippage) { m_slippage = slippage; }
    void                SetMaxRetries(int retries) { m_maxRetries = retries; }

    // Exécution des ordres
    SExecutionResult    ExecuteBuy(string symbol, double lots, double sl, double tp, string comment = "");
    SExecutionResult    ExecuteSell(string symbol, double lots, double sl, double tp, string comment = "");
    bool                ClosePosition(ulong ticket);
    bool                CloseAllPositions(string symbol = "");
    bool                ModifyPosition(ulong ticket, double newSL, double newTP);

    // Getters
    ulong               GetMagicNumber() { return m_magicNumber; }
    string              GetLastError() { return m_lastError; }
    SExecutionResult    GetLastResult() { return m_lastResult; }
    int                 GetTotalExecutions() { return m_totalExecutions; }
    int                 GetSuccessRate();

    // Utilitaires
    double              NormalizePrice(string symbol, double price);
    double              NormalizeLots(string symbol, double lots);
    bool                IsMarketOpen(string symbol);
};

//+------------------------------------------------------------------+
//| Constructeur                                                      |
//+------------------------------------------------------------------+
CTradeExecutor::CTradeExecutor()
{
    m_magicNumber = 0;
    m_slippage = 30;
    m_maxRetries = 3;

    m_totalExecutions = 0;
    m_successfulExecutions = 0;
    m_failedExecutions = 0;

    m_lastError = "";
}

//+------------------------------------------------------------------+
//| Destructeur                                                       |
//+------------------------------------------------------------------+
CTradeExecutor::~CTradeExecutor()
{
}

//+------------------------------------------------------------------+
//| Initialisation                                                    |
//+------------------------------------------------------------------+
bool CTradeExecutor::Init(ulong magic, int slippage = 30, int maxRetries = 3)
{
    m_magicNumber = magic;
    m_slippage = slippage;
    m_maxRetries = maxRetries;

    // Configurer l'objet trade
    m_trade.SetExpertMagicNumber(magic);
    m_trade.SetDeviationInPoints(slippage);
    m_trade.SetTypeFilling(ORDER_FILLING_FOK);
    m_trade.SetAsyncMode(false);

    Print("TRADE EXECUTOR: Initialized - Magic:", magic, " | Slippage:", slippage,
          " | MaxRetries:", maxRetries);

    return true;
}

//+------------------------------------------------------------------+
//| Définir le magic number                                          |
//+------------------------------------------------------------------+
void CTradeExecutor::SetMagicNumber(ulong magic)
{
    m_magicNumber = magic;
    m_trade.SetExpertMagicNumber(magic);
}

//+------------------------------------------------------------------+
//| Obtenir le meilleur mode de remplissage                          |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING CTradeExecutor::GetBestFillingMode(string symbol)
{
    uint filling = (uint)SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);

    if((filling & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
        return ORDER_FILLING_FOK;

    if((filling & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
        return ORDER_FILLING_IOC;

    return ORDER_FILLING_RETURN;
}

//+------------------------------------------------------------------+
//| Préparer la requête d'ordre                                      |
//+------------------------------------------------------------------+
bool CTradeExecutor::PrepareOrderRequest(MqlTradeRequest &request,
                                         string symbol, ENUM_ORDER_TYPE orderType,
                                         double lots, double price,
                                         double sl, double tp, string comment)
{
    ZeroMemory(request);

    request.action = TRADE_ACTION_DEAL;
    request.symbol = symbol;
    request.volume = NormalizeLots(symbol, lots);
    request.type = orderType;
    request.price = NormalizePrice(symbol, price);
    request.sl = NormalizePrice(symbol, sl);
    request.tp = NormalizePrice(symbol, tp);
    request.deviation = m_slippage;
    request.magic = m_magicNumber;
    request.comment = comment;
    request.type_filling = GetBestFillingMode(symbol);

    return true;
}

//+------------------------------------------------------------------+
//| Tenter d'exécuter un ordre                                       |
//+------------------------------------------------------------------+
bool CTradeExecutor::TryExecuteOrder(MqlTradeRequest &request, MqlTradeResult &result)
{
    ZeroMemory(result);

    for(int attempt = 1; attempt <= m_maxRetries; attempt++)
    {
        // Rafraîchir les prix
        if(request.type == ORDER_TYPE_BUY)
            request.price = SymbolInfoDouble(request.symbol, SYMBOL_ASK);
        else
            request.price = SymbolInfoDouble(request.symbol, SYMBOL_BID);

        request.price = NormalizePrice(request.symbol, request.price);

        // Envoyer l'ordre
        if(OrderSend(request, result))
        {
            if(result.retcode == TRADE_RETCODE_DONE ||
               result.retcode == TRADE_RETCODE_PLACED)
            {
                return true;
            }
        }

        // Traiter les erreurs récupérables
        if(result.retcode == TRADE_RETCODE_REQUOTE ||
           result.retcode == TRADE_RETCODE_PRICE_CHANGED ||
           result.retcode == TRADE_RETCODE_PRICE_OFF)
        {
            Print("TRADE EXECUTOR: Retry ", attempt, "/", m_maxRetries,
                  " - Retcode: ", result.retcode);
            Sleep(100 * attempt);  // Backoff exponentiel
            continue;
        }

        // Erreur non récupérable
        break;
    }

    return false;
}

//+------------------------------------------------------------------+
//| Exécuter un ordre BUY                                            |
//+------------------------------------------------------------------+
SExecutionResult CTradeExecutor::ExecuteBuy(string symbol, double lots,
                                            double sl, double tp, string comment = "")
{
    SExecutionResult result;
    ZeroMemory(result);

    m_totalExecutions++;

    // Vérifier le marché
    if(!IsMarketOpen(symbol))
    {
        result.status = EXEC_MARKET_CLOSED;
        result.message = "Market is closed";
        m_lastError = result.message;
        m_failedExecutions++;
        m_lastResult = result;
        return result;
    }

    // Obtenir le prix actuel
    double price = SymbolInfoDouble(symbol, SYMBOL_ASK);

    // Préparer et exécuter
    MqlTradeRequest request;
    MqlTradeResult tradeResult;

    PrepareOrderRequest(request, symbol, ORDER_TYPE_BUY, lots, price, sl, tp, comment);

    if(TryExecuteOrder(request, tradeResult))
    {
        result.status = EXEC_SUCCESS;
        result.ticket = tradeResult.order;
        result.fillPrice = tradeResult.price;
        result.fillLots = tradeResult.volume;
        result.retcode = (int)tradeResult.retcode;
        result.message = "BUY order executed successfully";

        m_successfulExecutions++;

        Print("TRADE EXECUTOR: BUY SUCCESS - Ticket:", result.ticket,
              " | Price:", result.fillPrice, " | SL:", sl, " | TP:", tp);
    }
    else
    {
        result.status = EXEC_FAILED;
        result.retcode = (int)tradeResult.retcode;
        result.message = "BUY order failed: " + IntegerToString(tradeResult.retcode);

        m_lastError = result.message;
        m_failedExecutions++;

        Print("TRADE EXECUTOR: BUY FAILED - Retcode:", tradeResult.retcode,
              " | Comment:", tradeResult.comment);
    }

    m_lastResult = result;
    return result;
}

//+------------------------------------------------------------------+
//| Exécuter un ordre SELL                                           |
//+------------------------------------------------------------------+
SExecutionResult CTradeExecutor::ExecuteSell(string symbol, double lots,
                                             double sl, double tp, string comment = "")
{
    SExecutionResult result;
    ZeroMemory(result);

    m_totalExecutions++;

    // Vérifier le marché
    if(!IsMarketOpen(symbol))
    {
        result.status = EXEC_MARKET_CLOSED;
        result.message = "Market is closed";
        m_lastError = result.message;
        m_failedExecutions++;
        m_lastResult = result;
        return result;
    }

    // Obtenir le prix actuel
    double price = SymbolInfoDouble(symbol, SYMBOL_BID);

    // Préparer et exécuter
    MqlTradeRequest request;
    MqlTradeResult tradeResult;

    PrepareOrderRequest(request, symbol, ORDER_TYPE_SELL, lots, price, sl, tp, comment);

    if(TryExecuteOrder(request, tradeResult))
    {
        result.status = EXEC_SUCCESS;
        result.ticket = tradeResult.order;
        result.fillPrice = tradeResult.price;
        result.fillLots = tradeResult.volume;
        result.retcode = (int)tradeResult.retcode;
        result.message = "SELL order executed successfully";

        m_successfulExecutions++;

        Print("TRADE EXECUTOR: SELL SUCCESS - Ticket:", result.ticket,
              " | Price:", result.fillPrice, " | SL:", sl, " | TP:", tp);
    }
    else
    {
        result.status = EXEC_FAILED;
        result.retcode = (int)tradeResult.retcode;
        result.message = "SELL order failed: " + IntegerToString(tradeResult.retcode);

        m_lastError = result.message;
        m_failedExecutions++;

        Print("TRADE EXECUTOR: SELL FAILED - Retcode:", tradeResult.retcode,
              " | Comment:", tradeResult.comment);
    }

    m_lastResult = result;
    return result;
}

//+------------------------------------------------------------------+
//| Fermer une position                                              |
//+------------------------------------------------------------------+
bool CTradeExecutor::ClosePosition(ulong ticket)
{
    if(!PositionSelectByTicket(ticket))
    {
        m_lastError = "Position not found: " + IntegerToString(ticket);
        return false;
    }

    if(m_trade.PositionClose(ticket))
    {
        Print("TRADE EXECUTOR: Position closed - Ticket:", ticket);
        return true;
    }

    m_lastError = "Failed to close position: " + IntegerToString(m_trade.ResultRetcode());
    return false;
}

//+------------------------------------------------------------------+
//| Fermer toutes les positions                                      |
//+------------------------------------------------------------------+
bool CTradeExecutor::CloseAllPositions(string symbol = "")
{
    bool allClosed = true;

    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(!PositionSelectByTicket(ticket))
            continue;

        // Vérifier le magic number
        if(PositionGetInteger(POSITION_MAGIC) != m_magicNumber)
            continue;

        // Vérifier le symbole si spécifié
        if(symbol != "" && PositionGetString(POSITION_SYMBOL) != symbol)
            continue;

        if(!ClosePosition(ticket))
            allClosed = false;
    }

    return allClosed;
}

//+------------------------------------------------------------------+
//| Modifier une position                                            |
//+------------------------------------------------------------------+
bool CTradeExecutor::ModifyPosition(ulong ticket, double newSL, double newTP)
{
    if(!PositionSelectByTicket(ticket))
    {
        m_lastError = "Position not found: " + IntegerToString(ticket);
        return false;
    }

    string symbol = PositionGetString(POSITION_SYMBOL);
    newSL = NormalizePrice(symbol, newSL);
    newTP = NormalizePrice(symbol, newTP);

    if(m_trade.PositionModify(ticket, newSL, newTP))
    {
        Print("TRADE EXECUTOR: Position modified - Ticket:", ticket,
              " | New SL:", newSL, " | New TP:", newTP);
        return true;
    }

    m_lastError = "Failed to modify position: " + IntegerToString(m_trade.ResultRetcode());
    return false;
}

//+------------------------------------------------------------------+
//| Normaliser le prix                                               |
//+------------------------------------------------------------------+
double CTradeExecutor::NormalizePrice(string symbol, double price)
{
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    if(tickSize > 0)
        return MathRound(price / tickSize) * tickSize;
    return NormalizeDouble(price, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
}

//+------------------------------------------------------------------+
//| Normaliser les lots                                              |
//+------------------------------------------------------------------+
double CTradeExecutor::NormalizeLots(string symbol, double lots)
{
    double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

    lots = MathFloor(lots / lotStep) * lotStep;
    lots = MathMax(minLot, MathMin(lots, maxLot));

    return lots;
}

//+------------------------------------------------------------------+
//| Vérifier si le marché est ouvert                                 |
//+------------------------------------------------------------------+
bool CTradeExecutor::IsMarketOpen(string symbol)
{
    MqlTick tick;
    if(!SymbolInfoTick(symbol, tick))
        return false;

    // Vérifier si les prix sont valides
    if(tick.bid <= 0 || tick.ask <= 0)
        return false;

    // Vérifier le spread (si trop large, le marché est probablement fermé)
    double spread = tick.ask - tick.bid;
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

    if(spread > point * 1000)  // Spread > 1000 points = marché fermé
        return false;

    return true;
}

//+------------------------------------------------------------------+
//| Obtenir le taux de succès                                        |
//+------------------------------------------------------------------+
int CTradeExecutor::GetSuccessRate()
{
    if(m_totalExecutions == 0)
        return 0;

    return (int)((double)m_successfulExecutions / m_totalExecutions * 100);
}

//+------------------------------------------------------------------+
