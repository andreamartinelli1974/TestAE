function AA_BackTest(U,strategy,params) % *************************
% Before launching this method at least one dynamic AA strategy
% must have run (e.g. Universe_1.Dynamic_AA_1(DAA_params))
% strategy: one of the fields (currently only 1 is managed) in U.Strategies (e.g. Dynamic_AA_1)
% params: a struct array conmtaining a set of parameters needed
% to perform the backtest:
% .target: the desired level of risk (expressed as an interval, e.g. [0.15 0.16])
% .targetName: name of the field to search in .Strategies.Dynamic_AA_1.Dynamic_Frontier_EP

% IMPORTANT NOTES:
% I)
% returns must be calculated in the currency
% of denomination of the asset, since for futures and
% options there is no FX risk (excluding the margin for
% now, if it is deposited in the foreign currency),
% while for cash investments the FX risk is captured
% through separate assets (still TODO !!!!)

% II)
% suffix 'tminus' refers to the 'left limit' of the time variable
% t (that is BEFORE the investment decision is made BUT AFTER the
% market info for time t is available)
% suffix 'tplus' refers to the 'right limit' of the time variable
% t (that is AFTER the investment decision is made AND the
% market info for time t is available)

% TODO: at the very end ADD STOCHASTIC PROGRAMMING OPTIMAL
% CONTROL POLICY ALGORITHM TO DEFINE THE BEST REBALANCING
% POLICY

% IMPORTANT: 'lag4AA_enforcment': externalise this parameter.
% PURPOSE: 
% -> when = 1 every new optimal AA estimated as of time t
% kick in at time t + 1. HERE THE NEW AA IS IMPLEMENTED THE DAY AFTER - THIS IS WHAT WE NORMALLY DO
% -> when = 0 every new optimal AA estimated as of t kicks in at time t:
% this choice is not properly managed here, as we should consider different
% clsoing times for different mkt and also being able to get prices
% slightlu earlier than the mkt closing time. IN PRACTICE HERE WE ASSUME
% THAT WE IMPLEMENT (BUY/SELL) THE NEW AA AT TIME t



lag4AA_enforcment = U.Strategies.(strategy).DAA_params.lag4AA_enforcment;


U.Strategies.(strategy).BackTest = [];
S = U.Strategies.(strategy); % select the strategy to backtest

% input params
FixRebalThreshold = params.FixRebalThreshold;
FixedRebalCost_pct = params.FixedRebalCost_pct;
MinOutW_Assets = params.MinOutW_Assets;
Budget = U.Strategies.(strategy).DAA_params.Budget ;
StdES_window = params.VolaAndES_window;

L = size(S.H_dates_vector,1); % length in time dimension

active_assets = S.Dynamic_Frontier_EP.Active_Assets;
inactive_assets = abs(active_assets-1);
StartingTime = S.StartingTime;
Prices = S.Current_Prices4BackTest; % S.Current_Prices;

U.Strategies.(strategy).BackTest.HistPrices = Prices; % market prices

