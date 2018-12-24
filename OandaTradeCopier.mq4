//+------------------------------------------------------------------+
//|                                             OandaTradeCopier.mq4 |
//|                                                   Lonnie Coffman |
//|                                 https://github.com/LonnieCoffman |
//+------------------------------------------------------------------+
#property copyright "Lonnie Coffman"
#property link      "https://github.com/LonnieCoffman"
#property version   "1.00"
#property strict


/*
   
   // example data file
   // 203712197-8117,
   //  (mt4)    (fx)
   
   // Monitor MT4 trades
   //
   // IF NEW TRADE
   // -- place trade with FXtrade
   // -- record trade in data file mt4 id / fxtrade id
   
*/

// Pair Struct
struct pairinf {
   string         Pair;
   string         FXtradeName;
   string         Trades[];          
}; pairinf PairInfo[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
   // create timer
   EventSetTimer(1);

   ArrayResize(PairInfo,1);
   ArrayResize(PairInfo[0].Trades,6);

   // dummy data
   PairInfo[0].Pair = "EURUSD";
   PairInfo[0].FXtradeName = "EUR_USD";
   PairInfo[0].Trades[0] = "203712197-8110";
   PairInfo[0].Trades[1] = "203712197-8111";
   PairInfo[0].Trades[2] = "203712197-8112";
   PairInfo[0].Trades[3] = "203712197-8113";
   PairInfo[0].Trades[4] = "203712197-8114";
   PairInfo[0].Trades[5] = "203712197-8115";
   
   // Remove leftover objects and set colors
   CleanChart();
   
   WriteTradeArray(PairInfo[0].Pair, PairInfo[0].Trades);
   ReadTradeArray(PairInfo[0].Pair);
   
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
   
   
}
//+------------------------------------------------------------------+
//================================================//
// Write Trade Array to data file                 //
//================================================//
void WriteTradeArray(string Pair, string &TradesArray[]){
   int handle;
   string filename = "TradeCopier\\data-"+Pair+".txt";

   // delete the current file if it exists to erase any previous data
   FileDelete(filename);

   // write file
   handle = FileOpen(filename,FILE_READ|FILE_WRITE|FILE_TXT);
   
   if(handle!=INVALID_HANDLE){
      FileWriteArray(handle, TradesArray);
   }
   FileClose(handle);
}

//================================================//
// Read Trade Array from data file                //
//================================================//
void ReadTradeArray(string Pair){
   int handle;
   string filename = "TradeCopier\\data-"+Pair+".txt";
   string tempArr[];
   
   // read file
   if (FileIsExist(filename)){
      handle = FileOpen(filename,FILE_READ|FILE_TXT);
      FileReadArray(handle, tempArr);
      FileClose(handle);
   }

   for(int i = 0; i < ArraySize(tempArr); i++){
      Print(tempArr[i]);
   } 
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