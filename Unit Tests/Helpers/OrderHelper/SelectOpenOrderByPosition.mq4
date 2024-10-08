//+------------------------------------------------------------------+
//|                                    SelectOpenOrderByPosition.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Wantanites\Framework\Helpers\OrderHelper.mqh>
#include <Wantanites\Framework\UnitTests\IntUnitTest.mqh>
#include <Wantanites\Framework\UnitTests\BoolUnitTest.mqh>

#include <Wantanites\Framework\CSVWriting\CSVRecordTypes\DefaultUnitTestRecord.mqh>

const string Directory = "/UnitTests/Helpers/OrderHelper/SelectOpenOrderByPosition/";
const int NumberOfAsserts = 25;
const int AssertCooldown = 1;
const bool RecordScreenShot = false;
const bool RecordErrors = true;

// https://drive.google.com/file/d/1y1DaxrjpYMj4LcN3J7N0s41ALWMG2vMD/view?usp=sharing
BoolUnitTest<DefaultUnitTestRecord> *SelectsOpenOrderByPositionUnitTest;

// https://drive.google.com/file/d/1GTbk43wZx8mNKQdjDtNFF2BdUVDmb47d/view?usp=sharing
IntUnitTest<DefaultUnitTestRecord> *NoOpenOrdersInvalidPositionHasErrorUnitTest;

int OnInit()
{
    SelectsOpenOrderByPositionUnitTest = new BoolUnitTest<DefaultUnitTestRecord>(
        Directory, "Select Open Order By Position", "Should Return True Indicating It Was Able To Select The Correct Order",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        true, SelectOpenOrdersByPosition);

    NoOpenOrdersInvalidPositionHasErrorUnitTest = new IntUnitTest<DefaultUnitTestRecord>(
        Directory, "No Orders Invalid Position Returns Error", "Should Return An Error When Selecing An Invalid Position With No Orders Opened",
        NumberOfAsserts, AssertCooldown, RecordScreenShot, RecordErrors,
        Errors::NO_ERROR, NoOpenOrdersInvalidPositionHasError);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    delete SelectsOpenOrderByPositionUnitTest;
    delete NoOpenOrdersInvalidPositionHasErrorUnitTest;
}

void OnTick()
{
    SelectsOpenOrderByPositionUnitTest.Assert();
    NoOpenOrdersInvalidPositionHasErrorUnitTest.Assert(false);
}

int SelectOpenOrdersByPosition(bool &actual)
{
    int ticket = -1;
    int type = OP_BUYSTOP;
    int entryPrice = Ask + OrderHelper::PipsToRange(200);
    int stopLoss = Bid - OrderHelper::PipsToRange(200);

    ticket = OrderSend(Symbol(), type, 0.1, entryPrice, 0, stopLoss, 0.0, NULL, 0, 0, clrNONE);
    if (ticket == EMPTY)
    {
        return GetLastError();
    }

    for (int i = 0; i < 1; i++)
    {
        int error = OrderHelper::SelectOpenOrderByPosition(i, "Testing Select Open Order By Position");
        if (error != Errors::NO_ERROR)
        {
            return error;
        }
    }

    OrderDelete(ticket, clrNONE);

    actual = ticket == OrderTicket();
    return Results::UNIT_TEST_RAN;
}

int NoOpenOrdersInvalidPositionHasError(int &actual)
{
    actual = OrderHelper::SelectOpenOrderByPosition(10, "Testing No Orders With Invalid Posiiton");
    return Results::UNIT_TEST_RAN;
}