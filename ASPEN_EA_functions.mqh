//+------------------------------------------------------------------+
//|                                            ENV_SPM_functions.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
double PtsToPrice(double pts)
  {
   return(pts*MathPow(10,-Digits));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PriceToPts(double price)
  {
   return(price*MathPow(10,Digits));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void removeTPandSLfromSubSet(SubSet& subSet)

  {
   for(int tradesIdx=0; tradesIdx<subSet.nextTradeIdx; tradesIdx++)
     {
      if(OrderSelect(subSet.ticket[tradesIdx],SELECT_BY_TICKET) && OrderCloseTime()==0)
         if(OrderModify(OrderTicket(),Bid,0,0,0,clrAliceBlue))
            Print("TP, SL and TS of trade #",(string)OrderTicket()," removed");
         else
            Print("OrderModify at removeTPandSLfromIT order #",(string)OrderTicket()," failed");
     }
   return;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double FreeMarginBalanceLots(double percentage, int multiply, int divide, string& lotsCalcString)
  {
   double amount;
   string nameAmount;

   if(ammountRiskedIT==1)
     {
      amount=NormalizeDouble(AccountInfoDouble(ACCOUNT_MARGIN_FREE),2);
      nameAmount="Free Margin";
     }
   else
     {
      amount=NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE),2);
      nameAmount="Balance";
     }

   double Lots=NormalizeDouble(amount*percentage/100*AccountLeverage()/100000*multiply/divide,2);


   lotsCalcString=(nameAmount+" ("+(string)amount+") * % ("+
                   (string)percentage+") / 100 * Leverage ("+(string)AccountLeverage()+") / 100000 * "+(string)multiply+" / "+
                   (string)divide+" = "+(string)CheckMaxMinLots(Lots)+" (After checking Max, Min and Step lots allowed)");


   return(CheckMaxMinLots(Lots));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//This function checks if desired lots fit between maximum and minimum lots req.
//And also calculates the step required for each lot
double CheckMaxMinLots(double lots)
  {
   if(lots>SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX))
      return(SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX));
   else
      if(lots<SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN))
         return(SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN));
      else
         return(MathRound(lots/MarketInfo(Symbol(),MODE_LOTSTEP))*MarketInfo(Symbol(),MODE_LOTSTEP));
  }

