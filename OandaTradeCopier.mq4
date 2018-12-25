//+------------------------------------------------------------------+
//|                                             OandaTradeCopier.mq4 |
//|                                                   Lonnie Coffman |
//|                                 https://github.com/LonnieCoffman |
//+------------------------------------------------------------------+
#property copyright "Lonnie Coffman"
#property link      "https://github.com/LonnieCoffman"
#property version   "1.00"
#property strict

// Refresh FXtrade Data files in case trades change on FXtrade from outside this EA.
int SecondsFXtData = 60;

extern int        MagicNumber =     12345;   // MT4 Magic Number


// Filenames
string LockFilename =  "TradeCopier\\bridge_lock";
string AliveFileName = "TradeCopier\\alive_check";

// Pair Struct
struct pairinf {
   string         Pair;             // Pair name
   string         FXtTradeName;     // Pair name for FXtrade
   int            MT4Trades[];      // Open MT4 Trades
   int            FXtTrades[];      // Open FXtrade Trades
   string         Trades[];         // TEMP: raw trade data for testing
}; pairinf PairInfo[];

// MT4 Data
int            MT4ID[];          // MT4 Trade ID
string         MT4Pair[];        // MT4 Pair
string         MT4Direction[];   // MT4 Trade Direction
datetime       MT4Time[];        // MT4 Trade Time
double         MT4Lots[];        // MT4 Trade Lots
double         MT4Price[];       // MT4 Trade OpenPrice

// FXtrade Data
int            FXtID[];          // FXtrade Trade ID
int            FXtToMT4ID[];     // FXtrade to MT4 ID
string         FXtPair[];        // FXtrade Pair
string         FXtDirection[];   // FXtrade Trade Direction
datetime       FXtTime[];        // FXtrade Trade Time
int            FXtLots[];        // FXtrade Trade Lots
double         FXtPrice[];       // FXtrade Trade OpenPrice
double         FXtFinancing[];   // FXtrade Trade Financing

