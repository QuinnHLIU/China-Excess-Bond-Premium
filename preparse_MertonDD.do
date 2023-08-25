/* Preprocess Data as input for the matlab DD program. Jul-3. */
//E=daily market valuation; sigmaE = sd of stock returns over past 252 business day window
//mu=average asset growth in the past three years;D=liquid liability+long-term liability/2;T=1Y

global root E:\Dropbox\UMP_Paper/EBP/Git
cd $root 


foreach step1 in "DailyStockPriceMarketVal"{
	
use RawData/StockMktval_Daily,replace

gen lnprice=log(close_price)
gen returns=d.lnprice
su lnprice returns market_valuation close_price
replace returns=. if returns==0 //weekends or holidays 

forv k=1/365{    // =252 business day
	gen mvlag`k' = l`k'.returns 
}
egen numtrade=rownonmiss(mvlag*)
egen sigmaE = rowsd(mvlag*)
replace sigmaE=. if numtrade < 90  //if less than 90 days of trading
replace sigmaE=. if sigmaE==0      //1 


rename market_valuation E 
keep stockcode date E sigmaE 
replace E=. if E==0
drop if sigmaE==. | E==. 

unique stockcode  // 4282 stocks
save CleanData/MertonE,replace

}



foreach step2 in "quarterlyBalanceSheet"{ 

//data retrieved from WIND excel API 
forv k=1/2{
import excel using RawData/quarterlydata_allStock_part`k'.xlsx,firstrow clear
gen Date=date(date,"YMD")
gen qdate=qofd(Date),a(date) 
drop date Date
findname stockcode qdate,not local(vvs)
foreach v in `vvs'{
	cap bys stockcode (qdate): ipolate `v' qdate,gen(ipo)
	if _rc==0{
	drop `v'
	rename ipo `v'
	}
}

egen id=group(stockcode)
xtset id qdate,q 
gen lnasset=log(资产总计)
gen assetgr = d.lnasset
forv k=1/16{
	gen lyr`k'growth=l`k'.assetgr 
}
egen drift=rowmean(lyr* )

// see how well you can do; very likely one 12/31 data exists then you have to do ipolate 
// there might also be seasonality / inflation issue to think about.
// would this be the reason that you see a trend in your EBP? how about do a HP filter?
egen shortdebt=rowtotal(短期借款 应付票据 应付账款 应付职工薪酬 应付利息 应付股利 应付手续费及佣金 应交税费 一年内到期的非流动负债),missing
egen longdebt=rowtotal(长期借款 应付债券),missing 
rename 流动负债合计 shortliability 
rename 非流动负债合计 longliability 

gen quarter=quarter(dofq(qdate))
tab quarter if shortdebt != .  // actually even !

drop quarter
*replace shortliability=shortliability/cpib1989  // deflated by CPI with 1989 as base year
*replace longliability=longliability/cpib1989  


keep stockcode qdate *liability *debt drift
egen rownonmiss=rownonmiss(*liability *debt drift)
drop if rownonmiss==0
drop rownonmiss


//ipolate to daily 
gen quarter=quarter(dofq(qdate))
gen year=year(dofq(qdate))
gen date=mdy(1,1,year) if quarter==1
replace date=mdy(4 ,1,year) if quarter==2
replace date=mdy(7 ,1,year) if quarter==3
replace date=mdy(12,31,year) if quarter==4
egen fid=group(stockcode)
xtset fid date,d
tsfill
bys fid (stockcode):replace stockcode=stockcode[_N]
findname *liability *debt drift,local(vvs)
foreach v in `vvs'{
	bys fid (date):ipolate `v' date,gen(ipo)
	drop `v'
	rename ipo `v'
}
drop qdate quarter year fid
save TempFiles/ListedFirmQuarterlyDebtIpolated_`k',replace

}

 use TempFiles/ListedFirmQuarterlyDebtIpolated_1,replace
merge 1:1 stockcode date using TempFiles/ListedFirmQuarterlyDebtIpolated_2,nogen
save CleanData/ListedFirmDebtIpolated,replace 

}




use CleanData/MertonE,replace
gen year=year(date),a(date)
merge m:1 date using RawData/treasury1y,keep(1 3) nogen // already annualized
rename treasury1y rf 
//tab year if rf == .  // pre 2002 or 2023
drop if rf==.

merge 1:1 stockcode date using CleanData/ListedFirmDebtIpolated,keep(1 3) nogen
replace longdebt=longdebt/2 
egen D = rowtotal(shortdebt longdebt),missing
keep stockcode date E sigmaE drift D rf 
replace D=D/10^8  // unit=100Mil RMB(in line with E)

replace D=. if D<=0  //required by MATLAB to be positive...193 changes
replace E=. if E<=0  //required by MATLAB to be positive...0 changes

replace rf=rf/100 
su drift rf  // right magnitude :>
//replace drift =0 if drift ==. //required by MATLAB to be positive
save CleanData/MertonEstimate,replace 


//create separate excel as input for MATLAB
 use CleanData/MertonEstimate,replace 

qui levelsof stockcode,local(stks)
foreach stk in `stks'{
	preserve 
	keep if stockcode=="`stk'"
	tsset date,d 
	tsfill
	
	foreach v in sigmaE drift rf{
		replace `v'=`v'*100
	}
	keep  date E sigmaE D rf drift
	order date E sigmaE D rf drift
	qui egen rowexit=rowmiss(E sigmaE D rf drift)
	qui su 
	local mm = r(min)
	if `mm'==0{ //only estimate if at least one obs.
	drop rowexit
	local stn = subinstr("`stk'",".","_",.)
	export excel using TempFiles/InputofMATLAB/`stn'.xlsx,firstrow(variables) replace
	gen id = _n // keep the date column there
	save TempFiles/InputofSTATA/`stn',replace 
	}
	restore 
}


// Then run mertonDD.m 




