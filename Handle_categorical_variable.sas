%global PMLRfolder;
%let PMLRfolder=/folders/myfolders/ECPMLR41;
libname pmlr "&PMLRfolder";


/*Use PROC MEANS to generate a temporary data set with information about the average response rate and
sample size for each level of Cluster_Code. Name the output data set work.level.
Use the NOPRINT and NWAY options.*/

proc means data=pmlr.pva_train_imputed nway;
class cluster_code;
var target_B;
output out=work.level mean=prop;
 run;

/*Write a PROC CLUSTER step that does the following:
1. groups the observations in the work.level data set using Greenacre's method
2. creates a horizontal dendrogram with the X axis corresponding to the squared multiple correlation
3. Specify Cluster_Code as the variable that identifies observations in the cluster history,
and create an output data set named work.fortree that can be used in PROC TREE.
4. Use the ODS OUTPUT statement to create a temporary data set named work.cluster from the clusterhistory output object. */

ods output clusterhistory=work.cluster;

proc cluster data=work.level method=ward 
             outtree=work.fortree
             plots=(dendrogram(horizontal height=rsq));
   freq _freq_;
   var prop;
   id cluster_code;
run;

/*a PROC FREQ step that creates a temporary data set named work.chi,
 which contains the original Pearson chi-square value from the 54*2 contingency table.*/
proc freq data=pmlr.pva_train_imputed;
   tables cluster_code*target_b / chisq;
   output out=work.chi(keep=_pchi_) chisq;
run;

/*a DATA step that creates a data set named work.cutoff, which contains the log of the p-value of the appropriate
 chi-square test for each number of clusters. This determines which level of clustering is appropriate.*/
data work.cutoff;
   if _n_=1 then set work.chi;
   set work.cluster;
   chisquare=_pchi_*rsquared;
   degfree=numberofclusters-1;
   logpvalue=logsdf('CHISQ',chisquare,degfree); 
run;

/*a PROC SGPLOT step that plots the log of the p-value by the number of clusters from the data set work.cutoff. 
The range of the Y axis should be -40 to 0.*/
title1 "Plot of the Log of the P-Value by Number of Clusters";
proc sgplot data=work.cutoff;
   scatter y=logpvalue x=numberofclusters 
           / markerattrs=(color=blue symbol=circlefilled);
   xaxis label="Number of Clusters";
   yaxis label="Log of P-Value" min=-40 max=0;
run;
title1; 

/*Use PROC SQL to create a global macro variable named ncl that stores the value of the number of clusters with
 the lowest log of the p-value. Submit the code and look at the results.*/
%global ncl;

proc sql;
   select NumberOfClusters into :ncl
   from work.cutoff
   having logpvalue=min(logpvalue);
quit;

/*Use PROC TREE to create a temporary data set named work.clus, which contains the results of the cluster solution
 with the lowest log of the p-value. To suppress the PROC TREE output, specify the NOPRINT option.*/

/*Sort and print the work.clus data set. In the PROC PRINT step, include BY and ID statements that specify the variable Clusname.*/

proc tree data=work.fortree nclusters=&ncl 
          out=work.clus ;
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

/*Create a SAS program file with the score code that computes the assignments for Cluster_Code.
Define a new variable named Cluster_Clus.*/

filename clcode "&PMLRfolder/cluster_code.sas";

data _null_;
   file clcode;
   set work.clus end=last;
   if _n_=1 then put "select (cluster_code);";
   put "  when ('" cluster_code +(-1) "') cluster_clus='" cluster +(-1) "';";
   if last then do;
      put "  otherwise cluster_clus='U';" / "end;";
   end;
run;


/*Add a second DATA step to put the new assignments for Cluster_Code into a data set named pmlr.pva_train_imputed_clus. */
data pmlr.pva_train_imputed_clus;
   set pmlr.pva_train_imputed;
   %include clcode;
run;
