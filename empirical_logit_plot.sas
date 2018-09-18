%global PMLRfolder;
%let PMLRfolder=/folders/myfolders/ECPMLR41;
libname pmlr "&PMLRfolder";

/*Write code that bins the Last_Gift_Amt variable in the pmlr.pva_train_imputed_swoe data set.
 Create a macro variable to store the variable name Last_Gift_Amt. In PROC RANK, specify 20 groups
 and create an output data set named work.ranks.*/

%global LGA;
%let LGA=Last_Gift_Amt;

proc rank data=pmlr.pva_train_imputed_swoe groups=20 out=work.ranks;
var &LGA.;
ranks bin;
run;

/* Print the dataset and check the rank */
proc print data=work.ranks (obs=15);
var &LGA. bin;
run;

/*To compute the logits and add them to the work.bins data set, use PROC MEANS and the DATA step.*/
proc means data=work.ranks nway noprint;
class bin;
var Target_B &LGA.;
output out=	work.bin sum(Target_B)=event mean(&LGA.)=mean;
run;

data work.bins;
set work.bin;
elogit= log((event + sqrt(_freq_/2))/(_freq_-event+sqrt(_freq_/2)));
&LGA.=mean;
Target_B=event;
drop mean event;
run;

/*Create an empirical logit plot of Last_Gift_Amt versus Target_B.*/
title1 "Empirical Logit against &LGA.";
proc sgplot data=work.bins;
reg x=&LGA. Y=elogit / lineattrs=(color=red);
series x=&LGA. Y=elogit;
run;
title1;

/*Create an empirical logit plot of the bins of Last_Gift_Amt versus Target_B*/
title1 "Empirical Logit against Binned &LGA.";
proc sgplot data=work.bins;
reg x=bin Y=elogit / lineattrs=(color=green);;
series x=bin Y=elogit;
run;
title1;
