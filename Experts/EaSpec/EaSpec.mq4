//+------------------------------------------------------------------+
//|                                         Zones.mq4 |
//|                                               NOEL M NGUEMECHIEU |
//|              https://github.com/nguemechieu/Zones |
//+------------------------------------------------------------------+
#property strict

#property copyright "Copyright 2023. techexpert-solution .inc"
#property link      "https://github.com/nguemechieu/easpec"
//--- includes
#include <DoEasy\Engine.mqh>
#ifdef __MQL5__
#include <Trade\Trade.mqh>
#endif 
#include <DiscordTelegram/jason.mqh>
#include <DiscordTelegram\Common.mqh>
input string backendUrl="https://bynrhumc70.execute-api.us-east-1.amazonaws.com/prod/FRED";//BACK END URL
input double  my_current_rate =5;// my-current-rate 








input string ss21;//======= CHART COLOR ==========
input color BullCandle=clrGreen;
input color BearCandle =clrRed;
input color Bear_Outline =clrWhite;
input color Bull_Outline=clrAliceBlue;
input color BackGround =clrBlack;
input color ForeGround =clrAquamarine;

//--- enums
enum ENUM_BUTTONS
  {
   BUTT_BUY,
   BUTT_BUY_LIMIT,
   BUTT_BUY_STOP,
   BUTT_BUY_STOP_LIMIT,
   BUTT_CLOSE_BUY,
   BUTT_CLOSE_BUY2,
   BUTT_CLOSE_BUY_BY_SELL,
   BUTT_SELL,
   BUTT_SELL_LIMIT,
   BUTT_SELL_STOP,
   BUTT_SELL_STOP_LIMIT,
   BUTT_CLOSE_SELL,
   BUTT_CLOSE_SELL2,
   BUTT_CLOSE_SELL_BY_BUY,
   BUTT_DELETE_PENDING,
   BUTT_CLOSE_ALL,
   BUTT_PROFIT_WITHDRAWAL,
   BUTT_SET_STOP_LOSS,
   BUTT_SET_TAKE_PROFIT,
   BUTT_TRAILING_ALL
  };
#define TOTAL_BUTT   (20)
//--- structures
struct SDataButt
  {
   string      name;
   string      text;
  };




struct sNews
  {
   datetime          dTime;
   string            time;
   string            currency;
   string            importance;
   string            news;
   string            Actual;
   string            forecast;
   string            previus;
  };

//--- input variables
input int            InpMagic             =  123;  // Magic number
input double            InpLots              =  0.1;  // Lots
input uint              InpStopLoss          =  100;   // StopLoss in points
input uint              InpTakeProfit        =  100;   // TakeProfit in points
input uint              InpDistance          =  15;   // Pending orders distance (points)
input uint              InpDistanceSL        =  100;   // StopLimit orders distance (points)

input uint MaxOpenOrder=50;
input bool               NEWS_FILTER               =true;
input bool               NEWS_IMPOTANCE_LOW        =true;
input bool               NEWS_IMPOTANCE_MEDIUM     =true;
input bool               NEWS_IMPOTANCE_HIGH       =true;
input int                STOP_BEFORE_NEWS          =60;
input int                START_AFTER_NEWS          =60;
input string             Currencies_Check          ="USD,EUR,CAD,AUD,NZD,GBP";
input bool               Check_Specific_News       =false;
input string             Specific_News_Text        ="FOMC";
input bool               DRAW_NEWS_CHART           = true;

input string             News_Font                 ="Arial";
input color              Font_Color                =clrRed;
input bool               DRAW_NEWS_LINES           =true;
input color              Line_Color                =clrRed;
input ENUM_LINE_STYLE    Line_Style                =STYLE_DOT;
input int                Line_Width                =2;

int Font_Size=12;
string LANG="en-US";
sNews NEWS_TABLE[],HEADS;
datetime date;
int TIME_CORRECTION,NEWS_ON=0;
double current_rate=0;


//
//Trade instructions. 
//
//if  api-current-rate is greater than  my-current-rate then 
// toggle / go long or go short. user decides i.e user tic box
//if  api-current-rate is less than  my-current-rate then 
// toggle / go long or go short. user decides i.e user tic box
//
//effectively i want to give this EA 2 different trades and depending on the news release results the EA will make that trade accordingly
//
//I want it to only do something when there is a change. if the values are the same then just keep checking. 1000 api calls per second max.
//
//Once a change happens, make one trade only


