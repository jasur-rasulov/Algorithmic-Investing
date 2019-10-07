/* COUNT MISSING DATA FOR VARIABLES */
data MissVars;
	set PCA_Base;
	nummiss=nmiss(of infome, NPM, DEBT_INVCAP, TOTDEBT_INVCAP, PS, DEBT_AT, PRETRET_EARNAT, LT_DEBT, EVM, INT_TOTDEBT, AT_TURN, EY, ROIC, PTB, ROIC5A, Mo12, FIP);
run;

proc summary data=MissVars nway;
	var NPM DEBT_INVCAP TOTDEBT_INVCAP PS DEBT_AT PRETRET_EARNAT LT_DEBT EVM INT_TOTDEBT AT_TURN ROIC PTB ROIC5A EY Mo12 FIP;
	output out=MissCount nmiss=;
run;

data MissCount;
	set MissCount (drop=_type_ _freq_);
run;

proc transpose data=MissCount out=MissCount prefix=MissVars;
run;

data MissCount;
	set MissCount;
	MissingPerc = MissVars1 / 138696;
	format MissingPerc percentN9.2;
run;

proc sql;
	create table MissValRets as
		select * from MissVars
			where nummiss > 0;
run;

quit;

proc sql;
	create table NoMissValRets as
		select * from MissVars
			where nummiss = 0;
run;

quit;

proc sql;
	select mean(ret12) from PCA_Base;
run;

quit;

proc sql;
	select mean(ret12) from MissValRets;
run;

quit;

proc sql;
	select mean(ret12) from NoMissValRets;
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
	set PCA_Base(keep=SIC);
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
	format PercMissing percentN9.2;
run;

proc sort data=SICFinal;
	by descending missfreq;
run;

/* DELETING MISSING VALUES FOR EY, ROIC, PTB, ROIC5A */
data PCAFinal;
	set PCA_Base;

	if cmiss(of NPM, DEBT_INVCAP, TOTDEBT_INVCAP, PS, DEBT_AT, PRETRET_EARNAT, LT_DEBT, EVM, INT_TOTDEBT, AT_TURN, EY, ROIC, PTB, ROIC5A) then
		delete;
run;

proc sql;
	select mean(ret12) from PCAFinal;
quit;