% ******************
% initial prices (as of the first investment decision (t=StartingTime)
% initial_prices = U.Strategies.(strategy).P0(StartingTime,:);
U.Strategies.(strategy).BackTest.AA = zeros(L,S.NAssets);
U.Strategies.(strategy).BackTest.AA_shares_tminus = zeros(L,S.NAssets);
U.Strategies.(strategy).BackTest.AA_shares_tplus = zeros(L,S.NAssets);
U.Strategies.(strategy).BackTest.SelectedSigma = zeros(L,1);
U.Strategies.(strategy).BackTest.SelectedER =  zeros(L,1);
U.Strategies.(strategy).TargetFoundFlag = zeros(L,1);

Rebalancing_Costs = zeros(L,1); % rebalancing costs
NewBudget = zeros(L,1); % equity process (net of rebalancing costs)
NewBudget_gross = zeros(L,1);  % equity process (gross of rebalancing costs)
Values_fcy_tplus = zeros(L,S.NAssets); % preallocation of matrix for single assets value process (in FCY)
Values_fcy_tminus = zeros(L,S.NAssets); % preallocation of matrix for single assets value process (in FCY)
Values_EUR_tplus = zeros(L,S.NAssets); % preallocation of matrix for single assets value process in EUR at the initial FX rate
Values_EUR_tminus = zeros(L,S.NAssets); % preallocation of matrix for single assets value process in EUR at the initial FX rate
Current_values_EUR = zeros(L,S.NAssets); % preallocation of matrix for single assets value process (in EUR)
Gains_fcy = zeros(L,S.NAssets); % preallocation of matrix for single assets gain process (in FCY)
Gains_EUR = zeros(L,S.NAssets); % preallocation of matrix for single assets gain process in EUR at the initial FX rate
CumGains_fcy = zeros(L,S.NAssets); % preallocation of matrix for single assets cumulative gain process (in FCY)
CumGains_EUR = zeros(L,S.NAssets); % tot gains process per single asset
TotGains_EUR = zeros(L,1); % tot P&L per day in EUR
TotCumGains_EUR = zeros(L,1); % cum P&L in EUR
Weights_Real = zeros(L,S.NAssets); % real weights
% Since I am considering P&L in EUROS (see note at the
% beginning), sterilizing FX impact, the vector LastFxDate(t) will
% keep track of the date to be used with the metghod ConvertFX
% to convert the Value amounts in EUR at the exchange rate of
% the last trade (current AA implementation)
LastFxDate_idx = zeros(L,1);
% for checks purposes
ReturnsFromRebal_EUR = zeros(L,S.NAssets);
ReturnsFromRebal_fcy = zeros(L,S.NAssets);
ReturnsFromRebal_price = zeros(L,S.NAssets);
ReturnsFromRebal_portfolio_1 = zeros(L,1);
ReturnsFromRebal_portfolio_2 = zeros(L,1);
cnt_chk = 0;

TotRet_stdev.fromt0 = zeros(L,1);
TotRet_es.fromt0 = zeros(L,1);
TotRet_stdev.rollwin = zeros(L,1);
TotRet_es.rollwin = zeros(L,1);

% Bonds and swaps pricing correction.
P_correction = ones(S.NAssets,1);

for t=StartingTime:L
    t-L
    
    REBALANCING = 0; % REBALANCING FLAG
    Rebalancing_Costs(t,1) = 0;
    
    % **************  REBALANCING FLAG MGMT *******************
    % Rebalancing can occur for 2 reasons
    % 1) FIXED REBALANCING RULE (temporary)
    % % rebalancing simply based on a fixed rule (e.g. when the diff between real and theorethical weights
    % is above a given threshold)
    % TODO: THIS DECISION SHOULD BE BASED ON STOCHASTIC
    % PROGRAMMING OPTIMIZATION
    % 2) change in optimal AA

    if t > StartingTime
        delta_aa(t,:) =  Weights_Real(t-1,:) - U.Strategies.(strategy).BackTest.AA(t-1,:);
        fc = find(abs(delta_aa(t,:)) > FixRebalThreshold); % FIXED REBAL RULE (at least one abs delta > FixRebalThreshold)
        
        if (~isempty(fc) && numel(fc) > MinOutW_Assets) ... % fixed rebal rule
                | (U.Strategies.(strategy).Allocation_changes_EP(t-lag4AA_enforcment) == 1) ... % AA change (in t-lag4AA_enforcment, but will produce effects from t, ...see below)

                REBALANCING = 1; % REBALANCING FLAG
            % If rebalancing occurs create a vector with ones
            % everywhere apart for swaps and bond where you
            % have the bond price.
            P_correction = ones(S.NAssets,1);
            for assetlookup =1 : S.NAssets
                if strcmp(class(U.Assets(assetlookup).value) , 'irs') == 1
                    if ~inactive_assets(t,assetlookup)
                        P_correction(assetlookup) = Prices(t,assetlookup);
                    end
                end
            end
        end
    end
    % ***********  END OF REBALANCING FLAG MGMT ***************
    
    % Multipliers as of time t
    for k=1:S.NAssets
        % retrieving the multiplier
        mult(t,k) = U.Assets(k).value.Multiplier; % asset multiplier
        
    end % k assets (hist prices as of time t)
    
    % Calculate the unit notional amounts: this is the mkt
    % price that refers to the units put in AA_shares
    U.Strategies.(strategy).BackTest.HistUnitNotionals(t,:) = (Prices(t,:).*mult(t,:));
    
    % Initial settings on the first day of the backtesting
    % window and dynamic asset allocation process
    if t==StartingTime
        
        % ****************************************************
        timeTOsearch = t;
        NewBudget(1:t) = Budget;
        NewBudget_gross(1:t) = Budget;
        % get allocations as of current t (U.Strategies.(strategy).BackTest.AA)
        
        [ft,tgtfound] = U.Search_AA(U,params,strategy,S,timeTOsearch);
        if isempty(ft)
            return
        end
        
        U.Strategies.(strategy).BackTest.SelectedSigma(t:end,1) = S.Dynamic_Frontier_EP.Risk(ft,timeTOsearch);
        U.Strategies.(strategy).BackTest.SelectedER(t:end,1) =  S.Dynamic_Frontier_EP.ExpectedReturn(ft,timeTOsearch);
        U.Strategies.(strategy).TargetFoundFlag(t:end,1) = tgtfound;
        
        % Creating matrix [Time x NoAssets] with
        % allocations to each asset (columns) per each
        % time (rows). THEORETICAL WEIGHTS AND NO OF SHARES
        for k=1:S.NAssets
            nma = ['Asset_',num2str(k)];
            % TRACKING ALLOCATION AS OF t
            % ... in relative weights terms
            U.Strategies.(strategy).BackTest.AA(t:end,k) = S.Dynamic_Frontier_EP.Allocation.(nma)(ft,timeTOsearch);
            
        end % k assets
        
        LastFxDate_idx(t:end) =  StartingTime;
        
        % as of t==StartingTime the values assigned below are
        % all zeros: remember that each new allocation,
        % including the first one, is executed the next trading
        % day
        U.Strategies.(strategy).BackTest.AA_shares_tminus = U.Strategies.(strategy).BackTest.AA_shares_tplus;
        Values_fcy_tminus(t,:) = U.Strategies.(strategy).BackTest.AA_shares_tminus(t,:).*U.Strategies.(strategy).BackTest.HistUnitNotionals(t,:);
        Values_EUR_tminus(t,:) = U.ConvertFX(Values_fcy_tminus(t,:), U.Currencies, U.ExchangeRates.fts,S.H_dates_vector(LastFxDate_idx(t)),'FXEUR');
        
        Values_fcy_tplus(t,:) = Values_fcy_tminus(t,:);
        Values_EUR_tplus(t,:) = Values_EUR_tminus(t,:);
        % ****************************************************
        
    end % t==StartingTime
    
    if t > StartingTime
        
        % ****************************************************
        sh = U.Strategies.(strategy).BackTest.AA_shares_tplus(t-1,:);
        rsh = repmat(sh,L-t+1,1);
        U.Strategies.(strategy).BackTest.AA_shares_tminus(t:end,:) = rsh; % updates no of shares in t- based on (t-1)+
        Values_fcy_tminus(t,:) = U.Strategies.(strategy).BackTest.AA_shares_tplus(t-1,:) ...
            .*U.Strategies.(strategy).BackTest.HistUnitNotionals(t,:);
        Values_EUR_tminus(t,:) = U.ConvertFX(Values_fcy_tminus(t,:), U.Currencies, ...
            U.ExchangeRates.fts,S.H_dates_vector(LastFxDate_idx(t)),'FXEUR');
        
        % ****************************************************
    end
    
    % *********************************************************
    % computed in t(-), before any AA change is considered
    Gains_fcy(t,:) = (Values_fcy_tminus(t,:) - Values_fcy_tplus(t-1,:))  .* P_correction'; % added correction term as per spreadsheet (SwapP&L_test4BackTest.xls in \AssetAllocation\DOC\Panos4validation\)
    Gains_fcy(t,find(inactive_assets(t-1,:))) = 0;
    CumGains_fcy(t,:) = sum(Gains_fcy(StartingTime:t,:));
    
    Gains_EUR(t,:) = (Values_EUR_tminus(t,:) - Values_EUR_tplus(t-1,:)) .* P_correction'; % added correction term as per spreadsheet (SwapP&L_test4BackTest.xls in \AssetAllocation\DOC\Panos4validation\)
    Gains_EUR(t,find(inactive_assets(t-1,:))) = 0;
    CumGains_EUR(t,:) = sum(Gains_EUR(StartingTime:t,:));
    
    TotGains_EUR(t,1) = sum(Gains_EUR(t,:));
    TotCumGains_EUR(t,1) = sum(CumGains_EUR(t,:));
    
    NewBudget(t) = NewBudget(t-1) + TotGains_EUR(t,1);
    NewBudget_gross(t) = NewBudget_gross(t-1) + TotGains_EUR(t,1);
    
    % *********************************************************
    
    % The code within the IF statement below is executed only
    % if the current time is > StartingTime and a REBALANCING
    % is triggered (by the availability of a new set of optimal
    % weights or by a rebalancing rule aimed at re-aligning
    % real weights to theoretical optimal ones)
    if REBALANCING == 1 & t>StartingTime+1
        
        % here the process Values_fcy(t-) becomes Values_fcy(t+)
        
        % REBALANCING
        % TODO: possibly design specific method for
        % different simple fixed rebalancing rules
        % [AA_shares_rebalanced, buys_sells] = rebalancing(rule, ....)
        % get allocations as of t-lag4AA_enforcment
        % (put in U.Strategies.(strategy).BackTest.AA)
        % As of time t-lag4AA_enforcment: if REBALANCING == 1 it means that a rebalancing trigger has
        % occurred in t-lag4AA_enforcment (see mgmt of REBALANCING flag above)
        % At this point all returns calculations based on the
        % previous allocation have been performed (see above).
        
        % BASICALLY when using, for example, lag4AA_enforcment=1 
        % I AM CHANGING ALLOCATION AT THE END OF THE
        % DAY following the day when the signal occurred: at
        % the end of this day the previous AA is sold and the
        % one emerged in t-1 is implemented (ASSUMING THAT BOTH SALES AND
        % PURCHASES ARE MADE AT THE CLOSING PRICES OF DAY t)
        
        Rebalancing_Costs(t,1) = NewBudget(t,1).*FixedRebalCost_pct;
        NewBudget(t) = NewBudget(t).*(1 - FixedRebalCost_pct);

        timeTOsearch =  t-lag4AA_enforcment;
        
        [ft,tgtfound] = U.Search_AA(U,params,strategy,S,timeTOsearch); % the main output is U.Strategies.(strategy).BackTest.AA (relative weights to be used below)
        if isempty(ft)
            return;
        end
        
        U.Strategies.(strategy).BackTest.SelectedSigma(t:end,1) = S.Dynamic_Frontier_EP.Risk(ft,timeTOsearch);
        U.Strategies.(strategy).BackTest.SelectedER(t:end,1) =  S.Dynamic_Frontier_EP.ExpectedReturn(ft,timeTOsearch);
        U.Strategies.(strategy).TargetFoundFlag(t:end,1) = tgtfound;
        
        % Creating matrix [Time x NoAssets] with
        % allocations to each asset (columns) per each
        % time (rows). THEORETICAL WEIGHTS AND NO OF SHARES
        for k=1:S.NAssets
            nma = ['Asset_',num2str(k)];
            % TRACKING ALLOCATION AS OF t
            % ... in relative weights terms
            U.Strategies.(strategy).BackTest.AA(t:end,k) = S.Dynamic_Frontier_EP.Allocation.(nma)(ft,timeTOsearch);
            % ... in no of shares terms:
            % this wouldn't be correct since at the moment
            % S.Dynamic_Frontier_EP.AllocationShares_FX is
            % calculated based on initial Budget and not on the
            % dynamically updated NewBudget as in AA_BackTest
            % U.Strategies.(strategy).BackTest.AA_shares_tplus(t:end,k) = S.Dynamic_Frontier_EP.AllocationShares_FX.(nma)(ft,timeTOsearch);
            
        end % k assets
        
        
        aa_weights = U.Strategies.(strategy).BackTest.AA(t,:);
        aa_EUR = NewBudget(t).*aa_weights;
        Values_fcy_tplus(t,:) = U.ConvertFX(aa_EUR,U.Currencies,U.ExchangeRates.fts,S.H_dates_vector(t),'EURFX');
        Values_fcy_tplus(t,find(inactive_assets(t,:))) = 0;
        Values_EUR_tplus(t,:) = aa_EUR;
        LastFxDate_idx(t:end,1) = t;
        sh = Values_fcy_tplus(t,:)./U.Strategies.(strategy).BackTest.HistUnitNotionals(t,:);
        sh(find(inactive_assets(t,:))) = 0;
        rsh = repmat(sh,L-t+1,1);
        U.Strategies.(strategy).BackTest.AA_shares_tplus(t:end,:) = rsh;
    else
        Values_fcy_tplus(t,:) = Values_fcy_tminus(t,:);
        Values_EUR_tplus(t,:) = Values_EUR_tminus(t,:);
    end % REBALANCING == 1
    
    % the following measures of tot return should be equal
    TotReturn_1(t,1) = NewBudget(t,1)./Budget - 1; % Net tot ret
    TotReturn_2(t,1) = TotCumGains_EUR(t,1)./Budget; % Gross tot ret
    Weights_Real(t,:) = Values_EUR_tplus(t,:)./NewBudget(t);
    % *********************************************************
    
    % **************** a few checks ******************
    if t>StartingTime+1
        % a) % P&L per asset (from previous rebalancing ) calculated based on Values_fcy and
        % Values_EUR must be the same to be sure that there is no
        % FX impact (see note at the beginning) and both must equal
        % pct price change in fcy. Their sum should equal
        % portfolio's return from previous rebalancing
        ReturnsFromRebal_EUR(t,:) = Values_EUR_tminus(t,:)./Values_EUR_tplus(LastFxDate_idx(t),:) - 1;
        ReturnsFromRebal_fcy(t,:) = Values_fcy_tminus(t,:)./Values_fcy_tplus(LastFxDate_idx(t),:) - 1;
        ReturnsFromRebal_price(t,:) = Prices(t,:)./Prices(LastFxDate_idx(t),:) - 1;
        ReturnsFromRebal_portfolio_1(t,1) = NewBudget(t,1)./NewBudget(LastFxDate_idx(t),1) - 1;
        
        % TODO: for now make checks using the intermediate
        % output file produced below: to implement the below
        % listed automatic checks it is necessary to fix
        % rounding and NaN indiced errors in the equalities
        % below
        
        %                     if ~(ReturnsFromRebal_EUR(t,:)==ReturnsFromRebal_fcy(t,:) & ReturnsFromRebal_fcy(t,:)==ReturnsFromRebal_price(t,:) ...
        %                             & sum(ReturnsFromRebal_price(t,:)) == ReturnsFromRebal_portfolio_1(t,:))
        %                         msgbox('Consistency check (a) violated');
        %                         pause;
        %                     end
        
        % b) Single assets % P&L from previous rebal, weighted by
        % the real weights vector, should equal % portfolio's %
        % return
        % TODO: check this check !!!
        
        fnotnan = find(~isnan(ReturnsFromRebal_EUR(t,:)));
        ReturnsFromRebal_portfolio_2(t,1) = sum(ReturnsFromRebal_EUR(t,fnotnan).*Weights_Real(t-1,fnotnan));
        %                     if ~(ReturnsFromRebal_portfolio_2(t,1) == ReturnsFromRebal_portfolio_1(t,1))
        %                         msgbox('Consistency check (b) violated');
        %                         pause;
        %                     end
        
        % STD and ES measures for the portfolio equity line as
        % of time t: BOTH FROM TIME 0 AND BASED ON A ROLLING
        % WINDOW
        dTotRet = [0;diff(TotReturn_2)];
        TotRet_stdev.fromt0(t,1) = std(dTotRet(StartingTime:t));
        VaR = prctile(dTotRet(StartingTime:t),1); % VaR 1%
        ES = mean(dTotRet(dTotRet<=VaR));
        TotRet_es.fromt0(t,1) = max(0,-ES);
        if (t-StartingTime) > StdES_window % ROLLING MEASURES
            TotRet_stdev.rollwin(t,1) = std(dTotRet(t-StdES_window+1:t));
            subset = dTotRet(t-StdES_window+1:t);
            VaR_roll = prctile(subset,1);
            ES_roll = mean(subset(subset<=VaR_roll));
            TotRet_es.rollwin(t,1) = max(0,-ES_roll);
        end
    end
    % ************************************************
    % partial output for checks (for each time t)
    dt_xls = m2xdate(S.H_dates_vector(t));
    
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'Prices (FCY)',Prices(t,:),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'Multiplier',mult(t,:),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'Unit Notionals',U.Strategies.(strategy).BackTest.HistUnitNotionals(t,:),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'Current Value processes FCYs in t-',Values_fcy_tminus(t,:),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'Current Value processes FCYs in t+',Values_fcy_tplus(t,:),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'Current Value processes EUR (at initial FX rates) in t-',Values_EUR_tminus(t,:),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'Current Value processes EUR (at initial FX rates) in t+',Values_EUR_tplus(t,:),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'Gain Process FCY',Gains_fcy(t,:),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'Cum Gain Process FCY',CumGains_fcy(t,:),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'Gain Process EUR',Gains_EUR(t,:),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'Cum Gain Process EUR',CumGains_EUR(t,:),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls ...
        ,'Tot Gains process  EUR (at initial FX rates)',TotGains_EUR(t,1),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'Tot Cum Gain process EUR (at initial FX rates)', TotCumGains_EUR(t,1),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'Portfolio % Total Return 1',TotReturn_1(t,1),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'Portfolio % Total Return 2',TotReturn_2(t,1),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        '% Returns from previous rebal based on EUR Value process',ReturnsFromRebal_EUR(t,:),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        '% Returns from previous rebal based on fcy Value process',ReturnsFromRebal_fcy(t,:),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        '% Returns from previous rebal based on prices',ReturnsFromRebal_price(t,:),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        '% Portfolio Return from previous rebal',ReturnsFromRebal_portfolio_1(t,:),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        '% Portfolio Return from previous rebal (based on real weights)',ReturnsFromRebal_portfolio_2(t,:),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'Real Weights', Weights_Real(t,:),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'No of Shares in t-', U.Strategies.(strategy).BackTest.AA_shares_tminus(t,:),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'No of Shares in t+', U.Strategies.(strategy).BackTest.AA_shares_tplus(t,:),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'Theoretical Weights', U.Strategies.(strategy).BackTest.AA(t,:),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'Net Running Budget', NewBudget(t,1),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'Gross Running Budget', NewBudget_gross(t,1),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'Portfolio realized Volatility (from t0)', TotRet_stdev.fromt0(t,1),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'Portfolio realized ES (from t0)', TotRet_es.fromt0(t,1),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'Portfolio realized Volatility (rolling window)', TotRet_stdev.rollwin(t,1),S.NAssets);
    cnt_chk = cnt_chk + 1;
    U.Strategies.(strategy).BackTest.output_check(cnt_chk,:) = U.Write_Output_Check(dt_xls, ...
        'Portfolio realized ES (rolling window)', TotRet_es.rollwin(t,1),S.NAssets);
    
    % END OF partial output for checks (for each time t)
    % **********************************************************
