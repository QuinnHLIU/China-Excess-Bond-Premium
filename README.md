# China-Excess-Bond-Premium

## Step 1. Retrieve Market Data at Stock Level from WIND Excel API

run **preparse_MertonDD.do**: 
- read stock prices and market valuation
- construct $E$(market valuation), $\sigma_E$(stock volatility), $\mu$(average asset growth rate) and $D$(face value of debt)
- export to separate excel files for each stock to be read by MATLAB program

## Step 2. Estimate Merton DD Model

run **mertonDD.m**:
- essentially a for loop for each stock.
- help mertonmodel for parameters and model assumption

## Step 3. Combine DD Measure for Each Stock and Evaluate Distribution

run **computeDD.do**


## Step 4: Compute Excess Bond Premium Based on the DD measure

run **EBP.do**
- the constuction refers to Gilchrist and Zakrajšek (2012)

