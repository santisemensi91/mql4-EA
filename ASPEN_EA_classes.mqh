//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2018, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class SubSet
  {

public:
   int               ticket[],positionInChart[],nextTradeIdx,openOrdersCount,maxTradesAllowed,ptsForNextTrade;
   string            nameSubSet,extraString;
   color             colorBuy,colorSell;
   double            SL,TP,profitAcum,lotsAcum,openPriceAcum;
   bool              subSetOpen,maxTradesReached;

                     SubSet()
     {
      subSetOpen=false;
      maxTradesReached=false;
      nextTradeIdx=0;
      profitAcum=0;
     }

   //+------------------------------------------------------------------+
   //|                                                                  |
   //+------------------------------------------------------------------+

   bool              OpenTrade(int orderType, int setIdx, int tradeIdx=0)
     {
      double openPrice;
      color  colorTrade;
      string stringOrderType,tradeComment,lotsCalcString;

      if(orderType==OP_BUY)
        {
         stringOrderType="Buy";
         openPrice=Ask;
         colorTrade=colorBuy;
        }
      else
        {
         stringOrderType="Sell";
         openPrice=Bid;
         colorTrade=colorSell;
        }


      //Resize array to allow storage of information
      if(nextTradeIdx+1 > ArraySize(ticket))
        {
         ArrayResize(ticket,nextTradeIdx+1,maxTrades);
         ArrayResize(positionInChart,nextTradeIdx+1,maxTrades);
        }

      if(nameSubSet=="REPO")
         tradeComment="- "+nameSubSet+" "+stringOrderType+" order nº"+
                      (string)(nextTradeIdx+1)+",set "+(string)(setIdx+1)+" of trade #"+(string)MainSet[setIdx].ITset.ticket[tradeIdx]+" -";
      else
         tradeComment="- "+nameSubSet+" "+stringOrderType+" order nº"+
                      (string)(nextTradeIdx+1)+",set "+(string)(setIdx+1)+" -";


      ticket[nextTradeIdx]=OrderSend(Symbol(),
                                     orderType,
                                     CalculateLots(setIdx,tradeIdx,lotsCalcString),
                                     openPrice,
                                     Slippage,
                                     0,
                                     0,
                                     tradeComment,
                                     MAGICMA,
                                     0,
                                     colorTrade);

      if(ticket[nextTradeIdx]>0)
        {
         //If trade opens succesfully...
         if(OrderSelect(ticket[nextTradeIdx],SELECT_BY_TICKET,MODE_TRADES))
           {
            Print("~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~");
            Print(nameSubSet+" "+stringOrderType+" order nº"+
                  (string)(nextTradeIdx+1)+" opened of set "+(string)(setIdx+1)+". Ticket #"+(string)OrderTicket());
            Print("Spread is: "+(string)MarketInfo(Symbol(),MODE_SPREAD));
            Print("Lots calculation for trade #"+(string)OrderTicket()+" :");
            Print(lotsCalcString);

            //Flag the subset as open
            subSetOpen=true;

            //Set SL, TP
            if(SL!=0 && TP !=0)
               SetSLandTP(OrderTicket(),orderType);

            //Store the IT index the repetition trade is copying
            if(nameSubSet=="REPO")
               positionInChart[nextTradeIdx]=tradeIdx;

            nextTradeIdx++;

            if(nextTradeIdx==maxTradesAllowed)
               maxTradesReached=true;
           }
         return(true);
        }
      else
         Print("Error opening "+nameSubSet+" "+(string)(nextTradeIdx+1)+"º "+stringOrderType+
               " order of set nº"+(string)(setIdx+1)+": ",ErrorDescription(GetLastError()));
      return(false);

     }

   //+------------------------------------------------------------------+
   //|                                                                  |
   //+------------------------------------------------------------------+


   double            CalculateLots(int setIdx, int tradeIdx, string& lotsCalcString)
     {
      double orderLots;

      if(nameSubSet=="IT")
        {
         if(nextTradeIdx==0)
           {
            // lotsCalcString value is passed by reference by FreeMarginLots2()
            return(CheckMaxMinLots(FreeMarginBalanceLots(RFinitial,1,1,lotsCalcString)));
           }
         else
           {
            orderLots=GetOrderLots(ticket[0]);

            lotsCalcString="1º IT lots: "+(string)orderLots+
                           " * lotsMultFactorIT: "+(string)lotsMultFactorIT+
                           " * trade nº after 1º IT: "+(string)nextTradeIdx+
                           " = "+(string)CheckMaxMinLots(orderLots*lotsMultFactorIT*nextTradeIdx)+
                           " (After checking Max, Min and Step lots allowed)";
            return(CheckMaxMinLots(orderLots*lotsMultFactorIT*nextTradeIdx));
           }
        }

      if(nameSubSet=="REPO")
        {
         orderLots=GetOrderLots(MainSet[setIdx].ITset.ticket[tradeIdx]);

         lotsCalcString="Repetition order of trade #"+(string)MainSet[setIdx].ITset.ticket[tradeIdx]+", so lots:"+(string)orderLots;
         return(orderLots);
        }

      if(nameSubSet=="LCT")
        {
         orderLots=GetOrderLots(MainSet[setIdx].ITset.ticket[MainSet[setIdx].ITset.nextTradeIdx-1]);

         lotsCalcString="Last IT order lots: "+(string)orderLots+
                        " * lotsMultFactorLCT: "+(string)lotsMultFactorLCT+
                        " * LCT trade nº: "+(string)(nextTradeIdx+1)+
                        " = "+(string)CheckMaxMinLots(orderLots*lotsMultFactorLCT*(nextTradeIdx+1))+
                        " (After checking Max, Min and Step lots allowed)";
         return(CheckMaxMinLots(orderLots*lotsMultFactorLCT*(nextTradeIdx+1)));
        }

      if(nameSubSet=="LCT2")
        {
         orderLots=GetOrderLots(MainSet[setIdx].LCTset.ticket[MainSet[setIdx].LCTset.nextTradeIdx-1]);

         lotsCalcString="Last LCT order lots: "+(string)orderLots+
                        " * lotsMultFactorLCT: "+(string)lotsMultFactorLCT2+
                        " * LCT2 trade nº: "+(string)(nextTradeIdx+1)+
                        " = "+(string)CheckMaxMinLots(orderLots*lotsMultFactorLCT2*(nextTradeIdx+1))+
                        " (After checking Max, Min and Step lots allowed)";
         return(CheckMaxMinLots(orderLots*lotsMultFactorLCT2*(nextTradeIdx+1)));
        }

      return(0);
     }

   //+------------------------------------------------------------------+
   //|                                                                  |
   //+------------------------------------------------------------------+

   void              GetTradesData()
     {
      // Assume that subSet is not open before first iteration
      subSetOpen=false;
      profitAcum=0;
      lotsAcum=0;
      openPriceAcum=0;

      for(int tradeIdx=0; tradeIdx< nextTradeIdx; tradeIdx++)
        {
         if(OrderSelect(ticket[tradeIdx],SELECT_BY_TICKET)==true)
            if(OrderSymbol() == Symbol() && OrderMagicNumber()==MAGICMA)

               //Only get data from open trades
               if(OrderCloseTime()==0)
                 {
                  openOrdersCount++;
                  subSetOpen=true;
                  profitAcum+=(OrderProfit()+OrderCommission()+OrderSwap());
                  lotsAcum+=OrderLots();
                  openPriceAcum+=OrderOpenPrice();
                 }
        }
      return;
     }

   //+------------------------------------------------------------------+
   //|                                                                  |
   //+------------------------------------------------------------------+

   // Method ment to be called from LCT or LCT2 subsets.
   // Determines if conditions regarding negative profit are met to open loss compensation trades.

   bool              CheckIfLossCompensationNeeded(int setIdx, SubSet& subSet1, SubSet& subSet2)

     {
      ammount ammountRisked;
      int orderType=GetOrderType(subSet1.ticket[0]);
      int openOrdersCount_;
      double profitNeededToLCT, openPriceAcum_, profitAcum_, actualPriceAcum, pLoss;
      string  string0,string1;
      bool   return_=false;

      if(nameSubSet=="LCT")
        {
         ammountRisked=ammountRiskedLCT;
         profitAcum_=subSet1.profitAcum+subSet2.profitAcum;
         openOrdersCount_=subSet1.openOrdersCount+subSet2.openOrdersCount;
         openPriceAcum_=subSet1.openPriceAcum+subSet2.openPriceAcum;
         pLoss=percentLossLCT;
        }
      else
        {
         ammountRisked=ammountRiskedLCT2;
         profitAcum_=subSet1.profitAcum;
         openOrdersCount_=subSet1.openOrdersCount;
         openPriceAcum_=subSet1.openPriceAcum;
         pLoss=percentLossLCT2;
        }

      switch(ammountRisked)
        {
         case 0:
            profitNeededToLCT=NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE)*pLoss*0.01,2);
            if(profitAcum_ < (-profitNeededToLCT))
              {
               string1=(nameSubSet+" starts on set "+(string)(setIdx+1)+". Profit Accumulated is: "+(string)profitAcum_+
                        ". And %Balance to activate LCT: "+(string)(-profitNeededToLCT));

               return_=true;
              }
            else
               return (false);
            break;

         case 1:
            profitNeededToLCT=NormalizeDouble(AccountInfoDouble(ACCOUNT_MARGIN_FREE)*pLoss*0.01,2);
            if(profitAcum_ < (-profitNeededToLCT))
              {
               string1=(nameSubSet+" starts on set "+(string)(setIdx+1)+". Profit Accumulated is: "+(string)profitAcum_+
                        ". And %FM to activate "+nameSubSet+": "+(string)(-profitNeededToLCT));

               return_=true;
              }
            else
               return (false);
            break;

         case 2:
            if(orderType==OP_BUY)
              {
               actualPriceAcum=Bid*(openOrdersCount_);
               return_=(actualPriceAcum*100/openPriceAcum_ <= 100-pLoss);
               string0=("So the % loss is: "+(string)(100-(actualPriceAcum*100/openPriceAcum_)));
              }
            else
              {
               actualPriceAcum=Ask*(openOrdersCount_);
               return_=(actualPriceAcum*100/openPriceAcum_ >= 100+pLoss);
               string0=("So the % loss is: "+(string)((actualPriceAcum*100/openPriceAcum_)-100));
              }
            if(return_)
               string1=((string)nameSubSet+" starts on set "+(string)(setIdx+1)+". IT open prices accumulated are: "+(string)openPriceAcum_+
                        ", and the actual price *"+(string)openOrdersCount_+" open orders is: "+(string)actualPriceAcum+". "+string0);
            break;

         default:
            return(false);
            break;
        }

      if(return_ && !subSetOpen)
        {
         Print("----------------------------------------------------------------------------------------");
         Print(string1);
         Print("ACCOUNT_BALANCE = "+(string)AccountInfoDouble(ACCOUNT_BALANCE));
         Print("ACCOUNT_MARGIN_FREE = "+(string)AccountInfoDouble(ACCOUNT_MARGIN_FREE));
         Print("ACCOUNT_MARGIN_LEVEL = "+(string)AccountInfoDouble(ACCOUNT_MARGIN_LEVEL));
         Print("ACCOUNT_EQUITY = "+(string)AccountInfoDouble(ACCOUNT_EQUITY));
         Print("----------------------------------------------------------------------------------------");
        }

      return(return_);

     }

   //+------------------------------------------------------------------+
   //|                                                                  |
   //+------------------------------------------------------------------+

   // This method serves to check if price is above or below 'x' pts from the highest or lowest trade in the subset

   bool              CheckIfPriceIsAboveHighestOrBelowLowestTrades()
     {
      // If it's the first trade of the subset, just return true
      if(nextTradeIdx==0)
         return (true);

      double highestOpenPrice=0;
      double lowestOpenPrice=0;
      double actualPrice;

      for(int tradeIdx=0; tradeIdx < nextTradeIdx; tradeIdx++)
        {
         double currentTradeOP=GetOrderOpenPrice(ticket[tradeIdx]);

         if(tradeIdx==0)
           {
            highestOpenPrice=currentTradeOP;
            lowestOpenPrice=currentTradeOP;
           }
         else
           {
            if(currentTradeOP>highestOpenPrice)
               highestOpenPrice=currentTradeOP;

            if(currentTradeOP<lowestOpenPrice)
               lowestOpenPrice=currentTradeOP;
           }
        }

      if(GetOrderType(ticket[0])==OP_BUY)
         actualPrice=Ask;
      else
         actualPrice=Bid;

      if(actualPrice > highestOpenPrice+PtsToPrice(ptsForNextTrade))
         return (true);
      if(actualPrice < lowestOpenPrice+PtsToPrice(ptsForNextTrade))
         return (true);

      return(false);
     }

  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class InitialTrades : public SubSet
  {
public:
   string               trend;
   int               barsSinceSetIsOpen;

                     InitialTrades()
     {
      nameSubSet="IT";
      colorBuy=colorITbuy;
      colorSell=colorITsell;
      maxTradesAllowed=maxTrades;
      SL=SLentry;
      TP=TPentry;
      barsSinceSetIsOpen=0;
     }
   //+------------------------------------------------------------------+
   //|                                                                  |
   //+------------------------------------------------------------------+

   bool              BarCountReached()
     {
      static datetime CurrentTime=iTime(NULL,TimeFrame,0);

      if(CurrentTime!=iTime(NULL,TimeFrame,0))
        {
         CurrentTime=iTime(NULL,TimeFrame,0);
         barsSinceSetIsOpen++;

         if(barsSinceSetIsOpen >= nCandles)
            return (true);
         else
            return(false);
        }
      else
         return(false);
     }

  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class RepetitionTrades : public SubSet
  {
public:

                     RepetitionTrades()
     {
      nameSubSet="REPO";
      colorBuy=colorREPObuy;
      colorSell=colorREPOsell;
      maxTradesAllowed=maxTradesREPO;
      SL=SLentry;
      TP=TPentry;
     }
   //+------------------------------------------------------------------+
   //|                                                                  |
   //+------------------------------------------------------------------+

   void                 CheckForOpenRepetitionTrade(int setIdx)
     {
      datetime ITcloseTime;
      double   ITopenPrice;
      int      ITorderType;
      int      tradeDirection=-1;
      bool     otherREPOofSameITopen=false;

      //Search for closed initial trades
      for(int iIT=0; iIT< MainSet[setIdx].ITset.nextTradeIdx; iIT++)
        {
         if(OrderSelect(MainSet[setIdx].ITset.ticket[iIT],SELECT_BY_TICKET))
            if(OrderSymbol() == Symbol() && OrderMagicNumber()==MAGICMA)

               //If selected trade is closed, see if repetition trade can open
               if(OrderCloseTime()!=0)
                 {
                  ITcloseTime=OrderCloseTime();
                  ITopenPrice=OrderOpenPrice();
                  ITorderType=OrderType();
                  extraString=(string)OrderTicket();

                  //Check if there is no other repetition trade open for same IT
                  if(subSetOpen)
                     for(int iREP=0; iREP< nextTradeIdx; iREP++)
                       {
                        if(OrderSelect(ticket[iREP],SELECT_BY_TICKET))
                           if(OrderCloseTime()==0)
                              if(positionInChart[iREP]==iIT)
                                 otherREPOofSameITopen=true;
                       }

                  if(!otherREPOofSameITopen && Time[0] > ITcloseTime) // Controlar MaxTrades Repo desde el llamado a la funcion
                    {
                     if(((Close[1] > ITopenPrice && Ask < ITopenPrice) ||
                         (Close[1] < ITopenPrice && Ask > ITopenPrice)) &&
                        ITorderType==OP_BUY)
                        tradeDirection=OP_BUY;

                     if(((Close[1] > ITopenPrice && Bid < ITopenPrice) ||
                         (Close[1] < ITopenPrice && Bid > ITopenPrice)) &&
                        ITorderType==OP_SELL)
                        tradeDirection=OP_SELL;

                     if(tradeDirection > -1)
                        // Open repetition trade until reaching the maximum desired
                        OpenTrade(tradeDirection,setIdx,iIT);

                    }
                 }
        }
      return;
     }
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class LossCompTrades : public SubSet
  {
public:
   int               finalDirection;
   dir               direction_LCT;

                     LossCompTrades()
     {
      nameSubSet="LCT";
      colorBuy=colorLCTbuy;
      colorSell=colorLCTsell;
      maxTradesAllowed=maxTradesLCT;
      ptsForNextTrade=xPtsLCT;
      SL=0;
      TP=0;
     }
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class LossCompTrades2 : public SubSet
  {
public:
   int               finalDirection;

                     LossCompTrades2()
     {
      nameSubSet="LCT2";
      colorBuy=colorLCT2buy;
      colorSell=colorLCT2sell;
      maxTradesAllowed=maxTradesLCT2;
      ptsForNextTrade=xPtsLCT2;
      SL=0;
      TP=0;
     }
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MainSetManipulator
  {
public:
                     MainSetManipulator()
     {
      setOpen=false;
      barsSinceSetIsOpen=0;
      maximumLossRecorded=0;
     }

   int               barsSinceSetIsOpen;
   bool              setOpen;
   double            maximumLossRecorded;
   InitialTrades               ITset;
   RepetitionTrades            REPset;
   LossCompTrades              LCTset;
   LossCompTrades2             LCT2set;

   //+------------------------------------------------------------------+
   //|                                                                  |
   //+------------------------------------------------------------------+
   bool              BarCountReached()
     {
      static datetime CurrentTime=iTime(NULL,TimeFrame,0);

      if(CurrentTime!=iTime(NULL,TimeFrame,0))
        {
         CurrentTime=iTime(NULL,TimeFrame,0);
         barsSinceSetIsOpen++;

         if(barsSinceSetIsOpen >= nCandles)
            return (true);
         else
            return(false);
        }
      else
         return(false);
     }

   //+------------------------------------------------------------------+
   //|                                                                  |
   //+------------------------------------------------------------------+
   void              CheckForCloseLossCompensatedTrades(int& setIdx)
     {
      double totalProfit=ITset.profitAcum+REPset.profitAcum+LCTset.profitAcum+LCT2set.profitAcum;

      // Store maximumLossRecorded for later use in target profit calculation
      if(totalProfit < maximumLossRecorded)
         maximumLossRecorded=totalProfit;

      if((totalProfit >= 0 && breakEven) ||
         ((totalProfit >= MathAbs(maximumLossRecorded*(percentWon*0.01))) && !breakEven))
        {
         Print("*************************************************************************************************");
         Print("Set Nº",(string)(setIdx+1),": Closing all trades in IT + REPO + LCT + LCT2 at price ",Bid);
         Print("Profit acumulated in IT is: ",(string)NormalizeDouble(ITset.profitAcum,2));
         Print("Profit acumulated in REPO trades is: ",(string)NormalizeDouble(REPset.profitAcum,2));
         Print("Profit acumulated in LCT trades is: ",(string)NormalizeDouble(LCTset.profitAcum,2));
         Print("Profit acumulated in LCT2 trades is: ",(string)NormalizeDouble(LCT2set.profitAcum,2));
         Print("Profit IT + profit REPO + profit LCT + profit LCT2 = ",(string)NormalizeDouble(totalProfit,2));
         Print("And maximum loss recorded in set was = ",(string)NormalizeDouble(MathAbs(maximumLossRecorded),2)," %",
               (string)percentWon," = target profit of ",(string)MathAbs(maximumLossRecorded*(percentWon*0.01)));
         Print("*************************************************************************************************");

         CloseSubset(ITset);
         CloseSubset(REPset);
         CloseSubset(LCTset);
         CloseSubset(LCT2set);
         setOpen=false;
        }
      return;
     }

   //+------------------------------------------------------------------+
   //|                                                                  |
   //+------------------------------------------------------------------+
   void              CloseSubset(SubSet& subSet)
     {
      double priceClose;

      if(subSet.subSetOpen)
        {
         // Set this value to try and close all the trades at same price
         if(GetOrderType(subSet.ticket[0])==OP_BUY)
            priceClose=Bid;
         else
            priceClose=Ask;

         // Close all trades
         for(int tradeIdx=0; tradeIdx < subSet.nextTradeIdx; tradeIdx++)
           {
            if(OrderSelect(subSet.ticket[tradeIdx],SELECT_BY_TICKET))
               if(OrderCloseTime()==0 &&
                  OrderSymbol()==Symbol() &&
                  OrderMagicNumber()==MAGICMA)

                  if(OrderClose(OrderTicket(),OrderLots(),priceClose,Slippage,clrOrange))
                     Print(subSet.nameSubSet+" order Nº "+(string)subSet.ticket[tradeIdx]+" closed");
                  else
                     Print(subSet.nameSubSet+" order Nº "+(string)subSet.ticket[tradeIdx]+" failed to close: "+ErrorDescription(GetLastError()));
           }
        }
      return;
     }

   //+------------------------------------------------------------------+
   //|                                                                  |
   //+------------------------------------------------------------------+
   void              PrintAllTrades(int& setIdx)
     {
      Print("~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~");
      Print("┼---------------------------------------------------------------------------------------------------┼");
      Print("Trades for set nº "+(string)(setIdx+1)+" includes open trades:");

      if(ITset.subSetOpen)
         PrintTradesSubset(ITset);
      if(REPset.subSetOpen)
         PrintTradesSubset(REPset);
      if(LCTset.subSetOpen)
         PrintTradesSubset(LCTset);
      if(LCT2set.subSetOpen)
         PrintTradesSubset(LCT2set);

      Print("┼---------------------------------------------------------------------------------------------------┼");
      Print("ACCOUNT_BALANCE = "+(string)AccountInfoDouble(ACCOUNT_BALANCE));
      Print("ACCOUNT_MARGIN_FREE = "+(string)AccountInfoDouble(ACCOUNT_MARGIN_FREE));
      Print("ACCOUNT_MARGIN_LEVEL = "+(string)AccountInfoDouble(ACCOUNT_MARGIN_LEVEL));
      Print("ACCOUNT_EQUITY = "+(string)AccountInfoDouble(ACCOUNT_EQUITY));
      Print("┼---------------------------------------------------------------------------------------------------┼");

     }

   //+------------------------------------------------------------------+
   //|                                                                  |
   //+------------------------------------------------------------------+
   void              PrintTradesSubset(SubSet& subSet)

     {
      double totalProfit=0;

      Print("┼---------------------------------------------------------------------------------------------------┼");
      Print(subSet.nameSubSet+":");
      for(int tradeIdx=0; tradeIdx < subSet.nextTradeIdx; tradeIdx++)
        {
         if(OrderSelect(subSet.ticket[tradeIdx],SELECT_BY_TICKET))
            if(OrderSymbol() ==Symbol() && OrderMagicNumber()==MAGICMA)
               if(OrderCloseTime()==0)
                 {
                  totalProfit+=OrderProfit()+OrderCommission()+OrderSwap();
                  string type;
                  if(OrderType()==0)
                     type="BUY";
                  else
                     type="SELL";
                  Print("#",OrderTicket(),"  -> Order Type: ",type," - Lots: ",OrderLots()," - Profit: ",OrderProfit(),
                        " - Order Comission: ",OrderCommission()," - Order Swap: ",OrderSwap());
                 }
        }
      Print("Profit acumulated "+subSet.nameSubSet+": ",totalProfit);
      Print("┼---------------------------------------------------------------------------------------------------┼");
     }
  };

//+------------------------------------------------------------------+
