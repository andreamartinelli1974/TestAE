classdef Option_Vanilla < InvestmentUniverse.asset
    % definizione sub-class Option_Vanilla (base class is asset)
    % The purpose of this class is to model an option with constant time
    % to expiry (for repricicng at the investment horizon).
    % It will be adapted to several possible underlyings (e.g. 'equity',
    % 'fx', etc.) managed through internal IF statements. The following
    % notes refers to an 'equity' option.
    % Main inputs will be:
    % obj of class 'equity': this will provide the underlying's
    % distribution
    % obj of class bond: this will provide the interest rate component
    % needed for repricing
    % IMPLIED VOLATILITY: this must be an obj of class ImpliedVola_Surface
    
    properties
        IV_field_BBG = []; % BBG field for constant time to expiry vola used to dowload hist implied vola
        IV_history = []; % history og the constant time to expiry ATM implied volatility
        tte_benchmark_yf = []; % time to expiry chosen as benchmark to select the implied vola timeseries in time dimension (the moneyness dim is determined by Moneyness or actual moneyness)
        tte_actual = []; % constant time to maturity used for pricing
        ExpiryDate = [];
        iv_hist = [];
    end
    
    properties (SetAccess = immutable)
        % proprietà specifiche subclass 'equity'
        Specific_Attributes = [];
        isproxy  = [];
        Underlying_Obj = [];
        VolaSurface_obJ = [];
        Curve_Obj = [];
        IVola_start_date = [];
        IVola_end_date = [];
        Moneyness = [];
        time2expiry_OPTIONAL = [];
        FixedExpiryFlag = [];
        ExpiryDate_OPTIONAL = [];
        
    end
    
    
    methods
        % costruttore oggetto 'Option_Vanilla' come subclass di asset
        function O = Option_Vanilla(asset_params, underlying_obj, curve_obj, vola_surface_obj, ...
                iv_start_date, iv_end_date, moneyness, time2expiry_OPTIONAL,FixedExpiryFlag,expiry_date_OPTIONAL)
            O = O@InvestmentUniverse.asset(asset_params);
            % inputs specific to @Option_Vanilla
            % underlying_obj: object representing the underlying (e.g. obj
            % of subclass equity for equity options)
            % curve_obj: obj of class IR_Curve needed to get discountiung measures
            % vola surface obj: obj of class ImpliedVola_Surface to model
            % the skew
            % ref_curve: struct array with 2 fields:
            % iv_start_date, iv_end_date: initial and final dates for
            % implied volatility to be calculated using the method Get_ImpliedVolaInvariant
            % moneyness: defined as 1-Strike/Price for CALLS
            %                       Strike/Price - 1 for PUTS
            %  IF EMPTY the strike price of the option used to build the obj
            % (O.Specific_Attributes.OPT_STRIKE_PX) will be used
            % IMORTANT for AA: when moneyness is not
            % empty ideally it should be assigned a value that reflects the
            % relative position of the strike of the modeled option to
            % the underlying price when the investment universe is
            % built. Then this same moneyness will be used at the investment horizon
            % of all repricing operations over the historical backtest window
            % time2expiry_OPTIONAL: added on Dec 29 2016: if empty the
            % constant time to expiry of the modeled option will be
            % downloaded from Bloomberg (so it will depend on the date when
            % prices are downloaded). IF NOT EMPTY it must contain a time
            % to expiry expressed in year fraction terms, that will be used
            % as the constant time to expiry of the modeled option. This is
            % particularly useful when modeling options in FA Project
            % context, where we weant to model an option having a time 2
            % expiry as of portfolio'date
            % FixedExpiryFlag: if 1 the option has a fixed expiry date and
            % not a constant expiry one
            % expiry_date_OPTIONAL: can be non empty if FixedExpiryFlag =
            % 1. When it is empty the expiry date from Bloomberg is used,
            % otherwise the date assigned to it is used as the expiry date
            
            O.Underlying_Obj = underlying_obj; % reference to the underlying obj
            O.VolaSurface_obJ = vola_surface_obj;
            
            O.Curve_Obj = curve_obj;
            O.Moneyness = moneyness;
            O.time2expiry_OPTIONAL = time2expiry_OPTIONAL;
            O.FixedExpiryFlag = FixedExpiryFlag;
            O.ExpiryDate_OPTIONAL = x2mdate(expiry_date_OPTIONAL);
            
            % getting Bloomberg static data through an instance
            % of class Utility
            uparam.DataFromBBG = asset_params.DataFromBBG;
            uparam.ticker = asset_params.ticker_BBG;
            uparam.fields = {'TICKER','OPT_DIV_YIELD','OPT_STRIKE_PX','DELTA_MID_RT','IVOL_MID_RT','OPT_EXPIRE_DT','OPT_DAYS_EXPIRE', ...
                'OPT_TICK_VAL','OPT_CONT_SIZE','OPT_TICK_SIZE','OPT_PUT_CALL','OPT_UNDL_TICKER','OPT_EXER_TYP'};
            uparam.override_fields = [];
            uparam.override_values = [];
            U = Utilities(uparam);
            U.GetBBG_StaticData;
            d = U.Output.BBG_getdata;
            
            %[d,sec] = getdata(bbgconn,ticker_BBG,{'TICKER','OPT_DIV_YIELD','OPT_STRIKE_PX','DELTA_MID_RT','IVOL_MID_RT','OPT_EXPIRE_DT','OPT_DAYS_EXPIRE', ...
            %   'OPT_TICK_VAL','OPT_CONT_SIZE','OPT_TICK_SIZE','OPT_PUT_CALL','OPT_UNDL_TICKER'});
            O.Specific_Attributes.ticker_BBG = asset_params.ticker_BBG;
            O.Specific_Attributes.OPT_PUT_CALL = d.OPT_PUT_CALL;
            O.Specific_Attributes.TICKER = d.TICKER;
            O.Specific_Attributes.OPT_DIV_YIELD = d.OPT_DIV_YIELD;
            O.Specific_Attributes.OPT_STRIKE_PX = d.OPT_STRIKE_PX;
            O.Specific_Attributes.DELTA_MID_RT = d.DELTA_MID_RT;
            O.Specific_Attributes.IVOL_MID_RT = d.IVOL_MID_RT;
            O.Specific_Attributes.OPT_EXPIRE_DT = d.OPT_EXPIRE_DT;
            O.Specific_Attributes.OPT_DAYS_EXPIRE = d.OPT_DAYS_EXPIRE;
            O.Specific_Attributes.OPT_TICK_VAL = d.OPT_TICK_VAL;
            O.Specific_Attributes.OPT_CONT_SIZE = d.OPT_CONT_SIZE;
            O.Specific_Attributes.OPT_TICK_SIZE = d.OPT_TICK_SIZE;
            O.Specific_Attributes.OPT_UNDL_TICKER = d.OPT_UNDL_TICKER;
            O.Specific_Attributes.OPT_EXER_TYP = d.OPT_EXER_TYP;
            
            % correcting the strike price for options whose price (and
            % strike) is denominated in cents of a given currency (e.g.
            % GBp, USd): this must be done since all underlying prices are
            % always converted into units of currency (GBP, USD, etc), within the class 'asset'.
            % However these corrections shouldn't affect the ImpliedVola_Surface
            % where it searches for availaable strikes. The currency label
            % itself will be corrected later (after historical prices are
            % amended). Here the name of the currency is amended as well.
            % Since both the strike and the underlying are converted in
            % units of currency the price of options originally denominated
            % in cents of currency will be naturally prices in units of
            % currency when the hist price history is built later in this
            % class
            crncy = O.Reference_Info.currency{1};
            input2CurrencyCorrecttion = [111111, O.Specific_Attributes.OPT_STRIKE_PX]; % 111111 is aa fictious date used to be able to invoke Cents2UnitsofCurrency(ts,crncy)
            unitprices = O.Cents2UnitsofCurrency(input2CurrencyCorrecttion,crncy);
            O.Specific_Attributes.OPT_STRIKE_PX = unitprices(2);
            O.Reference_Info.currency{1} = upper(O.Reference_Info.currency{1});
            
            % deriving the 'Yellow Key'
            possible_ykeys{1,1} = ['Equity'];
            possible_ykeys{2,1} = ['Comdty'];
            possible_ykeys{3,1} = ['Index'];
            possible_ykeys{4,1} = ['Curncy'];
            possible_ykeys{5,1} = ['Govt'];
            for k=1:size(possible_ykeys,1)
                f = regexp(O.Specific_Attributes.ticker_BBG,possible_ykeys{k,1},'match');
                if ~isempty(f)
                    O.Specific_Attributes.YELLOW_KEY = f;
                    break
                end
            end
            
            % management of the Fixed Expiry Date / Constant Time to Expiry
            % decision: if it is an option with a fixed, given expiry date
            % then the ExpiryDate property is set here and will never
            % change. Likewise, if it is an option with a constant time to
            % expiry then the tte_actual property is set here and will
            % never change
            if FixedExpiryFlag==1  % ** option with a fixed expiry date
                if isempty(expiry_date_OPTIONAL) % expiry date from Bloomberg
                    O.ExpiryDate = O.Specific_Attributes.OPT_EXPIRE_DT;
                else % expiry date from the user
                    O.ExpiryDate = x2mdate(expiry_date_OPTIONAL);
                end
                
            elseif FixedExpiryFlag==0 % ** option with a constant time to expiry
                if isempty(O.time2expiry_OPTIONAL)             
                    O.tte_actual = O.Specific_Attributes.OPT_DAYS_EXPIRE./365;
                else
                    O.tte_actual = O.time2expiry_OPTIONAL;
                end
                
            end
            
            % assigning invariants for the object: this is a plain vanilla
            % option. I need 3 invariants:
            % 1) underlying's invariants
            % 2) interest rate for discounting
            % 3) implied volatility: through method
            % Get_ImpliedVolaInvariant_NEW, invoked within method
            % GetImpliedHistory (see below)
            
            % the following FOR is to inherit from the underlying objects
            % all the attributes of the 'Invariants' property
            fldnames = fieldnames(underlying_obj.Invariants);
            for k=1:numel(fldnames)
                O.Invariants(1).(fldnames{k}) = underlying_obj.Invariants.(fldnames{k});
                % Name of the factor that will be used to search the
                % appropriate series in AllInvariants.NameSet
                O.Risk_Factors_Names.Price = underlying_obj.Risk_Factors_Names.Price;
            end
            O.Invariants(1).External4AtHorizonModeling = false(1);
            
            % rates invariants (for discounting)
            % here I use interpolated zero YTM, that will be used to derive
            % the corresponding discount factor
            
            tte_string = strrep(num2str(O.tte_benchmark_yf),'.','_');
            O.Risk_Factors_Names.YTM = curve_obj.Name; %[curve_obj.Name,'_discount_ZYTM_maturity_',tte_string];
            O.Invariants(2).Name = O.Risk_Factors_Names.YTM;
            O.Invariants(2).Type = ['YTM_changes'];
            O.Invariants(2).External4AtHorizonModeling = true(1);
            
            O.Invariants(2).Prices(:,1) = O.Curve_Obj.Curve.dates;
            O.Invariants(2).Prices =[O.Invariants(2).Prices  O.Curve_Obj.Curve.rates ];
            O.Invariants(2).YTM_changes(:,1) =  O.Curve_Obj.Curve.dates ;
            [x,y] = size(O.Invariants(2).Prices(:,2:end));
            O.Invariants(2).YTM_changes = [zeros(1,y);diff(O.Invariants(2).Prices(:,2:end))];
            O.Invariants(2).YTM_changes = [O.Curve_Obj.Curve.dates  O.Invariants(2).YTM_changes];
            
        end % constructor
        
        function Get_ImpliedVolaInvariant_NEW(O,iv_hist) % calculating invariants
            % Volatility update
            
            O.IV_history.TimeSeries = iv_hist;
            
            % defining the history of the invariant 'implied vola'
            O.Invariants(3).ImpliedVola(:,1) = O.IV_history.TimeSeries(:,1);
            log_iv = log(O.IV_history.TimeSeries(:,2));
            O.Invariants(3).ImpliedVola(:,2) = [0;diff(log_iv)];
            O.Invariants(3).Prices = O.IV_history.TimeSeries;
            
            O.Invariants(3).Name = O.VolaSurface_obJ.Name;
            O.Invariants(3).Type = ['ImpliedVola'];
            O.Invariants(3).External4AtHorizonModeling = true(1);
            
            % Name of the factor that will be used to search the
            % appropriate series in AllInvariants.NameSet for "At Hoprizon"
            % pricing
            O.Risk_Factors_Names.ImpliedVola = O.VolaSurface_obJ.Name;
            
        end % Get_ImpliedVolaInvariant
        
        
        function GetImpliedHistory(O)
            % this method uses the Reprice method and other info made
            % available by the constructor to imply a theoretical price history
            % correspondent to the available price hist for the underlying
            disp('Implied Price history calcs');
            
            und_ts = O.Underlying_Obj.History.Price.TimeSeries; % underlying
            % use the highest between 'DvdYldInd' and 'DvdYldEst'
            % (reminder: when Bloomberg returns NaNs for dividends, they
            % are replaced with 0)
            dvdYield_ts = [O.Underlying_Obj.History.Price.TimeSeries(:,1), ...
                max([O.Underlying_Obj.History.DvdYldInd.TimeSeries(:,2),O.Underlying_Obj.History.DvdYldEst.TimeSeries(:,2)],[],2)];
            
            for t=1:size(O.Curve_Obj.Curve.dates ,1)
                if O.FixedExpiryFlag == 0 % NO FIXED EXPIRY MEANS FIXED TAU
                    tmp1 = O.tte_actual;
                    tmp2 = 0; % means Do not decrease time
                else  % FIXED EXPIRY MEANS TAU GETS SMALLER by t.
                    if isempty(O.ExpiryDate)==1
                        tmp1 = O.tte_actual;
                        tmp2 = 1; % means decrease time from tte.actual
                    elseif isempty(O.ExpiryDate_OPTIONAL)==1
                        tmp1 =  (O.ExpiryDate - datenum(O.Underlying_Obj.History.Price.TimeSeries(1,1)))/365;
                        tmp2 = 1; % means decrease time from tte.ExpiryDate.
                    else
                        tmp1 =  ((O.ExpiryDate) -datenum(O.Underlying_Obj.History.Price.TimeSeries(1,1)))/365;
                        tmp2 = 1; % means decrease time from tte.ExpiryDate.
                    end
                end
                tau_update(t,1) = max( tmp1 - t/365 * tmp2, 0 );
                dt = O.Curve_Obj.Curve.dates(t) ; % Lookup Date.
                df_ts(t,1) = dt;
                import InvestmentUniverse.*;
                df_ts(t,2) = universe.CurveInterp(O.Curve_Obj.Curve,dt,tau_update(t,1),'rates',5);
            end
            
            % using Utilities.GetCommonDataSet to get a dataset on a common
            % set of dates.
            uparams.inputTS{1,1} = und_ts;
            uparams.inputTS{2,1} = df_ts;
            uparams.inputTS{3,1} = dvdYield_ts;
            uparams.op_type = 'intersect';
            U = Utilities(uparams);
            U.GetCommonDataSet;
            
            Mmat.ts = U.Output.DataSet.data;
            Mmat.dates = U.Output.DataSet.dates;
            
            
            %% Need to get the appropriate implied vola for pricing
            cnt = 0; % counting days where we do have a price for volatility
            for t=1:size(Mmat.dates ,1)
                % iv_ts needs to be defined in here for every t in
                % dates.
                dt = Mmat.dates(t,1);
                % Strike needs to be redefined again.
                
                if isempty(O.Moneyness)
                    Strike(t) = O.Specific_Attributes.OPT_STRIKE_PX;
                    if strcmp(O.Specific_Attributes.OPT_PUT_CALL,'Call')   % Moneyness calculations
                        Moneyness = 1 - Strike(t)/Mmat.ts(t,1);
                    elseif strcmp(O.Specific_Attributes.OPT_PUT_CALL,'Put')
                        Moneyness = -(1 - Strike(t)/Mmat.ts(t,1));
                    end
                else
                    if strcmp(O.Specific_Attributes.OPT_PUT_CALL,'Call')
                        Moneyness = O.Moneyness;
                        Strike(t) = Mmat.ts(t,1).*(1 - O.Moneyness);
                    elseif strcmp(O.Specific_Attributes.OPT_PUT_CALL,'Put')
                        Moneyness = O.Moneyness;
                        Strike(t) = Mmat.ts(t,1).*(1 + O.Moneyness);
                    end
                end
                
                if strcmp(O.VolaSurface_obJ.DataSource,'BBG')  % **********
                    % if the datasource for implied vola data is BBG (and not
                    % MDS), then it is necessary to invoke the method
                    % EstimateHistoricalSurface of class ImpliedVola_Surface.m,
                    % to estimate the implied vola to be used for pricing
                    % (added by GP on 29/8/2017)
                    histEstimWindow.start = U.Output.DataSet.dates(1);
                    histEstimWindow.end = U.Output.DataSet.dates(end);
                    
                    %                     [impliedVola] = ...
                    %                         O.VolaSurface_obJ.EstimateHistoricalSurface(O.DataFromBBG,histEstimWindow,O.Invariants(1).Returns(:,1), ...
                    %                         O.Invariants(1).Returns(:,2),tau_update(t),Strike(t),Mmat.ts(t,1),dt,false(1),[]);
                    
                    [impliedVola] = O.VolaSurface_obJ.EstimateHistoricalSurface(tau_update(t),Strike(t),Mmat.ts(t,1),dt,false(1),[]);
                    
                    if ~isempty(impliedVola)
                        cnt = cnt + 1;
                        iv_ts(cnt,1) = dt;
                        iv_ts(cnt,2) = impliedVola;
                    
                    end
                elseif strcmp(O.VolaSurface_obJ.DataSource,'MDS') % *******
                    % Volatility needs to be interpolated here.
                    
                    % dt = O.Curve_Obj.Curve.dates(t): incorrect: the date must
                    % be searched within Mmat.dates
                    
                    % Here, like it has been done above when retireving
                    % unerlying prices and df, we want to use available data
                    % only (after the current for we will intersect again on
                    % dates). We will manage in a centralized way possible big
                    % holes in the impliev vola data if this is useful
                    
                    % Lookup Date.
                    idx = find(O.VolaSurface_obJ.MktImpliedVolasHistoricalDates == dt);
                    if isempty(idx)
                        continue % skip
                    end
                    cnt = cnt + 1;
                    
                    X1 = O.VolaSurface_obJ.Time2Maturity(:,:,1); % Ttm Vector coordinates
                    X2 =  O.VolaSurface_obJ.Moneyness_Vector_ABSlog(:,:,1); % Moneyness Vector coordinates
                    V = O.VolaSurface_obJ.MktImpliedVolas(:,:,idx);
                    Xq1 = min(tau_update(t),O.VolaSurface_obJ.Time2Maturity(end,1,1));
                    Xq2 = min(max(Moneyness,O.VolaSurface_obJ.Moneyness_Vector_ABSlog(1,1,1)),O.VolaSurface_obJ.Moneyness_Vector_ABSlog(1,end,1));
                    iv_ts(cnt,1) = dt;
                    iv_ts(cnt,2) = interpn(X1,X2,V,Xq1,Xq2,'spline'); % Only spline for extrapolation
                end % whether BBG or MDS vola
            end % loop over the range of historical dates
            
            O.Get_ImpliedVolaInvariant_NEW(iv_ts);
            
            uparams.inputTS{1,1} = [Mmat.dates,Mmat.ts];
            uparams.inputTS{2,1} = iv_ts;
            uparams.op_type = 'intersect';
            U = Utilities(uparams);
            U.GetCommonDataSet;
            
            Mmat.ts = U.Output.DataSet.data;
            Mmat.dates = U.Output.DataSet.dates;
            
            %% Options calculation can be continued.
            params.underlying = Mmat.ts(:,1);
            
            params.yield = [Mmat.ts(:,3)]; % annualised pct dividend yield
            params.iv_t_raw = [Mmat.ts(:,1),Mmat.ts(:,4)]; % implied volatility
            params.ytm_T = max(0.000001,Mmat.ts(:,2)); % TODO: Matlab built in function does not allow negative rates
            params.reprice_vola_flag = 0;
            params.dates = Mmat.dates;
            
            opt_price = O.Reprice(params);
            ts = [Mmat.dates,opt_price];
            
            O.History.Price.TimeSeries(:,1) = ts(:,1);
            O.History.Price.TimeSeries(:,2) = ts(:,2);
            O.History.Price.Name = strrep(O.Specific_Attributes.ticker_BBG,' ','_');
            O.History.Price.Notes = 'Implied Price History for the option';
            
            
        end % GetImpliedHistory
        
        function opt_price = Reprice(O,params)
            import InvestmentUniverse.*;
            
            disp('Option repricing');
            % params.p0: the option's initial price (NOT NEEDED for now)
            % params.underlying: the price of the underlying
            % params.reprice_vola_flag: if 1 the vola at horizon must be
            % repriced: in this case the following 2 inputs are needed
            % 1) params.iv0_table: initial implied vola prices
            % 2) params.iv0_table_names: names associated to the various
            % volatilities in params.iv0_table. Needed to manage implaied
            % volatility when performing "At Horizon" pricing
            % 3) params.iv0_table_expret: annualized and projected to horizon
            %    expected return for the implied volatilities
            % These inputs will be used to derive iv_t_raw
            % params
            % if params.reprice_vola_flag == 0, instead:
            % params.iv_t_raw must be provided and this value will be used
            % for historical repricing. Must be a matrix made of 2 columns
            % vector: dates and data
            % 4) params.ytm_T and params.df: annualized and interpolated
            % (if needed) zero yield and associated discount factor that
            % will be used to discount the final payoff
            % 5) params.dates: date to which the repricing refers to
            % (needed to compute time to maturity tau)
            % 6) params.yield: the pct annualised dividend yield (when
            % available, otherwise it is 0)
            if params.reprice_vola_flag == 1 % "At Horizon" Repricing
                % Price
                Price = params.underlying; % price of the underlying at the repricing date
                nPrices = size(Price,1);
                
                % Strike
                if isempty(O.Moneyness)
                    Strike = O.Specific_Attributes.OPT_STRIKE_PX.*ones(nPrices,1); % I want a vector even when Strike is a single value
                else
                    if strcmp(O.Specific_Attributes.OPT_PUT_CALL,'Call')
                        Strike = Price.*(1 - O.Moneyness);
                    elseif strcmp(O.Specific_Attributes.OPT_PUT_CALL,'Put')
                        Strike = Price.*(1 + O.Moneyness);
                    end
                end
                
                % Retrieve Moneyness for later interpolation.
                if strcmp(O.Specific_Attributes.OPT_PUT_CALL,'Call')   % Moneyness calculations
                    Moneyness = 1 - Strike./Price;
                elseif strcmp(O.Specific_Attributes.OPT_PUT_CALL,'Put')
                    Moneyness = -(1 - Strike./Price);
                end
                
                Tau = params.tte; % generated within universe.HRepricing
                
                %                 % TtM to intepolate from vol tables.
                %                 if O.FixedExpiryFlag == 1
                %                     if isempty(O.ExpiryDate_OPTIONAL) == 1
                %                         Tau = max((O.ExpiryDate-params.dates)/365 ,0);
                %                     else
                %                         Tau = max((O.ExpiryDate_OPTIONAL-params.dates)/365 ,0);
                %                     end
                %                 else
                %                     Tau = O.tte_actual;  % I think this needs to be updated@
                %                 end
                
                % if time to expiry is zero skip the remaining part of code
                % and calculate the option's final payoff
                if Tau<=0
                    if strcmp(O.Specific_Attributes.OPT_PUT_CALL,'Call')
                        opt_price = max(0,Price-Strike);
                    elseif strcmp(O.Specific_Attributes.OPT_PUT_CALL,'Put')
                        opt_price = max(0,Strike - Price);
                    end
                    return;
                end
                
                if strcmp(O.VolaSurface_obJ.DataSource,'MDS') % **********
                    % when the source of vola data is MDS we have the whole
                    % simulated surface with both moneyness and time to
                    % maturity dimensions
                    
                    % Recreate Volatility tables to interpolate
                    % params.iv0_table_names
                    % params.iv0_table % Initial Volatility
                    % params.iv0_table_expret % To be used to recreate volatilities based on scenarios
                    underscores = strfind(params.iv0_table_names,'_');
                    for cvol = 1:length(underscores)
                        TABLE.Expiry{cvol} = strrep(params.iv0_table_names{cvol}(underscores{cvol}(2)+1:underscores{cvol}(3)-2),'dot','.');
                        TABLE.Moneyness{cvol} = strrep(strrep(params.iv0_table_names{cvol}(underscores{cvol}(3)+1:end-1),'dot','.'),'m','-');
                    end
                    
                    % Pass str2num in cell array
                    TABLE.Expiry = cellfun(@(x) str2double(x),TABLE.Expiry);
                    TABLE.Moneyness = cellfun(@(x) str2double(x),TABLE.Moneyness);
                    
                    x = TABLE.Expiry;
                    y = TABLE.Moneyness;
                    
                    % Create the volatility scenarios
                    % params.iv0.*exp(params.iv0_expret)
                    [sx,sy] = size(params.iv0_table_expret);
                    v = repmat(params.iv0_table,sx,1).*exp(params.iv0_table_expret);
                    
                    % Interpolate
                    % Now that the projected volatility tables have been rebuilt do the
                    % interpolation of scatttered data.
                    xq = max(min(Tau,max(x)),min(x)); % Putting caps and floors on interpolants
                    yq = max(min(Moneyness,max(y)),min(y));
                    iv_t_raw = zeros(sx,1); % Preallocating space
                    for vollength = 1 : sx
                        % iv_t_raw(vollength,1) = griddata(x,y,v(vollength,:),xq,yq(vollength),'linear');
                        F = scatteredInterpolant(x',y',v(vollength,:)','linear');
                        iv_t_raw(vollength,1) = F(xq,yq(vollength));
                    end
                    
                elseif strcmp(O.VolaSurface_obJ.DataSource,'BBG') % *******
                    % when the source of vola data is Bloomberg we have
                    % simulated ATM volas only, related to a set of
                    % maturities. In this case we need to estimate the
                    % skew, similarly to what has been done for historical
                    % pricing in the 'BBG' case within the method
                    % 'GetImpliedHistory' above
                    simVolaAtHorizon = params.iv0_table.*exp(params.iv0_table_expret);
                    %                     [iv_t_raw] = ...
                    %                         O.VolaSurface_obJ.EstimateHistoricalSurface(O.DataFromBBG,[],[], ...
                    %                         [],Tau,Strike,Price,[],true(1),simVolaAtHorizon);
                    [iv_t_raw] = ...
                        O.VolaSurface_obJ.EstimateHistoricalSurface(Tau,Strike,Price,[],true(1),simVolaAtHorizon);
                    
                end
                
                % ************************************************************
            elseif params.reprice_vola_flag == 0 % Historical Repricing
                % ************************************************************
                
                iv_t_raw = params.iv_t_raw;
                
                Price = params.underlying; % price of the underlying at the repricing date
                nPrices = size(Price,1);
                
                if O.FixedExpiryFlag == 0
                    Tau = O.tte_actual;
                else
                    if isempty(O.ExpiryDate)==1
                        Tau = max(O.tte_actual - [1:length(Price)]/365 ,0)';
                    else
                        if isempty(O.ExpiryDate_OPTIONAL) == 1
                            Tau = max((O.ExpiryDate-params.dates(1:end,1))/365 ,0);
                        else
                            Tau = max((O.ExpiryDate_OPTIONAL-params.dates(1:end,1))/365 ,0);
                        end
                    end
                    
                end
                
                if isempty(O.Moneyness)
                    Strike = O.Specific_Attributes.OPT_STRIKE_PX.*ones(nPrices,1); % I want a vector even when Strike is a single value
                    
                    if strcmp(O.Specific_Attributes.OPT_PUT_CALL,'Call')   % Moneyness calculations
                        Moneyness = 1 - Strike./Price;
                    elseif strcmp(O.Specific_Attributes.OPT_PUT_CALL,'Put')
                        Moneyness = -(1 - Strike./Price);
                    end
                else
                    Moneyness = O.Moneyness;
                    if strcmp(O.Specific_Attributes.OPT_PUT_CALL,'Call')
                        Strike = Price.*(1 - O.Moneyness);
                    elseif strcmp(O.Specific_Attributes.OPT_PUT_CALL,'Put')
                        Strike = Price.*(1 + O.Moneyness);
                    end
                end
            end % reprice_vola_flag == 1
            
            % *********************
            if params.reprice_vola_flag == 1
                iv_t = iv_t_raw; % At Horizon pricing
            elseif params.reprice_vola_flag == 0
                iv_t = iv_t_raw(:,2); % historical pricing
            end
            
            
            Yield = params.yield;
            iv_t(iv_t<=0) = 0.05;
            Rate = max(params.ytm_T,0.000001); % 0.01; % hard coded for now; TODO: FIX THIS
            
            if strcmp(O.Specific_Attributes.OPT_EXER_TYP,'European') % & (Rate - Yield) > 0 % for stock Yield cannot be negative (used <= in case we extend the pricing to commodities' options)
                % if the cost of carry is not less than the risk free rate
                % the American call will never be exercised early
                
                % note on payoff discounting: managed by blsprice when rates
                % are > 0, otherwise it is managed outside through P_correct,
                % since the built-in Matlab function does not handle negative
                % rates. APPLIED TO EUROPEAN OPTION ONLY, where the
                % built-in pricing function is used
                
                P_correct = exp(-params.ytm_T .* Tau.*(params.ytm_T<0));
                
                if strcmp(O.Specific_Attributes.OPT_PUT_CALL,'Call')
                    [opt_price, ~] = blsprice(Price, Strike, Rate, Tau, iv_t, Yield./100);
                elseif strcmp(O.Specific_Attributes.OPT_PUT_CALL,'Put')
                    [~, opt_price] = blsprice(Price, Strike, Rate, Tau, iv_t, Yield./100);
                end
                
                opt_price = opt_price .*P_correct;
                
            elseif strcmp(O.Specific_Attributes.OPT_EXER_TYP,'American')
                
                batch_size = size(Price,1); % 500; % set this = to size(Price,1) to use no batches, otheriwse set to a no < size(Price,1);
                total_batches = floor(length(Price)/batch_size);
                
                if strcmp(O.Specific_Attributes.OPT_PUT_CALL,'Call')
                    CP = {'C'};
                elseif strcmp(O.Specific_Attributes.OPT_PUT_CALL,'Put')
                    CP = {'P'};
                end
                
                carry = Rate - Yield./100;
                
                % Vectorized version below
                %for batch = 1 : total_batches
                opt_price = zeros(size(Price,1),1);
                batch = 0;
                leftovers = 0;
                while batch <= total_batches  | leftovers > 0
                    
                    batch = batch + 1;
                    
                    if batch > total_batches
                        cbatch_s = cbatch_e;
                        cbatch_e = cbatch_e + leftovers;
                    elseif batch <= total_batches
                        cbatch_s = batch_size * (batch - 1) + 1;
                        cbatch_e = batch_size * batch;
                    end
                    
                    if length(Tau) > 1
                        Tau_tmp = Option_Vanilla.getSubset(Tau,cbatch_s,cbatch_e);
                    else
                        Tau_tmp = Tau;
                    end
                    % Importing "InvestmentUniverse" package needed to call:
                    % universe.m
                    import InvestmentUniverse.*;
                    C = Option_Vanilla.getSubset(carry,cbatch_s,cbatch_e);
                    R = Option_Vanilla.getSubset(Rate,cbatch_s,cbatch_e);
                    Y = Option_Vanilla.getSubset(Yield ./100,cbatch_s,cbatch_e);
                    IV = Option_Vanilla.getSubset(iv_t ,cbatch_s,cbatch_e);
                    P = Option_Vanilla.getSubset(Price,cbatch_s,cbatch_e);
                    STK = Option_Vanilla.getSubset(Strike,cbatch_s,cbatch_e);
                    
                    
                    if strcmp(CP,'C')
                        
                        % use 'American Opt' pricer only if cost of carry is is
                        % higher than the r.f.r.
                        fAmerican = find(C < R);
                        fEuropean = find(C >= R);
                        
                        if ~isempty(fAmerican)
                            Pa = Option_Vanilla.getSubset(P,fAmerican);
                            STKa = Option_Vanilla.getSubset(STK,fAmerican);
                            Ra = Option_Vanilla.getSubset(R,fAmerican);
                            Ya = Option_Vanilla.getSubset(Y,fAmerican);
                            IVa = Option_Vanilla.getSubset(IV,fAmerican);
                            Tau_tmpa = Option_Vanilla.getSubset(Tau_tmp,fAmerican);
                            
                            [~, ~, tmpO] = Option_Vanilla.AmOptionPricer_v3(Pa,STKa , ...
                                Ra,Ya,IVa, Tau_tmpa,CP);
                            opt_price(cbatch_s+fAmerican-1,1) = tmpO;
                        end
                        
                        if ~isempty(fEuropean)
                            Pe = Option_Vanilla.getSubset(P,fEuropean);
                            STKe = Option_Vanilla.getSubset(STK,fEuropean);
                            Re = Option_Vanilla.getSubset(R,fEuropean);
                            Ye = Option_Vanilla.getSubset(Y,fEuropean);
                            IVe = Option_Vanilla.getSubset(IV,fEuropean);
                            Tau_tmpe = Option_Vanilla.getSubset(Tau_tmp,fEuropean);
                            
                            [tmpO, ~] = blsprice(Pe, STKe, Re, Tau_tmpe, IVe, Ye);
                            opt_price(cbatch_s+fEuropean-1,1) = tmpO;
                        end
                        
                    elseif strcmp(CP,'P')
                        % puts always priced using  the 'American pricer'
                        fAmerican = [1:1:numel(C)]';
                        
                        if ~isempty(fAmerican)
                            Pa = Option_Vanilla.getSubset(P,fAmerican);
                            STKa = Option_Vanilla.getSubset(STK,fAmerican);
                            Ra = Option_Vanilla.getSubset(R,fAmerican);
                            Ya = Option_Vanilla.getSubset(Y,fAmerican);
                            IVa = Option_Vanilla.getSubset(IV,fAmerican);
                            Tau_tmpa = Option_Vanilla.getSubset(Tau_tmp,fAmerican);
                            [~, ~, tmpO] = Option_Vanilla.AmOptionPricer_v3(Pa,STKa , ...
                                Ra,Ya,IVa, Tau_tmpa,CP);
                            opt_price(cbatch_s+fAmerican-1,1) = tmpO;
                            
                        end
                        
                        
                    end % if (American) call/put
                    
                    leftovers = max(length(Price) - batch * batch_size, 0);  % the max operator is not needed normally since length(S) >= total_batches * batch_size.
                    
                end % while batch
                
            end % IF American/European
            
            
            % FLOORING PRICE WHEN DOING HISTORICAL PRICING
            % when the option is close to expiry and deep out of the money,
            % it is possible that the estimates historical price is too low
            % (something of the order of 10e-18 for example). This can
            % translate into unrealistically high returns when the
            % estimated hist price is used as a denominator when
            % calculating projected returns. It can also cause problems in
            % the backtesting stage. This is why below the historcal option
            % price is floored based on the value of the d1 term (in B&S
            % formula), that is the point where the std norm CDF is
            % evaluated. If d1 is < -floor_nStd (e.g. floor_nStd=3 means a
            % very unlikely outcome) then the opt price is floored)
            floor_nStd = 3;
            floorPct = 0.001; % 0.1% of the underlying price. TODO: can be made better
            if params.reprice_vola_flag == 0 % when performing historical (not At Horizon repricing)
                % need to make Moneyness a vector for the algorithm that
                % follow to work properly. Moneyness is a number when
                % dealing with constant moneyness options
                moneyness_vector = Moneyness;
                if numel(moneyness_vector)==1
                    moneyness_vector = moneyness_vector.*ones(size(opt_price,1),1);
                end
                if numel(Yield)==1
                    Yield = Yield.*ones(size(opt_price,1),1);
                end
                if numel(Tau)==1
                    Tau = Tau.*ones(size(opt_price,1),1);
                end
                if numel(Strike)==1
                    Strike = Strike.*ones(size(opt_price,1),1);
                end
                if numel(Rate)==1
                    Rate = Rate.*ones(size(opt_price,1),1);
                end
                
                % ** ff = find((1./moneyness_vector).*Tau > -0.25 & moneyness_vector<0); %      TODO: can be made better
                d1=(log(Price./Strike) + Tau.*(Rate - Yield./100 + (iv_t.^2)/2))./(iv_t.*sqrt(Tau));
                
                if strcmp(O.Specific_Attributes.OPT_PUT_CALL,'Call')
                    % do nothing
                elseif strcmp(O.Specific_Attributes.OPT_PUT_CALL,'Put')
                    d1 = d1*(-1);
                end
                
                ff = find(d1<-floor_nStd);
                
                if ~isempty(ff)
                    opt_price(ff) = Price(ff)*floorPct;
                end
                
            end % if on reprice_vola_flag
            
            
        end % reprice
        
    end % methods
    
    methods (Static = true)
        
        function [Sx, EuroPrice, AmerPrice] = AmOptionPricer_v3(S,K,r,q,v,T,PutCall)
            % global BSCall BSPut
            % Barone-Adesi and Whaley quadratic approximation for American vanilla options
            % Finds the American prices as the European prices + premium
            % Premium is based on Sx, the critical stock price above or below
            % which it becomes optimal to exercise the American options
            % S = Spot price
            % K = Strike price
            % r = Risk free rate
            % q = Dividend yield
            % v = Volatility
            % T = Maturity
            % PutCall = 'C'all or 'P'ut
            
            import InvestmentUniverse.*;
            
            % Anonymous functions for Black Scholes call and put
            BSCall = @(s,K,r,q,v,T) s.*exp(-q.*T).*normcdf((log(s./K) + (r-q+v.^2./2).*T)./v./sqrt(T)) - K.*exp(-r.*T).*normcdf((log(s./K) + (r-q+v.^2./2).*T)./v./sqrt(T) - v.*sqrt(T));
            BSPut  = @(s,K,r,q,v,T) K.*exp(-r.*T).*normcdf(-(log(s./K) + (r-q+v.^2./2).*T)./v./sqrt(T) + v.*sqrt(T)) - s.*exp(-q.*T).*normcdf(-(log(s./K) + (r-q+v.^2./2).*T)./v./sqrt(T));
            % options = optimset('MaxFunEvals',1000,'MaxIter',1000);
            S_length = length(S);
            % Quadratic approximation
            switch PutCall{1}	case 'C'
                EuroPrice = BSCall(S,K,r,q,v,T);
                % Importing "InvestmentUniverse" package needed to call:
                % universe.m
                import InvestmentUniverse.*;
                Sx = Option_Vanilla.newton_American(K,r,q,v,T,PutCall,BSCall,BSPut,S);
              
                d1 = (log(Sx./K) + (r-q+v.^2/2))./v./sqrt(T); 
                n = 2*(r-q)./v.^2;   
                k = (2*r./(v.^2))./(1-exp(-r.*T));  
                q2 = (1-n+sqrt((n-1).^2+4*k))./2; 
                A2 = Sx.*(1-exp(-q.*T).*normcdf(d1))./q2;  % note: goes to zero for T very small      
                
                AmerPrice = zeros(S_length,1); % initialize vector.
                for i =1:S_length
                    if S(i) < Sx(i)
                        AmerPrice(i) = EuroPrice(i) + A2(i)*(S(i)/Sx(i))^q2(i); % american option price as: European opt price + early exercise premium
                    else
                        AmerPrice(i) = S(i) - K(i);
                    end
                    
                end
                
                
                case 'P'
                    EuroPrice = BSPut(S,K,r,q,v,T);
                    
                    Sx = Option_Vanilla.newton_American(K,r,q,v,T,PutCall,BSCall,BSPut,S);
                    
                    d1 = (log(Sx./K) + (r-q+v.^2/2))./v./sqrt(T);    
                    n = 2*(r-q)./v.^2;       
                    k = (2*r./(v.^2))./(1-exp(-r.*T));
                    q1 = (1-n-sqrt((n-1).^2+4*k))/2;           
                    A1 = -Sx.*(1-exp(-q.*T).*normcdf(-d1))./q1; % note: goes to zero for T very small      
                    
                    AmerPrice = zeros(S_length,1); % initialize vector.
                    for i =1:S_length
                        if S(i)>Sx(i)
                            AmerPrice(i) = EuroPrice(i) + A1(i)*(S(i)/Sx(i))^q1(i); % american option price as: European opt price + early exercise premium
                        else
                            AmerPrice(i) = K(i) - S(i);
                        end
                    end
            end % put/call switch
            
        end % AmOptionPricer_v3
        
        
        function [Si] = newton_American(X,r,q,sigma,time,CP,BSCall,BSPut,StockPrice)
            % Newton Raphson for Barone-Adesi: Newton's iteration algo used
            % to solve for the 'equilibrium price'
%             BSCall = @(s,K,r,q,v,T) s.*exp(-q.*T).*normcdf((log(s./K) + (r-q+v.^2./2).*T)./v./sqrt(T)) - K.*exp(-r.*T).*normcdf((log(s./K) + (r-q+v.^2./2).*T)./v./sqrt(T) - v.*sqrt(T));
%             BSPut  = @(s,K,r,q,v,T) K.*exp(-r.*T).*normcdf(-(log(s./K) + (r-q+v.^2./2).*T)./v./sqrt(T) + v.*sqrt(T)) - s.*exp(-q.*T).*normcdf(-(log(s./K) + (r-q+v.^2./2).*T)./v./sqrt(T));
            
            ACCURACY=1.0e-6;
            max_iter = 1000;
            no_iterations=0; % iterate on S to find S_star, using Newton steps
            error = 1; % To enter while.
            
            % Update b
            b = r-q;
            % Page 305 formulas.
            sigma_sqr = sigma.*sigma;
            time_sqrt = sqrt(time);
            % nn = 2*b./sigma_sqr;
            m = 2*r./sigma_sqr;
            nn = 2*b./sigma_sqr;
            
            K = 1 - exp(-r.*time);
            % K = 2*r./sigma.^2./(1-exp(-r.*time));
            
            if strcmp(CP{1},'C') == 1 % CALL CASE
                
                % seed value from paper for calls
                q2 = (-(nn-1)+sqrt((nn-1).^2+(4*m./K))).*0.5;
                q2_inf = 0.5 * ( -(nn-1) + sqrt((nn-1).^2+4*m));
                S_star_inf = X ./ (1 - 1./q2_inf);
                h2 = -(b.*time+2.0*sigma.*time_sqrt).*(X./(S_star_inf-X));
                S_seed_call = X + (S_star_inf-X).*(1-exp(h2));
                % GP 5.12.17: temporary quick fix: there are extremely rare occurrences
                % when the seed is < 0, that shouldn't happen. For now use
                % the simulated spot price (StockPrice) as a replacement.
                % Ask Panos to review this more in depth
                S_seed_call(S_seed_call<0) = StockPrice((S_seed_call<0));
                
            else
                
                % seed value from paper for puts
                q1_inf = 0.5 * ( -(nn-1) - sqrt((nn-1).^2+4*m));
                S_twostar_inf = X ./ (1 - 1./q1_inf);
                q1 = (-(nn-1)-sqrt((nn-1).^2+(4*m./K))).*0.5;
                %     q1 = (1-nn-sqrt((nn-1).^2+4*K))/2;
                h1 = (b.*time - 2 *sigma.*time_sqrt).*(X./(X - S_twostar_inf));
                S_seed_put = S_twostar_inf + (X - S_twostar_inf).*exp(h1);
                % GP 5.12.17: temporary quick fix: there are extremely rare occurrences
                % when the seed is < 0, that shouldn't happen. For now use
                % the simulated spot price (StockPrice) as a replacement.
                % Ask Panos to review this more in depth
                S_seed_put(S_seed_put<0) = StockPrice((S_seed_put<0));
            end
            
            if strcmp(CP{1},'C') == 1 % CALL CASE
                Si=S_seed_call; % Initiate seed as in paper.
                while ((error > ACCURACY) && ( no_iterations < max_iter))
                    
                    Si_old = Si;
                    c = BSCall(Si,X,r,b,sigma,time);      % option_price_european_call_payout(Si,X,r,b,sigma,time);
                    d1 = (log(Si./X)+(b+0.5*sigma_sqr).*time)./(sigma.*time_sqrt);
                    
                    % g(Si): vector valued function of Si whose root I want to find 
                    g = (1 - 1./q2).*Si-X-c+(1 ./q2).*Si.*exp((b-r).*time).*normcdf(d1);   % FORMULA 26,a,b.
                    
                    % ALTERNATIVELY
                    % g = Si - X - c - (1-exp((b-r).*time).*normcdf(d1)).*Si./q2;
                    
                    % d(g(Si))/dSi: first derivative (diag of Jacobian
                    % since there are no mixed terms)
                    gprime = ( 1-1./q2).*(1 -exp((b-r).*time).*normcdf(d1)) ...
                        +(1./q2).*exp((b-r).*time).*normpdf(d1).*(1./(sigma.*time_sqrt));   % FORMULA 27
                    
                    % ALTERNATIVELY
                    % gprime2 = 1- (exp((b-r).*time).*normcdf(d1).*(1-1/q2) + (1-exp((b-r).*time).*normcdf(d1)/(sigma*time_sqrt))./q2);
                    
                    Si = Si-(g./gprime);    % Newton iteration
                    
                    no_iterations = no_iterations + 1;
                    
                    Si(Si < 0) = 0;
                    
                    error = (norm(Si-Si_old)/norm(Si)); % ERROR NORM for vector x1 Newton Raphson
                    
                end % END CALL CASE.
                Si(abs(g)>ACCURACY) = S_seed_call(abs(g)>ACCURACY); % For the ones not converged (as with the paper)
                
            else %' PUT CASE NEED TO CHANGE THE g and gprime calculations.
                Si=S_seed_put; % Initiate seed as in paper.
                while ((error > ACCURACY) && ( no_iterations < max_iter))
                    
                    Si_old = Si;
                    
                    p = BSPut(Si,X,r,b,sigma,time);      % option_price_european_call_payout(Si,X,r,b,sigma,time);
                    d1 = (log(Si./X)+(b+0.5*sigma_sqr).*time)./(sigma.*time_sqrt);
                    
                    % g(Si): vector valued function of Si whose root I want to find 
                    g = -(1 -1./q1).*Si+X-p-(1 ./q1).*Si.*exp((b-r).*time).*normcdf(-d1);
                    
                    % OR Formula 24
                    % g =  X -Si - p + (1-exp((b-r).*time).*normcdf(-d1)).*Si./q1;
                    
                    % gprime = -( 1-1./q1).*(1 -exp((b-r).*time).*normpdf(-d1)) ...
                    % -(1./q2).*exp((b-r).*time).*normcdf(-d1).*(1./(sigma.*time_sqrt));
                    
                    % d(g(Si))/dSi: first derivative (diag of Jacobian
                    % since there are no mixed terms)
                    gprime =  1- (exp((b-r).*time).*normcdf(d1).*(1-1./q1) - (1+exp((b-r).*time).*normpdf(-d1)./(sigma.*time_sqrt))./q1);
                    
                    Si = Si - (g./gprime);  % Newton iteration
                    
                    no_iterations = no_iterations + 1;
                    
                    Si(Si < 0) = 0;
                    
                    error = (norm(Si-Si_old)/norm(Si)); % ERROR NORM for vector x1 Newton Raphson
                    
                end
                Si(abs(g)>ACCURACY) = S_seed_put(abs(g)>ACCURACY); % For the ones not converged (as with the paper)
                
            end   % END PUT CASE
            
            
            
        end % newton_American
        
        function subset = getSubset(varargin)
            % X must be a vector or a scalar representing the full set
            % first,last: scalars identifying the limits of the
            % desired subset
            % idx: a set of positional indices referred to X (1st input
            % arg)
            X = varargin{1};
            if nargin == 3
                first = varargin{2};
                last = varargin{3};
                if numel(X)==1
                    subset = X;
                else
                    subset = X(first:last);
                end
            elseif nargin == 2
                idx = varargin{2};
                if numel(X)==1
                    subset = X;
                else
                    subset = X(idx);
                end
            end
        end % getSubset
        
    end % static methods
    
end % classdef

