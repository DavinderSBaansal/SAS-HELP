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
