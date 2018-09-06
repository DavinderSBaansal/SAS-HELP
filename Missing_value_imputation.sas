libname pmlr "&PMLRfolder";

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

proc rank data=pmlr.pva_train_mi out=work.pva_train_rank groups=3;
var recent_response_prop recent_avg_gift_amt;
ranks grp_resp grp_amt;
run;

proc sort data=work.pva_train_rank out=work.pva_train_rank_sort;
by grp_resp grp_amt;
run;


proc stdize data=work.pva_train_rank_sort out=pmlr.pva_train_imputed method=median reponly;
by grp_resp grp_amt;
var DONOR_AGE INCOME_GROUP WEALTH_RATING;
run;
options label;