end % t

delete('BT_checks_test.*');

% * xlswrite('BT_checks_test',U.Strategies.(strategy).BackTest.output_check);

Rebalancing_Costs_BT = Rebalancing_Costs(StartingTime:end);
BT_dates_vector = S.H_dates_vector(StartingTime:end);
AA_changes_BT_window = S.Allocation_changes_EP(StartingTime:end);

faac = find(AA_changes_BT_window == 1); % indices of AA changes times over the BT window
frbc = find(Rebalancing_Costs_BT>0); % indices of rebal times over the BT window

U.Strategies.(strategy).BackTest.TotReturn(t,1) = S.H_dates_vector(t);
U.Strategies.(strategy).BackTest.TotReturn(t,2) = TotReturn_1(t,1);
U.Strategies.(strategy).BackTest.TotReturn(t,3) = TotReturn_2(t,1);
U.Strategies.(strategy).BackTest.Dates_Vector = S.H_dates_vector;
U.Strategies.(strategy).BackTest.Values_fcy_tminus = Values_fcy_tminus;
U.Strategies.(strategy).BackTest.Values_fcy_tplus = Values_fcy_tplus;
U.Strategies.(strategy).BackTest.Values_EUR_tminus = Values_fcy_tminus;
U.Strategies.(strategy).BackTest.Values_EUR_tplus = Values_fcy_tplus;
U.Strategies.(strategy).BackTest.Gains_fcy = Gains_fcy;
U.Strategies.(strategy).BackTest.Gains_EUR = Gains_EUR;
U.Strategies.(strategy).BackTest.CumGains_fcy = CumGains_fcy;
U.Strategies.(strategy).BackTest.CumGains_EUR = CumGains_EUR;
U.Strategies.(strategy).BackTest.TotGains_EUR = TotGains_EUR;
U.Strategies.(strategy).BackTest.TotReturn_1 = TotReturn_1;
U.Strategies.(strategy).BackTest.TotReturn_2 = TotReturn_2;
U.Strategies.(strategy).BackTest.Weights_Real = Weights_Real;
U.Strategies.(strategy).BackTest.TotCumGains_EUR = TotCumGains_EUR;
U.Strategies.(strategy).BackTest.AA_changes_no = numel(faac);
U.Strategies.(strategy).BackTest.Rebal_no = numel(frbc);
U.Strategies.(strategy).NewBudget = NewBudget;
U.Strategies.(strategy).TotRet_stdev = TotRet_stdev;
U.Strategies.(strategy).TotRet_es = TotRet_es;

