//+------------------------------------------------------------------+
//|                                                        Types.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\CSVWriting\ICSVRecord.mqh>
#include <SummitCapital\Framework\Helpers\OrderHelper.mqh>

class DefaultTradeRecord : ICSVRecord
{
public:
    string Symbol;
    int TimeFrame;
    string OrderType;
    double AccountBalanceBefore;
    double AccountBalanceAfter;
    datetime EntryTime;
    string EntryImage;
    datetime ExitTime;
    string ExitImage;
    double EntryPrice;
    double EntryStopLoss;
    double Lots;
    double ExitPrice;
    double ExitStopLoss;

    DefaultTradeRecord();
    ~DefaultTradeRecord();

    double TotalMovePips() { return NormalizeDouble(OrderHelper::RangeToPips((EntryPrice - ExitPrice)), 2); }
    double PotentialRR() { return NormalizeDouble((EntryPrice - ExitPrice) / (EntryPrice - EntryStopLoss), 2); }

    void Write(int fileHandle);
    void Reset();
};

DefaultTradeRecord::DefaultTradeRecord()
{
    Reset();
}

DefaultTradeRecord::~DefaultTradeRecord() {}

void DefaultTradeRecord::Write(int fileHandle)
{
    FileWrite(fileHandle, Symbol, TimeFrame, OrderType, AccountBalanceBefore, AccountBalanceAfter, EntryTime, EntryImage, ExitTime, ExitImage, EntryPrice,
              EntryStopLoss, Lots, ExitPrice, ExitStopLoss, TotalMovePips(), PotentialRR());
}

void DefaultTradeRecord::Reset()
{
    Symbol = "";
    TimeFrame = 0;
    OrderType = "";
    AccountBalanceBefore = 0;
    AccountBalanceAfter = 0;
    EntryTime = 0;
    EntryImage = "";
    ExitTime = 0;
    ExitImage = "";
    EntryPrice = 0.0;
    EntryStopLoss = 0.0;
    Lots = 0.0;
    ExitPrice = 0.0;
    ExitStopLoss = 0.0;
}