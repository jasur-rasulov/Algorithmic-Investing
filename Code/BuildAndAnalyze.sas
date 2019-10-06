libname Moment "C:\Users\jasur\Desktop\INDEP STUDY\ERP5";

*libname Moment "F:\StockData\IndepStudy";
*libname Moment "E:\IndepStudy\Fall2018\Jasur";
%let path=C:\Users\jasur\Desktop\INDEP STUDY\ERP5;

*First step to creating a dataset with the variables for ERP5 Model;
data ERP5_Base;
	set  Moment.Merged(keep=infome gvkey sic SP500Member MktCap CONM TIC 
		EXCHCD CurrentPrice EY AFTRET_INVCAPX PTB ret3 ret6 ret9 ret12 ret15 ret18 ret24 mo1 mo12 FIP rename=(AFTRET_INVCAPX=ROIC));
run;

/* CREATING A 5-YEAR AVERAGE ROIC VARIABLE */
proc sort data=ERP5_Base;
	by gvkey infome;
run;

data Recnum;
	format recnum 8.;
	set  ERP5_Base;
	by   gvkey;
	recnum+1;

	if   first.gvkey then
		recnum=1;
run;

*Arithmetic Average;
data ERP5;
	set Recnum;
	by gvkey;

	if recnum ge 5 then
		do;
			L1 = Lag(ROIC);
			L2 = Lag2(ROIC);
			L3 = Lag3(ROIC);
			L4 = Lag4(ROIC);
			ROIC5A = mean(ROIC, L1, L2, L3, L4);
		end;
run;

/* COMPARING THE AVERAGE RETURNS OF RECNUM < 5 AND RECNUM > 5 TO ANALYZE THE EVENTUAL IMPACT */
data rec1;
	set ERP5(keep=recnum ret12 rename=(ret12=Avg_Ret));
run;

proc means data=rec1 noprint nway;
	class recnum;
	var Avg_Ret;
	where recnum < 5;
	output out=recless5 mean=Avg_Ret;
run;

proc means data=rec1 noprint nway;
	class recnum;
	var Avg_Ret;
	where recnum > 5;
	output out=recgreater5 mean=Avg_Ret;
run;

proc means data=recless5;
	var Avg_Ret;
run;

proc means data=recgreater5;
	var Avg_Ret;
run;

*Deleting companies with recnums less than 5;
data ERP5;
	set ERP5;

	if recnum le 4 then
		delete;
run;

proc sql;
	select count(gvkey) from ERP5_Base;
	select count(gvkey) from ERP5;
quit;

/* COUNT MISSING DATA FOR VARIABLES */
data MissVars;
	set ERP5;
	nummiss=nmiss(of infome,EY,ROIC,PTB,ROIC5A);
run;

proc summary data=MissVars nway;
	var EY ROIC PTB ROIC5A;
	output out=MissCount nmiss=;
run;

proc sql;
	create table MissValRets as
		select * from MissVars
			where nummiss > 0;
run;

quit;

proc sql;
	select mean(ret12) from MissValRets;
run;

quit;

/* AUDIT ON MISSING VALUES BASED ON INDUSTRY CODE */
data SICMissing;
	set MissVars(keep=sic nummiss);
	where nummiss > 0;
run;

proc summary data=SICMissing nway;
	class SIC;
	output out=SICMissing;
run;

data SICMissing;
	set SICMissing;
	missfreq = _freq_;
run;

proc sort data=SICMissing;
	by SIC;
run;

data SICTotal;
	set ERP5(keep=SIC);
run;

proc summary data=SICTotal nway;
	class SIC;
	output out=SICTotal;
run;

data SICTotal;
	set SICTotal;
	totalfreq = _freq_;
run;

proc sort data=SICTotal;
	by SIC;
run;

data  SICFinal (drop=_freq_ _type_);
	merge SICMissing
		SICTotal;
	by 	      SIC;
run;

data SICFinal;
	set SICFinal;
	PercMissing = missfreq/totalfreq;
run;

proc sort data=SICFinal;
	by descending missfreq;
run;

/* DELETING MISSING VALUES FOR EY, ROIC, PTB, ROIC5A */
data ERP5Final;
	set ERP5;

	if cmiss(of EY,ROIC,PTB,ROIC5A) then
		delete;
run;

proc sql;
	select mean(ret12) from Erp5Final;
quit;

/* RANKING PROCESS */
proc sort data=ERP5Final;
	by infome;
run;

/* Ranking Variables */
proc rank data=ERP5Final out=IndRanks descending ties=high;
	by infome;
	var    Mo1;
	ranks Mo1Rank;
run;

proc rank data=IndRanks out=IndRanks descending ties=high;
	by infome;
	var    EY           ROIC          PTB           ROIC5A             Mo12;
	ranks EYRank   ROICRank  PTBRank  ROIC5YRank      Mo12Rank;
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

/*Sorting out Blue Chip Stocks*/
data IndRanks;
	set IndRanks;
	where CurrentPrice > 5;
run;

/* Calculating the Sum of All 6 Ratio Rankings */
data CombRank;
	set  IndRanks;
	TotalRankValue = EYRank + ROICRank + PTBRank + ROIC5YRank + Mo12Rank + FIPRank;
run;

/* Ranking the Sum of All 6 Ratio Rankings */
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
	reterp5_mo = (Avg_Ret-1)/1;
run;

proc sort data=AvgRet;
	by infome;
run;

data ERP5MoTop;
	set AvgRet;
	where FinalRanks = 0;
run;

proc sql;
	select mean(reterp5_mo) from ERP5MoTop;
quit;

/*COMPARISON*/
data comparison;
	merge Moment.AvgRet
		AvgRet;
	by infome;
	diff = reterp5_mo - reterp5;
	format reterp5 reterp5_mo diff percentN9.2;
run;

proc sql;
	select mean(reterp5) as reterp5, mean(reterp5_mo) as reterp5_mo from comparison
		where FinalRanks=0;
run;

data ERP5MoTopRets (drop=Avg_Ret);
	set AvgRet;
	where FinalRanks = 0;
run;

data CombRank;
	set CombRank;
	return = (ret12-1)/1;
	format return percent10.;
run;

proc boxplot data=CombRank;
	plot return*infome / BOXWIDTHSCALE=1;
run;