string getDirection(){


if(getCurrencyRate(Symbol())> my_current_rate ){
printf("GO LONG");

return "GO LONG";

}else    if(getCurrencyRate(Symbol())<my_current_rate)  {

printf("Go SHORT");
return "GO SHORT";

}
return "";

}
 

  void   OnTimer(){
  OnTick();}
  
  

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ChartColorSet()//set chart colors
  {
   ChartSetInteger(ChartID(), CHART_COLOR_ASK, BearCandle);
   ChartSetInteger(ChartID(), CHART_COLOR_BID, clrOrange);
   ChartSetInteger(ChartID(), CHART_COLOR_VOLUME, clrAqua);
   int keyboard = 12;
   ChartSetInteger(ChartID(), CHART_KEYBOARD_CONTROL, keyboard);
   ChartSetInteger(ChartID(), CHART_COLOR_CHART_DOWN, 231);
   ChartSetInteger(ChartID(), CHART_COLOR_CANDLE_BEAR, BearCandle);
   ChartSetInteger(ChartID(), CHART_COLOR_CANDLE_BULL, BullCandle);
   ChartSetInteger(ChartID(), CHART_COLOR_CHART_DOWN, Bear_Outline);
   ChartSetInteger(ChartID(), CHART_COLOR_CHART_UP, Bull_Outline);
   ChartSetInteger(ChartID(), CHART_SHOW_GRID, 0);
   ChartSetInteger(ChartID(), CHART_SHOW_PERIOD_SEP, false);
   ChartSetInteger(ChartID(), CHART_MODE, 1);
   ChartSetInteger(ChartID(), CHART_SHIFT, 1);
   ChartSetInteger(ChartID(), CHART_SHOW_ASK_LINE, 2);
   ChartSetInteger(ChartID(), CHART_COLOR_BACKGROUND, BackGround);
   ChartSetInteger(ChartID(), CHART_COLOR_FOREGROUND, ForeGround);
   return(true);
  }
  

//+-----------------------------------------------------------------+
//| Calculation of Trend Direction                                  |
//+-----------------------------------------------------------------+


//--- global variables
CEngine        engine;
#ifdef __MQL5__
CTrade         trade;
#endif 
SDataButt      butt_data[TOTAL_BUTT];
string         prefix;
double         lot;

