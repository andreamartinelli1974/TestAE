classdef asset < handle
    % this class defines a generic asset and is the base class for several
    % subclasses: Bond, Stock, etc.
    
    properties (Constant)
        % number of generic contracts to be downloaded to manage rollover
        % jumps
        Rolling_Generic_No = 2;
     
    end
    
    properties
        AssetType = [];
        FX_Exposure_derived;
        Credit_Exposure_derived;
        % 'Invariants' property of each object will be used to derive the
        % distribution of Invariant through a specific method of the
        % Universe class.
        % property 'Invariants': IMPORTANT: this property will be
        % implemented by subclasses (equity, bond, etc) with the
        % appropriate timeseries. THIS is a structured array with fields:
        % .Name: usually the Bloomberg ticker (without spaces) used to
        % download the timeseries used to derive invariants
        % .Type: type of possible invariants (e.g. Returns, YTM_changes,
        % ImpliedVola TODO: maybe useful to have a spcific enum type for
        % these possible choices)
        % .(Type): a field having the name of one of the possible choices
        % of .Type above
        % .(Type).Timeseries: the timeseries of invariants
        % .External4AtHorizonModeling: boolean: = True(1) when the corresponding invariant
        % for "at Horizon" pricing (made by a method of class Universe) will be recovered from the set of
        % external invariants. False(1) when the same invariant used for
        % historical pricing can be used to model its distribution at
        % Horizon.
        Invariants = [];
        % names of risk factors used to retrieve data from the field
        % AllInvariants of objects of class Universe: MUST HAVE the same
        % format of values in Universe_1.AllInvariants.NamesSet
        % The fields used so far (09022016) are
        % .Price: eg stock prices or FX exchange rates
        % .YTM: eg bonds' ytm
        % .ImpliedVola: imp vola for options (with constante tte for now)
        Risk_Factors_Names = [];
        AA_limits = []; % struct array containing limits for AA purposes (public so that I can change it from outside)
    end
    
    
    properties (SetAccess = immutable) % solo il constructor può modificare queste proprietà
        val_pt = 0;
        DataFromBBG = []; % BBG connection obj and BBG data access options
        Enter_Universe_date = [] % dt from which the asset will enter the inv universe (if [] will always be in the Universe)
        isETF = [];
        Horizon = []; % investment horizon (common to Universe class)
        RolloverRule = []; % pct margin applied by the clearer
        Synthetic = [];
        invertBbgSigns = [];
        MultiplyBBGPricesBy = [];
        % all infos needed do manage accruals: NO MORE NEEDED
        AccrualsInfo = [];
        External_RF; 
        SignsMap;
        CurrentWgts; % introduced on 130617 (optional: for reporting purposes only, to be able to compare current wgts with optimal ones - used in RiskAnalytics)
        BBG_SimultaneousData;
    end
    
    properties (SetAccess = protected)
        History = []; % to store all hist info (e.g. historical timeseries)
        Multiplier = []; % multiplier to be used to go from mkt price to underlying notional
        Reference_Info = [];
        BloombergError = false(1);
        isFuture = [];
        Proxy = [];
    end
    
    methods
        function A = asset(asset_params) % constructor
            
            % from 14.11.2016: all the parameters below have been put under
            % a struct array (asset_params): so all the params listed below
            % are subfields of asset_params:
            % here these subfields are re-assigned to the variables used
            % before
            ticker_BBG = asset_params.ticker_BBG;
            asset_type = asset_params.asset_type;
            DataFromBBG = asset_params.DataFromBBG;
            isproxy = asset_params.isproxy;
            isETF = asset_params.isETF;
            isFuture = asset_params.isFuture;
            rollover_rule = asset_params.rollover_rule;
            ticker_BBG_2 = asset_params.ticker_BBG_2;
            und_ticker = asset_params.und_ticker;
            enter_U_dt = asset_params.enter_U_dt;
            aa_lim = asset_params.aa_lim;
            hor = asset_params.hor ;
            synthetic = asset_params.synthetic;
            invertBbgSigns = asset_params.invertBbgSigns;
            MultiplyBBGPricesBy = asset_params.MultiplyBBGPricesBy;
            AccrualsInfo = asset_params.accruals; % NO MORE USED
            External_RF = asset_params.external_RF;
            CurrentWgts = asset_params.currentWgts;
            if isfield(asset_params,'BBG_SimultaneousData')
                BBG_SimultaneousData = asset_params.BBG_SimultaneousData;
            else
                BBG_SimultaneousData = []; % not using simultaneous data download from BBG
            end
            % INPUTS to the base class 'asset' (as subfields of the struct array asset_params):
            % -> ticker_BBG: Bloomberg ticker: (WHEN USING SYNTHETIC ASSETS USE
            % SOMETHING LIKE 'Sinthetic Asset Bond 1', etc). If it is a
            % swap use a name unique to the specific instance 
            % asset_type: one of the allowed asset classes
            % -> ourTranche: specific for assets of subclass 'MBS': it is used
            % to specify the tranche we are modeling (that is the tranche
            % represented by the current instance of the object). It is
            % empty when there are no tranches and obviously for assets
            % other than MBS.
            % -> DataFromBBG: Bloomberg connection obj and BBG data access options
            % -> isproxy: it is a proxy (not traded, e.g. a rolling fixed maturity bond)
            % proprietà specifiche oggetto 'equity'
            % -> isETF: 1 if it is an ETF, 0 otherwise
            % -> isFuture: 1 if it is a futuree, 0 otherwise
            % -> rollover_rule: for OTC (when isFuture==2) must contain a
            % string indicating the rule to be applied to derive the set of
            % rollover dates (see method rolloverDatesVector of class
            % asset.m)
            % -> ticker_BBG_2: ticker of the subsequent rolling future to manage
            % rollover jumps
            % -> und_ticker: if the instrument is a future put here the
            % Bloomberg ticker of the underlying instrument, otherwise void
            % []. It is important to match the future with the drivers used
            % to generate underlying signals. If the spot underlying is
            % not identifiable put the same ticker as for the future
            % -> enter_U_dt: this is the date the instrument will enter the
            % investable universe. If [] it means that the instrument will
            % ALWAYS BE IN THE UNIVERSE
            % -> aa_lim: structured array whose fields contain limits for
            % asset allocation purposes (e.g. upper and lower investment
            % limits) - for securities with fixed maturity this field is
            % used in conjuncion with the rule based on which the weight
            % must be zero when the security cannot be in the investment
            % universe (based on enter_U_dt and maturity date). IF A GIVEN
            % FIELD OF THE STRUCUTRE IS EMPTY OR NON EXISTENT IT MEANS THAT
            % THERE IS NO LIMIT
            % -> synthetic: IMPORTANT: this is a shortcut to create a 'synthetic' asset 
            % of class equity (now extended to other subclasses like ZCB bonds) (ONLY WHEN THIS FIELD IS NOT EMPTY):
            % if not empty the field must contain a price series that will
            % be automatically assigned to S.History.****.TimeSeries, where
            % '***' must be provided by the user as a subfield of the
            % struct synthetic and should be consistent with the logic
            % implemented within the Bloomberg_GetHistory method (e.g. mc.Name being 'ZCB_bond' or
            % 'equity', etc.) when prices are downloaded from Bloomberg
            % If not empty it must be a structure containing at least the
            % following 2 fields:
            % .synthetic_prices: timeseries of 100 based prices
            % .dates_prices: corresponding dates vector
            % .currency (for now only = 'EUR')
            % .price_type ('Price', 'YTM', ... etc.)
            % IMPORTANT NOTE: the 'synthetic' option is normally used when
            % the security is non existent ob Bloomberg, so we cannot
            % download any static or historical Bloomberg field. If the
            % security exists on Bloomberg (for example wrt many MBSs), but
            % we want to download its history from a different source (e.g.
            % an Excel file), this is done by specifying a different
            % historical prices source and managing it within the
            % 'Bloomberg_GetHistory' method of class 'assset'.
            % -> invertBbgSigns: set to True to invert the sign (multiply by
            % -1) of the price series downloaded from Bloomberg
            % -> MultiplyBBGPricesBy: a factor by which timeseries downloaded
            % from BBG will be multiplied. E.G. when rates downloaded from
            % BBG are expressed in basis points (and not in pct as usual,
            % it is necessary to divide by 100). SO THE DEFAULT MULTIPLIER
            % MUST BE 1.
            % -> AccrualsInfo: *** NO MORE USED ***
            % ************************* IMPORTANT *************************
            % -> External_RF: this is the instance of External_Risk_Factors
            % created within AA_DashBoard. It contains the timeseries for
            % all of the 'external invariants' (that is, the risk factors
            % needed for pricing that are not directly defined with a
            % specific subclass instance -  like in the case of log-returns
            % for sub class 'equity' for eample - but are defined at an outer level).
            % These external risk factors are typically used to price
            % several assets: e.g. normally an IR curve includes risk
            % factors needed to price several assets. This property, that always
            % (for any obj of superclass 'asset' )references
            % the instance of class External_Risk_Factors created with the AA_DashBoard,
            % has 2 main purposes:
            
            % i) it is always used for "At Horizon" repricing, in
            % combination with the property (specific to each asset
            % subclass) Risk_Factors_Names. More specifically the latter
            % contains the name of the 'external invariants' included in
            % the instance of External_Risk_Factors that need to be used to
            % price the specific asset at the investment horizon;
            % ii) while for some assets (e.g. 'equity', 'Option_vanilla', '
            % etc.) a specific property (Invariants) is created at the
            % sub-class level to hold the data needed for 'Historical'
            % pricing (it is typically filled used inputs provided when
            % building the class or invoking the 'Price2Invariants'
            % methods), for more complex classes (e.g. 'irs') the
            % 'Invariants' property is not defined and the instance of class
            % External_Risk_Factors is used directly to pick the invariants
            % (time homogeneous risk factors) needed for pricing
            % *************************************************************
            % -> BBG_SimultaneousData: this is a repository of Bloomberg
            % data that have been previously downloaded in a simultaneous
            % way to speed up execution. It has subfields .historical and
            % .static, collecting hist timeseries and static data
            % respectively. The content of this repository will be checked
            % by the Utilities methods invoked to download data from
            % Bloomberg to check whther data is available already. The
            % field is empty when simultaneous data download is not used
            % if this subfield is not given as an input then it is
            % automatically set to empty. 
            
            mc = metaclass(A);
            if strcmp(mc.Name,'InvestmentUniverse.irs') % if this is an instance of 'irs' sub-class
                irs_flag = true(1); 
            else
                irs_flag = false(1); 
            end
         
                
            A.Multiplier = 1;
            A.RolloverRule = rollover_rule;
            A.Synthetic = synthetic;
            A.isETF = isETF;
            A.isFuture = isFuture;
            A.DataFromBBG = DataFromBBG;
            A.Horizon = hor;
            A.BBG_SimultaneousData = BBG_SimultaneousData;
            
            if strcmp(mc.Name,'InvestmentUniverse.MBS')
                tmp = strtrim(split(ticker_BBG,'Mtge'));
                % building the specific ticker from the generic 'issuance
                % ticker' (e.g. SIENA 2010-7 Mtge) and the specific
                % trance identifier (e.g. A3). This will also work when
                % there are no tranches (ourTranche = []).
                ticker_BBG = [tmp{1},' ',asset_params.ourTranche,' ','Mtge'];
            end
            
            A.Reference_Info.ticker_BBG = ticker_BBG;
            A.Reference_Info.und_ticker = und_ticker;
            A.Reference_Info.ticker_BBG_2 = ticker_BBG_2; % ticker of the 2nd rolling future (needed to manage rollover jumps)
            A.AssetType = asset_type;
            A.Reference_Info.isproxy = isproxy;
            A.Enter_Universe_date = enter_U_dt;
            A.AA_limits = aa_lim;
            A.invertBbgSigns = invertBbgSigns;
            A.MultiplyBBGPricesBy = MultiplyBBGPricesBy;
            A.AccrualsInfo = AccrualsInfo; % NO MORE USED
            A.External_RF = External_RF;
            A.CurrentWgts = CurrentWgts;
            
            if ~irs_flag
                if isempty(A.Synthetic)
                    bbg_flds = {'LAST_PRICE','ID_ISIN','SECURITY_TYP','NAME','CRNCY', ...
                        'OPT_CONT_SIZE','OPT_TICK_VAL','OPT_VAL_PT','FUT_VAL_PT', ...
                        'FUT_NOMINAL_CONTRACT_VALUE','FUT_TICK_VAL','COUNTRY','INDUSTRY_SECTOR','INDUSTRY_GROUP'};
                    uparam.DataFromBBG = DataFromBBG;
                    uparam.ticker = ticker_BBG;
                    uparam.fields = bbg_flds;
                    uparam.override_fields = [];
                    uparam.override_values = [];
                    uparam.NOBBG = true(1);
                    uparam.save2disk = true(1);
                    uparam.BBG_SimultaneousData = A.BBG_SimultaneousData;
                    U = Utilities(uparam);
                    U.GetBBG_StaticData;
                    d = U.Output.BBG_getdata;
                    
                    if isfield(d,'ERROR') & strcmp(d.ERROR,'INVALID_SECURITY')
                        A.BloombergError = true(1);
                        return
                    end
                
                    % [d,sec] = getdata(bbgconn,ticker_BBG,bbg_flds);
                    A.Reference_Info.last_price = d.LAST_PRICE;
                    A.Reference_Info.security_type = d.SECURITY_TYP;
                    A.Reference_Info.ISIN = d.ID_ISIN;
                    A.Reference_Info.name = d.NAME;
                    A.Reference_Info.Country = d.COUNTRY;
                    A.Reference_Info.IndustrySector = d.INDUSTRY_SECTOR;
                    A.Reference_Info.IndustryGroup = d.INDUSTRY_GROUP;
                    
                    % TODO (URGENT): THIS 'ITL' PROVISION IS VERY TEMPORARY, introduced
                    % to manage a case where the rate used to mnodel btp's
                    % asset swap is a security denominated in ITL. MANAGE THIS
                    % ISSUE IN A MORE GENERAL WAY
                    if strcmp(d.CRNCY,'ITL') | strcmp(d.CRNCY,'XEU') | strcmp(d.CRNCY,'DEM')
                        d.CRNCY{1} = ['EUR'];
                    end
                    A.Reference_Info.currency = d.CRNCY;
                    
                    A.Reference_Info.FUT_NOMINAL_CONTRACT_VALUE = d.FUT_NOMINAL_CONTRACT_VALUE;
                    A.Reference_Info.FUT_TICK_VAL = d.FUT_TICK_VAL;
                    A.Reference_Info.FUT_VAL_PT = d.FUT_VAL_PT;
                    A.Reference_Info.OPT_CONT_SIZE = d.OPT_CONT_SIZE;
                    A.Reference_Info.OPT_TICK_VAL = d.OPT_TICK_VAL;
                    A.Reference_Info.OPT_VAL_PT = d.OPT_VAL_PT;
                    
                else ~isempty(A.Synthetic) % ******************************
                    
                    A.History.(A.Synthetic.price_type).TimeSeries = [A.Synthetic.dates_prices, A.Synthetic.synthetic_prices];
                    
                    A.History.(A.Synthetic.price_type).Name = strrep(A.Reference_Info.ticker_BBG,' ','_')
                    A.Reference_Info.currency{1} = A.Synthetic.currency;
                    A.Reference_Info.name{1} = ticker_BBG;
                    A.Reference_Info.ISIN = ['Synthehtic Asset'];
                    A.Reference_Info.currency{1} = synthetic.currency;
                    A.Reference_Info.FUT_VAL_PT = 1;
                    A.Reference_Info.Country{1} =  [];
                    A.Reference_Info.IndustrySector{1} = [];
                    A.Reference_Info.IndustryGroup{1} = [];
                end
                
                % assume it is EUR if the field is empty TODO: REVIEW THIS !!!
                if isempty(A.Reference_Info.currency{1})
                    A.Reference_Info.currency{1} = 'EUR';
                end
                
            elseif irs_flag
                A.Reference_Info.Country{1} =  [];
                A.Reference_Info.IndustrySector{1} = [];
                A.Reference_Info.IndustryGroup{1} = [];
            end % if not an 'irs'
            
            % Option_Vanilla_OLD is kept only for temporary
            % compatibility with the Factor Analysis code
            % both Option_Vanilla_ApproxSurface and Option_Vanilla_OLD
            % SUBCLASSES ARE NO MORE USED WITHIN THE aa FRAMEWORK
            % TODO: remove both from everywhere when possible
            if isFuture == 1 | strcmp(mc.Name,'InvestmentUniverse.Option_Vanilla') | strcmp(mc.Name,'InvestmentUniverse.Option_Vanilla_ApproxSurface') | strcmp(mc.Name,'InvestmentUniverse.Option_Vanilla_OLD')
                if isFuture == 1
                    A.Multiplier = A.Reference_Info.FUT_VAL_PT{1};
                elseif strcmp(mc.Name,'Option_Vanilla') | strcmp(mc.Name,'Option_Vanilla_ApproxSurface') | strcmp(mc.Name,'Option_Vanilla_OLD')
                    A.Multiplier = A.Reference_Info.OPT_VAL_PT(1); 
                end
                if iscell(A.Multiplier)
                    A.Multiplier = A.Multiplier{1};
                end
            else
                if strcmp(mc.Name,'InvestmentUniverse.bond_ZCB')
                    % in this way when I will get the following result:
                    % e.g.: price of the bon = 102
                    % price*multiplier = 1.02;
                    % Notional to be invested = 100000 -> composition
                    % shares will be 100000/1.02 = approx 98k
                    A.Multiplier = 0.01;
                elseif strcmp(mc.Name,'InvestmentUniverse.cds')
                    % assigned within cds subclass
                end
            end
            
            if iscell(A.Multiplier)
                A.Multiplier = cell2mat(A.Multiplier);
            end
            
            if ischar(A.Multiplier)
                A.Multiplier = str2num(A.Multiplier);
            end
            
                        
            if  ~irs_flag && (~strcmp(A.Reference_Info.currency,'EUR') & isFuture==0)
                % if the cuirrency is not EUR and the asset is not a future
                % I need to extract the currency exposure, as for this
                % asset class all returnsa will be calculated in euros.
                % The exposure to the currency will be made explicit by
                % creating a new asset class of type FX and this will be
                % done for all 'extracted' (indirect) currency exposures by
                % looking at the content of the field FX_Exposure_derived
                A.FX_Exposure_derived = A.Reference_Info.currency; % TODO: this field still not used in the AA setup
            end
            
            disp(['Generating Asset: ',ticker_BBG]);
        end % constructor
        
        function Bloomberg_GetHistory(A,start_dt, end_dt, frequency, currency, addparams)
            % this method was initially designed to provide financial
            % dataseries download capabilities from Bloomberg only. Since
            % then it has been expanded to be able to read historical
            % timeseries from xls files (for CDS credit spreads at the moment)
            
            % INPUT:
            % start_dt, end_dt, frequency: refers to the initial date,
            % final date and the granularity of data downloaded from xls
            % using 'history'
            % currency: NOT USED FOR NOW: it is the currency used to
            % download data from BBG with 'history'
            % addparams: a struct array containing additional parameters
            % that may be needed (e.g. the .quickCDS flag that is set to
            % 'true' when CDS repricing over the hist horizon is based on the
            % initial SDV01 (otherwise SDV01 is recalculated at each point
            % in time based on the prevailing credit spread curve)
            % for assets of subclass 'MBS' the 'addparams' struct must also
            % contain a field ('hist_prices_source') that identifies the
            % source of hist data (can be 'BBG' or 'excel' as of 22.1.2018)
            % and a field ('hist_prices_source_path') identifying the
            % subfolder within the AA folder that contains the hisotrical
            % prices when the price source is 'excel'
            A.History = [];
            d1 = [];
            
            mc = metaclass(A);
            
            if isempty(A.Synthetic)
                % download historical timeseries from Bloomberg, plus infos
                % needed to manage rollover adjustments when returns are
                % calculated using the spoecific method, .... or quotes
                % from and external file
                
                % NOT USED FOR NOW ******
                if strcmp(mc.Name,'InvestmentUniverse.fx')
                    crncy = [];
                else
                    crncy = ['EUR'];
                end
                % ***********************
                
                % set the PriceType that will be used to name the fields of
                % History. They should be reflective of the nature of the
                % price series. 
                % From 28.11.2017 (GP): 'PriceType' can now be a cell
                % array containing many names, corresponding to the names
                % of the fields in 'fields2download': in this case more
                % than one field will be created in the struct named
                % 'History'. 
                fields2download = {'LAST_PRICE'};
                
                % Option_Vanilla_OLD is kept only for temporary
                % compatibility with the Factor Analysis code
                % both Option_Vanilla_ApproxSurface and Option_Vanilla_OLD
                % SUBCLASSES ARE NO MORE USED WITHIN THE aa FRAMEWORK
                % TODO: remove both from everywhere when possible
                if strcmp(mc.Name,'InvestmentUniverse.Option_Vanilla') | strcmp(mc.Name,'InvestmentUniverse.Option_Vanilla_ApproxSurface') | strcmp(mc.Name,'InvestmentUniverse.Option_Vanilla_OLD')
                    m = msgbox('Invoking Bloomberg_GetHistory method not allowed for Option_Vanilla and ption_Vanilla_ApproxSurface objects: use GetImpliedHistory instead','Icon','warn');
                end
                
                if  strcmp(mc.Name,'InvestmentUniverse.bond_ZCB') && A.isRate == 1
                    PriceType = 'YTM';
                elseif  strcmp(mc.Name,'InvestmentUniverse.bond_ZCB') && A.isRate == 0
                    PriceType = 'Price';
                elseif strcmp(mc.Name,'InvestmentUniverse.equity') | strcmp(mc.Name,'InvestmentUniverse.fx')
                    fields2download = {'LAST_PRICE','EQY_DVD_YLD_EST','EQY_DVD_YLD_IND'}; % indicated and estimated dividend yield should 'cpver' both indices and single stocks
                    PriceType = {'Price','DvdYldEst','DvdYldInd'};
                elseif strcmp(mc.Name,'InvestmentUniverse.Option_Vanilla') | strcmp(mc.Name,'InvestmentUniverse.Option_Vanilla_ApproxSurface') | strcmp(mc.Name,'InvestmentUniverse.Option_Vanilla_OLD')
                    disp('Method call not allowed for Options');
                    disp('implied Volatility History is downloaded');
                    disp('via the Get_ImpliedVolaInvariant method of class Option_Vanilla or Option_Vanilla_ApproxSurface');
                    pause;
                elseif strcmp(mc.Name,'InvestmentUniverse.cds')
                      PriceType = 'CdsSpread'; 
                      % TODO: REVIEW THIS
                      % fields2download = {'LAST_PRICE'};
%                       if strcmp(A.Specific_Attributes.GENERIC_CDS_INDEX,'Y')
                          fields2download = {'LAST_PRICE','ROLL_ADJUSTED_MID_PRICE'};
%                       end          
                elseif strcmp(mc.Name,'InvestmentUniverse.irs')
                    PriceType = 'Price';
                elseif strcmp(mc.Name,'InvestmentUniverse.MBS')    
                    PriceType = 'Price';
                end
                
                start_dt_num = datenum(start_dt,'mm/dd/yyyy');
                end_dt_num = datenum(end_dt,'mm/dd/yyyy');
                % set list of hist fields to download
                if ~strcmp(mc.Name,'InvestmentUniverse.irs') % A.Reference_Info.currency{1} assigned in sub-class for 'irs' objects
                    crncy = A.Reference_Info.currency{1};
                end
                
                if A.isFuture == 1 | A.isFuture == 2
                    
                    if A.isFuture == 2
                        isOtc = true(1);
                    else
                        isOtc = false(1);
                    end
                    fields2download = {'LAST_PRICE','FUT_CUR_GEN_TICKER'};
                    % here I need 2 rolling products to manage the rollover
                    % jumps
                    uparam.DataFromBBG = A.DataFromBBG;
                    uparam.ticker = A.Reference_Info.ticker_BBG;
                    uparam.fields = fields2download;
                    uparam.history_start_date = start_dt_num;
                    uparam.history_end_date = end_dt_num;
                    uparam.granularity = frequency;
                    uparam.BBG_SimultaneousData = A.BBG_SimultaneousData;
                    U = Utilities(uparam);
                    U.GetHistPrices;
                    d1 = U.Output.HistInfo;
                    
%                     % sometimes we get NaNs in the FUT_CUR_GEN_TICKER
%                     % field: need to remove them
%                     fchar = cellfun(@ischar, d1(:,3), 'UniformOutput', false);
%                     fnan = ~cell2mat(fchar); 
%                     fnan = find(fnan==1);
%                     if ~isempty(fnan)
%                         d1(fnan,:) = [];
%                     end
%                     
%                     % ... and removing NaN prices as well
%                     fnan = cellfun(@isnan, d1(:,2), 'UniformOutput', false);
%                     fnan = cell2mat(fnan); 
%                     fnan = find(fnan==1);
%                     if ~isempty(fnan)
%                        d1(fnan,:) = [];
%                     end
                    
                    
                    % Need to remove any NaN value (should be more
                    % efficient than the code above - commented -
                    % previously written for the same purpose
                    if ~isOtc
                        toDelete = [];
                        for col=1:3 % 3 % initial 2 columns contain dates and prices for each contract ticker (in the 3-rd column)
                            findnan = cellfun(@isnan,d1(:,col),'UniformOutput', false);
                            if col<3
                                if iscell(findnan)
                                    findnan = cell2mat(findnan);
                                end
                                idnan = find(findnan==1);
                            elseif col==3 % to identify rows where the ticker is a NaN
                                
                                findnan = cellfun(@(x) (x==1),findnan,'UniformOutput', false);
                                findnan = (cellfun(@numel,findnan,'UniformOutput', false));
                                idnan = find(cell2mat(findnan)==1);
                            end
                            toDelete = [toDelete;idnan];
                            
                        end
                        toDelete = unique(toDelete);
                        d1(toDelete,:) = [];
                    end
                    
                    unitprices = A.Cents2UnitsofCurrency(d1,crncy);
                    d1 = unitprices;
                    
                    uparam.ticker = A.Reference_Info.ticker_BBG_2;
                    U = Utilities(uparam);
                    U.GetHistPrices;
                    d2 = U.Output.HistInfo;
                    
                    if ~isOtc
                        % sometimes we get NaNs in the FUT_CUR_GEN_TICKER
                        % field: need to remove them
                        fchar = cellfun(@ischar, d2(:,3), 'UniformOutput', false);
                        fnan = ~cell2mat(fchar);
                        fnan = find(fnan==1);
                        if ~isempty(fnan)
                            d2(fnan,:) = [];
                        end
                        
                        %  ... and removing NaN prices as well
                        fnan = cellfun(@isnan, d2(:,2), 'UniformOutput', false);
                        fnan = cell2mat(fnan);
                        fnan = find(fnan==1);
                        if ~isempty(fnan)
                            d2(fnan,:) = [];
                        end
                    end
                    
                    unitprices = A.Cents2UnitsofCurrency(d2,crncy);
                    d2 = unitprices;
                    
                    % when the conversion  correction for cents (e.g. GBp or USd) is made 
                    % the currency label is changed (e.g. from
                    % GBp to GBP)
                    A.Reference_Info.currency{1} = upper(A.Reference_Info.currency{1});
                    
                    if  (strcmp(mc.Name,'InvestmentUniverse.bond_ZCB') && A.isRate == 1)
                        d1(:,2) = d1(:,2)./100;
                        d2(:,2) = d2(:,2)./100;
                    end
                    
                    
                    if A.invertBbgSigns
                        d1(:,2) = -d1(:,2);
                        d2(:,2) = -d2(:,2);
                    end
                                        
                    if iscell(d1)
                        dn1 = cell2mat(d1(:,1:2));
                    else
                        dn1 = d1(:,1:2); 
                    end
                    if iscell(d1)
                        dn2 = cell2mat(d2(:,1:2));
                    else
                        dn2 = d2(:,1:2);
                    end
                    
                    dn1(:,2) = dn1(:,2).*A.MultiplyBBGPricesBy;
                    dn2(:,2) = dn2(:,2).*A.MultiplyBBGPricesBy;
                    
                    % intersection on common dates
                    % TODO: interpolation may be needed if there are many big
                    % holes in data
                    [Cdates,ia,ib] = intersect(dn1(:,1),dn2(:,1));
                    
                    % TODO: see notes on the same topic: need to reorganize
                    % and fully automate (also making more robust) the mgmt
                    % of PriceType
                    % Here I am relying on the fact the the first element
                    % refers to the price of the asset
                    if iscell(PriceType)
                        A.History.(PriceType{1}).TimeSeries(:,1) = Cdates;
                        A.History.(PriceType{1}).TimeSeries(:,2) = dn1(ia,2);
                        A.History.(PriceType{1}).TimeSeries(:,3) = Cdates;
                        A.History.(PriceType{1}).TimeSeries(:,4) = dn2(ib,2);
                    else
                        A.History.(PriceType).TimeSeries(:,1) = Cdates;
                        A.History.(PriceType).TimeSeries(:,2) = dn1(ia,2);
                        A.History.(PriceType).TimeSeries(:,3) = Cdates;
                        A.History.(PriceType).TimeSeries(:,4) = dn2(ib,2);
                    end
                    
                    
                elseif ~(A.isFuture == 1) % NOT A FUTURE
                    
                    if strcmp(mc.Name,'InvestmentUniverse.cds') % ** && A.CDS_Curve.CurveInputParams.excel_spread_input.flag
                        % only if it is a CDS with data read from xls file
                        % CHANGED: no more true (2-nd piece of the IF above
                        % commented), since I already have these data into
                        % the curve obj, even when the Curve obj comes from
                        % BBG or any other source, like MDS. In this way
                        % consistency between the series of the invariants
                        % and their date vector and the timeseries of
                        % prices is guaranteed.
                        pricecolumn = A.CDS_Curve.Curve.Tickers2ColumnsMap(A.Reference_Info.ticker_BBG);
                        d1(:,1) = A.CDS_Curve.Curve.dates;
                        % d1(:,2) = A.CDS_Curve.Curve.CDS(:,pricecolumn);
                        % IMPORTANT: NEEDS TO BE MULTIPLIED BY 100 TO HAVE
                        % IT IN THE SAME FORM AS THE DATA WHEN THEY COME
                        % FROM BLOOMBERG (later this will be divided by
                        % 100()
                        % d1(:,2) = A.CDS_Curve.Curve.CDS(:,pricecolumn).*100;
                        d1(:,2) = A.CDS_Curve.Curve.CDS_interp(:,pricecolumn).*100; % TODO: parametrize the choice of interp data
                        d1(:,3) = d1(:,2); % for compatibility with the BBG download case for indices (where data in col 3 are used)
                    else
                        if ~strcmp(mc.Name,'InvestmentUniverse.irs') % for IRS there are no BBG prices
                            
                            % here the case that the asset is an MBS and
                            % historical prices come form an xls
                            % spreadsheet is managed. TODO: THIS CAN BE
                            % EXTENDED TO ANY ASSET FOR WHICH WE WANT TO
                            % READ HIATORICAL PRICES FROM EXCEL
                            if strcmp(mc.Name,'InvestmentUniverse.MBS') & strcmp(addparams.hist_prices_source,'excel')
                                % TODO: write e method of class Utilities
                                % to generalize data reading from external
                                % files
                                filename = fullfile(cd,addparams.hist_prices_source_path,addparams.hist_prices_filename);
                                T = readtable(filename);
                                d1(:,1) = datenum(T.(addparams.xls_colName{1})); % assuming that dates can be read as a datetime array (TODO: more check on this)
                                d1(:,2) = T.(addparams.xls_colName{2})./addparams.xls_price_base.*100;
                                
                            else % historical prices from Bloomberg
                                
                                % EQUITY PRICES ARE DOWNLOADED HERE
                                uparam.DataFromBBG = A.DataFromBBG;
                                uparam.ticker = A.Reference_Info.ticker_BBG;
                                uparam.fields = fields2download;
                                uparam.history_start_date = start_dt_num;
                                uparam.history_end_date = end_dt_num;
                                uparam.granularity = frequency;
                                uparam.BBG_SimultaneousData = A.BBG_SimultaneousData;
                                
                                U = Utilities(uparam);
                                U.GetHistPrices;
                                d1 = U.Output.HistInfo;
                                if iscell(d1)
                                    d1 = cell2mat(d1);
                                end
                                unitprices = A.Cents2UnitsofCurrency(d1,crncy);
                                d1 = unitprices;
                                
                            end
                            
                            % when the conversion  correction for cents (e.g. GBp or USd) is made
                            % the currency label is changed (e.g. from
                            % GBp to GBP)
                            A.Reference_Info.currency{1} = upper(A.Reference_Info.currency{1});
                          
                        end
                    end
                    
                    % USE THE COMMENTED CODE BELOW TO USE DIRECTLY THE
                    % CREDIT SPREADS USED FOR CURVE OBJECTS, BUT THEY ARE
                    % NOT BASED ON ROLL_ADJUSTED_MID_PRICE.
                    % TODO: REVIEW THIS
                    % if strcmp(mc.Name,'cds') 
                        % if it is a CDS get the priceseries directly from
                        % the curve obj that got it already
                    %     pricecolumn = A.CDS_Curve.Curve.Tickers2ColumnsMap(A.Reference_Info.ticker_BBG)
                    %     d1(:,1) = A.CDS_Curve.Curve.dates;
                    %     d1(:,2) = A.CDS_Curve.Curve.CDS(:,pricecolumn);
                    % else
                    %     [d1,~] = history(A.bbgconn,A.Reference_Info.ticker_BBG,fields2download, ...
                    %          start_dt_num,end_dt_num,frequency,crncy);
                    % end
                    
                    % to deal with data formatted as a cell array (can
                    % happen when using simultaneous Bloomberg data
                    % download - see class parallelBBG.m)
                    if iscell(d1)
                        d1 = cell2mat(d1);
                    end
                    
                    if  (strcmp(mc.Name,'InvestmentUniverse.bond_ZCB') && A.isRate == 1) | strcmp(mc.Name,'InvestmentUniverse.cds')
                        d1(:,2:end) = d1(:,2:end)./100;
                    end
                    if ~strcmp(mc.Name,'InvestmentUniverse.irs')
                        d1(:,2:end) = d1(:,2:end).*A.MultiplyBBGPricesBy;
                    end
                    if A.invertBbgSigns
                        d1(:,2:end) = -d1(:,2:end);
                    end
                    
                    % TODO: the management of PriceType and of the
                    % historical BBG fields to download can be made better
                    % and more automatized. Do it when there is time,
                    % keeping in mind the following:
                    % a) a list of historical field to download can be
                    % defined at sub-class (of class asset) level
                    % b) all these fields can be downloaded and associated
                    % to sub-fields of the struct array 'asset'.History
                    % (like it is done below for equities).
                    currentName = mc.Name;
                    if ~strcmp(currentName,'InvestmentUniverse.irs')
                        switch currentName
                            case 'InvestmentUniverse.equity'
                                if ~isempty(U.Output.HistInfo) 
                                    fields_n = numel(fields2download);
                                    for n=1:fields_n
                                        if strcmp(fields2download{n},'EQY_DVD_YLD_EST') ...
                                           | strcmp(fields2download{n},'EQY_DVD_YLD_IND')     
                                                d1(isnan(d1(:,n+1)),n+1) = 0; % replace missing dvds with zero
                                        end
                                        A.History.(PriceType{n}).TimeSeries(:,1) = d1(:,1); % dates
                                        A.History.(PriceType{n}).TimeSeries(:,2) = d1(:,n+1); % data
                                    end
                                else
                                    A.History.(PriceType).TimeSeries = d1;
                                    % * A.History.(PriceType).TimeSeries(:,1) = d1(:,1);
                                    % * A.History.(PriceType).TimeSeries(:,2:size(d1,2)) = d1(:,2); % in AA, if empty the asset will be excluded within ReadFromIU_inputFile.m
                                end
                            case 'InvestmentUniverse.MBS'
                                 A.History.(PriceType).TimeSeries(:,1) = d1(:,1);
                                 A.History.(PriceType).TimeSeries(:,2) = d1(:,2);
                            otherwise
                                A.History.(PriceType).TimeSeries(:,1) = d1(:,1);
                                % for CDS there will be mkt spread in col 2 and roll adj spread in column 3
                                A.History.(PriceType).TimeSeries(:,2:size(d1,2)) = d1(:,2:end);
                        
                        end % switch on 'currentName'
                    end % if on ~strcmp(currentName,'irs')
                    
                    if strcmp(mc.Name,'InvestmentUniverse.cds')
                        % need to derive the price of the CDS
                        % here I assume that the contract spread equals
                        % .FixedCoupon: on each subsequent day the CDS will be priced using
                        % this contract spread. This genertates an upfront
                        % payment on the trading date. 
                        
                        % *****************************************************
                        disp('Pricing CDS and CSDV01 calculation over hist horizon');
                        tenor = A.FixedTtm; % in year fraction
                        spreads = [A.History.CdsSpread.TimeSeries(:,1),A.History.CdsSpread.TimeSeries(:,3)]; %(:,3) % USING ADJ SPREADS (column 3 in .Timeseries) TO SMOOTH OUT ROLLOVERS EFFECTS
                        % initial contract spread (the first day in the hist timeseries)
                        contract_spread = A.FixedCoupon./100;
                        sz = size(spreads,1);
                        cashflow = zeros(sz,1);
                        continuousAccruals = zeros(sz,1);
                        continuousAccrualsRate = A.FixedCoupon/(365*10000);
                        rolladj = zeros(sz,1); % assumed to be 0: good when using ROLL_ADJUSTED_MID_PRICE prices from Bloomberg (see commented code below): TODO: parametrize this
                        
                        RPV01_FIRST_EST = false(1); % VERY TEMP APPROX
                        dspreads = [0;diff(spreads(:,2))];
                        
                        for k=1:sz % pricing at each point in time
                           
                            pricing_dt = spreads(k,1);
                            
                            fpaydt = find(A.PL_dates == pricing_dt);
                            % if it is a payment date leg compute the cashflow
                            if ~isempty(fpaydt)
                                % this is considered alread when using
                                % cdsrpv01 or cdsprice in
                                % cds.BootstrapAndPrice method called below
                                if A.AccrueCDS_coupon
                                    % A.PL_frequency will be 1 for monthly
                                    % frequencies, 3 for quarterly freq, 12
                                    % for yearly freq, based on the mapping
                                    % defined in class cds (CDS.FreqMap)
                                    
                                    % TODO: cashflow is currently noit used
                                    % nor stored in any property of the cds
                                    % class
                                    cashflow(k,1) = (A.Notional.*(A.FixedCoupon./10000))./(12./A.PL_frequency) .* -sign(A.Notional);  
                                else
                                    cashflow(k,1) = 0; 
                                end
                            end
                            
                            if addparams.quickCDS % *** THIS IS THE OPTION CURRENTLY USED ***
                                % if .quickCDS is 'true' then only the
                                % initial SDV01 is computed 
                                if mod(k,addparams.quickCDS_SDV01_recalcFreq)==0
                                % every quickCDS_SDV01_recalcFreq units of
                                % time recalculate SDV01 to reduce the
                                % impact of convexity
                                    RPV01_FIRST_EST = false(1);
                                end
                                
                                if ~RPV01_FIRST_EST
                                    [npv1(k,1),delta_npv2(k,1),RPV01(k,1),HazardRate(k,1),Rate(k,1),DP(k,1)] = ...
                                        A.BootstrapAndPrice(pricing_dt, contract_spread, tenor);
                                    if isnan(RPV01(k,1)) % there was no curve onb the date in 'pricing_dt'
                                        continue;
                                    end
                                    fixedRPV01 = RPV01(k,1);
                                else
                                    delta_npv2(k,1) = A.Notional.*(spreads(k,2) - contract_spread) * fixedRPV01./100;
                                    RPV01(k,1) = fixedRPV01;
                                end
                                
                                
                            else % *** NOT USED IN PRACTICE: TOO SLOW:  need to be reviewed ***
                                % otherwise SDV01 is computed at each point
                                % in time based on the default
                                % probabilities implied by the prevailing
                                % credit spreads curve
                                [npv1(k,1),delta_npv2(k,1),RPV01(k,1),HazardRate(k,1),Rate(k,1),DP(k,1)] = ...
                                    A.BootstrapAndPrice(pricing_dt, contract_spread, tenor);
                            end
                            
                            
                            RPV01_FIRST_EST = true(1); 
                            % The rolldates adj below is not needed when using
                            % the 'ROLL_ADJUSTED_MID_PRICE' (instead of
                            % 'LAST_PRICE') as PriceUsed
                            % to build CDS curves - FOR NOW USING THIS:
                            % PARAMETRIZE THE execution of the adj below based
                            % on the value of PriceUsed in CDS curves
                            
                            % frolldt = find(A.CDS_RollDates   == pricing_dt);
                            % on rolling dates permanently remove the change
                            % in npv from previous day
                            % TODO: this is an APPROXIMATION: should be
                            % replaced with the removal of the change in npv
                            % due to rollover only (while in this case we are also including
                            % the share of the change attributable to the mkt action)
                            %if ~isempty(frolldt)
                            %    rolladj(k,1) = -(delta_npv2(k,1) - delta_npv2(k-1,1));
                            %end
                            
                            % INCORPORATING ACCRUALS: when
                            % A.AccrueCDS_coupon is True I need to
                            % continuously account for accruals, based on
                            % the fixed coupon A.FixedCoupon
                            % Note: when A.Notional>0 I am modeling a long
                            % protection CDS, so I am paying the coupon
                            % (protection leg) and viceversa
                            if A.AccrueCDS_coupon
                                continuousAccruals(k,1) = (A.Notional.*continuousAccrualsRate) .* -sign(A.Notional);  
                            else
                                continuousAccruals(k,1) = 0;
                            end
                            
                        end % for on k (time)
                        ZC_cds = 1.*exp(-(Rate + HazardRate+0).*tenor); % for approx check
                        % assign properties
                        N = A.Notional; %.*-sign(A.Notional);
                        A.History.Price.TimeSeries = [spreads(:,1),N + delta_npv2 + cumsum(continuousAccruals) - cumsum(rolladj)] ;
                        A.History.SPV01.TimeSeries = [spreads(:,1),RPV01];
                        % removing NaN
                        fnan = find(isnan(A.History.Price.TimeSeries(:,2)));
                        A.History.Price.TimeSeries(fnan,:) = [];
                        fnan = find(isnan(A.History.SPV01.TimeSeries(:,2)));
                        A.History.SPV01.TimeSeries(fnan,:) = [];
                        % *****************************************************
                    end % if cds
                   
                end % if isFuture, ..else
                
                if  strcmp(mc.Name,'InvestmentUniverse.bond_ZCB') & ~isempty(A.Enter_Universe_date)
                    % when there is an 'Enter Universe date' the downloaded
                    % history must extend outside the Enter_Universe_date /
                    % MaturityDate window (when it is not so already), to cover the
                    % whole start_dt_num/end_dt window, to avoid that when
                    % intersection on dates is performed or during backtesting,
                    % etc., the shorter series can condition all remaining
                    % series over periods when the asset with shorter history
                    % has no weight on the portfolio
                    
                    eud = datenum(A.Enter_Universe_date);
                    mat = datenum(A.MaturityDate);
                    dfirst = A.History.(PriceType).TimeSeries(1,1);
                    dlast = A.History.(PriceType).TimeSeries(end,1);
                    if dfirst>start_dt_num & eud>dfirst
                        newrows = [[start_dt_num:1:dfirst-1]',zeros(dfirst-start_dt_num,1)];
                        if size(A.History.(PriceType).TimeSeries,2) == 2
                            A.History.(PriceType).TimeSeries = [newrows;A.History.(PriceType).TimeSeries];
                        elseif size(A.History.(PriceType).TimeSeries,2) == 4
                            A.History.(PriceType).TimeSeries = [[newrows,newrows];A.History.(PriceType).TimeSeries];
                        end
                    end
                    
                    if dlast<end_dt_num & mat<end_dt_num
                        newrows = [[dlast+1:1:end_dt_num]',zeros(end_dt_num-dlast,1)];
                        if size(A.History.(PriceType).TimeSeries,2) == 2
                            A.History.(PriceType).TimeSeries = [A.History.(PriceType).TimeSeries;newrows];
                        elseif size(A.History.(PriceType).TimeSeries,2) == 4
                            A.History.(PriceType).TimeSeries = [A.History.(PriceType).TimeSeries];[newrows,newrows];
                        end
                    end
                    
                end % if bond_ZCB
                
                % calculating hist prices for IRS
                if strcmp(mc.Name,'InvestmentUniverse.irs')
                    % GENERATING THE IRS PRICE HISTORY BY REPRICING IT
                    % AT EACH POINT IN TIME OVER THE SELECTED WINDOW
                    
                    % the set of dates for which I want to reprice the swap: it is the
                    % one associated with the domestic curve history
                    
                    dates = A.CurvesHistory.ZeroCurves{1}.Curve.dates;
                    % redefining based on the start/end date of the
                    % backtesting window valid for the whole AA
                    ds = find(dates>=start_dt_num); ds = ds(1);
                    de = find(dates<=end_dt_num);   de = de(end);
                    
                    nd = size(dates,1); % length of hist horizon
                    % in the next loop the irs is prices on each date of
                    % the hist horizon
                    % TODO: the pricer (class Cleg) cannot work as a
                    % 'vectorial function' at the moment. See if it can
                    % be appropriate in terms of time savings to modify
                    % it to be able to price the 'entire history' in one
                    % shot
                    
                    totReturnPV = [];
                    PriceTotReturn = [];
                    for t=ds:de
                        current_dt = dates(t);
                        tradeDate = dates(t);
                        params.repricing_dt = current_dt; % date of repricing
                        params.typeOfRepricing = 'Historical';
                        params.tradeDate = tradeDate;
                        
                        output = A.Reprice(params); % using the Reprice method of the sub-class

                        if isempty(output.PV) || isnan(output.PV)  % excluding NaNs while empty means that there are no curve's data for the current date
                            continue;
                        end
                        % DEBUG PANOS.
                        debug(t,:) = [current_dt output.PV output.accrualsTot output.PV+output.accrualsTot]; 
                        totReturnPV = [totReturnPV;[current_dt output.PV + output.accrualsTot]]; % not used for now (19012017)
                        PriceTotReturn = [PriceTotReturn;[current_dt output.PriceTotReturn]];
                        
                    end % cycling over the historical dates range
                
                    A.History.(PriceType).TimeSeries = PriceTotReturn; % historical timeseries ofr the IRS that will be used to calculate returns
                    
                end % if 'irs'
                
                % Getting info needed to manage returns'adj on rollovers
                % when calculatinmg returns
                if A.isFuture == 1
                     % TODO: see notes on the same topic: need to reorganize
                    % and fully automate (also making more robust) the mgmt
                    % of PriceType
                    % Here I am relying on the fact the the first element
                    % refers to the price of the asset
                    if iscell(PriceType)
                        ptype_fldName = PriceType{1};
                    else
                        ptype_fldName = PriceType;
                    end
                    
                    A.History.(ptype_fldName).HistFutTickers = d1(:,3);
                    % downloading the rolling date of the historical
                    % constituents'contracts
                    hist_tickers = unique(A.History.(ptype_fldName).HistFutTickers);
                   
                    RollingDates = [];
                    for k=1:size(hist_tickers,1)
                       
                        splitStr = regexp(A.Reference_Info.ticker_BBG,' ','split');
                        full_ticker = [hist_tickers{k},' ',splitStr{2}];
                        % getting Bloomberg static data through an instance 
                        % of class Utility
                        uparam.DataFromBBG = A.DataFromBBG;
                        uparam.ticker = full_ticker;
                        uparam.fields = ['FUT_ROLL_DT'];
                        uparam.override_fields = [];
                        uparam.override_values = [];
                        uparam.NOBBG = true(1);
                        uparam.save2disk = true(1);
                        uparam.BBG_SimultaneousData = A.BBG_SimultaneousData;
                        
                        U = Utilities(uparam);
                        U.GetBBG_StaticData;
                        dt = U.Output.BBG_getdata;
                        
                        % [dt,~] = getdata(A.bbgconn,full_ticker,{'FUT_ROLL_DT'});
                        if iscell(dt.FUT_ROLL_DT)
                            dt.FUT_ROLL_DT = cell2mat(dt.FUT_ROLL_DT);
                        end
                        RollingDates = [RollingDates, dt.FUT_ROLL_DT];
                    end
                    A.History.(ptype_fldName).RollingDates = RollingDates + 1;
                
                elseif A.isFuture == 2 % it is an OTC
                    if iscell(PriceType)
                        ptype_fldName = PriceType{1};
                    else
                        ptype_fldName = PriceType;
                    end
                    disp(['Getting rolling dates for the OTC product ',A.Reference_Info.ticker_BBG]);
                    RollingDates = A.rolloverDatesVector(A.History.Price.TimeSeries(:,1), A.RolloverRule);
                    A.History.(ptype_fldName).RollingDates = RollingDates;
                end % if is future
                
                
                if iscell(PriceType)
                    A.History.(PriceType{1}).Name = strrep(A.Reference_Info.ticker_BBG,' ','_'); % name of the security used to download history
                else
                    % TODO: temp fix: make that 'PriceType' field is always
                    % a cell and automnatize its mgmt
                    A.History.(PriceType).Name = strrep(A.Reference_Info.ticker_BBG,' ','_'); % name of the security used to download history
                end
            else
                m = msgbox('Invoking Bloomberg_GetHistory method not allowed for synthetic assets','Icon','warn');
            end
            
            
        end % Bloomberg_GetHistory
        
      
                
%         % metodo di tipo set che consente di verificare il valore assunto
%         % da un proprietà (Matlab esegue questa verifica at RunTime,
%         % generando un errore qualora l'utente o un metodo cerchi di
%         % attribuire a type un valore diverso da quelli consentiti
%         function settype = set.AssetType(settype,value)
%             if ~(strcmpi(value,'bond') | strcmpi(value,'equity') | strcmpi(value,'derivative') | strcmpi(value,'ETF') ...
%                     | strcmpi(value,'HF') | strcmpi(value,'credit') | strcmpi(value,'fx') | strcmpi(value,'commodity') ...
%                     | strcmpi(value,'cds') | strcmpi(value,'volatility') | strcmpi(value,'rates') | strcmpi(value,'gamma') ...
%                     | strcmpi(value,'options') | strcmpi(value,'asset swap') | strcmpi(value,'equity option') ...
%                     | strcmpi(value,'sensitivity') | strcmpi(value,'DVA') | strcmpi(value,'IRS') | strcmpi(value,'commodity') ...
%                     | strcmpi(value,'credit') | strcmpi(value,'shortRate') | strcmpi(value,'rate') | strcmpi(value,'equity future') ...
%                     | strcmpi(value,'spreadBonds') | strcmpi(value,'ABS'))
%                 error('Type not allowed')  
% 
%             else 
%                 settype.AssetType = value; % per assegnare il valore passato in input una volta superato il check
%             end
%         end
        
    end % methods
    
    methods(Static) % lo definisco come statico, così non devo passare l'oggetto (è una normale funzione)
        
        
        function nprices = Convert2Notionals(ts,crncy,ptval)
        % this function convert a timeseries of option or future prices into the corresponding
        % timeseries of notional amounts taking into account the $ value
        % of a point
        % ts: must be a [Tx2] matrix containing a set of date in the first
        % column and the corresponding prices in the second columns
        % crncy: this is the currency in which the option or future price
        % is denominated (NOT USED FOR NOW)
        % ptval: this is the monetary value of 1 point
      
        nprices(:,1) = ts(:,1); % dates vector is unchanged
        nprices(:,2) = ts(:,2).*ptval; % price x point value to get the notional 
       
        end % Convert2Notionals
        
        
        function unitprices = Cents2UnitsofCurrency(ts,crncy)
            % this function corrects prices expressed in cents (e.g. GBp,
            % USd, etc.), based on the crncy provided as input. ts must be
            % a 2 col vectors matrix (dates and prices
            if ~isempty(crncy) && crncy(end) == lower(crncy(end))
            % this equality should check all occurrences when the price is
            % denominated in cents (e.g. USd or GBp)
                unitprices(:,1) = ts(:,1);
                n = size(ts,2); % TODO: assign this 'n' outside the function (to deal with occurrences when we do not to divide by 100 all columns)
                unitprices(:,2:n) = ts(:,2:n)./100;
            else
                unitprices = ts;
            end

        end % Cents2UnitsofCurrency

        function rollingdates = rolloverDatesVector(dates, rule)
            if strcmp(rule,'W1')
                ff = find(dates==2);
                rollingdates = dates(ff,1);
            else
                error(['No rollover dates rule provided for OTC asset ',A.Reference_Info.ticker_BBG]);
            end
        end
        
    end % static methods
    
end



