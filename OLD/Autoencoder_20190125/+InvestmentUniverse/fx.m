classdef fx < InvestmentUniverse.asset
    % definizione sub-class fx (base class is asset)
    % this subclass is also used to model indirect FX exposure due to
    % investments in different asset classes (see property asset.FX_Exposure_derived). 
    % When the exposure is not in EUR??? term (e.g. USDCNY) the asset must be a future and
    % invariants are calculated in the usual way
    
    % TODO: put checks on properties to avoid not allowed combinations of
    % flags IsFuture/isSpot, etc.
    
    properties
    
    end
    
    properties (SetAccess = immutable)
       % proprietà specifiche subclass 'equity'
       Specific_Attributes = [];
       isproxy  = []; 
    end
    
    methods
        % costruttore oggetto 'equity' come subclass di asset 
        function S = fx(asset_params)
            S = S@InvestmentUniverse.asset(asset_params);
            % inputs specific to @fx
            
            % getting Bloomberg static data through an instance
            % of class Utility
            uparam.DataFromBBG = asset_params.DataFromBBG;
            uparam.ticker = asset_params.ticker_BBG;
            uparam.fields = {'TICKER','TICKER_AND_EXCH_CODE'};
            uparam.override_fields = [];
            uparam.override_values = [];
            
            U = Utilities(uparam);
            U.GetBBG_StaticData;
            d = U.Output.BBG_getdata;
            % [d,sec] = getdata(bbgconn,ticker_BBG,{'TICKER','TICKER_AND_EXCH_CODE'});
            
            S.Specific_Attributes.TICKER = d.TICKER;
            S.Specific_Attributes.tickexchcode = d.TICKER_AND_EXCH_CODE;
        end
        
        function Price2Invariants(S, params) % calculating invariants
            % this methods invokes the RewtCalc static method to calculate
            % returns based on the parameters provided in params
            % TODO: VERIFY THAT THE RETURN ADJ IN RETCALC WORKS PROPERLY
            % (CHECK RollingDates + 1 ABOVE)
            if S.isFuture == 1
                
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
            
            % Name of the factor that will be uased to search the
            % appropriate series in AllInvariants.NameSet
            S.Risk_Factors_Names.Price = S.History.Price.Name;
            
        end
        
        function price = Reprice(S,params)
            % params.p0: the initial price
            % params.er: the  annualized expected log return multiplied
            % by time horizon
            disp('FX repricing');
            price = params.p0.*exp(params.er);
            
        end % Reprice
        
    end % methods
    
    
end % classdef


