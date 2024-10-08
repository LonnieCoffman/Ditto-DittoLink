//+------------------------------------------------------------------+
//|                                                         temp.mq4 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//|                                                  Protect-002.mq4 |
//|                                Copyright © 2009, Sergey Kravchuk |
//|                                         http://forextools.com.ua |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2009, Sergey Kravchuk"
#property link      "http://forextools.com.ua"

#property show_inputs

extern string prefix = "char";
extern string text   = "2009.09.11 23:59:00";
string rez           = ""; // here we will assemble the result

int start()
{
  // enter the original text to see what this string is
  rez = text; 
  //2009.09.11 23:59:00
  for (int i = 0; i < StringLen(text); i++) 
   rez = rez + StringGetChar(text, i) + ",";
  
  // cut the last '+' character and print string to the log
  Print(text+" = "+StringSubstr(rez, StringLen(text), StringLen(rez)));
  return(0);
}