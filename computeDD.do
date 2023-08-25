/* Read back outputs of mertonDD.m. Jul-3. */


global root E:\Dropbox\UMP_Paper/EBP/Git
cd $root 


filelist,dir("$root/OutPut")
qui levelsof filename,local(fs)
foreach f in `fs'{
	import excel using OutPut/`f', clear 
	rename A PD
	rename B DD
	gen id=_n 
	local fn=subinstr("`f'",".xlsx","",.)
	save TempFiles/`fn'out,replace 
}



use CleanData/MertonEstimate,replace 
qui levelsof stockcode,local(stks)
foreach stk  in `stks'{
	preserve 
	local stn = subinstr("`stk'",".","_",.)
	qui cap use TempFiles/InputofSTATA/`stn',replace //so that we retrieve exactly the time id 
	cap gen stockcode="`stk'"
	cap replace stockcode="`stk'"
	cap merge 1:1 id using TempFiles/`fn'out,nogen   //all full match
	qui save TempFiles/`fn'est,replace 
	restore 
}

clear 
foreach stk  in `stks'{
	local stn = subinstr("`stk'",".","_",.)
	cap append using TempFiles/`fn'est
}
unique stockcode
rename PD EDF  // prob. of default 




hist EDF  // 
su EDF

hist DD if DD <50
winsor2 DD, cut(1 99) suffix(ws) trim
winsor2 EDF, cut(1 99) suffix(ws) trim

hist DDws 
hist EDFws,width(0.2) 

save OutPut\MertonDDEstimateAug13,replace 
/*
 use OutPut\MertonDDEstimateJul26,replace
keep stockcode 
duplicates drop 
export excel using TempFiles/suppIndustry.xlsx,firstrow(variables) replace 
import excel using TempFiles/suppIndustry.xlsx,firstrow clear 
save TempFiles/indname,replace
*/
 use OutPut\MertonDDEstimateAug13,replace
//su DD, d  //>>> 1st or 99th: -4 and 6
//hist DD
//drop if DD<-4 | DD>6
//hist DD
merge m:1 stockcode using TempFiles/indname,keep(1 3) nogen 
gen mdate=mofd(date)
save TempFiles/ebptemp,replace

 use TempFiles/ebptemp,replace
 drop if DDws==.
bys mdate:egen DDp50=median(DDws)
bys mdate:egen DDp25=pctile(DDws),p(25)
bys mdate:egen DDp75=pctile(DDws),p(75)
gen nonfinancial=(所属证监会行业 != "金融、保险业")
bys mdate nonfinancial:egen DDmed=median(DD)
format mdate %tm
gen year=year(date)
tabstat DD,by(year)
tw (rarea DDp25 DDp75 mdate,fc(yellow) lc(white)) (line DDp50 mdate,lc(red) lp(dash)) ///
   (line DDmed mdate if nonfinancial,lc(black)) if year>=2002,xti("") 
gr export OutPut/Graphics/distance-to-default-0813.png,width(2400) replace 






//merge daily bond data with daily stock price
use TempFiles/allListedBond,replace
merge stockcode

/* --------------- Local Projection: InvestGrowth on MPS x EBP --------------- */

gen scode=substr(stockcode,1,strpos(stockcode,".")-1)
unique stockcode scode
unique scode  // indeed unique!



