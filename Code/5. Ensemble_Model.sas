/* ENSEMBLE 1 */
proc rank data=PCA.PredComb descending ties=high out=RanksAnal1;
	by 	infome;
	var   RegPred MARSPred NNPred;
	ranks RankReg RankMARS RankNN;
run;

data RanksAnal1;
	set  RanksAnal1;
	Ens1Total = (TotalRankValue*0.05) + (RankReg*0.2) + (RankMARS*0.45) + (RankNN*0.3);
run;

proc rank data=RanksAnal1 out=RanksAnal2;
	by infome;
	var Ens1Total;
	ranks EnsTotalRanks;
run;

proc rank data=RanksAnal2 out=RanksAnal2 groups=20;
	by infome;
	var EnsTotalRanks;
	ranks EnsFinalRanks;
run;

proc means data=RanksAnal2 noprint nway;
	class infome EnsFinalRanks;
	var ret12;
	output out=EnsRets mean=Avg_Ret;
run;

data Ensemble1;
	set EnsRets (drop=_type_ _freq_);
	rets = Avg_Ret-1;
	where EnsFinalRanks = 0;
run;

proc sql;
	select mean(rets) as EnsembleRets from Ensemble1;
quit;

/* ENSEMBLE 1 DONE */
