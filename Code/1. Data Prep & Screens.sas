*First step to creating a dataset with the variables for this model;
data PCA_Base;
	set  Moment.Merged(keep=
	/*General Variables*/ infome gvkey sic SP500Member MktCap CONM TIC EXCHCD CurrentPrice 
	/*Screen Variables*/ AT AP ACT CHE LCT DLC TXP DP CH DLTT LT XACC
	/*10 PCA Variables*/ NPM DEBT_INVCAP   TOTDEBT_INVCAP   PS   DEBT_AT   PRETRET_EARNAT   LT_DEBT   EVM   INT_TOTDEBT   AT_TURN
	/*ERP5 Variables*/ EY  AFTRET_INVCAPX  PTB
	/*Return and Momentum Vars*/ ret3 ret6 ret9 ret12 ret15 ret18 ret24 mo1 mo12 FIP rename=(AFTRET_INVCAPX=ROIC));

	/*MANUAL CALCULATIONS: 
	Operating Assets = (Total Assets - Cash) - (Total Liabilities - Total Debt)*/
	OA = (AT - CH) - (LT - DLTT);

	/*Operating Liabilities = Accounts payable + Accrued expenses + Income tax payable*/
	OL = AP + XACC + TXP;
run;

/*SCREENS*/
/*Accural Screen*/
proc sort data=PCA_Base;
	by gvkey infome;
run;

data PCA_Base;
	set PCA_Base;
	by gvkey;

	/*	Capturing Changes in: Assets, Cash & Equivalents, Liabilities, Long Term Debt, Income Taxes Payable*/
	CINAT = ifn(first.gvkey,.,dif(ACT));
	CINCE = ifn(first.gvkey,.,dif(CHE));
	CINL = ifn(first.gvkey,.,dif(LCT));
	CINLTD = ifn(first.gvkey,.,dif(DLC));
	CINITP = ifn(first.gvkey,.,dif(TXP));
	CA = CINAT - CINCE;
	CL = CINL - CINLTD - CINITP;

	/*	STA = Scaled Total Accruals = (Change in Assets - Change in Liabilities - Deprecitation and Amortization Expense / Total Assets*/
	STA = (CA - CL - DP) / AT;

	/*SNOA = (Operating Assets - Operating Liabilities) / Total Assets*/
	SNOA = (OA - OL) / AT;
run;

proc sort data=PCA_Base;
	by infome gvkey;
run;

proc sql;
	select mean(ret12) from ROICle5;
run;

quit;

/*Percentiles for STA and SNOA*/
proc rank data=PCA_Base groups=20 descending out=PCA_Base;
	by infome;
	var 	 STA 		      SNOA;
	ranks STAPerc    SNOAPerc;
run;

data PCA_Base;
	set PCA_Base;
	COMBOACCRUAL = mean(STAPerc, SNOAPerc);

	if COMBOACCRUAL = 0 then
		delete;
run;

/* CREATING A 5-YEAR AVERAGE ROIC VARIABLE */
proc sort data=PCA_Base;
	by gvkey infome;
run;

data Recnum;
	format recnum 8.;
	set  PCA_Base;
	by   gvkey;
	recnum+1;

	if   first.gvkey then
		recnum=1;
run;

*Arithmetic Average;
data PCA_Base;
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

*Deleting companies with recnums less than 5;
data ROICLe5;
	set PCA_Base;
	where recnum le 4;
run;

data PCA_Base;
	set PCA_Base;

	if recnum le 4 then
		delete;
run;
