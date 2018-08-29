/* LOGISTIC model of a biased sample*/
/* estimate paramters will be adjusted in Proc logistic by PRIOREVCENT staement */

%global ex_pi1;

proc sql;
select mean(Target_B) into :ex_pi1
from pmlr.pva_raw_data;
quit;

%put &ex_pi1;

title1 "Logistic Regression Model of the Veterans' Organization Data";
proc logistic data=pmlr.pva_train plots(only MAXPOINTS=NONE)=
              (effect(clband x=(pep_star recent_avg_gift_amt
              frequency_status_97nk)) oddsratio (type=horizontalstat));
   class pep_star (param=ref ref='0');
   model target_b(event='1')=pep_star recent_avg_gift_amt
                  frequency_status_97nk / clodds=pl;
   effectplot slicefit(sliceby=pep_star x=recent_avg_gift_amt) / noobs; 
   effectplot slicefit(sliceby=pep_star x=frequency_status_97nk) / noobs; 
   score data=pmlr.pva_train out=work.scopva_train priorevent=&ex_pi1;
run;

title1 "Adjusted Predicted Probabilities of the Veteran's Organization Data";
proc print data=work.scopva_train(obs=10);
   var p_1 pep_star recent_avg_gift_amt frequency_status_97nk;
run;
title;
