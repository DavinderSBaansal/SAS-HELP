
/* Code for the Practices in the SAS e-Course 
   "Predictive Modeling Using Logistic Regression" */


/* The practices in this SAS e-course build on each 
other. If you started a new SAS session since you
ran the previous practice(s), you need to set up access
to the course files (see the Course Overview and Data Setup)
and then re-run the code from the previous practices before 
you perform the current practice. 

This page contains the code for all of the practices
in the e-course. The title of each practice appears
in a comment above the code for that practice.

To re-run the code for previous practices, follow 
these steps:

1. On this page, find the title of the practice you
   want to perform.
2. Select all of the code on this page above that title
   (the code for previous practices) and paste it into 
   the editor in your SAS software.
3. Before you submit the code, make any necessary 
   modifications to the code, if indicated in comments.
   Note: Most of the code requires no modifications.
4. Submit the code and check the log to verify that it
   ran without errors.

After performing the steps above, you are ready to proceed 
with the current practice!
*/

/* ===================================================== */
/* Lesson 1, Section 1:
   Practice: Exploring the Veterans' Organization Data 
   Used in the Practices
   [m641_1_p2; derived from pmlr00e01.sas]               */
/* ===================================================== */

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


/* ===================================================== */
/* Lesson 1, Section 2:
   Practice: Splitting the Data
   [m641_2_p; derived from pmlr01s01.sas]                */
/* ===================================================== */

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


/* ===================================================== */
/* Lesson 2, Section 2:
   Practice: Fitting a Logistic Regression Model
   [m642_2_p; derived from pmlr02s01.sas]                */
/* ===================================================== */

/* Modifications for your SAS software:
   ------------------------------------------------------
   (Optional) To avoid a warning in the log about the 
   suppression of plots that have more than 5000 
   observations, you can add the MAXPOINTS= option 
   to the PROC LOGISTIC statement like this: 
   plots(maxpoints=none only). Omitting the 
   MAXPOINTS= option does not affect the results 
   of the practices in this course. 
*/

%global ex_pi1;
%let ex_pi1=0.05;

title1 "Logistic Regression Model of the Veterans' Organization Data";
proc logistic data=pmlr.pva_train plots(only)=
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


/* ===================================================== */
/* Lesson 3, Section 1:
   Practice: Imputing Missing Values
   [m643_1_p; derived from pmlr03s01.sas]                */
/* ===================================================== */

data pmlr.pva_train_mi(drop=i);
   set pmlr.pva_train;
   /* name the missing indicator variables */
   array mi{*} mi_DONOR_AGE mi_INCOME_GROUP 
               mi_WEALTH_RATING;
   /* select variables with missing values */
   array x{*} DONOR_AGE INCOME_GROUP WEALTH_RATING;
   do i=1 to dim(mi);
      mi{i}=(x{i}=.);
      nummiss+mi{i};
   end;
run;

proc rank data=pmlr.pva_train_mi out=work.pva_train_rank 
          groups=3;
   var recent_response_prop recent_avg_gift_amt;
   ranks grp_resp grp_amt;
run;

proc sort data=work.pva_train_rank out=work.pva_train_rank_sort;
   by grp_resp grp_amt;
run;

proc stdize data=work.pva_train_rank_sort method=median
            reponly out=pmlr.pva_train_imputed;
   by grp_resp grp_amt;
   var DONOR_AGE INCOME_GROUP WEALTH_RATING;
run;

options nolabel;
proc means data=pmlr.pva_train_imputed median;
   class grp_resp grp_amt;
   var DONOR_AGE INCOME_GROUP WEALTH_RATING;
run;
options label;


/* ===================================================== */
/* Lesson 3, Section 2:
   Practice: Collapsing the Levels of a Nominal Input
   [m643_2_p; derived from pmlr03s02.sas] 
    
   Note: After you submit this code, a note in the log 
   indicates that argument 3 to the LOGSDF function 
   is invalid. You can ignore this note; it is not 
   important for this analysis. The note pertains 
   to the situation in which the number of clusters is 1. 
   In this case, the degrees of freedom is 0 (degrees of 
   freedom is equal to the number of clusters minus 1) and 
   the mathematical operation cannot be performed in the 
   LOGSDF function. Therefore, the log of the p-value is 
   set to missing.               */
/* ===================================================== */

proc means data=pmlr.pva_train_imputed noprint nway;
   class cluster_code;
   var target_b;
   output out=work.level mean=prop;
run;

