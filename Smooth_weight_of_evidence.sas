%global PMLRfolder;
%let PMLRfolder=/folders/myfolders/ECPMLR41;
libname pmlr "&PMLRfolder";
%global rho1_ex;

/*Write a PROC SQL step to compute the proportion of events in the pmlr.pva_train_imputed data set*/
proc sql noprint;
	select mean(target_b) into :rho1_ex from pmlr.pva_train_imputed;
	run;
	%put &rho1_ex;

/*Add a PROC MEANS step to calculate the response rate and frequency in each of the levels of Cluster_Code.*/
proc means data=pmlr.pva_train_imputed sum nway noprint;
	class cluster_code;
	var target_b;
	output out=work.counts sum=events;
run;

/*Create a SAS program file with the score code that computes the smoothed weight of evidence values.
 Use the value 24 for c and assign the overall logit to any observation with an undefined Cluster_Code. 
 Define a new variable named Cluster_Swoe for the smoothed weight of evidence values.*/ 

filename clswoe "&PMLRfolder/swoe_cluster.sas";

data _null_;
	file clswoe;
	set work.counts end=last;
	logit=log((events + &rho1_ex*24)/ (_FREQ_ - events + (1-&rho1_ex)*24));

	if _n_=1 then
		put "select (cluster_code);";
	put "  when ('" cluster_code +(-1) "') 
       cluster_swoe=" logit ";";

	if last then
		do;
			logit=log(&rho1_ex/(1-&rho1_ex));
			put "  otherwise cluster_swoe=" logit ";" / "end;";
		end;
run;

/*Add a DATA step to put the new assignments into a data set named pmlr.pva_train_imputed_swoe.*/
data pmlr.pva_train_imputed_swoe;
set pmlr.pva_train_imputed;
%include "&PMLRfolder/swoe_cluster.sas"/ source2;
run;

/*Add a PROC PRINT step that helps you answer the following question: 
What is the value of the smoothed weight of evidence for cluster code 01? */
title;

proc print data=pmlr.pva_train_imputed_swoe(obs=1);
   where cluster_code = "01";
   var cluster_code cluster_swoe;
run;

/*the smoothed weight of evidence for cluster code 01 is -0.98447.*/
