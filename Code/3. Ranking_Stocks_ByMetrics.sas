/* RANKING PROCESS */
proc sort data=PCAFinal;
	by infome;
run;

/*CORRELATION MATRIX*/
%paint(values=-1 to 1 by 0.05, macro=setstyle,
	colors=CXEEEEEE red magenta blue cyan white
	cyan blue magenta red CXEEEEEE
	-1 -0.99 -0.75 -0.5 -0.25 0 0.25 0.5 0.75 0.99 1)

	proc template;
edit Base.Corr.StackedMatrix;
column (RowName RowLabel) (Matrix) * (Matrix2);
edit matrix;

%setstyle(backgroundcolor)
end;
end;
run;

ods html body='corr.html' style=statistical;
ods listing close;

proc corr data=PCAFinal Pearson Spearman Kendall noprob;
	var NPM DEBT_INVCAP TOTDEBT_INVCAP PS DEBT_AT PRETRET_EARNAT LT_DEBT EVM INT_TOTDEBT AT_TURN;
run;

ods listing;
ods html close;

proc template;
	delete Base.Corr.StackedMatrix;
run;

/* Ranking Variables */
proc sort data=PCAFinal;
	by infome gvkey;
run;

proc rank data=PCAFinal out=IndRanks descending ties=high;
	by infome;
	var    Mo1;
	ranks Mo1Rank;
run;

proc rank data=IndRanks out=IndRanks ties=high;
	by infome;
	var    FIP;
	ranks FIPRank;
run;

proc rank data=IndRanks out=IndRanks groups=20;
	by infome;
	var Mo1Rank;
	ranks Mo1Ranks;
run;

data IndRanks;
	set IndRanks;

	if Mo1Ranks = 0 then
		delete;
run;

proc rank data=IndRanks out=IndRanks ties=high;
	by infome;
	var    DEBT_INVCAP   		 PS   		  DEBT_AT   		   LT_DEBT   		EVM   		  INT_TOTDEBT   		  TOTDEBT_INVCAP;
	ranks DEBT_INVCAPRank  PSRank   DEBT_ATRank   LT_DEBTRank   EVMRank   INT_TOTDEBTRank   TOTDEBT_INVCAPRank;
run;

proc rank data=IndRanks out=IndRanks descending ties=high;
	by infome;
	var    NPM   			 PRETRET_EARNAT   		 AT_TURN                 EY           ROIC          PTB           ROIC5A            Mo12;
	ranks NPMRank   PRETRET_EARNATRank   AT_TURNRank        EYRank   ROICRank  PTBRank  ROIC5YRank    Mo12Rank;
run;

/*Sorting out Blue Chip Stocks*/
data IndRanks;
	set IndRanks;
	where CurrentPrice > 5;
run;

/* Calculating the Sum of All Ratio Rankings */
data CombRank;
	set  IndRanks;
	TotalRankValue = (NPMRank) + 
		(DEBT_INVCAPRank) + 
		(TOTDEBT_INVCAPRank) + 
		(PSRank) + 
		(DEBT_ATRank) + 
		(PRETRET_EARNATRank) + 
		(LT_DEBTRank) + 
		(EVMRank) + 
		(INT_TOTDEBTRank) + 
		(AT_TURNRank) +
		(EYRank) + 
		(ROICRank) + 
		(PTBRank) + 
		(ROIC5YRank) +
		(Mo12Rank) +
		(FIPRank);
run;

/* Ranking the Sum of All Ratio Rankings */
proc rank data=CombRank out=CombRank groups=20;
	by infome;
	var TotalRankValue;
	ranks FinalRanks;
run;

/* Calculating Average Returns by Group and Year */
proc means data=CombRank noprint nway;
	class infome FinalRanks;
	var ret12;
	output out=AvgRet mean=Avg_Ret;
run;

data AvgRet (drop=_type_ _freq_);
	set AvgRet;
	PCARetMo = (Avg_Ret-1);
run;

proc sort data=AvgRet;
	by infome;
run;

data PCAMoTop;
	set AvgRet;
	where FinalRanks = 0;
run;

proc sql;
	select mean(PCARetMo) from PCAMoTop;
quit;

proc sort data=AvgRet;
	by FinalRanks;

proc boxplot data=AvgRet;
	plot PCARetMo*FinalRanks;
run;

proc summary data=AvgRet;
	by FinalRanks;
	var PCARetMo;
	output out=AvgRetSummary mean=;
	format PCARetMo percentN9.2;
run;

ods graphics on / attrpriority=none;

proc sgplot data=AvgRetSummary;
	styleattrs datasymbols=(circlefilled);
	scatter x=FinalRanks y=PCARetMo / markerattrs=(symbol=circleFilled size=2pct color=navy);
run;

ods graphics / reset;
