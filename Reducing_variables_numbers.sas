%global PMLRfolder;
%let PMLRfolder=/folders/myfolders/ECPMLR41;
libname pmlr "&PMLRfolder";


/*Write a PROC VARCLUS step that does the following:

 ->  clusters all of the numeric input variables in the pmlr.pva_train_imputed_swoe data set in a hierarchical structure
 ->  specifies the numeric inputs by referencing the ex_inputs macro variable that you created in the previous step
 ->  specifies the missing indicator variables and the cluster smoothed-weight-of-evidence variable
 ->  uses MAXEIGEN=.70 as the stopping criterion
 ->  specifies the HI option to require the clusters at different levels to maintain a hierarchical structure

Before the PROC VARCLUS code, add an ODS OUTPUT statement to create the following:

 ->  a data set named work.summary from the clusterquality output object
 ->  a data set named work.clusters from each RSquare output object
 
Before the ODS OUTPUT statement, add an ODS SELECT NONE statement to suppress output to the open ODS destination.
Following the PROC VARCLUS code, add an ODS SELECT ALL statement to resume sending output to the open ODS destination.
Submit the code for this step and check the log.*/


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

%put "ex_inputs=>" &ex_inputs.;

ods select none;
ods output clusterquality=work.summary
           rsquare=work.clusters;

proc varclus data=pmlr.pva_train_imputed_swoe 
             hi maxeigen=0.60;
   var &ex_inputs mi_DONOR_AGE mi_INCOME_GROUP 
       mi_WEALTH_RATING cluster_swoe;
run;

ods select all;

/*Write a CALL SYMPUT routine that creates a macro variable named nvar, which contains the value of the 
number of clusters in the last iteration of the clustering algorithm. Use the COMPRESS function to strip 
blanks from the variables.*/
data _null_;
   set work.summary;
   call symput('nvar',compress(NumberOfClusters));
run;

%put nvar macro=&nvar.;

/*Write a PROC PRINT step to print the table of the R-square statistics from the last iteration of PROC VARCLUS*/
title1 "Variables by Cluster";
proc print data=work.clusters noobs label split='*';
   where NumberOfClusters=&nvar;
   var Cluster Variable RSquareRatio;
   label RSquareRatio="1 - RSquare*Ratio";
run;

/*Add a second PROC PRINT step to print the table that shows the proportion of variation explained by the clusters.*/
title1 "Variation Explained by Clusters";
proc print data=work.summary label;
run;
title1;

