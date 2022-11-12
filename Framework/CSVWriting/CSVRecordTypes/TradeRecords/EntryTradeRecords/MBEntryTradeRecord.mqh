//+------------------------------------------------------------------+
//|                                            MBEntryTradeRecord.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <SummitCapital\Framework\CSVWriting\CSVRecordTypes\TradeRecords\EntryTradeRecords\SingleTimeFrameEntryTradeRecord.mqh>

class MBEntryTradeRecord : public SingleTimeFrameEntryTradeRecord
{
public:
    double MBHeight;
    int MBWidth;
    double EntryDistanceFromPreviousMB;
    int MBCount;
    int ZoneNumber;
    double ZoneImbalancePercentChange;

    MBEntryTradeRecord();
    ~MBEntryTradeRecord();

    virtual void WriteHeaders(int fileHandle, bool writeDelimiter);
    virtual void WriteRecord(int fileHandle, bool writeDelimiter);
};

MBEntryTradeRecord::MBEntryTradeRecord() : SingleTimeFrameEntryTradeRecord()
{
    MBWidth = -1.0;
    MBHeight = -1.0;
    EntryDistanceFromPreviousMB = -1.0;
    ZoneImbalancePercentChange = -1.0;
}

MBEntryTradeRecord::~MBEntryTradeRecord()
{
}

void MBEntryTradeRecord::WriteHeaders(int fileHandle, bool writeDelimiter = false)
{
    SingleTimeFrameEntryTradeRecord::WriteHeaders(fileHandle, true);
    FileHelper::WriteString(fileHandle, "MB Height");
    FileHelper::WriteString(fileHandle, "MB Width");
    FileHelper::WriteString(fileHandle, "Entry Distance From Pervious MB");
    FileHelper::WriteString(fileHandle, "MB Count");
    FileHelper::WriteString(fileHandle, "Zone Number");
    FileHelper::WriteString(fileHandle, "Zone Imbalance % Change");
}

void MBEntryTradeRecord::WriteRecord(int fileHandle, bool writeDelimiter = false)
{
    SingleTimeFrameEntryTradeRecord::WriteRecord(fileHandle, true);
    FileHelper::WriteDouble(fileHandle, MBHeight, Digits);
    FileHelper::WriteInteger(fileHandle, MBWidth);
    FileHelper::WriteDouble(fileHandle, EntryDistanceFromPreviousMB, Digits);
    FileHelper::WriteInteger(fileHandle, MBCount);
    FileHelper::WriteInteger(fileHandle, ZoneNumber);
    FileHelper::WriteDouble(fileHandle, ZoneImbalancePercentChange, Digits);
}
