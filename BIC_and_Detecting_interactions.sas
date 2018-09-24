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
	select 1-probchi(log(sum(target_b ge 0)), 1) into :sl from 
		pmlr.pva_train_imputed_swoe;
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
	model target_b(event='1')=&ex_screened 
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

/*Using Backward Elimination to Subset the Variables*/
/*Using Backward Elimination to Subset the Variables*/
/*Using Backward Elimination to Subset the Variables*/
/*Write a PROC LOGISTIC step that does the following:

uses the backward elimination method to find a subset of the inputs
specifies pmlr.pva_train_imputed_swoe as the input data set
models the probability that Target_B=1
specifies the screened variables (referenced by the ex_screened macro variable that you created in an earlier practice) and the interactions detected by the forward selection method in the previous practice
in the MODEL statement, specifies the FAST option, the HIERARCHY=SINGLE option, the BIC-based significance level, and the profile likelihood confidence intervals
uses the NAMELEN= option in the PROC LOGISTIC statement to set the maximum length of effect names to 50
*/
title1 "Backward Selection for Variable Annuity Data Set";

proc logistic data=pmlr.pva_train_imputed_swoe namelen=50;
	model target_b(event='1')=&ex_screened 
         LAST_GIFT_AMT*LIFETIME_AVG_GIFT_AMT 
		LIFETIME_AVG_GIFT_AMT*RECENT_STAR_STATUS 
		LIFETIME_GIFT_COUNT*MONTHS_SINCE_LAST_GIFT / clodds=pl selection=backward 
		slstay=&sl hier=single fast;
run;

title1;

/*Using Fit Statistics to Select a Model*/
/*Using Fit Statistics to Select a Model*/
/*Using Fit Statistics to Select a Model*/


/*FITSTAT Macro program */
%macro fitstat(data=, target=, event=, inputs=, best=, priorevent=);
	ods select none;
	ods output bestsubsets=work.score;

	proc logistic data=&data namelen=50;
		model &target(event="&event")=&inputs / selection=score best=&best;
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
		ods output scorefitstat=work.stat&ic;

		proc logistic data=&data namelen=50;
			model &target(event="&event")=&im;
			score data=&data out=work.scored fitstat priorevent=&priorevent;
		run;

		proc datasets library=work nodetails nolist;
			delete scored;
			run;
		quit;

	%end;

	data work.modelfit;
		set work.stat1 - work.stat&lastindx;
		model=_n_;
	run;

%mend fitstat;


/*Call the Fitstat macro to generate fit statistics for the models that the macro generates
 using best-subsets selection. Specify the following arguments:

    data=pmlr.pva_train_imputed_swoe
    target=Target_B
    event=1
    inputs=&ex_screened Last_Gift_Amt*Lifetime_Avg_Gift_Amt 
    		Lifetime_Avg_Gift_Amt*Recent_Star_Status 
    		Lifetime_Gift_Count*Months_Since_Last_Gift
    best=1
    priorevent=0.05
*/

%fitstat(data=pmlr.pva_train_imputed_swoe,target=target_b,event=1,
         inputs=&ex_screened LAST_GIFT_AMT*LIFETIME_AVG_GIFT_AMT
         LIFETIME_AVG_GIFT_AMT*RECENT_STAR_STATUS 
         LIFETIME_GIFT_COUNT*MONTHS_SINCE_LAST_GIFT,best=1,
         priorevent=0.05);
         
/*Add a PROC SORT step to sort the work.modelfit data set by BIC.*/
proc sort data=work.modelfit;
   by bic;
run;

/*Add a PROC PRINT step to print a table that shows the variables Model, AUC, BIC,
 Misclass, AdjRsquare, and BrierScore.
 Add an ODS SELECT ALL statement before the PROC PRINT step.
*/

title1 "Fit Statistics from Models selected from Best-Subsets";
ods select all;
proc print data=work.modelfit;
   var model auc aic bic misclass adjrsquare brierscore;
run;
title1;

/*Write a PROC SQL step that creates a macro variable named ex_selected, which stores
 the variable names in the model with the lowest BIC. As the input data set, 
 specify work.score.
*/

proc sql;
   select VariablesInModel into :ex_selected
   from work.score
   where numberofvariables=9;
quit;

/*How many interactions are in the model with the lowest BIC?*/

/*the following two interactions are in the model: 
Last_Gift_Amt*Lifetime_Avg_Gift_Amt and Lifetime_Gift_Count*Months_Since_Last_Gift.
*/
