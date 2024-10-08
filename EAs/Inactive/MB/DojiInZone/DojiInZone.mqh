//+------------------------------------------------------------------+
//|                                                    DojiInZone.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Objects\DataObjects\EA.mqh>
#include <Wantanites\Framework\Constants\MagicNumbers.mqh>

class DojiInZone : public EA<SingleTimeFrameEntryTradeRecord, EmptyPartialTradeRecord, SingleTimeFrameExitTradeRecord, SingleTimeFrameErrorRecord>
{
public:
    MBTracker *mMBT;

    int mFirstMBInSetup;
    string mProfitObjectName;

public:
    DojiInZone(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
               CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
               CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt);
    ~DojiInZone();

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

DojiInZone::DojiInZone(int magicNumber, int setupType, int maxCurrentSetupTradesAtOnce, int maxTradesPerDay, double stopLossPaddingPips, double maxSpreadPips, double riskPercent,
                       CSVRecordWriter<SingleTimeFrameEntryTradeRecord> *&entryCSVRecordWriter, CSVRecordWriter<SingleTimeFrameExitTradeRecord> *&exitCSVRecordWriter,
                       CSVRecordWriter<SingleTimeFrameErrorRecord> *&errorCSVRecordWriter, MBTracker *&mbt)
    : EA(magicNumber, setupType, maxCurrentSetupTradesAtOnce, maxTradesPerDay, stopLossPaddingPips, maxSpreadPips, riskPercent, entryCSVRecordWriter, exitCSVRecordWriter, errorCSVRecordWriter)
{
    mMBT = mbt;

    mFirstMBInSetup = ConstantValues::EmptyInt;
    mProfitObjectName = "ProfitLabel" + (setupType == SignalType::Bearish ? "Bearish" : "Bullish");

    EAInitHelper::FindSetPreviousAndCurrentSetupTickets<DojiInZone>(this);
    EAInitHelper::SetPreviousSetupTicketsOpenData<DojiInZone, SingleTimeFrameEntryTradeRecord>(this);
}

DojiInZone::~DojiInZone()
{
}

void DojiInZone::PreRun()
{
    mMBT.Draw();
    EARunHelper::ShowOpenTicketProfit<DojiInZone>(this);
}

bool DojiInZone::AllowedToTrade()
{
    return EARunHelper::BelowSpread<DojiInZone>(this) && EARunHelper::WithinTradingSession<DojiInZone>(this);
}

void DojiInZone::CheckSetSetup()
{
    if (EASetupHelper::CheckSetSingleMBSetup<DojiInZone>(this, mMBT, mFirstMBInSetup, SetupType()))
    {
        mHasSetup = true;
    }
}

void DojiInZone::CheckInvalidateSetup()
{
    mLastState = EAStates::CHECKING_FOR_INVALID_SETUP;

    if (mFirstMBInSetup != mMBT.MBsCreated() - 1)
    {
        InvalidateSetup(true);
    }
}

void DojiInZone::InvalidateSetup(bool deletePendingOrder, int error = 0)
{
    EASetupHelper::InvalidateSetup<DojiInZone>(this, deletePendingOrder, mStopTrading, error);

    mFirstMBInSetup = ConstantValues::EmptyInt;
}

bool DojiInZone::Confirmation()
{
    if (iBars(EntrySymbol(), EntryTimeFrame()) <= BarCount())
    {
        return false;
    }

    return EASetupHelper::DojiInsideMostRecentMBsHoldingZone<DojiInZone>(this, mMBT, mFirstMBInSetup, 1) &&
           EASetupHelper::CandleIsInZone<DojiInZone>(this, mMBT, mFirstMBInSetup, 1, true);
}

void DojiInZone::PlaceOrders()
{
    double entry = 0.0;
    double stopLoss = 0.0;

    ZoneState *zoneState;
    if (!mMBT.GetNthMostRecentMBsClosestValidZone(0, zoneState))
    {
        return;
    }

    if (SetupType() == SignalType::Bullish)
    {
        entry = CurrentTick().Ask();
        stopLoss = MathMin(iLow(EntrySymbol(), EntryTimeFrame(), 1), zoneState.ExitPrice());
    }
    else if (SetupType() == SignalType::Bearish)
    {
        entry = CurrentTick().Bid();
        stopLoss = MathMax(iHigh(EntrySymbol(), EntryTimeFrame(), 1), zoneState.ExitPrice());
    }

    EAOrderHelper::PlaceMarketOrder<DojiInZone>(this, entry, stopLoss);
}

void DojiInZone::PreManageTickets()
{
    double profit = 0.0;
    for (int i = 0; i < mCurrentSetupTickets.Size(); i++)
    {
        profit += mCurrentSetupTickets[i].Profit();
    }

    double profitTarget = AccountInfoDouble(ACCOUNT_BALANCE) * 0.01;
    if (profit > profitTarget)
    {
        for (int i = 0; i < mCurrentSetupTickets.Size(); i++)
        {
            mCurrentSetupTickets[i].Close();
        }
    }
}

void DojiInZone::ManageCurrentPendingSetupTicket(Ticket &ticket)
{
}

void DojiInZone::ManageCurrentActiveSetupTicket(Ticket &ticket)
{
}

bool DojiInZone::MoveToPreviousSetupTickets(Ticket &ticket)
{
    return false;
}

void DojiInZone::ManagePreviousSetupTicket(Ticket &ticket)
{
}

void DojiInZone::CheckCurrentSetupTicket(Ticket &ticket)
{
    // Make sure we are only ever losing how much we intend to risk, even if we entered at a worse price due to slippage
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    if ((AccountInfoDouble(ACCOUNT_EQUITY) - accountBalance) / accountBalance * 100 <= -RiskPercent())
    {
        ticket.Close();
    }
}

void DojiInZone::CheckPreviousSetupTicket(Ticket &ticket)
{
}

void DojiInZone::RecordTicketOpenData(Ticket &ticket)
{
    EARecordHelper::RecordSingleTimeFrameEntryTradeRecord<DojiInZone>(this, ticket);
}

void DojiInZone::RecordTicketPartialData(Ticket &partialedTicket, int newTicketNumber)
{
}

void DojiInZone::RecordTicketCloseData(Ticket &ticket)
{
    EARecordHelper::RecordSingleTimeFrameExitTradeRecord<DojiInZone>(this, ticket);
}

void DojiInZone::RecordError(string methodName, int error, string additionalInformation = "")
{
    EARecordHelper::RecordSingleTimeFrameErrorRecord<DojiInZone>(this, methodName, error, additionalInformation);
}

bool DojiInZone::ShouldReset()
{
    return false;
}

void DojiInZone::Reset()
{
}