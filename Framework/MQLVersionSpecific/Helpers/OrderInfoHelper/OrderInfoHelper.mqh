//+------------------------------------------------------------------+
//|                                                     OrderInfoHelper.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#ifdef __MQL4__
#include <Wantanites\Framework\MQLVersionSpecific\Helpers\OrderInfoHelper\MQL4OrderInfoHelper.mqh>
#endif
#ifdef __MQL5__
#include <Wantanites\Framework\MQLVersionSpecific\Helpers\OrderInfoHelper\MQL5OrderInfoHelper.mqh>
#endif

class OrderInfoHelper
{
public:
    static int GetMarginForLotSize(TicketType ticketType, string symbol, double lotSize, double entryPrice, double &margin);

    static int TotalCurrentOrders();

    static int CountTradesTakenToday(int magicNumber, int &tradeCount);
    static int CountOtherEAOrders(bool todayOnly, List<int> &magicNumber, int &orderCount);
    static int GetAllActiveTickets(List<int> &ticketNumbers);
    static int FindActiveTicketsByMagicNumber(int magicNumber, string symbol, int &tickets[]);
    static int FindNewTicketAfterPartial(int magicNumber, string symbol, double openPrice, datetime orderOpenTime, int &ticket);
    static double GetTotalLotsForSymbolAndDirection(string symbol, TicketType type);
};

static int OrderInfoHelper::GetMarginForLotSize(TicketType ticketType, string symbol, double lotSize, double entryPrice, double &margin)
{
    return VersionSpecificOrderInfoHelper::GetMarginForLotSize(ticketType, symbol, lotSize, entryPrice, margin);
}

int OrderInfoHelper::TotalCurrentOrders()
{
    return VersionSpecificOrderInfoHelper::TotalCurrentOrders();
}

static int OrderInfoHelper::CountTradesTakenToday(int magicNumber, int &tradeCount)
{
    return VersionSpecificOrderInfoHelper::CountTradesTakenToday(magicNumber, tradeCount);
}

int OrderInfoHelper::CountOtherEAOrders(bool todayOnly, List<int> &magicNumbers, int &orderCount)
{
    return VersionSpecificOrderInfoHelper::CountOtherEAOrders(todayOnly, magicNumbers, orderCount);
}

int OrderInfoHelper::GetAllActiveTickets(List<int> &ticketNumbers)
{
    return VersionSpecificOrderInfoHelper::GetAllActiveTickets(ticketNumbers);
}

int OrderInfoHelper::FindActiveTicketsByMagicNumber(int magicNumber, string symbol, int &tickets[])
{
    return VersionSpecificOrderInfoHelper::FindActiveTicketsByMagicNumber(magicNumber, symbol, tickets);
}

int OrderInfoHelper::FindNewTicketAfterPartial(int magicNumber, string symbol, double openPrice, datetime orderOpenTime, int &ticket)
{
    return VersionSpecificOrderInfoHelper::FindNewTicketAfterPartial(magicNumber, symbol, openPrice, orderOpenTime, ticket);
}

static double OrderInfoHelper::GetTotalLotsForSymbolAndDirection(string symbol, TicketType type)
{
    return VersionSpecificOrderInfoHelper::GetTotalLotsForSymbolAndDirection(symbol, type);
}