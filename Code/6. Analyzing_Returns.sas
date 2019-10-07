/*ANALYZING OVERALL RETURNS*/
proc summary data=RanksAnal nway;
	class infome FinalRanks;
	var ret12;
	output out=EWret mean=retew;
run;

proc summary data=RanksAnal nway;
	class infome Rankreg;
	var ret12;
	output out=regret mean=retreg;
run;

proc summary data=RanksAnal nway;
	class infome RankMARS;
	var ret12;
	output out=marsret mean=retmars;
run;

proc summary data=RanksAnal nway;
	class infome RankNN;
	var ret12;
	output out=nnret mean=retnn;
run;

data  compare (drop=_type_ _freq_);
	merge ewret (rename=(finalranks=rank))
		regret(rename=(rankreg=rank))
		marsret(rename=(RankMARS=rank))
		nnret(rename=(ranknn=rank))
	;
	by    infome rank;
run;

data best;
	set  compare;

	if   rank=0;
	retew =retew-1;
	retreg=retreg-1;
	retmars=retmars-1;
	retnn=retnn-1;
run;

proc sql;
	select mean(retew) as EqualWeights, mean(retreg) as Regression, mean(retmars) as MARS, mean(retnn) as NeuralNet
		from Best;
quit;

/*DATA MINING END*/