% ************************  CHARTS ****************************
% leg{1,1} = ['Net Value Process'];
leg{1,1} = ['Gross Value Process'];
leg{2,1} = ['Asset Allocation Changes'];
leg{3,1} = ['Rebalancings'];
totE(:,1) = S.H_dates_vector(StartingTime:end);
totE(:,2) = NewBudget(StartingTime:end);
totE(:,3) = Budget + TotCumGains_EUR(StartingTime:end);
CumG_assets = CumGains_EUR(StartingTime:end,:);
totCumG = TotCumGains_EUR(StartingTime:end);

% Create the grouping and sum CumG_assets by grouping.
for i= 1 : size(CumGains_EUR,2)
    temp{1,i} = cell2mat(U.Assets(i,1).value.AssetType);   % Panos addition saving asset type to create new aggregate 24/10/2017
end
[unique_data_types,~,c] = unique(temp);

Gains_EUR_by_asset_type = zeros(length(unique_data_types) ,size(CumGains_EUR,1));
for i = 1 : size(CumGains_EUR,1)  % For all days
    Gains_EUR_by_asset_type(:,i) = accumarray(c,CumGains_EUR(i,:));
end
Gains_EUR_by_asset_type = Gains_EUR_by_asset_type';
CumG_assets_bytype = Gains_EUR_by_asset_type(StartingTime:end,:);