ods output clusterhistory=work.cluster;

proc cluster data=work.level method=ward 
             outtree=work.fortree
             plots=(dendrogram(horizontal height=rsq));
   freq _freq_;
   var prop;
   id cluster_code;
run;

proc freq data=pmlr.pva_train_imputed noprint;
   tables cluster_code*target_b / chisq;
   output out=work.chi(keep=_pchi_) chisq;
run;

data work.cutoff;
   if _n_=1 then set work.chi;
   set cluster;
   chisquare=_pchi_*rsquared;
   degfree=numberofclusters-1;
   logpvalue=logsdf('CHISQ',chisquare,degfree);
run;

title1 "Plot of the Log of the P-Value by Number of Clusters";
proc sgplot data=work.cutoff;
   scatter y=logpvalue x=numberofclusters 
           / markerattrs=(color=blue symbol=circlefilled);
   xaxis label="Number of Clusters";
   yaxis label="Log of P-Value" min=-40 max=0;
run;

title1; 

%global ncl;

proc sql;
   select NumberOfClusters into :ncl
   from work.cutoff
   having logpvalue=min(logpvalue);
quit;

proc tree data=work.fortree nclusters=&ncl 
          out=work.clus noprint;
   id cluster_code;
run;

proc sort data=work.clus;
   by clusname;
run;

title1 "Cluster Assignments";
proc print data=work.clus;
   by clusname;
   id clusname;
run;

filename clcode "&PMLRfolder/cluster_code.sas";

data _null_;
   file clcode;
   set work.clus end=last;
   if _n_=1 then put "select (cluster_code);";
   put "  when ('" cluster_code +(-1) "') 
          cluster_clus='" cluster +(-1) "';";
   if last then do;
      put "  otherwise cluster_clus='U';" / "end;";
   end;
run;

data pmlr.pva_train_imputed_clus;
   set pmlr.pva_train_imputed;
   %include clcode;
run;


/* ===================================================== */
/* Lesson 3, Section 2:
   Practice: Computing the Smoothed Weight of Evidence
   [m643_2_p3; derived from pmlr03s03.sas]               */
/* ===================================================== */

%global rho1_ex;
proc sql noprint;
   select mean(target_b) into :rho1_ex
   from pmlr.pva_train_imputed;
run; 

proc means data=pmlr.pva_train_imputed 
           sum nway noprint;
   class cluster_code;
   var target_b;
   output out=work.counts sum=events;
run;

filename clswoe "&PMLRfolder/swoe_cluster.sas";

data _null_;
   file clswoe;
   set work.counts end=last;
      logit=log((events + &rho1_ex*24)/
                (_FREQ_ - events + (1-&rho1_ex)*24));
   if _n_=1 then put "select (cluster_code);" ;
   put "  when ('" cluster_code +(-1) "') cluster_swoe=" logit ";" ;
   if last then do;
      logit=log(&rho1_ex/(1-&rho1_ex));
      put "  otherwise cluster_swoe=" logit ";" / "end;";
   end;
run;

data pmlr.pva_train_imputed_swoe;
   set pmlr.pva_train_imputed;
   %include clswoe;
run;

title;

proc print data=pmlr.pva_train_imputed_swoe(obs=1);
   where cluster_code = "01";
   var cluster_code cluster_swoe;
run;


/* ===================================================== */
/* Lesson 3, Section 3:
   Practice: Reducing Redundancy by Clustering Variables
   [m643_3_p; derived from pmlr03s04.sas]                */
/* ===================================================== */

/*Note: If you run this code in 32-bit SAS, the variable 
   assignments to clusters might vary from what is shown 
   in the results in this course. This discrepancy does 
   not affect the results of the remaining practices in 
   this course.
*/

