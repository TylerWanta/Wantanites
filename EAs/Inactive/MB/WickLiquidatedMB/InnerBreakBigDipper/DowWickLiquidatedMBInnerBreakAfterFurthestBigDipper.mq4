//+------------------------------------------------------------------+
//|                                               TheGrannySmith.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites/Framework/Constants/MagicNumbers.mqh>
#include <Wantanites/Framework/Constants/SymbolConstants.mqh>
#include <Wantanites/EAs/Active/WickLiquidatedMB/InnerBreakBigDipper/WickLiquidatedMB.mqh>

string ForcedSymbol = "US30";
int ForcedTimeFrame = 1;

// --- EA Inputs ---
double RiskPercent = 1;
int MaxCurrentSetupTradesAtOnce = 1;
int MaxTradesPerDay = 5;

// -- MBTracker Inputs
int MBsToTrack = 10;
int MaxZonesInMB = 5;
bool AllowMitigatedZones = false;
bool AllowZonesAfterMBValidation = true;
bool AllowWickBreaks = true;
bool OnlyZonesInMB = true;
bool PrintErrors = false;
bool CalculateOnTick = false;

string StrategyName = "WickLiquidatedMB/";
string EAName = "Dow/";
string SetupTypeName = "InnerBreakAfterFurthestBigDipper/";
string Directory = StrategyName + EAName + SetupTypeName;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>(Directory + "Entries/", "Entries.csv");
CSVRecordWriter<PartialTradeRecord> *PartialWriter = new CSVRecordWriter<PartialTradeRecord>(Directory + "Partials/", "Partials.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>(Directory + "Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>(Directory + "Errors/", "Errors.csv");

MBTracker *SetupMBT;
WickLiquidatedMB *WLMBBuys;
WickLiquidatedMB *WLMBSells;

double MaxSpreadPips = SymbolConstants::DowSpreadPips;
double EntryPaddingPips = 2;
double MinStopLossPips = 0;
double StopLossPaddingPips = 5;
double PipsToWaitBeforeBE = 40;
double BEAdditionalPips = SymbolConstants::DowSlippagePips;
double LargeBodyPips = 15;
double PushFurtherPips = 15;
double CloseRR = 20;

int OnInit()
{
    if (!EAHelper::CheckSymbolAndTimeFrame(ForcedSymbol, ForcedTimeFrame))
    {
        return INIT_PARAMETERS_INCORRECT;
    }

    SetupMBT = new MBTracker(Symbol(), Period(), 300, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, OnlyZonesInMB, PrintErrors, CalculateOnTick);

    WLMBBuys = new WickLiquidatedMB(MagicNumbers::DowWickLiquidatedMBInnerBreakBigDipperBuys, OP_BUY, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                    ExitWriter, ErrorWriter, SetupMBT);

    WLMBBuys.SetPartialCSVRecordWriter(PartialWriter);
    WLMBBuys.AddPartial(CloseRR, 100);

    WLMBBuys.mEntryPaddingPips = EntryPaddingPips;
    WLMBBuys.mMinStopLossPips = MinStopLossPips;
    WLMBBuys.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    WLMBBuys.mBEAdditionalPips = BEAdditionalPips;
    WLMBBuys.mLargeBodyPips = LargeBodyPips;
    WLMBBuys.mPushFurtherPips = PushFurtherPips;

    WLMBBuys.AddTradingSession(10, 30, 23, 0);

    WLMBSells = new WickLiquidatedMB(MagicNumbers::DowWickLiquidatedMBInnerBreakBigDipperSells, OP_SELL, MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                     ExitWriter, ErrorWriter, SetupMBT);
    WLMBSells.SetPartialCSVRecordWriter(PartialWriter);
    WLMBSells.AddPartial(CloseRR, 100);

    WLMBSells.mEntryPaddingPips = EntryPaddingPips;
    WLMBSells.mMinStopLossPips = MinStopLossPips;
    WLMBSells.mPipsToWaitBeforeBE = PipsToWaitBeforeBE;
    WLMBSells.mBEAdditionalPips = BEAdditionalPips;
    WLMBSells.mLargeBodyPips = LargeBodyPips;
    WLMBSells.mPushFurtherPips = PushFurtherPips;

    WLMBSells.AddTradingSession(10, 30, 23, 0);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SetupMBT;

    delete WLMBBuys;
    delete WLMBSells;

    delete EntryWriter;
    delete PartialWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    WLMBBuys.Run();
    WLMBSells.Run();
}