%% fugure 1
if ~isdeployed
    figure;
    hold on; grid on;
    % plot(totE(:,1),totE(:,2),'LineWidth',3); % TODO: visualize only after having introduced a reliable rebalancing policy
    plot(totE(:,1),totE(:,3),'Color','r','LineWidth',3);
    plot(totE(faac,1),totE(faac,3),'o','Color','g','LineWidth',0.5);
    % plot(totE(frbc,1),totE(frbc,2),'o','Color','y','LineWidth',2); % rebalancing times
    dateaxis('x',12);
    xlim([min(totE(:,1)) max(totE(:,1))]);
    xlabel('Time (daily granularity)');
    ylabel(['Total Value (base = ',num2str(Budget),')']);
    tit = ['Dynamic AA with strategy ',strrep(strategy,'_',' '),': Total Value Process'];
    title(tit,'FontSize',12);
    legend(leg);
end
%% figure 2
if ~isdeployed
    fl{1,1} = ['Overall Gain Process'];
    leg1 = [fl{1,1};U.Assets_Legend(:,1)];
    figure
    hold on; grid on;
    plot(totE(:,1),totCumG,'Color','r','LineWidth',3);
    plot(totE(:,1),CumG_assets);
    dateaxis('x',12);
    xlim([min(totE(:,1)) max(totE(:,1))]);
    xlabel('Time (daily granularity)');
    ylabel(['EUR denominated gains']);
    title(['Overall and single assets gain processs'],'FontSize',12);
    legend(leg1,'Location','eastoutside','Orientation','vertical','Interpreter','none','FontSize',7);
