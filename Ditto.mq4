//+------------------------------------------------------------------+
//|                                                        Ditto.mq4 |
//|                                                   Lonnie Coffman |
//|                                 https://github.com/LonnieCoffman |
//+------------------------------------------------------------------+
#property copyright "Lonnie Coffman"
#property link      "https://github.com/LonnieCoffman"
#property version   "1.3.7"
#property strict

string dittoVersion = "1.3.7";

enum TradeDir
{
   BothDirections = 0,  // Copy Short and Long trades
   OnlyShort      = 1,  // Copy only Short trades
   OnlyLong       = 2   // Copy only Long trades
};

enum RowSize
{
   ExtraSmall = 15,  // Extra Small
   Small      = 18,  // Small
   Regular    = 21,  // Medium (Standard)
   Large      = 24,  // Large
   ExtraLarge = 27   // Extra Large
};

enum Type
{
   DemoAccount = 0,  // Demo Account
   LiveAccount = 1   // Live Account
};

enum Lev
{
   fiftyToOne  = 50, // 50:1
   fourtyToOne = 40, // 40:1
   thirtyToOne = 30, // 30:1
   twentyToOne = 20, // 20:1
   tenToOne    = 10  // 10:1
};

// Refresh FXtrade Data files in case trades change on FXtrade from outside this EA.
int SecondsFXtData = 300;
extern string     externDash0 = "";                      // -------- OANDA ACCOUNT --------
extern string     SystemName =            "default";     // System Name (Unique for mult. instances)
extern string     FirstAccount =          "";            // 1st Oanda fxTrade Acct. Number
extern string     SecondAccount =         "";            // 2nd Oanda fxTrade Acct. Number (Blank for single)
extern string     APIKey =                "";            // Your Oanda V20 API Key
extern Type       AccountType =           0;             // Type of Account
extern Lev        AccountLeverage =       50;            // Account leverage
extern string     spacer1 = "";                          // .
extern string     externDash1 = "";                      // -------- TRADE DETAILS --------
extern int        MagicNumber =           12345;         // MT4 Magic Number (0 for all)
extern TradeDir   TradeDirection =        BothDirections;// Trading Direction to Monitor
extern bool       CopyPendingTrades =     true;          // Copy Pending trades (Only works with Oanda MT4)
extern double     PercentOfMT4 =          10.0;          // Percent of MT4 Trade Size
// extern bool       UseIncrementalLots =    true;          // Increase each trade by 1 unit (US FIFO)
extern string     spacer2 = "";                          // .
extern string     externDash2 = "";                      // -------- DASHBOARD DISPLAY --------
extern bool       IncludeSwapInPL =       true;          // Include Finance Charges in P/L Totals?
extern double     ShortPandLOffset =      0.0;           // Offset to Adjust Short P/L Reported by Oanda
extern double     LongPandLOffset =       0.0;           // Offset to Adjust Long P/L Reported by Oanda
extern RowSize    RowHeight =             21;            // Size of rows in dash
extern int        HeaderText =            8;             // Header Text Size

bool DisplayMT4LotsAsUnits = false; // Display MT4 Lots as Units?
bool DisplayFXtLotsAsUnits = true;  // Display FXt Lots as Units?
bool ShowAllTrades = false;         // Toggle show all trades

// graphics
string ArrowUp =  "\\Images\\SmallUpArrow.bmp";
string ArrowDown ="\\Images\\SmallDownArrow.bmp";
string Neutral =  "\\Images\\Neutral.bmp";

// Dashboard Variables
int   x_axis;
int   y_axis; // defined in draw dash
int   HeaderTextSize;
int   LabelTextSize;
int   DashRowHeight;
int   DashTextSize;
int   DashWidth;
//int   DashMid = int(DashWidth / 2)-50;

// Filenames
string MT4LockFilename;
string LockFilename;
string AliveFileName;

// Pair Struct
struct pairinf {
   string         Pair;                // Pair name
   string         FXtTradeName;        // Pair name for FXtrade
   double         USMarginRequirement; // US Margin Requirements
   bool           ShowTrades;          // Display Trades in Dash?
   string         TradeDirection;      // Not used
   
   // MT4 Trade Data
   int            MT4TradeCount;
   int            MT4ShortTradeCount;
   int            MT4LongTradeCount;
   int            MT4PendingOrderCount;
   int            MT4PendingLongOrderCount;
   int            MT4PendingShortOrderCount;
   int            MT4TradeID[];
   double         MT4OpenLotsize;
   double         MT4ShortOpenLotsize;
   double         MT4LongOpenLotsize;
   double         MT4Profit;
   double         MT4LongProfit;
   double         MT4ShortProfit;
   double         MT4ProfitPips;
   double         MT4ShortProfitPips;
   double         MT4LongProfitPips;

   // FXtrade Trade Data
   int            FXtTradeCount;
   int            FXtShortTradeCount;
   int            FXtLongTradeCount;
   int            FXtPendingOrderCount;
   int            FXtPendingLongOrderCount;
   int            FXtPendingShortOrderCount;
   int            FXtTradeID[];
   int            FXtOpenLotsize;
   int            FXtShortOpenLotsize;
   int            FXtLongOpenLotsize;
   double         FXtShortAveragePrice;
   double         FXtLongAveragePrice;
   double         FXtAveragePrice;
   double         FXtFinancing;
   double         FXtProfit;
   double         FXtLongProfit;
   double         FXtShortProfit;
   double         FXtProfitPips;
   double         FXtShortProfitPips;
   double         FXtLongProfitPips;
   double         FXtUsedMargin;
   double         FXtShortUsedMargin;
   double         FXtLongUsedMargin;
   
}; pairinf PairInfo[];

// MT4 Data
int            MT4ID[];          // MT4 Trade ID
string         MT4Pair[];        // MT4 Pair
string         MT4Direction[];   // MT4 Trade Direction
datetime       MT4Time[];        // MT4 Trade Time
double         MT4Lots[];        // MT4 Trade Lots
double         MT4Price[];       // MT4 Trade OpenPrice
double         MT4PrevPrice[];   // MT4 Previous price for pending order change
double         MT4Profit[];      // MT4 Current Profit/Loss

double         MT4CurrentProfit; // MT4 Account Profit
double         MT4CurrentShortProfit;
double         MT4CurrentLongProfit;

int            MT4TotalTrades;   // MT4 Total Trades
int            MT4TotalShortTrades;
int            MT4TotalLongTrades;

int            MT4TotalOrders;   // MT4 Total Pending Orders

double         MT4TotalLots;     // MT4 Total Lots
double         MT4TotalLongLots;
double         MT4TotalShortLots;
double         MT4TotalPips;

// FXtrade Data
int            FXtID[];          // FXtrade Trade ID
int            FXtToMT4ID[];     // FXtrade to MT4 ID
string         FXtPair[];        // FXtrade Pair
string         FXtDirection[];   // FXtrade Trade Direction
datetime       FXtTime[];        // FXtrade Trade Time
int            FXtLots[];        // FXtrade Trade Lots
double         FXtPrice[];       // FXtrade Trade OpenPrice
double         FXtProfit[];      // FXtrade Trade Profit
double         FXtFinancing[];   // FXtrade Trade Financing
double         FXtMargin[];      // FXtrade Trade Margin Used

double         FXtCurrentProfit; // FXt Account Profit
double         FXtCurrentShortProfit;
double         FXtCurrentLongProfit;

int            FXtTotalTrades;   // FXt Total Trades
int            FXtTotalShortTrades;
int            FXtTotalLongTrades;

int            FXtTotalPendingOrders;

double         FXtCurrentFinancing;
double         FXtCurrentShortFinancing;
double         FXtCurrentLongFinancing;

double         FXtTotalUsedMargin;
double         FXtTotalShortUsedMargin;
double         FXtTotalLongUsedMargin;

int            FXtTotalLots;     // FXt Total Lots
int            FXtTotalLongLots;
int            FXtTotalShortLots;
double         FXtTotalPips;

// Account Data
double ShortAccountBal,ShortAvailMargin,ShortUsedMargin,ShortMarginLevel,ShortAccountEquity,ShortRealizedPL,ShortAccountProfit,ShortAccountPips;
int ShortNumOpenTrades;

double LongAccountBal,LongAvailMargin,LongUsedMargin,LongMarginLevel,LongAccountEquity,LongRealizedPL,LongAccountProfit,LongAccountPips;
int LongNumOpenTrades;

double AccountBal,AvailMargin,UsedMargin,MarginLevel,AcctEquity,RealizedPL,CurrentProfit,CurrentPips;
int NumOpenTrades;

int MT4PrevTotalTrades;
int MT4PrevTotalOrders;

int SecondsFXtDataTimer;

bool DualAccounts;
string FolderName, ErrorMessage, ConfigErrorMessage;
bool DeleteSystemFolder;

int AliveTimer,AliveSeconds;

