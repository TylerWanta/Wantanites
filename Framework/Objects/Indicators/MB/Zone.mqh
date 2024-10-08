//+------------------------------------------------------------------+
//|                                                         Zone.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\Indicators\MB\ZoneState.mqh>

class Zone : public ZoneState
{
public:
    typedef bool (*TZoneNumberLocator)(Zone &, int);

    Zone();           // only used for default constructor in ObjectList
    Zone(Zone &zone); // only here for copy constructor in ObjectList
    Zone(bool isPending, string symbol, ENUM_TIMEFRAMES timeFrame, int mbNumber, int zoneNumber, SignalType type, string description, datetime startDateTime,
         double entryPrice, datetime endDateTime, double exitPrice, int entryOffset, CandlePart brokenBy, color zoneColor);
    ~Zone();

    void EndTime(datetime time) { mEndDateTime = time; }

    void UpdateDrawnObject();

    static bool LocateByNumber(Zone &zone, int number);
};
Zone::Zone() {}

Zone::Zone(Zone &zone) {}

Zone::Zone(bool isPending, string symbol, ENUM_TIMEFRAMES timeFrame, int mbNumber, int zoneNumber, SignalType type, string description, datetime startDateTime,
           double entryPrice, datetime endDateTime, double exitPrice, int entryOffset, CandlePart brokenBy, color zoneColor)
{
    mIsPending = isPending;
    mSymbol = symbol;
    mTimeFrame = timeFrame;

    mNumber = zoneNumber;
    mMBNumber = mbNumber;
    mType = type;
    mDescription = description;

    mHeight = 0.0;

    mStartDateTime = startDateTime;
    mEndDateTime = endDateTime;

    mEntryPrice = entryPrice;
    mExitPrice = exitPrice;

    mEntryOffset = entryOffset;

    mBrokenBy = brokenBy;
    mDrawn = false;
    mZoneColor = zoneColor;

    mFurthestPointWasSet = false;
    mLowestConfirmationMBLowWithin = 0.0;
    mHighestConfirmationMBHighWithin = 0.0;

    mFirstCandleInZoneTime = ConstantValues::EmptyInt;

    mName = "Zone" + IntegerToString(mType) + ": " + IntegerToString(timeFrame) + "_" + IntegerToString(mNumber) + ", MB: " + IntegerToString(mMBNumber);
}

Zone::~Zone()
{
    ObjectsDeleteAll(ChartID(), mName, 0, OBJ_RECTANGLE);
}

void Zone::UpdateDrawnObject()
{
    if (!mDrawn)
    {
        Draw();
    }
    else
    {
        ObjectSetInteger(ChartID(), mName, OBJPROP_TIME, 0, mStartDateTime);
        ObjectSetDouble(ChartID(), mName, OBJPROP_PRICE, 0, mEntryPrice);
        ObjectSetInteger(ChartID(), mName, OBJPROP_TIME, 1, mEndDateTime);
        ObjectSetDouble(ChartID(), mName, OBJPROP_PRICE, 1, mExitPrice);

        ChartRedraw();
    }
}

static bool Zone::LocateByNumber(Zone &zone, int number)
{
    return zone.Number() == number;
}