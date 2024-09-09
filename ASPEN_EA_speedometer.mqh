//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2018, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
struct speed_data
  {
   double            price;
   datetime          time;
   uint              timeMsc;
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SpeedometerSeconds(double& maxBearDif, double& maxBullDif)
  {
   static int i=0;
   static double priceDif=0;
   double maxPrice=0;
   double minPrice=0;
   maxBullDif=0;
   maxBearDif=0;
   int maxPriceIdx=0;
   int minPriceIdx=0;
   int o=0;

// Tick by tick stores price and time value
   ArrayResize(speed_arr,i+1);
   speed_arr[i].price=Bid;
   speed_arr[i].time=TimeCurrent();
   i++;

   if(i==1)
      return;

//Look for the last tick that meets the required seconds

   if(speed_arr[i-1].time - speed_arr[o].time >= spmSeconds)
     {
      do
         o++;
      while(speed_arr[i-1].time - speed_arr[o].time >= spmSeconds);

      o--;

      for(int a=0; a<o; a++)
         MoveSpeedArray(speed_arr,i);


      i-=o;
      o=0;

      for(int idx=0; idx<i; idx++)
        {
         if(idx==0)
           {
            maxPrice=speed_arr[idx].price;
            maxPriceIdx=idx;
            minPrice=speed_arr[idx].price;
            minPriceIdx=idx;

            continue;
           }
         if(maxPrice < speed_arr[idx].price)
           {
            maxPrice=speed_arr[idx].price;
            maxPriceIdx=idx;
           }
         if(minPrice > speed_arr[idx].price)
           {
            minPrice=speed_arr[idx].price;
            minPriceIdx=idx;
           }

         if(speed_arr[idx].price - minPrice > maxBullDif && idx > minPriceIdx && speed_arr[idx].price > minPrice)
            maxBullDif=speed_arr[idx].price - minPrice;

         if(speed_arr[idx].price - maxPrice < maxBearDif && idx > maxPriceIdx && speed_arr[idx].price < maxPrice)
            maxBearDif=speed_arr[idx].price - maxPrice;

        }
      maxBearDif=NormalizeDouble(PriceToPts(maxBearDif),0);
      maxBullDif=NormalizeDouble(PriceToPts(maxBullDif),0);
     }

   Comment("Max points moved in the last "+(string)spmSeconds+
           " seconds:\nBearish: "+
           (string)maxBearDif+
           "\nBullish: "+(string)maxBullDif+
           "\n\nSpread is: "+IntegerToString((int)MarketInfo(Symbol(),MODE_SPREAD)));

   return;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SpeedometerMsc(double& maxBearDif, double& maxBullDif)

  {
   static int i=0;
   static double priceDif=0;
   double maxPrice=0;
   double minPrice=0;
   maxBearDif=0;
   maxBullDif=0;
   int maxPriceIdx=0;
   int minPriceIdx=0;
   int o=0;


   ArrayResize(speed_arr,i+1);
   speed_arr[i].price=Bid;
   speed_arr[i].timeMsc=GetTickCount();
   i++;

   if(i==1)
      return;

//Look for the last tick that meets the required milliseconds

   if(speed_arr[i-1].timeMsc - speed_arr[o].timeMsc >= spmMsc)
     {
      do
         o++;
      while(speed_arr[i-1].timeMsc - speed_arr[o].timeMsc >= spmMsc);

      o--;



      for(int a=0; a<o; a++)
         MoveSpeedArray(speed_arr,i);

      i-=o;
      o=0;

      for(int idx=0; idx<i; idx++)
        {
         if(idx==0)
           {
            maxPrice=speed_arr[idx].price;
            maxPriceIdx=idx;
            minPrice=speed_arr[idx].price;
            minPriceIdx=idx;

            continue;
           }
         if(maxPrice < speed_arr[idx].price)
           {
            maxPrice=speed_arr[idx].price;
            maxPriceIdx=idx;
           }
         if(minPrice > speed_arr[idx].price)
           {
            minPrice=speed_arr[idx].price;
            minPriceIdx=idx;
           }

         if(speed_arr[idx].price - minPrice > maxBullDif && idx > minPriceIdx && speed_arr[idx].price > minPrice)
            maxBullDif=speed_arr[idx].price - minPrice;

         if(speed_arr[idx].price - maxPrice < maxBearDif && idx > maxPriceIdx && speed_arr[idx].price < maxPrice)
            maxBearDif=speed_arr[idx].price - maxPrice;


        }
      maxBearDif=NormalizeDouble(PriceToPts(maxBearDif),0);
      maxBullDif=NormalizeDouble(PriceToPts(maxBullDif),0);
     }

   Comment("Max points moved in the last "+(string)spmMsc+
           " milliseconds:\nBearish: "+
           (string)maxBearDif+
           "\nBullish: "+(string)maxBullDif+
           "\n\nSpread is: "+IntegerToString((int)MarketInfo(Symbol(),MODE_SPREAD)));

   return;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MoveSpeedArray(speed_data& _speedArr[],int o)
  {
   for(int i=1; i<o; i++)
     {
      _speedArr[i-1].price=_speedArr[i].price;
      _speedArr[i-1].time=_speedArr[i].time;
      _speedArr[i-1].timeMsc=_speedArr[i].timeMsc;
     }
   return;
  }
//+------------------------------------------------------------------+
