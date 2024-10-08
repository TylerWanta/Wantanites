//+------------------------------------------------------------------+
//|                                            TimeRangeBreakout.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Constants\ConstantValues.mqh>
#include <Wantanites\Framework\Helpers\DateTimeHelper.mqh>

class TimeRangeBreakout
{
private:
    string mObjectNamePrefix;

    int mBarsCalculated;
    int mLastDay;

    int mRangeHourStartTime;
    int mRangeMinuteStartTime;
    int mRangeHourEndTime;
    int mRangeMinuteEndTime;

    datetime mRangeStartTime;
    datetime mRangeEndTime;

    bool mUpdateRangeStart;
    bool mUpdateRangeEnd;

    double mRangeHigh;
    double mRangeLow;

    bool mUpdateRangeHigh;
    bool mUpdateRangeLow;

    datetime mBrokeRangeHighTime;
    datetime mBrokeRangeLowTime;

    void Update();
    void Calculate(int barIndex);
    void Reset();

public:
    TimeRangeBreakout(int rangeHourStartTime, int rangeMinuteStartTime, int rangeHourEndTime, int rangeMinuteEndTime);
    ~TimeRangeBreakout();

    datetime RangeStartTime() { return mRangeStartTime; }
    datetime RangeEndTime() { return mRangeEndTime; }

    double RangeHigh();
    double RangeLow();
    double RangeHeight() { return RangeHigh() - RangeLow(); }

    bool MostRecentCandleBrokeRangeHigh();
    bool MostRecentCandleBrokeRangeLow();

    void Draw();
};

TimeRangeBreakout::TimeRangeBreakout(int rangeHourStartTime, int rangeMinuteStartTime, int rangeHourEndTime, int rangeMinuteEndTime)
{
    mObjectNamePrefix = "TimeRangeBreakout";

    mBarsCalculated = 0;
    mLastDay = DateTimeHelper::CurrentDay();

    mRangeHourStartTime = rangeHourStartTime;
    mRangeMinuteStartTime = rangeMinuteStartTime;
    mRangeHourEndTime = rangeHourEndTime;
    mRangeMinuteEndTime = rangeMinuteEndTime;

    Reset();
    Update();
}

TimeRangeBreakout::~TimeRangeBreakout()
{
    ObjectsDeleteAll(ChartID(), mObjectNamePrefix);
}

double TimeRangeBreakout::RangeHigh()
{
    Update();
    return mRangeHigh;
}

double TimeRangeBreakout::RangeLow()
{
    Update();
    return mRangeLow;
}

bool TimeRangeBreakout::MostRecentCandleBrokeRangeHigh()
{
    Update();

    if (mBrokeRangeHighTime <= 0)
    {
        return false;
    }

    return iBarShift(Symbol(), Period(), mBrokeRangeHighTime) == 0;
}

bool TimeRangeBreakout::MostRecentCandleBrokeRangeLow()
{
    Update();

    if (mBrokeRangeLowTime <= 0)
    {
        return false;
    }

    return iBarShift(Symbol(), Period(), mBrokeRangeLowTime) == 0;
}

void TimeRangeBreakout::Update()
{
    int totalBars = iBars(Symbol(), Period());
    int start = totalBars - mBarsCalculated;

    for (int i = start; i >= 0; i--)
    {
        Calculate(i);
    }

    mBarsCalculated = totalBars;
}

