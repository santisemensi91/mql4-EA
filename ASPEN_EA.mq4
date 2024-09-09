//+------------------------------------------------------------------+
//|                                                      SPM_LCT.mq4 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Santiago Semensi"
#property link      "https://www.mql5.com"
#property version   "1.0"
#property strict

#include <stderror.mqh>
#include <stdlib.mqh>

enum dir {CTF=0,PTF=1,BUY=2,SELL=3};
enum ammount {Balance=0,FreeMargin=1,TradesPercentage=2};
enum ammountIT  {balance=0,freeMargin=1};

input string             Settings;//---------- Main Settings ----------

input int                MAGICMA = 6813; //Magic number
extern int               Slippage = 20;   //Slippage
input ENUM_TIMEFRAMES    TimeFrame = PERIOD_CURRENT;
input int                SLentry=400;  //Stop Loss
input int                TPentry= 100; //Take Profit
input bool               UseTrailingStop=false; //Use Trailing Stop
input int                trailingStop= 50; //Trailing Stop Distance
input int                trailingStopStep= 10; //Trailing Stop Step
input int                trailingStopStart= 50; //Trailing Stop Start
input int                spmPoints=100; //SPM Min Points
input int                spmSeconds=60; //SPM Max Seconds
input uint               spmMsc=0; //SPM Milliseconds (to use set seconds to 0)
input int                minVolume=10; //Min Volume to enter IT
input ENUM_TIMEFRAMES    tfVolume=PERIOD_CURRENT; //TF applied to Volume
input int                minMarginLevel=100; //Min % Margin Level


input string             Parameters;//---------- IT & REPO Settings ----------

input color              colorITbuy=clrGreen; //Arrow color IT buy
input color              colorITsell=clrRed; //Arrow color IT sell
input int                spreadFilter=0; //Max Spread allowed (0 to switch off)
input dir                directionIT =0; //Direction IT
input ammountIT          ammountRiskedIT=1; //Balance/FM risked for IT
extern double            RFinitial=0.01; //% risked for IT
input double             lotsMultFactorIT=2; //Lots Multiplication factor IT
input int                nCandles = 60; //Nº of candles to restart func
input int                maxTrades = 5; //Max Trades IT for selected direction
input int                xPts = 20; //x Points for next trade

input color              colorREPObuy=clrMediumSeaGreen; //Arrow color REPO buy
input color              colorREPOsell=clrSalmon; //Arrow color REPO sell
input int                maxTradesREPO=7; //Max trades REPO (0 switchs off)


input string             LCTsettings;//---------- LCT Settings ----------

input color              colorLCTbuy=clrBlue; //Arrow color LCT buy
input color              colorLCTsell=clrDeepPink; //Arrow color LCT sell
input dir                directionLCT=0; //LCT direction
input int                xPtsLCT=10;     //LCT x Points for next trade
input ammount            ammountRiskedLCT=1; //Balance/FM/Set% in loss to start LCT
input double             percentLossLCT=0.5; //% Balance/FM in loss to LCT (0 switchs off)
input bool               breakEven=false; //CTIL at Breakeven
input double             percentWon=10;   //% won to CTIL (if above false)
input int                maxTradesLCT=5; //Max trades LCT
input double             lotsMultFactorLCT=2; //Lots Multiplication factor LCT


input string             LCT2settings;//---------- LCT2 Settings ----------

input color              colorLCT2buy=clrDarkBlue; //Arrow color LCT2 buy
input color              colorLCT2sell=clrDarkViolet; //Arrow color LCT2 sell
input dir                directionLCT2=0;  //LCT2 direction
input int                xPtsLCT2=10;      //LCT2 x Points for next trade
input ammount            ammountRiskedLCT2=1; //Balance/FM/Set% in loss to start LCT2
input double             percentLossLCT2=0.5; //% Balance/FM in loss to LCT2 (0 switchs off)
input int                maxTradesLCT2=5;  //Max trades LCT2
input double             lotsMultFactorLCT2=2; //Lots Multiplication factor LCT2

input string             MAsettings;//---------- LCT MA Trend Settings ----------

input bool               LCTMaOn=true; //On / Off
input int                ma1Period=5; //MA1 Period
input int                ma1Shift=0; //MA1 Shift
input ENUM_MA_METHOD     ma1Method=MODE_SMA; //MA1 Method
input ENUM_APPLIED_PRICE ma1ApPrice=PRICE_CLOSE; //MA1 Applied price
input int                ma2Period=13; //MA2 Period
input int                ma2Shift=0; //MA2 Shift
input ENUM_MA_METHOD     ma2Method=MODE_SMA; //MA2 Method
input ENUM_APPLIED_PRICE ma2ApPrice=PRICE_CLOSE; //MA2 Applied price
input bool               M1=false;
input int                candlesToAvgM1=5; //Number of candles to average M1
input bool               M15=false;
input int                candlesToAvgM15=5; //Number of candles to average M15
input bool               M30=false;
input int                candlesToAvgM30=5; //Number of candles to average M30
input bool               H1=false;
input int                candlesToAvgH1=5; //Number of candles to average H1
input bool               H4=false;
input int                candlesToAvgH4=5; //Number of candles to average H4
input bool               D1=true;
input int                candlesToAvgD1=5; //Number of candles to average D1
input bool               W1=true;
input int                candlesToAvgW1=5; //Number of candles to average W1
input bool               MN=true;
input int                candlesToAvgMN=5; //Number of candles to average MN
input int                tfToMatch=2; //Number of TF to match
input int                startCandleMA=0; //Start counting from candle: (0 is current)

