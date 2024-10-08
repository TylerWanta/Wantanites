//+------------------------------------------------------------------+
//|                                                       BaseTicket.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Constants\Errors.mqh>
#include <Wantanites\Framework\Types\TicketTypes.mqh>
#include <Wantanites\Framework\Constants\ConstantValues.mqh>

#include <Wantanites\Framework\Objects\DataObjects\Partial.mqh>
#include <Wantanites\Framework\Objects\DataStructures\List.mqh>
#include <Wantanites\Framework\Objects\DataStructures\Dictionary.mqh>
#include <Wantanites\Framework\Objects\DataStructures\ObjectList.mqh>

class BaseTicket
{
private:
    bool mLastCloseCheck;
    bool mLastActiveCheck;

    bool mIsClosed;

    double mExpectedOpenPrice;
    double mOriginalStopLoss;

    double mRRAcquired;
    double mDistanceRanFromOpen;
    bool mStopLossIsMovedToBreakEven;

    double mAccountBalanceBefore;

protected:
    ulong mNumber;
    int mMagicNumber;
    TicketType mType; // type doesn't change after it has become a normal Buy or Sell order
    double mOpenPrice;
    datetime mOpenTime;
    double mLotSize; // lot size can't change. If a ticket is partialed you get a new ticket
    double mCurrentStopLoss;
    double mClosePrice;
    datetime mCloseTime;
    double mTakeProfit;
    datetime mExpiration;
    double mProfit;
    double mCommission;

    bool mWasActivated;
    bool mWasManuallyClosed;

    virtual int SelectIfOpen(string action) = NULL;
    virtual int SelectIfClosed(string action) = NULL;

public:
    BaseTicket();
    BaseTicket(int ticket);
    BaseTicket(BaseTicket &ticket);
    ~BaseTicket();

    string DisplayName() { return "BaseTicket"; }

    ObjectList<Partial> *mPartials;

    // Dictionary of <function name chcking if a ticket was activated or closed, previous result>
    Dictionary<string, bool> *mActivatedSinceLastCheckCheckers;
    Dictionary<string, bool> *mClosedSinceLastCheckCheckers;

    ulong Number() { return mNumber; };

    double ExpectedOpenPrice() { return mExpectedOpenPrice; }
    void ExpectedOpenPrice(double expectedOpenPrice) { mExpectedOpenPrice = expectedOpenPrice; }

    double OriginalStopLoss() { return mOriginalStopLoss; }
    void OriginalStopLoss(double originalStopLoss) { mOriginalStopLoss = originalStopLoss; }

    double AccountBalanceBefore() { return mAccountBalanceBefore; }
    void AccountBalanceBefore(double accountBalanceBefore) { mAccountBalanceBefore = accountBalanceBefore; }

    virtual int MagicNumber() = NULL;
    virtual TicketType Type() = NULL;
    void OpenPrice(double openPrice) { mOpenPrice = openPrice; } // used in NewsEmulation.mqh
    virtual double OpenPrice() = NULL;
    virtual datetime OpenTime() = NULL;
    virtual double LotSize() = NULL;
    virtual double CurrentStopLoss() = NULL;
    virtual double ClosePrice() = NULL;
    virtual datetime CloseTime() = NULL;
    virtual double TakeProfit() = NULL;
    virtual datetime Expiration() = NULL;
    virtual double Profit() = NULL;
    virtual double Commission() = NULL;

    double RRAcquired() { return mRRAcquired; }
    void RRAcquired(double rrAcquired) { mRRAcquired = rrAcquired; }

    double DistanceRanFromOpen() { return mDistanceRanFromOpen; }
    void DistanceRanFromOpen(double distanceRanFromOpen) { mDistanceRanFromOpen = distanceRanFromOpen; }

    int StopLossIsMovedToBreakEven(bool &stopLossIsMovedBreakEven);
    void SetStopLossIsMovedToBreakEven(bool stopLossIsMovedToBreakEven) { mStopLossIsMovedToBreakEven = stopLossIsMovedToBreakEven; }

    void SetNewTicket(int ticket);
    void UpdateTicketNumber(int newTicketNumber);

    int IsActive(bool &isActive);
    virtual int WasActivated(bool &active) = NULL;
    int WasActivatedSinceLastCheck(string checker, bool &active);

    int IsClosed(bool &closed);
    int WasClosedSinceLastCheck(string checker, bool &closed);

