//+------------------------------------------------------------------+
//|                                            TheSunriseShatter.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\EAs\The Sunrise Shatter\TheSunriseShatterSingleMB.mqh>
#include <Wantanites\EAs\The Sunrise Shatter\TheSunriseShatterDoubleMB.mqh>
#include <Wantanites\EAs\The Sunrise Shatter\TheSunriseShatterLiquidationMB.mqh>

// --- EA Inputs ---
input double StopLossPaddingPips = 0;
input double RiskPercent = 0.25;
input int MaxCurrentSetupTradesAtOnce = 1;
input int MaxTradesPerDay = 5;
input int MaxSpreadPips = 10;

// -- MBTracker Inputs
input int MBsToTrack = 10;
input int MaxZonesInMB = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterMBValidation = true;
input bool AllowWickBreaks = true;
input bool PrintErrors = false;
input bool CalculateOnTick = true;

// --- Min ROC. Inputs ---
input int ServerHourStartTime = 16;
input int ServerMinuteStartTime = 30;
input int ServerHourEndTime = 16;
input int ServerMinuteEndTime = 33;
input double MinROCPercent = 0.17;

MBTracker *MBT;
MinROCFromTimeStamp *MRFTS;

TheSunriseShatterSingleMB *TSSSMB;
TheSunriseShatterDoubleMB *TSSDMB;
TheSunriseShatterLiquidationMB *TSSLMB;

CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *EntryWriter = new CSVRecordWriter<SingleTimeFrameEntryTradeRecord>("The Sunrise Shatter/Entries/", "Entries.csv");
CSVRecordWriter<SingleTimeFrameExitTradeRecord> *ExitWriter = new CSVRecordWriter<SingleTimeFrameExitTradeRecord>("The Sunrise Shatter/Exits/", "Exits.csv");
CSVRecordWriter<SingleTimeFrameErrorRecord> *ErrorWriter = new CSVRecordWriter<SingleTimeFrameErrorRecord>("The Sunrise Shatter/Errors/", "Errors.csv");

int OnInit()
{
    MBT = new MBTracker(Symbol(), Period(), MBsToTrack, MaxZonesInMB, AllowMitigatedZones, AllowZonesAfterMBValidation, AllowWickBreaks, PrintErrors, CalculateOnTick);
    MRFTS = new MinROCFromTimeStamp(Symbol(), Period(), ServerHourStartTime, ServerHourEndTime, ServerMinuteStartTime, ServerMinuteEndTime, MinROCPercent);

    TSSSMB = new TheSunriseShatterSingleMB(Period(), MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                                           ErrorWriter, MRFTS, MBT);
    TSSDMB = new TheSunriseShatterDoubleMB(Period(), MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter, ExitWriter,
                                           ErrorWriter, MRFTS, MBT);
    TSSLMB = new TheSunriseShatterLiquidationMB(Period(), MaxCurrentSetupTradesAtOnce, MaxTradesPerDay, StopLossPaddingPips, MaxSpreadPips, RiskPercent, EntryWriter,
                                                ExitWriter, ErrorWriter, MRFTS, MBT);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete TSSSMB;
    delete TSSDMB;
    delete TSSLMB;

    delete MBT;
    delete MRFTS;

    delete EntryWriter;
    delete ExitWriter;
    delete ErrorWriter;
}

void OnTick()
{
    TSSSMB.Run();
    TSSDMB.Run();
    TSSLMB.Run();
}
