/*DATA MINING - 5 YEARS*/
%Macro PredModels;
	%do ThisYear=1975 %to 2015;
		%let NextYear=%eval(&ThisYear+1);
		%put &NextYear;
		%let FirstYear=%eval(&ThisYear-4);

		data ForAnal;
			set CombRank;

			if &FirstYear<=year(infome)<=&ThisYear;
		run;

		data ForScore;
			set CombRank;

			if Year(infome)=&NextYear;
		run;

		/*LINEAR REGRESSION*/
		proc reg data=ForAnal outest=RegOut&ThisYear;
			model ret12 = NPMRank   DEBT_INVCAPRank   TOTDEBT_INVCAPRank   PSRank   DEBT_ATRank   PRETRET_EARNATRank   LT_DEBTRank   EVMRank   INT_TOTDEBTRank   AT_TURNRank EYRank   ROICRank  PTBRank  ROIC5YRank  Mo12Rank  FIPRank;
		run;

		quit;

		proc score data=ForScore score=RegOut&ThisYear out=Scored&NextYear type=parms;
			var NPMRank   DEBT_INVCAPRank   TOTDEBT_INVCAPRank   PSRank   DEBT_ATRank   PRETRET_EARNATRank   LT_DEBTRank   EVMRank   INT_TOTDEBTRank   AT_TURNRank EYRank   ROICRank  PTBRank  ROIC5YRank  Mo12Rank  FIPRank;
		run;

		/*MARS*/
		proc adaptivereg data=ForAnal;
			model ret12 = NPMRank   DEBT_INVCAPRank   TOTDEBT_INVCAPRank   PSRank   DEBT_ATRank   PRETRET_EARNATRank   LT_DEBTRank   EVMRank   INT_TOTDEBTRank   AT_TURNRank EYRank   ROICRank  PTBRank  ROIC5YRank  Mo12Rank  FIPRank;
			score data=ForScore out=MARSScoredOut&NextYear;
		run;

		/*NEURAL NET*/
		proc hpneural data=ForAnal;
			input NPMRank   DEBT_INVCAPRank   TOTDEBT_INVCAPRank   PSRank   DEBT_ATRank   PRETRET_EARNATRank   LT_DEBTRank   EVMRank   INT_TOTDEBTRank   AT_TURNRank EYRank   ROICRank  PTBRank  ROIC5YRank  Mo12Rank  FIPRank;
			target ret12 / level=INT;
			id infome gvkey ret12;
			hidden 10;
			train outmodel=model_NN;
		run;

		proc hpneural data=ForScore;
			id infome gvkey ret12;
			score model=model_NN out=NNScored&NextYear(drop=_WARN_);
		run;

	%end;
%Mend PredModels;

%PredModels;

data RegScored (rename=(Model1=RegPred));
	set Scored:;
run;

data MARSScored (rename=(Pred=MARSPred));
	set MarsScoredOut:;
run;

data NeuralNetPred (rename=(P_Ret12=NNPred));
	set NNScored:;
run;

proc sort data=RegScored;
	by infome gvkey;
run;

proc sort data=MARSScored;
	by infome gvkey;
run;

proc sort data=NeuralNetPred;
	by infome gvkey;
run;

data PredComb;
	merge RegScored MARSScored NeuralNetPred;
	by infome gvkey;
	label NNPred='NeuralNetPred';
run;

proc sort data=PredComb;
	by infome gvkey;
run;

proc rank data=PredComb groups=20 descending ties=high out=RanksAnal;
	by 	infome;
	var   RegPred MARSPred NNPred;
	ranks RankReg RankMARS RankNN;
run;

/*MODEL BUILDING END*/
