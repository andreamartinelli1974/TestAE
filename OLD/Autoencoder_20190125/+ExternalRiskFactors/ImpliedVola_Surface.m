classdef ImpliedVola_Surface < handle
    % this class does the following:
    % 1) get historical implied volatility data: from BBG or impliying them
    % from hist mkt prices (underlying, interest rates, etc.)
    % 2) calibrate a 2 parameters model separately for a set of fixed
    % "times to expiry" and Call/Put indicator
    % 3) define an interpolation function to be used in practical
    % applications (eg in AA for pricing at horizon)
    
    % FOR NOW THIS WORKS in a BLS FRAMEWORK (it will bne possioble top
    % expand the class to model different pricings)
    
    % Instances of this class will be used, as an example, when repricing
    % options at the investment horizon: since the invariant used is the
    % ATM implied volatility, at horizon it is necessary to 'transform' it
    % in a measure taking into account moneyness (skew)
    % This is an initial simplified approach
    
    % ex. to create and instance of the class:
    % V = ImpliedVola_Surface(c,'SX5E Index','SX5E',date,25,0,0.01,0.005)
    % then ...:
    % V.CalibrateSkewParams(1)
    % V.DrawEstimatedSurface(0.2,3000), with 0.2 = current ATM implied
    % vola and 3000 = current underlying's price
    
    % TODO: verify using fwd ATM
    %       chart the mkt vola surface and the one generated using mkt data
    %       top estimate params
    %       see if it is worthwhile making alfa and beta time(2mat)-dependent
    %       when possible plug in to the Resouce database to get hist
    %       implied volatilities (putting them in the same matrices used to
    %       store Bloomberg's datasets)
    
    properties (Constant)
        fields2download = {'LAST_TRADE'};
        fields2download_2 = {'LAST_TRADE','EOD_TIME_TO_EXPIRY_MID'};
        fields2download_static_data = {'OPT_EXPIRE_DT'};
        
        % new (14042018): will use the IVOL_SURFACE_MONEYNESS Bloomberg
        % field to skews used to derive the parameters upon whom it is
        % modeled - TODO: in future revisions make a specific contained for
        % this info, to be shared by all options having the same underlying
        ivol_fields = {'IVOL_SURFACE_MONEYNESS'}; % {'IVOL_SURFACE_MONEYNESS','IVOL_SURFACE_STRIKE'};
        
        % TO BE USED when Bloomberg is used as data provider
        frequency = 'daily';
        StrikeSearchMaxIter = 100; % max no of iterations allowed in strike search (v method IdentifyValidStrike)
        TimeToExpiry_BBG = [1 2 3 4 5 6 7 8 9 10 11 12]; % fixed times to expiry (in months) to be used for calibration
        MoneynessLimits_BBG = [0.80 1.20]; % moneyness interval to calibrate over
        MoneynessGranularity_BBG = 0.05; % steps in the moneyness dimension (TODO: parametrize this since it strictly depends on price levels)
        
        % TO BE USED when Mds is used as data provider
        % when the start date < 7/2015
        TimeToExpiry_Mds_1 = [1/12, 3/12, 6/12, 1, 2, 3, 4, 5]; % year fractions
        Moneyness_Vector_Mds_1 = [0.8, 0.9, 0.95, 1, 1.05, 1.1, 1.20, 1.3];
        % when the start date > 7/2015
        TimeToExpiry_Mds_2 = [1/52 1/12, 2/12, 3/12, 6/12, 9/12, 1, 1.50, 2, 3, 4, 5, 7, 10]; % year fractions
        Moneyness_Vector_Mds_2 = [0.3 0.4 0.6 0.8, 0.9, 0.95, 0.975, 1, 1.025, 1.05, 1.1, 1.20, 1.3 1.5 1.75 2 2.5 3];
        
    end
    
    properties (Access = public)
        % MAIN OUTPUT: alfa and beta to model vola surface based on current
        % ATM vola (see method DrawEstimatedSurface)
        alfa = []; % alfa and beta are the single skew parans when 
        beta = [];
        Calibration = []; % 'one_for_each_TTE' or 'one_for_all_TTE' Calibration = 'one_for_all_TTE'
        skewsParamByExpiry; % used in place of alfa and beta when they are computed as time 2 expiry dependent parameters (when Calibration = 'one_for_each_TTE'
        X = [];
        IntExt = [];
        ToBeIncludedInInvariants = [];
        % these are the extremes values of abs log moneyness upon which
        % parameters have been estimated. It is possible to make that any
        % request to GetAdjIV_Estimates being limited to these boundaries
        % (uncommenting %commented% lines of code in the  method)
        MoneynessAbsLogMinBoundary;
        MoneynessAbsLogMaxBoundary;
        Data4SurfaceDrawing = []; % struct used to save calibration data when running V.CalibrateSkewParams to be able to invoke the method V.DrawSkewsSurface 'from outside'
    end
    
    properties (SetAccess = immutable)
        Name = [];
        DataFromBBG = [];
        DataFromMDS = [];
        HistDates = [];
        Underlying_Ticker = [];
        Yield = [];
        OptMktPrices = [];
        Moneyness_Vector = [];
        Strikes = [];
        DataSource = [];
        TimeToExpiry;
        MoneynessLimits;
        SaveParams;
        FilledDataMap;
    end
    
    properties (SetAccess = protected)
        Moneyness_Vector_ABSlog = [];
        Time2Maturity = [];
        MktImpliedVolasHistoricalDates = [];
        MktImpliedVolas = [];
        ImpliedAtmVola_Preprocessed = [];
        proxyMDS_Flag = false(1);
        MktImpliedVolasHistoricalDates_raw = [];
        MktImpliedVolas_raw = [];
    end
    
    methods
        function V = ImpliedVola_Surface(DataFromBBG,DataFromMDS,underlying_ticker,option_ticker, ...
                dates,min_strike_increase,dec_digits,rfr,yield,data_source,useSavedParams,volaMap) % CONSTRUCTOR
            % INPUT:
            % DataFromBBG: Bloomberg connection obj and BBG data saving
            % options
            % underlying_ticker: underlying's ticker (e.g. SX5E Index)
            % option_ticker: root ticker for options (e.g. SX5E for options
            % referenced as SX5E 02/19/16 C 2800)
            % dates: struct array with fields 'start' and 'end' containing
            % the initial and final dates of the hist window to be used to
            % calibrate volatility parameters
            % min_strike_increase: this is the minimum increase in strike 
            % for quoted options on the given underlying (e.g. for the
            % Eurostoxx50 this number is 25, ... strikes go like
            % 2675,2700,2725, .....) ** NO MORE NEEDED in the new version
            % dec_digits: is the no of dec digits used to define the
            % strike (e.g. for SX5E there are 0 dec digits; ** NO MORE NEEDED in the new version
            % rfr: risk free rate TODO: refine this
            % yield: for now a single number (e.g. the annual div yield for
            % options written on stock indices or the foreign interest rate
            % for FX options) TODO: refine this
            % data_source: 'BBG' if data are taken from Bloomberg. 'MDS' if
            % data are downloaded from the internal Db. The former choice
            % works well for a limited range of dates (up to 10 days)
            % otherwise it becomes too burdensome both in terms of time and
            % of amount of data to be downloaded from Bloomberg Terminal
            % (there are daily limits !!!)
            % DataFromMDS: when DataSource=='MDS' this structure must be
            % non empty and contain the fields needed to setup a connection
            % to the mkt data server. (In the same way when
            % DataSource=='BBG' then DataFromBBG must be non empty and contain the fields
            % needed for a Bloomberg connection). Both DataFromMDS and
            % DataFromBBG implement the 'save2disk' option that together
            % with the NOBBG (or NOMDS) flag make it possible to run the
            % code on machines not connected to MDS using previously saved
            % data.
            % useSavedParams: made of 2 subfields:
            % useSavedParams.flag: if = 0 then saves the calibrated parameters a
            % and b and the whole 'V' obj for possible  future use (to save
            % time); if = 1 then tries to find previously saved
            % parameters a and b and use them
            % useSavedParams.folder: folder where obj are saved /
            % retrieved from
            % -> volaMap: an obj of class conmtainers.Map (that may be
            % empty) used to hold the implied vola data that have been at
            % least partially filled through previous regressions via mthe
            % method .GetExtendedIV
            
            % ----> data have always daily % here I need many rolling products to manage the rollover jumps
            V.Name = strrep(['ImpliedVola_',option_ticker],' ','_'); % name of the object that will be used to reference it within different class (e.g. Option_Vanilla)
            V.DataFromBBG = DataFromBBG;
            V.DataFromMDS = DataFromMDS;
            V.HistDates = dates;
            V.HistDates.start = datenum(V.HistDates.start);
            V.HistDates.end = datenum(V.HistDates.end);
            V.Underlying_Ticker = underlying_ticker;
            % ** V.DecDigits_no = dec_digits;
            V.Yield = yield;
            % ** V.MinStrikeIncrease = min_strike_increase;
            V.DataSource = data_source;
            V.SaveParams = useSavedParams;
            V.FilledDataMap = volaMap;
            
            % OPTION'S HIST PRICES
            % for each date of hist horizon of prices I need to:
            % 1) identify the call/put strikes whose prices I want to
            % download
            % 2) identify the set of expiry dates I am intersted in
            % 3) identify the ticker of each option
            % 4) downloading its price
            % 5) deriving BLS volatility
            
            % identify nearest strike for which there is a traded option
            % (this is the best proxy for ATM)
            
            
            if strcmp(V.DataSource,'BBG') % *******************************
                
                %                 if V.SaveParams.flag == 1
                %                     undticker = strrep(V.Underlying_Ticker,' ','_');
                %                     undticker = strrep(undticker,'\','_');
                %                     undticker = strrep(undticker,'/','_');
                %                     filename = [V.SaveParams.folder,undticker,'_SavedVolaObj.mat'];
                %                     ff = dir(filename);
                %                     if numel(ff) == 0
                %                         disp('NO PREVIOUSLY SAVED VOLA OBJ FOUND: BUILDING SURFACE AND ESTIMATING PARAMETERS .....');
                %                         % ** return
                %                     else
                %                         m = ['Previously saved (on ',datestr(ff.datenum),') version of the vola surface uploaded'];
                %                         disp(m);
                %                         oldV = load(filename);
                %                         V = oldV.objToSave;
                %                         V.SaveParams = useSavedParams;
                %                         V.FilledDataMap = volaMap; % preserve the volaMap passed to the current instance
                %                         return
                %                     end
                %                 end
                
                
                % data from BBG: we get implied volas from options prices
                disp(['Retrieving BLS implied vola from Bloomberg s mkt option prices for ',option_ticker]);
                Moneyness_Vector = [V.MoneynessLimits_BBG(1):V.MoneynessGranularity_BBG:V.MoneynessLimits_BBG(2)]';
                V.Moneyness_Vector = Moneyness_Vector;
                V.TimeToExpiry = V.TimeToExpiry_BBG;
                V.MoneynessLimits = [V.MoneynessLimits_BBG(1) V.MoneynessLimits_BBG(2)];
                
                % UNDERLYING HIST PRICES
                % download of the underlying hist timeseries (the currency
                % field is omitted so that prices will always be expressed in
                % the undelrlying's native currency)
                
                % getting historical data through
                % an instance of class Utilities
                %                 uparam.DataFromBBG = DataFromBBG;
                %                 uparam.ticker = underlying_ticker;
                %                 uparam.fields = V.fields2download;
                %                 uparam.history_start_date = dates.start;
                %                 uparam.history_end_date = dates.end;
                %                 uparam.granularity = V.frequency;
                %                 U = Utilities(uparam);
                %                 U.GetHistPrices;
                %                 P = U.Output.HistInfo;
                T = 1; % size(P,1);
                
                % Preallocation of the matrix (one column for each element of
                % TimeToExpiry) that will be obtained as an output from the
                % follolwing cycle. The horizontal dim is the dim of TIME to
                % expire (fixed, see TimeToExpiry).
                % The vertical dim represents MONEYNESS:
                % -> the first row will contain (for each time to expiry) the
                % implied vola for a level of strike corresponding to
                % MoneynessLimits(1), the 2nd row will correspond to a
                % moneyness of MoneynessLimits(1)+MoneynessGranularity, the 3rd
                % one to MoneynessLimits(1)+2*MoneynessGranularity, ... and so
                % on up to MoneynessLimits(2)
                
                % All the matrices below have the following 3D:
                % 1) MONEYNESS as defined in Moneyness_Vector;
                % 2) TIME TO EXPIRY, as defined in V.TimeToExpiry (months), but the
                % values in the cells reflect the true time to expiry (in years), that
                % varies depending on the hist date that data refers to
                % 3) NUMBER OF HISTORICAL DAYS used to download the dataset
                % (this depends on the start/end dates provided as an input
                % through the struct array 'dates'.
                V.MktImpliedVolas = zeros(size(Moneyness_Vector,1),size(V.TimeToExpiry_BBG,2),T);
                V.Time2Maturity = V.MktImpliedVolas;
                V.OptMktPrices =  V.MktImpliedVolas;
                V.Strikes = V.MktImpliedVolas;
                V.Moneyness_Vector_ABSlog = V.MktImpliedVolas;
                
                % *********************************************************
                uparam.DataFromBBG = DataFromBBG;
                uparam.ticker = underlying_ticker;
                uparam.fields = V.ivol_fields;
                uparam.override_fields = [];
                uparam.override_values = [];
                U = Utilities(uparam);
                U.GetBBG_StaticData;
                
                expiries = string(U.Output.BBG_getdata.IVOL_SURFACE_MONEYNESS{:,1}(:,1));
                expiries = datenum(expiries,'yyyymmdd');
                time2expiries = (expiries-today)./365; % times to expiry in yrs
                time2expiries_months = time2expiries*12; % for compatibility with previous version
                monenynesses_mkt = cell2mat(U.Output.BBG_getdata.IVOL_SURFACE_MONEYNESS{:,1}(:,2));
                ivols = cell2mat(U.Output.BBG_getdata.IVOL_SURFACE_MONEYNESS{:,1}(:,4)) ./ 100;
                strikes = cell2mat(U.Output.BBG_getdata.IVOL_SURFACE_MONEYNESS{:,1}(:,3));
                prices_mkt = cell2mat(U.Output.BBG_getdata.IVOL_SURFACE_MONEYNESS{:,1}(:,5));
                
                t = 1;
                % place calls implied volatility in the output matrices in
                % a position that is the closest to the corresponding
                % level of monenyness
                for k=1:size(monenynesses_mkt,1)
                    [~,mni] = min(abs(monenynesses_mkt(k) - Moneyness_Vector)); % identify the position corresponding to the closest monenyness
                    [~,n] = min(abs(V.TimeToExpiry_BBG - time2expiries_months(k))); % identify the position corresponding to the closest monenyness
                    V.MktImpliedVolas(mni,n,t) = ivols(k);
                    V.Strikes(mni,n,t) = strikes(k);
                    V.Time2Maturity(:,n,t) = time2expiries(k); % this is constant for current n,t
                    V.Moneyness_Vector_ABSlog(mni,n,1) = log(strikes(k)) - log(prices_mkt(k));
                end
                
                % interpolate over moneyness dimension to fill zero values
                % for current n (time to expiry) and t (date to which data
                % refers to)
                for n=1:size(V.Time2Maturity,2)
                fz = find(V.MktImpliedVolas(:,n,t)==0); % zeros values
                fnz = find(V.MktImpliedVolas(:,n,t)~=0); % non zero values
                moneyness = Moneyness_Vector;
                % TODO: REVIEW THIS
                if ~isempty(fz) & ~isempty(fnz)
                    x = moneyness(fnz);
                    y = V.MktImpliedVolas(fnz,n,t);
                    xq = moneyness(fz);
                    V.MktImpliedVolas(fz,n,t) = interp1(x,y,xq,'linear','extrap');
                    
                    y = V.Moneyness_Vector_ABSlog(fnz,n,t);
                    V.Moneyness_Vector_ABSlog(fz,n,t) = interp1(x,y,xq,'linear','extrap');
                end
                end
                % ***  OLD VERSION ***
                % *********************************************************
                
                % %                 for t = 1:T % for each hist date
                % %
                % %                     % preallocating MktImpliedVola matrix that will contain mkt
                % %                     % implied volas
                % %
                % %                     for n=1:size(V.TimeToExpiry_BBG,2) % for each time to expiry
                % %                         expiry_yr = year(P(t,1));
                % %                         expiry_mth = month(P(t,1)) + V.TimeToExpiry_BBG(n);
                % %                         while expiry_mth>12
                % %                             expiry_mth = expiry_mth - 12;
                % %                             expiry_yr = expiry_yr + 1;
                % %                         end
                % %
                % %                         % SETTING THE TIME TO MATURITY BEING WORKED OUT
                % %                         expiry = [num2str(expiry_mth),'/',num2str(expiry_yr)];
                % %
                % %                         current_date = P(t,1);
                % %                         current_price = round(P(t,2),dec_digits);
                % %
                % %                         % size of the price increase used to find the nearest
                % %                         % strike (it is a function of dec_digits)
                % %                         p_increase = 1./(10.^dec_digits);
                % %
                % %                         % identifying target strikes to be used to download call
                % %                         % prices (for strikes above current mkt price of the underlying)
                % %                         TargetStrikeDOWN = current_price;
                % %                         TargetStrikeUP = round(V.MoneynessLimits(2).*current_price,dec_digits);
                % %                         opttype = 'C';
                % %                         [CallStrikes,CallOptPrices,CallTimes2Expiry,CallExpiries,CallOptTickers] = V.GetOptionsStrip(DataFromBBG,option_ticker,expiry,opttype, ...
                % %                             P(t,1),p_increase,V.fields2download_2,V.fields2download_static_data,min_strike_increase,TargetStrikeUP,TargetStrikeDOWN);
                % %                         CallTimes2Expiry_yrs = CallTimes2Expiry./365;
                % %
                % %                         % doing the same for put options
                % %                         % identifying target strikes to be used to download call
                % %                         % prices (for strikes below current mkt price of the underlying)
                % %                         TargetStrikeDOWN = round(V.MoneynessLimits(1).*current_price,dec_digits);
                % %                         TargetStrikeUP = current_price;
                % %                         opttype = 'P';
                % %                         [PutStrikes,PutOptPrices,PutTimes2Expiry,PutExpiries,PutOptTickers] = V.GetOptionsStrip(DataFromBBG,option_ticker,expiry,opttype, ...
                % %                             P(t,1),p_increase,V.fields2download_2,V.fields2download_static_data,min_strike_increase,TargetStrikeUP,TargetStrikeDOWN);
                % %                         PutTimes2Expiry_yrs = PutTimes2Expiry./365;
                % %
                % %                         % if there is no data go ahead
                % %                         if isempty(CallOptPrices) | isempty(PutOptPrices) ...
                % %                                 | isempty(CallExpiries) | isempty(PutExpiries) % if already expired we could have prices, but not expiry dates
                % %                             continue
                % %                         end
                % %
                % %                         % derive times 2 expiries from expiry dates if the tte
                % %                         % field is NaN (from Bloomberg): could also use this
                % %                         % approach always !!! (... inherited from old versione of
                % %                         % code)
                % %                         nan_CallTimes2Expiry_yrs = find(isnan(CallTimes2Expiry_yrs));
                % %                         if ~isempty(nan_CallTimes2Expiry_yrs)
                % %                             CallTimes2Expiry_yrs(nan_CallTimes2Expiry_yrs) = ((CallExpiries - current_date)./365);
                % %                         end
                % %                         nan_PutTimes2Expiry_yrs = find(isnan(PutTimes2Expiry_yrs));
                % %                         if ~isempty(nan_PutTimes2Expiry_yrs)
                % %                             PutTimes2Expiry_yrs(nan_PutTimes2Expiry_yrs) = ((PutExpiries - current_date)./365);
                % %                         end
                % %
                % %                         % deriving implied volatilities from call and put prices
                % %                         CallsImpVolatility = blsimpv(P(t,2), CallStrikes, rfr, CallTimes2Expiry_yrs, CallOptPrices, [], yield, [], true(1));
                % %                         PutsImpVolatility = blsimpv(P(t,2), PutStrikes, rfr, PutTimes2Expiry_yrs, PutOptPrices, [], yield, [], false(1));
                % %
                % %                         % derive relative moneynesses for calls and puts
                % %                         % downloaded above
                % %                         eff_monenyness_calls = CallStrikes./current_price;
                % %                         eff_monenyness_puts = PutStrikes./current_price;
                % %
                % %                         % place calls implied volatility in the output matrices in
                % %                         % a position that is the closest to the corresponding
                % %                         % level of monenyness
                % %                         for k=1:size(eff_monenyness_calls,1)
                % %                             [mn,mni] = min(abs(eff_monenyness_calls(k) - Moneyness_Vector)); % identify the position corresponding to the closest monenyness
                % %                             V.OptMktPrices(mni,n,t) = CallOptPrices(k);
                % %                             V.MktImpliedVolas(mni,n,t) = CallsImpVolatility(k);
                % %
                % %                             V.Strikes(mni,n,t) = CallStrikes(k);
                % %                             V.Time2Maturity(:,n,t) = CallTimes2Expiry_yrs(k); % this is constant for current n,t
                % %                             V.Moneyness_Vector_ABSlog(mni,n,t) = log(CallStrikes(k)) - log(P(t,2));
                % %                         end
                % %
                % %                         % ... do the same for puts
                % %                         for k=1:size(eff_monenyness_puts,1)
                % %                             [mn,mni] = min(abs(eff_monenyness_puts(k) - Moneyness_Vector)); % identify the position corresponding to the closest monenyness
                % %                             V.OptMktPrices(mni,n,t) = PutOptPrices(k);
                % %                             V.MktImpliedVolas(mni,n,t) = PutsImpVolatility(k);
                % %                             V.Strikes(mni,n,t) = PutStrikes(k);
                % %                             V.Time2Maturity(:,n,t) = PutTimes2Expiry_yrs(k);
                % %                             V.Moneyness_Vector_ABSlog(mni,n,t) = log(PutStrikes(k)) - log(P(t,2));
                % %                         end
                % %
                % %                         % interpolate over moneyness dimension to fill zero values
                % %                         % for current n (time to expiry) and t (date to which data
                % %                         % refers to)
                % %                         fz = find(V.MktImpliedVolas(:,n,t)==0); % zeros values
                % %                         fnz = find(V.MktImpliedVolas(:,n,t)~=0); % non zero values
                % %                         moneyness = Moneyness_Vector;
                % %                         % TODO: REVIEW THIS
                % %                         if ~isempty(fz)
                % %                             x = moneyness(fnz);
                % %                             y = V.MktImpliedVolas(fnz,n,t);
                % %                             xq = moneyness(fz);
                % %                             V.MktImpliedVolas(fz,n,t) = interp1(x,y,xq,'linear','extrap');
                % %
                % %                             y = V.Moneyness_Vector_ABSlog(fnz,n,t);
                % %                             V.Moneyness_Vector_ABSlog(fz,n,t) = interp1(x,y,xq,'linear','extrap');
                % %                         end
                % %
                % %                         % *********************************************************
                % %                     end % n (no of fixed times to expiry used)
                % %                 end % t (historical calibration window)
                
            elseif  strcmp(V.DataSource,'MDS') % **************************
                % data from MDS: we get implied volas directly
                disp(['Retrieving BLS implied vola from from MDS s mkt option prices for ',option_ticker]);
                
                
                if datenum(V.HistDates.start)>datenum('07/31/2015')
                    V.TimeToExpiry = V.TimeToExpiry_Mds_2;
                    ttm = V.TimeToExpiry_Mds_2;
                    moneyness = V.Moneyness_Vector_Mds_2;
                else
                    V.TimeToExpiry = V.TimeToExpiry_Mds_1;
                    ttm = V.TimeToExpiry_Mds_1;
                    moneyness = V.Moneyness_Vector_Mds_1;
                end
                V.MoneynessLimits = [moneyness(1) moneyness(2)];
                V.Moneyness_Vector = moneyness;
                uparams.DataFromMDS = DataFromMDS;
                uparams.dataType = 'VolaData';
                uparams.nameEntity = option_ticker;
                uparams.category = 'Equity';
                uparams.startDate = datestr(datenum(V.HistDates.start),'yyyy-mm-dd');
                uparams.endDate =  datestr(datenum(V.HistDates.end),'yyyy-mm-dd');
                uparams.ttm = ttm;
                uparams.moneyness = moneyness;
                uparams.dataType = 'VolaData';
                U = Utilities(uparams);
                U.GetMdsData;
                
                V.MktImpliedVolas = U.Output.VolaSurfaceHistory.VolaSurfaceTimeSeries./100; % output needed to calibrate the model (Mds vola data are in pct format)
                V.MktImpliedVolasHistoricalDates = U.Output.VolaSurfaceHistory.TradeDates;
                
                t = size(V.MktImpliedVolas,2); % time to maturity dimension
                m = size(V.MktImpliedVolas,1); % moneyness dimension
                
                T = size(V.MktImpliedVolas,3); % length of history
                V.Time2Maturity = zeros(size(V.MktImpliedVolas));
                V.Moneyness_Vector_ABSlog = zeros(size(V.MktImpliedVolas));
                
                V.Time2Maturity = repmat(ttm',1,m,T);
                V.Moneyness_Vector_ABSlog = repmat(moneyness,t,1,T) - 1;
                
                
            end % input on DataSource
            
            disp('done: Vola Surface check')
        end
        
        
        function CalibrateSkewParams(V,calibration)
            % calibrating the 2 parameters alfa and beta on the hist
            % implied vola structure
            % choice: only 1 available for now
            % e.g. V.CalibrateSkewParams(1)
            V.Calibration = calibration; % type of calibration
            moneynessPointsNum = size(V.MktImpliedVolas,1);
            expiryPointsNum = size(V.MktImpliedVolas,2);
            tradingDaysNum = size(V.MktImpliedVolas,3);
            % put in ATM_MktVol each one of the fixed times to expiry in
            % V.TimeToExpiry, stacking in this single vector data from all
            % the trading days within the horizon taken into consideration.
            ATM_MktVol_idx = find(V.Moneyness_Vector == 1);
            ATM_MktVol = [];
            rATM_MktVol = [];
            for k=1:tradingDaysNum % for each one of the trading days used to estimate the surface
                % ATM_MktVol = [ATM_MktVol;V.MktImpliedVolas(ATM_MktVol_idx,:,k)'];
                ATM_MktVol = V.MktImpliedVolas(ATM_MktVol_idx,:,k); % ATM volas traded on the k-th day across all expiries
                rATM_MktVol = [rATM_MktVol;repmat(ATM_MktVol,moneynessPointsNum,1)];
            end
            % exluding zero columns (time 2 maturities for which we do not
            % have data) from th estimation
            zerocols = find(sum(rATM_MktVol)==0);
            nonzerocols = find(sum(rATM_MktVol)~=0);
            
            rATM_MktVol(:,zerocols) = [];
            % Stacking into a single 2D matrix data in MktImpliedVolas that
            % refers to different trading days (3rd dimension)
            % ... and the same for V.Time2Maturity and V.Strikes
            MktImpliedVolas_hist = [];
            Time2Maturity_hist = [];
            %            Strikes_hist = [];
            Moneyness_Vector_ABSlog_hist = [];
            for k=1:tradingDaysNum % for each one of the trading days used to estimate the surface
                MktImpliedVolas_hist = [MktImpliedVolas_hist;V.MktImpliedVolas(:,nonzerocols,k)];
                Time2Maturity_hist = [Time2Maturity_hist;V.Time2Maturity(:,nonzerocols,k)];
                %                Strikes_hist = [Strikes_hist;V.Strikes(:,:,k)];
                Moneyness_Vector_ABSlog_hist = [Moneyness_Vector_ABSlog_hist;V.Moneyness_Vector_ABSlog(:,nonzerocols,k)];
            end
            V.MoneynessAbsLogMinBoundary = min(min(Moneyness_Vector_ABSlog_hist));
            V.MoneynessAbsLogMaxBoundary = max(max(Moneyness_Vector_ABSlog_hist));
            
            if strcmp(calibration,'one_for_all_TTE')
                % objective f (for a given TTE and Call/put indicator)
                x0 = [0 0]; % initial guess
                options = optimoptions('fminunc','Algorithm','quasi-newton');
                
                [x,funval] = fminunc(@vol,x0,options);
                V.alfa = x(1);
                V.beta = x(2);
                V.X = x;
                
                % choice 2: 2 params per each ********************************
            elseif strcmp(calibration,'one_for_each_TTE')
                
                skewsParamByExpiry = cell(expiryPointsNum,1);
                % Here we calibrate a skew for each expiry
                for k=1:expiryPointsNum
                    volaDatas.MktImpliedVolas_hist_byExpiry = MktImpliedVolas_hist(:,k);
                    volaDatas.rATM_MktVol_byExpiry = rATM_MktVol(:,k);
                    volaDatas.Time2Maturity_hist_byExpiry = Time2Maturity_hist(:,k);
                    volaDatas.Moneyness_Vector_ABSlog_hist_byExpiry = Moneyness_Vector_ABSlog_hist(:,k);
                    
                    x0 = [0 0]; % initial guess
                    options = optimoptions('fminunc','Algorithm','quasi-newton');
                    
                    [x,funval] = fminunc(@vol_byExpiry,x0,options);
                    % k-th row of skewsParamByExpiry contains the couple of
                    % calibrated parameters for the k-th expiry skew
                    skewsParamByExpiry(k,:) = {x};
                end
                % Draw che resulting impl. vola surface
                V.Data4SurfaceDrawing.skewsParamByExpiry = skewsParamByExpiry;
                V.Data4SurfaceDrawing.volaDatas = volaDatas;
                V.Data4SurfaceDrawing.Time2Maturity_hist = Time2Maturity_hist;
                V.Data4SurfaceDrawing.ATM_MktVol = ATM_MktVol;
                V.skewsParamByExpiry = skewsParamByExpiry;
            end
            
            % **** NO MORE USED ****
            %             if V.SaveParams.flag==0
            %                 undticker = strrep(V.Underlying_Ticker,' ','_');
            %                 undticker = strrep(undticker,'\','_');
            %                 undticker = strrep(undticker,'/','_');
            %                 filename = [V.SaveParams.folder,undticker,'_SavedVolaObj.mat'];
            %                 objToSave = V;
            %                 warning off;
            %                 save(filename,'objToSave'); % saving the obj to the disk
            %                 warning on;
            %             end
            
            
            function f = vol(x)
                f = sum(nansum((MktImpliedVolas_hist - (rATM_MktVol ...
                    +(x(1)./(Time2Maturity_hist).^0.5).*(Moneyness_Vector_ABSlog_hist) ...
                    + (x(2)./(Time2Maturity_hist)).*(Moneyness_Vector_ABSlog_hist).^2)).^2));
            end % vol
            
            function f = vol_byExpiry(x)
                f = sum(nansum((volaDatas.MktImpliedVolas_hist_byExpiry - (volaDatas.rATM_MktVol_byExpiry ...
                    + (x(1)./(volaDatas.Time2Maturity_hist_byExpiry).^0.5).*(volaDatas.Moneyness_Vector_ABSlog_hist_byExpiry) ...
                    + (x(2)./(volaDatas.Time2Maturity_hist_byExpiry)).*(volaDatas.Moneyness_Vector_ABSlog_hist_byExpiry).^2)).^2));
            end
            
        end % method CalibrateSkewParams
        
        
        function DrawSkewsSurface(V,parameters, MonABSLog_byExpiry, TTExpiries, AtmVola_byExpiry)
            
            if strcmp(V.Calibration,'one_for_each_TTE')
                
                for k = 1:numel(parameters)
                    param = parameters{k};
                    f1 = @(x) AtmVola_byExpiry(k) + param(1)*x + param(2)*(x.^2);
                    skewsSurface(:,k) = f1(MonABSLog_byExpiry);
                end
                
                [TTE_grid,MonABSLog_grid] = meshgrid(TTExpiries,MonABSLog_byExpiry);
                figure;
                surf(TTE_grid,MonABSLog_grid,skewsSurface)
                VolaName = strrep(V.Name,'_',' ');
                xlabel('TtE (yrs)')
                ylabel('Moneyness')
                zlabel(VolaName)
                figure;
                plot(MonABSLog_byExpiry,skewsSurface(:,1))
                xlabel('Moneyness')
                ylabel([VolaName '- nearest TTE'])
                
            else
                disp('Cannot invoke this method when Calibration type is not -one_for_each_TTE-');
            end
            
        end
        
        function DrawEstimatedSkew(V,ATMVol,UnderlyingCurrent,tte)
            % to be completed
            
            % this function draws an estimated vola surface
            % INPUTS:
            % ATMVol: ATM Vola
            % UnderlyingCurrent = current level of the underlying (must be
            % consistent with ATMVol)
            % ex: to invoke the method V.DrawEstimatedSurface(0.2,3000)
            
            if strcmp(V.Calibration,'one_for_each_TTE')
                params = cell2mat(V.skewsParamByExpiry);
%                 alfa = interp1(V.TimeToExpiry_BBG',params(:,1),tte);
%                 beta = interp1(V.TimeToExpiry_BBG',params(:,2),tte);
                alfa = params(:,1);
                beta = params(:,2);
            elseif strcmp(V.Calibration,'one_for_all_TTE')
                alfa = V.alfa;
                beta = V.beta;
            end
            
            T = V.TimeToExpiry_BBG';
            n = numel(T);
            f = @(ATMvol,U,T,K) ATMvol + (repmat((log(K) - log(U)),n,1)./(repmat(T.^0.5,1,numel(K)))).*(repmat(alfa,1,numel(K))) ...
                + repmat((log(K) - log(U)).^2,n,1)./(repmat(T,1,numel(K))).*(repmat(beta,1,numel(K)));
            
            U = UnderlyingCurrent;
            % * K = [U.*V.MoneynessLimits(1):V.MinStrikeIncrease:U.*V.MoneynessLimits(2)]';
            K = linspace(U.*V.MoneynessLimits(1),U.*V.MoneynessLimits(2),20);
            
            [X,Y] = meshgrid(T,K);
            Z = f(ATMVol,UnderlyingCurrent,T,K);
            figure;
            surf(X,Y,Z)
            hold on;
            % add to the plot a point identifying current underlying's
            % price (TODO: REVIEW)
            %           rU = ones(size(T,1),1).*U;
            %           plot3(T,rU,f(ATMVol,UnderlyingCurrent,T,rU),'Color','r','LineWidth',4)
        end
        
        function iv = GetAdjIV_Estimates(V,TTe,ATM,K,U)
            % this methods calculates the implied vola taking into account the
            % parametrized skew.
            % INPUTS:
            % TTe: constant time to expiry
            % ATM: current 'raw' ATM vola
            % K: option's strike price
            % U: current underlying's price
            % ATM, K and U can be vectors (same length): in this case the
            % output will be a vector of the same length
            if strcmp(V.Calibration,'one_for_each_TTE')
                tteVector_yrs = V.Time2Maturity(1,:)';
                params = cell2mat(V.skewsParamByExpiry);
                % interpolate in time dimension (do not extrapolate)
                if TTe<tteVector_yrs(1)
                    alfa = params(1,1);
                    beta = params(1,2);
                elseif TTe>tteVector_yrs(end)    
                    alfa = params(end,1);
                    beta = params(end,2);
                else
                    alfa = interp1(tteVector_yrs,params(:,1),TTe);
                    beta = interp1(tteVector_yrs,params(:,2),TTe);
                end
            elseif strcmp(V.Calibration,'one_for_all_TTE')
                alfa = V.alfa;
                beta = V.beta;
            end
            
            absLogMonenyness = log(K) - log(U);
            % uncomment to limit the abs log moneyness to the extremes upon
            % which parameters have been estimated
            %             absLogMonenyness(absLogMonenyness<V.MoneynessAbsLogMinBoundary) = V.MoneynessAbsLogMinBoundary;
            %             absLogMonenyness(absLogMonenyness>V.MoneynessAbsLogMaxBoundary) = V.MoneynessAbsLogMaxBoundary;
            
            f = @(ATMvol,T) ATMvol + (alfa./(T.^0.5)).*(absLogMonenyness) ...
                + (beta./(T)).*(absLogMonenyness).^2;
            iv = f(ATM,TTe);
            % TODO: PARAMETRIZE THIS FLOOR. REFINE THE FUNCTION WITH NON
            % NEG CONSTRAINTS
            iv(iv<=0) = 0.05;
        end
        
        function GetExtendedIV(V,DataFromBBG,histEstimWindow,und_hist_dates,und_hist_returns)
            % >> When data_source = 'BBG'
            % the purpose of this function is to download historical ATM
            % volatilities that will be used to estimate the historical
            % volatility surface based on the optimal parameters obtained
            % through the method CalibrateSkewParams.
            % This method is invoked when data_source = 'BBG', that means
            % that we do not have (like when using MDS as data source) the
            % historical volatility surfaces and want to estimate it using
            % the approximation based on the function used in CalibrateSkewParams
            % *** LOGIC ***
            % Here we want to be able to use the method
            % .GetAdjIV_Estimates(V,TTe,ATM,K,U) to estimate the historical
            % vola surface. To this purpose we need ATM, that is a vector
            % of historical implied volatilities upon which the estimate
            % of the hist surface will be based. To get the hist ATM volas we
            % need to 'decide' which ATM vola to use based on time to expiry.
            % Also, some preprocessing will be used to fill
            % gaps in BBG data and remove outliers, similarly to what was
            % done in the old class Option_Vanilla_ApproxSurface. This
            % function, indeed, is written within an effort made to get rid
            % of the class Option_Vanilla_ApproxSurface and use
            % Option_Vanilla only, that is better and able to deal with option
            % with both constant time to maturity and fixed maturity. BUT to be
            % able to always use the class Option_Vanilla  we need to
            % reproduce an historical surface like if we were working with
            % MDS data. So the final purpose of this method is to fill the
            % properties MktImpliedVolas and MktImpliedVolasHistoricalDates
            %
            % >> When data_source = 'MDS'
            % In this case the historical volatility surfaces are already
            % available from Market data server, but there is the
            % possibility to extend the historical time series building the
            % Implied Volatility proxy (buildVolaProxy method)
            %
            % **** INPUTS ****:
            % -> DataFromBBG: Bloomberg struct (connection to BBG terminal)
            % -> histEstimWindow: struct array witrh fields .start and .end
            % containing the start/end date of the hisotrical window over
            % which the vola surface needs to be estimated (normally these
            % are the same historical start/end dates used within the AA
            % process
            % -> und_hist_dates: hist dates for the undelrying's returns.
            % This is needed to understand which dates (if any) must be filled
            % through pre-processing operations. This information is
            % provided when the method is invoked
            % -> und_hist_returns: hist returns for the underlying
            %
            % **** OUTPUTS **** :
            % >> When data_source = 'BBG'
            % -> V.ImpliedAtmVola_Preprocessed: intermediate output from steps
            % 1) and 2) below (to avoid executing them more then once,
            % since this method can be invoked from within several
            % instances of the class Option_Vanilla)
            %
            % >> When data_source = 'MDS'
            % -> V.proxyMDS_Flag: set as true(1) when the proxy has been
            % built
            % -> The following variable are adjusted according to the new
            % proxy: V.MktImpliedVolasHistoricalDates, V.MktImpliedVolas,
            % V.Time2Maturity, V.Moneyness_Vector_ABSlog
            
            
            filledDataMap = V.FilledDataMap;
            filledDataMapExists = true;
            
            % STRUCT fillOutliers_params:
            fillOutliers_params.FillMethod = 'previous'; % Fill with previous non-outlier entry.
            fillOutliers_params.MOVMETHOD = 'movmedian'; % Moving window method to find contextual outliers
            fillOutliers_params.WL = 60; % Length of the moving window
            fillOutliers_params.ThresholdFactor = 'ThresholdFactor'; % modifies the outlier detection thresholds
            fillOutliers_params.ThresholdFactorValue = 8; % New thresholdFactor value
            
            if strcmp(V.DataSource,'BBG') % Bloomberg Data Source
                
                % ************************************************ ************
                % 1) Getting hist ATM volas for all maturities (available via
                % BBG terminal) ***********************************************
                
                % BBG data download will be done for both calls and puts: then
                % an average will be taken
                
                % Do not execute if we already have these preprocessed data
                if isempty(V.ImpliedAtmVola_Preprocessed)
                    
                    % OPTION Maturities associated to the ATM implied volas
                    % used below (expressed in year fractions terms)
                    maturities = [30/365 3/12 6/12 12/12 18/12 24/12]';
                    
                    % OPTION Type
                    opttype{1} = ['PUT'];
                    opttype{2} = ['CALL'];
                    
                    % % NOT USED: the realizedVola_Prices loop has been
                    % moved outside the loop over n, so at the moment we
                    % use a single lag (see lagMap(1) below)
                    tenorKey   = [1,2,3,4,5,6];
                    tenorValue = [20,20,20,20,20,20];
                    lagMap = containers.Map(tenorKey,tenorValue);
                    
                    % REGRESSOR: Realized Vola
                    % this is common to all the dependent variables estimated below
                    t = size(und_hist_dates,1);
                    lag = lagMap(1);
                    proxyParams.lag = lag;
                    realizedVola_Prices = zeros(t,1);
                    for k=lag+1:t
                        realizedVola_Prices(k,1) = std(und_hist_returns(k-lag:k,1)) * (252.^0.5);
                    end
                    realizedVola_Prices = [und_hist_dates, realizedVola_Prices];
                    realizedVola_Prices = realizedVola_Prices(lag+1:end,:); % removing initial 0's
                    
                    n_opttype = numel(opttype);
                    for nt=1:n_opttype % for each type
                        type = opttype(nt);
                        
                        tenorStr{1} = [type{1},'_IMP_VOL_30D'];
                        tenorStr{2} = ['3MO_',type{1},'_IMP_VOL'];
                        tenorStr{3} = ['6MO_',type{1},'_IMP_VOL'];
                        tenorStr{4} = ['12MO_',type{1},'_IMP_VOL'];
                        tenorStr{5} = ['18MO_',type{1},'_IMP_VOL'];
                        tenorStr{6} = ['24MO_',type{1},'_IMP_VOL'];
                        
                        for n=1:numel(tenorStr) % for each maturity
                            
                            IV_field_BBG = tenorStr{n};
                            ticker = V.Underlying_Ticker;
                            
                            % Getting Historical Data through
                            % an instance of class Utilities
                            uparam.DataFromBBG = DataFromBBG;
                            uparam.ticker = ticker;
                            uparam.fields = IV_field_BBG;
                            uparam.history_start_date = histEstimWindow.start;
                            uparam.history_end_date = histEstimWindow.end;
                            uparam.granularity = ['daily'];
                            U = Utilities(uparam);
                            U.GetHistPrices;
                            iv_hist = U.Output.HistInfo;
                            iv_hist(:,2) = iv_hist(:,2)./100; % as BBG data are in annualized % format
                            
                            
                            % *****************************************************************
                            % 2) data cleansing and cleaning **********************************
                            % *****************************************************************
                            % *** Regression on realized volatility to fill in ****************
                            % *** missing data in the history of implied volatility ***********
                            % *** compared to the history of the underlying         ***********
                            
                            % TODO: *******
                            % 1) here some forward bias can be introduced
                            % some of the filled holes are past the historical dataset used
                            % to estimate the relation between implied and realized vola
                            % 2) can implement more sophisticated forms of regression
                            % (Kalman filter could be useful as well)
                            
                            % compute the set of historical data on the
                            % underlying that is relevant to the filling
                            % procedure below: I do not want to fill
                            % datapoints in implied vola that precede the
                            % first historical available data. To this
                            % purpose, more in general, when strictly needed
                            % we can use the DAA_params.InvariantBackwardsProxy flag
                            % und_hist_returns = und_hist_returns_initialInput(und_hist_dates_initialInput >= iv_hist_dates(1));
                            % und_hist_dates = und_hist_dates_initialInput(und_hist_dates_initialInput >= iv_hist_dates(1));
                            
                            fillAndMap_flag = false(1);
                            
                            % Missing dates in iv history
                            missing_iv_dates = setdiff(und_hist_dates, iv_hist(:,1));
                            miss_orig = length(missing_iv_dates);
                            % Checking missing values
                            if ~isempty(missing_iv_dates)
                                % Create TimeSeriesData Object
                                TSD = TimeSeriesData(V.DataSource, ...
                                    ticker, ...
                                    type, ...
                                    maturities(n), ...
                                    fillOutliers_params, ...
                                    proxyParams);
                                
                                % Compute HashCode
                                hashKey = TSD.hash;
                                % Check if .mat file exists
                                if filledDataMapExists
                                    if isKey(filledDataMap, hashKey) % Found previous data, Load It
                                        % Read saved iv_hist
                                        iv_hist = filledDataMap(hashKey);
                                        % Compute new missing dates array
                                        missing_iv_dates = setdiff(und_hist_dates, iv_hist(:,1));
                                        
                                        % removing NaN values
                                        % introduced when data were
                                        % saved in the map (see comment
                                        % {'cheating' the map}) to restore
                                        % the 'ordinary' workflow
                                        fnan = find(isnan(iv_hist(:,2)));
                                        iv_hist(fnan,:) = [];
                                        
                                        if ~isempty(missing_iv_dates)
                                            %                                             % Compute new fillings
                                            %                                             iv_hist = buildVolaProxy(V, ticker, realizedVola_Prices, iv_hist);
                                            %                                             % Put Updated Fillings in the map
                                            %                                             filledDataMap(hashKey) = iv_hist;
                                            %                                             disp(['Update map (BBG): ',  ticker, ' - ',hashKey]);
                                            
                                            fillAndMap_flag = true(1);
                                        else
                                            disp(['Map is up to date (BBG): ', ticker, ' - ', hashKey]);
                                        end
                                    else % No Data Computed
                                        %                                         % Compute new fillings
                                        %                                          iv_hist = buildVolaProxy(V, ticker, realizedVola_Prices, iv_hist);
                                        %                                          % Put Updated Fillings in the map
                                        %                                          filledDataMap(hashKey) = iv_hist;
                                        %                                          disp(['Update map (BBG): ', ticker, ' - ', hashKey]);
                                        
                                        fillAndMap_flag = true(1);
                                    end % End If isKey
                                end % if on filledDataMapExists
                            end % End If on ~isempty(missing_iv_dates)
                            
                            if fillAndMap_flag
                                % ***
                                % Compute new fillings
                                iv_hist = buildVolaProxy(V, ticker, realizedVola_Prices, iv_hist);
                                % ******* 'cheating' the map **********
                                % during the regression process some
                                % 'dates' (within the initial und_hist_dates)
                                % are lost due to intersections
                                % performed between dependent and
                                % independent variables dates vectors.
                                % Here I need to reintroduce them into
                                % the timeseries saved within the map
                                % to be able to match dates
                                % und_hist_dates with the saved dataset
                                % the next that the code is executed)
                                [ignoredDates,iidx] = setdiff(und_hist_dates,iv_hist(:,1));
                                residualNaNs = [ignoredDates,nan(numel(ignoredDates),1)];
                                tmp = [iv_hist;residualNaNs];
                                [tmp_sorted,idx_sorted] = sort(tmp(:,1));
                                iv_hist_withNaN = tmp(idx_sorted,:);
                                % ************************************
                                
                                % Add object to map
                                filledDataMap(hashKey) = iv_hist_withNaN;
                                disp(['Added to map (BBG): ', ticker, ' - ', hashKey]);
                                
                                % ***
                            end
                            
                            %  *** End of Regression of Implied vola on Realized one **********
                            % *****************************************************************
                            
                            
                            NaN_beforeOutliersMgmt = any(isnan(iv_hist(:,2)));
                            % *****************  outliers processing **********************
                            iv_hist(:,2) = filloutliers(((iv_hist(:,2))), ...
                                fillOutliers_params.FillMethod, ...
                                fillOutliers_params.MOVMETHOD, ...
                                fillOutliers_params.WL, ...
                                fillOutliers_params.ThresholdFactor, ...
                                fillOutliers_params.ThresholdFactorValue);
                            % *************************************************************
                            NaN_afterOutliersMgmt = any(isnan(iv_hist(:,2)));
                            % remove anu NaN induced by outliers mgmt
                            if ~NaN_beforeOutliersMgmt & NaN_afterOutliersMgmt
                                fnan = find(isnan(iv_hist(:,2)));
                                iv_hist(fnan,:)=[];
                            end
                            
                            % Partial Output
                            partialOutput.(type{1}){n} = iv_hist;
                            
                        end % loop on possible times to maturity
                        
                    end % loop on opttype
                    
                    % need to perform intersection on dates, since we could
                    % have partialOutputs timeseries of different dimensions
                    clear upar;
                    upar.inputTS = [partialOutput.CALL,partialOutput.PUT]';
                    upar.op_type = ['intersect'];
                    Util = Utilities(upar);
                    Util.GetCommonDataSet;
                    % Averaging call and put data
                    data = Util.Output.DataSet.data;
                    nc = size(data,2);
                    data = (data(:,[1:1:nc/2]) + data(:,[nc/2+1:1:nc]))./2;
                    
                    V.ImpliedAtmVola_Preprocessed.maturities = maturities;
                    V.ImpliedAtmVola_Preprocessed.dates = Util.Output.DataSet.dates;
                    V.ImpliedAtmVola_Preprocessed.data = data;
                    
                end % if on V.ImpliedAtmVola_Preprocessed being not empty
                
            elseif strcmp(V.DataSource,'MDS')
                
                % Do not execute if we already have these proxy data
                if ~V.proxyMDS_Flag
                    
                    % Store implied volatilities from MDS (it could be useful
                    % to compare the MDS original data with the proxy one)
                    V.MktImpliedVolas_raw = V.MktImpliedVolas;
                    V.MktImpliedVolasHistoricalDates_raw = V.MktImpliedVolasHistoricalDates;
                    
                    disp('Method EstimateHistoricalSurface of class ImpliedVola_Surface');
                    
                    ticker = V.Underlying_Ticker;
                    maturities = V.TimeToExpiry;
                    moneyness = V.Moneyness_Vector;
                    iv_data = V.MktImpliedVolas;
                    iv_dates = V.MktImpliedVolasHistoricalDates;
                    ndate = numel(iv_dates);
                    
                    % % NOT USED: the realizedVola_Prices loop has been
                    % moved outside the loop over n, so at the moment we
                    % use a single lag (see lagMap(1) below)
                    tenorKey   = [1,2,3,4,5,6,7,8];
                    tenorValue = [20,20,20,20,20,20,20,20];
                    lagMap = containers.Map(tenorKey,tenorValue);
                    
                    % REGRESSOR: Realized Vola
                    % this is commonf to all the dependent variables estimated below
                    t = size(und_hist_dates,1);
                    lag = lagMap(1);
                    proxyParams.lag = lag;
                    realizedVola_Prices = zeros(t,1);
                    for k=lag+1:t
                        realizedVola_Prices(k,1) = std(und_hist_returns(k-lag:k,1)) * (252.^0.5);
                    end
                    realizedVola_Prices = [und_hist_dates, realizedVola_Prices];
                    realizedVola_Prices = realizedVola_Prices(lag+1:end,:); % removing initial 0's
                    
                    for n=1:numel(maturities) % for each maturity
                        
                        for m=1:numel(moneyness) % for each moneyness
                            
                            iv_hist = [iv_dates, reshape(iv_data(n,m,:), ndate, 1)];
                            
                            % Missing dates in iv history
                            missing_iv_dates = setdiff(und_hist_dates,iv_hist(:,1));
                            
                            fillAndMap_flag = false(1);
                            
                            % *****************************************************************
                            % ** data cleansing and cleaning **********************************
                            % *****************************************************************
                            % *** Regression on realized volatility to fill in ****************
                            % *** missing data in the history of implied volatility ***********
                            % *** compared to the history of the underlying         ***********
                            
                            
                            % Checking missing values
                            if ~isempty(missing_iv_dates)
                                % Create TimeSeriesData Object
                                TSD = TimeSeriesData(V.DataSource, ...
                                    ticker, ...
                                    ' ', ...
                                    maturities(n), ...
                                    fillOutliers_params, ...
                                    proxyParams);
                                % Compute HashCode
                                hashKey = TSD.hash;
                                % Check if .mat file exists
                                if filledDataMapExists
                                    if isKey(filledDataMap, hashKey) % Found previous data, Load It
                                        % Read saved iv_hist
                                        iv_hist = filledDataMap(hashKey);
                                        % Compute new missing dates array
                                        missing_iv_dates = setdiff(und_hist_dates, iv_hist(:,1));
                                        
                                        % removing NaN values
                                        % introduced when data were
                                        % saved in the map (see comment
                                        % {'cheating' the map}) to restore
                                        % the 'ordinary' workflow
                                        fnan = find(isnan(iv_hist(:,2)));
                                        iv_hist(fnan,:) = [];
                                        
                                        if ~isempty(missing_iv_dates)
                                            %                                             % Compute new fillings
                                            %                                             iv_hist = buildVolaProxy(V, ticker, realizedVola_Prices, iv_hist);
                                            %                                             % Put Updated Fillings in the map
                                            %                                             filledDataMap(hashKey) = iv_hist;
                                            %                                             disp(['Updated map (MDS): ', ticker, ' - ', hashKey]);
                                            
                                            fillAndMap_flag = true(1);
                                            
                                        else
                                            disp(['Map is up to date (MDS): ', ticker, ' - ', hashKey]);
                                        end
                                    else % No Data Computed
                                        %                                         % Compute new fillings
                                        %                                          iv_hist = buildVolaProxy(V, ticker, realizedVola_Prices, iv_hist);
                                        %                                          % Put Updated Fillings in the map
                                        %                                          filledDataMap(hashKey) = iv_hist;
                                        
                                        fillAndMap_flag = true(1);
                                    end % End If isKey
                                    
                                end % End If on filledDataMapExists
                            end % End If on ~isempty(missing_iv_dates)
                            
                            if fillAndMap_flag
                                % ***
                                % Compute fillings
                                iv_hist = buildVolaProxy(V, ticker, realizedVola_Prices, iv_hist);
                                
                                % Create map
                                filledDataMap = containers.Map();
                                % Set filledDataMapExists Flag as True
                                filledDataMapExists = true;
                                
                                % ******* 'cheating' the map **********
                                % during the regression process some
                                % 'dates' (within the initial und_hist_dates)
                                % are lost due to intersections
                                % performed between dependent and
                                % independent variables dates vectors.
                                % Here I need to reintroduce them into
                                % the timeseries saved within the map
                                % to be able to match dates
                                % und_hist_dates with the saved dataset
                                % the next that the code is executed)
                                [ignoredDates,iidx] = setdiff(und_hist_dates,iv_hist(:,1));
                                residualNaNs = [ignoredDates,nan(numel(ignoredDates),1)];
                                tmp = [iv_hist;residualNaNs];
                                [tmp_sorted,idx_sorted] = sort(tmp(:,1));
                                iv_hist_withNaN = tmp(idx_sorted,:);
                                % ************************************
                                
                                % Add object to map
                                filledDataMap(hashKey) = iv_hist_withNaN;
                                disp(['Added to map (MDS): ', ticker, ' - ', hashKey]);
                                % ***
                            end
                            
                            %  *** End of Regression of Implied vola on Realized one ***
                            % *************************************************************
                            
                            
                            NaN_beforeOutliersMgmt = any(isnan(iv_hist(:,2)));
                            % *****************  outliers processing **********************
                            iv_hist(:,2) = filloutliers(((iv_hist(:,2))), ...
                                fillOutliers_params.FillMethod, ...
                                fillOutliers_params.MOVMETHOD, ...
                                fillOutliers_params.WL, ...
                                fillOutliers_params.ThresholdFactor, ...
                                fillOutliers_params.ThresholdFactorValue);
                            % *************************************************************
                            NaN_afterOutliersMgmt = any(isnan(iv_hist(:,2)));
                            % remove anu NaN induced by outliers mgmt
                            if ~NaN_beforeOutliersMgmt & NaN_afterOutliersMgmt
                                fnan = find(isnan(iv_hist(:,2)));
                                iv_hist(fnan,:)=[];
                            end
                            
                            tmpOut = reshape(iv_hist(:,2),1,1,size(iv_hist,1));
                            
                            % Partial Output
                            if m==1
                                partialOutput = tmpOut;
                            else
                                partialOutput = [partialOutput, tmpOut];
                            end
                            
                        end % loop on possible moneyness
                        
                        % Final Output
                        if n==1
                            finalOutput = partialOutput;
                        else
                            finalOutput = [finalOutput; partialOutput];
                        end
                        
                        partialOutput = [];
                        
                        %                         figure;
                        %                         X_plot = repmat(iv_hist(:,1),1,m);
                        %                         Y_plot = repmat(moneyness,size(finalOutput,3),1);
                        %                         Z_plot = reshape(finalOutput(n,:,:),size(finalOutput,3),m,1);
                        %                         plot3(X_plot,Y_plot,Z_plot);
                        %                         grid on;
                        
                    end % loop on possible times to maturity
                    
                    V.proxyMDS_Flag = true(1);
                    V.MktImpliedVolasHistoricalDates = iv_hist(:,1);
                    V.MktImpliedVolas = finalOutput;
                    
                    d1 = size(V.MktImpliedVolas,1); % time to maturity dimension
                    d2 = size(V.MktImpliedVolas,2); % moneyness dimension
                    d3 = size(V.MktImpliedVolas,3); % length of history
                    
                    V.Time2Maturity = zeros(d1,d2,d3);
                    V.Moneyness_Vector_ABSlog = zeros(d1,d2,d3);
                    
                    V.Time2Maturity = repmat(maturities',1,d2,d3);
                    V.Moneyness_Vector_ABSlog = repmat(moneyness,d1,1,d3) - 1;
                    
                end % if on V.proxyMDS_Flag being not empty
                
            end % if data source is BBG or Market Data Server
            
            
        end % GetExtendedIV
        
        function iv_hist_out = buildVolaProxy(~, ticker, realizedVola_Prices, iv_hist)
            
            disp('Running rolling window based regression to fill Implied Vola timeseries');
            
            upar.data1 = realizedVola_Prices;
            upar.data2 = [];
            upar.lag = 1;
            upar.pct = 1;
            upar.logret = 1;
            upar.rolldates = [];
            upar.last_roll = 0;
            upar.EliminateFlag = 0;
            upar.ExtendedLag = 3;
            U = Utilities(upar);
            U.RetCalc;
            realizedVola_Returns = U.Output.CleanRet;
            realizedVola_Prices = U.Output.CleanPrices;
            % remove zero prices and corresponding returns
            fz = find(realizedVola_Prices(:,2)==0);
            realizedVola_Prices(fz,:) = [];
            realizedVola_Returns(fz,:) = [];
            
            % ASSET: Implied Vola
            impliedVola_Prices  = iv_hist;
            
            % get $ daily returns
            upar.data1 = impliedVola_Prices;
            upar.data2 = [];
            upar.lag = 1;
            upar.pct = 1;
            upar.logret = 1;
            upar.rolldates = [];
            upar.last_roll = 0;
            upar.EliminateFlag = 0;
            upar.ExtendedLag = 3;
            U = Utilities(upar);
            U.RetCalc;
            impliedVola_Returns = U.Output.CleanRet;
            impliedVola_Prices =  U.Output.CleanPrices;
            
            % *****************************************
            % remove large holes from implied vola data
            % (they are quite frequent for some stocks)
            % TODO: centralize all data cleansing
            done = false(1);
            while ~done
                ddays = [diff(impliedVola_Prices(:,1))]; % want to remove the starting point of every hole at each iteration
                flarge = find(ddays>30);
                if isempty(flarge); done=true(1); end
                impliedVola_Prices(flarge,:) = [];
                impliedVola_Returns(flarge,:) = [];
            end
            % *****************************************
            
            % Utilities params
            proxyParam.Asset_Name    = ticker;
            proxyParam.retType       = 'Log';
            proxyParam.Asset_Ret     = impliedVola_Returns;  % Implied Vola Returns: nx2 with returns of the Asset
            proxyParam.Asset_Price   = impliedVola_Prices;   % Implied Vola Prices: nx2 with prices of the Asset
            proxyParam.Regressor_Ret = realizedVola_Returns; % Realized Vola Returns: nx2 with returns of the Regressor
            proxyParam.chunkSize  = 40;
            proxyParam.firstCoeff = true(1); % true: apply alpha and beta of the first chunk to the past dates
            % TEMPORARY: WAITING TO IMPLEMENT A VARX MODEL
            proxyParam.useRegressor4BackwardProxy = true(1); % to fill past holes (where dependent variable data are not available) with the regressor (wout applying any beta)
            
            % Build Proxy (Prices and Returns)
            uObject = Utilities(proxyParam);
            uObject.buildEquityProxy;
            % Output
            iv_hist_Proxy = uObject.Output.Proxy_Price;
            
            % Proxy timeseries while preserving real available data
            [~ , pos]  = setdiff(iv_hist_Proxy(:,1),iv_hist(:,1)); % Using Prices from Invariants instead of S.History.Price.TimeSeries(:,1)
            newSeries  = [ iv_hist_Proxy(pos,:); iv_hist];
            [~ , sidx] = sort(newSeries(:,1));
            iv_hist_Proxy_Final  = newSeries(sidx,:);
            
            volaFloor = 0.07; % TODO: parametrize
            fneg = find(iv_hist_Proxy_Final(:,2)<=0);
            if ~isempty(fneg)
                iv_hist_Proxy_Final(fneg,2) = volaFloor;
                disp(['estimated implied vola floored to 7% for some dates']);
            end
            
            iv_hist_out = iv_hist_Proxy_Final;
            
            % Plot (for debuggging) *****************
            %                                 % 1) original asset
            %                                 Price_Orig  = impliedVola_Prices(:,end);
            %                                 Price_OrigD = impliedVola_Prices(:,1);
            %                                 Ret_Orig    = impliedVola_Returns(:,end);
            %                                 % 2) regressor asset
            %                                 Price_Regr  = realizedVola_Prices(:,end);
            %                                 Price_RegrD = realizedVola_Prices(:,1);
            %                                 % 3) proxy
            %                                 Price_Proxy  = iv_hist_Proxy_Final(:,end);
            %                                 Price_ProxyD = iv_hist_Proxy_Final(:,1);
            %                                 plot(Price_ProxyD, Price_Proxy, 'b', Price_OrigD, Price_Orig, 'r');
            %                                 title(['Orginal Asset:   ', strrep([proxyParam.Asset_Name, ' ', BBG_ticker{n}],'_',' ')]);
            %                                 legend('Proxy','Asset','Location','southoutside');
            %                                 axlim = get(gca, 'XLim');
            %                                 aylim = get(gca, 'YLim');
            %                                 x_txt = min(axlim) + 0.05*diff(aylim);
            %                                 y_txt = min(aylim) - 0.25*diff(aylim);
            %                                 y_txt1 = min(aylim) - 0.35*diff(aylim);
            %                                 text(x_txt, y_txt, ['Proxy size: ' num2str(size(Price_Proxy,1))]);
            %                                 text(x_txt, y_txt1, ['Asset size: ' num2str(size(Price_Orig,1))]);
            %
            %             elseif dataSource=='MDS'
            %
            %                 disp('ongoing');
            
            %            end
            
        end
        
        
        function [impliedVola] = ...
                EstimateHistoricalSurface(V,tte,strike,currentUnderlyingPrice,pricing_date,simulatedData_flag, simulated_ATMv)
            % Using the dataset created when the method
            % 'GetExtendedIV' was invoked (from within
            % ReadFromIU_inputFile) to build the historical volatility
            % surface for a specific options (this method is invoked from
            % within Option_Vanilla indeede)
            % **** INPUTS **** :
            % tte: time to expiry of the option
            % strike: option's strike
            % currentUnderlyingPrice: current underlying price
            % pricing_date: date of pricing
            % simulatedData_flag: its says whether we are working with
            % simulated or historical data (see below)
            % simulated_ATMv: simulated data needed when the previous
            % flag is set to 1
            
            % **** OUTPUTS **** :
            % -> impliedVola: estimated implied volatility for the date
            % 'pricing_date' to price the specific option that has called
            % this method
            
            % *************************************************
            % Estimation of historical surface ****************
            % *************************************************
            % here, given the ATM volas in
            % V.ImpliedAtmVola_Preprocessed, corresponding to the set
            % of maturities in
            % V.ImpliedAtmVola_Preprocessed.maturities, I want to
            % estimate the implied vola that takes into account the
            % skew (based on the skew parameters estimated within this
            % class) and that will be used for pricing.
            
            % selecting the ATM corresponding to a maturity that is the
            % closest one to 'tte' (time to expiry)
            [mn,mn_i] = min(abs(tte - V.ImpliedAtmVola_Preprocessed.maturities));
            
            if simulatedData_flag
                volaToBeUsed = simulated_ATMv;
            else
                volaToBeUsed = V.ImpliedAtmVola_Preprocessed.data;
            end
            
            selectedATM = volaToBeUsed(:,mn_i);
            
            if simulatedData_flag
                % when working on simulations I use all the simulated data data
                ATMv = selectedATM(:,1);
                fd = 1;
            else
                % selecting the ATM for the current pricing date
                fd = find(V.ImpliedAtmVola_Preprocessed.dates == pricing_date);
                ATMv = selectedATM(fd,1);
            end
            if ~isempty(fd)
                impliedVola = V.GetAdjIV_Estimates(tte,ATMv,strike,currentUnderlyingPrice);
            else
                impliedVola = [];
            end
            
        end % method EstimateHistoricalSurface
        
    end % methods
    
    methods (Static)
        
