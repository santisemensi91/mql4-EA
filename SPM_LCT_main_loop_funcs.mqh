//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MainLoop()
  {
   for(int setIdx=0; setIdx<=setsCounter; setIdx++)
     {
      if(MainSet[setIdx].setOpen)
        {
         if(UseTrailingStop && MainSet[setIdx].LCTset.subSetOpen==false)
            TrailingStopStep(setIdx);

         // Get trades data from IT and REP subsets still flagged as open
         if(MainSet[setIdx].ITset.subSetOpen==true)
            MainSet[setIdx].ITset.GetTradesData();

         if(MainSet[setIdx].REPset.subSetOpen==true)
            MainSet[setIdx].REPset.GetTradesData();

         //Flag set as closed if bar count reached and IT and REP are closed
         if(MainSet[setIdx].BarCountReached() &&
            MainSet[setIdx].ITset.subSetOpen==false &&
            MainSet[setIdx].REPset.subSetOpen==false)
           {
            MainSet[setIdx].setOpen=false;
            continue;
           }

         if(MainSet[setIdx].LCTset.subSetOpen==true)
           {
            MainSet[setIdx].LCTset.GetTradesData();
            if(MainSet[setIdx].LCT2set.subSetOpen==true)
               MainSet[setIdx].LCT2set.GetTradesData();

            // Check if added profit of all subSets meet requirements to close them
            MainSet[setIdx].CheckForCloseLossCompensatedTrades(setIdx);
           }
         // Check if REP trades need to open
         if(MainSet[setIdx].LCTset.subSetOpen==false)
            MainSet[setIdx].REPset.CheckForOpenRepetitionTrade(setIdx);
        }

      // If after GetTradesData() IT or REP subsets are still open, check for LCT opening
      if((MainSet[setIdx].ITset.subSetOpen==true || MainSet[setIdx].REPset.subSetOpen==true)
         && percentLossLCT!=0.0
         && MainSet[setIdx].LCT2set.subSetOpen==false)
        {
         CheckForOpenLCT(setIdx);

         if(MainSet[setIdx].LCTset.subSetOpen==true)
            CheckForOpenLCT2(setIdx);
        }
     }
   return;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckForOpenLCT(int& setIdx)
  {
   string stringRange1,stringRange2;
   bool priceIsInRangeDesired=false;

// Need to check some conditions before first LCT opens
   if(MainSet[setIdx].LCTset.subSetOpen==false)
     {
      //Determine direction for LCT depending if LCTRangeDirectionOn is true or not
      if(LCTRangeDirectionOn)
         priceIsInRangeDesired=InPriceRange(stringRange1,stringRange2,MainSet[setIdx].LCTset.direction_LCT);
      else // Use global variable for direction
         MainSet[setIdx].LCTset.direction_LCT=directionLCT;
     }

//Check if LCTset is open already or needs to be
   if(percentLossLCT!=0.0 && ((MainSet[setIdx].LCTset.subSetOpen==true &&
                               !MainSet[setIdx].LCTset.maxTradesReached &&
                               MainSet[setIdx].LCTset.CheckIfPriceIsAboveHighestOrBelowLowestTrades()) ||
                              ((!LCTRangeDirectionOn || (LCTRangeDirectionOn && priceIsInRangeDesired)) &&
                               MainSet[setIdx].LCTset.CheckIfLossCompensationNeeded(setIdx,MainSet[setIdx].ITset,MainSet[setIdx].REPset))))
     {

      //If LCTset.subSetOpen was false means that LCT can start so new IT can come
      if(MainSet[setIdx].LCTset.subSetOpen==false)
        {
         // If LCTMaOn and trend is NULL, return
         // If !LCTMaOn determines the "trend" according to the IT trade direction
         if(LCTMaOn)
           {
            MainSet[setIdx].ITset.trend=MAtrend();
            if(MainSet[setIdx].ITset.trend=="NULL")
               return;
           }
         else
            if(GetOrderType(MainSet[setIdx].ITset.ticket[0])==OP_BUY)
               MainSet[setIdx].ITset.trend="BULL";
            else
               MainSet[setIdx].ITset.trend="BEAR";

         // Define trade direction for the rest of subSet life spam, storing it in class variable
         if((MainSet[setIdx].LCTset.direction_LCT==PTF && MainSet[setIdx].ITset.trend=="BULL") ||
            (MainSet[setIdx].LCTset.direction_LCT==CTF && MainSet[setIdx].ITset.trend=="BEAR") ||
            MainSet[setIdx].LCTset.direction_LCT==BUY)
            MainSet[setIdx].LCTset.finalDirection=OP_BUY;

         if((MainSet[setIdx].LCTset.direction_LCT==CTF && MainSet[setIdx].ITset.trend=="BULL") ||
            (MainSet[setIdx].LCTset.direction_LCT==PTF && MainSet[setIdx].ITset.trend=="BEAR") ||
            MainSet[setIdx].LCTset.direction_LCT==SELL)
            MainSet[setIdx].LCTset.finalDirection=OP_SELL;

         // Try to open first loss compensation trade
         if(MainSet[setIdx].LCTset.OpenTrade(MainSet[setIdx].LCTset.finalDirection,setIdx))
           {
            // Print information about price range
            if(LCTRangeDirectionOn)
              {
               Print(stringRange1);
               Print(stringRange2);
               Print("~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~");
              }

            //Remove SL and TP from Initial Trades
            removeTPandSLfromSubSet(MainSet[setIdx].ITset);

            //Remove SL and TP from REP Trades
            if(MainSet[setIdx].REPset.subSetOpen==true)
               removeTPandSLfromSubSet(MainSet[setIdx].REPset);

            //Print all trades each time LCT opens to see the profit of all trades
            MainSet[setIdx].PrintAllTrades(setIdx);

            MainSet[setIdx].setOpen=true;

            allowNewEntry=true;
           }
        }

      if(MainSet[setIdx].LCTset.OpenTrade(MainSet[setIdx].LCTset.finalDirection,setIdx))
        {
         MainSet[setIdx].setOpen=true;
         MainSet[setIdx].PrintAllTrades(setIdx);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckForOpenLCT2(int& setIdx)
  {
   if(percentLossLCT2!=0.0 && ((MainSet[setIdx].LCT2set.subSetOpen==true &&
                                !MainSet[setIdx].LCT2set.maxTradesReached &&
                                MainSet[setIdx].LCT2set.CheckIfPriceIsAboveHighestOrBelowLowestTrades()) ||
                               MainSet[setIdx].LCT2set.CheckIfLossCompensationNeeded(setIdx,MainSet[setIdx].LCTset,MainSet[setIdx].LCTset)))
     {
      if(MainSet[setIdx].LCT2set.subSetOpen==false)
        {
         if((MainSet[setIdx].LCTset.finalDirection==OP_BUY && directionLCT2==PTF) ||
            (MainSet[setIdx].LCTset.finalDirection==OP_SELL && directionLCT2==CTF) ||
            directionLCT2==BUY)
            MainSet[setIdx].LCT2set.finalDirection=OP_BUY;

         if((MainSet[setIdx].LCTset.finalDirection==OP_SELL && directionLCT2==PTF) ||
            (MainSet[setIdx].LCTset.finalDirection==OP_BUY && directionLCT2==CTF) ||
            directionLCT2==SELL)
            MainSet[setIdx].LCT2set.finalDirection=OP_SELL;
        }

      if(MainSet[setIdx].LCT2set.OpenTrade(MainSet[setIdx].LCT2set.finalDirection,setIdx))
        {
         MainSet[setIdx].setOpen=true;
         MainSet[setIdx].PrintAllTrades(setIdx);
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