    virtual int Close() = NULL;
    virtual int ClosePartial(double price, double lotSize) = NULL;
    bool WasManuallyClosed() { return mWasManuallyClosed; }

    void SetPartials(List<double> &partialRRs, List<double> &partialPercents);

    static bool EqualsTicketNumber(BaseTicket &ticket, int ticketNumber);
};

typedef bool (*TTicketNumberLocator)(BaseTicket &, int);

BaseTicket::BaseTicket()
{
    mPartials = new ObjectList<Partial>();
    mActivatedSinceLastCheckCheckers = new Dictionary<string, bool>();
    mClosedSinceLastCheckCheckers = new Dictionary<string, bool>();

    SetNewTicket(ConstantValues::EmptyInt);
}

BaseTicket::BaseTicket(int ticket)
{
    mPartials = new ObjectList<Partial>();
    mActivatedSinceLastCheckCheckers = new Dictionary<string, bool>();
    mClosedSinceLastCheckCheckers = new Dictionary<string, bool>();

    SetNewTicket(ticket);
}

BaseTicket::BaseTicket(BaseTicket &ticket)
{
    mNumber = ticket.Number();
    mRRAcquired = ticket.mRRAcquired;

    mPartials = new ObjectList<Partial>(ticket.mPartials);
    mActivatedSinceLastCheckCheckers = new Dictionary<string, bool>(ticket.mActivatedSinceLastCheckCheckers);
    mClosedSinceLastCheckCheckers = new Dictionary<string, bool>(ticket.mClosedSinceLastCheckCheckers);

    mMagicNumber = ticket.MagicNumber();
    mDistanceRanFromOpen = ticket.mDistanceRanFromOpen;
    mOpenPrice = ticket.OpenPrice();
    mOpenTime = ticket.OpenTime();
    mOriginalStopLoss = ticket.mOriginalStopLoss;
    mLotSize = ticket.LotSize();
    mCurrentStopLoss = ticket.CurrentStopLoss();
    mClosePrice = ticket.ClosePrice();
    mCloseTime = ticket.CloseTime();
    mTakeProfit = ticket.TakeProfit();
    mExpiration = ticket.Expiration();
    mProfit = ticket.Profit();
    mCommission = ticket.Commission();
    mAccountBalanceBefore = ticket.AccountBalanceBefore();

    mWasManuallyClosed = false;

    // update this tickets status' by calling the old tickets methods
    // do this just in case something changed since the last check
    ticket.WasActivated(mWasActivated);
    ticket.IsClosed(mIsClosed);
    ticket.StopLossIsMovedToBreakEven(mStopLossIsMovedToBreakEven);
}

BaseTicket::~BaseTicket()
{
    delete mPartials;
    delete mActivatedSinceLastCheckCheckers;
    delete mClosedSinceLastCheckCheckers;
}

void BaseTicket::SetNewTicket(int ticket)
{
    mNumber = ticket;

    mLastCloseCheck = false;
    mLastActiveCheck = false;

    mWasActivated = false;
    mIsClosed = false;

    mRRAcquired = ConstantValues::EmptyDouble;
    mStopLossIsMovedToBreakEven = false;
    mDistanceRanFromOpen = ConstantValues::EmptyDouble;

    mMagicNumber = ConstantValues::EmptyInt;
    mType = TicketType::Empty;
    mOpenPrice = ConstantValues::EmptyDouble;
    mOpenTime = 0;
    mOriginalStopLoss = ConstantValues::EmptyDouble;
    mLotSize = ConstantValues::EmptyDouble;
    mCurrentStopLoss = ConstantValues::EmptyDouble;
    mClosePrice = ConstantValues::EmptyDouble;
    mCloseTime = 0;
    mTakeProfit = ConstantValues::EmptyDouble;
    mExpiration = 0;
    mProfit = ConstantValues::EmptyDouble;
    mCommission = ConstantValues::EmptyDouble;

    mAccountBalanceBefore = ConstantValues::EmptyDouble;

    mPartials.Clear();
    mActivatedSinceLastCheckCheckers.Clear();
    mClosedSinceLastCheckCheckers.Clear();
}

void BaseTicket::UpdateTicketNumber(int newTicketNumber)
{
    mNumber = newTicketNumber;
    mWasActivated = false;
    mIsClosed = false;
    mStopLossIsMovedToBreakEven = false;
}