%         function [Strikes,Hprices,T2e,Expiry,OptTicker] = GetOptionsStrip(DataFromBBG,option_ticker,expiry,opttype, ...
%                 current_date,p_increase,fields2download,fields2download_static,min_strike_increase,target_UP,target_DOWN)
%             
%              ***********  NO MORE USED IN THE NEW VERSION **********
%
%             % building a vector of strikes (and corresponding Bloomberg
%             % tickers for download from BBG) from target_DOWN to target_UP
%             currentStrike = target_DOWN;
%             increase = p_increase;
%             cnt = 0;
%             while currentStrike<target_UP
%                 cnt = cnt + 1;
%                 strikes(cnt,1) = currentStrike;
%                 opt_ticker{cnt,1} = [option_ticker,' ',expiry,' ',opttype,num2str(currentStrike), ' Index'];
%                 
%                 currentStrike = currentStrike + increase;
%                 
%                 % increase is 'very low' until the first 'round' (in terms of
%                 % min_strike_increase) is found, then it is set equal to
%                 % min_strike_increase itself
%                 if mod(currentStrike,min_strike_increase) == 0
%                     increase = min_strike_increase;
%                     continue;
%                 end
%             end
%             
%             T2e = [];
%             % getting historical data through
%             % an instance of class Utilities
%             uparam.DataFromBBG = DataFromBBG;
%             uparam.ticker = opt_ticker;
%             uparam.fields = fields2download;
%             uparam.history_start_date = current_date;
%             uparam.history_end_date = current_date;
%             uparam.granularity = 'DAILY';
%             U = Utilities(uparam);
%             U.GetHistPrices;
%             Hprices = U.Output.HistInfo;
%             
%             % filtering out meaningless fields
%             % first remove empty fields
%             if size(Hprices,1)>1 % only in this case it can be a cell array, othgerwise it is a double
%                 fbad1 = cellfun(@isempty,Hprices,'UniformOutput',0);
%                 fbad1 = cell2mat(fbad1);
%                 fbad1 = find(fbad1);
%                 
%                 Hprices(fbad1,:) = [];
%                 strikes(fbad1,:) = [];
%                 opt_ticker(fbad1,:) = [];
%                 % then identify errors of type Unknown/Invalid securityInvalid Security [nid:960]
%                 fbad2 = cellfun(@(x)strfind(x,'Unknown'),Hprices,'UniformOutput',0);
%                 fgood = cellfun(@isempty,fbad2,'UniformOutput',0);
%                 fgood = cell2mat(fgood);
%                 fgood = find(fgood);
%                 Hprices = Hprices(fgood,:);
%                 Hprices = cell2mat(Hprices);
%                 
%             else
%                 fgood = [];
%             end
%             
%             if ~isempty(Hprices)
%                 T2e = Hprices(:,3); % times to expiry
%                 Hprices = Hprices(:,2); % prices
%             end
%             Strikes = strikes(fgood,:);
%             OptTicker = opt_ticker(fgood,:);
%             
%             if isempty(OptTicker)
%                 Expiry = [];
%                 return
%             end
%             
%             % now need the static field 'OPT_EXPIRE_DT' (it's in fields2download_static)
%             % for these selected options
%             % getting Bloomberg static data through an instance
%             % of class Utility
%             uparam.DataFromBBG = DataFromBBG;
%             uparam.ticker = OptTicker;
%             uparam.fields = fields2download_static;
%             uparam.override_fields = [];
%             uparam.override_values = [];
%             U = Utilities(uparam);
%             U.GetBBG_StaticData;
%             
%             if iscell(U.Output.BBG_getdata.OPT_EXPIRE_DT)
%                 if isempty(cell2mat(U.Output.BBG_getdata.OPT_EXPIRE_DT)) % if no data returned
%                     Expiry = [];
%                     return
%                 end
%             end
%             
%             Expiry = unique(U.Output.BBG_getdata.OPT_EXPIRE_DT);  % expiry dates (must be a single date since we are using 'expiry' (see above) for all options
%             
%             
%         end % GetOptionsStrip
        
        
    end % static methods
end % classdef