bool ConfigValid;
bool FXtUpdated;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
/*
   //OrderSend("CADCHF",OP_SELLSTOP,0.03,0.73080,30.0,0,0,NULL,12345);
   OrderSend("CADCHF",OP_BUYLIMIT,0.02,0.73166,30.0,0,0,NULL,12345);
   OrderSend("CADCHF",OP_SELLLIMIT,0.03,0.74480,30.0,0,0,NULL,12345);
   OrderSend("CADCHF",OP_BUYSTOP,0.05,0.74891,30.0,0,0,NULL,12345);

   OrderSend("GBPUSD",OP_BUY,0.03,MarketInfo("GBPUSD",MODE_ASK),30.0,0,0,NULL,12345);
   OrderSend("AUDJPY",OP_SELL,0.03,MarketInfo("AUDJPY",MODE_BID),30.0,0,0,NULL,12345);
   OrderSend("NZDJPY",OP_BUY,0.03,MarketInfo("NZDJPY",MODE_ASK),30.0,0,0,NULL,12345);
   OrderSend("CADCHF",OP_SELL,0.03,MarketInfo("CADCHF",MODE_BID),30.0,0,0,NULL,12345);
*/
//OrderSend("EURUSD",OP_BUYSTOP,0.05,1.14473,30.0,0,0,NULL,12345);
//OrderSend("GBPUSD",OP_BUYLIMIT,0.04,1.26789,30.0,0,0,NULL,12345);

   //OpenFXtPending("AUD_CHF", "sell", "stop", 0.73080, 200, 204547577);
   //CloseFXtPending("AUD_USD", "buy", "limit", 200, 4235, 204560842);
   
   FXtUpdated = false;
   
   DeleteSystemFolder = true;
   FolderName = CleanFolderName(SystemName);
   
   CleanChart();
   
   Print("Ditto v"+dittoVersion+" | (c)2018 by Lonnie Coffman"); 
   
   ConfigValid = true;
   if (!InitOK()){
      Comment("\n   ========================================\n   == "+ConfigErrorMessage+" ==\n   ========================================");
      Print("");
      Print("==== "+ConfigErrorMessage+" ====");
      Print("");
      ConfigValid = false;
   }

   if (ConfigValid){
   
      CreateConfigFile();
      
      AliveTimer = 0;
      AliveSeconds = 0;
      
      MT4LockFilename  = "Ditto\\"+FolderName+"\\MT4-Locked";
      LockFilename     = "Ditto\\"+FolderName+"\\bridge_lock";
      AliveFileName    = "Ditto\\"+FolderName+"\\alive_check";
      
      if (SecondAccount == "") DualAccounts = false;
      
      // Dash Sizing.  Here so changes with Extern redraw dash
      x_axis = 30;
      //y_axis; // defined in draw dash
      HeaderTextSize = HeaderText;
      LabelTextSize = 7;
      DashRowHeight = RowHeight;
      DashTextSize = DashRowHeight/3;
      DashWidth = 1048;
   
      // create timer
      //EventSetTimer(1);
      SecureSetTimer(1);
      SecondsFXtDataTimer = SecondsFXtData;
   
      // Oanda currently has 70 pairs available, so this is the max size the PairInfo array could ever be
      ArrayResize(PairInfo,70);
   
      UpdateMT4Trades();
      UpdateFXtTradeData();
      UpdateFXtTrades();
      UpdateData();
      DrawDash();
      MT4PrevTotalTrades = MT4TotalTrades;
      MT4PrevTotalOrders = MT4TotalOrders;
      
   }
   
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){

   EventKillTimer();
   
   // Remove folder
   if (DeleteSystemFolder){
      FolderClean("Ditto\\"+FolderName);
      FolderDelete("Ditto\\"+FolderName);
   }
   
   // Remove objects
   ObjectsDeleteAll(0);
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer(){
   
   if (ConfigValid){
      
      UpdateMT4Trades();
      UpdateFXtTrades();
      
      UpdateData();
      UpdateDash();
   
      if (StatusOK() && FXtUpdated){
         OpenTrades();
         CloseTrades();
      }
   
      // Number of trades changed...update data( for pending change) and redraw
      if ((MT4TotalTrades != MT4PrevTotalTrades)||(MT4TotalOrders != MT4PrevTotalOrders)){
         UpdateMT4Trades();
         UpdateFXtTrades();
         UpdateData();
         DrawDash();
         UpdateDash();
         MT4PrevTotalTrades = MT4TotalTrades;
         MT4PrevTotalOrders = MT4TotalOrders;
         // trigger update trade data from fxTrade
         SecondsFXtDataTimer = SecondsFXtData;
      }
      
      // Update FXtrade data on defined timer. (Not necessary, but just in case)
      if (SecondsFXtDataTimer >= SecondsFXtData){
         UpdateFXtTradeData();
         SecondsFXtDataTimer = 0;
      } else SecondsFXtDataTimer++;

   }
}
//+------------------------------------------------------------------+
//================================================//
// Secure Event timer -- thx Thomas               //
//================================================//
bool SecureSetTimer(int seconds){
   int error=-1;
   int counter=1;
   
   do{
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

//================================================//
// Close Trades                                   //
//================================================//
void CloseTrades(){
   string filename = "Ditto\\"+FolderName+"\\FXtTrades.txt";
   
   if (FileIsExist(LockFilename) != true){ // Wait for python to finish
      if (FileIsExist(MT4LockFilename) != true){ // If MT4 lock file exists wait. (just in case)
         // loop through existing FXt trades
         // -- if MT4 trade does not exist CLOSE
         for (int i = 0; i < ArraySize(FXtID); i++){
            bool closeTrade = true; // set to false if trade found
            
            for (int a = 0; a < ArraySize(MT4ID); a++){
               if (FXtToMT4ID[i] == MT4ID[a]){
                  closeTrade = false;
                  // if pending price changed remove pending.
                  if ((FXtDirection[i] != "short")&&(FXtDirection[i] != "long")){
                     if (MT4PrevPrice[a] != MT4Price[a]){
                        closeTrade = true;
                     }
                  }
               }
            }

            if (closeTrade){
               // close active trade
               if ((FXtDirection[i] == "short")||(FXtDirection[i] == "long")){
                  CloseFXtTrade(FXtID[i], FXtDirection[i]);
               } else { // remove pending order
                  if (FXtDirection[i] == "sellStop")        CloseFXtPending(FXtPair[i], "sell", "stop",  FXtLots[i], FXtID[i], FXtToMT4ID[i]);
                  else if (FXtDirection[i] == "sellLimit")  CloseFXtPending(FXtPair[i], "sell", "limit", FXtLots[i], FXtID[i], FXtToMT4ID[i]);
                  else if (FXtDirection[i] == "buyStop")    CloseFXtPending(FXtPair[i], "buy",  "stop",  FXtLots[i], FXtID[i], FXtToMT4ID[i]);
                  else if (FXtDirection[i] == "buyLimit")   CloseFXtPending(FXtPair[i], "buy",  "limit", FXtLots[i], FXtID[i], FXtToMT4ID[i]);
               }
            }
         }
      }
   }
}

//================================================//
// Open Trades                                    //
//================================================//
void OpenTrades(){
   bool openTrade = true;
   int numTrades = 0;
   string filename = "Ditto\\"+FolderName+"\\FXtTrades.txt";
   int handle;
   string trades[];
   
   if (FileIsExist(LockFilename) != true){ // Wait for python to finish
      if (FileIsExist(MT4LockFilename) != true){ // If MT4 lock file exists wait. (just in case)
         if (FileIsExist(filename) == true){
            // loop through existing MT4 trades
            // -- if FXt trade does not exist OPEN
            for (int i = 0; i < ArraySize(MT4ID); i++){
               if (ArraySize(FXtID) > 0) openTrade = false;
               for (int a = 0; a < ArraySize(FXtID); a++){
                  openTrade = true;
                  if (MT4ID[i] == FXtToMT4ID[a]){
                     openTrade = false;
                     break;
                  }
               }
               
               if (openTrade){
                  // verify that trade is not already in FXtTrades.txt?
                  if (FileIsExist(filename)){
                     handle = FileOpen(filename,FILE_READ|FILE_TXT);
                     FileReadArray(handle, trades);
                     FileClose(handle);
                     
                     string pair = StringSubstr(MT4Pair[i],0,3)+"_"+StringSubstr(MT4Pair[i],3,3);
                     
                     for (int c = 0; c < ArraySize(trades); c++){
                        string result[];
                        StringSplit(trades[c],StringGetCharacter("_",0),result);
                        if (int(StringToInteger(result[3])) == MT4ID[i]) return; // trade already exists
                        // increment trade count for lot sizing
                        if (result[0] == MT4Pair[i]) numTrades++;
                     }
                     
                     // market or pending
                     if ((MT4Direction[i] == "long")||(MT4Direction[i] == "short")){
                        OpenFXtOrder(pair, MT4Direction[i], CalculateUnits(MT4Lots[i],pair), MT4ID[i]);
                     } else { // this is a pending order
                        if (MT4Direction[i] == "sellStop")        OpenFXtPending(pair, "sell", "stop",  MT4Price[i], CalculateUnits(MT4Lots[i],pair), MT4ID[i]);
                        else if (MT4Direction[i] == "sellLimit")  OpenFXtPending(pair, "sell", "limit", MT4Price[i], CalculateUnits(MT4Lots[i],pair), MT4ID[i]);
                        else if (MT4Direction[i] == "buyStop")    OpenFXtPending(pair, "buy",  "stop",  MT4Price[i], CalculateUnits(MT4Lots[i],pair), MT4ID[i]);
                        else if (MT4Direction[i] == "buyLimit")   OpenFXtPending(pair, "buy",  "limit", MT4Price[i], CalculateUnits(MT4Lots[i],pair), MT4ID[i]);
                     }
                     return; // Only try to open 1 trade per timer loop
                  }
               }
            }
         }
      }
   }
}

//================================================//
// Calculate Lot Size                             //
//================================================//
int CalculateUnits(double lots, string pair){
   int tempArray[];
   int addon = 0;
   //int size;
   StringReplace(pair,"_","");
   
   int baseUnits = int(NormalizeDouble(lots * 100000,0));
   int fxtUnits = int(NormalizeDouble(baseUnits * PercentOfMT4 * 0.01,0));
   
   /*
   if (UseIncrementalLots){
      
      // create array of open trade sizes
      for (int i = 0; i < ArraySize(FXtID); i++){
         if (FXtPair[i] == pair){
            size = ArraySize(tempArray);
            ArrayResize(tempArray,size+1);
            tempArray[size] = FXtLots[i];
         }
      }

      if (ArraySize(tempArray) > 0){
      
         // if size > max open trade no need to continue
         int maxOpen = tempArray[ArrayMaximum(tempArray)];
         if (fxtUnits > maxOpen) return fxtUnits;
         
         // count up starting at fxtUnits
         for (int i = fxtUnits; i < maxOpen; i++){
            int idx = ArrayBsearch(tempArray, i);
            if (tempArray[idx] != fxtUnits) return i;
         }
         
         // if we made it here there was a problem
         return maxOpen + 1;
      }
   }
   */
   
   return fxtUnits + addon;
}

//================================================//
// Update Data                                    //
//================================================//
void UpdateData(){
   string tempArray[];
   int sortedArray[];
   int count = 0;
   string filename;
   int handle;

//-----------  update account information
   if (FileIsExist(LockFilename) != true){ // Wait for python to finish
      if (FileIsExist(MT4LockFilename) != true){ // If MT4 lock file exists wait. (just in case)
         
         bool PrevAccounts = DualAccounts;
         
         // Are we trading a single account or dual
         filename = "Ditto\\"+FolderName+"\\account-combined.txt";
         if (FileIsExist(filename)){
            handle = FileOpen(filename,FILE_READ|FILE_CSV,",");
            
            AccountBal =      NormalizeDouble(StrToDouble(FileReadString(handle)),2);
            NumOpenTrades =   StrToInteger(FileReadString(handle));
            AvailMargin =     NormalizeDouble(StrToDouble(FileReadString(handle)),2);
            UsedMargin =      NormalizeDouble(StrToDouble(FileReadString(handle)),2);
            RealizedPL =      NormalizeDouble(StrToDouble(FileReadString(handle)),2);
            
            FileClose(handle);
            
            AcctEquity =      NormalizeDouble(AccountBal + CurrentProfit,2);

            if (FXtTotalUsedMargin != 0) MarginLevel = NormalizeDouble((AcctEquity / FXtTotalUsedMargin) * 100, 2);
               else MarginLevel = 0;
            
            DualAccounts = false;
            if (PrevAccounts != DualAccounts) DrawDash();
         // Dual account details 
         } else {
            // update short account
            filename = "Ditto\\"+FolderName+"\\account-short.txt";
            if (FileIsExist(filename)){
               handle = FileOpen(filename,FILE_READ|FILE_CSV,",");
               
               ShortAccountBal =      StrToDouble(FileReadString(handle));
               ShortNumOpenTrades =   StrToInteger(FileReadString(handle));
               ShortAvailMargin =     StrToDouble(FileReadString(handle));
               ShortUsedMargin =      StrToDouble(FileReadString(handle));
               ShortRealizedPL =      StrToDouble(FileReadString(handle));
               
               FileClose(handle);
            }
            // update long account
            filename = "Ditto\\"+FolderName+"\\account-long.txt";
            if (FileIsExist(filename)){
               handle = FileOpen(filename,FILE_READ|FILE_CSV,",");
               
               LongAccountBal =      StrToDouble(FileReadString(handle));
               LongNumOpenTrades =   StrToInteger(FileReadString(handle));
               LongAvailMargin =     StrToDouble(FileReadString(handle));
               LongUsedMargin =      StrToDouble(FileReadString(handle));
               LongRealizedPL =      StrToDouble(FileReadString(handle));
               
               FileClose(handle);
            }
         
            DualAccounts = true;
            if (PrevAccounts != DualAccounts) DrawDash();
            // update combined account
            AccountBal = NormalizeDouble(ShortAccountBal + LongAccountBal,2);
            NumOpenTrades = ShortNumOpenTrades + LongNumOpenTrades;
            AvailMargin = NormalizeDouble(ShortAvailMargin + LongAvailMargin,2);
            UsedMargin = NormalizeDouble(ShortUsedMargin + LongUsedMargin,2);
            RealizedPL = NormalizeDouble(ShortRealizedPL + LongRealizedPL,2);
            
            AcctEquity           = NormalizeDouble(AccountBal + CurrentProfit,2);
            ShortAccountEquity   = NormalizeDouble(ShortAccountBal + ShortAccountProfit,2);
            LongAccountEquity    = NormalizeDouble(LongAccountBal + LongAccountProfit,2);

            if (FXtTotalUsedMargin != 0) MarginLevel = NormalizeDouble((AcctEquity / FXtTotalUsedMargin) * 100, 2);
               else MarginLevel = 0;
            if (FXtTotalShortUsedMargin != 0) ShortMarginLevel = NormalizeDouble((ShortAccountEquity / FXtTotalShortUsedMargin) * 100, 2);
               else ShortMarginLevel = 0;
            if (FXtTotalLongUsedMargin != 0) LongMarginLevel  = NormalizeDouble((LongAccountEquity / FXtTotalLongUsedMargin) * 100, 2);
               else LongMarginLevel = 0;

         }
      }
   }
   

   
// ---------- loop through MT4 array and resize trading arrays
   for (int i = 0; i < ArraySize(MT4Pair); i++){

      bool found = false;
      
      // Check if in temp array
      for (int a = 0; a < ArraySize(tempArray); a++){
         if (MT4Pair[i] == tempArray[a]) found = true;
      }
      
      // not in array so increase array size by 1 and add
      if (!found){
         int size = ArraySize(tempArray);
         ArrayResize(tempArray,size+1);
         tempArray[size] = MT4Pair[i];
      }
   }

   // resize based on unique pair count above.
   ArrayResize(PairInfo,ArraySize(tempArray));
   ArrayResize(sortedArray,ArraySize(tempArray));
   
   // alphabetize array to make dynamic display easier
   for (int i = 0; i < ArraySize(tempArray); i++){
      sortedArray[i] = PairToInt(tempArray[i]);
   }
   
   if (ArraySize(sortedArray) > 0) ArraySort(sortedArray);
   
   // reassign sortedArray to tempArray
   for (int i = 0; i < ArraySize(sortedArray); i++){
      tempArray[i] = IntToPair(sortedArray[i]);
   }
   
   // assign pairnames to PairInfo.Pair. Should be in alphabetical order
   for (int i = 0; i < ArraySize(tempArray); i++){
      PairInfo[i].Pair = tempArray[i];
   }
   
   // loop through all unique pairs and update data
   for(int i=0;i<ArraySize(PairInfo);i++){
      PairInfo[i].FXtTradeName = StringSubstr(PairInfo[i].Pair,0,3)+"_"+StringSubstr(PairInfo[i].Pair,3,3);
      PairInfo[i].FXtProfit = 0;
   }
   
// ---------- Update FXt Short Trade Info
   if (FileIsExist(LockFilename) != true){ // Wait for python to finish
      if (FileIsExist(MT4LockFilename) != true){ // If MT4 lock file exists wait. (just in case)
         
         for(int i=0;i<ArraySize(PairInfo);i++){
            // read position
            filename = "Ditto\\"+FolderName+"\\position-"+PairInfo[i].FXtTradeName+"-short.txt";
            if (FileIsExist(filename)){
               // assign values
               handle = FileOpen(filename,FILE_READ|FILE_CSV,",");
               PairInfo[i].TradeDirection = FileReadString(handle);
               PairInfo[i].FXtShortOpenLotsize = MathAbs(int(FileReadString(handle)));
               PairInfo[i].FXtShortAveragePrice = StringToDouble(FileReadString(handle));
               PairInfo[i].FXtShortTradeCount = int(FileReadString(handle));
               FileClose(handle);
               
               // calculate Short Profit and pips
               if (PairInfo[i].FXtShortTradeCount > 0){
                  if (StringFind(PairInfo[i].Pair,"JPY") >= 0) PairInfo[i].FXtShortProfit = MarketInfo(PairInfo[i].Pair, MODE_TICKVALUE) * PairInfo[i].FXtShortOpenLotsize * (PairInfo[i].FXtShortAveragePrice - MarketInfo(PairInfo[i].Pair,MODE_ASK))/100;
                     else PairInfo[i].FXtShortProfit = MarketInfo(PairInfo[i].Pair, MODE_TICKVALUE) * PairInfo[i].FXtShortOpenLotsize * (PairInfo[i].FXtShortAveragePrice - MarketInfo(PairInfo[i].Pair,MODE_ASK));
                  PairInfo[i].FXtShortProfitPips = NormalizeDouble((PairInfo[i].FXtShortAveragePrice - MarketInfo(PairInfo[i].Pair,MODE_ASK))/MarketInfo(PairInfo[i].Pair,MODE_POINT)/10,1);
               }
               
            } else {
               // reset values
               PairInfo[i].TradeDirection = "none";
               PairInfo[i].FXtShortOpenLotsize = 0;
               PairInfo[i].FXtShortAveragePrice = 0;
               PairInfo[i].FXtShortProfitPips = 0;
               PairInfo[i].FXtShortTradeCount = 0;
               PairInfo[i].FXtShortProfit = 0;
            }
         }
      
      // ---------- Update FXt Long Trade Info
         for(int i=0;i<ArraySize(PairInfo);i++){
            // read position
            filename = "Ditto\\"+FolderName+"\\position-"+PairInfo[i].FXtTradeName+"-long.txt";
            if (FileIsExist(filename)){
               // assign values
               handle = FileOpen(filename,FILE_READ|FILE_CSV,",");
               PairInfo[i].TradeDirection = FileReadString(handle);
               PairInfo[i].FXtLongOpenLotsize = int(FileReadString(handle));
               PairInfo[i].FXtLongAveragePrice = StringToDouble(FileReadString(handle));
               PairInfo[i].FXtLongTradeCount = int(FileReadString(handle));
               FileClose(handle);
               
               // calculate Long Profit and pips
               if (PairInfo[i].FXtLongTradeCount > 0){
                  if (StringFind(PairInfo[i].Pair,"JPY") >= 0) PairInfo[i].FXtLongProfit = MarketInfo(PairInfo[i].Pair, MODE_TICKVALUE) * PairInfo[i].FXtLongOpenLotsize * (MarketInfo(PairInfo[i].Pair,MODE_BID) - PairInfo[i].FXtLongAveragePrice)/100;
                  else PairInfo[i].FXtLongProfit = MarketInfo(PairInfo[i].Pair, MODE_TICKVALUE) * PairInfo[i].FXtLongOpenLotsize * (MarketInfo(PairInfo[i].Pair,MODE_BID) - PairInfo[i].FXtLongAveragePrice);
               PairInfo[i].FXtLongProfitPips = NormalizeDouble((MarketInfo(PairInfo[i].Pair,MODE_BID) - PairInfo[i].FXtLongAveragePrice)/MarketInfo(PairInfo[i].Pair,MODE_POINT)/10,1);
               }
               
            } else {
               // reset values
               PairInfo[i].TradeDirection = "none";
               PairInfo[i].FXtLongOpenLotsize = 0;
               PairInfo[i].FXtLongAveragePrice = 0;
               PairInfo[i].FXtLongProfitPips = 0;
               PairInfo[i].FXtLongTradeCount = 0;
               PairInfo[i].FXtLongProfit = 0;
            }
            
            // update trade count
            PairInfo[i].FXtTradeCount = PairInfo[i].FXtLongTradeCount + PairInfo[i].FXtShortTradeCount;
         }
      }
   }

   
// ----------- Update MT4 Trade Info
   MT4CurrentProfit     = 0;
   MT4CurrentShortProfit= 0;
   MT4CurrentLongProfit = 0;
   MT4TotalLots         = 0;
   MT4TotalLongLots     = 0;
   MT4TotalShortLots    = 0;
   MT4TotalTrades       = 0;
   MT4TotalOrders       = 0;
   MT4TotalShortTrades  = 0;
   MT4TotalLongTrades   = 0;
   MT4TotalPips         = 0;
   
   // -------------FXt Trade Info
   FXtCurrentProfit        = 0;
   FXtCurrentShortProfit   = 0;
   FXtCurrentLongProfit    = 0;
   FXtTotalLots            = 0;
   FXtTotalLongLots        = 0;
   FXtTotalShortLots       = 0;
   FXtTotalTrades          = 0;
   FXtTotalShortTrades     = 0;
   FXtTotalLongTrades      = 0;
   FXtTotalPendingOrders   = 0;
   FXtTotalPips            = 0;
   FXtCurrentFinancing     = 0;
   FXtCurrentShortFinancing= 0;
   FXtCurrentLongFinancing = 0;
   FXtTotalUsedMargin      = 0;
   FXtTotalShortUsedMargin = 0;
   FXtTotalLongUsedMargin  = 0;

   // repopulate info
   for(int i=0;i<ArraySize(PairInfo);i++){
      
      int MT4TradeNum  = 0;
      
      // reset info
      PairInfo[i].MT4TradeCount              = 0;
      PairInfo[i].MT4ShortTradeCount         = 0;
      PairInfo[i].MT4LongTradeCount          = 0;
      PairInfo[i].MT4PendingOrderCount       = 0;
      PairInfo[i].MT4PendingLongOrderCount   = 0;
      PairInfo[i].MT4PendingShortOrderCount  = 0;
      PairInfo[i].MT4OpenLotsize             = 0;
      PairInfo[i].MT4ShortOpenLotsize        = 0;
      PairInfo[i].MT4LongOpenLotsize         = 0;
      PairInfo[i].MT4Profit                  = 0;
      PairInfo[i].MT4LongProfit              = 0;
      PairInfo[i].MT4ShortProfit             = 0;
      PairInfo[i].MT4ProfitPips              = 0;
      PairInfo[i].MT4ShortProfitPips         = 0;
      PairInfo[i].MT4LongProfitPips          = 0;
      
      for(int a=0; a<OrdersTotal(); a++){
         if((OrderSelect(a,SELECT_BY_POS) == true)&&((OrderMagicNumber() == MagicNumber)||(MagicNumber == 0))){
            if(OrderSymbol() == PairInfo[i].Pair){
               // Populate short data
               if (((TradeDirection == BothDirections)&&(OrderType() == OP_SELL))||
                   ((TradeDirection == OnlyShort)&&(OrderType() == OP_SELL))){
               //if(OrderType() == OP_SELL){
                  PairInfo[i].MT4ShortTradeCount++;
                  PairInfo[i].MT4ShortOpenLotsize += OrderLots();
                  PairInfo[i].MT4ShortProfit += OrderProfit();
                  PairInfo[i].MT4ShortProfitPips += (OrderOpenPrice() - MarketInfo(PairInfo[i].Pair,MODE_ASK)) / MarketInfo(PairInfo[i].Pair,MODE_POINT) / 10;
               }
               
               // Populate short pending
               if (CopyPendingTrades){
                  if (((TradeDirection == BothDirections)&&((OrderType() == OP_SELLLIMIT)||(OrderType() == OP_SELLSTOP)))||
                      ((TradeDirection == OnlyShort)&&((OrderType() == OP_SELLLIMIT)||(OrderType() == OP_SELLSTOP)))){
                     PairInfo[i].MT4PendingOrderCount++;
                     PairInfo[i].MT4PendingShortOrderCount++;
                  }
               }
               
               // Populate long data
               if (((TradeDirection == BothDirections)&&(OrderType() == OP_BUY))||
                   ((TradeDirection == OnlyLong)&&(OrderType() == OP_BUY))){
               //if(OrderType() == OP_BUY){
                  PairInfo[i].MT4LongTradeCount++;
                  PairInfo[i].MT4LongOpenLotsize += OrderLots();
                  PairInfo[i].MT4LongProfit += OrderProfit();
                  PairInfo[i].MT4LongProfitPips += (MarketInfo(PairInfo[i].Pair,MODE_BID) - OrderOpenPrice()) / MarketInfo(PairInfo[i].Pair,MODE_POINT) / 10;
               }
               
               // Populate long pending
               if (CopyPendingTrades){
                  if (((TradeDirection == BothDirections)&&((OrderType() == OP_BUYLIMIT)||(OrderType() == OP_BUYSTOP)))||
                      ((TradeDirection == OnlyLong)&&((OrderType() == OP_BUYLIMIT)||(OrderType() == OP_BUYSTOP)))){
                     PairInfo[i].MT4PendingOrderCount++;
                     PairInfo[i].MT4PendingLongOrderCount++;
                  }
               }
            }  
         }
      }
      // Populate data not dependant on side
      PairInfo[i].MT4TradeCount  = PairInfo[i].MT4ShortTradeCount + PairInfo[i].MT4LongTradeCount;
      PairInfo[i].MT4OpenLotsize = NormalizeDouble(PairInfo[i].MT4ShortOpenLotsize + PairInfo[i].MT4LongOpenLotsize,2);
      PairInfo[i].MT4Profit      = NormalizeDouble(PairInfo[i].MT4ShortProfit + PairInfo[i].MT4LongProfit,2);
      PairInfo[i].MT4ProfitPips  = NormalizeDouble(PairInfo[i].MT4ShortProfitPips + PairInfo[i].MT4LongProfitPips,1);
      // Normalize data
      PairInfo[i].MT4ShortOpenLotsize  = NormalizeDouble(PairInfo[i].MT4ShortOpenLotsize,2);
      PairInfo[i].MT4LongOpenLotsize   = NormalizeDouble(PairInfo[i].MT4LongOpenLotsize,2);
      PairInfo[i].MT4LongProfit        = NormalizeDouble(PairInfo[i].MT4LongProfit,2);
      PairInfo[i].MT4ShortProfit       = NormalizeDouble(PairInfo[i].MT4ShortProfit,2);
      PairInfo[i].MT4ShortProfitPips   = NormalizeDouble(PairInfo[i].MT4ShortProfitPips,1);
      PairInfo[i].MT4LongProfitPips    = NormalizeDouble(PairInfo[i].MT4LongProfitPips,1);
      
      // Total profit
      MT4CurrentProfit += (PairInfo[i].MT4ShortProfit + PairInfo[i].MT4LongProfit);
      MT4CurrentShortProfit += PairInfo[i].MT4ShortProfit;
      MT4CurrentLongProfit += PairInfo[i].MT4LongProfit;
      
      MT4TotalLots += PairInfo[i].MT4OpenLotsize;
      MT4TotalShortLots += PairInfo[i].MT4ShortOpenLotsize;
      MT4TotalLongLots += PairInfo[i].MT4LongOpenLotsize;
      
      MT4TotalTrades += PairInfo[i].MT4TradeCount;
      MT4TotalShortTrades += PairInfo[i].MT4ShortTradeCount;
      MT4TotalLongTrades += PairInfo[i].MT4LongTradeCount;
      
      MT4TotalOrders += PairInfo[i].MT4PendingOrderCount;
      
      MT4TotalPips += PairInfo[i].MT4ProfitPips;

      // FXt Total calcs
      double financing = 0;
      double longFinancing = 0;
      double shortFinancing = 0;
      double margin = 0;
      double longMargin = 0;
      double shortMargin = 0;
      
      // Calculate total financing and margin
      for (int a = 0; a < ArraySize(FXtID); a++){
         if (FXtPair[a] == PairInfo[i].Pair){
            financing += FXtFinancing[a];
            if (FXtDirection[a] == "short"){
               margin += FXtMargin[a];
               shortMargin += FXtMargin[a];
               shortFinancing += FXtFinancing[a];
            }
            if (FXtDirection[a] == "long"){
               margin += FXtMargin[a];
               longMargin += FXtMargin[a];
               longFinancing  += FXtFinancing[a];
            }
         }
      }
      PairInfo[i].FXtFinancing = financing;
      FXtCurrentFinancing     += financing;
      FXtCurrentShortFinancing+= shortFinancing;
      FXtCurrentLongFinancing += longFinancing;
      
      PairInfo[i].FXtUsedMargin = margin;
      FXtTotalUsedMargin       += margin;
      FXtTotalShortUsedMargin  += shortMargin;
      FXtTotalLongUsedMargin   += longMargin;
      
      FXtCurrentProfit        += (PairInfo[i].FXtShortProfit + PairInfo[i].FXtLongProfit);
      FXtCurrentShortProfit   += PairInfo[i].FXtShortProfit;
      FXtCurrentLongProfit    += PairInfo[i].FXtLongProfit;
      
      FXtTotalLots            += PairInfo[i].FXtOpenLotsize;
      FXtTotalShortLots       += PairInfo[i].FXtShortOpenLotsize;
      FXtTotalLongLots        += PairInfo[i].FXtLongOpenLotsize;
      
      FXtTotalTrades          += (PairInfo[i].FXtLongTradeCount + PairInfo[i].FXtShortTradeCount);
      FXtTotalShortTrades     += PairInfo[i].FXtShortTradeCount;
      FXtTotalLongTrades      += PairInfo[i].FXtLongTradeCount;
      
      FXtTotalPips            += PairInfo[i].FXtProfitPips;
      
      // Set position pips
      PairInfo[i].FXtProfitPips = PairInfo[i].FXtLongProfitPips + PairInfo[i].FXtShortProfitPips;
      // Set position profit
      PairInfo[i].FXtProfit     = NormalizeDouble(PairInfo[i].FXtShortProfit + PairInfo[i].FXtLongProfit,2);
      
      // Resize MT4TradeID array
      ArrayResize(PairInfo[i].MT4TradeID,PairInfo[i].MT4TradeCount+PairInfo[i].MT4PendingOrderCount);
      ArrayResize(PairInfo[i].FXtTradeID,PairInfo[i].MT4TradeCount+PairInfo[i].MT4PendingOrderCount);
      
      // Array Trade nums to MT4TradeID and matching FXt trade to FXtTradeID
      int counter = 0;
      for (int a = 0; a < ArraySize(MT4ID); a++){
         if (MT4Pair[a] == PairInfo[i].Pair){
            int match = -1;
            PairInfo[i].MT4TradeID[counter] = a;
            for (int c = 0; c < ArraySize(FXtID); c++){ // found a match. find matching FXt trade if not found assign to 0
               if (MT4ID[a] == FXtToMT4ID[c]){
                  match = c;
               }
            }
            PairInfo[i].FXtTradeID[counter] = match;
            counter++;
         }
      }

      PairInfo[i].FXtProfitPips              = 0;
      PairInfo[i].FXtPendingOrderCount       = 0;
      PairInfo[i].FXtPendingLongOrderCount   = 0;
      PairInfo[i].FXtPendingShortOrderCount  = 0;
      // update profit pips and pending count for FXt
      for (int a = 0; a < ArraySize(PairInfo[i].FXtTradeID); a++){
         int b = PairInfo[i].FXtTradeID[a];
         if (b >= 0){
            if (FXtDirection[b] == "short"){
               PairInfo[i].FXtProfitPips += NormalizeDouble((FXtPrice[b] - MarketInfo(FXtPair[b],MODE_ASK))/MarketInfo(FXtPair[b],MODE_POINT)/10,1);
            } else if (FXtDirection[b] == "long"){ 
               PairInfo[i].FXtProfitPips += NormalizeDouble((MarketInfo(FXtPair[b],MODE_BID) - FXtPrice[b])/MarketInfo(FXtPair[b],MODE_POINT)/10,1);
            } else if ((FXtDirection[b] == "sellStop")||(FXtDirection[b] == "sellLimit")){
               PairInfo[i].FXtPendingShortOrderCount++;
               PairInfo[i].FXtPendingOrderCount++;
            } else {
               PairInfo[i].FXtPendingLongOrderCount++;
               PairInfo[i].FXtPendingOrderCount++;
            }
         }
      }
   }
}

//================================================//
// Calculate Used Margin                          //
//================================================//
double GetUsedMargin(string pair, int units){
   double leverage, conversion;
   string basePair;
   int usBased;
   
   // get leverage
   double pairLeverage = NormalizeDouble(100 / GetPairMarginRequired(pair),1);
   if (pairLeverage < AccountLeverage) leverage = (100 / pairLeverage) * 0.01;
   else leverage = (100 / AccountLeverage) * 0.01;
   
   // get basepair
   string base =     StringSubstr(pair,0,3);
   string counter =  StringSubstr(pair,3,3);
   
   if (base == "USD"){
      basePair = pair;
      usBased = 0;
   } else if (PairToInt("USD"+base) >= 0){
      basePair = "USD"+base;
      usBased = 1;
   } else if (PairToInt(base+"USD") >= 0){
      basePair = base+"USD";
      usBased = 2;
   } else return 0; // error
   
   // get values
   double ask = MarketInfo(basePair, MODE_ASK);
   double bid = MarketInfo(basePair, MODE_BID);
   int digits = int(MarketInfo(basePair, MODE_DIGITS));
   double midPrice = bid + ((ask - bid) / 2);
   
   // if midPrice ==  0 then symbol likely not loaded.  Load it and try again on next iteration
   if (midPrice == 0){
      SymbolSelect(basePair, true);
      return 0;
   }
   
   // get midPrice
   if (usBased == 0) conversion = 1;
   else if (usBased == 1)conversion = NormalizeDouble(midPrice,digits);
   else conversion = NormalizeDouble(1/midPrice,digits);
   
   return NormalizeDouble(units * leverage * conversion, 4);
}

/*
Margin Used Calculation Example:

You have a USD account with maximum leverage set to 20:1 and a long 10,000 EUR/GBP open position. The current rate for EUR/USD is 1.1320/1.1321, therefore the current midpoint rate of EUR/USD is 1.13205.
For the leverage calculation, the lower of the maximum regulated leverage and your selected leverage is used. The regulator allows 50:1 leverage on EUR/GBP, but because you have selected a 20:1 leverage for your account, a leverage of 20:1 (or 5% margin requirement) is used.
Your margin used is position size x Margin Requirement = 10,000 EUR x 5% = 500 EUR. The Margin Used in your account currency = 500 x 1.13205 = 566.025 USD.
*/
//================================================//
// Populate MT4 Trade Data                        //
//================================================//
// Assigning MT4 trades to an array, rather than performing operations on each iteration, so trades are only looped over once from MT4.
// Need to loop once for MT4 to FXt and again for FXt to MT4.
void UpdateMT4Trades(){
   int count = 0;
   
   // resize the arrays. Added to the ordersTotal in the offchance that an order is triggered between resetting the arrays and the order loop.
   ArrayResize(MT4ID, OrdersTotal()+5);
   ArrayResize(MT4Pair, OrdersTotal()+5);
   ArrayResize(MT4Direction, OrdersTotal()+5);
   ArrayResize(MT4Time, OrdersTotal()+5);
   ArrayResize(MT4Lots, OrdersTotal()+5);
   ArrayResize(MT4Price, OrdersTotal()+5);
   ArrayResize(MT4PrevPrice, OrdersTotal()+5);
   ArrayResize(MT4Profit, OrdersTotal()+5);
   
   // loop through open orders
   for(int i=0; i<OrdersTotal(); i++){
      if((OrderSelect(i,SELECT_BY_POS) == true)&&((OrderMagicNumber() == MagicNumber)||(MagicNumber == 0))){
         if ((TradeDirection == BothDirections)||
             ((TradeDirection == OnlyLong)&&((OrderType() == OP_BUY)||(OrderType() == OP_BUYLIMIT)||(OrderType() == OP_BUYSTOP)))||
             ((TradeDirection == OnlyShort)&&((OrderType() == OP_SELL)||(OrderType() == OP_SELLLIMIT)||(OrderType() == OP_SELLSTOP)))){
            // Populate open orders
            if (OrderType() == OP_BUY || OrderType() == OP_SELL){
               MT4ID[count] = OrderTicket();
               MT4Pair[count] = OrderSymbol();
               if (OrderType() == OP_BUY) MT4Direction[count] = "long";
                  else MT4Direction[count] = "short";
               MT4Time[count] = OrderOpenTime();
               MT4Lots[count] = OrderLots();
               MT4Price[count] = OrderOpenPrice();
               MT4Profit[count] = OrderProfit();
               count++;
            // Populate pending orders
            } else {
               if (CopyPendingTrades){
                  MT4PrevPrice[count] = MT4Price[count];
                  MT4ID[count] = OrderTicket();
                  MT4Pair[count] = OrderSymbol();
                  if (OrderType() == OP_BUYLIMIT)        MT4Direction[count] = "buyLimit";
                  else if (OrderType() == OP_BUYSTOP)    MT4Direction[count] = "buyStop";
                  else if (OrderType() == OP_SELLLIMIT)  MT4Direction[count] = "sellLimit";
                  else                                   MT4Direction[count] = "sellStop";
                  MT4Time[count] = OrderOpenTime();
                  MT4Lots[count] = OrderLots();
                  MT4Price[count] = OrderOpenPrice();
                  MT4Profit[count] = EMPTY_VALUE;
                  count++;
               }
            }
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
   ArrayResize(MT4Profit, count);
   
}

//================================================//
// Populate FXtrade Array                         //
//================================================//
// -- Read data from FXtrade's trade file and populate FXt arrays
void UpdateFXtTrades(){
   int handle;
   string filename = "Ditto\\"+FolderName+"\\FXtTrades.txt";
   string trades[];
   int numTrades;
   
   if (FileIsExist(LockFilename) != true){ // Wait for python to finish
      if (FileIsExist(MT4LockFilename) != true){ // If MT4 lock file exists wait. (just in case)
         LockDirectory(); // we don't want python to change our file
      
         // read file
         if (FileIsExist(filename)){
            FXtUpdated = true;
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
         ArrayResize(FXtProfit, numTrades);
         ArrayResize(FXtFinancing, numTrades);
         ArrayResize(FXtMargin, numTrades);
         
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
            FXtLots[i] =      MathAbs(int(StringToInteger(result[5])));
            FXtPrice[i] =     StringToDouble(result[6]);
            FXtFinancing[i] = StringToDouble(result[7]);
            FXtMargin[i] =    GetUsedMargin(FXtPair[i],FXtLots[i]);
            
            // calculate FXtProfit
            if (FXtDirection[i] == "long"){
               if (StringFind(FXtPair[i],"JPY") >= 0) FXtProfit[i] = MarketInfo(FXtPair[i], MODE_TICKVALUE) * FXtLots[i] * (MarketInfo(FXtPair[i],MODE_BID) - FXtPrice[i])/100;
                  else FXtProfit[i] = MarketInfo(FXtPair[i], MODE_TICKVALUE) * FXtLots[i] * (MarketInfo(FXtPair[i],MODE_BID) - FXtPrice[i]);
            }
            if (FXtDirection[i] == "short"){
               if (StringFind(FXtPair[i],"JPY") >= 0) FXtProfit[i] = MarketInfo(FXtPair[i], MODE_TICKVALUE) * FXtLots[i] * (FXtPrice[i] - MarketInfo(FXtPair[i],MODE_ASK))/100;
                  else FXtProfit[i] = MarketInfo(FXtPair[i], MODE_TICKVALUE) * FXtLots[i] * (FXtPrice[i] - MarketInfo(FXtPair[i],MODE_ASK));
            }
          
         }
         
         UnlockDirectory();
      }
   }
}
/*
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
   string filename = "Ditto\\"+FolderName+"\\data-"+pair+".txt";

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
   string filename = "Ditto\\"+FolderName+"\\data-"+pair+".txt";
   
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
*/
//================================================//
// FXtrade Bridge Functions                       //
//================================================//
// create order file (side = "long" or "short")
bool OpenFXtOrder(string instrument, string side, int units, int mt4TradeID = 0){
   int fileHandle;
   bool success = false;
   string pair = instrument;
   StringReplace(pair,"_","");
   string command = "openMarket-"+instrument+"-"+side+"-"+IntegerToString(units)+"-"+IntegerToString(mt4TradeID);

   if (FileIsExist(LockFilename) != true){ // Wait for python to finish
      LockDirectory();
      fileHandle = FileOpen("Ditto\\"+FolderName+"\\"+command,FILE_WRITE|FILE_TXT);
      if(fileHandle!=INVALID_HANDLE){
         FileClose(fileHandle);
         success = true;
      }
      UnlockDirectory();
      Sleep(1000);
   }
   
   return success;
}

// create pending order
bool OpenFXtPending(string instrument, string side, string type, double price, int units, int mt4TradeID){
   int fileHandle;
   bool success = false;
   string pair = instrument;
   StringReplace(pair,"_","");
   string pendingType;
   
   if (type == "stop"){
      if (side == "sell") pendingType = "openPending-sell-stop";
      if (side == "buy")  pendingType = "openPending-buy-stop";
   } else if (type == "limit"){
      if (side == "sell") pendingType = "openPending-sell-limit";
      if (side == "buy")  pendingType = "openPending-buy-limit";
   } else return false;
   
   string command = pendingType+"-"+instrument+"-"+IntegerToString(units)+"-"+DoubleToStr(price, int(MarketInfo(pair,MODE_DIGITS)))+"-"+IntegerToString(mt4TradeID);
   
   // remove dot from command. replace with underscore
   StringReplace(command,".","_");
   
   if (FileIsExist(LockFilename) != true){ // Wait for python to finish
      LockDirectory();
      fileHandle = FileOpen("Ditto\\"+FolderName+"\\"+command,FILE_WRITE|FILE_TXT);
      if(fileHandle!=INVALID_HANDLE){
         FileClose(fileHandle);
         success = true;
      }
      UnlockDirectory();
      Sleep(1000);
   }
   return success;
}
// create close pending file
bool CloseFXtPending(string instrument, string side, string type, int units, int tradeID, int mt4TradeID){
   int fileHandle;
   bool success = false;
   string pair = instrument;
   StringReplace(pair,"_","");
   string pendingType;
   
   if (type == "stop"){
      if (side == "sell") pendingType = "cancelPending-sell-stop";
      if (side == "buy")  pendingType = "cancelPending-buy-stop";
   } else if (type == "limit"){
      if (side == "sell") pendingType = "cancelPending-sell-limit";
      if (side == "buy")  pendingType = "cancelPending-buy-limit";
   } else return false;
   
   string command = pendingType+"-"+instrument+"-"+IntegerToString(units)+"-"+IntegerToString(tradeID)+"-"+IntegerToString(mt4TradeID);
   
   if (FileIsExist(LockFilename) != true){ // Wait for python to finish
      LockDirectory();
      fileHandle = FileOpen("Ditto\\"+FolderName+"\\"+command,FILE_WRITE|FILE_TXT);
      if(fileHandle!=INVALID_HANDLE){
         FileClose(fileHandle);
         success = true;
      }
      UnlockDirectory();
      Sleep(1000);
   }
   return success;
}

// create close trade file (side = "long" or "short")
bool CloseFXtTrade(int tradeID, string side, int units=0){
   int fileHandle;
   bool success = false;
   
   if (FileIsExist(LockFilename) != true){ // Wait for python to finish
      LockDirectory();
      fileHandle=FileOpen("Ditto\\"+FolderName+"\\closeTrade-"+IntegerToString(tradeID)+"-"+side+"-"+IntegerToString(units),FILE_WRITE|FILE_TXT);
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
      fileHandle=FileOpen("Ditto\\"+FolderName+"\\closePosition-"+instrument+"-"+side+"-"+IntegerToString(units),FILE_WRITE|FILE_TXT);
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
      fileHandle=FileOpen("Ditto\\"+FolderName+"\\updateTradeData",FILE_WRITE|FILE_TXT);
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
   fuFilehandle=FileOpen("Ditto\\"+FolderName+"\\MT4-Locked",FILE_WRITE|FILE_TXT);
   if(fuFilehandle!=INVALID_HANDLE){
      FileClose(fuFilehandle);
      return true;
   } else return false;
}

// unlock directory so python can access files
bool UnlockDirectory(){
   int fuFilehandle;
   fuFilehandle=FileDelete("Ditto\\"+FolderName+"\\MT4-Locked");
   if (fuFilehandle == false) return false;
      else return true;
}

//================================================//
// Clean Chart on First Open                      //
//================================================//
void CleanChart(){
   // remove any old comments
   Comment("");
   
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

//================================================//
// Update Dashboard                               //
//================================================//
void UpdateDash(){
   UpdateHeader();
   UpdateRows();
   UpdateFooter();
}
// -- Display data in the dashboard header
void UpdateHeader(){

   // update status
   string side = "Long and Short";
   if (TradeDirection == 1) side = "Short";
   if (TradeDirection == 2) side = "Long";
   
   string magic = "#"+IntegerToString(MagicNumber);
   if (MagicNumber == 0) magic = "All Activity";
   
   if (ErrorMessage != ""){
      ObjectSetText("StatusMessage",ErrorMessage,HeaderTextSize,NULL,clrOrangeRed);
      ObjectSetString(0,"StatusMessage",OBJPROP_TOOLTIP,ErrorMessage);
   } else {
      ObjectSetText("StatusMessage","Status: OK: Monitoring "+side+" Trades for "+magic,HeaderTextSize,NULL,clrDarkGreen);
      ObjectSetString(0,"StatusMessage",OBJPROP_TOOLTIP,"Status: OK: Monitoring "+side+" Trades for "+magic);
   }
   
   // display system name
   ObjectSetText("SystemName","System Name: "+SystemName,HeaderTextSize,NULL,clrGray);
   ObjectSetString(0,"SystemName",OBJPROP_TOOLTIP,SystemName);
   
   // update clock
   ObjectSetText("SystemClock",TimeToStr(TimeLocal(),TIME_MINUTES|TIME_SECONDS),HeaderTextSize,NULL,clrGray);
   
   ObjectSetText("AccountBalance","Account Balance: $"+DoubleToStr(AccountBal,2),HeaderTextSize,NULL,C'136,136,136');
   ObjectSetString(0,"AccountBalance",OBJPROP_TOOLTIP,"$"+DoubleToStr(AccountBal,2));
   if (DualAccounts){
      ObjectSetText("ShortAccountBalance","Short Balance: $"+DoubleToStr(ShortAccountBal,2),HeaderTextSize-1,NULL,C'114,114,114');
      ObjectSetString(0,"ShortAccountBalance",OBJPROP_TOOLTIP,"$"+DoubleToStr(ShortAccountBal,2));
      ObjectSetText("LongAccountBalance","Long Balance: $"+DoubleToStr(LongAccountBal,2),HeaderTextSize-1,NULL,C'114,114,114');
      ObjectSetString(0,"LongAccountBalance",OBJPROP_TOOLTIP,"$"+DoubleToStr(LongAccountBal,2));
   }
   
   if (IncludeSwapInPL){
      ObjectSetText("AccountEquity","Account Equity: $"+DoubleToStr(AccountBal + FXtCurrentProfit + FXtCurrentFinancing,2),HeaderTextSize,NULL,C'136,136,136');
      ObjectSetString(0,"AccountEquity",OBJPROP_TOOLTIP,"$"+DoubleToStr(AccountBal + FXtCurrentProfit + FXtCurrentFinancing,2));
   } else {
      ObjectSetText("AccountEquity","Account Equity: $"+DoubleToStr(AccountBal+FXtCurrentProfit,2),HeaderTextSize,NULL,C'136,136,136');
      ObjectSetString(0,"AccountEquity",OBJPROP_TOOLTIP,"$"+DoubleToStr(AccountBal+FXtCurrentProfit,2));
   }
   
   if (DualAccounts){
      if (IncludeSwapInPL){
         ObjectSetText("ShortAccountEquity","Short Equity: $"+DoubleToStr(ShortAccountBal+FXtCurrentShortProfit + FXtCurrentShortFinancing,2),HeaderTextSize-1,NULL,C'114,114,114');
         ObjectSetString(0,"ShortAccountEquity",OBJPROP_TOOLTIP,"$"+DoubleToStr(ShortAccountBal+FXtCurrentShortProfit + FXtCurrentShortFinancing,2));
      } else {
         ObjectSetText("ShortAccountEquity","Short Equity: $"+DoubleToStr(ShortAccountBal+FXtCurrentShortProfit,2),HeaderTextSize-1,NULL,C'114,114,114');
         ObjectSetString(0,"ShortAccountEquity",OBJPROP_TOOLTIP,"$"+DoubleToStr(ShortAccountBal+FXtCurrentShortProfit,2));
      }
      if (IncludeSwapInPL){
         ObjectSetText("LongAccountEquity","Long Equity: $"+DoubleToStr(LongAccountBal+FXtCurrentLongProfit+FXtCurrentLongFinancing,2),HeaderTextSize-1,NULL,C'114,114,114');
         ObjectSetString(0,"LongAccountEquity",OBJPROP_TOOLTIP,"$"+DoubleToStr(LongAccountBal+FXtCurrentLongProfit+FXtCurrentLongFinancing,2));
      } else {
         ObjectSetText("LongAccountEquity","Long Equity: $"+DoubleToStr(LongAccountBal+FXtCurrentLongProfit,2),HeaderTextSize-1,NULL,C'114,114,114');
         ObjectSetString(0,"LongAccountEquity",OBJPROP_TOOLTIP,"$"+DoubleToStr(LongAccountBal+FXtCurrentLongProfit,2));
      }
   }
   
   if (MarginLevel > 0){
      ObjectSetText("AccountMargin","Margin Used / Avail: $"+DoubleToStr(FXtTotalUsedMargin,2)+" / $"+DoubleToStr(AcctEquity - FXtTotalUsedMargin,2)+" ("+DoubleToStr(MarginLevel,2)+"%)",HeaderTextSize,NULL,C'136,136,136');
      ObjectSetString(0,"AccountMargin",OBJPROP_TOOLTIP,"$"+DoubleToStr(FXtTotalUsedMargin,2)+" / $"+DoubleToStr(AcctEquity - FXtTotalUsedMargin,2)+" ("+DoubleToStr(MarginLevel,2)+"%)");
   } else {
      ObjectSetText("AccountMargin","Margin Used / Avail: $"+DoubleToStr(FXtTotalUsedMargin,2)+" / $"+DoubleToStr(AcctEquity - FXtTotalUsedMargin,2),HeaderTextSize,NULL,C'136,136,136');
      ObjectSetString(0,"AccountMargin",OBJPROP_TOOLTIP,"$"+DoubleToStr(FXtTotalUsedMargin,2)+" / $"+DoubleToStr(AcctEquity - FXtTotalUsedMargin,2));
   }
   
   if (DualAccounts){
      if (ShortMarginLevel > 0){
         ObjectSetText("ShortAccountMargin","Short Margin: $"+DoubleToStr(FXtTotalShortUsedMargin,2)+" / $"+DoubleToStr(ShortAccountEquity - FXtTotalShortUsedMargin,2)+"  ("+DoubleToStr(ShortMarginLevel,2)+"%)",HeaderTextSize-1,NULL,C'114,114,114');
         ObjectSetString(0,"ShortAccountMargin",OBJPROP_TOOLTIP,"$"+DoubleToStr(FXtTotalShortUsedMargin,2)+" / $"+DoubleToStr(ShortAccountEquity - FXtTotalShortUsedMargin,2)+"  ("+DoubleToStr(ShortMarginLevel,2)+"%)");
      } else {
         ObjectSetText("ShortAccountMargin","Short Margin: $"+DoubleToStr(FXtTotalShortUsedMargin,2)+" / $"+DoubleToStr(ShortAccountEquity - FXtTotalShortUsedMargin,2),HeaderTextSize-1,NULL,C'114,114,114');
         ObjectSetString(0,"ShortAccountMargin",OBJPROP_TOOLTIP,"$"+DoubleToStr(FXtTotalShortUsedMargin,2)+" / $"+DoubleToStr(ShortAccountEquity - FXtTotalShortUsedMargin,2));
      }
      if (LongMarginLevel > 0){
         ObjectSetText("LongAccountMargin","Long Margin: $"+DoubleToStr(FXtTotalLongUsedMargin,2)+" / $"+DoubleToStr(LongAccountEquity - FXtTotalLongUsedMargin,2)+"  ("+DoubleToStr(LongMarginLevel,2)+"%)",HeaderTextSize-1,NULL,C'114,114,114');
         ObjectSetString(0,"LongAccountMargin",OBJPROP_TOOLTIP,"$"+DoubleToStr(FXtTotalLongUsedMargin,2)+" / $"+DoubleToStr(LongAccountEquity - FXtTotalLongUsedMargin,2)+"  ("+DoubleToStr(LongMarginLevel,2)+"%)");
      } else {
         ObjectSetText("LongAccountMargin","Long Margin: $"+DoubleToStr(FXtTotalLongUsedMargin,2)+" / $"+DoubleToStr(LongAccountEquity - FXtTotalLongUsedMargin,2),HeaderTextSize-1,NULL,C'114,114,114');
         ObjectSetString(0,"LongAccountMargin",OBJPROP_TOOLTIP,"$"+DoubleToStr(FXtTotalLongUsedMargin,2)+" / $"+DoubleToStr(LongAccountEquity - FXtTotalLongUsedMargin,2));
      }
   }
    
   ObjectSetText("AccountRealPL","Realized P/L: $"+DoubleToStr((NormalizeDouble(RealizedPL + ShortPandLOffset,2) + NormalizeDouble(LongRealizedPL + LongPandLOffset,2)),2),HeaderTextSize,NULL,C'136,136,136');
   ObjectSetString(0,"AccountRealPL",OBJPROP_TOOLTIP,"$"+DoubleToStr((NormalizeDouble(RealizedPL + ShortPandLOffset,2) + NormalizeDouble(LongRealizedPL + LongPandLOffset,2)),2));
   
   if (DualAccounts){
      ObjectSetText("ShortAccountRealPL","Short P/L: $"+DoubleToStr((NormalizeDouble(ShortRealizedPL + ShortPandLOffset,2)),2),HeaderTextSize-1,NULL,C'114,114,114');
      ObjectSetString(0,"AccountRealPL",OBJPROP_TOOLTIP,"$"+DoubleToStr((NormalizeDouble(ShortRealizedPL + ShortPandLOffset,2)),2));
      ObjectSetText("LongAccountRealPL","Long P/L: $"+DoubleToStr((NormalizeDouble(LongRealizedPL + LongPandLOffset,2)),2),HeaderTextSize-1,NULL,C'114,114,114');
      ObjectSetString(0,"AccountRealPL",OBJPROP_TOOLTIP,"$"+DoubleToStr((NormalizeDouble(LongRealizedPL + LongPandLOffset,2)),2));
   }

   if (MT4TotalTrades > 0){
      if (MT4CurrentProfit < 0) {
         ObjectSetText("MT4PandLText",DoubleToString(MathAbs(MT4CurrentProfit),2),DashTextSize,NULL,clrOrangeRed);
         ObjectSetString(0,"MT4PandLText",OBJPROP_TOOLTIP,"$"+DoubleToString(MT4CurrentProfit,2));
      } else {
         ObjectSetText("MT4PandLText",DoubleToString(MathAbs(MT4CurrentProfit),2),DashTextSize,NULL,C'147,255,38');
         ObjectSetString(0,"MT4PandLText",OBJPROP_TOOLTIP,"$"+DoubleToString(MT4CurrentProfit,2));
      }
   } else {
      ObjectSetText("MT4PandLText","000.00",DashTextSize,NULL,C'68,68,68');
      ObjectSetString(0,"MT4PandLText",OBJPROP_TOOLTIP,"$0.00");
   }
   
   if (FXtTotalTrades > 0){
      if (IncludeSwapInPL){
         if ((FXtCurrentProfit + FXtCurrentFinancing) < 0) ObjectSetText("FXtPandLText",DoubleToString(MathAbs(FXtCurrentProfit + FXtCurrentFinancing),2),DashTextSize,NULL,clrOrangeRed);
            else ObjectSetText("FXtPandLText",DoubleToString(MathAbs(FXtCurrentProfit + FXtCurrentFinancing),2),DashTextSize,NULL,C'147,255,38');
         ObjectSetString(0,"FXtPandLText",OBJPROP_TOOLTIP,"$"+DoubleToString(FXtCurrentProfit + FXtCurrentFinancing,2));
      } else {
         if (FXtCurrentProfit < 0) ObjectSetText("FXtPandLText",DoubleToString(MathAbs(FXtCurrentProfit),2),DashTextSize,NULL,clrOrangeRed);
            else ObjectSetText("FXtPandLText",DoubleToString(MathAbs(FXtCurrentProfit),2),DashTextSize,NULL,C'147,255,38');
         ObjectSetString(0,"FXtPandLText",OBJPROP_TOOLTIP,"$"+DoubleToString(FXtCurrentProfit,2));
      }
   } else {
      ObjectSetText("FXtPandLText","000.00",DashTextSize,NULL,C'68,68,68');
      ObjectSetString(0,"FXtPandLText",OBJPROP_TOOLTIP,"$0.00");
   }
}
// -- Update each row in the dashboard
void UpdateRows(){
   
   // Update data for each row.
   for(int i=0; i<ArraySize(PairInfo); i++){
      
      // MT4 Lot size
      if (PairInfo[i].MT4LongOpenLotsize > 0){
         ObjectSetText("Row_MT4_LongLots_"+IntegerToString(i),FormatMT4Lots(PairInfo[i].MT4LongOpenLotsize),DashTextSize,NULL,clrBlanchedAlmond);
         ObjectSetString(0,"Row_MT4_LongLots_"+IntegerToString(i),OBJPROP_TOOLTIP,FormatMT4LotsTooltip(PairInfo[i].MT4LongOpenLotsize));
      } else {
         ObjectSetText("Row_MT4_LongLots_"+IntegerToString(i),FormatMT4Lots(PairInfo[i].MT4LongOpenLotsize),DashTextSize,NULL,C'68,68,68');
         ObjectSetString(0,"Row_MT4_LongLots_"+IntegerToString(i),OBJPROP_TOOLTIP,"0");
      }
      if (PairInfo[i].MT4ShortOpenLotsize > 0){
         ObjectSetText("Row_MT4_ShortLots_"+IntegerToString(i),FormatMT4Lots(PairInfo[i].MT4ShortOpenLotsize),DashTextSize,NULL,clrBlanchedAlmond);
         ObjectSetString(0,"Row_MT4_ShortLots_"+IntegerToString(i),OBJPROP_TOOLTIP,FormatMT4LotsTooltip(PairInfo[i].MT4ShortOpenLotsize));
      } else {
         ObjectSetText("Row_MT4_ShortLots_"+IntegerToString(i),FormatMT4Lots(PairInfo[i].MT4ShortOpenLotsize),DashTextSize,NULL,C'68,68,68');
         ObjectSetString(0,"Row_MT4_ShortLots_"+IntegerToString(i),OBJPROP_TOOLTIP,"0");
      }
      
      // MT4 Trade count
      if (PairInfo[i].MT4LongTradeCount > 0){
         ObjectSetText("Row_MT4_OrdersBuy_"+IntegerToString(i),IntegerToString(PairInfo[i].MT4LongTradeCount),DashTextSize,NULL,clrBlanchedAlmond);
         ObjectSetString(0,"Row_MT4_OrdersBuy_"+IntegerToString(i),OBJPROP_TOOLTIP,"Long MT4 trades: "+IntegerToString(PairInfo[i].MT4LongTradeCount));
      } else {
         ObjectSetText("Row_MT4_OrdersBuy_"+IntegerToString(i),"0",DashTextSize,NULL,C'68,68,68');
         ObjectSetString(0,"Row_MT4_OrdersBuy_"+IntegerToString(i),OBJPROP_TOOLTIP,"Long MT4 trades: 0");
      }
      if (PairInfo[i].MT4ShortTradeCount > 0){
         ObjectSetText("Row_MT4_OrdersSell_"+IntegerToString(i),IntegerToString(PairInfo[i].MT4ShortTradeCount),DashTextSize,NULL,clrBlanchedAlmond);
         ObjectSetString(0,"Row_MT4_OrdersSell_"+IntegerToString(i),OBJPROP_TOOLTIP,"Short MT4 trades: "+IntegerToString(PairInfo[i].MT4ShortTradeCount));
      } else {
         ObjectSetText("Row_MT4_OrdersSell_"+IntegerToString(i),"0",DashTextSize,NULL,C'68,68,68');
         ObjectSetString(0,"Row_MT4_OrdersSell_"+IntegerToString(i),OBJPROP_TOOLTIP,"Short MT4 trades: 0");
      }
      
      if (PairInfo[i].MT4PendingOrderCount > 0){
         ObjectSetText("Row_MT4_Pending_"+IntegerToString(i),IntegerToString(PairInfo[i].MT4PendingOrderCount),DashTextSize,NULL,clrSteelBlue);
         ObjectSetString(0,"Row_MT4_Pending_"+IntegerToString(i),OBJPROP_TOOLTIP,"Pending Orders: "+IntegerToString(PairInfo[i].MT4PendingOrderCount));
      } else {
         ObjectSetText("Row_MT4_Pending_"+IntegerToString(i),"",DashTextSize,NULL,clrNONE);
         ObjectSetString(0,"Row_MT4_Pending_"+IntegerToString(i),OBJPROP_TOOLTIP,"...");
      }
      
      // MT4 Profit/Loss
      if (PairInfo[i].MT4LongTradeCount > 0){
         if (PairInfo[i].MT4LongProfit < 0) ObjectSetText("Row_MT4_BuyPrice_"+IntegerToString(i),DoubleToString(MathAbs(PairInfo[i].MT4LongProfit),2),DashTextSize,NULL,clrOrangeRed);
            else ObjectSetText("Row_MT4_BuyPrice_"+IntegerToString(i),DoubleToString(PairInfo[i].MT4LongProfit,2),DashTextSize,NULL,C'147,255,38');
         ObjectSetString(0,"Row_MT4_BuyPrice_"+IntegerToString(i),OBJPROP_TOOLTIP,"Long MT4 P/L: $"+DoubleToString(PairInfo[i].MT4LongProfit,2));
      } else {
         ObjectSetText("Row_MT4_BuyPrice_"+IntegerToString(i),"0.00",DashTextSize,NULL,C'68,68,68');
         ObjectSetString(0,"Row_MT4_BuyPrice_"+IntegerToString(i),OBJPROP_TOOLTIP,"---");
      }
      
      if (PairInfo[i].MT4ShortTradeCount > 0){
         if (PairInfo[i].MT4ShortProfit < 0) ObjectSetText("Row_MT4_SellPrice_"+IntegerToString(i),DoubleToString(MathAbs(PairInfo[i].MT4ShortProfit),2),DashTextSize,NULL,clrOrangeRed);
            else ObjectSetText("Row_MT4_SellPrice_"+IntegerToString(i),DoubleToString(PairInfo[i].MT4ShortProfit,2),DashTextSize,NULL,C'147,255,38');
         ObjectSetString(0,"Row_MT4_SellPrice_"+IntegerToString(i),OBJPROP_TOOLTIP,"Short MT4 P/L: $"+DoubleToString(PairInfo[i].MT4ShortProfit,2));
      } else {
         ObjectSetText("Row_MT4_SellPrice_"+IntegerToString(i),"0.00",DashTextSize,NULL,C'68,68,68');
         ObjectSetString(0,"Row_MT4_SellPrice_"+IntegerToString(i),OBJPROP_TOOLTIP,"---");
      }
      
      // MT4 Combined Profit/Loss
      if (PairInfo[i].MT4TradeCount > 0){
         if (PairInfo[i].MT4Profit < 0) ObjectSetText("Row_MT4_ProfitLoss_"+IntegerToString(i),DoubleToString(MathAbs(PairInfo[i].MT4Profit),2),DashTextSize,NULL,clrOrangeRed);
            else ObjectSetText("Row_MT4_ProfitLoss_"+IntegerToString(i),DoubleToString(PairInfo[i].MT4Profit,2),DashTextSize,NULL,C'147,255,38');
         ObjectSetString(0,"Row_MT4_ProfitLoss_"+IntegerToString(i),OBJPROP_TOOLTIP,"MT4 P/L: $"+DoubleToString(PairInfo[i].MT4Profit,2));
      } else {
         ObjectSetText("Row_MT4_ProfitLoss_"+IntegerToString(i),"0.00",DashTextSize,NULL,C'68,68,68');
         ObjectSetString(0,"Row_MT4_ProfitLoss_"+IntegerToString(i),OBJPROP_TOOLTIP,"---");
      }
      
      // MT4 Pips
      if (PairInfo[i].MT4TradeCount > 0){
         if (PairInfo[i].MT4ProfitPips < 0) ObjectSetText("Row_MT4_Pips_"+IntegerToString(i),DoubleToString(MathAbs(PairInfo[i].MT4ProfitPips),1),DashTextSize,NULL,clrOrangeRed);
            else ObjectSetText("Row_MT4_Pips_"+IntegerToString(i),DoubleToString(PairInfo[i].MT4ProfitPips,1),DashTextSize,NULL,C'147,255,38');
         ObjectSetString(0,"Row_MT4_Pips_"+IntegerToString(i),OBJPROP_TOOLTIP,"MT4 Pips: "+DoubleToString(PairInfo[i].MT4ProfitPips,1));
      } else {
         ObjectSetText("Row_MT4_Pips_"+IntegerToString(i),"0.0",DashTextSize,NULL,C'68,68,68');
         ObjectSetString(0,"Row_MT4_Pips_"+IntegerToString(i),OBJPROP_TOOLTIP,"---");
      }
      
      // FXt change color only when trade active
      if (ArraySize(PairInfo[i].FXtTradeID) > 0){
         if (PairInfo[i].FXtTradeID[0] > -1)
            ObjectSetText("Row_FXt_Label_"+IntegerToString(i),PairInfo[i].Pair,DashTextSize,NULL,clrBlanchedAlmond);
      } else ObjectSetText("Row_FXt_Label_"+IntegerToString(i),PairInfo[i].Pair,DashTextSize,NULL,C'68,68,68');
      ObjectSetString(0,"Row_FXt_Label_"+IntegerToString(i),OBJPROP_TOOLTIP,PairInfo[i].Pair+"\nTrades: "+IntegerToString(PairInfo[i].FXtTradeCount)+"\nPending: "+IntegerToString(PairInfo[i].FXtPendingOrderCount));
      
      // FXt Lot size
      if (PairInfo[i].FXtLongOpenLotsize > 0){
         ObjectSetText("Row_FXt_LongLots_"+IntegerToString(i),FormatFXtLots(PairInfo[i].FXtLongOpenLotsize),DashTextSize,NULL,clrBlanchedAlmond);
         ObjectSetString(0,"Row_FXt_LongLots_"+IntegerToString(i),OBJPROP_TOOLTIP,FormatFXtLotsTooltip(PairInfo[i].FXtLongOpenLotsize));
      } else {
         ObjectSetText("Row_FXt_LongLots_"+IntegerToString(i),FormatFXtLots(PairInfo[i].FXtLongOpenLotsize),DashTextSize,NULL,C'68,68,68');
         ObjectSetString(0,"Row_FXt_LongLots_"+IntegerToString(i),OBJPROP_TOOLTIP,"---");
      }
      
      if (PairInfo[i].FXtShortOpenLotsize > 0){
         ObjectSetText("Row_FXt_ShortLots_"+IntegerToString(i),FormatFXtLots(PairInfo[i].FXtShortOpenLotsize),DashTextSize,NULL,clrBlanchedAlmond);
         ObjectSetString(0,"Row_FXt_ShortLots_"+IntegerToString(i),OBJPROP_TOOLTIP,FormatFXtLotsTooltip(PairInfo[i].FXtShortOpenLotsize));
      } else {
         ObjectSetText("Row_FXt_ShortLots_"+IntegerToString(i),FormatFXtLots(PairInfo[i].FXtShortOpenLotsize),DashTextSize,NULL,C'68,68,68');
         ObjectSetString(0,"Row_FXt_ShortLots_"+IntegerToString(i),OBJPROP_TOOLTIP,"---");
      }
      
      // FXt Trade count
      if (PairInfo[i].FXtLongTradeCount > 0){
         ObjectSetText("Row_FXt_OrdersBuy_"+IntegerToString(i),IntegerToString(PairInfo[i].FXtLongTradeCount),DashTextSize,NULL,clrBlanchedAlmond);
         ObjectSetString(0,"Row_FXt_OrdersBuy_"+IntegerToString(i),OBJPROP_TOOLTIP,"Long fxT trades: "+IntegerToString(PairInfo[i].FXtLongTradeCount));
      } else {
         ObjectSetText("Row_FXt_OrdersBuy_"+IntegerToString(i),"0",DashTextSize,NULL,C'68,68,68');
         ObjectSetString(0,"Row_FXt_OrdersBuy_"+IntegerToString(i),OBJPROP_TOOLTIP,"Long fxT trades: 0");
      }
      
      if (PairInfo[i].FXtShortTradeCount > 0){
         ObjectSetText("Row_FXt_OrdersSell_"+IntegerToString(i),IntegerToString(PairInfo[i].FXtShortTradeCount),DashTextSize,NULL,clrBlanchedAlmond);
         ObjectSetString(0,"Row_FXt_OrdersSell_"+IntegerToString(i),OBJPROP_TOOLTIP,"Short fxT trades: "+IntegerToString(PairInfo[i].FXtShortTradeCount));
      } else {
         ObjectSetText("Row_FXt_OrdersSell_"+IntegerToString(i),"0",DashTextSize,NULL,C'68,68,68');
         ObjectSetString(0,"Row_FXt_OrdersSell_"+IntegerToString(i),OBJPROP_TOOLTIP,"Short FXt trades: 0");
      }
      
      if (PairInfo[i].FXtPendingOrderCount > 0){
         ObjectSetText("Row_FXt_Pending_"+IntegerToString(i),IntegerToString(PairInfo[i].FXtPendingOrderCount),DashTextSize,NULL,clrSteelBlue);
         ObjectSetString(0,"Row_FXt_Pending_"+IntegerToString(i),OBJPROP_TOOLTIP,"Pending Orders: "+IntegerToString(PairInfo[i].FXtPendingOrderCount));
      } else {
         ObjectSetText("Row_FXt_Pending_"+IntegerToString(i),"",DashTextSize,NULL,clrNONE);
         ObjectSetString(0,"Row_FXt_Pending_"+IntegerToString(i),OBJPROP_TOOLTIP,"...");
      }
      // FXt Hedged
      //if ((PairInfo[i].FXtLongTradeCount > 0)&&(PairInfo[i].FXtShortTradeCount > 0)) {
         
      //   ObjectSetString(0,"Row_FXt_Hedged_"+IntegerToString(i),OBJPROP_TOOLTIP,"fxT Hedge");
      //} else ObjectSetText("Row_FXt_Hedged_"+IntegerToString(i),"",DashTextSize,NULL,clrNONE);
      
      
      // FXt Long Profit
      if (PairInfo[i].FXtLongTradeCount > 0){
         if (PairInfo[i].FXtLongProfit < 0) ObjectSetText("Row_FXt_BuyPrice_"+IntegerToString(i),DoubleToString(MathAbs(PairInfo[i].FXtLongProfit),2),DashTextSize,NULL,clrOrangeRed);
            else ObjectSetText("Row_FXt_BuyPrice_"+IntegerToString(i),DoubleToString(PairInfo[i].FXtLongProfit,2),DashTextSize,NULL,C'147,255,38');
         ObjectSetString(0,"Row_FXt_BuyPrice_"+IntegerToString(i),OBJPROP_TOOLTIP,"Long fxT P/L: $"+DoubleToString(PairInfo[i].FXtLongProfit,2));
      } else {
         ObjectSetText("Row_FXt_BuyPrice_"+IntegerToString(i),"0.00",DashTextSize,NULL,C'68,68,68');
         ObjectSetString(0,"Row_FXt_BuyPrice_"+IntegerToString(i),OBJPROP_TOOLTIP,"---");
      }
      // FXt Short Profit
      if (PairInfo[i].FXtShortTradeCount > 0){
         if (PairInfo[i].FXtShortProfit < 0) ObjectSetText("Row_FXt_SellPrice_"+IntegerToString(i),DoubleToString(MathAbs(PairInfo[i].FXtShortProfit),2),DashTextSize,NULL,clrOrangeRed);
            else ObjectSetText("Row_FXt_SellPrice_"+IntegerToString(i),DoubleToString(PairInfo[i].FXtShortProfit,2),DashTextSize,NULL,C'147,255,38');
         ObjectSetString(0,"Row_FXt_SellPrice_"+IntegerToString(i),OBJPROP_TOOLTIP,"Short fxT P/L: $"+DoubleToString(PairInfo[i].FXtShortProfit,2));
      } else {
         ObjectSetText("Row_FXt_SellPrice_"+IntegerToString(i),"0.00",DashTextSize,NULL,C'68,68,68');
         ObjectSetString(0,"Row_FXt_SellPrice_"+IntegerToString(i),OBJPROP_TOOLTIP,"---");
      }
      
      // FXt Trade financing
      if (PairInfo[i].FXtFinancing == 0) ObjectSetText("Row_FXt_Swap_"+IntegerToString(i),"0.0000",DashTextSize,NULL,C'68,68,68');
      else if (PairInfo[i].FXtFinancing < 0) ObjectSetText("Row_FXt_Swap_"+IntegerToString(i),DoubleToStr(MathAbs(PairInfo[i].FXtFinancing),4),DashTextSize,NULL,clrOrangeRed);
         else ObjectSetText("Row_FXt_Swap_"+IntegerToString(i),DoubleToStr(MathAbs(PairInfo[i].FXtFinancing),4),DashTextSize,NULL,C'147,255,38');
      ObjectSetString(0,"Row_FXt_Swap_"+IntegerToString(i),OBJPROP_TOOLTIP,"fxT Financing: $"+DoubleToStr(PairInfo[i].FXtFinancing,2));
      
      // FXt Combined Profit/Loss
      if ((PairInfo[i].FXtShortTradeCount > 0)||(PairInfo[i].FXtLongTradeCount > 0)){
         if (IncludeSwapInPL){
            if (PairInfo[i].FXtProfit < 0) ObjectSetText("Row_FXt_ProfitLoss_"+IntegerToString(i),DoubleToString(MathAbs(PairInfo[i].FXtProfit + PairInfo[i].FXtFinancing),2),DashTextSize,NULL,clrOrangeRed);
               else ObjectSetText("Row_FXt_ProfitLoss_"+IntegerToString(i),DoubleToString(PairInfo[i].FXtProfit + PairInfo[i].FXtFinancing,2),DashTextSize,NULL,C'147,255,38');
            ObjectSetString(0,"Row_FXt_ProfitLoss_"+IntegerToString(i),OBJPROP_TOOLTIP,"fxT P/L: $"+DoubleToString(PairInfo[i].FXtProfit + PairInfo[i].FXtFinancing,2));
         } else {
            if (PairInfo[i].FXtProfit < 0) ObjectSetText("Row_FXt_ProfitLoss_"+IntegerToString(i),DoubleToString(MathAbs(PairInfo[i].FXtProfit),2),DashTextSize,NULL,clrOrangeRed);
               else ObjectSetText("Row_FXt_ProfitLoss_"+IntegerToString(i),DoubleToString(PairInfo[i].FXtProfit,2),DashTextSize,NULL,C'147,255,38');
            ObjectSetString(0,"Row_FXt_ProfitLoss_"+IntegerToString(i),OBJPROP_TOOLTIP,"fxT P/L: $"+DoubleToString(PairInfo[i].FXtProfit,2));
         }
      } else {
         ObjectSetText("Row_FXt_ProfitLoss_"+IntegerToString(i),"0.00",DashTextSize,NULL,C'68,68,68');
         ObjectSetString(0,"Row_FXt_ProfitLoss_"+IntegerToString(i),OBJPROP_TOOLTIP,"---");
      }
      
      // FXt Pips
      if ((PairInfo[i].FXtShortTradeCount > 0)||(PairInfo[i].FXtLongTradeCount > 0)){
         if (PairInfo[i].FXtProfitPips < 0) ObjectSetText("Row_FXt_Pips_"+IntegerToString(i),DoubleToString(MathAbs(PairInfo[i].FXtProfitPips),1),DashTextSize,NULL,clrOrangeRed);
            else ObjectSetText("Row_FXt_Pips_"+IntegerToString(i),DoubleToString(PairInfo[i].FXtProfitPips,1),DashTextSize,NULL,C'147,255,38');
         ObjectSetString(0,"Row_FXt_Pips_"+IntegerToString(i),OBJPROP_TOOLTIP,"fxT Pips: "+DoubleToString(PairInfo[i].FXtProfitPips,1));
      } else {
         ObjectSetText("Row_FXt_Pips_"+IntegerToString(i),"0.0",DashTextSize,NULL,C'68,68,68');
         ObjectSetString(0,"Row_FXt_Pips_"+IntegerToString(i),OBJPROP_TOOLTIP,"---");
      }
      
      // FXt Margin Used
      if ((PairInfo[i].FXtShortTradeCount > 0)||(PairInfo[i].FXtLongTradeCount > 0)){
         ObjectSetText("Row_FXt_Margin_"+IntegerToString(i),DoubleToString(PairInfo[i].FXtUsedMargin,2),DashTextSize,NULL,C'117,117,117');
         ObjectSetString(0,"Row_FXt_Margin_"+IntegerToString(i),OBJPROP_TOOLTIP,"fxT Used Margin: $"+DoubleToString(PairInfo[i].FXtUsedMargin,2));
      } else {
         ObjectSetText("Row_FXt_Margin_"+IntegerToString(i),"0.00",DashTextSize,NULL,C'68,68,68');
         ObjectSetString(0,"Row_FXt_Margin_"+IntegerToString(i),OBJPROP_TOOLTIP,"---");
      }
      
      // Are there subrows?
      if (PairInfo[i].ShowTrades){
         
         for (int a = 0; a < ArraySize(PairInfo[i].MT4TradeID); a++){
            
            int id = PairInfo[i].MT4TradeID[a];

            if ((id >= 0)&&(id < ArraySize(MT4ID))){

               // MT4 Order number
               if ((MT4Direction[id] == "long")||(MT4Direction[id] == "buyLimit")||(MT4Direction[id] == "buyStop")){
                  ObjectSetText("SubRow_MT4ID_"+IntegerToString(a)+"_"+IntegerToString(i),IntegerToString(MT4ID[id]),DashTextSize,NULL,clrDarkGreen);
                  ObjectSetString(0,"SubRow_MT4ID_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"MT4 Long ID: "+IntegerToString(MT4ID[id]));
               } else if ((MT4Direction[id] == "short")||(MT4Direction[id] == "sellLimit")||(MT4Direction[id] == "sellStop")){
                  ObjectSetText("SubRow_MT4ID_"+IntegerToString(a)+"_"+IntegerToString(i),IntegerToString(MT4ID[id]),DashTextSize,NULL,clrFireBrick);
                  ObjectSetString(0,"SubRow_MT4ID_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"MT4 Short ID: "+IntegerToString(MT4ID[id]));
               }
               
               // MT4 Lot Size
               if (MT4Direction[id] == "long"){
                  ObjectSetText("SubRow_MT4_LongLots_"+IntegerToString(a)+"_"+IntegerToString(i),FormatMT4Lots(MT4Lots[id]),DashTextSize,NULL,clrGray);
                  ObjectSetString(0,"SubRow_MT4_LongLots_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,FormatMT4LotsTooltip(MT4Lots[id]));
                  ObjectSetText("SubRow_MT4_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),FormatMT4Lots(0),DashTextSize,NULL,C'68,68,68');
                  ObjectSetString(0,"SubRow_MT4_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"---");
               } else if (MT4Direction[id] == "short"){
                  ObjectSetText("SubRow_MT4_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),FormatMT4Lots(MT4Lots[id]),DashTextSize,NULL,clrGray);
                  ObjectSetString(0,"SubRow_MT4_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,FormatMT4LotsTooltip(MT4Lots[id]));
                  ObjectSetText("SubRow_MT4_LongLots_"+IntegerToString(a)+"_"+IntegerToString(i),FormatMT4Lots(0),DashTextSize,NULL,C'68,68,68');
                  ObjectSetString(0,"SubRow_MT4_LongLots_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"---");
               } else { // this is a pending order
                  ObjectSetText("SubRow_MT4_LongLots_"+IntegerToString(a)+"_"+IntegerToString(i),"",DashTextSize,NULL,clrNONE);
                  if (MT4Direction[id] == "sellStop"){
                     ObjectSetText("SubRow_MT4_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),"Pending - Sell Stop Order of "+FormatMT4Lots(MT4Lots[id])+" @ "+DoubleToStr(MT4Price[id],int(MarketInfo(MT4Pair[id],MODE_DIGITS))),DashTextSize,NULL,clrSteelBlue);
                     ObjectSetString(0,"SubRow_MT4_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"MT4 Sell Stop");
                  } else if (MT4Direction[id] == "sellLimit"){
                     ObjectSetText("SubRow_MT4_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),"Pending - Sell Limit Order of "+FormatMT4Lots(MT4Lots[id])+" @ "+DoubleToStr(MT4Price[id],int(MarketInfo(MT4Pair[id],MODE_DIGITS))),DashTextSize,NULL,clrSteelBlue);
                     ObjectSetString(0,"SubRow_MT4_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"MT4 Sell Limit");
                  } else if (MT4Direction[id] == "buyStop"){
                     ObjectSetText("SubRow_MT4_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),"Pending - Buy Stop Order of "+FormatMT4Lots(MT4Lots[id])+" @ "+DoubleToStr(MT4Price[id],int(MarketInfo(MT4Pair[id],MODE_DIGITS))),DashTextSize,NULL,clrSteelBlue);
                     ObjectSetString(0,"SubRow_MT4_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"MT4 Buy Stop");
                  } else if (MT4Direction[id] == "buyLimit"){
                     ObjectSetText("SubRow_MT4_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),"Pending - Buy Limit Order of "+FormatMT4Lots(MT4Lots[id])+" @ "+DoubleToStr(MT4Price[id],int(MarketInfo(MT4Pair[id],MODE_DIGITS))),DashTextSize,NULL,clrSteelBlue);
                     ObjectSetString(0,"SubRow_MT4_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"MT4 Buy Limit");
                  } else ObjectSetText("SubRow_MT4_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),"",DashTextSize,NULL,clrNONE); // there was an error
               }
               
               // MT4 Trade Count
               /*
               if (MT4Direction[id] == "long"){
                  ObjectSetText("SubRow_MT4_OrdersBuy_"+IntegerToString(a)+"_"+IntegerToString(i),"1",DashTextSize,NULL,clrGray);
                  ObjectSetText("SubRow_MT4_OrdersSell_"+IntegerToString(a)+"_"+IntegerToString(i),"0",DashTextSize,NULL,C'68,68,68');
               }
               if (MT4Direction[id] == "short"){
                  ObjectSetText("SubRow_MT4_OrdersSell_"+IntegerToString(a)+"_"+IntegerToString(i),"1",DashTextSize,NULL,clrGray);
                  ObjectSetText("SubRow_MT4_OrdersBuy_"+IntegerToString(a)+"_"+IntegerToString(i),"0",DashTextSize,NULL,C'68,68,68');
               }
               */
               
               // MT4 Profit/Loss
               if (MT4Direction[id] == "long"){
                  if (MT4Profit[id] < 0) ObjectSetText("SubRow_MT4_BuyPrice_"+IntegerToString(a)+"_"+IntegerToString(i),DoubleToStr(MathAbs(MT4Profit[id]),2),DashTextSize,NULL,clrFireBrick);
                     else ObjectSetText("SubRow_MT4_BuyPrice_"+IntegerToString(a)+"_"+IntegerToString(i),DoubleToStr(MathAbs(MT4Profit[id]),2),DashTextSize,NULL,clrDarkGreen);
                  ObjectSetText("SubRow_MT4_SellPrice_"+IntegerToString(a)+"_"+IntegerToString(i),"0.00",DashTextSize,NULL,C'68,68,68');
                  ObjectSetString(0,"SubRow_MT4_SellPrice_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"---");
                  ObjectSetString(0,"SubRow_MT4_BuyPrice_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"Long MT4 P/L: $"+DoubleToStr(MT4Profit[id],2));
               } else if (MT4Direction[id] == "short"){
                  if (MT4Profit[id] < 0) ObjectSetText("SubRow_MT4_SellPrice_"+IntegerToString(a)+"_"+IntegerToString(i),DoubleToStr(MathAbs(MT4Profit[id]),2),DashTextSize,NULL,clrFireBrick);
                     else ObjectSetText("SubRow_MT4_SellPrice_"+IntegerToString(a)+"_"+IntegerToString(i),DoubleToStr(MathAbs(MT4Profit[id]),2),DashTextSize,NULL,clrDarkGreen);
                  ObjectSetText("SubRow_MT4_BuyPrice_"+IntegerToString(a)+"_"+IntegerToString(i),"0.00",DashTextSize,NULL,C'68,68,68');
                  ObjectSetString(0,"SubRow_MT4_SellPrice_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"Short MT4 P/L: $"+DoubleToStr(MT4Profit[id],2));
                  ObjectSetString(0,"SubRow_MT4_BuyPrice_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"---");
               } else { // this is a pending order
                  ObjectSetText("SubRow_MT4_SellPrice_"+IntegerToString(a)+"_"+IntegerToString(i),"",DashTextSize,NULL,clrNONE);
                  ObjectSetText("SubRow_MT4_BuyPrice_"+IntegerToString(a)+"_"+IntegerToString(i),"",DashTextSize,NULL,clrNONE);
               }
               
               
               
               // MT4 Pips
               if ((MT4Direction[id] == "long")||(MT4Direction[id] == "short")){
                  double pips = 0;
                  if (MT4Direction[id] == "short")pips = NormalizeDouble((MT4Price[id] - MarketInfo(MT4Pair[id],MODE_ASK))/MarketInfo(MT4Pair[id],MODE_POINT)/10,1);
                  if (MT4Direction[id] == "long") pips = NormalizeDouble((MarketInfo(MT4Pair[id],MODE_BID) - MT4Price[id])/MarketInfo(MT4Pair[id],MODE_POINT)/10,1);
                  
                  if (MT4Profit[id] < 0) ObjectSetText("SubRow_MT4_Pips_"+IntegerToString(a)+"_"+IntegerToString(i),DoubleToStr(MathAbs(pips),1),DashTextSize,NULL,clrFireBrick);
                     else ObjectSetText("SubRow_MT4_Pips_"+IntegerToString(a)+"_"+IntegerToString(i),DoubleToStr(MathAbs(pips),1),DashTextSize,NULL,clrDarkGreen);
                  ObjectSetString(0,"SubRow_MT4_Pips_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"MT4 Pips: "+DoubleToStr(pips,1));
               } else { // this is a pending order
                  ObjectSetText("SubRow_MT4_Pips_"+IntegerToString(a)+"_"+IntegerToString(i),"",DashTextSize,NULL,clrNONE);
               }
               
               int fid = PairInfo[i].FXtTradeID[a];
               
               // fid < 0 if FXt trade not open yet.
               if ((fid >= 0)&&(fid < ArraySize(FXtID))){
                  
                  // FXt Order number
                  if ((FXtDirection[fid] == "long")||(FXtDirection[fid] == "buyLimit")||(FXtDirection[fid] == "buyStop")){
                     ObjectSetText("SubRow_FXtID_"+IntegerToString(a)+"_"+IntegerToString(i),IntegerToString(FXtID[fid]),DashTextSize,NULL,clrDarkGreen);
                     ObjectSetString(0,"SubRow_FXtID_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"fxT Long ID: "+IntegerToString(FXtID[fid]));
                  }
                  
                  if ((FXtDirection[fid] == "short")||(FXtDirection[fid] == "sellLimit")||(FXtDirection[fid] == "sellStop")){
                     ObjectSetText("SubRow_FXtID_"+IntegerToString(a)+"_"+IntegerToString(i),IntegerToString(FXtID[fid]),DashTextSize,NULL,clrFireBrick);
                     ObjectSetString(0,"SubRow_FXtID_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"fxT Short ID: "+IntegerToString(FXtID[fid]));
                  }
                  
                  // FXt Lot Size
                  if (FXtDirection[fid] == "long"){
                     ObjectSetText("SubRow_FXt_LongLots_"+IntegerToString(a)+"_"+IntegerToString(i),FormatFXtLots(FXtLots[fid]),DashTextSize,NULL,clrGray);
                     ObjectSetString(0,"SubRow_FXt_LongLots_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,FormatFXtLotsTooltip(FXtLots[fid]));
                     ObjectSetText("SubRow_FXt_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),FormatFXtLots(0),DashTextSize,NULL,C'68,68,68');
                     ObjectSetString(0,"SubRow_FXt_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"---");
                  } else if (FXtDirection[fid] == "short"){
                     ObjectSetText("SubRow_FXt_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),FormatFXtLots(FXtLots[fid]),DashTextSize,NULL,clrGray);
                     ObjectSetString(0,"SubRow_FXt_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,FormatFXtLotsTooltip(FXtLots[fid]));
                     ObjectSetText("SubRow_FXt_LongLots_"+IntegerToString(a)+"_"+IntegerToString(i),FormatFXtLots(0),DashTextSize,NULL,C'68,68,68');
                     ObjectSetString(0,"SubRow_FXt_LongLots_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"---");
                  } else { // this is a pending order
                     ObjectSetText("SubRow_FXt_LongLots_"+IntegerToString(a)+"_"+IntegerToString(i),"",DashTextSize,NULL,clrNONE);
                     if (FXtDirection[fid] == "sellStop"){
                        ObjectSetText("SubRow_FXt_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),"Pending - Sell Stop Order of "+FormatFXtLots(FXtLots[fid])+" @ "+DoubleToStr(FXtPrice[fid],int(MarketInfo(FXtPair[fid],MODE_DIGITS))),DashTextSize,NULL,clrSteelBlue);
                        ObjectSetString(0,"SubRow_FXt_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"fxT Sell Stop");
                     } else if (FXtDirection[fid] == "sellLimit"){
                        ObjectSetText("SubRow_FXt_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),"Pending - Sell Limit Order of "+FormatFXtLots(FXtLots[fid])+" @ "+DoubleToStr(FXtPrice[fid],int(MarketInfo(FXtPair[fid],MODE_DIGITS))),DashTextSize,NULL,clrSteelBlue);
                        ObjectSetString(0,"SubRow_FXt_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"fxT Sell Limit");
                     } else if (FXtDirection[fid] == "buyStop"){
                        ObjectSetText("SubRow_FXt_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),"Pending - Buy Stop Order of "+FormatFXtLots(FXtLots[fid])+" @ "+DoubleToStr(FXtPrice[fid],int(MarketInfo(FXtPair[fid],MODE_DIGITS))),DashTextSize,NULL,clrSteelBlue);
                        ObjectSetString(0,"SubRow_FXt_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"fxT Buy Stop");
                     } else if (FXtDirection[fid] == "buyLimit"){
                        ObjectSetText("SubRow_FXt_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),"Pending - Buy Limit Order of "+FormatFXtLots(FXtLots[fid])+" @ "+DoubleToStr(FXtPrice[fid],int(MarketInfo(FXtPair[fid],MODE_DIGITS))),DashTextSize,NULL,clrSteelBlue);
                        ObjectSetString(0,"SubRow_FXt_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"fxT Buy Limit");
                     } else ObjectSetText("SubRow_FXt_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),"",DashTextSize,NULL,clrNONE); // there was an error
                  }
                  
                  // FXt Profit/Loss
                  if (FXtDirection[fid] == "long"){
                     if (FXtProfit[fid] < 0) ObjectSetText("SubRow_FXt_BuyPrice_"+IntegerToString(a)+"_"+IntegerToString(i),DoubleToStr(MathAbs(FXtProfit[fid]),2),DashTextSize,NULL,clrFireBrick);
                        else ObjectSetText("SubRow_FXt_BuyPrice_"+IntegerToString(a)+"_"+IntegerToString(i),DoubleToStr(MathAbs(FXtProfit[fid]),2),DashTextSize,NULL,clrDarkGreen);
                     ObjectSetText("SubRow_FXt_SellPrice_"+IntegerToString(a)+"_"+IntegerToString(i),"0.00",DashTextSize,NULL,C'68,68,68');
                     ObjectSetString(0,"SubRow_FXt_SellPrice_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"---");
                     ObjectSetString(0,"SubRow_FXt_BuyPrice_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"Long fxT P/L: $"+DoubleToStr(FXtProfit[fid],2));
                  } else if (FXtDirection[fid] == "short"){
                     if (FXtProfit[fid] < 0) ObjectSetText("SubRow_FXt_SellPrice_"+IntegerToString(a)+"_"+IntegerToString(i),DoubleToStr(MathAbs(FXtProfit[fid]),2),DashTextSize,NULL,clrFireBrick);
                        else ObjectSetText("SubRow_FXt_SellPrice_"+IntegerToString(a)+"_"+IntegerToString(i),DoubleToStr(MathAbs(FXtProfit[fid]),2),DashTextSize,NULL,clrDarkGreen);
                     ObjectSetText("SubRow_FXt_BuyPrice_"+IntegerToString(a)+"_"+IntegerToString(i),"0.00",DashTextSize,NULL,C'68,68,68');
                     ObjectSetString(0,"SubRow_FXt_BuyPrice_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"---");
                     ObjectSetString(0,"SubRow_FXt_SellPrice_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"Short fxT P/L: $"+DoubleToStr(FXtProfit[fid],2));
                  } else { // this is a pending order
                     ObjectSetText("SubRow_FXt_SellPrice_"+IntegerToString(a)+"_"+IntegerToString(i),"",DashTextSize,NULL,clrNONE);
                     ObjectSetText("SubRow_FXt_BuyPrice_"+IntegerToString(a)+"_"+IntegerToString(i),"",DashTextSize,NULL,clrNONE);
                  }
                  
                  // FXt Trade financing
                  if ((FXtDirection[fid] == "long")||(FXtDirection[fid] == "short")){
                     if (FXtFinancing[fid] == 0) ObjectSetText("SubRow_FXt_Swap_"+IntegerToString(a)+"_"+IntegerToString(i),"0.0000",DashTextSize,NULL,C'68,68,68');
                     else if (FXtFinancing[fid] < 0) ObjectSetText("SubRow_FXt_Swap_"+IntegerToString(a)+"_"+IntegerToString(i),DoubleToStr(MathAbs(FXtFinancing[fid]),4),DashTextSize,NULL,clrFireBrick);
                        else ObjectSetText("SubRow_FXt_Swap_"+IntegerToString(a)+"_"+IntegerToString(i),DoubleToStr(MathAbs(FXtFinancing[fid]),4),DashTextSize,NULL,clrDarkGreen);
                     ObjectSetString(0,"SubRow_FXt_Swap_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"fxT Financing: $"+DoubleToStr(FXtFinancing[fid],2));
                  } else { // this is a pending order
                     ObjectSetText("SubRow_FXt_Swap_"+IntegerToString(a)+"_"+IntegerToString(i),"",DashTextSize,NULL,clrNONE);
                  }
                  
                  // FXt Pips
                  if ((FXtDirection[fid] == "long")||(FXtDirection[fid] == "short")){
                     double pips = 0;
                     if (FXtDirection[fid] == "short")pips = NormalizeDouble((FXtPrice[fid] - MarketInfo(FXtPair[fid],MODE_ASK))/MarketInfo(FXtPair[fid],MODE_POINT)/10,1);
                     if (FXtDirection[fid] == "long") pips = NormalizeDouble((MarketInfo(FXtPair[fid],MODE_BID) - FXtPrice[fid])/MarketInfo(FXtPair[fid],MODE_POINT)/10,1);
                     
                     if (FXtProfit[fid] < 0) ObjectSetText("SubRow_FXt_Pips_"+IntegerToString(a)+"_"+IntegerToString(i),DoubleToStr(MathAbs(pips),1),DashTextSize,NULL,clrFireBrick);
                        else ObjectSetText("SubRow_FXt_Pips_"+IntegerToString(a)+"_"+IntegerToString(i),DoubleToStr(MathAbs(pips),1),DashTextSize,NULL,clrDarkGreen);
                     ObjectSetString(0,"SubRow_FXt_Pips_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"fxT Pips: "+DoubleToStr(pips,1));
                  } else { // this is a pending order
                     ObjectSetText("SubRow_FXt_Pips_"+IntegerToString(a)+"_"+IntegerToString(i),"",DashTextSize,NULL,clrNONE);
                  }
                  
                  // Fxt Margin Used
                  if ((FXtDirection[fid] == "long")||(FXtDirection[fid] == "short")){
                     ObjectSetText("SubRow_FXt_Margin_"+IntegerToString(a)+"_"+IntegerToString(i),DoubleToStr(FXtMargin[fid],2),DashTextSize,NULL,C'68,68,68');
                     ObjectSetString(0,"SubRow_FXt_Margin_"+IntegerToString(a)+"_"+IntegerToString(i),OBJPROP_TOOLTIP,"fxT Used Margin: $"+DoubleToStr(FXtMargin[fid],1));
                  } else { // this is a pending order
                     ObjectSetText("SubRow_FXt_Margin_"+IntegerToString(a)+"_"+IntegerToString(i),"",DashTextSize,NULL,clrNONE);
                  }
               }
            }
         }
      }
   }
}
// -- Update Footer
void UpdateFooter(){

   ObjectSetText("FooterMT4Pairs",IntegerToString(ArraySize(PairInfo))+" Pairs",DashTextSize,NULL,C'117,117,117');
   ObjectSetString(0,"FooterMT4Pairs",OBJPROP_TOOLTIP,"Pairs: "+IntegerToString(ArraySize(PairInfo))+"\nTrades: "+IntegerToString(MT4TotalTrades)+"\nPending: "+IntegerToString(MT4TotalOrders));
   
   ObjectSetText("FooterMT4LongLots",FormatMT4Lots(MT4TotalLongLots),DashTextSize,NULL,C'117,117,117');
   ObjectSetString(0,"FooterMT4LongLots",OBJPROP_TOOLTIP,"Long MT4 size: "+FormatMT4Lots(MT4TotalLongLots));
   
   ObjectSetText("FooterMT4ShortLots",FormatMT4Lots(MT4TotalShortLots),DashTextSize,NULL,C'117,117,117');
   ObjectSetString(0,"FooterMT4ShortLots",OBJPROP_TOOLTIP,"Short MT4 size: "+FormatMT4Lots(MT4TotalShortLots));
   
   ObjectSetText("FooterMT4LongOrders",IntegerToString(MT4TotalLongTrades),DashTextSize,NULL,C'117,117,117');
   ObjectSetString(0,"FooterMT4LongOrders",OBJPROP_TOOLTIP,"Long MT4 trades: "+IntegerToString(MT4TotalLongTrades));
   
   ObjectSetText("FooterMT4ShortOrders",IntegerToString(MT4TotalShortTrades),DashTextSize,NULL,C'117,117,117');
   ObjectSetString(0,"FooterMT4ShortOrders",OBJPROP_TOOLTIP,"Short MT4 trades: "+IntegerToString(MT4TotalShortTrades));
   
   ObjectSetText("FooterMT4LongPrice",DoubleToString(MT4CurrentLongProfit,2),DashTextSize,NULL,C'117,117,117');
   ObjectSetString(0,"FooterMT4LongPrice",OBJPROP_TOOLTIP,"Long MT4 P/L: $"+DoubleToString(MT4CurrentLongProfit,2));
   
   ObjectSetText("FooterMT4ShortPrice",DoubleToString(MT4CurrentShortProfit,2),DashTextSize,NULL,C'117,117,117');
   ObjectSetString(0,"FooterMT4ShortPrice",OBJPROP_TOOLTIP,"Short MT4 P/L: $"+DoubleToString(MT4CurrentShortProfit,2));
   
   ObjectSetText("FooterMT4ProfitLoss",DoubleToString(MT4CurrentProfit,2),DashTextSize,NULL,C'117,117,117');
   ObjectSetString(0,"FooterMT4ProfitLoss",OBJPROP_TOOLTIP,"System MT4 P/L: $"+DoubleToString(MT4CurrentProfit,2));
   
   ObjectSetText("FooterMT4Pips",DoubleToString(MT4TotalPips,1),DashTextSize,NULL,C'117,117,117');
   ObjectSetString(0,"FooterMT4Pips",OBJPROP_TOOLTIP,DoubleToString(MT4TotalPips,1)+" pips");
   
   ObjectSetText("FooterFXtLongLots",FormatFXtLots(FXtTotalLongLots),DashTextSize,NULL,C'117,117,117');
   ObjectSetString(0,"FooterFXtLongLots",OBJPROP_TOOLTIP,"Short fxT size: "+FormatFXtLots(FXtTotalLongLots));
   
   ObjectSetText("FooterFXtShortLots",FormatFXtLots(FXtTotalShortLots),DashTextSize,NULL,C'117,117,117');
   ObjectSetString(0,"FooterFXtShortLots",OBJPROP_TOOLTIP,"Short fxT size: "+FormatFXtLots(FXtTotalShortLots));
   
   ObjectSetText("FooterFXtLongOrders",IntegerToString(FXtTotalLongTrades),DashTextSize,NULL,C'117,117,117');
   ObjectSetString(0,"FooterFXtLongOrders",OBJPROP_TOOLTIP,"Long fxT trades: "+IntegerToString(FXtTotalLongTrades));
   
   ObjectSetText("FooterFXtShortOrders",IntegerToString(FXtTotalShortTrades),DashTextSize,NULL,C'117,117,117');
   ObjectSetString(0,"FooterFXtShortOrders",OBJPROP_TOOLTIP,"Short fxT trades: "+IntegerToString(FXtTotalShortTrades));
   
   ObjectSetText("FooterFXtLongPrice",DoubleToString(FXtCurrentLongProfit,2),DashTextSize,NULL,C'117,117,117');
   ObjectSetString(0,"FooterFXtLongPrice",OBJPROP_TOOLTIP,"Long fxT P/L: $"+DoubleToString(FXtCurrentLongProfit,2));
   
   ObjectSetText("FooterFXtShortPrice",DoubleToString(FXtCurrentShortProfit,2),DashTextSize,NULL,C'117,117,117');
   ObjectSetString(0,"FooterFXtShortPrice",OBJPROP_TOOLTIP,"Short fxT P/L: $"+DoubleToString(FXtCurrentShortProfit,2));
   
   ObjectSetText("FooterFXtFinancing",DoubleToString(FXtCurrentFinancing,4),DashTextSize,NULL,C'117,117,117');
   ObjectSetString(0,"FooterFXtFinancing",OBJPROP_TOOLTIP,"fxT Financing: $"+DoubleToString(FXtCurrentFinancing,2));
   
   if (IncludeSwapInPL){
      ObjectSetText("FooterFXtProfitLoss",DoubleToString(FXtCurrentProfit + FXtCurrentFinancing,2),DashTextSize,NULL,C'117,117,117');
      ObjectSetString(0,"FooterFXtProfitLoss",OBJPROP_TOOLTIP,"System fxT P/L: $"+DoubleToString(FXtCurrentProfit + FXtCurrentFinancing,2));
   } else {
      ObjectSetText("FooterFXtProfitLoss",DoubleToString(FXtCurrentProfit,2),DashTextSize,NULL,C'117,117,117');
      ObjectSetString(0,"FooterFXtProfitLoss",OBJPROP_TOOLTIP,"System fxT P/L: $"+DoubleToString(FXtCurrentProfit,2));
   }
   
   ObjectSetText("FooterFXtPips",DoubleToString(FXtTotalPips,1),DashTextSize,NULL,C'117,117,117');
   ObjectSetString(0,"FooterFXtPips",OBJPROP_TOOLTIP,DoubleToString(FXtTotalPips,1)+" pips");
   
   ObjectSetText("FooterFXtMargin",DoubleToString(FXtTotalUsedMargin,2),DashTextSize,NULL,C'117,117,117');
   ObjectSetString(0,"FooterFXtMargin",OBJPROP_TOOLTIP,"$"+DoubleToString(FXtTotalUsedMargin,2));
}

// -- Format MT4 lot sizes for display
string FormatMT4Lots(double lots){
   if (DisplayMT4LotsAsUnits){
      int units = int(NormalizeDouble(lots * 100000,0));
      if (units >= 100000) return IntegerToString(units);
         else if (units >= 10000) return "0"+IntegerToString(units);
         else if (units >= 1000)  return "00"+IntegerToString(units);
         else if (units >= 100)   return "000"+IntegerToString(units);
         else if (units >= 10)    return "0000"+IntegerToString(units);
         else return "00000"+IntegerToString(units);
   } else {
      if (lots == 0) return "0.00";
         else return DoubleToStr(lots,2);
   }
}

string FormatMT4LotsTooltip(double lots){
   if (DisplayMT4LotsAsUnits) return IntegerToString(int(NormalizeDouble(lots * 100000,0)))+" units = "+DoubleToString(lots,2)+" lots";
   else return DoubleToString(lots,2)+" lots = "+IntegerToString(int(NormalizeDouble(lots * 100000,0)))+" units";
}

// -- Format FXt lot sizes for display
string FormatFXtLots(int units){
   if (DisplayFXtLotsAsUnits){
      if (units == 0) return "00000";
         else if (units < 10) return "0000"+IntegerToString(units);
         else if (units < 100) return "000"+IntegerToString(units);
         else if (units < 1000) return "00"+IntegerToString(units);
         else if (units < 10000) return "0"+IntegerToString(units);
         else return IntegerToString(units);
   } else {
      if (units == 0) return "0.00000";
      double lots = units * 0.00001;
      return DoubleToString(lots,5);
   }
}

string FormatFXtLotsTooltip(int units){ 
   if (DisplayFXtLotsAsUnits) return IntegerToString(units)+" units = "+DoubleToString(units * 0.00001,5)+" lots";
   else return DoubleToString(units * 0.00001,5)+" lots = "+IntegerToString(units)+" units";
}

//================================================//
// Draw Dashboard                                 //
//================================================//
void DrawDash(){
   
   if (SecondAccount == "") DualAccounts = false;
   else DualAccounts = true;
   
   if (DualAccounts) y_axis = 140;
      else y_axis = 95;

   ObjectsDeleteAll();
   DrawHeader();
   DrawRows();
   DrawFooter();
}
// --- Draw the dashboard header
void DrawHeader(){

   // status message
   SetText("StatusMessage","Status: ",x_axis,22,C'136,136,136',HeaderTextSize);
   
   // system name
   SetText("SystemName","System Name: ",x_axis+460,22,C'136,136,136',HeaderTextSize);
   
   // version number
   SetText("VersionNum","Version: "+dittoVersion,x_axis+820,22,C'136,136,136',HeaderTextSize);
   
   // system clock
   SetText("SystemClock", "00:00:00",x_axis+990,22,C'136,136,136',HeaderTextSize);
   
   // create dashboard objects
   SetPanel("BP",0,x_axis-1,y_axis-55,DashWidth,475,clrBlack,clrBlack,1);
   
   if (DualAccounts) SetPanel("AccountBar",0,x_axis-2,y_axis-100,DashWidth,75,C'34,34,34',clrBlack,1);
      else SetPanel("AccountBar",0,x_axis-2,y_axis-55,DashWidth,32,C'34,34,34',clrBlack,1);
   
   SetPanel("HeaderBar",0,x_axis-2,y_axis-30,DashWidth,26,C'136,136,136',clrBlack,1);
   
   if (SecondAccount == "") DualAccounts = false;
   
   if (DualAccounts){
      SetText("AccountBalance","Account Balance: $000.00",x_axis+21,y_axis-90,C'136,136,136',HeaderTextSize);
      SetText("ShortAccountBalance","Short Account: $000.00",x_axis+48,y_axis-70,C'114,114,114',HeaderTextSize-1);
      SetText("LongAccountBalance","Long Account: $000.00",x_axis+50,y_axis-52,C'114,114,114',HeaderTextSize-1);
   } else SetText("AccountBalance","Account Balance: $000.00",x_axis+21,y_axis-50,C'136,136,136',HeaderTextSize);
   
   
   if (DualAccounts){
      SetText("AccountEquity","Account Equity: $000.00",x_axis+235,y_axis-90,C'136,136,136',HeaderTextSize);
      SetText("ShortAccountEquity","Short Equity: $000.00",x_axis+262,y_axis-70,C'114,114,114',HeaderTextSize-1);
      SetText("LongAccountEquity","Long Equity: $000.00",x_axis+264,y_axis-52,C'114,114,114',HeaderTextSize-1);
   } else SetText("AccountEquity","Account Equity: $000.00",x_axis+235,y_axis-50,C'136,136,136',HeaderTextSize);
   
   
   if (DualAccounts){
      SetText("AccountMargin","Margin Used / Avail: $000.00 / $000.00",x_axis+450,y_axis-90,C'136,136,136',HeaderTextSize);
      SetText("ShortAccountMargin","Short Margin: $000.00 / $000.00",x_axis+507,y_axis-70,C'114,114,114',HeaderTextSize-1);
      SetText("LongAccountMargin","Long Margin: $000.00 / $000.00",x_axis+509,y_axis-52,C'114,114,114',HeaderTextSize-1);
   } else SetText("AccountMargin","Margin Used / Avail: $000.00 / $000.00",x_axis+450,y_axis-50,C'136,136,136',HeaderTextSize);
   
   
   if (DualAccounts){
      SetText("AccountRealPL","Realized P/L: $000.00",x_axis+815,y_axis-90,C'136,136,136',HeaderTextSize);
      SetText("ShortAccountRealPL","Short P/L: $000.00",x_axis+832,y_axis-70,C'114,114,114',HeaderTextSize-1);
      SetText("LongAccountRealPL","Long P/L: $000.00",x_axis+834,y_axis-52,C'114,114,114',HeaderTextSize-1);
   } else SetText("AccountRealPL","Realized P/L: $000.00",x_axis+815,y_axis-50,C'136,136,136',HeaderTextSize);
   
   SetPanel("ShowAll_Bar",0,x_axis-2,y_axis-30,24,26,C'136,136,136',clrNONE,1);
   
   if (ShowAllTrades){
      SetText("ShowAll_Toggle","-",x_axis+2,y_axis-26,clrBlack,HeaderTextSize);
      ObjectSetString(0,"ShowAll_Toggle",OBJPROP_TOOLTIP,"Hide all trades");
   } else {
      SetText("ShowAll_Toggle","+",x_axis+2,y_axis-24,clrBlack,HeaderTextSize);
      ObjectSetString(0,"ShowAll_Toggle",OBJPROP_TOOLTIP,"Show all trades");
   }
   
   SetText("MT4Label","MT4",x_axis+24,y_axis-24,clrBlack,HeaderTextSize);
   ObjectSetString(0,"MT4Label",OBJPROP_TOOLTIP,"MT4 Trades");
   
   if (DisplayMT4LotsAsUnits){
      SetText ("MT4LotsLabel","Units",x_axis+124,y_axis-30,C'68,68,68',LabelTextSize);
      ObjectSetString(0,"MT4LotsLabel",OBJPROP_TOOLTIP,"Switch to MT4 lots");
   } else {
      SetText ("MT4LotsLabel","Lots",x_axis+124,y_axis-30,C'68,68,68',LabelTextSize);
      ObjectSetString(0,"MT4LotsLabel",OBJPROP_TOOLTIP,"Switch to MT4 units");
   }
    
   SetText ("MT4LotsBuyLabel","Buy",x_axis+96,y_axis-19,C'68,68,68',LabelTextSize);
   if (DisplayMT4LotsAsUnits) ObjectSetString(0,"MT4LotsBuyLabel",OBJPROP_TOOLTIP,"Long MT4 units");
   else ObjectSetString(0,"MT4LotsBuyLabel",OBJPROP_TOOLTIP,"Long MT4 lots");
   
   SetText ("MT4LotsSellLabel","Sell",x_axis+155,y_axis-19,C'68,68,68',LabelTextSize);
   if (DisplayMT4LotsAsUnits) ObjectSetString(0,"MT4LotsSellLabel",OBJPROP_TOOLTIP,"Short MT4 units");
   else ObjectSetString(0,"MT4LotsSellLabel",OBJPROP_TOOLTIP,"Short MT4 lots");
   
   SetText ("MT4OrdersLabel","Trades",x_axis+202,y_axis-30,C'68,68,68',LabelTextSize);
   ObjectSetString(0,"MT4OrdersLabel",OBJPROP_TOOLTIP,"MT4 Orders");
   
   SetText ("MT4OrdersBuyLabel","Buy",x_axis+196,y_axis-19,C'68,68,68',LabelTextSize);
   ObjectSetString(0,"MT4OrdersBuyLabel",OBJPROP_TOOLTIP,"Long MT4 orders");
   
   SetText ("MT4OrdersSellLabel","Sell",x_axis+225,y_axis-19,C'68,68,68',LabelTextSize);
   ObjectSetString(0,"MT4OrdersSellLabel",OBJPROP_TOOLTIP,"Short MT4 orders");
   
   SetText ("MT4BuyPriceLabel","Buy",x_axis+259,y_axis-19,C'68,68,68',LabelTextSize);
   ObjectSetString(0,"MT4BuyPriceLabel",OBJPROP_TOOLTIP,"Long MT4 P/L");
   
   SetText ("MT4SellPriceLabel","Sell",x_axis+311,y_axis-19,C'68,68,68',LabelTextSize);
   ObjectSetString(0,"MT4SellPriceLabel",OBJPROP_TOOLTIP,"Short MT4 P/L");
   
   SetPanel("MT4PandLBox",0,x_axis+355,y_axis-28,61,22,clrBlack,clrNONE,1);
   SetText ("MT4PandLText","000.00",x_axis+360,y_axis-24,C'68,68,68',DashTextSize);
   
   SetText ("MT4PipsLabel","Pips",x_axis+418,y_axis-19,C'68,68,68',LabelTextSize);
   ObjectSetString(0,"MT4PipsLabel",OBJPROP_TOOLTIP,"MT4 Pips");

   SetPanel("VertDivider",0,x_axis+460,y_axis-29,2,24,C'85,85,85',C'34,34,34',3);
   
   SetText("FXtLabel","fxTrade",x_axis+476,y_axis-24,clrBlack,HeaderTextSize);
   ObjectSetString(0,"FXtLabel",OBJPROP_TOOLTIP,"fxT Trades");
   
   if (DisplayFXtLotsAsUnits){
      SetText ("FXtLotsLabel","Units",x_axis+581,y_axis-30,C'68,68,68',LabelTextSize);
      ObjectSetString(0,"FXtLotsLabel",OBJPROP_TOOLTIP,"Switch to fxT lots");
   } else { 
      SetText ("FXtLotsLabel","Lots",x_axis+581,y_axis-30,C'68,68,68',LabelTextSize);
      ObjectSetString(0,"FXtLotsLabel",OBJPROP_TOOLTIP,"Switch to fxT units");
   }
   
   SetText ("FXtLotsBuyLabel","Buy",x_axis+557,y_axis-19,C'68,68,68',LabelTextSize);
   if (DisplayFXtLotsAsUnits) ObjectSetString(0,"FXtLotsBuyLabel",OBJPROP_TOOLTIP,"Long fxT units");
   else ObjectSetString(0,"FXtLotsBuyLabel",OBJPROP_TOOLTIP,"Long fxT lots");
   
   SetText ("FXtLotsSellLabel","Sell",x_axis+610,y_axis-19,C'68,68,68',LabelTextSize);
   if (DisplayFXtLotsAsUnits) ObjectSetString(0,"FXtLotsSellLabel",OBJPROP_TOOLTIP,"Short fxT units");
   else ObjectSetString(0,"FXtLotsSellLabel",OBJPROP_TOOLTIP,"Short fxT lots");
   
   SetText ("FXtOrdersLabel","Trades",x_axis+662,y_axis-30,C'68,68,68',LabelTextSize);
   ObjectSetString(0,"FXtOrdersLabel",OBJPROP_TOOLTIP,"fxT orders");
   
   SetText ("FXtOrdersBuyLabel","Buy",x_axis+656,y_axis-19,C'68,68,68',LabelTextSize);
   ObjectSetString(0,"FXtOrdersBuyLabel",OBJPROP_TOOLTIP,"Long fxT orders");
   
   SetText ("FXtOrdersSellLabel","Sell",x_axis+685,y_axis-19,C'68,68,68',LabelTextSize);
   ObjectSetString(0,"FXtOrdersSellLabel",OBJPROP_TOOLTIP,"Short fxT orders");
   
   SetText ("FXtBuyPriceLabel","Buy",x_axis+719,y_axis-19,C'68,68,68',LabelTextSize);
   ObjectSetString(0,"FXtBuyPriceLabel",OBJPROP_TOOLTIP,"Long fxT P/L");
   
   SetText ("FXtSellPriceLabel","Sell",x_axis+771,y_axis-19,C'68,68,68',LabelTextSize);
   ObjectSetString(0,"FXtSellPriceLabel",OBJPROP_TOOLTIP,"Short fxT P/L");
   
   SetText ("FXtFinancing","Swap",x_axis+823,y_axis-19,C'68,68,68',LabelTextSize);
   ObjectSetString(0,"FXtFinancing",OBJPROP_TOOLTIP,"fxT financing");
   
   SetPanel("FXtPandLBox",0,x_axis+877,y_axis-28,61,22,clrBlack,clrNONE,1);
   SetText ("FXtPandLText","000.00",x_axis+882,y_axis-24,C'68,68,68',DashTextSize);

   SetText ("FXtPipsLabel","Pips",x_axis+940,y_axis-19,C'68,68,68',LabelTextSize);
   ObjectSetString(0,"FXtPipsLabel",OBJPROP_TOOLTIP,"fxT pips");
   
   SetText ("FXtUpperMarginLabel","Margin",x_axis+990,y_axis-30,C'68,68,68',LabelTextSize);
   ObjectSetString(0,"FXtUpperMarginLabel",OBJPROP_TOOLTIP,"fxT used margin");
   
   SetText ("FXtLowerMarginLabel","Used",x_axis+993,y_axis-19,C'68,68,68',LabelTextSize);
   ObjectSetString(0,"FXtLowerMarginLabel",OBJPROP_TOOLTIP,"fxT used margin");
   
   UpdateHeader();
}
// --- Draw the dashboard rows
void DrawRows(){
   int y_textPosition;
   int row = 0;
   int subRow = 0;
   int level = 0;
   string showHide, MT4EmptyUnits, FXtEmptyUnits;
   
   if (DisplayMT4LotsAsUnits) MT4EmptyUnits = "000000";
      else MT4EmptyUnits = "0.00";
   
   if (DisplayFXtLotsAsUnits) FXtEmptyUnits = "00000";
      else FXtEmptyUnits = "0.00000";
   
   // Draw each row
   for(int i=0; i<ArraySize(PairInfo); i++){
      
      y_textPosition = (level*DashRowHeight)+y_axis-((26-DashRowHeight)/3);
      
      SetPanel("Row_"+IntegerToString(i),0,x_axis-2,(level*DashRowHeight)+y_axis-5,DashWidth,DashRowHeight-1,clrBlack,clrBlack,1);
      SetPanel("Row_Divider_"+IntegerToString(i),0,x_axis-2,(level*DashRowHeight)+y_axis+DashRowHeight-6,DashWidth,1,C'73,73,73',clrNONE,1);

      if(PairInfo[i].ShowTrades) showHide = "-";
         else showHide = "+";
      SetText("Row_ShowHide_"+IntegerToString(i),showHide,x_axis+2,y_textPosition,clrBlanchedAlmond,DashTextSize);
      if (showHide == "-") ObjectSetString(0,"Row_ShowHide_"+IntegerToString(i),OBJPROP_TOOLTIP,"Hide "+PairInfo[i].Pair+" trades");
      else ObjectSetString(0,"Row_ShowHide_"+IntegerToString(i),OBJPROP_TOOLTIP,"Show "+PairInfo[i].Pair+" trades");
      
      SetText("Row_MT4_Label_"+IntegerToString(i),PairInfo[i].Pair,x_axis+12,y_textPosition,clrBlanchedAlmond,DashTextSize);
      ObjectSetString(0,"Row_MT4_Label_"+IntegerToString(i),OBJPROP_TOOLTIP,PairInfo[i].Pair+"\nTrades: "+IntegerToString(PairInfo[i].MT4TradeCount)+"\nPending: "+IntegerToString(PairInfo[i].MT4PendingOrderCount));
      
      SetText("Row_MT4_LongLots_"+IntegerToString(i),MT4EmptyUnits,x_axis+85,y_textPosition,C'68,68,68',DashTextSize);
      SetText("Row_MT4_ShortLots_"+IntegerToString(i),MT4EmptyUnits,x_axis+145,y_textPosition,C'68,68,68',DashTextSize);
      
      SetText("Row_MT4_OrdersBuy_"+IntegerToString(i),"0",x_axis+202,y_textPosition,C'68,68,68',DashTextSize);
      SetText("Row_MT4_Pending_"+IntegerToString(i),"",x_axis+217,y_textPosition-4,C'68,68,68',DashTextSize-1);
      //SetText("Row_MT4_LongHedge_"+IntegerToString(i),"",x_axis+210,y_textPosition,C'68,68,68',DashTextSize);
      //SetText("Row_MT4_Hedged_"+IntegerToString(i),"",x_axis+215,y_textPosition,C'68,68,68',DashTextSize);
      //SetText("Row_MT4_ShortHedge_"+IntegerToString(i),"",x_axis+224,y_textPosition,C'68,68,68',DashTextSize);
      SetText("Row_MT4_OrdersSell_"+IntegerToString(i),"0",x_axis+231,y_textPosition,C'68,68,68',DashTextSize);
      
      SetText("Row_MT4_BuyPrice_"+IntegerToString(i),"0.00",x_axis+256,y_textPosition,C'68,68,68',DashTextSize);
      SetText("Row_MT4_SellPrice_"+IntegerToString(i),"0.00",x_axis+308,y_textPosition,C'68,68,68',DashTextSize);
      SetText("Row_MT4_ProfitLoss_"+IntegerToString(i),"0.00",x_axis+360,y_textPosition,C'68,68,68',DashTextSize);
      SetText("Row_MT4_Pips_"+IntegerToString(i),"0.0",x_axis+418,y_textPosition,C'68,68,68',DashTextSize);
      
      SetText("Row_FXt_Label_"+IntegerToString(i),PairInfo[i].Pair,x_axis+476,y_textPosition,C'68,68,68',DashTextSize);
      
      SetText("Row_FXt_LongLots_"+IntegerToString(i),FXtEmptyUnits,x_axis+545,y_textPosition,C'68,68,68',DashTextSize);
      SetText("Row_FXt_ShortLots_"+IntegerToString(i),FXtEmptyUnits,x_axis+605,y_textPosition,C'68,68,68',DashTextSize);
      
      SetText("Row_FXt_OrdersBuy_"+IntegerToString(i),"0",x_axis+662,y_textPosition,C'68,68,68',DashTextSize);
      //SetText("Row_FXt_LongHedge_"+IntegerToString(i),"",x_axis+670,y_textPosition,C'68,68,68',DashTextSize);
      SetText("Row_FXt_Pending_"+IntegerToString(i),"",x_axis+677,y_textPosition-4,C'68,68,68',DashTextSize-1);
      //SetText("Row_FXt_ShortHedge_"+IntegerToString(i),"",x_axis+684,y_textPosition,C'68,68,68',DashTextSize);
      SetText("Row_FXt_OrdersSell_"+IntegerToString(i),"0",x_axis+691,y_textPosition,C'68,68,68',DashTextSize);
      
      SetText("Row_FXt_BuyPrice_"+IntegerToString(i),"0.00",x_axis+716,y_textPosition,C'68,68,68',DashTextSize);
      SetText("Row_FXt_SellPrice_"+IntegerToString(i),"0.00",x_axis+768,y_textPosition,C'68,68,68',DashTextSize);
      SetText("Row_FXt_Swap_"+IntegerToString(i),"0.0000",x_axis+820,y_textPosition,C'68,68,68',DashTextSize);
      SetText("Row_FXt_ProfitLoss_"+IntegerToString(i),"0.00",x_axis+882,y_textPosition,C'68,68,68',DashTextSize);
      SetText("Row_FXt_Pips_"+IntegerToString(i),"0.0",x_axis+940,y_textPosition,C'68,68,68',DashTextSize);
      SetText("Row_FXt_Margin_"+IntegerToString(i),"0.00",x_axis+992,y_textPosition,C'68,68,68',DashTextSize);
      
      row++;
      level++;
      
      // is there a subpanel?
      if (PairInfo[i].ShowTrades){
         for(int a = 0; a < (PairInfo[i].MT4TradeCount + PairInfo[i].MT4PendingOrderCount); a++){
            
            y_textPosition = (level*DashRowHeight)+y_axis-((26-DashRowHeight)/3);
            
            SetPanel("SubRow_"+IntegerToString(a)+"_"+IntegerToString(i),0,x_axis-2,(level*DashRowHeight)+y_axis-5,DashWidth,DashRowHeight-1,C'17,17,17',clrBlack,1);
            SetPanel("SubRow_Divider_"+IntegerToString(a)+"_"+IntegerToString(i),0,x_axis-2,(level*DashRowHeight)+y_axis+DashRowHeight-6,DashWidth,1,C'73,73,73',clrNONE,1);

            SetText("SubRow_MT4ID_"+IntegerToString(a)+"_"+IntegerToString(i),"000000000",x_axis+14,y_textPosition,C'68,68,68',DashTextSize);
            
            SetText("SubRow_MT4_LongLots_"+IntegerToString(a)+"_"+IntegerToString(i),MT4EmptyUnits,x_axis+85,y_textPosition,C'68,68,68',DashTextSize);
            SetText("SubRow_MT4_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),MT4EmptyUnits,x_axis+145,y_textPosition,C'68,68,68',DashTextSize);
            
            //SetText("SubRow_MT4_OrdersBuy_"+IntegerToString(a)+"_"+IntegerToString(i),"0",x_axis+202,y_textPosition,C'68,68,68',DashTextSize);
            //SetText("SubRow_MT4_OrdersSell_"+IntegerToString(a)+"_"+IntegerToString(i),"0",x_axis+230,y_textPosition,C'68,68,68',DashTextSize);
            
            SetText("SubRow_MT4_BuyPrice_"+IntegerToString(a)+"_"+IntegerToString(i),"0.00",x_axis+256,y_textPosition,C'68,68,68',DashTextSize);
            SetText("SubRow_MT4_SellPrice_"+IntegerToString(a)+"_"+IntegerToString(i),"0.00",x_axis+308,y_textPosition,C'68,68,68',DashTextSize);
            //SetText("SubRow_MT4_ProfitLoss_"+IntegerToString(a)+"_"+IntegerToString(i),"0.00",x_axis+360,y_textPosition,C'68,68,68',DashTextSize);
            SetText("SubRow_MT4_Pips_"+IntegerToString(a)+"_"+IntegerToString(i),"0.0",x_axis+418,y_textPosition,C'68,68,68',DashTextSize);
            
            
            SetText("SubRow_FXtID_"+IntegerToString(a)+"_"+IntegerToString(i),"000",x_axis+478,y_textPosition,C'68,68,68',DashTextSize);
            
            SetText("SubRow_FXt_LongLots_"+IntegerToString(a)+"_"+IntegerToString(i),FXtEmptyUnits,x_axis+545,y_textPosition,C'68,68,68',DashTextSize);
            SetText("SubRow_FXt_ShortLots_"+IntegerToString(a)+"_"+IntegerToString(i),FXtEmptyUnits,x_axis+605,y_textPosition,C'68,68,68',DashTextSize);
            
            //SetText("SubRow_FXt_OrdersBuy_"+IntegerToString(a)+"_"+IntegerToString(i),"0",x_axis+662,y_textPosition,C'68,68,68',DashTextSize);
            //SetText("SubRow_FXt_OrdersSell_"+IntegerToString(a)+"_"+IntegerToString(i),"0",x_axis+690,y_textPosition,C'68,68,68',DashTextSize);
            
            SetText("SubRow_FXt_BuyPrice_"+IntegerToString(a)+"_"+IntegerToString(i),"0.00",x_axis+716,y_textPosition,C'68,68,68',DashTextSize);
            SetText("SubRow_FXt_SellPrice_"+IntegerToString(a)+"_"+IntegerToString(i),"0.00",x_axis+768,y_textPosition,C'68,68,68',DashTextSize);
            SetText("SubRow_FXt_Swap_"+IntegerToString(a)+"_"+IntegerToString(i),"0.0000",x_axis+820,y_textPosition,C'68,68,68',DashTextSize);
            //SetText("SubRow_FXt_ProfitLoss_"+IntegerToString(a)+"_"+IntegerToString(i),"0.00",x_axis+882,y_textPosition,C'68,68,68',DashTextSize);
            SetText("SubRow_FXt_Pips_"+IntegerToString(a)+"_"+IntegerToString(i),"0.0",x_axis+940,y_textPosition,C'68,68,68',DashTextSize);
            SetText("SubRow_FXt_Margin_"+IntegerToString(a)+"_"+IntegerToString(i),"0.00",x_axis+992,y_textPosition,C'68,68,68',DashTextSize);
            
            level++;
            subRow++;
         }
      }
   }
   UpdateRows();
}
// -- Draw Footer
void DrawFooter(){
   // calculate number open rows
   int numRows = 0;
   for (int i = 0; i < ArraySize(PairInfo); i++){
      if (PairInfo[i].ShowTrades) numRows += (PairInfo[i].MT4TradeCount+PairInfo[i].MT4PendingOrderCount);
      numRows++;
   }
   
   int y_textPosition = (numRows*DashRowHeight)+y_axis-((26-DashRowHeight)/3);
   
   SetPanel("FooterMT4Bar",0,x_axis-2,(numRows*DashRowHeight)+y_axis-5,DashWidth,25,C'34,34,34',clrBlack,1);
   
   SetText ("FooterMT4Pairs","# Pairs",x_axis+12,y_textPosition,C'114,114,114',DashTextSize);
   
   SetText("FooterMT4LongLots","00.00",x_axis+85,y_textPosition,C'114,114,114',DashTextSize);
   SetText("FooterMT4ShortLots","00.00",x_axis+145,y_textPosition,C'114,114,114',DashTextSize);
   
   SetText ("FooterMT4LongOrders","0",x_axis+202,y_textPosition,C'114,114,114',LabelTextSize);
   SetText ("FooterMT4ShortOrders","0",x_axis+230,y_textPosition,C'114,114,114',LabelTextSize);
   
   SetText("FooterMT4LongPrice","0.00",x_axis+256,y_textPosition,C'114,114,114',DashTextSize);
   SetText("FooterMT4ShortPrice","0.00",x_axis+308,y_textPosition,C'114,114,114',DashTextSize);
   SetText("FooterMT4ProfitLoss","0.00",x_axis+360,y_textPosition,C'114,114,114',DashTextSize);
   
   SetText("FooterMT4Pips","0.0",x_axis+418,y_textPosition,C'114,114,114',DashTextSize);
   
   SetText("FooterFXtLongLots","00000",x_axis+545,y_textPosition,C'114,114,114',DashTextSize);
   SetText("FooterFXtShortLots","00000",x_axis+605,y_textPosition,C'114,114,114',DashTextSize);
   
   SetText ("FooterFXtLongOrders","0",x_axis+662,y_textPosition,C'114,114,114',LabelTextSize);
   SetText ("FooterFXtShortOrders","0",x_axis+690,y_textPosition,C'114,114,114',LabelTextSize);
   
   SetText("FooterFXtLongPrice","0.00",x_axis+716,y_textPosition,C'114,114,114',DashTextSize);
   SetText("FooterFXtShortPrice","0.00",x_axis+768,y_textPosition,C'114,114,114',DashTextSize);
   SetText("FooterFXtProfitLoss","0.00",x_axis+882,y_textPosition,C'114,114,114',DashTextSize);
   
   SetText("FooterFXtFinancing","0.0000",x_axis+820,y_textPosition,C'114,114,114',DashTextSize);
   
   SetText("FooterFXtPips","0.0",x_axis+940,y_textPosition,C'114,114,114',DashTextSize);
   SetText("FooterFXtMargin","0.00",x_axis+992,y_textPosition,C'114,114,114',DashTextSize);
   
   UpdateFooter();
}

//================================================//
// Draw Panel on Chart                            //
//================================================//
void SetPanel(string name,int sub_window,int x,int y,int width,int height,color bg_color,color border_clr,int border_width){
   if(ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,sub_window,0,0)){
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(0,name,OBJPROP_XSIZE,width);
      ObjectSetInteger(0,name,OBJPROP_YSIZE,height);
      ObjectSetInteger(0,name,OBJPROP_COLOR,border_clr);
      ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,name,OBJPROP_WIDTH,border_width);
      ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_SOLID);
      ObjectSetInteger(0,name,OBJPROP_BACK,true);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,0);
      ObjectSetInteger(0,name,OBJPROP_SELECTED,0);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,name,OBJPROP_ZORDER,0);
   }
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,bg_color);
}

void ColorPanel(string name,color bg_color,color border_clr){
   ObjectSetInteger(0,name,OBJPROP_COLOR,border_clr);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,bg_color);
}

void SetText(string name,string text,int x,int y,color colour,int fontsize=12, string font="arial"){
   if (ObjectFind(0,name)<0)
      ObjectCreate(0,name,OBJ_LABEL,0,0,0);

    ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
    ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
    ObjectSetInteger(0,name,OBJPROP_COLOR,colour);
    ObjectSetInteger(0,name,OBJPROP_FONTSIZE,fontsize);
    ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
    ObjectSetString(0,name,OBJPROP_FONT,font);
    ObjectSetString(0,name,OBJPROP_TEXT,text);
}
//================================================//
// Draw Bitmap on chart                           //
//================================================//
bool BitmapCreate(const string            name,
                  const string            image,
                  const int               x=0,
                  const int               y=0,
                  const long              chart_ID=0,
                  const bool              hidden=false)
  {
//--- reset the error value
   ResetLastError();
//--- create the button
   if(!ObjectCreate(chart_ID,name,OBJ_BITMAP_LABEL,0,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create the button! Error code = ",GetLastError());
      return(false);
     }
//--- set button coordinates
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
   ObjectSetString(0,name,OBJPROP_BMPFILE,0,image);
   if (hidden) ObjectSetInteger(0,name,OBJPROP_XSIZE,-1);
   return(true);
}
//================================================//
// Button Presses                                //
//================================================//
void OnChartEvent(const int id,  const long &lparam, const double &dparam,  const string &sparam){
   int pairID;
   string rawPairID;
   
   if(id==CHARTEVENT_OBJECT_CLICK){
      
      // A row has been clicked
      if (StringSubstr(sparam,0,3) == "Row"){
         rawPairID = StringSubstr(sparam,StringLen(sparam)-2,2);
         StringReplace(rawPairID, "_", "");// remove underscore if present for row ID's smaller than 10
         pairID = int(StringToInteger(rawPairID));
         PairInfo[pairID].ShowTrades = !PairInfo[pairID].ShowTrades;
         DrawDash();
      }
      
      // MT4 Units to Lots
      if (sparam == "MT4LotsLabel"){
         DisplayMT4LotsAsUnits = !DisplayMT4LotsAsUnits;
         DrawDash();
      }
      
      // FXt Units to Lots
      if (sparam == "FXtLotsLabel"){
         DisplayFXtLotsAsUnits = !DisplayFXtLotsAsUnits;
         DrawDash();
      }
      
      // Toggle show all trades
      if (StringSubstr(sparam,0,8) == "ShowAll_"){
         ShowAllTrades = !ShowAllTrades;
         for(int i=0; i<ArraySize(PairInfo); i++){
            if (ShowAllTrades) PairInfo[i].ShowTrades = true;
               else  PairInfo[i].ShowTrades = false;
         }
         DrawDash();
      }
   }
}

//================================================//
// Workaround to look for unique pairs in array   //
//================================================//
int PairToInt(string pair){
        if (pair == "AUDCAD") return 1;
   else if (pair == "AUDCHF") return 2;
   else if (pair == "AUDHKD") return 3;
   else if (pair == "AUDJPY") return 4;
   else if (pair == "AUDNZD") return 5;
   else if (pair == "AUDSGD") return 6;
   else if (pair == "AUDUSD") return 7;
   else if (pair == "CADCHF") return 8;
   else if (pair == "CADHKD") return 9;
   else if (pair == "CADJPY") return 10;
   else if (pair == "CADSGD") return 11;
   else if (pair == "CHFHKD") return 12;
   else if (pair == "CHFJPY") return 13;
   else if (pair == "CHFZAR") return 14;
   else if (pair == "EURAUD") return 15;
   else if (pair == "EURCAD") return 16;
   else if (pair == "EURCHF") return 17;
   else if (pair == "EURCZK") return 18;
   else if (pair == "EURDKK") return 19;
   else if (pair == "EURGBP") return 20;
   else if (pair == "EURHKD") return 21;
   else if (pair == "EURHUF") return 22;
   else if (pair == "EURJPY") return 23;
   else if (pair == "EURNOK") return 24;
   else if (pair == "EURNZD") return 25;
   else if (pair == "EURPLN") return 26;
   else if (pair == "EURSEK") return 27;
   else if (pair == "EURSGD") return 28;
   else if (pair == "EURTRY") return 29;
   else if (pair == "EURUSD") return 30;
   else if (pair == "EURZAR") return 31;
   else if (pair == "GBPAUD") return 32;
   else if (pair == "GBPCAD") return 33;
   else if (pair == "GBPCHF") return 34;
   else if (pair == "GBPHKD") return 35;
   else if (pair == "GBPJPY") return 36;
   else if (pair == "GBPNZD") return 37;
   else if (pair == "GBPPLN") return 38;
   else if (pair == "GBPSGD") return 39;
   else if (pair == "GBPUSD") return 40;
   else if (pair == "GBPZAR") return 41;
   else if (pair == "HKDJPY") return 42;
   else if (pair == "NZDCAD") return 43;
   else if (pair == "NZDCHF") return 44;
   else if (pair == "NZDHKD") return 45;
   else if (pair == "NZDJPY") return 46;
   else if (pair == "NZDSGD") return 47;
   else if (pair == "NZDUSD") return 48;
   else if (pair == "SGDCHF") return 49;
   else if (pair == "SGDHKD") return 50;
   else if (pair == "SGDJPY") return 51;
   else if (pair == "TRYJPY") return 52;
   else if (pair == "USDCAD") return 53;
   else if (pair == "USDCHF") return 54;
   else if (pair == "USDCNH") return 55;
   else if (pair == "USDCZK") return 56;
   else if (pair == "USDDKK") return 57;
   else if (pair == "USDHKD") return 58;
   else if (pair == "USDHUF") return 59;
   else if (pair == "USDJPY") return 60;
   else if (pair == "USDMXN") return 61;
   else if (pair == "USDNOK") return 62;
   else if (pair == "USDPLN") return 63;
   else if (pair == "USDSAR") return 64;
   else if (pair == "USDSEK") return 65;
   else if (pair == "USDSGD") return 66;
   else if (pair == "USDTHB") return 67;
   else if (pair == "USDTRY") return 68;
   else if (pair == "USDZAR") return 69;
   else if (pair == "ZARJPY") return 70;
   else return -1;
}

string IntToPair(int pair){
        if (pair == 1 ) return "AUDCAD";
   else if (pair == 2 ) return "AUDCHF";
   else if (pair == 3 ) return "AUDHKD";
   else if (pair == 4 ) return "AUDJPY";
   else if (pair == 5 ) return "AUDNZD";
   else if (pair == 6 ) return "AUDSGD";
   else if (pair == 7 ) return "AUDUSD";
   else if (pair == 8 ) return "CADCHF";
   else if (pair == 9 ) return "CADHKD";
   else if (pair == 10) return "CADJPY";
   else if (pair == 11) return "CADSGD";
   else if (pair == 12) return "CHFHKD";
   else if (pair == 13) return "CHFJPY";
   else if (pair == 14) return "CHFZAR";
   else if (pair == 15) return "EURAUD";
   else if (pair == 16) return "EURCAD";
   else if (pair == 17) return "EURCHF";
   else if (pair == 18) return "EURCZK";
   else if (pair == 19) return "EURDKK";
   else if (pair == 20) return "EURGBP";
   else if (pair == 21) return "EURHKD";
   else if (pair == 22) return "EURHUF";
   else if (pair == 23) return "EURJPY";
   else if (pair == 24) return "EURNOK";
   else if (pair == 25) return "EURNZD";
   else if (pair == 26) return "EURPLN";
   else if (pair == 27) return "EURSEK";
   else if (pair == 28) return "EURSGD";
   else if (pair == 29) return "EURTRY";
   else if (pair == 30) return "EURUSD";
   else if (pair == 31) return "EURZAR";
   else if (pair == 32) return "GBPAUD";
   else if (pair == 33) return "GBPCAD";
   else if (pair == 34) return "GBPCHF";
   else if (pair == 35) return "GBPHKD";
   else if (pair == 36) return "GBPJPY";
   else if (pair == 37) return "GBPNZD";
   else if (pair == 38) return "GBPPLN";
   else if (pair == 39) return "GBPSGD";
   else if (pair == 40) return "GBPUSD";
   else if (pair == 41) return "GBPZAR";
   else if (pair == 42) return "HKDJPY";
   else if (pair == 43) return "NZDCAD";
   else if (pair == 44) return "NZDCHF";
   else if (pair == 45) return "NZDHKD";
   else if (pair == 46) return "NZDJPY";
   else if (pair == 47) return "NZDSGD";
   else if (pair == 48) return "NZDUSD";
   else if (pair == 49) return "SGDCHF";
   else if (pair == 50) return "SGDHKD";
   else if (pair == 51) return "SGDJPY";
   else if (pair == 52) return "TRYJPY";
   else if (pair == 53) return "USDCAD";
   else if (pair == 54) return "USDCHF";
   else if (pair == 55) return "USDCNH";
   else if (pair == 56) return "USDCZK";
   else if (pair == 57) return "USDDKK";
   else if (pair == 58) return "USDHKD";
   else if (pair == 59) return "USDHUF";
   else if (pair == 60) return "USDJPY";
   else if (pair == 61) return "USDMXN";
   else if (pair == 62) return "USDNOK";
   else if (pair == 63) return "USDPLN";
   else if (pair == 64) return "USDSAR";
   else if (pair == 65) return "USDSEK";
   else if (pair == 66) return "USDSGD";
   else if (pair == 67) return "USDTHB";
   else if (pair == 68) return "USDTRY";
   else if (pair == 69) return "USDZAR";
   else if (pair == 70) return "ZARJPY";
   else return "";
}

//================================================//
// US Margin Requirements                         //
//================================================//
double GetPairMarginRequired(string Pair){
        if (Pair == "AUDCAD") return 3.0;
   else if (Pair == "AUDCHF") return 3.0;
   else if (Pair == "AUDHKD") return 5.0;
   else if (Pair == "AUDJPY") return 4.0;
   else if (Pair == "AUDNZD") return 3.0;
   else if (Pair == "AUDSGD") return 5.0;
   else if (Pair == "AUDUSD") return 3.0;
   else if (Pair == "CADCHF") return 3.0;
   else if (Pair == "CADHKD") return 5.0;
   else if (Pair == "CADJPY") return 4.0;
   else if (Pair == "CADSGD") return 5.0;
   else if (Pair == "CHFHKD") return 5.0;
   else if (Pair == "CHFJPY") return 4.0;
   else if (Pair == "CHFZAR") return 7.0;
   else if (Pair == "EURAUD") return 3.0;
   else if (Pair == "EURCAD") return 2.0;
   else if (Pair == "EURCHF") return 3.0;
   else if (Pair == "EURCZK") return 5.0;
   else if (Pair == "EURDKK") return 2.0;
   else if (Pair == "EURGBP") return 5.0;
   else if (Pair == "EURHKD") return 5.0;
   else if (Pair == "EURHUF") return 5.0;
   else if (Pair == "EURJPY") return 4.0;
   else if (Pair == "EURNOK") return 3.0;
   else if (Pair == "EURNZD") return 3.0;
   else if (Pair == "EURPLN") return 5.0;
   else if (Pair == "EURSEK") return 3.0;
   else if (Pair == "EURSGD") return 5.0;
   else if (Pair == "EURTRY") return 12.0;
   else if (Pair == "EURUSD") return 2.0;
   else if (Pair == "EURZAR") return 7.0;
   else if (Pair == "GBPAUD") return 5.0;
   else if (Pair == "GBPCAD") return 5.0;
   else if (Pair == "GBPCHF") return 5.0;
   else if (Pair == "GBPHKD") return 5.0;
   else if (Pair == "GBPJPY") return 5.0;
   else if (Pair == "GBPNZD") return 5.0;
   else if (Pair == "GBPPLN") return 5.0;
   else if (Pair == "GBPSGD") return 5.0;
   else if (Pair == "GBPUSD") return 5.0;
   else if (Pair == "GBPZAR") return 7.0;
   else if (Pair == "HKDJPY") return 5.0;
   else if (Pair == "NZDCAD") return 3.0;
   else if (Pair == "NZDCHF") return 3.0;
   else if (Pair == "NZDHKD") return 5.0;
   else if (Pair == "NZDJPY") return 4.0;
   else if (Pair == "NZDSGD") return 5.0;
   else if (Pair == "NZDUSD") return 3.0;
   else if (Pair == "SGDCHF") return 5.0;
   else if (Pair == "SGDHKD") return 5.0;
   else if (Pair == "SGDJPY") return 5.0;
   else if (Pair == "TRYJPY") return 12.0;
   else if (Pair == "USDCAD") return 2.0;
   else if (Pair == "USDCHF") return 3.0;
   else if (Pair == "USDCNH") return 5.0;
   else if (Pair == "USDCZK") return 5.0;
   else if (Pair == "USDDKK") return 2.0;
   else if (Pair == "USDHKD") return 5.0;
   else if (Pair == "USDHUF") return 5.0;
   else if (Pair == "USDJPY") return 4.0;
   else if (Pair == "USDMXN") return 8.0;
   else if (Pair == "USDNOK") return 3.0;
   else if (Pair == "USDPLN") return 5.0;
   else if (Pair == "USDSAR") return 5.0;
   else if (Pair == "USDSEK") return 3.0;
   else if (Pair == "USDSGD") return 5.0;
   else if (Pair == "USDTHB") return 5.0;
   else if (Pair == "USDTRY") return 12.0;
   else if (Pair == "USDZAR") return 7.0;
   else if (Pair == "ZARJPY") return 7.0;
   else return 0.0;
}

bool InitOK(){

   // Is folder name set
   if (FolderName == ""){
      ConfigErrorMessage = "DITTO CONFIG ERROR: You Must Define a System Name";
      return false;
   }

   // is the first account defined?
   if (FirstAccount == ""){
      ConfigErrorMessage = "DITTO CONFIG ERROR: The First Account Must be Defined";
      return false;
   }

   // is the API key defined?
   if (APIKey == ""){
      ConfigErrorMessage = "DITTO CONFIG ERROR: The API Key Must be Defined";
      return false;
   }

   // Does the folder exist?
   string folderName = "Ditto\\"+FolderName;

   if(!FileIsExist(folderName+"\\config.ini")){
      FolderCreate(folderName);
      FolderClean(folderName);
   } else {
      if (!FileIsExist(folderName+"\\"+FirstAccount)){
         ConfigErrorMessage = "DITTO CONFIG ERROR: System Name Already In Use";
         DeleteSystemFolder = false;
         return false;
      }
   }
   
   // Write acct# in case of crash
   int handle = FileOpen(folderName+"\\"+FirstAccount,FILE_READ|FILE_WRITE|FILE_TXT);
   FileClose(handle);
   
   ConfigErrorMessage = "";
   return true;
}

bool StatusOK(){
   
   // check for error.txt
   string errorFile = "Ditto\\"+FolderName+"\\error.txt";
   if (FileIsExist(errorFile)){
      int fileHandle;
      
      // read error message
      fileHandle = FileOpen(errorFile,FILE_READ|FILE_TXT);
      string msg = FileReadString(fileHandle);
      FileClose(fileHandle);

      if (msg == "{\"errorMessage\":\"Insufficient authorization to perform request.\"}") ErrorMessage = "Status: ERROR: API Key Provided is Incorrect";
      else if (msg == "{\"errorMessage\":\"The provided request was forbidden.\"}") ErrorMessage = "Status: ERROR: Invalid Account Number Provided";
      else if (msg == "{\"errorMessage\":\"Invalid value specified for 'accountID'\"}") ErrorMessage = "Status: ERROR: Invalid Account Number Provided";
      else ErrorMessage = "Status: ERROR: Check Account Details";
      return false;
   }
   
   // does the config file exist?
   if (FileIsExist("Ditto\\"+FolderName+"\\config.ini") != true){
      ErrorMessage = "Status: ERROR: The Config File Does Not Exist";
      return false;
   }

   int SecondsDown = 2; // number of seconds dittoLink down before displaying error message
   // All trade activity is ceased if the Python script is not running.
   if (FileIsExist(LockFilename) != true){ // Wait for python to finish
      if (!FileIsExist(AliveFileName)){
         AliveSeconds++;
         if (AliveSeconds >= SecondsDown){
            ErrorMessage = "Status: ERROR: DittoLink not monitoring this dash.";
            return false;
         }
      }
   }
   
   // Verify Python script still running by deleting the alive check file every 5 seconds   
   if (AliveTimer % 5 == 0){
      AliveTimer = 0;
      AliveSeconds = 0;
      FileDelete(AliveFileName);
   }
   AliveTimer++;

   ErrorMessage = "";
   return true;
}

bool CreateConfigFile(){
   int handle;
   string liveAccount;
   string filename = "Ditto\\"+FolderName+"\\config.ini";

   if (AccountType == 0) liveAccount = "False";
      else liveAccount = "True";

   // delete the current file if it exists to erase any previous data
   FileDelete(filename);

   // check if required info is present
   if ((FirstAccount != "")&&(APIKey != "")){

      // write file
      handle = FileOpen(filename,FILE_READ|FILE_WRITE|FILE_TXT);
      
      if(handle!=INVALID_HANDLE){
         string DataString = "[settings]\nsystem_name = "+FolderName+"\nfirst_account_id = "+FirstAccount+"\nsecond_account_id = "+SecondAccount+"\ntoken = "+APIKey+"\nlive_trading = "+liveAccount;
         FileWriteString(handle, DataString);
      } else return false;
      
      FileClose(handle);
      return true;
      
   } else return false;
}

string CleanFolderName(string str){
  StringReplace(str,"<","");
  StringReplace(str,">","");
  StringReplace(str,":","");
  StringReplace(str,"\"","");
  StringReplace(str,"/","");
  StringReplace(str,"\\","");
  StringReplace(str,"|","");
  StringReplace(str,"?","");
  StringReplace(str,"*","");
  //StringReplace(str," ","");
  return(str);
}