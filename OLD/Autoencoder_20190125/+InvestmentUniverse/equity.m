classdef equity < InvestmentUniverse.asset
    % definizione sub-class equity (base class is asset): this class is
    % suited to model all 'equity style' products, bot necessarily
    % corresponding to products that belongs to the EQUITY asset class.
    % E.G. the Bund future is best modelled through this class. The 'asset_type'
    % property is used as an input to describe the specific asset in terms
    % of ASSET CLASS.
    
    properties
        
    end
    
    properties (SetAccess = immutable)
        % proprietà specifiche subclass 'equity'
        isproxy  = [];
        Specific_Attributes = [];
    end
    
    properties (SetAccess = protected)
        % proprietà specifiche subclass 'equity'
    end
    
    methods
        % costruttore oggetto 'equity' come subclass di asset
        function S = equity(asset_params)
            S = S@InvestmentUniverse.asset(asset_params);
            % inputs specific to @equity
            
            
            if isempty(S.Synthetic)
                bbg_fields = {'TICKER','TICKER_AND_EXCH_CODE','EQY_PRIM_EXCH_SHRT','CUR_MKT_CAP','PE_RATIO', ...
                    'EBITDA','BEST_ROE_MEDIAN','TOT_DEBT_TO_TOT_CAP','EQY_RAW_BETA','IDX_EST_DVD_YLD', ...
                    'EQY_DVD_YLD_EST','INDUSTRY_SECTOR','INDUSTRY_GROUP','EQY_DVD_CASH_GROSS_NEXT','BDVD_PROJ_DIV_AMT', ...
                    'EQY_DVD_CASH_EX_DT_NEXT','BDVD_NEXT_EST_EX_DT','REL_INDEX','BETA_OVERRIDE_REL_INDEX'};
                % getting Bloomberg static data through an instance
                % of class Utility
                uparam.DataFromBBG = asset_params.DataFromBBG;
                uparam.ticker = asset_params.ticker_BBG;
                uparam.fields = bbg_fields;
                uparam.override_fields = [];
                uparam.override_values = [];
                
                U = Utilities(uparam);
                U.GetBBG_StaticData;
                d = U.Output.BBG_getdata;
                
                
                % [d,sec] = getdata(bbgconn,ticker_BBG,bbg_fields); % data request to Bloomberg
                S.Specific_Attributes.raw_beta = d.EQY_RAW_BETA;
                S.Specific_Attributes.tickexchcode = d.TICKER_AND_EXCH_CODE;
                S.Specific_Attributes.primary_exch = d.EQY_PRIM_EXCH_SHRT;
                S.Specific_Attributes.mktcap = d.CUR_MKT_CAP;
                S.Specific_Attributes.pe_ratio = d.PE_RATIO;
                S.Specific_Attributes.ebitda = d.EBITDA;
                S.Specific_Attributes.ROE = d.BEST_ROE_MEDIAN;
                S.Specific_Attributes.tdebt2tcap = d.TOT_DEBT_TO_TOT_CAP;
                S.Specific_Attributes.IDX_EST_DVD_YLD = d.IDX_EST_DVD_YLD;
                S.Specific_Attributes.EQY_DVD_YLD_EST = d.EQY_DVD_YLD_EST;
                S.Specific_Attributes.TICKER = d.TICKER;
                S.Specific_Attributes.INDUSTRY_SECTOR = d.INDUSTRY_SECTOR;
                S.Specific_Attributes.INDUSTRY_GROUP = d.INDUSTRY_GROUP;
                S.Specific_Attributes.EQY_DVD_CASH_GROSS_NEXT = d.EQY_DVD_CASH_GROSS_NEXT;
                S.Specific_Attributes.BDVD_PROJ_DIV_AMT = d.BDVD_PROJ_DIV_AMT;
                S.Specific_Attributes.EQY_DVD_CASH_EX_DT_NEXT = d.EQY_DVD_CASH_EX_DT_NEXT;
                S.Specific_Attributes.BDVD_NEXT_EST_EX_DT = d.BDVD_NEXT_EST_EX_DT;
                S.Specific_Attributes.REL_INDEX = d.REL_INDEX;
                
                
                if ~isfield(S.Specific_Attributes,'INDUSTRY_SECTOR') || isempty(S.Specific_Attributes.INDUSTRY_SECTOR{1})
                    S.Specific_Attributes.INDUSTRY_SECTOR{1} = 'Other';
                end
                if ~isfield(S.Specific_Attributes,'INDUSTRY_GROUP') || isempty(S.Specific_Attributes.INDUSTRY_GROUP{1})
                    S.Specific_Attributes.INDUSTRY_GROUP{1} = 'Other';
                end
            end
            
        end % costructor
        
        function Price2Invariants(S, params) % calculating invariants
            % this methods invokes the RetCalc static method to calculate
            % returns based on the parameters provided in params
            % TODO: VERIFY THAT THE RETURN ADJ IN RETCALC WORKS PROPERLY
            % (CHECK RollingDates + 1 ABOVE)
            if S.isFuture == 1 | S.isFuture == 2
                
                utilParams.data1 = S.History.Price.TimeSeries(:,1:2);
                utilParams.data2 = S.History.Price.TimeSeries(:,3:4);
                utilParams.lag = params.lag;
                utilParams.pct = params.pct;
                utilParams.logret = params.logret;
                utilParams.rolldates = S.History.Price.RollingDates;
                utilParams.last_roll = params.last_roll;
                utilParams.EliminateFlag = params.EliminateFlag;
                utilParams.ExtendedLag = params.ExtendedLag;
                U = Utilities(utilParams);
                U.RetCalc;
                CleanRet = U.Output.CleanRet;
                CleanPrices = U.Output.CleanPrices;
                
            elseif S.isFuture == 0
                
                utilParams.data1 = S.History.Price.TimeSeries(:,1:2);
                utilParams.data2 = [];
                utilParams.lag = params.lag;
                utilParams.pct = params.pct;
                utilParams.logret = params.logret;
                utilParams.rolldates = [];
                utilParams.last_roll = params.last_roll;
                utilParams.EliminateFlag = params.EliminateFlag;
                utilParams.ExtendedLag = params.ExtendedLag;
                U = Utilities(utilParams);
                U.RetCalc;
                CleanRet = U.Output.CleanRet;
                CleanPrices = U.Output.CleanPrices;
                
            end
            
            S.Invariants.Name = S.History.Price.Name;
            S.Invariants.Type = ['Returns'];
            S.Invariants.Returns = CleanRet;
            % these are the prices of the assets used to derive
            % invariant, non necessarily the traded assets in the
            % Universe
            S.Invariants.Prices = CleanPrices;
            S.Invariants.External4AtHorizonModeling = false(1);
            
            % Name of the factor that will be ased to search the
            % appropriate series in AllInvariants.NameSet
            S.Risk_Factors_Names.Price = S.History.Price.Name;
        end
        
        function price = Reprice(~,params)
            % params.p0: the initial price
            % params.er: the  expected log return multiplied
            disp('Equity repricing');
            price = params.p0.*exp(params.er);
            
        end % Reprice
        
        function enforceProxy(S, params)
            % params.proxyName: name of the regressor utilized to build the proxy
            % params.proxyPrices: time series with dates in the first column and prices in the second one
            % params.inputParams.params_Equity_ret: params needed to compute invariants
            % This method enforces a proxy integrating it into the
            % available historical timeseries and then recalculating
            % invariants (lof returns)
            
            Proxy = params.proxyParam;
            inputParams = params.inputParams;
            
            % Proxy name
            S.Proxy = Proxy;
            
            % History: Time Series.
            % incorporaating the proxy timeseries while preserving real available data
            [~ , pos]  = setdiff(Proxy.Proxy_Price(:,1),S.Invariants.Prices(:,1)); % Using Prices from Invariants instead of S.History.Price.TimeSeries(:,1)
            newSeries  = [ Proxy.Proxy_Price(pos,:) ; S.Invariants.Prices ];
            [~ , sidx] = sort(newSeries(:,1));
            newSeries  = newSeries(sidx,:);
            
            S.History.Price.TimeSeries = newSeries;
            
            % Update dividend timeseries as well
            % *************************************************************
            % when a proxy has been enforced through the method
            % 'enforceProxy' of class 'equity' the length of the price
            % series becomes higher than the length of the dividends
            % timeseries. In this case we assume zero dividends for the
            % period where we miss them (
            % TODO: it is possible to implement a sort of proxy for
            % dividends as well
            prices_dates = S.History.Price.TimeSeries(:,1);
            for dvd_field={'DvdYldEst','DvdYldInd'}
                dvdSeries = S.History.(dvd_field{1}).TimeSeries;
                dvd_dates = dvdSeries(:,1);
                [missing_dates] = setdiff(prices_dates,dvd_dates,'stable');
                
                [to_remove,ib] = setdiff(dvd_dates,prices_dates,'stable');
                dvd_dates(ib) = [];
                % pay attention here: also need to remove elements of
                % the date whose date is not in the price vector (this
                % can happen in the process of creating a proxy)
                dvdSeries(ib,:)= [];
                matrix2append = [missing_dates,zeros(size(missing_dates,1),1)];
                % pre-append and sort (most probably they are sorted
                % already)
                dvdSeries = [matrix2append;dvdSeries];
                [srt,srt_i] = sort(dvdSeries(:,1));
                S.History.(dvd_field{1}).TimeSeries = [dvdSeries(srt_i,1),dvdSeries(srt_i,2)];
                
            end
            % *************************************************************
            
            % isFuture: Time Series
            S.isFuture = 0;
            
            % Price2Invariants
            % redefined invariants based on proxy
            S.Price2Invariants(inputParams.params_Equity_ret);
            
        end
        
        
    end % methods
    
    methods (Static)
        
    end % static methods
    
end % classdef