//+------------------------------------------------------------------+
//| Functions                                                        |
//+------------------------------------------------------------------+
int RelativeTimeSec(datetime DateTime)
  {
   int RelTime=TimeHour(DateTime)*3600+TimeMinute(DateTime)*60+TimeSeconds(DateTime);
   return(RelTime);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool GoodTime(string Time_on, string Time_off)
  {
   if(Time_on!="" && Time_off!="")
     {
      int sCurrent_time=RelativeTimeSec(TimeCurrent());
      int st_start=RelativeTimeSec(StrToTime(Time_on));
      int st_stop=RelativeTimeSec(StrToTime(Time_off));

      if(st_start<st_stop)
        {
         if(sCurrent_time<st_start || sCurrent_time>=st_stop)
           {
            return(false);
           }
        }
      else
         if(st_start>st_stop)
           {
            if(sCurrent_time<st_start && sCurrent_time>=st_stop)
              {
               return(false);
              }
           }
     }
   return(true);
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//This function sets SL and TP after opening each trade
void SetSLandTP(int orderTicket, int orderType)
  {
   double priceSL,priceTP,closePrice;

   if(OrderSelect(orderTicket,SELECT_BY_TICKET))
     {
      if(orderType==OP_BUY)
        {
         priceSL=OrderOpenPrice()-PtsToPrice(SLentry);
         priceTP=OrderOpenPrice()+PtsToPrice(TPentry);
         closePrice=Bid;
        }
      else
        {
         priceSL=OrderOpenPrice()+PtsToPrice(SLentry);
         priceTP=OrderOpenPrice()-PtsToPrice(TPentry);
         closePrice=Ask;
        }

      if(OrderModify(orderTicket,OrderOpenPrice(),priceSL,priceTP,0,clrRed))
        {
         Print("#"+(string)orderTicket+
               ". SL set to: "+(string)(priceSL)+
               ". TP set to: "+(string)(priceTP));
         Print("~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~");
        }
      else
        {
         Print("#"+(string)orderTicket+". Order Modify error: "+ErrorDescription(GetLastError()));
         for(int i=0; i<10; i++)
           {
            Sleep(1500);

            if(OrderProfit()>0)
               if(OrderClose(orderTicket,OrderLots(),closePrice,Slippage,clrGray))
                  Print("Closed order in SL and TP set because profit > 0");
               else
                  Print("OrderClose error:",GetLastError());

            if(OrderModify(orderTicket,OrderOpenPrice(),priceSL,priceTP,0,clrRed))
              {
               Print("#"+(string)orderTicket+" OrderModify succeed on attempt nº "+(string)(i+2)+
                     ". SL set to: "+(string)(priceSL)+
                     ". TP set to: "+(string)(priceTP));
               Print("~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~");
               ;
               break;
              }
            else
              {
               Print("#"+(string)orderTicket+". Order Modify error: "+ErrorDescription(GetLastError()));
               if(i==9)
                  if(OrderClose(orderTicket,OrderLots(),closePrice,1000,clrGray))
                     Print("OrderClose because in 10 iterations couldn't set SL and TP");
                  else
                     Print("OrderClose error:",GetLastError());
              }
           }
        }
     }
   return;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailingStopStep(int& setIdx)
  {
   for(int tradesIdx=0; tradesIdx < MainSet[setIdx].ITset.nextTradeIdx; tradesIdx++)
      if(OrderSelect(MainSet[setIdx].ITset.ticket[tradesIdx],SELECT_BY_TICKET,MODE_TRADES)==true)
         if(OrderSymbol() ==Symbol() && OrderMagicNumber()==MAGICMA)
           {
            if(OrderType() == OP_BUY)
               if(Bid - OrderOpenPrice() >= PtsToPrice(trailingStopStart))
                 {
                  double newSL=OrderOpenPrice();

                  //look for the closest SL to price minus TS distance
                  do
                    {
                     newSL+=PtsToPrice(trailingStopStep);
                    }
                  while(newSL <= Bid - PtsToPrice(trailingStop));
                  newSL-=PtsToPrice(trailingStopStep);

                  if(NormalizeDouble(newSL,Digits)>OrderStopLoss())
                     if(OrderModify(OrderTicket(),OrderOpenPrice(),newSL,OrderTakeProfit(),0,Green))
                        Print("TS apply on order: "+(string)OrderTicket());
                     else
                        Print("Buy Order "+(string)OrderTicket()+" Modify error ",ErrorDescription(GetLastError()));

                 }
            if(OrderType() == OP_SELL)
               if(OrderOpenPrice() - Ask > PtsToPrice(trailingStopStart))
                 {
                  double newSL=OrderOpenPrice();

                  //look for the closest SL to price plus TS distance
                  do
                    {
                     newSL-=PtsToPrice(trailingStopStep);
                    }
                  while(newSL >= Ask + PtsToPrice(trailingStop));
                  newSL+=PtsToPrice(trailingStopStep);

                  if(NormalizeDouble(newSL,Digits)<OrderStopLoss())
                     if(OrderModify(OrderTicket(),OrderOpenPrice(),newSL,OrderTakeProfit(),0,Red))
                        Print("TS apply on order: "+(string)OrderTicket());
                     else
                        Print("Sell Order "+(string)OrderTicket()+" Modify error ",ErrorDescription(GetLastError()));


                 }
           }
   return;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool NewBarTime()
  {
   static datetime CurrentTime=iTime(NULL,TimeFrame,0);

   if(CurrentTime!=iTime(NULL,TimeFrame,0))
     {
      CurrentTime=iTime(NULL,TimeFrame,0);
      return (true);
     }
   else
      return(false);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool NewBarTime1()
  {
   static datetime CurrentTime=iTime(NULL,TimeFrame,0);

   if(CurrentTime!=iTime(NULL,TimeFrame,0))
     {
      CurrentTime=iTime(NULL,TimeFrame,0);
      return (true);
     }
   else
      return(false);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsAGoodTime()
  {
   if(GoodTime(Time_on1,Time_off1)
      || (GoodTime(Time_on2,Time_off2) && Time_on2!="" && Time_off2!="")
      || (GoodTime(Time_on3,Time_off3) && Time_on3!="" && Time_off3!="")
      || (GoodTime(Time_on4,Time_off4) && Time_on4!="" && Time_off4!="")
      || (GoodTime(Time_on5,Time_off5) && Time_on5!="" && Time_off5!=""))
      return (true);
   else
      return (false);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetOrderType(int ticket)
  {
   if(OrderSelect(ticket,SELECT_BY_TICKET))
      if(OrderType()==OP_BUY)
         return(OP_BUY);
      else
         return(OP_SELL);
   else
      Print("Error: "+ErrorDescription(GetLastError())+" in GetOrderType(), ticket: "+(string)ticket);
   return(-1);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetOrderOpenPrice(int ticket)
  {
   if(OrderSelect(ticket,SELECT_BY_TICKET))
      return (OrderOpenPrice());
   else
      Print("Error: "+ErrorDescription(GetLastError())+" in GetOrderOpenPrice(), ticket: "+(string)ticket);
   return(-1);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetOrderLots(int ticket)
  {
   if(OrderSelect(ticket,SELECT_BY_TICKET))
      return (OrderLots());
   else
      Print("Error: "+ErrorDescription(GetLastError())+" in GetOrderLots(), ticket: "+(string)ticket);
   return(-1);
  }

//+------------------------------------------------------------------+