input string             LCTrange;//---------- LCT range direction ----------

input bool               LCTRangeDirectionOn=true; //On / Off
input int                LCTRangeCandles=20;    //Number of candles to consider the range
input int                startCandleLCTRange=1;    //Start counting from candle: (0 is current)
input ENUM_TIMEFRAMES    LCTRangeTF=PERIOD_CURRENT;//Apply range to TF
input int                aboveUpperRangePerc=50; //% Above upper range
input dir                directionAboveUpperRange=1; //Direction from upper range to % above it
input int                belowUpperRangePerc=20; //% Below upper range
input dir                directionBelowUpperRange=1; //Direction from upper range to % below it
input int                aboveLowerRangePerc=20; //% Above lower range
input dir                directionAboveLowerRange=0; //Direction from lower range to % above it
input int                belowLowerRangePerc=50; //% Below lower range
input dir                directionBelowLowerRange=0; //Direction from lower range to % below it

input string             Hours;//- Trading Hours (leave blank to switch off) -

input string             Time_on1="00:00";  //Start Hour/Minute 1
input string             Time_off1="23:55"; //Stop Hour/Minute 1
input string             Time_on2=""; //Start Hour/Minute 2
input string             Time_off2=""; //Stop Hour/Minute 2
input string             Time_on3=""; //Start Hour/Minute 3
input string             Time_off3=""; //Stop Hour/Minute 3
input string             Time_on4=""; //Start Hour/Minute 4
input string             Time_off4=""; //Stop Hour/Minute 4
input string             Time_on5=""; //Start Hour/Minute 5
input string             Time_off5=""; //Stop Hour/Minute 5

#include <ASPEN_EA_initial_trades.mqh>
#include <ASPEN_EA_classes.mqh>
#include <ASPEN_EA_speedometer.mqh>
#include <ASPEN_EA_range_funcs.mqh>
#include <ASPEN_EA_functions.mqh>
#include <ASPEN_EA_main_loop_funcs.mqh>

speed_data speed_arr[];

MainSetManipulator           MainSet[];

double speedometerValueBull,speedometerValueBear,MA1,MA2;

static bool allowNewEntry=true;
int barCount=0;
int setsCounter=-1;
bool newB;

double stopMin=PtsToPrice(SymbolInfoInteger(NULL,SYMBOL_TRADE_STOPS_LEVEL));

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   int tfCounter=0;

   if(M1==true)
      tfCounter++;
   if(M15==true)
      tfCounter++;
   if(M30==true)
      tfCounter++;
   if(H1==true)
      tfCounter++;
   if(H4==true)
      tfCounter++;
   if(D1==true)
      tfCounter++;
   if(W1==true)
      tfCounter++;
   if(MN==true)
      tfCounter++;

   if(LCTMaOn==true && (tfToMatch > tfCounter || (tfCounter%tfToMatch==0 && tfCounter!=tfToMatch) || tfToMatch < tfCounter/2))
     {
      Alert("Check TF selected and number of TF to match");
      return(INIT_FAILED);
     }

   if(LCTMaOn==true && (candlesToAvgM1<1 ||
                         candlesToAvgM15<1 ||
                         candlesToAvgM30<1 ||
                         candlesToAvgH1<1 ||
                         candlesToAvgH4<1 ||
                         candlesToAvgD1<1 ||
                         candlesToAvgW1<1 ||
                         candlesToAvgMN<1))
     {
      Alert("Candles to average has to be at least 1");
      return(INIT_FAILED);
     }

   if(PtsToPrice(SLentry)<stopMin || PtsToPrice(TPentry)<stopMin)
     {
      Alert("SL pips are less than allowed by asset");
      return(INIT_FAILED);
     }
   if(maxTrades < 1)
     {
      Alert("Max Trades input has to be bigger than 0");
      return(INIT_FAILED);
     }

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//Just to visualize in tester chart
   if(LCTMaOn)
     {
      MA1=iMA(NULL,0,ma1Period,ma1Shift,ma1Method,ma1ApPrice,0);
      MA2=iMA(NULL,0,ma2Period,ma2Shift,ma2Method,ma2ApPrice,0);
     }

   if(Bars<100 || IsTradeAllowed()==false)
      return;

// If any of this happens means that it's allowed to enter first trades again

   if(!allowNewEntry)
      if(MainSet[setsCounter].LCTset.subSetOpen==true ||
         (MainSet[setsCounter].BarCountReached() &&
          MainSet[setsCounter].ITset.subSetOpen==false &&
          MainSet[setsCounter].REPset.subSetOpen==false))
         allowNewEntry=true;


//SPM value

   if(spmSeconds!=0)
     {
      SpeedometerSeconds(speedometerValueBear,speedometerValueBull);
     }
   else
      SpeedometerMsc(speedometerValueBear,speedometerValueBull);

   if(IsAGoodTime() && AccountInfoDouble(ACCOUNT_MARGIN_LEVEL) >= minMarginLevel)
     {
      if(allowNewEntry
         && ((int)MarketInfo(Symbol(),MODE_SPREAD) <= spreadFilter || spreadFilter==0)
         && iVolume(NULL,tfVolume,0) >= minVolume)
         CheckForOpenFirstInitialTrade();

      if(!allowNewEntry &&
         maxTrades > 1 &&
         ((int)MarketInfo(Symbol(),MODE_SPREAD) <= spreadFilter || spreadFilter==0))
         CheckForOpenInitialTrades();

      MainLoop();
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
