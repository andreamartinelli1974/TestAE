classdef cds < InvestmentUniverse.asset
     % CDS subclass
     
     properties (Constant)
        % mapping Bloomberg Payment Legs frequencies to corresponding year
        % fractions
        FreqKeySet =  {'M','Q','Y'};
        FreqValueSet = [1 3 12];
        
    end
     
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
       FixedTtm = []; % fixed time to maturity
       ReferenceCurve = [];
       CashFlow = [];
       Zero_Time = []; % points (in yf) on the disc curve needed to price the CDS
       % accrual frequencies map
       FreqMap = [];    
       FreqMap_words = [];
       PL_frequency = []; % Payment leg frequency
       FirstAccrual = []; % First Accrual Date (original date, month and day)
       PL_dates = []; % Payment Legs Dates
       dfCurve = [];
       CDS_Curve = [];
       Coupon = [];
       RollDates = [];
       CDS_RollDates = []; % vector of rollovers dates
       FixedCoupon = []; % fixed coupon for std contracts
       CDSmult = [];
       Notional = [];
       InputParams;
       % IF = 1 the historical price (used for backtesting) as well as projected prices
       % at the investment horizon, will incorporate the  FixedCoupon
       % based accruals
       AccrueCDS_coupon;
       
    end
    
    methods
        % costruttore: costruisce B come subclass di asset e ne eredità
        % proprietà e metodi
        function CDS = cds(asset_params,params_CDS)
            CDS = CDS@InvestmentUniverse.asset(asset_params);
            % input specific to CDS subclass (under params_CDS. struct
            % array root)
            % FixedTtm: constant time to maturity
            % dcurve: a struct array having the same structure of the field
            % Curve of objects of type IR_Curve
            % cds_curve: a struct array having the same structure of the field
            % Curve of objects of type CDS_Curve
            % cpn: annualized coupon in bps
            % cds_notional: -1 for long position on credit (that is SELL PROTECTION or short protection)
            % cds_mult:  % multiplier for CDS: must be the multiplier  to
            % be used to convert  positions into dollars (e.g.
            % abs(cds_notional*cds_mult) = the CDS notional)
            % excel_spread_input.flag: true(1) if input credit spreads must
            % be read from xls. In this case the following fields must be
            % provided as well
            % .excel_spread_input.xls_file_name
            % .excel_spread_input.xls_sheet_name
            % .excel_spread_input.manual_ticker

            % IMPORTANT: invariants (returns) will always be calculated
            % assuming a notional of 1. The Multiplier will be used the
            % same way it is used for options or futures, that is to
            % tyransform % weights into quantities during the dynamic AA
            % process
            
            % getting single params from input strucxt array (later upgrade
            % to initial input format): this is why some parameters are
            % assigned to single properties while a subset of them is simpy
            % assigne dotr the field InputParams (TODO: reorganize this)
            % ***********************************
            FixedTtm = params_CDS.FixedTtm;
            dcurve = params_CDS.dcurve;
            cds_curve = params_CDS.cds_curve;
            % cpn = params_CDS.cpn;
            rolldates = params_CDS.rolldates;
            fixedcoupon = params_CDS.fixedcoupon;
            cds_mult = params_CDS.cds_mult;
            cds_notional = params_CDS.cds_notional;
            AccrueCDS_coupon = params_CDS.AccrueCDS_coupon;
            % ***********************************
            
            CDS.InputParams = params_CDS;
            CDS.Notional = cds_notional;
            CDS.CDSmult = cds_mult;
            CDS.Multiplier = CDS.CDSmult; % assigning the property for the asset mother class (for cds only)
            CDS.AccrueCDS_coupon = AccrueCDS_coupon;
            
            % getting Bloomberg static data through an instance
            % of class Utility
            uparam.DataFromBBG = asset_params.DataFromBBG;
            uparam.ticker = asset_params.ticker_BBG;

            uparam.fields = {'TICKER','CDS_COMPANY_NAME', ...
                'CDS_FIRST_ACCRUAL_START_DATE','CDS_NEXT_LAST_CPN_DATE', ...
                'SW_PAY_NOTL_AMT','SW_PAY_FREQ','SW_REC_FREQ','CDS_TERM','CDS_RR', ...
                'GENERIC_CDS_INDEX','CDS_PAY_ACCRUED','GENERIC_CDS_INDEX','SW_PAY_NXT_CPN_DT'};
            uparam.override_fields = [];
            uparam.override_values = [];

            U = Utilities(uparam);
            U.GetBBG_StaticData;
            d = U.Output.BBG_getdata;
            if isfield(d,'ERROR') & strcmp(d.ERROR,'INVALID_SECURITY')
                CDS.BloombergError = true(1);
                return
            end
            %[d,sec] = getdata(bbgconn,ticker_BBG,{'TICKER','TICKER_AND_EXCH_CODE','CDS_COMPANY_NAME', ...
            %    'CDS_FIRST_ACCRUAL_START_DATE','CDS_NEXT_LAST_CPN_DATE', ...
            %    'SW_PAY_NOTL_AMT','SW_PAY_FREQ','SW_REC_FREQ','CDS_CASH_SETTLED_AMOUNT','CDS_TERM','CDS_RR', ...
            %    'CDS_PRICE_TO_SPREAD','GENERIC_CDS_INDEX','CDS_PAY_ACCRUED','GENERIC_CDS_INDEX','SW_PAY_NXT_CPN_DT'});

            CDS.Specific_Attributes.TICKER = d.TICKER;
            % CDS.Specific_Attributes.TICKER_AND_EXCH_CODE = d.TICKER_AND_EXCH_CODE;
            CDS.Specific_Attributes.CDS_FIRST_ACCRUAL_START_DATE = d.CDS_FIRST_ACCRUAL_START_DATE;
            CDS.Specific_Attributes.CDS_NEXT_LAST_CPN_DATE = d.CDS_NEXT_LAST_CPN_DATE;
            CDS.Specific_Attributes.SW_PAY_NOTL_AMT = d.SW_PAY_NOTL_AMT;
            CDS.Specific_Attributes.SW_PAY_FREQ = d.SW_PAY_FREQ;
            CDS.Specific_Attributes.SW_REC_FREQ = d.SW_REC_FREQ;
            % CDS.Specific_Attributes.CDS_CASH_SETTLED_AMOUNT = d.CDS_CASH_SETTLED_AMOUNT;
            CDS.Specific_Attributes.CDS_TERM = d.CDS_TERM;
            CDS.Specific_Attributes.CDS_RR = d.CDS_RR;
            % CDS.Specific_Attributes.CDS_PRICE_TO_SPREAD = d.CDS_PRICE_TO_SPREAD;
            CDS.Specific_Attributes.CDS_PAY_ACCRUED = d.CDS_PAY_ACCRUED; % 'Y' if accrued interest is paid on default
            CDS.Specific_Attributes.GENERIC_CDS_INDEX = d.GENERIC_CDS_INDEX; % 'Y' if it is a generic CDS index
            CDS.Specific_Attributes.SW_PAY_NXT_CPN_DT = d.SW_PAY_NXT_CPN_DT;
            CDS.dfCurve = dcurve;
            CDS.CDS_Curve = cds_curve;
            % CDS.Coupon = cpn;
            CDS.FreqMap = containers.Map(CDS.FreqKeySet,CDS.FreqValueSet);
            CDS.RollDates = rolldates;
            try
            CDS.PL_frequency = CDS.FreqMap(CDS.Specific_Attributes.SW_PAY_FREQ{1}); % PL freq in months
            catch
               disp('chk'); 
            end
            CDS.FirstAccrual.dt = CDS.Specific_Attributes.CDS_FIRST_ACCRUAL_START_DATE;
            CDS.FirstAccrual.day = day(CDS.FirstAccrual.dt);
            CDS.FirstAccrual.mth = month(CDS.FirstAccrual.dt);
            CDS.ReferenceCurve = cds_curve; %.Name;
            CDS.FixedCoupon = fixedcoupon;
            
            CDS.FixedTtm = FixedTtm;
            if isempty(CDS.FixedTtm)
                disp('Only Constant Maturity CDS managed for now');
                pause;
            end
            
            % ************************************************************
            % ************************************************************
            % Derive perpetual (or at least up to inv horizon) cashflow and
            % rollovers schedules
            % last date set as FixedTtm years ahead of Horizon calculated
            % from today (the most recent investment decision date)
            
            % TODO: parametrize to 2 cycles for PL_dates and Roll dates
            % below and implement the appropriate calendar
            
            % Payment leg dates
            last_dt = today + asset_params.hor + CDS.FixedTtm.*365; 
            pmth = CDS.FirstAccrual.mth;
            pday = CDS.FirstAccrual.day;
            freq = CDS.PL_frequency;
            yr = year(rolldates(1)); % using the year of rolldates as starting year (be sure that is is well in the past, rg 1900)
            nxtdt = datenum(yr - 1,pmth,pday);
            
            PL_dates = nxtdt;
            while nxtdt < last_dt
                
                pmth = pmth + freq;
                if pmth > 12
                    pmth = pmth - 12;
                    yr = yr + 1;
                end
                nxtdt = datenum(yr,pmth,pday);
                if ~isbusday(nxtdt)
                    % if not a bus day pick the first follwing busday (TODO: to be refined with exact calendar)
                    nxtdt = busdate(nxtdt, 1);
                end
                PL_dates = [PL_dates,nxtdt];
            end
            CDS.PL_dates = PL_dates';
            
            % Rolling dates
            yr = year(rolldates(1)); % using the year of rolldates as starting year (be sure that is is well in the past, rg 1900)
            nxtdt = rolldates(1);
            
            last_dt = today + asset_params.hor + CDS.FixedTtm.*365; 
            freq = abs(diff(month(CDS.RollDates)));
            R_dates = nxtdt;
            while nxtdt < last_dt
                nxtdt = datemnth(nxtdt, freq, 0);
                if ~isbusday(nxtdt)
                    % if not a bus day pick the first follwing busday (TODO: to be refined with exact calendar)
                    nxtdt_bus = busdate(nxtdt, 1);
                else
                    nxtdt_bus = nxtdt;
                end
                R_dates = [R_dates,nxtdt_bus];
            end
            
            CDS.CDS_RollDates = R_dates';
            % ************************************************************
            % ************************************************************
            
        end
        
        function Price2Invariants(CDS, params) % calculating invariants
            
            % note: returns on dates in CDS.CDS_RollDates will be removed
            
            % (:,1) and (:,2) to use data fron LAST_PRICE field
            % (:,1) and (:,3) to use data fron ROLL_ADJUSTED_MID_PRICE field
            s_ts = [CDS.History.CdsSpread.TimeSeries(:,1),CDS.History.CdsSpread.TimeSeries(:,3)]; %(:,3)
            
            utilParams.data1 = s_ts;
            utilParams.data2 = [];
            utilParams.lag = params.lag;
            utilParams.pct = params.pct;
            utilParams.logret = params.logret;
            utilParams.rolldates = CDS.CDS_RollDates;
            utilParams.last_roll = params.last_roll;
            utilParams.EliminateFlag = params.EliminateFlag;
            utilParams.ExtendedLag = params.ExtendedLag;
            U = Utilities(utilParams);
            U.RetCalc;
            CleanRet = U.Output.CleanRet;
            CleanPrices = U.Output.CleanPrices;
            
            CDS.Invariants.Name = CDS.History.CdsSpread.Name;
            CDS.Invariants.Type = ['CDS_changes'];
            CDS.Invariants.CDS_changes = CleanRet;
            CDS.Invariants.Prices = CleanPrices; % CDS.History.CdsSpread.TimeSeries(:,1:2);
            
            % the same invariants will be used since we are pricing constant
            % ttm CDS only for now, so we do not need a full curve to model
            % underlying risk factors for "At Horizon" pricing. 
            CDS.Invariants.External4AtHorizonModeling = false(1);
            
            % Name of the factor that will be used to search the
            % appropriate series in AllInvariants.NameSet: for CDS I will
            % always use the curve provided as an input 
            CDS.Risk_Factors_Names.CDS = CDS.History.CdsSpread.Name;
            % giving the same name to the field Name of internal
            % invariants, to be sure that it will not be duplicated by the
            % method GetAllInvariant of class Universe when creating
            % Universe.AllInvariants matrices
        end
        
        function price = Reprice(CDS,params)
            % method designed to reprice a CDS based on the fields in the
            % struct array params
            % params.type: 'full_repricing' or 'approx'
            % 'approx' only is available for now (TODO: complete with full repricing or may be with
            % some form of convexity adj, since full repricing can be too time consuming for my purposes)
            % params.p0: starting price (monetary amount) of the CDS spread
            % (as of date current_t_date )
            % params.SPV01 = spread DV01 as of settle date
            % params.settle = date of pricing (settle date in num date format);
            % params.er = expected annualised cds spread change at horizon. 
            % params.CDS_spread0: CDS spread as of settle date
            
            % (Using change here, not log-change, since we are in the log space already (
            % these values are added to YTM to price a bond. TODO. CHECK more carefully))
            % This can be a single value
            % or a vector as well (a distribution of expected CDS that will yield a 
            % distribution of CDS prices)
            
            disp('CDS repricing');
            R = CDS.Specific_Attributes.CDS_RR; % recovery rate
            expected_spread_distrib = (params.CDS_spread0 + params.er); % expected spread ditrib at horizon
            
            if strcmp(params.type,'approx')
                
                % price change approximation via SDV01
                
                % TODO: test this
                % using the starting price params.p0
                price = CDS.Notional.*params.p0 + ...
                    ((CDS.Notional.*params.p0).*(expected_spread_distrib - params.CDS_spread0) .* params.SPV01./100); 
                