int SecondsFXtDataTimer;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
   
   // create timer
   SecureSetTimer(1);
   SecondsFXtDataTimer = SecondsFXtData;

   // Oanda currently has 70 pairs available, so this is the max size the PairInfo array could ever be
   ArrayResize(PairInfo,70);

   ArrayResize(PairInfo[0].Trades,6);

   // dummy data
   PairInfo[0].Pair = "EURUSD";
   PairInfo[0].FXtTradeName = "EUR_USD";
   PairInfo[0].Trades[0] = "203712197-8110";
   PairInfo[0].Trades[1] = "203712197-8111";
   PairInfo[0].Trades[2] = "203712197-8112";
   PairInfo[0].Trades[3] = "203712197-8113";
   PairInfo[0].Trades[4] = "203712197-8114";
   PairInfo[0].Trades[5] = "203712197-8115";
   
   // Remove leftover objects and set colors
   CleanChart();
   
   // Get inital FXtrade Data
   //UpdateAllFXtTrades();
   
   //TEST: data backup and restore
   //DataBackup (PairInfo[0].Pair, 0);
   //DataRestore(PairInfo[0].Pair, 0);
   //for(int i = 0; i < ArraySize(PairInfo[0].Trades); i++){
   //   Print("MT4: "+PairInfo[0].MT4Trades[i]+" | FXt: "+PairInfo[0].FXtTrades[i]);
   //} 
   
   //TEST: MT4 trade retrieval
   
   //UpdateFXtTradeData();
   UpdateAllFXtTrades();
   Print(FXtTime[4]);
   
   //OpenFXtOrder("EUR_USD", "short", 200, 5879043);
   
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){

   EventKillTimer();
 
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer(){
   
   // Update MT4 trades
   UpdateAllMT4Trades();
   
   // Update FXtrade data on defined timer.
   if (SecondsFXtDataTimer >= SecondsFXtData){
      UpdateFXtTradeData();
      SecondsFXtDataTimer = 0;
   } else SecondsFXtDataTimer++;
    
   // loop through existing MT4 trades
   // -- if FXt trade does not exist OPEN
   
   // loop through existing FXt trades
   // -- if MT4 trade does not exist CLOSE
      
}
//+------------------------------------------------------------------+
//================================================//
// Populate MT4 Array                             //
//================================================//
// Assigning MT4 trades to an array, rather than performing operations on each iteration, so trades are only looped over once from MT4.
// Need to loop once for MT4 to FXt and again for FXt to MT4.
void UpdateAllMT4Trades(){
   int count = 0;
   
   // resize the arrays. Added to the ordersTotal in the offchance that an order is triggered between resetting the arrays and the order loop.
   ArrayResize(MT4ID, OrdersTotal()+5);
   ArrayResize(MT4Pair, OrdersTotal()+5);
   ArrayResize(MT4Direction, OrdersTotal()+5);
   ArrayResize(MT4Time, OrdersTotal()+5);
   ArrayResize(MT4Lots, OrdersTotal()+5);
   ArrayResize(MT4Price, OrdersTotal()+5);
   
   // loop through open orders
   for(int i=0; i<OrdersTotal(); i++){
      if((OrderSelect(i,SELECT_BY_POS) == true)&&(OrderMagicNumber() == MagicNumber)){
         if (OrderType() == OP_BUY || OrderType() == OP_SELL){
            MT4ID[count] = OrderTicket();
            MT4Pair[count] = OrderSymbol();
            if (OrderType() == OP_BUY) MT4Direction[count] = "long";
               else MT4Direction[count] = "short";
            MT4Time[count] = OrderOpenTime();
            MT4Lots[count] = OrderLots();
            MT4Price[count] = OrderOpenPrice();
            count++;
         }
      }
   }
   
   // resize arrays, removing unneeded elements.
   ArrayResize(MT4ID, count);
   ArrayResize(MT4Pair, count);
   ArrayResize(MT4Direction, count);
   ArrayResize(MT4Time, count);
   ArrayResize(MT4Lots, count);
   ArrayResize(MT4Price, count);
   
}

//================================================//
// Populate FXtrade Array                         //
//================================================//
// -- Read data from FXtrade's trade file and populate FXt arrays
void UpdateAllFXtTrades(){
   int handle;
   string filename = "TradeCopier\\FXtTrades.txt";
   string trades[];
   int numTrades;
   
   // read file
   if (FileIsExist(filename)){
      handle = FileOpen(filename,FILE_READ|FILE_TXT);
      FileReadArray(handle, trades);
      FileClose(handle);
   }
   
   numTrades = ArraySize(trades);
   
   ArrayResize(FXtID, numTrades);
   ArrayResize(FXtToMT4ID, numTrades);
   ArrayResize(FXtPair, numTrades);
   ArrayResize(FXtDirection, numTrades);
   ArrayResize(FXtTime, numTrades);
   ArrayResize(FXtLots, numTrades);
   ArrayResize(FXtPrice, numTrades);
   ArrayResize(FXtFinancing, numTrades);
   
   // loop over trades array
   for (int i = 0; i < numTrades; i++){
      // split each string
      string result[];
      StringSplit(trades[i],StringGetCharacter("_",0),result);
      // assign the split values to the arrays
      FXtPair[i] =      result[0];
      FXtDirection[i] = result[1];
      FXtID[i] =        int(StringToInteger(result[2]));
      FXtToMT4ID[i] =   int(StringToInteger(result[3]));
      FXtTime[i] =      int(StringToInteger(result[4]));
      FXtLots[i] =      int(StringToInteger(result[5]));
      FXtPrice[i] =     StringToDouble(result[6]);
      FXtFinancing[i] = StringToDouble(result[7]);
   }
}

//================================================//
// Read, Write and Restore Data                   //
//================================================//
// -- Backup and Restore functions
void DataBackup(string pair, int arrID){
   WriteTradeArray(pair, PairInfo[arrID].Trades);
}
void DataRestore(string pair, int arrID ){
   ReadTradeArray (pair, PairInfo[arrID].Trades);
   ParseTradeArray(pair, arrID);
}

// -- Write data to the data file
void WriteTradeArray(string pair, string &TradesArray[]){
   int handle;
   string filename = "TradeCopier\\data-"+pair+".txt";

   // delete the current file if it exists to erase any previous data
   FileDelete(filename);

   // write file
   handle = FileOpen(filename,FILE_READ|FILE_WRITE|FILE_TXT);
   
   if(handle!=INVALID_HANDLE){
      FileWriteArray(handle, TradesArray);
   }
   FileClose(handle);
}

// -- Read data from the data file
void ReadTradeArray(string pair, string &TradesArray[]){
   int handle;
   string filename = "TradeCopier\\data-"+pair+".txt";
   
   // read file
   if (FileIsExist(filename)){
      handle = FileOpen(filename,FILE_READ|FILE_TXT);
      FileReadArray(handle, TradesArray);
      FileClose(handle);
   }
}

// -- Parse data from the data file
void ParseTradeArray(string pair, int arrID){
   string result[];
   
   // resize the trade arrays
   ArrayResize(PairInfo[arrID].MT4Trades,ArraySize(PairInfo[arrID].Trades));
   ArrayResize(PairInfo[arrID].FXtTrades,ArraySize(PairInfo[arrID].Trades));
   
   // split the trade data and assign to proper arrays
   for (int i = 0; i < ArraySize(PairInfo[arrID].Trades); i++){
      if (StringSplit(PairInfo[arrID].Trades[i],StringGetCharacter("-",0),result) > 0){
         PairInfo[arrID].MT4Trades[i] = int(StringToInteger(result[0]));
         PairInfo[arrID].FXtTrades[i] = int(StringToInteger(result[1]));
      }
   }
}

//================================================//
// FXtrade Bridge Functions                       //
//================================================//
// create order file (side = "long" or "short")
bool OpenFXtOrder(string instrument, string side, int units, int mt4TradeID){
   int fileHandle;
   bool success = false;
   string pair = instrument;
   StringReplace(pair,"_","");
   string command = "openmarket-"+instrument+"-"+side+"-"+IntegerToString(units)+"-"+IntegerToString(mt4TradeID);

   if (FileIsExist(LockFilename) != true){ // Wait for python to finish
      LockDirectory();
      fileHandle = FileOpen("TradeCopier\\"+command,FILE_WRITE|FILE_TXT);
      if(fileHandle!=INVALID_HANDLE){
         FileClose(fileHandle);
         success = true;
      }
      UnlockDirectory();
      Sleep(5000);
   }
   
   return success;
}

// create close trade file (side = "long" or "short")
bool CloseFXtTrade(int tradeID, string side, int units=0){
   int fileHandle;
   bool success = false;
   
   if (FileIsExist(LockFilename) != true){ // Wait for python to finish
      LockDirectory();
      fileHandle=FileOpen("TradeCopier\\closeTrade-"+IntegerToString(tradeID)+"-"+side+"-"+IntegerToString(units),FILE_WRITE|FILE_TXT);
      if(fileHandle!=INVALID_HANDLE){
         FileClose(fileHandle);
         success = true;
      }
      UnlockDirectory();
   }
   
   return success;
}

// create close position file (side = "long", "short" or "both")
bool CloseFXtPosition(string instrument, int arrID, string side, int units=0){
   int fileHandle;
   double profit = 0.0;
   bool success = false;
   string pair = instrument;
   StringReplace(pair,"_","");

   if (FileIsExist(LockFilename) != true){ // Wait for python to finish
      LockDirectory();
      fileHandle=FileOpen("TradeCopier\\closePosition-"+instrument+"-"+side+"-"+IntegerToString(units),FILE_WRITE|FILE_TXT);
      if(fileHandle!=INVALID_HANDLE){
         FileClose(fileHandle);
         success = true;
      }
      UnlockDirectory();
   }
   
   return success;
}

// create update request file
bool UpdateFXtTradeData(){
   int fileHandle;
   bool success = false;
   
   if (FileIsExist(LockFilename) != true){ // Wait for python to finish
      LockDirectory();
      fileHandle=FileOpen("TradeCopier\\updateTradeData",FILE_WRITE|FILE_TXT);
      if(fileHandle!=INVALID_HANDLE){
         FileClose(fileHandle);
         success = true;
      }
      UnlockDirectory();
   }
   
   return success;
}

// lock directory so python does not access files
bool LockDirectory(){
   int fuFilehandle;
   fuFilehandle=FileOpen("TradeCopier\\MT4-Locked",FILE_WRITE|FILE_TXT);
   if(fuFilehandle!=INVALID_HANDLE){
      FileClose(fuFilehandle);
      return true;
   } else return false;
}

// unlock directory so python can access files
bool UnlockDirectory(){
   int fuFilehandle;
   fuFilehandle=FileDelete("TradeCopier\\MT4-Locked");
   if (fuFilehandle == false) return false;
      else return true;
}

//================================================//
// Clean Chart on First Open                      //
//================================================//
void CleanChart(){
   // remove any leftover objects
   for (int obj = ObjectsTotal(); obj > 0; obj--){
      ObjectDelete(ObjectName(obj));
   }
   // change chart colors
   ChartSetInteger(0,CHART_SCALE,0,5);
   ChartSetInteger(0,CHART_COLOR_GRID,0,clrNONE);
   ChartSetInteger(0,CHART_COLOR_BACKGROUND,0,clrNONE);
   ChartSetInteger(0,CHART_COLOR_FOREGROUND,0,clrGainsboro);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,0,clrNONE);
   ChartSetInteger(0,CHART_COLOR_CHART_DOWN,0,clrNONE);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,0,clrNONE);
   ChartSetInteger(0,CHART_COLOR_CHART_UP,0,clrNONE);
   ChartSetInteger(0,CHART_COLOR_ASK,0,clrNONE);
   ChartSetInteger(0,CHART_COLOR_BID,0,clrNONE);
   ChartSetInteger(0,CHART_COLOR_CHART_LINE,0,clrNONE);
   ChartSetInteger(0,CHART_COLOR_VOLUME,0,clrNONE);
   ChartSetInteger(0,CHART_COLOR_STOP_LEVEL,0,clrNONE);
   ChartSetInteger(0,CHART_COLOR_LAST,0,clrNONE);
   ChartSetInteger(0,CHART_MODE,0,0);
}

