classdef bond_ZCB < InvestmentUniverse.asset
     % definizione sub-class bond (base class is asset)
    properties
       % proprietà specifiche subclass 'bond'
        duration
        mod_duration
        maturity
        yield
    end
    
    properties (SetAccess = immutable)
       % proprietà specifiche subclass 'equity'
       Specific_Attributes = [];
       isproxy  = []; 
       isRate = [];
       FixedTtm = []; % fixed time to maturity
       Accrue4ConstantTtmBonds = []; % rate to be used for daily accrual if isRate = 1 and it is a Fixed time 2 mat bond
       MaturityDate = [];
       ReferenceCurve = []
    end
    
    methods
        % costruttore: costruisce B come subclass di asset e ne eredità
        % proprietà e metodi
        function B = bond_ZCB(asset_params, ...
                isRate,FixedTtm,matdate,ref_curve)
            B = B@InvestmentUniverse.asset(asset_params);
            
            % inputs specific to @bond
            % isRate: : 1 if the input timeseries is a rate
            % (usually for a constant time to maturity bond, e.g. GTESP2Y Govt)
            % FixedTtm: struct arry with fields:
            % -> .ttm: this field  contains a number expressed in years it
            % means that the object represents a constant time to maturity bond (e.g. 2 for GTESP2Y Govt), 
            % otherwise this field must be set to [] 
            % -> .accrue: %% NO MORE USED %% if [] nothing happens; if = 'rate' then the same
            % rate used to price the bond is used for daily accruals on the
            % coupon when calculating the bond price (that will impact
            % returns calculations): = a nummber (as a percentage) that is
            % the fixed rate to be used to accrue on a daily basis (e.g. if
            % = 2 it means 2% and 0.02/365 will be ccrued every day)
            % matdate: if FixedTtm == [], this field MUST contain
            % the expiry of the bond, otherwise this field must be set to
            % []
            % ref_curve: if MaturityDate is not [] then a reference to a
            % curve must be provided: this must be in the same format as
            % the field Name in obj of class IR_Curve. This means that for
            % pricing purposes the methods and programs  (e.g. Universe)
            % calling the Reprice method of this class will search the
            % appropriate risk factor (the yield for a given maturity)
            % within the set of External Risk Factors (TODO: REVIEW TO MAKE MORE GENERAL)
            
            % TODO: implement at least a few basic checks on the
            % consistency of the inputs in terms of FixedTtm/MaturityDate/ref_curve
            
            if isempty(B.Synthetic)
                % getting Bloomberg static data through an instance
                % of class Utility
                uparam.DataFromBBG = asset_params.DataFromBBG;
                uparam.ticker = asset_params.ticker_BBG;
                uparam.fields = {'TICKER','TICKER_AND_EXCH_CODE','DUR_MID','DUR_ADJ_MID'};
                uparam.override_fields = [];
                uparam.override_values = [];
                uparam.override_fields = [];
                uparam.override_values = [];

                U = Utilities(uparam);
                U.GetBBG_StaticData;
                d = U.Output.BBG_getdata;
             
                % [d,sec] = getdata(bbgconn,ticker_BBG,{'TICKER','TICKER_AND_EXCH_CODE','DUR_MID','DUR_ADJ_MID'});
                B.Specific_Attributes.tickexchcode = d.TICKER_AND_EXCH_CODE;
                B.Specific_Attributes.DUR_MID = d.DUR_MID;
                B.Specific_Attributes.DUR_ADJ_MID = d.DUR_ADJ_MID;
                B.Specific_Attributes.TICKER = d.TICKER;
            end  
                B.isRate = isRate;
                B.FixedTtm = FixedTtm.ttm;
                B.Accrue4ConstantTtmBonds = FixedTtm.accrue;
                B.MaturityDate = matdate;
                B.ReferenceCurve = ref_curve;
            % when curve data within a set of invariants (see what is done
            % within instances of class Universe) has to be used for
            % repricing
            if ~isempty(ref_curve)
                B.Risk_Factors_Names.YTM = B.ReferenceCurve.Name;
            end
        end
        
        function Price2Invariants(B) % calculating invariants
            % If isRate==1 it means that I am using an annualized
            % rate, so calculating the invariant is very simple and 
            % amounts to calculate the differences in fixed time to
            % maturity yields
            % If isRate==0 then I have a priceseries to be used to extract
            % YTMs.
            % if FixedTtm == [] then there is a MaturityDate and the time
            % to maturity is calculated each day of the historical window
            
            % this method is not invoked when there is a fixed
            % maturity since in this case it is necessary to have a curve
            % (to be found within extrernal invariants). Setup a check to
            % avoid that this method is accessed when the bond is not a
            % constant maturity one.
            if isempty(B.FixedTtm)
                disp('bond_ZCB calss: Price2Invariants method cannot be invoked for ZCB with a fixed maturity date');
                return;
            end
            
            if ~isempty(B.FixedTtm)
                ttm = B.FixedTtm;
            else
                if B.isRate == 1
                    ttm = B.MaturityDate - B.History.YTM.TimeSeries(:,1)
                elseif B.isRate == 0
                    ttm = B.MaturityDate - B.History.Price.TimeSeries(:,1)
                end
            end
                
            if B.isRate == 1
                
                y(:,1) = B.History.YTM.TimeSeries(1:end,1);
                y(:,2) = [0;diff(B.History.YTM.TimeSeries(:,2))]; % this are diff of logarithms already since each zc yield = (1/v)*(-log(Z))
                
                B.Invariants.Name = B.History.YTM.Name;
                B.Invariants.Type = ['YTM_changes'];
                B.Invariants.YTM_changes = y;
                B.Invariants.External4AtHorizonModeling = false(1);
                % these are the prices of the assets used to derive
                % invariant, non necessarily the traded assets in the
                % Universe
                B.Invariants.Prices = [B.History.YTM.TimeSeries(:,1),B.History.YTM.TimeSeries(:,2)];
                
                % Name of the factor that will be uased to search the
                % appropriate series in AllInvariants.NameSet
                B.Risk_Factors_Names.YTM = B.History.YTM.Name;
            
                % in this case I also need to derive the price history,
                % implying it for YTMs
                B.History.Price.TimeSeries(:,1) = B.History.YTM.TimeSeries(:,1);
                B.History.Price.TimeSeries(:,2) = exp(-B.History.YTM.TimeSeries(:,2).*ttm).*100; % TODO: parametrize this '100'
            
            elseif B.isRate == 0
                % in this case invariants (YTMs) must be recovered from prices
                % TODO 
                B.History.YTM.TimeSeries(:,1) = B.History.Price.TimeSeries(:,1);
                B.History.YTM.TimeSeries(:,2) = -log(B.History.Price.TimeSeries(:,1)).*(1./ttm);
            end
        end
        
        function price = Reprice(B,params)
            % params.ytm0 = starting YTM
            % params.er = the  annualized expected (YTM) return change multiplied
            % by time horizon. This can be a single value or a vector as
            % well (a distribution of expected YTM that will yield a distribution of prices)
            
            if B.isRate == 0 & ~isempty(B.FixedTtm)
             
                % in this case the repricing is 'equity style': the
                % timeseries is a price and the time to maturity is
                % constant, so time homogeneity is preserved
                disp('ZCB equity style repricing');
                price = params.p0.*exp(params.er);
                
            else
                disp('ZCB repricing');
                ytm_T  = params.ytm0 + params.er;
                price = exp(-ytm_T.*params.ttm).*100; 
            end
            
        end % Reprice
        
    end % methods
    
end