%let ex_inputs= MONTHS_SINCE_ORIGIN 
DONOR_AGE IN_HOUSE INCOME_GROUP PUBLISHED_PHONE
MOR_HIT_RATE WEALTH_RATING MEDIAN_HOME_VALUE
MEDIAN_HOUSEHOLD_INCOME PCT_OWNER_OCCUPIED
PER_CAPITA_INCOME PCT_MALE_MILITARY 
PCT_MALE_VETERANS PCT_VIETNAM_VETERANS 
PCT_WWII_VETERANS PEP_STAR RECENT_STAR_STATUS
FREQUENCY_STATUS_97NK RECENT_RESPONSE_PROP
RECENT_AVG_GIFT_AMT RECENT_CARD_RESPONSE_PROP
RECENT_AVG_CARD_GIFT_AMT RECENT_RESPONSE_COUNT
RECENT_CARD_RESPONSE_COUNT LIFETIME_CARD_PROM 
LIFETIME_PROM LIFETIME_GIFT_AMOUNT
LIFETIME_GIFT_COUNT LIFETIME_AVG_GIFT_AMT 
LIFETIME_GIFT_RANGE LIFETIME_MAX_GIFT_AMT
LIFETIME_MIN_GIFT_AMT LAST_GIFT_AMT
CARD_PROM_12 NUMBER_PROM_12 MONTHS_SINCE_LAST_GIFT
MONTHS_SINCE_FIRST_GIFT STATUS_FL STATUS_ES
home01 nses1 nses3 nses4 nses_ nurbr nurbu nurbs 
nurbt nurb_;

ods select none;
ods output clusterquality=work.summary
           rsquare=work.clusters;

proc varclus data=pmlr.pva_train_imputed_swoe 
             hi maxeigen=0.70;
   var &ex_inputs mi_DONOR_AGE mi_INCOME_GROUP 
       mi_WEALTH_RATING cluster_swoe;
run;

ods select all;

data _null_;
   set work.summary;
   call symput('nvar',compress(NumberOfClusters));
run;

title1 "Variables by Cluster";
proc print data=work.clusters noobs label split='*';
   where NumberOfClusters=&nvar;
   var Cluster Variable RSquareRatio;
   label RSquareRatio="1 - RSquare*Ratio";
run;

title1 "Variation Explained by Clusters";
proc print data=work.summary label;
run;
title1 ;


/* ===================================================== */
/* Lesson 3, Section 4:
   Practice: Performing Variable Screening
   [m643_4_p; derived from pmlr03s05.sas]                */
/* ===================================================== */

%let ex_reduced=
LIFETIME_GIFT_COUNT LAST_GIFT_AMT MEDIAN_HOME_VALUE 
FREQUENCY_STATUS_97NK MONTHS_SINCE_LAST_GIFT  nses_ 
mi_DONOR_AGE PCT_MALE_VETERANS PCT_MALE_MILITARY
PCT_WWII_VETERANS LIFETIME_AVG_GIFT_AMT cluster_swoe 
PEP_STAR nurbu nurbt home01 nurbr DONOR_AGE STATUS_FL 
MOR_HIT_RATE nses4 INCOME_GROUP RECENT_STAR_STATUS IN_HOUSE 
WEALTH_RATING PUBLISHED_PHONE PCT_OWNER_OCCUPIED nurbs;

ods select none;
ods output spearmancorr=work.spearman
           hoeffdingcorr=work.hoeffding;

proc corr data=pmlr.pva_train_imputed_swoe 
          spearman hoeffding;
   var target_b;
   with &ex_reduced;
run;

ods select all;

proc sort data=work.spearman;
    by variable;
run;

proc sort data=work.hoeffding;
    by variable;
run;

data work.correlations;
   attrib variable length=$32;
   merge work.spearman(rename=
         (target_b=scorr ptarget_b=spvalue))
         work.hoeffding
         (rename=(target_b=hcorr ptarget_b=hpvalue));
   by variable;
   scorr_abs=abs(scorr);
   hcorr_abs=abs(hcorr);
run;

proc rank data=work.correlations 
          out=work.correlations1 descending;
    var scorr_abs hcorr_abs;
    ranks ranksp rankho;
run;

proc sort data=work.correlations1;
   by ranksp;
run;

title1 "Rank of Spearman Correlations and Hoeffding Correlations";
proc print data=work.correlations1 label split='*';
   var variable ranksp rankho scorr spvalue hcorr hpvalue;
   label ranksp='Spearman rank*of variables'
         scorr='Spearman Correlation'
         spvalue='Spearman p-value'
         rankho='Hoeffding rank*of variables'
         hcorr='Hoeffding Correlation'
         hpvalue='Hoeffding p-value';
run;

%global vref href;
proc sql noprint;
   select min(ranksp) into :vref 
   from (select ranksp 
         from work.correlations1 
         having spvalue > .5);
   select min(rankho) into :href 
   from (select rankho
         from work.correlations1
         having hpvalue > .5);
quit;

title1 "Scatter Plot of the Ranks of Spearman vs. Hoeffding";
proc sgplot data=work.correlations1;
   refline &vref / axis=y;
   refline &href / axis=x;
   scatter y=ranksp x=rankho / datalabel=variable;
   yaxis label="Rank of Spearman";
   xaxis label="Rank of Hoeffding";
