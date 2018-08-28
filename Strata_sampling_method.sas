/* Checking and fixing the data */
data pmlr.pva(drop=control_number 
                   MONTHS_SINCE_LAST_PROM_RESP 
                   FILE_AVG_GIFT 
                   FILE_CARD_GIFT);
   set pmlr.pva_raw_data;
   STATUS_FL=RECENCY_STATUS_96NK in("F","L");
   STATUS_ES=RECENCY_STATUS_96NK in("E","S");
   home01=(HOME_OWNER="H");
   nses1=(SES="1");
   nses3=(SES="3");
   nses4=(SES="4");
   nses_=(SES="?");
   nurbr=(URBANICITY="R");
   nurbu=(URBANICITY="U");
   nurbs=(URBANICITY="S");
   nurbt=(URBANICITY="T");
   nurb_=(URBANICITY="?");
run;

proc contents data=pmlr.pva;
run;

proc means data=pmlr.pva mean nmiss max min;
   var _numeric_;
run;

proc freq data=pmlr.pva nlevels;
   tables _character_;
run;


/* Spliting the data into two - test and valid datasets */
proc sort data=pmlr.pva out=work.pva_sort;
   by target_b;
run;

proc sort data=pmlr.pva out=work.pva_sort;
   by target_b;
run;

proc surveyselect noprint data=work.pva_sort 
                  samprate=0.5 out=pva_sample seed=27513 
                  outall stratumseed=restore;
   strata target_b;
run;

data pmlr.pva_train(drop=selected SelectionProb SamplingWeight)
     pmlr.pva_valid(drop=selected SelectionProb SamplingWeight);
   set work.pva_sample;
   if selected then output pmlr.pva_train;
   else output pmlr.pva_valid;
run;
