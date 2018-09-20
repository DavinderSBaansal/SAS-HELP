%global PMLRfolder;
%let PMLRfolder=/folders/myfolders/ECPMLR41;
libname pmlr "&PMLRfolder";


%global ex_screened;
%let ex_screened=LIFETIME_GIFT_COUNT LAST_GIFT_AMT MEDIAN_HOME_VALUE 
                 FREQUENCY_STATUS_97NK MONTHS_SINCE_LAST_GIFT  nses_ 
                 mi_DONOR_AGE PCT_MALE_VETERANS PCT_MALE_MILITARY 
                 PCT_WWII_VETERANS LIFETIME_AVG_GIFT_AMT cluster_swoe 
                 PEP_STAR nurbu nurbt home01 nurbr DONOR_AGE STATUS_FL 
                 MOR_HIT_RATE nses4 INCOME_GROUP RECENT_STAR_STATUS 
                 IN_HOUSE WEALTH_RATING nurbs;
                 
/*Write a PROC SQL step to compute a BIC-based significance level using the sample size for n.
 Create a global macro variable named sl to store the significance level.*/
%global sl;
title1 "P-Value for Entry and Retention";
Proc sql;
select 1-probchi(log(sum(target_b ge 0)),1) into :sl
from pmlr.pva_train_imputed_swoe
;
quit;
title1;

/*Use PROC LOGISTIC to detect important two-factor interactions by doing the following:

    Fit a logistic regression model to the pmlr.pva_train_imputed_swoe data set with Target_B as the target variable.
    Model the probability that Target_B=1.
    Specify the input variables from variable screening (performed in a previous demonstration) by referencing the ex_screened macro variable that you created in a previous step.
    Use the bar notation for each of the input variables and the @2 notation to specify all input variables and their two-factor interactions.
    Specify the forward selection method and include the first 26 input variables.
    Specify the BIC-based significance level that you calculated in the previous step.
    Specify profile-likelihood confidence intervals.
    Set the maximum length of effect names to 50. Use the NAMELEN= option in the PROC LOGISTIC statement.
*/
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

