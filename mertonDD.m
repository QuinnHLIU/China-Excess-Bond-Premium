%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% Merton's DD model: Chinese listed-firm 1990-2022 %%%%%%%%%%%%
%%% Input:daily market valuation, stock return standard deviation over past
%%% year; quarterly balance sheet 

cd("E:\Dropbox\UMP_Paper\TempFiles\MertonEstimate")

inpath="E:\Dropbox\UMP_Paper\TempFiles\MertonEstimate\";
outpath="E:\Dropbox\UMP_Paper\OutPut\MertonEstimate\";
filelist = dir(strcat(inpath,"*.xlsx"));


for i=1:length(filelist) 

    [data,descr]=xlsread(strcat(inpath,filelist(i).name));

    % Current market value of firm's equity, specified as a positive value.
    Equity    = data(:,1); 

    % Volatility of the firm's equity, specified as a positive annualized standard deviation.
    % GZ:historical daily stock returns using a 250-day moving window
    % so use standard deviations of stock returns in the last year
    EquityVol = data(:,2); 

    % Liability threshold of firm, specified as a positive value. 
    % The liability threshold is often referred to as the default point.
    % so in the bond case, use bond's face value? then shouldn't the "equity"
    % replaced by unrestricted cash?
    % GZ: sum of current liabilities + long-term liabilities/2. This is also
    % used by Moody's KMV. Both current and long-term liabilities are taken
    % from quarterly Compustat and interpolated to daily frequency using a step
    % function.
    % Then how do you define "current" and "long-term liabilities"? 短期负债和长期负债？
    Liability = data(:,3);

    % Annualized risk-free interest rate, specified as a numeric value.
    % GZ:daily 1-year Treasury yield
    Rate      = data(:,4); 

    % Time to maturity corresponding to the liability threshold, 
    % specified as the comma-separated pair consisting of 'Maturity' and a positive value.
    % so just use the maturity of bonds (in unit of year instead of days! 
    % so devided by 365? or 250? I think it's 365 bcos that's how you convert year to days previously)
    % Maturity  = MertonData.Maturity;
    
    % Annualized drift rate (expected rate of return of the firm's assets...ROA?)
    % or daily stock returns compounded to annual? (exclude weekend and holidays, which have no data)
    % or just set it to be 0? (since it's optional)
    %Drift     = MertonData.Drift;
    Drift  =  data(:,5);

    
    [PD,DD,A,Sa] = mertonmodel(Equity,EquityVol,Liability,Rate,'Drift',Drift); %
    % PD:Probability of default of the firm at maturity, returned as a numeric value.
    % DD:Distance-to-default, defined as the number of standard deviations between 
    % the mean of the asset distribution at maturity and the liability threshold 
    % (default point), returned as a numeric value.
    % A=Current value of firm's assets, returned as a numeric value.
    % Sa=Annualized firm's asset volatility, returned as a numeric value.
    
    writematrix([PD,DD],strcat(outpath, strcat(filelist(i).name)))
end

