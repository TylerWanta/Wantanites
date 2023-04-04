//+------------------------------------------------------------------+
//|                                           ForexForensics.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#property indicator_chart_window
#property indicator_buffers 1 // Number of buffers

#include <Wantanices\Framework\Objects\DataStructures\ObjectList.mqh>
#include <Wantanites\Framework\Objects\Indicators\MB\MBTracker.mqh>
#include <Wantanites\Framework\Helpers\HashUtility.mqh>

inptu string SmartMoneySettings = "----------------";
input int StructureBoxesToTrack = 10;
input int MaxZonesInStructure = 5;
input bool AllowMitigatedZones = false;
input bool AllowZonesAfterStructureValidation = true;
input bool AllowZoneWickBreaks = true;
input bool OnlyZonesInStructure = true;

input string ClearAtTimeEachDay = "-------------";
input string ClearHour = EMPTY;
input string ClearMinute = EMPTY;

input string DoNotChange = "------------";
input string LicenseCheck = "";

MBTracker *MBT;

double Buffer1[];

int OnInit()
{
    MBT = new MBTracker(Symbol(), Period(), StructureBoxesToTrack, MaxZonesInStructure, AllowMitigatedZones, AllowZonesAfterStructureValidation, AllowZoneWickBreaks,
                        OnlyZonesInStructure, false, true);

    SetIndexBuffer(0, Buffer1);
    SetIndexStyle(0, DRAW_NONE);

    char hashResult[];
    int succeeded = HashUtility::Encode(LicenseCheck, hashResult);
    if (succeeded)
    {
        string resultAsString = CharArrayToString(hashResult);
        ArrayResize(Buffer1, ArraySize(hashResult));
        for (int i = 0; i < ArraySize(hashResult); i++)
        {
            Buffer1[i] = StringGetChar(resultAsString, i);
        }
    }

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete MBT;
}

int MBsCreated = 0;
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    int i = Bars - IndicatorCounted() - 1;

    // new bar / each bar
    while (i > 0)
    {
        // change to TimeHour(iTime());
        datetime barTime = iTime(Symbol(), Period(), i);
        if (ClearHour != EMPTY && ClearMinute != EMPTY && TimeHour(barTime) == ClearHour && TimeMinute(barTime) == ClearMinute)
        {
            MBT.ClearMBs();
        }

        MBT.DrawNMostRecentMBs(-1);
        MBT.DrawZonesForNMostRecentMBs(-1);
    }

    return (rates_total);
}