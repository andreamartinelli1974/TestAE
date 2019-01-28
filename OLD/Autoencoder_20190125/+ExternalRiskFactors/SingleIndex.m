classdef SingleIndex < handle
   % this class is used to encapsulate data (timeseries and corresponding invariants)
   % from a single index. Instances
   % of this class are mainly used as an input to the class
   % External_Risk_Factors when a risk factor has to be based on a single
   % index and not (as usually it is the case), on a curve
   
    properties (SetAccess = private)
        Name;
        Prices;
        Invariants;
        RatesFormat;
        isRate;
        RateType;
        Ticker;
        IntExt = []; % Internal/External risk factor
        ToBeIncludedInInvariants = []; % specifying if it has to be included within the AllInvariants matrix of obj of class universe
    end
    
    methods
        function I = SingleIndex(params) % constructor
            % the 'params' input structure contains the following subfields
            % .DataFromBBG: when data has to be downloaded from BBG (at the
            % moment the only option, but in the future the class will be
            % updated to be able to handle external inputs)
            % .ticker: BBG ticker when the data has to be downloaded from
            % BBG
            % .start_dt: first date of the index timeseries
            % .end_dt: end date of the index timeseries
            % .isRate: true(1) when the series represents an interest rate
            % .InputRatesFormat: if .isRate is True(1) then
            % .InputRatesFormat defines the numeric format of the data ('p'
            % for percentage (e.g. 10 for 10%), 'f' for fraction (e.g. 0.02
            % for 2%), 'bps' for basis points (e.g. 100 is 1%)
            % .rate_type:  if .isRate is True(1) it defines the type of
            % rate ('ytm','zero','fixing','forward', etc.)
            % .int_ext: 'External' if the curve has to be included in the
            % External Risk Factors obj of class External_Risk_Factors that
            % will be created within  AA_DashBoard
            
            I.Name = strrep(params.ticker,' ','_');
            I.IntExt = params.int_ext;
            if isfield(params,'ToBeIncludedInInvariants')
                % to avoid exceptions if this input field is not provided
                % (e.g. it is needed for AA purposes, when instances of the
                % the class are used as inputs to objects of class
                % univesr, but it is not needed for FA for example)
                I.ToBeIncludedInInvariants = params.ToBeIncludedInInvariants;
            end
            uparam.DataFromBBG = params.DataFromBBG;
            uparam.ticker = params.ticker;
            uparam.fields = ['LAST_PRICE'];
            uparam.history_start_date = params.start_dt;
            uparam.history_end_date = params.end_dt;
            uparam.granularity = 'DAILY';
            U = Utilities(uparam);
            U.GetHistPrices;
            d1 = U.Output.HistInfo;
            
            % parameters needed to run RetCalc (static method of class
            % 'asset') to calc returns
            retp.lag = 1;
            
            % TODO: the params below are fixed, could be parametrized
            retp.EliminateFlag = 0;
            retp.last_roll = 0;
            retp.ExtendedLag = 3;
            
            if params.isRate
                switch params.InputRatesFormat
                    case 'p'
                        d1(:,2) = d1(:,2) /100;
                    case 'f'    
                        % nothing to do: this is the desired default format
                    case 'bps'
                        d1(:,2) = d1(:,2)/10000;
                    otherwise
                        disp('SingleIndex class: Value not allowed for field .InputRatesFormat');
                        pause;
                        return;
                end
                I.RatesFormat = 'f'; % this is the default
            end
            
            I.Prices = d1;
            
            % type of returns to be computed defined based on isRate: if
            % it's a rate invariants are calculated as differences,
            % otherwise as log returns
            if params.isRate
                retp.pct = 0;
                retp.logret = 0;
            else
                retp.pct = 1;
                retp.logret = 1;
            end
                      
            % invoking method RetCalc of class Utilities for returns
            % calculations
            uparams.data1  = I.Prices(:,1:2);
            uparams.data2  = [];
            uparams.lag = retp.lag;
            uparams.pct = retp.pct;
            uparams.logret = retp.logret;
            uparams.rolldates = [];
            uparams.last_roll = retp.last_roll;
            uparams.EliminateFlag = retp.EliminateFlag;
            uparams.ExtendedLag = retp.ExtendedLag;
            U = Utilities(uparams);
            U.RetCalc;
            CleanRet = U.Output.CleanRet;
            CleanPrices = U.Output.CleanPrices;
            
%             [CleanRet,CleanPrices] = asset.RetCalc(I.Prices(:,1:2),[], ...
%                 retp.lag,retp.pct,retp.logret,[],retp.last_roll, ...
%                 retp.EliminateFlag, retp.ExtendedLag);
            
            I.Ticker = params.ticker;
            I.Prices = CleanPrices; % price series corresponding to return series
            I.Invariants = CleanRet;
            I.RateType = params.rate_type;
            I.isRate = params.isRate; 
                    
        end
    end
    
end

