//+------------------------------------------------------------------+
//|                                             ENV_SPM_range_v7.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
string MAtrend()
  {
// trend acts as a counter for trends of each TF (above 0 is Bull, and below 0 is Bear)
   int trend=0;

   if(M1)
      maAverageForTF(PERIOD_M1,candlesToAvgM1,trend);
   if(M15)
      maAverageForTF(PERIOD_M15,candlesToAvgM15,trend);
   if(M30)
      maAverageForTF(PERIOD_M30,candlesToAvgM30,trend);
   if(H1)
      maAverageForTF(PERIOD_H1,candlesToAvgH1,trend);
   if(H4)
      maAverageForTF(PERIOD_H4,candlesToAvgH4,trend);
   if(D1)
      maAverageForTF(PERIOD_D1,candlesToAvgD1,trend);
   if(W1)
      maAverageForTF(PERIOD_W1,candlesToAvgW1,trend);
   if(MN)
      maAverageForTF(PERIOD_MN1,candlesToAvgMN,trend);

   if(trend<0)
      return("BEAR");

   if(trend>0)
      return("BULL");

   return("NULL");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//This func calculates the sum of the 2 MAs in a given number of candles, for each TF
void maAverageForTF(ENUM_TIMEFRAMES period,
                    int candlesToAvg,
                    int& trend)
  {
   string periodString;
   switch(period)
     {
      case PERIOD_M1:
         periodString="M1";
         break;
      case PERIOD_M15:
         periodString="M15";
         break;
      case PERIOD_M30:
         periodString="M30";
         break;
      case PERIOD_H1:
         periodString="H1";
         break;
      case PERIOD_H4:
         periodString="H4";
         break;
      case PERIOD_D1:
         periodString="D1";
         break;
      case PERIOD_W1:
         periodString="W1";
         break;
      case PERIOD_MN1:
         periodString="MN";
         break;
     }
   double ma1=0;
   double ma2=0;

   for(int i=startCandleMA; i<candlesToAvg+startCandleMA; i++)
     {
      ma1+=iMA(NULL,period,ma1Period,ma1Shift,ma1Method,ma1ApPrice,i);
      ma2+=iMA(NULL,period,ma2Period,ma2Shift,ma2Method,ma2ApPrice,i);
     }

   if((ma1Period<ma2Period && ma1>ma2)
      || (ma2Period<ma1Period && ma2>ma1))
     {
      Print("Trend of "+periodString+" is Bullish");
      trend++;
     }
   if((ma1Period<ma2Period && ma1<ma2)
      || (ma2Period<ma1Period && ma2<ma1))
     {
      Print("Trend of "+periodString+" is Bearish");
      trend--;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
// This function returns true if the price is in between the ranges desired, and also based on what "zone" it is,
// sets the direction of LCT trades to direction_LCT variable
bool InPriceRange(string& stringRange1,
                  string& stringRange2,
                  dir& direction_LCT)
  {
   static double  upperRange,lowerRange;
   double         aboveUpperRange,belowUpperRange,aboveLowerRange,belowLowerRange;
   bool           priceIsInRange=false;

   for(int i=startCandleLCTRange; i<LCTRangeCandles+startCandleLCTRange; i++)
     {
      if(i==startCandleLCTRange)
        {
         upperRange=iHigh(NULL,LCTRangeTF,i);
         lowerRange=iLow(NULL,LCTRangeTF,i);
        }
      else
        {
         if(iHigh(NULL,LCTRangeTF,i) > upperRange)
            upperRange=iHigh(NULL,LCTRangeTF,i);

         if(iLow(NULL,LCTRangeTF,i) < lowerRange)
            lowerRange=iLow(NULL,LCTRangeTF,i);
        }
     }

   aboveUpperRange=(upperRange + (upperRange-lowerRange)*aboveUpperRangePerc*0.01);
   belowUpperRange=(upperRange - (upperRange-lowerRange)*belowUpperRangePerc*0.01);
   aboveLowerRange=(lowerRange + (upperRange-lowerRange)*aboveLowerRangePerc*0.01);
   belowLowerRange=(lowerRange - (upperRange-lowerRange)*belowLowerRangePerc*0.01);

   if(Bid < aboveUpperRange && Bid > upperRange)
     {
      stringRange2=("Adding a %"+(string)aboveUpperRangePerc+" from this to the upper range is: "+(string)aboveUpperRange+
                       ". Actual price ("+(string)Bid+") is between upper range and above upper range lines.");
      direction_LCT=directionAboveUpperRange;
      priceIsInRange=true;
     }

   if(Bid < upperRange && Bid > belowUpperRange)
     {
      stringRange2=("Substracting a %"+(string)belowUpperRangePerc+" from this to the upper range is: "+(string)belowUpperRange+
                       ". Actual price ("+(string)Bid+") is between upper range and below upper range lines.");
      direction_LCT=directionBelowUpperRange;
      priceIsInRange=true;
     }

   if(Bid < aboveLowerRange && Bid > lowerRange)
     {
      stringRange2=("Adding a %"+(string)aboveLowerRangePerc+" from this to the lower range is: "+(string)aboveLowerRange+
                       ". Actual price ("+(string)Bid+") is between lower range and above lower range lines.");
      direction_LCT=directionAboveLowerRange;
      priceIsInRange=true;

     }

   if(Bid < lowerRange && Bid > belowLowerRange)
     {
      stringRange2=("Substracting a %"+(string)belowLowerRangePerc+" from this to the lower range is: "+(string)aboveLowerRange+
                       ". Actual price ("+(string)Bid+") is between lower range and above lower range lines.");
      direction_LCT=directionBelowLowerRange;
      priceIsInRange=true;
     }

   if(priceIsInRange)
      stringRange1=("Upper range is: "+(string)upperRange+" and lower range is: "+(string)lowerRange+
                       ". The difference between them is: "+(string)NormalizeDouble(upperRange-lowerRange,Digits));

   return(priceIsInRange);
  }

//+------------------------------------------------------------------+

