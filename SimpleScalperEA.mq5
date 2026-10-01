#property strict

#include <Trade\Trade.mqh>

CTrade trade;

input bool EnableEA = true;
input double LotSize = 0.10;
input int MagicNumber = 20260401;
input int Slippage = 30;
input int StopLossPoints = 25;
input int TakeProfitPoints = 45;
input int FastMAPeriod = 12;
input int SlowMAPeriod = 26;
input int RSIPeriod = 14;
input double MaxSpreadPoints = 0.8;
input bool UseTrailingStop = true;
input int TrailingStopPoints = 15;

string START_STOP_BUTTON = "BTN_START_STOP";
string g_symbols[];

int OnInit()
{
   ArrayResize(g_symbols, 2);
   g_symbols[0] = "EURUSD";
   g_symbols[1] = "XAUUSD";

   CreateStartStopButton();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   ObjectDelete(0, START_STOP_BUTTON);
}

void OnTick()
{
   if(!EnableEA)
      return;

   for(int i = 0; i < ArraySize(g_symbols); i++)
   {
      string symbol = g_symbols[i];
      if(!IsSymbolAllowed(symbol))
         continue;

      if(HasOpenPosition(symbol))
      {
         if(UseTrailingStop)
            ApplyTrailingStop(symbol);
         continue;
      }

      if(!IsTradeAllowed(symbol))
         continue;

      int signal = GetSignal(symbol);
      if(signal == 1)
         OpenTrade(symbol, ORDER_TYPE_BUY);
      else if(signal == -1)
         OpenTrade(symbol, ORDER_TYPE_SELL);
   }
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == START_STOP_BUTTON)
   {
      EnableEA = !EnableEA;
      UpdateButtonState();
   }
}