run;


/* ===================================================== */
/* Lesson 3, Section 4:
   Practice: Creating Empirical Logit Plots
   [m643_4_p2; derived from pmlr03s05.sas]               */
/* ===================================================== */

%global var;
%let var=LAST_GIFT_AMT;

proc rank data=pmlr.pva_train_imputed_swoe 
          groups=20 out=work.ranks;
   var &var;
   ranks bin;
run;

proc means data=work.ranks noprint nway;
   class bin;
   var target_b &var;
   output out=work.bins sum(target_b)=target_b 
          mean(&var)=&var;
run;

data work.bins;
   set work.bins;
   elogit=log((target_b+(sqrt(_FREQ_ )/2))/
          ( _FREQ_ -target_b+(sqrt(_FREQ_ )/2)));
run;

title1 "Empirical Logit against &var";
proc sgplot data=work.bins;
   reg y=elogit x=&var /
       curvelabel="Linear Relationship?"
       curvelabelloc=outside
       lineattrs=(color=ligr);
   series y=elogit x=&var;
run;
title1;

title1 "Empirical Logit against Binned &var";
proc sgplot data=work.bins;
   reg y=elogit x=bin /
       curvelabel="Linear Relationship?"
       curvelabelloc=outside
       lineattrs=(color=ligr);
   series y=elogit x=bin;
run;
title1;


/* ===================================================== */
/* Lesson 3, Section 5:
   Practice: Using Forward Selection to Detect Interactions
   [m643_5_p; derived from pmlr03s06.sas]                */
/* ===================================================== */

%global ex_screened;

%let ex_screened=
LIFETIME_GIFT_COUNT LAST_GIFT_AMT MEDIAN_HOME_VALUE 
FREQUENCY_STATUS_97NK MONTHS_SINCE_LAST_GIFT  nses_ 
mi_DONOR_AGE PCT_MALE_VETERANS PCT_MALE_MILITARY
PCT_WWII_VETERANS LIFETIME_AVG_GIFT_AMT cluster_swoe 
PEP_STAR nurbu nurbt home01 nurbr DONOR_AGE STATUS_FL 
MOR_HIT_RATE nses4 INCOME_GROUP RECENT_STAR_STATUS
IN_HOUSE WEALTH_RATING nurbs;

%global sl;

title1 "P-Value for Entry and Retention";
proc sql;
   select 1-probchi(log(sum(target_b ge 0)),1) into :sl
   from pmlr.pva_train_imputed_swoe;
quit;
title1;

title1 "Interaction Detection using Forward Selection";
proc logistic data=pmlr.pva_train_imputed_swoe namelen=50;
   model target_b(event='1')= &ex_screened 
         LIFETIME_GIFT_COUNT|LAST_GIFT_AMT|MEDIAN_HOME_VALUE|
         FREQUENCY_STATUS_97NK|MONTHS_SINCE_LAST_GIFT|nses_|
         mi_DONOR_AGE|PCT_MALE_VETERANS|PCT_MALE_MILITARY|
         PCT_WWII_VETERANS|LIFETIME_AVG_GIFT_AMT|cluster_swoe|
         PEP_STAR|nurbu|nurbt|home01|nurbr|DONOR_AGE|STATUS_FL|
         MOR_HIT_RATE|nses4|INCOME_GROUP|RECENT_STAR_STATUS|
         IN_HOUSE|WEALTH_RATING|nurbs @2 / include=26 clodds=pl 
       selection=forward slentry=&sl;
run;
title1;



/* ===================================================== */
/* Lesson 3, Section 5:
   Practice: Using Backward Elimination to Subset the 
   Variables
   [m643_5_p2; derived from pmlr03s06.sas]               */
/* ===================================================== */

title1 "Backward Selection for Variable Annuity Data Set";
proc logistic data=pmlr.pva_train_imputed_swoe namelen=50;
   model target_b(event='1')= &ex_screened 
         LAST_GIFT_AMT*LIFETIME_AVG_GIFT_AMT 
         LIFETIME_AVG_GIFT_AMT*RECENT_STAR_STATUS 
         LIFETIME_GIFT_COUNT*MONTHS_SINCE_LAST_GIFT
         / clodds=pl selection=backward slstay=&sl hier=single 
         fast;
run;
title1;


