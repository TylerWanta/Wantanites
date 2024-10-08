//+------------------------------------------------------------------+
//|                                                    TestNewsTimeRangeBreakout.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataObjects\EA.mqh>
#include <Wantanites\Framework\Constants\MagicNumbers.mqh>
#include <Wantanites\Framework\Objects\Indicators\Time\TimeRangeBreakout.mqh>

class TestNewsTimeRangeBreakout : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    TimeRangeBreakout *mTRB;
    ObjectList<EconomicEvent> *mEconomicEvents;

    List<string> *mEconomicEventTitles;
    List<string> *mEconomicEventSymbols;
    List<int> *mEconomicEventImpacts;

    bool mLoadedEventsForToday;
    bool mDuringNews;

public:
    TestNewsTimeRangeBreakout(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                              CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                              CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeRangeBreakout *&trb);
    ~TestNewsTimeRangeBreakout();

    virtual double RiskPercent() { return mRiskPercent; }

    virtual void PreRun();
    virtual bool AllowedToTrade();
    virtual void CheckSetSetup();
    virtual void CheckInvalidateSetup();
    virtual void InvalidateSetup(bool deletePendingOrder, int error);
    virtual bool Confirmation();
    virtual void PlaceOrders();
    virtual void PreManageTickets();
    virtual void ManageCurrentPendingSetupTicket(Ticket &ticket);
    virtual void ManageCurrentActiveSetupTicket(Ticket &ticket);
    virtual bool MoveToPreviousSetupTickets(Ticket &ticket);
    virtual void ManagePreviousSetupTicket(Ticket &ticket);
    virtual void CheckCurrentSetupTicket(Ticket &ticket);
    virtual void CheckPreviousSetupTicket(Ticket &ticket);
    virtual void RecordTicketOpenData(Ticket &ticket);
    virtual void RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber);
    virtual void RecordTicketCloseData(Ticket &ticket);
    virtual void RecordError(string methodName, int error, string additionalInformation);
    virtual bool ShouldReset();
    virtual void Reset();
};

TestNewsTimeRangeBreakout::TestNewsTimeRangeBreakout(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                                                     CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                                                     CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, TimeRangeBreakout *&trb)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mTRB = trb;
    mEconomicEvents = new ObjectList<EconomicEvent>();

    mLoadedEventsForToday = false;
    mDuringNews = false;

    EAInitHelper::FindSetPreviousAndCurrentSetupTickets<TestNewsTimeRangeBreakout>(this);
    EAInitHelper::SetPreviousSetupTicketsOpenData<TestNewsTimeRangeBreakout, SingleTimeFrameEntryTradeRecord>(this);
}

TestNewsTimeRangeBreakout::~TestNewsTimeRangeBreakout()
{
    delete mEconomicEvents;
}

void TestNewsTimeRangeBreakout::PreRun()
{
    mTRB.Draw();
}

bool TestNewsTimeRangeBreakout::AllowedToTrade()
{
    return EAHelper::BelowSpread<TestNewsTimeRangeBreakout>(this) && EAHelper::WithinTradingSession<TestNewsTimeRangeBreakout>(this);
}

void TestNewsTimeRangeBreakout::CheckSetSetup()
{
    if (!mLoadedEventsForToday)
    {
        EAHelper::GetEconomicEventsForDate<TestNewsTimeRangeBreakout>(this, "JustEvents", TimeGMT(), mEconomicEventTitles, mEconomicEventSymbols, mEconomicEventImpacts);
        mLoadedEventsForToday = true;

        for (int i = 0; i < mEconomicEvents.Size(); i++)
        {
            Print("Event. Time: ", mEconomicEvents[i].Date(), ", Title: ", mEconomicEvents[i].Title());
        }
    }

    if (EAHelper::MostRecentCandleBrokeTimeRange<TestNewsTimeRangeBreakout>(this))
    {
        mDuringNews = EAHelper::CandleIsDuringEconomicEvent<TestNewsTimeRangeBreakout>(this);
        mHasSetup = true;
    }
}