void TimeRangeBreakout::Calculate(int barIndex)
{
    int currentDay = DateTimeHelper::CurrentDay();
    if (currentDay != mLastDay)
    {
        Reset();
        mLastDay = currentDay;
    }

    datetime validTime = iTime(Symbol(), Period(), barIndex);
    if (validTime > mRangeStartTime && validTime < mRangeEndTime)
    {
        if (iHigh(Symbol(), Period(), barIndex) > mRangeHigh || mRangeHigh == ConstantValues::EmptyDouble)
        {
            mRangeHigh = iHigh(Symbol(), Period(), barIndex);
            mUpdateRangeHigh = true;
        }

        if (iLow(Symbol(), Period(), barIndex) < mRangeLow || mRangeLow == ConstantValues::EmptyDouble)
        {
            mRangeLow = iLow(Symbol(), Period(), barIndex);
            mUpdateRangeLow = true;
        }
    }
    else
    {
        if (mRangeHigh != ConstantValues::EmptyDouble && mRangeLow != ConstantValues::EmptyDouble)
        {
            MqlTick currentTick;
            if (!SymbolInfoTick(Symbol(), currentTick))
            {
                return;
            }

            double thisValue = barIndex == 0 ? currentTick.bid : iClose(Symbol(), Period(), barIndex);
            if (mBrokeRangeHighTime <= 0)
            {
                if (iClose(Symbol(), Period(), barIndex + 1) < mRangeHigh && thisValue >= mRangeHigh)
                {
                    mBrokeRangeHighTime = iTime(Symbol(), Period(), barIndex);
                }
            }

            if (mBrokeRangeLowTime <= 0)
            {
                if (iClose(Symbol(), Period(), barIndex + 1) > mRangeLow && thisValue <= mRangeLow)
                {
                    mBrokeRangeLowTime = iTime(Symbol(), Period(), barIndex);
                }
            }
        }
    }
}

void TimeRangeBreakout::Reset()
{
    int currentDay = DateTimeHelper::CurrentDay();
    mRangeStartTime = DateTimeHelper::HourMinuteToDateTime(mRangeHourStartTime, mRangeMinuteStartTime, currentDay);
    mRangeEndTime = DateTimeHelper::HourMinuteToDateTime(mRangeHourEndTime, mRangeMinuteEndTime, currentDay);

    mUpdateRangeStart = true;
    mUpdateRangeEnd = true;

    mRangeHigh = ConstantValues::EmptyDouble;
    mRangeLow = ConstantValues::EmptyDouble;

    mUpdateRangeHigh = false;
    mUpdateRangeLow = false;

    mBrokeRangeHighTime = 0;
    mBrokeRangeLowTime = 0;
}

void TimeRangeBreakout::Draw()
{
    Update();

    if (mUpdateRangeStart)
    {
        ObjectDelete(NULL, mObjectNamePrefix + "_start");

        ObjectCreate(NULL, mObjectNamePrefix + "_start", OBJ_VLINE, 0, mRangeStartTime, 0);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_start", OBJPROP_COLOR, clrBlue);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_start", OBJPROP_WIDTH, 2);

        mUpdateRangeStart = false;
    }

    if (mUpdateRangeEnd)
    {
        ObjectDelete(NULL, mObjectNamePrefix + "_end");

        ObjectCreate(NULL, mObjectNamePrefix + "_end", OBJ_VLINE, 0, mRangeEndTime, 0);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_end", OBJPROP_COLOR, clrBlue);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_end", OBJPROP_WIDTH, 2);

        mUpdateRangeEnd = false;
    }

    if (mRangeHigh > 0 && mUpdateRangeHigh)
    {
        datetime tomorrow = TimeCurrent() + (60 * 60 * 24);
        ObjectDelete(NULL, mObjectNamePrefix + "_high");

        ObjectCreate(NULL, mObjectNamePrefix + "_high", OBJ_TREND, 0, mRangeStartTime, mRangeHigh, tomorrow, mRangeHigh);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_high", OBJPROP_COLOR, clrBlue);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_high", OBJPROP_WIDTH, 2);

        mUpdateRangeHigh = false;
    }

    if (mRangeLow > 0 && mUpdateRangeLow)
    {
        datetime tomorrow = TimeCurrent() + (60 * 60 * 24);
        ObjectDelete(NULL, mObjectNamePrefix + "_low");

        ObjectCreate(NULL, mObjectNamePrefix + "_low", OBJ_TREND, 0, mRangeStartTime, mRangeLow, tomorrow, mRangeLow);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_low", OBJPROP_COLOR, clrBlue);
        ObjectSetInteger(NULL, mObjectNamePrefix + "_low", OBJPROP_WIDTH, 2);

        mUpdateRangeLow = false;
    }
}