int          magic_number=InpMagic;
uint           stoploss;
uint           takeprofit;
uint           distance_pending;
uint           distance_stoplimit;
uint           slippage;
bool           trailing_on;
double         trailing_stop;
double         trailing_step;
uint           trailing_start;
uint           stoploss_to_modify;
uint           takeprofit_to_modify;
int            used_symbols_mode;
string         used_symbols;
string         array_used_symbols[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Calling the function displays the list of enumeration constants in the journal 
//--- (the list is set in the strings 22 and 25 of the DELib.mqh file) for checking the constants validity
   //EnumNumbersTest();



   ChartColorSet();
   


   magic_number=InpMagic;
   stoploss=InpStopLoss;
   takeprofit=InpTakeProfit;
   distance_pending=InpDistance;
   distance_stoplimit=InpDistanceSL;



EventSetMillisecondTimer(10000);
OnTimer();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- Remove EA graphical objects by an object name prefix
 
   EventKillTimer();
   
   
   
   

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()


  {
  

     trade=newsTrade(Symbol());
     
          
     int ticket=0;
     double price=0;
     double SL=0;
     double TP=0;
      int check=0;
     int myPoint=(int )MarketInfo(_Symbol,MODE_POINT);
        //Open Buy Order, instant signal is tested first
   RefreshRates();
   if(getDirection()== "GO LONG"  && MaxOpenOrder!=OrdersTotal()&& trade ) //Price crosses above Support
   
     {
      RefreshRates();
      price = MarketInfo(_Symbol,MODE_ASK);
       SL = NormalizeDouble(Ask-InpStopLoss*Point,Digits);
      TP=NormalizeDouble(Bid+InpTakeProfit*Point,Digits);
   
       if(IsTradeAllowed())
        {
         ticket = OrderSend(_Symbol,OP_BUYLIMIT,InpLots, price, 0,Ask-SL,TP+Ask, "buylimit order",magic_number,0,clrGreen);
         if(ticket <= 0)
         
         {
         
         Alert(
         
         "ORDER SEND ERROR"+ GetErrorDescription(GetLastError(),0))
         ;
         
          return;}
        }
      else //not autotrading => only send alert
 
    check= OrderModify(ticket,price, SL, TP,0,clrAntiqueWhite);
    
    if (check<0){
     printf( "MODIFIY ORDER "+GetErrorDescription(GetLastError(),0));
 
      }
     }
   
   //Open Sell Order, instant signal is tested first
   RefreshRates();
   if(getDirection()=="GO SHORT"//Price crosses below Resistance
   && MaxOpenOrder!=OrdersTotal() && trade   )
     {
      RefreshRates();
      price =MarketInfo(_Symbol,MODE_BID);
      SL = NormalizeDouble(Bid+InpStopLoss*Point,Digits);
      TP=NormalizeDouble(Bid-InpTakeProfit*Point,Digits);
   
      double TradeSize =InpLots;
     
          if(IsTradeAllowed())
        {
         ticket = OrderSend(Symbol(),OP_SELLLIMIT,InpLots, price,0, SL,TP, "selllimit order",magic_number,0,clrRed);
         if(ticket <= 0){    Alert("ORDER SEND ERROR"+ GetErrorDescription(GetLastError(),0))
         ;
         
         return;}
        }
      else //not autotrading => only send alert
         
         check= OrderModify(ticket,price, SL, TP,0,clrAntiqueWhite);
    
    if (check<0){
    printf( "MODIFIY ORDER "+GetErrorDescription(GetLastError(),0));
    
     }}
     
//--- If the trailing flag is set
   if(trailing_on)
     {
      TrailingPositions();
      TrailingOrders();
     }
  }
//+------------------------------------------------------------------+
//| Transform enumeration into the button text                       |

//+------------------------------------------------------------------+
//| Set StopLoss to all orders and positions                         |
//+------------------------------------------------------------------+
void SetStopLoss(void)
  {
   if(stoploss_to_modify==0)
      return;
//--- Set StopLoss to all positions where it is absent
   CArrayObj* list=engine.GetListMarketPosition();
   list=CSelect::ByOrderProperty(list,ORDER_PROP_SL,0,EQUAL);
   if(list==NULL)
      return;
   int total=list.Total();
   for(int i=total-1;i>=0;i--)
     {
      COrder* position=list.At(i);
      if(position==NULL)
         continue;
      double sl=CorrectStopLoss(position.Symbol(),position.TypeByDirection(),0,stoploss_to_modify);
      #ifdef __MQL5__
         trade.PositionModify(position.Ticket(),sl,position.TakeProfit());
      #else 
         PositionModify(position.Ticket(),sl,position.TakeProfit());
      #endif 
     }
//--- Set StopLoss to all pending orders where it is absent
   list=engine.GetListMarketPendings();
   list=CSelect::ByOrderProperty(list,ORDER_PROP_SL,0,EQUAL);
   if(list==NULL)
      return;
   total=list.Total();
   for(int i=total-1;i>=0;i--)
     {
      COrder* order=list.At(i);
      if(order==NULL)
         continue;
      double sl=CorrectStopLoss(order.Symbol(),(ENUM_ORDER_TYPE)order.TypeOrder(),order.PriceOpen(),stoploss_to_modify);
      #ifdef __MQL5__
         trade.OrderModify(order.Ticket(),order.PriceOpen(),sl,order.TakeProfit(),trade.RequestTypeTime(),trade.RequestExpiration(),order.PriceStopLimit());
      #else 
         PendingOrderModify(order.Ticket(),order.PriceOpen(),sl,order.TakeProfit());
      #endif 
     }
  }
//+------------------------------------------------------------------+
//| Set TakeProfit to all orders and positions                       |
//+------------------------------------------------------------------+
void SetTakeProfit(void)
  {
   if(takeprofit_to_modify==0)
      return;
//--- Set TakeProfit to all positions where it is absent
   CArrayObj* list=engine.GetListMarketPosition();
   list=CSelect::ByOrderProperty(list,ORDER_PROP_TP,0,EQUAL);
   if(list==NULL)
      return;
   int total=list.Total();
   for(int i=total-1;i>=0;i--)
     {
      COrder* position=list.At(i);
      if(position==NULL)
         continue;
      double tp=CorrectTakeProfit(position.Symbol(),position.TypeByDirection(),0,takeprofit_to_modify);
      #ifdef __MQL5__
         trade.PositionModify(position.Ticket(),position.StopLoss(),tp);
      #else 
         PositionModify(position.Ticket(),position.StopLoss(),tp);
      #endif 
     }
//--- Set TakeProfit to all pending orders where it is absent
   list=engine.GetListMarketPendings();
   list=CSelect::ByOrderProperty(list,ORDER_PROP_TP,0,EQUAL);
   if(list==NULL)
      return;
   total=list.Total();
   for(int i=total-1;i>=0;i--)
     {
      COrder* order=list.At(i);
      if(order==NULL)
         continue;
      double tp=CorrectTakeProfit(order.Symbol(),(ENUM_ORDER_TYPE)order.TypeOrder(),order.PriceOpen(),takeprofit_to_modify);
      #ifdef __MQL5__
         trade.OrderModify(order.Ticket(),order.PriceOpen(),order.StopLoss(),tp,trade.RequestTypeTime(),trade.RequestExpiration(),order.PriceStopLimit());
      #else 
         PendingOrderModify(order.Ticket(),order.PriceOpen(),order.StopLoss(),tp);
      #endif 
     }
 
  }
//+------------------------------------------------------------------+
//| Trailing stop of a position with the maximum profit              |
//+------------------------------------------------------------------+
void TrailingPositions(void)
  {
   MqlTick tick;
   if(!SymbolInfoTick(Symbol(),tick))
      return;
   double stop_level=StopLevel(Symbol(),2)*Point();
   //--- Get the list of all open positions
   CArrayObj* list=engine.GetListMarketPosition();
   //--- Select only Buy positions from the list
   CArrayObj* list_buy=CSelect::ByOrderProperty(list,ORDER_PROP_TYPE,POSITION_TYPE_BUY,EQUAL);
   //--- Sort the list by profit considering commission and swap
   list_buy.Sort(SORT_BY_ORDER_PROFIT_FULL);
   //--- Get the index of the Buy position with the maximum profit
   int index_buy=CSelect::FindOrderMax(list_buy,ORDER_PROP_PROFIT_FULL);
   if(index_buy>WRONG_VALUE)
     {
      COrder* buy=list_buy.At(index_buy);
      if(buy!=NULL)
        {
         //--- Calculate the new StopLoss
         double sl=NormalizeDouble(tick.bid-trailing_stop,Digits());
         //--- If the price and the StopLevel based on it are higher than the new StopLoss (the distance by StopLevel is maintained)
         if(tick.bid-stop_level>sl) 
           {
            //--- If the new StopLoss level exceeds the trailing step based on the current StopLoss
            if(buy.StopLoss()+trailing_step<sl)
              {
               //--- If we trail at any profit or position profit in points exceeds the trailing start, modify StopLoss
               if(trailing_start==0 || buy.ProfitInPoints()>(int)trailing_start)
                 {
                  #ifdef __MQL5__
                     trade.PositionModify(buy.Ticket(),sl,buy.TakeProfit());
                  #else 
                     PositionModify(buy.Ticket(),sl,buy.TakeProfit());
                  #endif 
                 }
              }
           }
        }
     }
   //--- Select only Sell positions from the list
   CArrayObj* list_sell=CSelect::ByOrderProperty(list,ORDER_PROP_TYPE,POSITION_TYPE_SELL,EQUAL);
   //--- Sort the list by profit considering commission and swap
   list_sell.Sort(SORT_BY_ORDER_PROFIT_FULL);
   //--- Get the index of the Sell position with the maximum profit
   int index_sell=CSelect::FindOrderMax(list_sell,ORDER_PROP_PROFIT_FULL);
   if(index_sell>WRONG_VALUE)
     {
      COrder* sell=list_sell.At(index_sell);
      if(sell!=NULL)
        {
         //--- Calculate the new StopLoss
         double sl=NormalizeDouble(tick.ask+trailing_stop,Digits());
         //--- If the price and StopLevel based on it are below the new StopLoss (the distance by StopLevel is maintained)
         if(tick.ask+stop_level<sl) 
           {
            //--- If the new StopLoss level is below the trailing step based on the current StopLoss or a position has no StopLoss
            if(sell.StopLoss()-trailing_step>sl || sell.StopLoss()==0)
              {
               //--- If we trail at any profit or position profit in points exceeds the trailing start, modify StopLoss
               if(trailing_start==0 || sell.ProfitInPoints()>(int)trailing_start)
                 {
                  #ifdef __MQL5__
                     trade.PositionModify(sell.Ticket(),sl,sell.TakeProfit());
                  #else 
                     PositionModify(sell.Ticket(),sl,sell.TakeProfit());
                  #endif 
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Trailing the farthest pending orders                             |
//+------------------------------------------------------------------+
void TrailingOrders(void)
  {
   MqlTick tick;
   if(!SymbolInfoTick(Symbol(),tick))
      return;
   double stop_level=StopLevel(Symbol(),2)*Point();
//--- Get the list of all placed orders
   CArrayObj* list=engine.GetListMarketPendings();
//--- Select only Buy orders from the list
   CArrayObj* list_buy=CSelect::ByOrderProperty(list,ORDER_PROP_DIRECTION,ORDER_TYPE_BUY,EQUAL);
   //--- Sort the list by distance from the price in points (by profit in points)
   list_buy.Sort(SORT_BY_ORDER_PROFIT_PT);
   //--- Get the index of the Buy order with the greatest distance
   int index_buy=CSelect::FindOrderMax(list_buy,ORDER_PROP_PROFIT_PT);
   if(index_buy>WRONG_VALUE)
     {
      COrder* buy=list_buy.At(index_buy);
      if(buy!=NULL)
        {
         //--- If the order is below the price (BuyLimit) and it should be "elevated" following the price
         if(buy.TypeOrder()==ORDER_TYPE_BUY_LIMIT)
           {
            //--- Calculate the new order price and stop levels based on it
            double price=NormalizeDouble(tick.ask-trailing_stop,Digits());
            double sl=(buy.StopLoss()>0 ? NormalizeDouble(price-(buy.PriceOpen()-buy.StopLoss()),Digits()) : 0);
            double tp=(buy.TakeProfit()>0 ? NormalizeDouble(price+(buy.TakeProfit()-buy.PriceOpen()),Digits()) : 0);
            //--- If the calculated price is below the StopLevel distance based on Ask order price (the distance by StopLevel is maintained)
            if(price<tick.ask-stop_level) 
              {
               //--- If the calculated price exceeds the trailing step based on the order placement price, modify the order price
               if(price>buy.PriceOpen()+trailing_step)
                 {
                  #ifdef __MQL5__
                     trade.OrderModify(buy.Ticket(),price,sl,tp,trade.RequestTypeTime(),trade.RequestExpiration(),buy.PriceStopLimit());
                  #else 
                     PendingOrderModify(buy.Ticket(),price,sl,tp);
                  #endif 
                 }
              }
           }
         //--- If the order exceeds the price (BuyStop and BuyStopLimit), and it should be "decreased" following the price
         else
           {
            //--- Calculate the new order price and stop levels based on it
            double price=NormalizeDouble(tick.ask+trailing_stop,Digits());
            double sl=(buy.StopLoss()>0 ? NormalizeDouble(price-(buy.PriceOpen()-buy.StopLoss()),Digits()) : 0);
            double tp=(buy.TakeProfit()>0 ? NormalizeDouble(price+(buy.TakeProfit()-buy.PriceOpen()),Digits()) : 0);
            //--- If the calculated price exceeds the StopLevel based on Ask order price (the distance by StopLevel is maintained)
            if(price>tick.ask+stop_level) 
              {
               //--- If the calculated price is lower than the trailing step based on order price, modify the order price
               if(price<buy.PriceOpen()-trailing_step)
                 {
                  #ifdef __MQL5__
                     trade.OrderModify(buy.Ticket(),price,sl,tp,trade.RequestTypeTime(),trade.RequestExpiration(),(buy.PriceStopLimit()>0 ? price-distance_stoplimit*Point() : 0));
                  #else 
                     PendingOrderModify(buy.Ticket(),price,sl,tp);
                  #endif 
                 }
              }
           }
        }
     }
//--- Select only Sell order from the list
   CArrayObj* list_sell=CSelect::ByOrderProperty(list,ORDER_PROP_DIRECTION,ORDER_TYPE_SELL,EQUAL);
   //--- Sort the list by distance from the price in points (by profit in points)
   list_sell.Sort(SORT_BY_ORDER_PROFIT_PT);
   //--- Get the index of the Sell order having the greatest distance
   int index_sell=CSelect::FindOrderMax(list_sell,ORDER_PROP_PROFIT_PT);
   if(index_sell>WRONG_VALUE)
     {
      COrder* sell=list_sell.At(index_sell);
      if(sell!=NULL)
        {
         //--- If the order exceeds the price (SellLimit), and it needs to be "decreased" following the price
         if(sell.TypeOrder()==ORDER_TYPE_SELL_LIMIT)
           {
            //--- Calculate the new order price and stop levels based on it
            double price=NormalizeDouble(tick.bid+trailing_stop,Digits());
            double sl=(sell.StopLoss()>0 ? NormalizeDouble(price+(sell.StopLoss()-sell.PriceOpen()),Digits()) : 0);
            double tp=(sell.TakeProfit()>0 ? NormalizeDouble(price-(sell.PriceOpen()-sell.TakeProfit()),Digits()) : 0);
            //--- If the calculated price exceeds the StopLevel distance based on the Bid order price (the distance by StopLevel is maintained)
            if(price>tick.bid+stop_level) 
              {
               //--- If the calculated price is lower than the trailing step based on order price, modify the order price
               if(price<sell.PriceOpen()-trailing_step)
                 {
                  #ifdef __MQL5__
                     trade.OrderModify(sell.Ticket(),price,sl,tp,trade.RequestTypeTime(),trade.RequestExpiration(),sell.PriceStopLimit());
                  #else 
                     PendingOrderModify(sell.Ticket(),price,sl,tp);
                  #endif 
                 }
              }
           }
         //--- If the order is below the price (SellStop and SellStopLimit), and it should be "elevated" following the price
         else
           {
            //--- Calculate the new order price and stop levels based on it
            double price=NormalizeDouble(tick.bid-trailing_stop,Digits());
            double sl=(sell.StopLoss()>0 ? NormalizeDouble(price+(sell.StopLoss()-sell.PriceOpen()),Digits()) : 0);
            double tp=(sell.TakeProfit()>0 ? NormalizeDouble(price-(sell.PriceOpen()-sell.TakeProfit()),Digits()) : 0);
            //--- If the calculated price is below the StopLevel distance based on the Bid order price (the distance by StopLevel is maintained)
            if(price<tick.bid-stop_level) 
              {
               //--- If the calculated price exceeds the trailing step based on the order placement price, modify the order price
               if(price>sell.PriceOpen()+trailing_step)
                 {
                  #ifdef __MQL5__
                     trade.OrderModify(sell.Ticket(),price,sl,tp,trade.RequestTypeTime(),trade.RequestExpiration(),(sell.PriceStopLimit()>0 ? price+distance_stoplimit*Point() : 0));
                  #else 
                     PendingOrderModify(sell.Ticket(),price,sl,tp);
                  #endif 
                 }
              }
           }
        }
     }
  }
  
  input string token="";//API KEY
  double getCurrencyRate(string sym){
  char data[];
  
  string headers="";
  string params="";
 
        string out="";
  
  
  double rate=0;
  char result[];
  string result_headers="";
 int res= WebRequest("GET",backendUrl,headers,5000,data,result,result_headers);
  
  
  
  headers="Authorization : Bearer "+token + "\n\nContent-Type: application/json";
  
 string cookie=NULL; 
   char post[];
//--- to enable access to the server, you should add URL "https://www.google.com/finance" 
//--- in the list of allowed URLs (Main Menu->Tools->Options, tab "Expert Advisors"): 
   string google_url=backendUrl; 
//--- Reset the last error code 
   ResetLastError(); 
//--- Loading a html page from Google Finance 
   int timeout=1000; //--- Timeout below 1000 (1 sec.) is not enough for slow Internet connection 
   res=WebRequest("GET",google_url,cookie,NULL,timeout,post,0,result,headers); 
//--- Checking errors 
   if(res==-1) 
     { 
      Print("Error in WebRequest. Error code  =",GetLastError()); 
      //--- Perhaps the URL is not listed, display a message about the necessity to add the address 
      MessageBox("Add the address '"+google_url+"' in the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION); 
     } 
   else 
     { 
      //--- Load successfully 
      PrintFormat("The file has been successfully loaded, File size =%d bytes.",ArraySize(result)); 
      //--- Save the data to a file 
      int filehandle=FileOpen("current_rate.csv",FILE_WRITE|FILE_BIN); 
      //--- Checking errors 
      if(filehandle!=INVALID_HANDLE) 
        { 
         //--- Save the contents of the result[] array to a file 
         FileSeek(filehandle,0,SEEK_END);
         FileWriteArray(filehandle,result,0,ArraySize(result)); 
         //--- Close the file 
         FileClose(filehandle); 
        } 
      else Print("Error in FileOpen. Error code=",GetLastError()); 
     } 
  
  out=CharArrayToString(result,0,WHOLE_ARRAY);
  string rate1="";
  printf("Out "+out);
   
         CJAVal js(NULL,jtUNDEF);
         //---
        bool done=js.Deserialize(out);
          //--- 
         rate1= js["current rate"].ToStr();
    
      
      rate=(double)rate1;
      
      printf("RATE "+ rate1);
       
      ObjectCreate(ChartID(),"rate",OBJ_LABEL,0,Time[0],Bid);
      ObjectSetInteger(ChartID(),"rate",OBJPROP_BGCOLOR,0);
      ObjectSetText( "rate","Current Rate "+(string)rate,9,NULL,clrAliceBlue);
      ObjectMove(ChartID(),"rate",0,Time[0],Ask);
      
      
       if(rate1=="" || rate1==NULL){
       
       return 0;
       }
      //---
   return rate;
 
  }
//+------------------------------------------------------------------+















//--- Alert
input bool FirstAlert = True;
input bool SecondAlert = True;
datetime AlertTime = 0;
//--- Buffers

//--- time
datetime xmlModifed;
int TimeOfDay = Hour();
datetime Midnight = 0;
string message ;
input int offset=-4;//GMT SHIFT (EX: - 1 OR +1)
//+------------------------------------------------------------------+
//|                          TimeNewsFunck                                        |
//+------------------------------------------------------------------+
datetime TimeNewsFunck(int nomf)//RETURN CORRECT NEWS TIME FORMAT
  {
   string s = (string)mynews[nomf].getDate();
   string time = StringConcatenate(StringSubstr(s, 0, 4), ".", StringSubstr(s, 5, 2), ".", StringSubstr(s, 8, 2), " ", StringSubstr(s, 11, 2), ":", StringSubstr(s, 14, 5));
   string hour = StringSubstr(s, 5, 2);
   mynews[nomf].setHours((int)hour);
   string seconde = StringSubstr(s, 14, 5);
   mynews[nomf].setSecondes((int)seconde);
   return ((datetime)StringToTime(time) + offset * 3600);
  }


int NomNews=0;
string str1="";
bool Now=false;
datetime LastUpd=0;
bool Signal=false;
input bool AvoidNews=false;
//+------------------------------------------------------------------+
//|                              ReadWEB                                 |
//+------------------------------------------------------------------+
string ReadWEB()
  {
   string google_urls = "https://nfs.faireconomy.media/ff_calendar_thisweek.json?version=63b6408d09b7d9a9c68c0fb2ffcd044d";
   string params = "[]";
   int timeout = 5000;
   char data[];
   int data_size = StringLen(params);
   uchar result[];
   string result_headers= "content-type: application/json";
   int   start_index = 0;
//--- application/x-www-form-urlencoded
   int res = WebRequest("GET", google_urls, "0", params, timeout, data, 0, result, result_headers);
   string  out;
   
   if(res==-1) 
     { 
      Print("Error in WebRequest. Error code  =",GetLastError()); 
      //--- Perhaps the URL is not listed, display a message about the necessity to add the address 
      MessageBox("Add the address '"+google_urls+"' in the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION); 
     } 
   out = CharArrayToString(result, 0, WHOLE_ARRAY,CP_UTF8);
   printf("News output " + out);
   if(res == 200) //OK
     {
      //--- delete BOM
      int size = ArraySize(result);
      //---
      CJAVal  js(NULL, out);
      js.Deserialize(result);
      int total = ArraySize(js[""].m_e);
      printf("json array size" + (string)total);
      NomNews = total;
      ArrayResize(mynews, total, 0);
      for(int i = 0;  i<total;i++)
        {
         //Getting jason data'
         CJAVal item = js.m_e[i];
         //looping troughout each arrays to get data
         mynews[i].setDate(item["date"].ToStr());
         mynews[i].setTitle(item["title"].ToStr());
         mynews[i].setSourceUrl(google_urls);
         mynews[i].setCountry(item["country"].ToStr());
         mynews[i].setImpact(item["impact"].ToStr());
         mynews[i].setForecast(item["forecast"].ToDbl());
         mynews[i].setPrevious(item["previous"].ToDbl());
         mynews[i].setMinutes((int)(-TimeNewsFunck(i) + TimeCurrent()));
        }
      for(int i =   0;i<total; i++)
        {
         bool handle = FileOpen("News" + "\\" + newsfile, FILE_READ | FILE_CSV | FILE_WRITE);
         if(!handle)
           {
            printf("Error Can't open file" + newsfile + " to store news events! \nIf open please close it while bot is running.");
           }
         else
           {  printf(mynews[i].toString());
            message = mynews[i].toString();
            FileSeek(handle, offset, SEEK_END);
            FileWrite(handle, message);
            FileClose(handle);
          
           }
        }
     }
   else
     {
      if(res == -1)
        {
         printf((string)(_LastError));
        }
      else
        {
         //--- HTTP errors
         if(res >= 100 && res <= 511)
           {
            out = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
            Print(out);
            printf((string)(ERR_HTTP_ERROR_FIRST + res));
           }
         printf(((string)res));
        }
     }
   printf(out);
   return(out);
  }

//+------------------------------------------------------------------+
//|                            newsUpdate()                                       |
//+------------------------------------------------------------------+
void UpdateNews()//UPDATE NEWS DATA
  {
//--- do not download on saturday
   if(TimeDayOfWeek(Midnight) == 6)
      return;
   else
     {
      Print(" checking news for updates...");
      Print("Delete older news file" + newsfile);
      FileDelete(newsfile);
      ReadWEB();
      xmlModifed = (datetime)FileGetInteger(newsfile, FILE_MODIFY_DATE, false);
      PrintFormat("NEWS updated successfully! last modified: %s", newsfile);
     }
  }


#include <DiscordTelegram/News.mqh>
CNews mynews[];
string jamberita = "";
bool judulnews = true;



bool Next = false;
input int BeforeNewsStop = 60;
input int MinAfter = 60; //Minutes after News
input int AfterNewsStop = 60;
string google_urlx;

input color highc          = clrRed;     // Colour important news
input color mediumc        = clrBlue;    // Colour medium news
input color lowc           = clrLime;    // The color of weak news
input int   Style          = 1;          // Line style
input int   Upd            = 86400;      // Period news updates in seconds



int   MinBefore=0;
bool trade=true;
string infoberita="";
bool NewsFilter=True;

input string newsfile = "news.csv";
//-------- Debit/Credit total -------------------
bool StopTarget()


  {
   double ProfitValue = AccountBalance() - AccountEquity();
   if((2 / AccountBalance()) * 100 >= ProfitValue)
     {
      return (true);
     }
   return (false);
  }
//---


//+------------------------------------------------------------------+
//|                   GMTOFFSET                                               |
//+------------------------------------------------------------------+
int gmtoffset()
  {
   int gmthour;
   int gmtminute;
   datetime timegmt; // Gmt time
   datetime timecurrent; // Current time
   int gmtoffset = offset;
   timegmt = TimeGMT();
   timecurrent = TimeCurrent();
   gmthour = (int)StringToInteger(StringSubstr(TimeToStr(timegmt), 11, 2));
   gmtminute = (int)StringToInteger(StringSubstr(TimeToStr(timegmt), 14, 2));
   gmtoffset = TimeHour(timecurrent) - gmthour;
   if(gmtoffset < 0)
      gmtoffset = 24 + gmtoffset;
   return(gmtoffset);
  }
//+------------------------------------------------------------------+
//|               NEWSTRADE                                                   |
//+------------------------------------------------------------------+
bool newsTrade(string sym) //RETURN TRUE IF TRADE IS ALLOWED
  {



   double CheckNews=0;

      if(TimeCurrent()-LastUpd>=Upd)
        {
         Comment("n\n\nNews Loading...");
         Print("News Loading...");;
         UpdateNews();
         LastUpd=TimeCurrent();
         Comment("");
        }
      WindowRedraw();
      //---Draw a line on the chart news--------------------------------------------
      if(DRAW_NEWS_LINES==true)
        {
         for(int i=0;i<NomNews; i++)
           {
            string Name=StringSubstr(TimeToStr(TimeNewsFunck(i),TIME_MINUTES)+"_"+mynews[i].getDate()+"_"+mynews[i].getTitle()+"  "+mynews[i].getImpact()+"  "
            
            +mynews[i].getImpact()
            
              ,0,63);
            
            printf(Name);
            if(mynews[i].getTitle()!="")
               if(ObjectFind(Name)==0)
                  continue;
            if(StringFind(str1,mynews[i].getImpact())<0)
               continue;
            if(TimeNewsFunck(i)<TimeCurrent() && Next)
               continue;

            color clrf=clrNONE ;
            if( NEWS_IMPOTANCE_HIGH &&(StringFind(mynews[i].getImpact(),(string)judulnews)>=0))
               clrf=highc;
            if(NEWS_IMPOTANCE_HIGH&& (StringFind(mynews[i].getImpact(),"High")>=0))
               clrf=highc;
            if(NEWS_IMPOTANCE_MEDIUM &&(StringFind(mynews[i].getImpact(),"Medium")>=0))
               clrf=mediumc;
            if(NEWS_IMPOTANCE_LOW&& (StringFind(mynews[i].getImpact(),"Low")>=0))
               clrf=lowc;

            if(clrf==clrNONE)
               continue;


              
               ObjectCreate(ChartID(),Name,OBJ_VLINE,0,TimeNewsFunck(i),Bid);
               ObjectSet(Name,OBJPROP_COLOR,clrf);
               ObjectSet(Name,OBJPROP_STYLE,Style);
               ObjectSetInteger(ChartID(),Name,OBJPROP_BACK,true);
               ObjectSetString(ChartID(),Name,OBJPROP_TEXT,mynews[i].getTitle());
              
           }
        
      //---------------event Processing------------------------------------
      int i;
      CheckNews=0;
      //tg
      /*      for(i=0;i<NomNews;i++)
              {
               int power=0;
               if(Vtunggal && StringFind(NewsArr[3][i],judulnews)>=0)power=1;
               if(Vhigh && StringFind(NewsArr[2][i],"High")>=0)power=1;
               if(Vmedium && StringFind(NewsArr[2][i],"Moderate")>=0)power=2;
               if(Vlow && StringFind(NewsArr[2][i],"Low")>=0)power=3;
               if(power==0)continue;
               if(TimeCurrent()+MinBefore*60>TimeNewsFunck(i) && TimeCurrent()-1*MinAfter<TimeNewsFunck(i) && StringFind(str1,NewsArr[1][i])>=0)
                 {
                 CheckNews=2;
                  break;
                 }
               else CheckNews=0;
               }*/

      //ory
      for(i=NomNews-1;i>0; i--)
        {
         int power=0;
         if(NEWS_IMPOTANCE_HIGH&&( StringFind(mynews[i].getImpact(),(string)judulnews)>=0))
            power=1;
         if(NEWS_IMPOTANCE_HIGH&& (StringFind(mynews[i].getImpact(),"High")>=0))
            power=1;
         if( NEWS_IMPOTANCE_MEDIUM&& (StringFind(mynews[i].getImpact(),"Medium")>=0))
            power=2;
         if( NEWS_IMPOTANCE_LOW && (StringFind(mynews[i].getImpact(),"Low")>=0))
            power=3;
         if(power==0)
            continue;
         if(TimeCurrent()+MinBefore*60>TimeNewsFunck(i) && TimeCurrent()-60*MinAfter<TimeNewsFunck(i) && StringFind(str1,mynews[i].getDate(),0)>=0)
           {
            jamberita= " In "+string((int)(TimeNewsFunck(i)-TimeCurrent())/60)+" Minutes ["+mynews[i].getTitle()+"]";
            infoberita = ">> "+StringSubstr(mynews[i].getCountry(),0,28);
            CheckNews=1;
            break;
           }
         else
            CheckNews=0;
        }
      if(CheckNews==1 && i!=Now && Signal)
        {
         Alert("In ",(int)(TimeNewsFunck(i)-TimeCurrent())/60," minutes released news Currency ",mynews[i].getCountry(),"_",mynews[i].getTitle());
         
         
         printf("In "+(string)((int)(TimeNewsFunck(i)-TimeCurrent())/60)+" minutes released news Currency "+mynews[i].getCountry()+"_"+mynews[i].getTitle());
         Now=i;
        }

     }

   if(CheckNews>0 && NewsFilter)
      trade=false;
   if(CheckNews>0)
     {

      /////  We are doing here if we are in the framework of the news
      if(!StopTarget() && NewsFilter){
         infoberita ="News Time >> TRADING OFF";
         Comment("\n\n\n"+infoberita);
         }
         
      if(!StopTarget()&& !NewsFilter)
       {  infoberita="Attention!\n News Time";
         Comment("\n\n\n"+infoberita);
         
        
         
         }

     }
   else
     {
      if(NewsFilter)
         trade=true;
      // We are out of scope of the news release (No News)
      if(!StopTarget())
         jamberita= "No News";
      infoberita = "  Waiting......";
     Comment(jamberita+"    "+infoberita);

     }
   return trade;
      
  }
void OnChartEvent(const int id,         // Event ID 
                  const long& lparam,   // Parameter of type long event 
                  const double& dparam, // Parameter of type double event 
                  const string& sparam  // Parameter of type string events 
                  ){
                  
                  
                  
                  
                  
                  
                  
                  
                  }