void TestNewsTimeRangeBreakout::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (LastDay() != DateTimeHelper::CurrentDay())
    {
        InvalidateSetup(true);
    }
}

void TestNewsTimeRangeBreakout::InvalidateSetup(bool deletePendingOrder, int error = 0)
{
    EAHelper::InvalidateSetup<TestNewsTimeRangeBreakout>(this, deletePendingOrder, mStopTrading, error);
}

bool TestNewsTimeRangeBreakout::Confirmation()
{
    return true;
}

void TestNewsTimeRangeBreakout::PlaceOrders()
{
    double newsPips = 25;
    double entry = 0.0;
    double stopLoss = 0.0;
    mRiskPercent = 1;

    if (SetupType() == SignalType::Bullish)
    {
        entry = CurrentTick().Ask();
        stopLoss = mTRB.RangeLow();

        if (mDuringNews)
        {
            entry += PipConverter::PipsToPoints(newsPips);
            mRiskPercent = (entry - stopLoss) / (CurrentTick().Ask() - stopLoss);

            EAOrderHelper::PlaceStopOrder<TestNewsTimeRangeBreakout>(this, entry, stopLoss);
        }
        else
        {
            EAOrderHelper::PlaceMarketOrder<TestNewsTimeRangeBreakout>(this, entry, stopLoss);
        }
    }
    else if (SetupType() == SignalType::Bearish)
    {
        entry = CurrentTick().Bid();
        stopLoss = mTRB.RangeHigh();

        if (mDuringNews)
        {
            entry -= PipConverter::PipsToPoints(newsPips);
            mRiskPercent = (entry - stopLoss) / (CurrentTick().Ask() - stopLoss);

            EAOrderHelper::PlaceStopOrder<TestNewsTimeRangeBreakout>(this, entry, stopLoss);
        }
        else
        {
            EAOrderHelper::PlaceMarketOrder<TestNewsTimeRangeBreakout>(this, entry, stopLoss);
        }
    }

    mStopTrading = true;
}

void TestNewsTimeRangeBreakout::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void TestNewsTimeRangeBreakout::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

void TestNewsTimeRangeBreakout::PreManageTickets()
{
}

bool TestNewsTimeRangeBreakout::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void TestNewsTimeRangeBreakout::ManagePreviousSetupTicket(Ticket &ticket)
{
}

void TestNewsTimeRangeBreakout::CheckCurrentSetupTicket(Ticket &ticket)
{
    // close if we are down 1%
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    if ((AccountInfoDouble(ACCOUNT_EQUITY) - balance) / balance * 100 <= -1)
    {
        ticket.Close();
    }
}

void TestNewsTimeRangeBreakout::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void TestNewsTimeRangeBreakout::RecordTicketOpenData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameEntryTradeRecord<TestNewsTimeRangeBreakout>(this, ticket);
}

void TestNewsTimeRangeBreakout::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void TestNewsTimeRangeBreakout::RecordTicketCloseData(Ticket &ticket)
{
    EAHelper::RecordSingleTimeFrameExitTradeRecord<TestNewsTimeRangeBreakout>(this, ticket, EntryTimeFrame());
}

void TestNewsTimeRangeBreakout::RecordError(string methodName, int error, string additionalInformation = "")
{
    EAHelper::RecordSingleTimeFrameErrorRecord<TestNewsTimeRangeBreakout>(this, methodName, error, additionalInformation);
}

bool TestNewsTimeRangeBreakout::ShouldReset()
{
    return !EAHelper::WithinTradingSession<TestNewsTimeRangeBreakout>(this);
}

void TestNewsTimeRangeBreakout::Reset()
{
    mStopTrading = false;
    mLoadedEventsForToday = false;
    mDuringNews = false;

    mEconomicEvents.Clear();
    EAOrderHelper::CloseAllCurrentAndPreviousSetupTickets<TestNewsTimeRangeBreakout>(this);
}