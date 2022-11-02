//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital/EAs/LiquidationMB/LiquidationMB.mqh>

// --- EA Inputs ---
double RiskPercent = 0.25;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 5;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = true;
bool AllowWickBreaks = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>("LiquidationMB/Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>("LiquidationMB/Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>("LiquidationMB/Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>("LiquidationMB/Errors/", "Errors.csv");

MBTracker *SetupMBT;

LiquidationSetupTracker *LSTBuys;
LiquidationSetupTracker *LSTSells;

LiquidationMB *LMBBuys;
LiquidationMB *LMBSells;

// Nas
double MaxSpreadPips = 10;
double EntryPaddingPips = 20;
double MinStopLossPips = 250;
double StopLossPaddingPips = 50;
double PipsToWaitBeforeBE = 200;
double BEAdditionalPips = 50;

int OnInit()
{
    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);

    LSTBuys = new LiquidationSetupTracker(OP_BUY, SetupMBT);
    LMBBuys = new LiquidationMB(-1, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                                ErrorWriter, SetupMBT, LSTBuys);
    LMBBuys.SetPartialCSVRecordWriter(PartialWriter);
    LMBBuys.AddPartial(1000, 100);

    LMBBuys.mEntryPaddingPips = EntryPaddingPips;
    // LMBBuys.mMinStopLossPips = MinStopLossPips;
    LMBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    LMBBuys.mBEAdditionalPips = BEAdditionalPips;

    LMBBuys.AddTradingSession(16, 30, 23, 0);

    LSTSells = new LiquidationSetupTracker(OP_SELL, SetupMBT);
    LMBSells = new LiquidationMB(-1, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                                 ErrorWriter, SetupMBT, LSTSells);
    LMBSells.SetPartialCSVRecordWriter(PartialWriter);
    LMBSells.AddPartial(1000, 100);

    LMBSells.mEntryPaddingPips = EntryPaddingPips;
    // LMBSells.mMinStopLossPips = MinStopLossPips;
    LMBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    LMBSells.mBEAdditionalPips = BEAdditionalPips;

    LMBSells.AddTradingSession(16, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete LSTBuys;
    delete LSTSells;

    delete LMBBuys;
    delete LMBSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    LMBBuys.Run();
    LMBSells.Run();
}