end

%% Panos Addition
% figure 3
f2{1,1} = ['Overall Gain Process'];
leg1 = [f2{1,1};unique_data_types'];
tit3 = ['Overall and assets by type gain processs'];

if ~isdeployed
    figure
    hold on; grid on;
    plot(totE(:,1),totCumG,'Color','r','LineWidth',3);
    plot(totE(:,1),CumG_assets_bytype);
    dateaxis('x',12);
    xlim([min(totE(:,1)) max(totE(:,1))]);
    xlabel('Time (daily granularity)');
    ylabel(['EUR denominated gains']);
    tit3 = ['Overall and assets by type gain processs'];
    title(tit3,'FontSize',12);
    legend(leg1,'Location','eastoutside','Orientation','vertical','Interpreter','none','FontSize',7);
end

Chart3.legenda = leg1;
Chart3.X = totE(:,1);
Chart3.Y1 = totCumG;
Chart3.Y2 = CumG_assets_bytype;
Chart3.Labels = {'Time (daily granularity)','EUR denominated gains',tit3};
save('Chart3.mat','Chart3');

% end panos add
%% figure 4
% leg{1,1} = ['Net Total Return 1'];
leg{1,1} = ['Gross Total Return 1'];
leg{2,1} = ['Asset Allocation Changes'];
leg{3,1} = ['Rebalancings'];
totR(:,1) = S.H_dates_vector(StartingTime:end);
totR(:,2) = TotReturn_1(StartingTime:end)*100;
totR(:,3) = TotReturn_2(StartingTime:end)*100;
tit = ['Dynamic AA with strategy ',strrep(strategy,'_',' '),': Total Return Process'];

if ~isdeployed
    figure;
    hold on; grid on;
    % plot(totR(:,1),totR(:,2),'LineWidth',3); % TODO: visualize only after having introduced a reliable rebalancing policy
    plot(totR(:,1),totR(:,3),'Color','r','LineWidth',3);
    plot(totR(faac,1),totR(faac,3),'o','Color','g','LineWidth',0.5);
    % plot(totR(frbc,1),totR(frbc,2),'o','Color','y','LineWidth',2); % rebalancing times
    dateaxis('x',12);
    xlim([min(totR(:,1)) max(totR(:,1))]);
    xlabel('Time (daily granularity)');
    ylabel('Total Return (%)');
    title(tit,'FontSize',12);
    legend(leg);
end

Chart4.legenda = leg;
Chart4.X1 = totR(:,1);
Chart4.Y1 = totR(:,3);
Chart4.X2 = totR(faac,1);
Chart4.Y2 = totR(faac,3);
Chart4.Labels = {'Time (daily granularity)','Total Return (%)',tit};
save('Chart4.mat','Chart4');

%% figure 5
W = zeros(size(S.H_dates_vector(StartingTime:end),1),size(Weights_Real,2)+1);
W(:,1) = S.H_dates_vector(StartingTime:end);
W(:,2:end) = Weights_Real(StartingTime:end,:);
tit5 = ('Real Weights (assuming simple fixed rule based rebalancing)');

if ~isdeployed
    figure;
    hold on; grid on;
    plot(W(:,1),W(:,2:end).*100);
    dateaxis('x',12);
    xlim([min(W(:,1)) max(W(:,1))]);
    xlabel('Time (daily granularity)');
    ylabel('% Weights');
    title(tit5,'FontSize',12);
    legend(U.Assets_Legend(:,1),'Location','eastoutside','Orientation','vertical','Interpreter','none','FontSize',7);
end

Chart5.legenda = U.Assets_Legend(:,1);
Chart5.X = W(:,1);
Chart5.Y = W(:,2:end).*100;
Chart5.Labels = {'Time (daily granularity)','% Weights',tit5};
save('Chart5.mat','Chart5');

%% figure 6
% charting realized volatility and ES (from initial time and rolling window based)
riskperf(:,1) = S.H_dates_vector(StartingTime:end);
riskperf(:,2) = TotRet_stdev.fromt0(StartingTime:end);
riskperf(:,3) = TotRet_stdev.rollwin(StartingTime:end);
riskperf(:,4) = TotRet_es.fromt0(StartingTime:end);
riskperf(:,5) = TotRet_es.rollwin(StartingTime:end);
legrp{1,1} = ['Volatility from t_0'];
legrp{2,1} = ['Rolling Volatility'];
legrp{3,1} = ['ES from t_0'];
legrp{4,1} = ['Rolling ES'];
tit6 = ('Realized SD and ES (both rolling and from initial time)');

if ~isdeployed
    figure;
    hold on; grid on;
    plot(riskperf(:,1),riskperf(:,2:3).*100,'Linewidth',1);
    plot(riskperf(:,1),riskperf(:,4:5).*100,'Linewidth',3);
    dateaxis('x',12);
    xlim([min(riskperf(:,1)) max(riskperf(:,1))]);
    xlabel('Time (daily granularity)');
    ylabel('% SD and ES (daily)');
    title(tit6,'FontSize',12);
    legend(legrp,'Location','eastoutside','Orientation','vertical','Interpreter','none','FontSize',7)
end

Chart6.legenda = legrp;
Chart6.X1= riskperf(:,1);
Chart6.Y1 = riskperf(:,2:3).*100;
Chart6.Y2 = riskperf(:,4:5).*100;
Chart6.Labels = {'Time (daily granularity)','% SD and ES (daily)',tit6};
save('Chart6.mat','Chart6');


end % AA_BackTest method ******************************************