void CreateStartStopButton()
{
   if(ObjectFind(0, START_STOP_BUTTON) != -1)
      ObjectDelete(0, START_STOP_BUTTON);

   long chart_id = 0;
   int sub_window = 0;
   int x = 20;
   int y = 20;
   int width = 120;
   int height = 28;

   if(!ObjectCreate(chart_id, START_STOP_BUTTON, OBJ_BUTTON, sub_window, 0, 0))
   {
      Print("Failed to create start/stop button");
      return;
   }

   ObjectSetInteger(chart_id, START_STOP_BUTTON, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(chart_id, START_STOP_BUTTON, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(chart_id, START_STOP_BUTTON, OBJPROP_XSIZE, width);
   ObjectSetInteger(chart_id, START_STOP_BUTTON, OBJPROP_YSIZE, height);
   ObjectSetString(chart_id, START_STOP_BUTTON, OBJPROP_TEXT, EnableEA ? "STOP" : "START");
   ObjectSetInteger(chart_id, START_STOP_BUTTON, OBJPROP_BGCOLOR, EnableEA ? clrDarkGreen : clrFireBrick);
   ObjectSetInteger(chart_id, START_STOP_BUTTON, OBJPROP_COLOR, clrWhite);
   ObjectSetString(chart_id, START_STOP_BUTTON, OBJPROP_FONT, "Arial");
   ObjectSetInteger(chart_id, START_STOP_BUTTON, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(chart_id, START_STOP_BUTTON, OBJPROP_BORDER_TYPE, BORDER_FLAT);
}

void UpdateButtonState()
{
   if(ObjectFind(0, START_STOP_BUTTON) == -1)
      return;

   ObjectSetString(0, START_STOP_BUTTON, OBJPROP_TEXT, EnableEA ? "STOP" : "START");
   ObjectSetInteger(0, START_STOP_BUTTON, OBJPROP_BGCOLOR, EnableEA ? clrDarkGreen : clrFireBrick);
}

bool IsSymbolAllowed(string symbol)
{
   if(!SymbolSelect(symbol, true))
      return false;

   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   if(!isNormalDouble(ask) || !isNormalDouble(bid))
      return false;

   double spread = (ask - bid) / GetPointSize(symbol);
   if(spread > MaxSpreadPoints)
      return false;

   return true;
}

bool IsTradeAllowed(string symbol)
{
   MqlTradeRequest req = {};
   MqlTradeResult res = {};
   return true;
}

int GetSignal(string symbol)
{
   ENUM_TIMEFRAMES tf = PERIOD_M5;
   double fastMA = iMA(symbol, tf, FastMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
   double slowMA = iMA(symbol, tf, SlowMAPeriod, 0, MODE_SMA, PRICE_CLOSE, 0);
   double rsi = iRSI(symbol, tf, RSIPeriod, PRICE_CLOSE, 0);

   double prevFastMA = iMA(symbol, tf, FastMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
   double prevSlowMA = iMA(symbol, tf, SlowMAPeriod, 0, MODE_SMA, PRICE_CLOSE, 1);
   double prevRSI = iRSI(symbol, tf, RSIPeriod, PRICE_CLOSE, 1);

   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double close = (bid + ask) / 2.0;

   bool longCondition = (fastMA > slowMA) && (prevFastMA <= prevSlowMA) && (rsi > 50) && (prevRSI <= 50) && (close > fastMA);
   bool shortCondition = (fastMA < slowMA) && (prevFastMA >= prevSlowMA) && (rsi < 50) && (prevRSI >= 50) && (close < fastMA);

   if(longCondition) return 1;
   if(shortCondition) return -1;
   return 0;
}

void OpenTrade(string symbol, int orderType)
{
   double price = 0;
   double stopLoss = 0;
   double takeProfit = 0;

   if(orderType == ORDER_TYPE_BUY)
   {
      price = SymbolInfoDouble(symbol, SYMBOL_ASK);
      stopLoss = price - StopLossPoints * GetPointSize(symbol);
      takeProfit = price + TakeProfitPoints * GetPointSize(symbol);
   }
   else if(orderType == ORDER_TYPE_SELL)
   {
      price = SymbolInfoDouble(symbol, SYMBOL_BID);
      stopLoss = price + StopLossPoints * GetPointSize(symbol);
      takeProfit = price - TakeProfitPoints * GetPointSize(symbol);
   }
   else
      return;

   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(Slippage);
   trade.SetTypeFilling(ORDER_FILLING_FOK);

   bool result = false;
   if(orderType == ORDER_TYPE_BUY)
      result = trade.Buy(LotSize, symbol, price, stopLoss, takeProfit, "SimpleScalperEA");
   else if(orderType == ORDER_TYPE_SELL)
      result = trade.Sell(LotSize, symbol, price, stopLoss, takeProfit, "SimpleScalperEA");

   if(!result)
      Print("Order failed for ", symbol, ": ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
}

bool HasOpenPosition(string symbol)
{
   for(int i = 0; i < PositionsTotal(); i++)
   {
      string posTicket = IntegerToString(PositionGetTicket(i));
      if(!PositionSelectByTicket(StringToInteger(posTicket)))
         continue;

      string posSymbol = PositionGetString(POSITION_SYMBOL);
      if(posSymbol == symbol && PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         return true;
   }
   return false;
}

void ApplyTrailingStop(string symbol)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) != symbol)
         continue;

      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;

      int type = (int)PositionGetInteger(POSITION_TYPE);
      double pointSize = GetPointSize(symbol);
      double currentPrice = (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_BID) : SymbolInfoDouble(symbol, SYMBOL_ASK);
      double currentStop = PositionGetDouble(POSITION_SL);
      double newStop = 0.0;

      if(type == POSITION_TYPE_BUY)
      {
         newStop = currentPrice - TrailingStopPoints * pointSize;
         if(currentStop < newStop || currentStop == 0)
         {
            trade.PositionModify(ticket, newStop, PositionGetDouble(POSITION_TP));
         }
      }
      else if(type == POSITION_TYPE_SELL)
      {
         newStop = currentPrice + TrailingStopPoints * pointSize;
         if(currentStop > newStop || currentStop == 0)
         {
            trade.PositionModify(ticket, newStop, PositionGetDouble(POSITION_TP));
         }
      }
   }
}

double GetPointSize(string symbol)
{
   double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(point <= 0)
      point = tickSize;
   return point;
}

bool isNormalDouble(double value)
{
   return (value != 0 && !MathIsNaN(value) && !MathIsInf(value));
}

string GetOrderTypeName(int type)
{
   switch(type)
   {
      case ORDER_TYPE_BUY: return "BUY";
      case ORDER_TYPE_SELL: return "SELL";
      default: return "UNKNOWN";
   }
}

void OnTimer()
{
   // Optional future enhancement
}

int OnTester()
{
   return 0;
}
