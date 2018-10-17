classdef External_Risk_Factors < handle
    
    properties
        %RFLastDate = {};
    end
    
    properties (Constant)
    end
    
    properties (SetAccess = immutable)
        params;
    end
    
    properties (SetAccess = protected)
        RF = [];
        RFLastDate = {};
    end
    methods
        function R = External_Risk_Factors(erfParams) % constructor
            % the constractor will simply initialize R.RF (to []). The
            % methods 'addRiskFactors' and 'removeRiskFactors' will be used
            % to add/remove risk factors
           
            % method GetInvariants_EmpiricalDistribution of class Universe
            % will be used to blend these objects into the AllInvariants
            % field
            
            % obj can be a row vector of objects
            disp('Building External Risk Factors Obj');
            R.params = erfParams;
            R.RF = [];
            
            
        end % constructor
        
        function removeRiskFactors(R,invName)
            toBeRemoved = [];
            for k=1:size(R.RF,1)
               if strcmp(R.RF(k).Name,invName) 
                  toBeRemoved = [toBeRemoved;k]; 
               end
            end
            R.RF(toBeRemoved) = [];
        end % removeInvariant
        
        function addRiskFactors(R,obj,obj_names)
            % obj: this is an obj containing hist info on a given risk
            % factor or set of risk factors. E.G. obj of type IR_curve: a
            % field of this obj can be used to implement different
            % constructors: e.g. when there is a field Curve_ID a dataset
            % of historical rates for a curve must be built. The field
            % 'Name' is important as it will be used to choose the
            % appropriate invariants for pricing purposes.
            % obj_names: a cell array comtaining the names of the objects
            % used to build 'this' instance of External_Risk_Factors
            % erfParams: set of parameters. ** IMPORTANT **: here the most
            % important subfield is erfParams.ExternalInvariantsToRemove
            % that contain a list of external invariants that will not be
            % included into the instance of object 'External_Risk_Factors'
            % (when using the parameter ''MinHistDate4Assets' - see class ReadFromIU_inputFile - ) 
            erfParams = R.params;
            no = numel(obj);
            if no==0; return; end
            % for each object, depending on the content of mc.Name, a
            % dataset is built withi9n the field RF: this set will be used
            % within method GetInvariants_EmpiricalDistribution of class
            % Universe to get all data needed
            k = 0;
            
            cnt = numel(R.RF); % if there are risk factors the new ones in obj will be queued
            
            while k < no
                k = k + 1;
                mc = metaclass(obj{k});
               
                if ~strcmp(obj{k}.IntExt,'external')
                    continue; % do not include invariant that are not 'external' as they are 'internal' to specific assets
                end
                if ~isempty(R.RF) && ismember(obj_names{k,1},{R.RF.ObjName})
                    continue; % to avoid repetitions of the same item
                end
                
                cnt = cnt + 1;
                R.RF(cnt,1).ObjName = obj_names{k,1};
                
                if strcmp(mc.Name,'ExternalRiskFactors.IR_Curve') % *** IR_Curve's type constructor
                    
                    R.RF(cnt,1).Invariants.Category = ['IR_Curve'];
                    R.RF(cnt,1).Name = obj{k}.Name;
                    R.RF(cnt,1).Ticker = obj{k}.CurveID;
                    R.RF(cnt,1).Tenors = obj{k}.Curve.tenors;
                    R.RF(cnt,1).Tenors_yf = obj{k}.Curve.tenors_yf;
                    R.RF(cnt,1).RatesFormat = obj{k}.Curve.RatesFormat;
                    R.RF(cnt,1).RatesType  = obj{k}.Curve.RatesType;
                    R.RF(cnt,1).ToBeIncludedInInvariants = obj{k}.ToBeIncludedInInvariants;
                    % ** R.RF(cnt,1).Invariants.Dates = obj{k}.Curve.dates;
                    % ** R.RF(cnt,1).Invariants.Prices = obj{k}.Curve.rates;
                    Type = ['YTM_changes'];
                    R.RF(cnt,1).Invariants.Type = Type;
                    
                    % using RetCalc to compute invariants *****************
                    utilParams.data1 = [obj{k}.Curve.dates,obj{k}.Curve.rates];
                    utilParams.data2 = [];
                    utilParams.lag = erfParams.returnsLag;
                    utilParams.pct = 0;
                    utilParams.logret = 0;
                    utilParams.rolldates = [];
                    utilParams.last_roll = [];
                    utilParams.EliminateFlag = [];
                    utilParams.ExtendedLag = erfParams.ExtendedLag;
                    U = Utilities(utilParams);
                    U.RetCalc;
                    R.RF(cnt,1).Invariants.Dates = U.Output.CleanRet(:,1);
                    R.RF(cnt,1).Invariants.Prices = U.Output.CleanPrices(:,2:end);
                    R.RF(cnt,1).Invariants.(Type) = U.Output.CleanRet(:,2:end);
                    
                    % *****************************************************
                    
                elseif strcmp(mc.Name,'ExternalRiskFactors.CDS_Curve') % *** CDS_Curve's type constructor
                    R.RF(cnt,1).Invariants.Category = ['CDS_Curve'];
                    R.RF(cnt,1).Name = obj{k}.Name;
                    R.RF(cnt,1).Tenors = obj{k}.Curve.tenors';
                    R.RF(cnt,1).Tenors_yf = obj{k}.Curve.tenors_yf;
                    R.RF(cnt,1).RatesFormat = obj{k}.Curve.RatesFormat;
                    R.RF(cnt,1).RatesType  = ['credit_spread'];
                    R.RF(cnt,1).ToBeIncludedInInvariants = obj{k}.ToBeIncludedInInvariants;
                    % ** R.RF(cnt,1).Invariants.Dates = obj{k}.Curve.dates;
                    % ** R.RF(cnt,1).Invariants.Prices = obj{k}.Curve.CDS_interp; % using interpolated values to remove NaN (TODO: refine this)
                    Type = ['CDS_changes'];
                    R.RF(cnt,1).Invariants.Type = Type;
                    % **R.RF(cnt,1).Invariants.(Type) = [zeros(1,size(R.RF(cnt,1).Invariants.Prices,2)); ...
                    % **    diff(R.RF(cnt,1).Invariants.Prices,1)]; % TODO: review when reviewing estimation interval in general
                    % using RetCalc to compute invariants *****************
                    utilParams.data1 = [R.obj{k}.Curve.dates,obj{k}.Curve.CDS_interp];
                    utilParams.data2 = [];
                    utilParams.lag = erfParams.returnsLag;
                    utilParams.pct = 0;
                    utilParams.logret = 0;
                    utilParams.rolldates = [];
                    utilParams.last_roll = [];
                    utilParams.EliminateFlag = [];
                    utilParams.ExtendedLag = erfParams.ExtendedLag;
                    U = Utilities(utilParams);
                    U.RetCalc;
                    R.RF(cnt,1).Invariants.Dates = U.Output.CleanRet(:,1);
                    R.RF(cnt,1).Invariants.Prices = U.Output.CleanPrices(:,2:end);
                    R.RF(cnt,1).Invariants.(Type) = U.Output.CleanRet(:,2:end);
                    % *****************************************************
                    
                elseif strcmp(mc.Name,'ExternalRiskFactors.SingleIndex') % *** Single Indices  type constructor
                    
                    R.RF(cnt,1).Invariants.Category = ['Single_Index'];
                    R.RF(cnt,1).Name = obj{k}.Name;
                    R.RF(cnt,1).ToBeIncludedInInvariants = obj{k}.ToBeIncludedInInvariants;
                    R.RF(cnt,1).Invariants.Dates = obj{k}.Prices(:,1);
                    R.RF(cnt,1).Invariants.Prices = obj{k}.Prices(:,2);
                    if obj{k}.isRate
                        R.RF(cnt,1).RatesFormat = obj{k}.RatesFormat;
                        Type = ['YTM_changes']; % TODO: here I always use 'YTM changes' even if I am dealing with zero rates or may be fwd rates: make this description more accurate
                    else
                        Type = ['Returns'];
                    end
                    R.RF(cnt,1).RatesType  = obj{k}.RateType;
                    R.RF(cnt,1).Invariants.Type = Type;
                    R.RF(cnt,1).Invariants.(Type) = obj{k}.Invariants(:,2);
                    
                elseif strcmp(mc.Name,'ExternalRiskFactors.ImpliedVola_Surface') % *** Volatility type constructor
                    
                    R.RF(cnt,1).Name = obj{k}.Name; % obj{k}.Underlying_Ticker;
                    R.RF(cnt,1).ToBeIncludedInInvariants  = obj{k}.ToBeIncludedInInvariants;
                    
                    if strcmp(obj{k}.DataSource,'MDS') % ************
                        R.RF(cnt,1).Invariants.Category = ['Vol_Curve'];
                        Type = ['Vol_changes'];
                        R.RF(cnt,1).Invariants.Type = Type;
                        % this is for vola surfaces that we get from the Market Data Server
                        
                        R.RF(cnt,1).Invariants.Tenor = obj{k}.Time2Maturity;
                        R.RF(cnt,1).Invariants.Moneyness = obj{k}.Moneyness_Vector_ABSlog;
                        
                        % Below I need to apply RetCalc to 'slices' (horizontal
                        % slices to visualize) of the 'MktImpliedVolas' 3D
                        % matrix, since RetCalc does not manage 3D matrices
                        % parameters that do not change
                        utilParams.data2 = [];
                        utilParams.lag = erfParams.returnsLag;
                        utilParams.pct = 1;
                        utilParams.logret = 1;
                        utilParams.rolldates = [];
                        utilParams.last_roll = [];
                        utilParams.EliminateFlag = [];
                        utilParams.ExtendedLag = erfParams.ExtendedLag;
                        
                        D1 = size(obj{k}.MktImpliedVolas,1);
                        for p=1:D1
                            % slicing the 3D matrix from 'top to bottom'
                            partialMatrix = obj{k}.MktImpliedVolas(p,:,:);
                            partialMatrix = squeeze(partialMatrix);
                            utilParams.data1 = [obj{k}.MktImpliedVolasHistoricalDates(:,1),partialMatrix']; % need to transpose
                            U = Utilities(utilParams);
                            U.RetCalc;
                            if p==1
                                R.RF(cnt,1).Invariants.Dates = U.Output.CleanRet(:,1); % the dates vector is uniquwe, so the 1st time is enough
                            end
                            R.RF(cnt,1).Invariants.Prices(p,:,:) =  U.Output.CleanPrices(:,2:end)'; % need to revert transposition
                            R.RF(cnt,1).Invariants.(Type)(p,:,:) = U.Output.CleanRet(:,2:end)';
                        end
                        
                        % since the RetCalc invoked above might have changed
                        % the dates vector, I need to make sure that the same
                        % changes to it are reflected within the time dimension
                        % of the Tenor and Moneyness matrices
                        [sdiff,sdiff_i] = setdiff(obj{k}.MktImpliedVolasHistoricalDates(:,1),R.RF(cnt,1).Invariants.Dates);
                        R.RF(cnt,1).Invariants.Tenor(:,:,sdiff_i) = [];
                        R.RF(cnt,1).Invariants.Moneyness(:,:,sdiff_i) = [];
                        
                    elseif strcmp(obj{k}.DataSource,'BBG') % ********
                        
                        
                        % this is for vola surfaces for which we do not have
                        % data in out MDS and use ATM Bloomberg data (on
                        % various maturities) to estimate the skew. So in this
                        % case our invariants (what we'll simulate) are the
                        % Bloomberg ATM volas, to which we will then apply the
                        % estimated 'skew function'. The Bloomberg ATM volas
                        % are in the field ImpliedAtmVola_Preprocessed
                        
                        if ~isempty(obj{k}.ImpliedAtmVola_Preprocessed)
                            % these objects are ready to be processed only when
                            % the field 'ImpliedAtmVola_Preprocessed' is not
                            % empty. The field is filled after the investment
                            % universe is created in AA_DashBoard
                            
                            R.RF(cnt,1).Invariants.Category = ['ATM_Vol_Curve'];
                            Type = ['ATM_Vol_changes'];
                            R.RF(cnt,1).Invariants.Type = Type;
                            
                            R.RF(cnt,1).Invariants.Tenor = obj{k}.ImpliedAtmVola_Preprocessed.maturities;
                            
                            % here we have the 'tenors' dimension only,
                            % since all the data refer to ATM implied volas
                            
                            utilParams.data1 = [obj{k}.ImpliedAtmVola_Preprocessed.dates,obj{k}.ImpliedAtmVola_Preprocessed.data];
                            utilParams.data2 = [];
                            utilParams.lag = erfParams.returnsLag;
                            utilParams.pct = 1;
                            utilParams.logret = 1;
                            utilParams.rolldates = [];
                            utilParams.last_roll = [];
                            utilParams.EliminateFlag = [];
                            utilParams.ExtendedLag = erfParams.ExtendedLag;
                            U = Utilities(utilParams);
                            U.RetCalc;
                            
                            R.RF(cnt,1).Invariants.Dates = U.Output.CleanRet(:,1);
                            R.RF(cnt,1).Invariants.Prices = U.Output.CleanPrices(:,2:end);
                            R.RF(cnt,1).Invariants.(Type) = U.Output.CleanRet(:,2:end);
                            
                        else
                            continue;
                        end
                    end
                end % if on mc.Name
                
                % 19.5.17 da Andrea
                date = R.RF(cnt,1).Invariants.Dates;
                firstdate = date(1);
                lastdate = date(end);
                maxdiff = max(diff(date));
                name = R.RF(cnt,1).Name;
                R.RFLastDate(cnt,:) = {name,firstdate,lastdate,maxdiff};
                
            end % k-loop
        end % addRiskFactors
        
    end % methods
    
    methods (Static)
        
    end
end

