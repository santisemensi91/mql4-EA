//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckForOpenFirstInitialTrade()
  {
   int tradeDirection=-1;

//-------------------
// Entry Long logic:
//-------------------

   if((directionIT==PTF && speedometerValueBull > spmPoints) || (directionIT==CTF && speedometerValueBear < -spmPoints))
      tradeDirection=OP_BUY;

//--------------------
// Entry Short logic:
//--------------------

   if((directionIT==PTF && speedometerValueBear < -spmPoints) || (directionIT==CTF && speedometerValueBull > spmPoints))
      tradeDirection=OP_SELL;


   if(tradeDirection > -1)
     {
      if(setsCounter+2 > ArraySize(MainSet))
        {
         ArrayResize(MainSet,setsCounter+2,1000);
         setsCounter++;
         Print("~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~");
         Print("IT SET Nº "+(string)(setsCounter+1)+" STARTS");
         Print("~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~");
        }

      //Open 1º trade of IT set
      if(MainSet[setsCounter].ITset.OpenTrade(tradeDirection,setsCounter))
        {
         allowNewEntry=false; // ver quien manipula esto
         MainSet[setsCounter].setOpen=true;
        }
     }

   return;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckForOpenInitialTrades()
  {
   if(MainSet[setsCounter].ITset.subSetOpen==true &&
      MainSet[setsCounter].LCTset.subSetOpen==false &&
      MainSet[setsCounter].ITset.maxTradesReached==false)
     {
      // Get order type of the 1º IT and store it in variable for use in pyramid entries
      int ITorderType=GetOrderType(MainSet[setsCounter].ITset.ticket[0]);
      int tradeDirection=-1;
      double lastOrderOpenPrice=GetOrderOpenPrice(MainSet[setsCounter].ITset.ticket[MainSet[setsCounter].ITset.nextTradeIdx-1]);

      //-------------------
      // Entry Long logic:
      //-------------------

      if(ITorderType==OP_BUY &&
         ((directionIT==PTF && Ask > lastOrderOpenPrice+PtsToPrice(xPts)) ||
          (directionIT==CTF &&  Ask < lastOrderOpenPrice-PtsToPrice(xPts))))
         tradeDirection=OP_BUY;

      //--------------------
      // Entry Short logic:
      //--------------------

      if(ITorderType==OP_SELL &&
         ((directionIT==PTF && Bid < lastOrderOpenPrice-PtsToPrice(xPts)) ||
          (directionIT==CTF && Bid > lastOrderOpenPrice+PtsToPrice(xPts))))
         tradeDirection=OP_SELL;

      if(tradeDirection > -1)
         // Open next initial trade until reaching the maximum desired
         if(MainSet[setsCounter].ITset.OpenTrade(tradeDirection,setsCounter))
            MainSet[setsCounter].setOpen=true;

     }
   return;
  }

//+------------------------------------------------------------------+