int BaseTicket::IsActive(bool &isActive)
{
    isActive = false;

    int selectTicketError = SelectIfOpen("Checking if Active");
    if (selectTicketError != Errors::NO_ERROR)
    {
        return selectTicketError;
    }

    TicketType type = Type();
    isActive = type == TicketType::Buy || type == TicketType::Sell;
    return Errors::NO_ERROR;
}

int BaseTicket::WasActivatedSinceLastCheck(string checker, bool &wasActivatedSinceLastCheck)
{
    wasActivatedSinceLastCheck = false;

    if (!mActivatedSinceLastCheckCheckers.HasKey(checker))
    {
        mActivatedSinceLastCheckCheckers.Add(checker, false);
    }
    else
    {
        bool lastCheck = false;
        if (!mActivatedSinceLastCheckCheckers.GetValueByKey(checker, lastCheck))
        {
            return Errors::UNABLE_TO_RETRIEVE_VALUE_FOR_CHECKER;
        }

        // we were already activated so we can just return with the value set to false
        if (lastCheck)
        {
            return Errors::NO_ERROR;
        }
    }

    bool wasActivated = false;
    int wasActivatedError = WasActivated(wasActivated);
    if (wasActivatedError != Errors::NO_ERROR)
    {
        return wasActivatedError;
    }

    // can just update and return wasActivated since we know it was preveously false so any change to it would just be itself
    mActivatedSinceLastCheckCheckers.UpdateValueForKey(checker, wasActivated);
    wasActivatedSinceLastCheck = wasActivated;

    return Errors::NO_ERROR;
}

int BaseTicket::IsClosed(bool &closed)
{
    if (mIsClosed)
    {
        closed = true;
        return Errors::NO_ERROR;
    }

    int selectTicketError = SelectIfClosed("Checking if Closed");
    if (selectTicketError != Errors::NO_ERROR)
    {
        closed = false;
        return selectTicketError;
    }

    mIsClosed = true;
    closed = mIsClosed;

    return Errors::NO_ERROR;
}

int BaseTicket::WasClosedSinceLastCheck(string checker, bool &wasClosedSinceLastCheck)
{
    wasClosedSinceLastCheck = false;

    if (!mClosedSinceLastCheckCheckers.HasKey(checker))
    {
        mClosedSinceLastCheckCheckers.Add(checker, false);
    }
    else
    {
        bool lastCheck = false;
        if (!mClosedSinceLastCheckCheckers.GetValueByKey(checker, lastCheck))
        {
            return Errors::UNABLE_TO_RETRIEVE_VALUE_FOR_CHECKER;
        }

        // we were already activated so we can just return with the value set to false
        if (lastCheck)
        {
            return Errors::NO_ERROR;
        }
    }

    bool isClosed = false;
    int closedError = IsClosed(isClosed);
    if (closedError != Errors::NO_ERROR)
    {
        return closedError;
    }

    // can just update and return wasActivated since we know it was preveously false so any change to it would just be itself
    mClosedSinceLastCheckCheckers.UpdateValueForKey(checker, isClosed);
    wasClosedSinceLastCheck = isClosed;

    return Errors::NO_ERROR;
}

int BaseTicket::StopLossIsMovedToBreakEven(bool &stopLossIsMovedBreakEven)
{
    if (!mStopLossIsMovedToBreakEven)
    {
        int error = SelectIfOpen("Checking If Break Even");
        if (error != Errors::NO_ERROR)
        {
            return error;
        }

        // Need to normalize or else this will always return false on pairs that have more digits like currencies
        double stopLoss = NormalizeDouble(CurrentStopLoss(), Digits());
        double openPrice = NormalizeDouble(OpenPrice(), Digits());

        TicketType type = Type();
        if (type == TicketType::Buy)
        {
            mStopLossIsMovedToBreakEven = stopLoss >= openPrice;
        }
        else if (type == TicketType::Sell)
        {
            mStopLossIsMovedToBreakEven = stopLoss <= openPrice;
        }
    }

    stopLossIsMovedBreakEven = mStopLossIsMovedToBreakEven;
    return Errors::NO_ERROR;
}

void BaseTicket::SetPartials(List<double> &partialRRs, List<double> &partialPercents)
{
    for (int i = 0; i < partialRRs.Size(); i++)
    {
        Partial *partial = new Partial(partialRRs[i], partialPercents[i]);
        mPartials.Add(partial);
    }
}

static bool BaseTicket::EqualsTicketNumber(BaseTicket &ticket, int number)
{
    return ticket.Number() == number;
}