bool SecureSetTimer(int seconds){
// **** Borrowed from Desky
// -------------------------------------------------

   //This is another brilliant idea by tomele. Many thanks Thomas. Here is the explanation:
/*
I am testing something René has developed on Eaymon's VPS as well as on Google's VPS. I ran into a problem with EventSetTimer(). 
This problem was reported by other users before and apparently occurs only on VPS's, not on desktop machines. The problem is that 
calls to EventSetTimer() eventually fail with different error codes returned. The EA stays on the chart with a smiley (it 
is not removed), but no timer events are sent to OnTimer() and the EA doesn't act anymore. 

The problem might be caused by the VPS running out of handles. A limited number of these handles is shared as a pool 
between all virtual machines running on the same host machine. The problem occurs randomly when all handles are in use 
and can be cured by repeatedly trying to set a timer until you get no error code.

I have implemented a function SecureSetTimer() that does this. If you replace EventSetTimer() calls with SecureSetTimer() 
calls in the EA code, this VPS problem will not affect you anymore:
*/
   int error=-1;
   int counter=1;
   
   do {
      EventKillTimer();
      ResetLastError();
      EventSetTimer(seconds);
      error=GetLastError();
      Print("SecureSetTimer, attempt=",counter,", error=",error);
      if(error!=0) Sleep(1000);
      counter++;
   }
   while(error!=0 && !IsStopped() && counter<100);
   
   return(error==0);
}