/* ===================================================== */
/* Lesson 3, Section 5:
   Practice: Using Fit Statistics to Select a Model
   [m643_5_p3; derived from pmlr03s06.sas]               */
/* ===================================================== */

%global ex_selected;

%macro fitstat(data=,target=,event=,inputs=,best=,priorevent=);

ods select none;
ods output bestsubsets=work.score;

proc logistic data=&data namelen=50;
   model &target(event="&event")=&inputs / 
         selection=score best=&best;
run;

proc sql noprint;
  select variablesinmodel into :inputs1 -  
  from work.score;
  select NumberOfVariables into :ic1 - 
  from work.score;
quit;

%let lastindx=&SQLOBS;

%do model_indx=1 %to &lastindx;

%let im=&&inputs&model_indx;
%let ic=&&ic&model_indx;

ods output scorefitstat=work.stat&ic ;
proc logistic data=&data namelen=50;
  model &target(event="&event")=&im;
  score data=&data out=work.scored fitstat
        priorevent=&priorevent;
run;

proc datasets
   library=work
   nodetails
   nolist;
   delete scored;
run;
quit;

%end;

data work.modelfit;
   set work.stat1 - work.stat&lastindx;
   model=_n_;
run;

%mend fitstat;

%fitstat(data=pmlr.pva_train_imputed_swoe,target=target_b,event=1,
         inputs=&ex_screened LAST_GIFT_AMT*LIFETIME_AVG_GIFT_AMT
         LIFETIME_AVG_GIFT_AMT*RECENT_STAR_STATUS 
         LIFETIME_GIFT_COUNT*MONTHS_SINCE_LAST_GIFT,best=1,
         priorevent=0.05);

proc sort data=work.modelfit;
   by bic;
run;

title1 "Fit Statistics from Models selected from Best-Subsets";
ods select all;
proc print data=work.modelfit;
   var model auc aic bic misclass adjrsquare brierscore;
run;
title1;

proc sql;
   select VariablesInModel into :ex_selected
   from work.score
   where numberofvariables=9;
quit;


/* ===================================================== */
/* Lesson 4, Section 1:
   Practice: Assessing Model Performance 
   [m644_2_p; derived from pmlr04s01.sas]                */
/* ===================================================== */

title1 "Variables with Missing Values on the Validation Data Set";
proc means data=pmlr.pva_valid nmiss;
   var LIFETIME_GIFT_COUNT LAST_GIFT_AMT MEDIAN_HOME_VALUE 
       FREQUENCY_STATUS_97NK PEP_STAR INCOME_GROUP 
       LIFETIME_AVG_GIFT_AMT MONTHS_SINCE_LAST_GIFT;
run;
title1;

proc univariate data=pmlr.pva_train_imputed_swoe noprint;
   var INCOME_GROUP;
   output out=work.medians
          pctlpts=50
          pctlpre=income_group;
run;

title1 "Medians for Variables with Missing Values";
proc print data=work.medians;
run;
title1;

data pmlr.pva_valid_imputed_swoe(drop=income_group50 i);
   if _N_=1 then set work.medians;
   set pmlr.pva_valid;
   array x(*) income_group;
   array med(*) income_group50;
      do i=1 to dim(x);
         if x(i)=. then x(i)=med(i);
      end;
   %include clswoe;
run;

title1 "Training Data Set Model";
proc logistic data= pmlr.pva_train_imputed_swoe;
   model target_b(event='1')=&ex_selected;
   score data= pmlr.pva_valid_imputed_swoe priorevent=&ex_pi1
         outroc=work.roc fitstat; 
run;
title1;

data work.roc;
   set work.roc;
   cutoff=_PROB_;
   specif=1-_1MSPEC_;
   tp=&ex_pi1*_SENSIT_;
   fn=&ex_pi1*(1-_SENSIT_);
   tn=(1-&ex_pi1)*specif;
   fp=(1-&ex_pi1)*_1MSPEC_;
   depth=tp+fp;
   pospv=tp/depth;
   negpv=tn/(1-depth);
   acc=tp+tn;
   lift=pospv/&ex_pi1;
   keep cutoff tn fp fn tp 
        _SENSIT_ _1MSPEC_ specif depth
        pospv negpv acc lift;
run;
title1 "Lift Chart for Validation Data";
proc sgplot data=work.roc;
   where 0.005 <= depth <= 0.50;
   series y=lift x=depth;
   refline 1.0 / axis=y;
   yaxis values=(0 to 4 by 1);
run; 
quit;
title1;


