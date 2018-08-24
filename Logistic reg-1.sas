ods graphics on;

proc logistic data=statdata.safety plots(only)=(effect oddsratio);
   format Size sizefmt.;
   class Region (param=ref ref='Asia')
         Size (param=ref ref='1');
   model Unsafe(event='1')=Weight Region Size / clodds=pl selection=backward;
   units weight=-1;
   store isSafe;
   
   title 'LOGISTIC MODEL: Backwards Elimination';
run;

title;


data checkSafety;
   length Region $9.;
	 input Weight Size Region $ 5-13;
	 datalines;
4 1 N America
3 1 Asia     
5 3 Asia     
5 2 N America
;
run;

proc plm restore=isSafe;
score data=checkSafety out=scored_cars / ILINK;
title 'Safety Predictions using PROC PLM';
run;

proc print data=scored_cars;
run;

title;