%                 % convert expected changes of spreads from the spread0
%                 % value in basis points
%                 conv2bps = (expected_spread_distrib - params.CDS_spread0).*10000;
%                 % convert the initial price into a 100 based price and
%                 % apply the SPV01 (change for each basis point)
%                 price = (100*CDS.Notional.*params.p0) + ...
%                     ((CDS.Notional.*params.p0).*(conv2bps) .* params.SPV01 ./100);
%                 price = price./100; % convert back into 1 based prices
                
            elseif strcmp(params.type,'full_repricing')
                % TO BE COMPLETED: DO NOT USE FOR NOW
                
                % find the discount facor as of date params.tdy
                fd = find(CDS.dfCurve.dates == params.tdy);
                % discount factors
                df_tenors = CDS.dfCurve.tenors_yf';
                df_rates = CDS.dfCurve.rates(fd,:)';
                df_dates = daysadd(datenum(params.tdy),360*df_tenors,1);
                
                df_curve = [df_dates df_rates];
                % ... interpolating corresponding disc factors
                %  [Zero_Rates] = universe.CurveInterp(CDS.dfCurve,params.tdy,Zero_Times','rates',5);
                
                cds0 = repmat(params.cds0,size(params.er,1),1);
                cds_distrib = (cds0 + params.er).*100; % estimated cds distrib at horizon
                
                % bootstrapping default probabilities and hazard rates for each
                % one of the scenarios in the distribution above
                
                % dates on the curve corresponding to available tenors (always starting from
                % the date of the pricing in params.tdy, since the assumption is that of a constant TTE
                % CDS)
                Market_Dates = daysadd(params.tdy,CDS.CDS_Curve.Curve.tenors_yf.*360);
                % corresponding cds prices: here, for each one of the scenarios
                % at horizon, need fo bootstrap the F(t) cum default prob to be
                % used for repricing
                
                %             repMarket_Dates = repmat(Market_Dates,size(cds_distrib,1),1);
                %             MarketData = reshape(cds_distrib',[size(cds_distrib,1).*size(cds_distrib,2),1]);
                %             Market = [repMarket_Dates,MarketData];
                %             [P,H] = cdsbootstrap(df_curve,Market,params.tdy,'RecoveryRate',R);
                
                % identifying the tenor to price (should reflect the fixed the constant maturity of the
                % specific instance of the object)
                ft = find(CDS.CDS_Curve.Curve.tenors_yf==CDS.FixedTtm);
                maturity = daysadd(params.tdy,CDS.FixedTtm.*360);
                
                for k=1:size(cds_distrib,1)
                    k-size(cds_distrib,1)
                    
                    MarketData = [Market_Dates,cds_distrib(k,:)'];
                    [P,H] = cdsbootstrap(df_curve,MarketData,params.tdy,'RecoveryRate',R);
                    HazCurveDates(k,:) = H(:,1)';
                    HazData(k,:) = H(:,2)';
                    ProbCurveDates(k,:) =  P(:,1)';
                    ProbData(k,:) = P(:,2)';
                    fneg = find(HazData(k,:)<0);
                    if ~isempty(fneg) & k>1
                        HazData(k,:) = HazData(k-1,:);
                        ProbData(k,:) = ProbData(k-1,:);
                    end
                    [price(k,1),acc_prem(k,1)] = cdsprice(df_curve,[ProbCurveDates(k,ft), ProbData(k,ft)],params.tdy,maturity,params.cds0(ft).*100,'Notional',1);
                    newp(k,1) = cdsspread(df_curve,[ProbCurveDates(k,ft), ProbData(k,ft)], params.tdy, maturity)
                end
                
            end % repricing type
        end % Reprice
        
        function [npv1,npv2,RPV01,hr,rate,DP] = BootstrapAndPrice(CDS, dt, spread, tenor)
            % dt: date of pricing
            % spread: mkt CDS spread in dt
            % tenor: tenor of the cds to price
            
            pl_frequency = 12./CDS.PL_frequency;
            R = CDS.Specific_Attributes.CDS_RR; % recovery rate
            pl_leg_start_dt = CDS.PL_dates(CDS.PL_dates>dt);
            pl_leg_start_dt = pl_leg_start_dt(1);
            
            % find the discount facor as of date dt
            % fd = find(CDS.dfCurve.dates == dt);
            % discount factors
            df_tenors = CDS.dfCurve.Curve.tenors_yf';
            % df_rates = CDS.dfCurve.rates(fd,:)';
            df_rates = InvestmentUniverse.universe.CurveInterp(CDS.dfCurve.Curve,dt,df_tenors,'rates',-5); % not really interpolating here, but invoking this for homog and to use the last parameter
            df_dates = daysadd(datenum(dt),floor(360*df_tenors),1);
            df_curve = [df_dates df_rates];
           
            % find the CDS spread curve as of dt
            cdscurve = InvestmentUniverse.universe.CurveInterp(CDS.CDS_Curve.Curve  ,dt,CDS.CDS_Curve.Curve.tenors_yf,'CDS_interp',-5); % TODO: parametrize the -5 here and above
            if isnan(cdscurve) % no values for the date on the curve
                npv1 = NaN;
                npv2 = NaN;
                RPV01 = NaN;
                hr = NaN;
                rate = NaN;
                DP = NaN;
                return;
            end
            % dates on the curve corresponding to available tenors (always starting from 
            % the date of the pricing in dt, since the assumption is that of a constant TTE
            % CDS)
            Market_Dates = daysadd(dt,floor(CDS.CDS_Curve.Curve.tenors_yf.*365));  % TODO: improve with 'dateshift'
            MarketData = [Market_Dates,100.*cdscurve];

            % maturity of the CDS
            maturity = daysadd(dt,floor(CDS.FixedTtm.*365)); % TODO: review the flooring (see dateshift as an alternative)
            
            % corresponding cds prices
            [P,H] = cdsbootstrap(df_curve,MarketData,dt,'RecoveryRate',R);
            
            Maturity3 = MarketData(:,1);
            Spread3Run = MarketData(:,2);
            Spread3Std = 100*ones(size(Maturity3));
            Price3 = cdsprice(df_curve,P,dt,Maturity3,Spread3Std);
            Upfront3 = Price3/CDS.Notional; % TODO: parametrize the notional

            ft = find(CDS.CDS_Curve.Curve.tenors_yf == tenor); % to select the appropriate cum probability

            npv1 = 0; % npv1 full reval calc below is time consuming
            
            RPV01 = cdsrpv01(df_curve,[P(ft,1), P(ft,2)],dt,maturity,'Period',pl_frequency,'Startdate',pl_leg_start_dt);
            % CDS price = Notional * (Current Spread - Contract Spread) * RPV01
            npv2 = CDS.Notional.*(MarketData(ft,2)./100 - spread) * RPV01./100;
            
            dP = [0;diff(P(:,2))];
            DP = dP(ft);
            hr = H(ft,2);
            rate = df_curve(ft,2);
            
        end % BootstrapAndPrice
        
% %         % ****************************************************************
% %         % OLD: NO MORE USED
% %          function price = Reprice(CDS,params)
% %             % method designed to reprice a CDS based on the fields in thje
% %             % struct array params
% %             % params.cds0 = starting cds level for all tenors;
% %             % params.tdy = date of pricing (num date format);
% %             % params.er = expected annualised cds spread change at horizon. 
% %             
% %             % params.er = expected annualised cds spread changes at horizon
% %             % for the whole curve
% %             
% %             % (Using change here, not log-change, since we are in the log space already (
% %             % these values are added to YTM to price a bond ? TOTO. CHECK more carefully))
% %             % This can be a single value
% %             % params.settle = pricing date
% %             % or a vector as well (a distribution of expected CDS that will yield a 
% %             % distribution of CDS prices)
% %                  
% %             disp('CDS repricing');
% %             R = CDS.Specific_Attributes.CDS_RR; % recovery rate
% %             
% %             % find the discount facor as of date params.tdy
% %             fd = find(CDS.dfCurve.dates == params.tdy);
% %             % discount factors
% %             df_tenors = CDS.dfCurve.tenors_yf';
% %             df_rates = CDS.dfCurve.rates(fd,:)';
% %             df_dates = daysadd(datenum(params.tdy),360*df_tenors,1);
% % 
% %             df_curve = [df_dates df_rates];
% %             % ... interpolating corresponding disc factors
% %             %  [Zero_Rates] = universe.CurveInterp(CDS.dfCurve,params.tdy,Zero_Times','rates',5);
% %             
% %             cds0 = repmat(params.cds0,size(params.er,1),1);
% %             cds_distrib = (cds0 + params.er).*100; % estimated cds distrib at horizon
% %             
% %             % bootstrapping default probabilities and hazard rates for each
% %             % one of the scenarios in the distribution above
% %             
% %             % dates on the curve corresponding to available tenors (always starting from 
% %             % the date of the pricing in params.tdy, since the assumption is that of a constant TTE
% %             % CDS)
% %             Market_Dates = daysadd(params.tdy,CDS.CDS_Curve.Curve.tenors_yf.*360); 
% %             % corresponding cds prices: here, for each one of the scenarios
% %             % at horizon, need fo bootstrap the F(t) cum default prob to be
% %             % used for repricing
% %             
% % %             repMarket_Dates = repmat(Market_Dates,size(cds_distrib,1),1);
% % %             MarketData = reshape(cds_distrib',[size(cds_distrib,1).*size(cds_distrib,2),1]);
% % %             Market = [repMarket_Dates,MarketData];
% %             % [P,H] = cdsbootstrap(df_curve,Market,params.tdy,'RecoveryRate',R);
% %             
% %             % identifying the tenor to price (should reflect the fixed the constant maturity of the 
% %             % specific instance of the object)
% %             ft = find(CDS.CDS_Curve.Curve.tenors_yf==CDS.FixedTtm);
% %             maturity = daysadd(params.tdy,CDS.FixedTtm.*360); 
% %             
% %             for k=1:size(cds_distrib,1)
% %                 k-size(cds_distrib,1)
% %                 
% %                 MarketData = [Market_Dates,cds_distrib(k,:)'];
% %                 [P,H] = cdsbootstrap(df_curve,MarketData,params.tdy,'RecoveryRate',R);
% %                 HazCurveDates(k,:) = H(:,1)';
% %                 HazData(k,:) = H(:,2)';
% %                 ProbCurveDates(k,:) =  P(:,1)';
% %                 ProbData(k,:) = P(:,2)';
% %                 fneg = find(HazData(k,:)<0);
% %                 if ~isempty(fneg) & k>1
% %                     HazData(k,:) = HazData(k-1,:);
% %                     ProbData(k,:) = ProbData(k-1,:);
% %                 end
% %                 [price(k,1),acc_prem(k,1)] = cdsprice(df_curve,[ProbCurveDates(k,ft), ProbData(k,ft)],params.tdy,maturity,params.cds0(ft).*100,'Notional',1);
% %                 newp(k,1) = cdsspread(df_curve,[ProbCurveDates(k,ft), ProbData(k,ft)], params.tdy, maturity)
% %             end
% %           
% %             
% %         end % Reprice
% %         % *****************************************************************
        
        
    end % methods
    
    methods(Static)
        
    end % static methods
end


