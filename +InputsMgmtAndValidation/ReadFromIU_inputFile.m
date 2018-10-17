classdef ReadFromIU_inputFile < handle
    % this class is used to read Investment Universe constituents assets
    % from the an obj of type table:  provided as an input (params.UniverseTable).
    
    properties (Constant)
        % maps needed to implement a min set of preliminary checks
        ExchangeNotionalSet =  {'Yes', 'No'};
        ExchangeNotionalValues = [1 0];
        LegSideSet =  {'Paid','Received','Dead'};
        LegSideValues = [1 1 0];
    end
    
    properties (SetAccess = immutable)
        InputParams;
        ExchangeNotionalMap;
        LegSideMap;
    end
    
    properties (SetAccess = protected)
        % output vectors containing instances of the various classes
        % representing the assets in the IU
        E;          % for assets of class equity
        C;          % for assets of class equity (used to map commodities as well)
        B;          % for assets of class equity
        CDS;        % for assets of class equity
        SB;         % for assets of class swaps_cpnBonds
        O;          % for assets of class Option_Vanilla
        F;          % for assets of class fx
        RemovedAssetLog; % assets excluded because there is not enough history  ('MinHistDate4Assets' params definition)
        RemovedExternalInvariants; % external invariants that must be removed given MinHistDate4Assets
        ExcludedAssetsLog; % assets that it was not possible to define for various reason (e.g. not enough curve data)
        Ext_RF;
    end
    
    
    methods
        function I = ReadFromIU_inputFile(params)
            % Main Input: params with fields
            % .UniverseTable: table containing the Investment Universe
            % constituents
            % .history_start_date: start date of the hist window that will
            % be used to provide the various assets with a set of
            % historical prices
            % .history_end_date: same as above, but w.r.t. the end date
            % .DataFromBBG: the 'usual' struct containing info necessary to
            % retrieve data from Bloomberg
            % .hor: investment horizon
            % .Ext_RF: struct array of 'external risk factors'
            % .granularity; granularity of timeseries to be downloaded form
            % BBG
            % .params_Equity_ret: input params needed to calc returns
            % curves and surfaces objects needed to instantiate asset
            % classes
            % .IRcurves
            % .CdsCurves
            % .sIndices
            % .SWAP_curves
            % .VolaSurfaces
            % .additional_params: more params needed to instantiate some
            % assets
            % .params_cds_ret: parameters needed to instantiate cds
            % .BBG_SimultaneousData: repository of data already downloaded in a parallel
            % way from Bloomberg to speed up the assets setup processa
            
            import InvestmentUniverse.*;
            import ExternalRiskFactors.*;
            import InputsMgmtAndValidation.*;

            
            I.ExchangeNotionalMap = containers.Map(I.ExchangeNotionalSet,I.ExchangeNotionalValues);
            I.LegSideMap = containers.Map(I.LegSideSet,I.LegSideValues);
            
            I.InputParams = params;
            % ******************** Loading Investment Universe ****************
            
            UniverseTable = params.UniverseTable;
            history_start_date = params.history_start_date;
            history_end_date = params.history_end_date;
            DataFromBBG = params.DataFromBBG;
            hor = params.hor;
            I.Ext_RF = params.Ext_RF;
            granularity = params.granularity;
            params_Equity_ret = params.params_Equity_ret;
            IRcurves = params.IRcurves;
            CdsCurves = params.CdsCurves;
            sIndices = params.sIndices;
            SWAP_curves = params.SWAP_curves;
            VolaSurfaces = params.VolaSurfaces;
            additional_params = params.additional_params;
            params_cds_ret = params.params_cds_ret;
            
            eof = false(1);
            rowNum = 0;
            assetNum = 0;
            equity_cnt = 0;
            bond_ZCB_cnt = 0;
            fx_cnt = 0;
            Option_Vanilla_cnt = 0;
            cds_cnt = 0;
            irs_cnt = 0;
            % function handles: useful in the code below
            fnan = @I.nan2empty;
            isplit = @I.inputSplit;
            char2num = @I.chr2num;
            
            IV_start_date = history_start_date;
            IV_end_date = history_end_date;
            acc_mode = ['History'];
            
            % To avoid multiple download of regressors data when building
            % proxies for equities
            regressorMap = containers.Map;
            
            while ~eof
                if rowNum==size(UniverseTable,1)
                    break;
                end
                rowNum = rowNum + 1;
                ObjType = table2cell(UniverseTable(rowNum,'TypeOfObject'));
                if ~isempty(ObjType{1})
                    % reading fields common to all obj of mother class 'asset'
                    ticker = table2cell(UniverseTable(rowNum,'Asset_ticker_BBG'));
                    if strcmp(ticker{1},'TIT IM Equity')
                       disp('check'); 
                    end           
                    asset_type = table2cell(UniverseTable(rowNum,'Asset_asset_type'));
                    isproxy = char2num(table2cell(UniverseTable(rowNum,'Asset_isproxy')));
                    isETF = char2num(table2cell(UniverseTable(rowNum,'Asset_isETF')));
                    isFuture = char2num(table2cell(UniverseTable(rowNum,'Asset_isFuture')));
                    RolloverRule =  table2cell(UniverseTable(rowNum,'Asset_rolloverRule'));
                    RolloverRule = fnan(RolloverRule);
                    ticker_BBG_2 =  table2cell(UniverseTable(rowNum,'Asset_ticker_BBG_2'));
                    ticker_BBG_2 = fnan(ticker_BBG_2);
                    und_ticker = table2cell(UniverseTable(rowNum,'Asset_und_ticker'));
                    und_ticker = fnan(und_ticker);
                    enter_U_dt = char2num(table2cell(UniverseTable(rowNum,'Asset_enter_U_dt')));
                    enter_U_dt = fnan(enter_U_dt);
                    enter_U_dt = datestr(x2mdate(enter_U_dt));
                    aa_lim.lb = char2num(table2cell(UniverseTable(rowNum,'Asset_aa_lim_lb')));
                    aa_lim.lb = fnan(aa_lim.lb);
                    aa_lim.ub = char2num(table2cell(UniverseTable(rowNum,'Asset_aa_lim_ub')));
                    aa_lim.ub = fnan(aa_lim.ub);
                    % from 130617 (GP): currentWgts will read the optional
                    % field 'Asset_currentAA_optional' used to hold current
                    % portfolio weights. This is optional and used for
                    % reporting purposes only, to compare optimal weights
                    % with current ones
                    currentWgts = char2num(table2cell(UniverseTable(rowNum,'Asset_currentAA_optional')));
                    currentWgts = fnan(currentWgts);
                    
                    synthetic_ts = cell2mat(table2cell(UniverseTable(rowNum,'Asset_synthetic_ts')));
                    synthetic_ts = fnan(synthetic_ts);
                    synthetic = []; % default is non-synthetic asset
                    
                    if ~isempty(synthetic_ts)
                        
                        % synthetic_ts_colToRead is needed since we may want to be able to
                        % read prices from a table with more than one column (like it is
                        % the case when we read from a 'Curve' Object where we have
                        % different timeseries for different pillars
                        synthetic_ts_colToRead = char2num(table2cell(UniverseTable(rowNum,'Asset_synthetic_ts_colToRead')));
                        synthetic_ts_colToRead = fnan(synthetic_ts_colToRead);
                        synthetic_crncy = table2cell(UniverseTable(rowNum,'Asset_synthetic_crncy'));
                        synthetic_crncy = fnan(synthetic_crncy);
                        synthetic_priceType = table2cell(UniverseTable(rowNum,'Asset_synthetic_priceType'));
                        synthetic_priceType = fnan(synthetic_priceType);
                        synthetic.ts = synthetic_ts;
                        synthetic.crncy = synthetic_crncy;
                        
                        % TODO: review and organize better the mgmt of the
                        % synthetica assets flag and data reading for all
                        % the possible types of objects. In particular data
                        % reading from xls could be an extension of the
                        % current Single Indices input tab mgmt, like we do
                        % for IR curves read from an external file
                        if strcmp(ObjType{1},'bond_ZCB')
                            % in case curve data, the reference to the
                            % external file must be in the IR_Curves input
                            % sheet and they have been read already at this
                            % point, within the IR section in AA_Dashboard
                            synthetic.dates_prices = IRcurves.(synthetic.ts).Curve.dates;
                            synthetic.synthetic_prices = IRcurves.(synthetic.ts).Curve.rates(:,synthetic_ts_colToRead);
                            synthetic.currency = synthetic_crncy;
                            synthetic.price_type = synthetic_priceType;
                        elseif strcmp(ObjType{1},'equity')
                            % in case of n 'equity' obj the timeseries is read
                            % here. Assuming to have a 2 columns matrix
                            % (dates,pries) in d1, with meaningful data
                            % starting on row 2. Dates in xls date format
                            % TODO: add error mgmt checks
                            disp(['Reading synthetic timeseries from xls for ',ticker{1}]);
                            [d1,d2] = xlsread(synthetic_ts);
                            d1 = d1(2:end,:);
                            synthetic.dates_prices = x2mdate(d1(:,1));
                            synthetic.synthetic_prices = d1(:,2);
                            synthetic.currency = synthetic_crncy;
                            synthetic.price_type = synthetic_priceType;
                        end
                    end
                    
                    invertBbgSigns = char2num(table2cell(UniverseTable(rowNum,'Asset_invertBbgSigns')));
                    invertBbgSigns = fnan(invertBbgSigns);
                    MultiplyBBGPricesBy = char2num(table2cell(UniverseTable(rowNum,'Asset_MultiplyBBGPricesBy')));
                    MultiplyBBGPricesBy = fnan(MultiplyBBGPricesBy);
                    
                    % struct array needed to instantiate the base class 'asset'
                    % *********************************************************
                    assetParams.ticker_BBG = ticker{1};
                    assetParams.asset_type = asset_type;
                    assetParams.DataFromBBG = DataFromBBG;
                    assetParams.isproxy = isproxy;
                    assetParams.isETF = isETF;
                    assetParams.isFuture = isFuture;
                    assetParams.rollover_rule = RolloverRule;
                    assetParams.ticker_BBG_2 = ticker_BBG_2;
                    assetParams.und_ticker = und_ticker;
                    assetParams.enter_U_dt = enter_U_dt;
                    assetParams.aa_lim = aa_lim;
                    assetParams.hor = hor;
                    assetParams.synthetic = synthetic;
                    assetParams.invertBbgSigns = invertBbgSigns;
                    assetParams.MultiplyBBGPricesBy = MultiplyBBGPricesBy;
                    assetParams.accruals = []; % not USED
                    assetParams.external_RF = I.Ext_RF;
                    assetParams.currentWgts = currentWgts;
                    assetParams.BBG_SimultaneousData = params.BBG_SimultaneousData;
                    % *********************************************************
                    toeval_1 = [];
                    toeval_2 = [];
                    toeval_3 = [];
                    toeval_4 = [];
                    
                    disp(['Reading ',ticker{1},' from Investment Universe']);
                    
                    switch ObjType{1}
                        
                        case 'equity'
                            equity_cnt = equity_cnt + 1;
                            toeval_BloombergError = {'e = E(equity_cnt).BloombergError;'}; % to detect error in collecting descriptive data from Bloomberg: e.g. INVALID security
                            toeval_1 = {'E(equity_cnt) = equity(assetParams);'};
                            toeval_2 = {'E(equity_cnt).Bloomberg_GetHistory(history_start_date, history_end_date, granularity, [], []);'};
                            toeval_3 = {'E(equity_cnt).Price2Invariants(params_Equity_ret);'};
                            toeval_deletion = {'E(equity_cnt)=[];'};
                            toeval_cntBack = {'equity_cnt = equity_cnt - 1;'};
                            
                        case 'bond_ZCB'
                            clear FixedTtm;
                            % reading fields specific to bond_ZCB subclass
                            isRate = char2num(table2cell(UniverseTable(rowNum,'Bond_isRate')));
                            isRate = fnan(isRate);
                            FixedTtm.ttm = char2num(table2cell(UniverseTable(rowNum,'Bond_FixedTtm_ttm')));
                            FixedTtm.ttm = fnan(FixedTtm.ttm);
                            FixedTtm.accrue = []; %% NO MORE USED %%
                            MaturityDate = char2num(table2cell(UniverseTable(rowNum,'Bond_matdate')));
                            MaturityDate = fnan(MaturityDate);
                            MaturityDate = datestr(x2mdate(MaturityDate));
                            RefCurve = cell2mat(table2cell(UniverseTable(rowNum,'Bond_ref_curve')));
                            RefCurve = fnan(RefCurve);
                            if ~isempty(RefCurve)
                                RefCurve = IRcurves.(RefCurve);
                            end
                            
                            bond_ZCB_cnt = bond_ZCB_cnt + 1;
                            toeval_BloombergError = {'e = B(bond_ZCB_cnt).BloombergError;'}; % to detect error in collecting descriptive data from Bloomberg: e.g. INVALID security
                            toeval_1 = {'B(bond_ZCB_cnt) = bond_ZCB(assetParams,isRate,FixedTtm,MaturityDate,RefCurve);'};
                            toeval_2 = {'B(bond_ZCB_cnt).Bloomberg_GetHistory(history_start_date, history_end_date, granularity, [], []);'};
                            if isempty(MaturityDate)
                                toeval_3 = {'B(bond_ZCB_cnt).Price2Invariants();'};
                            else
                                % when it is a bond with fixed maturity it is priced
                                % using curve obj
                                toeval_3 = [];
                            end
                            toeval_deletion = {'B(bond_ZCB_cnt)=[];'};
                            toeval_cntBack = {'bond_ZCB_cnt = bond_ZCB_cnt - 1;'};
                            %% NO MORE USED %%
                            %                             if ~isempty(FixedTtm.accrue) & ~strcmp(FixedTtm.accrue,'rates') ...
                            %                                     & ~isnumeric(FixedTtm.accrue)
                            %                                 % if this field (see notes to class bond_ZCB) contains a Bloonberg ticker
                            %                                 % a method to download the timeseries of rates to be
                            %                                 % used for coupon accrual need to be invoked here
                            %                                 toeval_4 = {'B(bond_ZCB_cnt).GetCouponRates(history_start_date, history_end_date, granularity, [])'};
                            %                             end
                            
                        case 'fx'
                            fx_cnt = fx_cnt + 1;
                            toeval_BloombergError = {'e = F(fx_cnt).BloombergError;'}; % to detect error in collecting descriptive data from Bloomberg: e.g. INVALID security
                            toeval_1 = {'F(fx_cnt) = fx(assetParams);'};
                            toeval_2 = {'F(fx_cnt).Bloomberg_GetHistory(history_start_date, history_end_date, granularity, [], []);'};
                            toeval_3 = {'F(fx_cnt).Price2Invariants(params_Equity_ret);'};
                            toeval_deletion = {'F(fx_cnt)=[];'};
                            toeval_cntBack = {'fx_cnt = fx_cnt - 1;'};
                            
                        case 'Option_Vanilla'
                            % reading fields specific to Option_Vanilla subclass
                            underlying_ticker = table2cell(UniverseTable(rowNum,'Option_underlying_obj'));
                            
                            underlying_ticker = fnan(underlying_ticker);
                            underlying_obj = [];
                            % searching the vector E for the ticker in underlying_ticker
                            neq = size(E,2);
                            for k=1:neq
                                if strcmp(E(1,k).Reference_Info.ticker_BBG,underlying_ticker)
                                    underlying_obj = E(1,k);
                                    break
                                end
                            end
                            
                            curve_obj = table2cell(UniverseTable(rowNum,'Option_curve_obj'));
                            curve_obj = fnan(curve_obj);
                            if ~isempty(curve_obj)
                                curve_obj = IRcurves.(curve_obj);
                            end
                            
                            vola_surface_objName = cell(1);
                            vola_surface_objName{1} = fnan(table2cell(UniverseTable(rowNum,'Option_vola_surface_obj')));
                            
                            
                            try
                                vola_surface_obj = cell(1);
                                vola_surface_obj{1} = VolaSurfaces.(vola_surface_objName{1});
                                
                                % invoking method .GetExtendedIV for the
                                % object 'vola_surface_obj' to get the history
                                % of BBG ATM volas (when the data source is not
                                % MDS), that will be used later to get the swek
                                % at different price dates based on skew
                                % parameters estimates
                                und_hist_dates = underlying_obj.Invariants.Returns(:,1);
                                und_hist_returns = underlying_obj.Invariants.Returns(:,2);
                                histEstimWindow.start = history_start_date;
                                histEstimWindow.end = history_end_date;
                                vola_surface_obj{1}.GetExtendedIV(DataFromBBG,histEstimWindow,und_hist_dates,und_hist_returns);
                                
                                I.Ext_RF.addRiskFactors(vola_surface_obj,vola_surface_objName);
                            catch ME
                                if strcmp(ME.identifier,'MATLAB:nonExistentField')
                                    disp('check: Vola Surface curve not found: asset added to exceptions');
                                    I.FeedExcludedAssetsLog(assetParams.ticker_BBG,[': Vola Surface Obj not found in struct VolaSurfaces']);
                                    continue;
                                elseif strcmp(ME.identifier,'MATLAB:structRefFromNonStruct') & isempty(underlying_obj)
                                    disp('check: Underlying missing for this option: asset added to exceptions');
                                    I.FeedExcludedAssetsLog(assetParams.ticker_BBG,[': Underlying obj non existent']);
                                    continue;
                                else
                                    disp('check: unknown issue with Vola Surface Obj asset added to exceptions');
                                    I.FeedExcludedAssetsLog(assetParams.ticker_BBG,[': unknown issue with Vola Surface Obj']);
                                    continue;
                                end
                            end
                            
                            %   IMORTANT: when moneyness is not
                            % empty it must be assigned a value that reflects the
                            % relative position of the strike of the modeled option to
                            % the underlying price when the investment universe is
                            % built. Then this same moneyness will be used at the investment horizon
                            % of all repricing operations over the historical backtest window
                            moneyness = char2num(table2cell(UniverseTable(rowNum,'Option_moneyness')));
                            moneyness = fnan(moneyness);
                            time2expiry_OPTIONAL = table2cell(UniverseTable(rowNum,'time2expiry_OPTIONAL'));
                            time2expiry_OPTIONAL = fnan(time2expiry_OPTIONAL);
                            FixedExpiryFlag = table2cell(UniverseTable(rowNum,'FixedExpiryFlag'));
                            FixedExpiryFlag = fnan(FixedExpiryFlag);
                            expiry_date_OPTIONAL = table2cell(UniverseTable(rowNum,'ExpiryDate_OPTIONAL'));
                            expiry_date_OPTIONAL = fnan(expiry_date_OPTIONAL);
                            
                            Option_Vanilla_cnt = Option_Vanilla_cnt + 1;
                            toeval_BloombergError = {'e = O(Option_Vanilla_cnt).BloombergError;'}; % to detect error in collecting descriptive data from Bloomberg: e.g. INVALID security
                            toeval_1 = {'O(Option_Vanilla_cnt) = Option_Vanilla(assetParams,underlying_obj,curve_obj,vola_surface_obj{1}, IV_start_date, IV_end_date, moneyness, time2expiry_OPTIONAL,FixedExpiryFlag,expiry_date_OPTIONAL);'};
                            toeval_3 = {'O(Option_Vanilla_cnt).GetImpliedHistory;'};
                            toeval_deletion = {'O(Option_Vanilla_cnt)=[];'};
                            toeval_cntBack = {'Option_Vanilla_cnt = Option_Vanilla_cnt - 1;'};
                            
                        case 'cds'
                            % reading fields specific to cds subclass
                            cds_mult = char2num(table2cell(UniverseTable(rowNum,'CDS_cds_mult')));
                            cds_mult = fnan(cds_mult);
                            cds_notional = char2num(table2cell(UniverseTable(rowNum,'CDS_cds_notional')));
                            cds_notional = fnan(cds_notional);
                            rolldates1 = char2num(table2cell(UniverseTable(rowNum,'CDS_rolldates_1')));
                            rolldates1 = fnan(rolldates1);
                            rolldates2 = char2num(table2cell(UniverseTable(rowNum,'CDS_rolldates_2')));
                            rolldates2 = fnan(rolldates2);
                            rolldates = (x2mdate([rolldates1 rolldates2]));
                            
                            fixedcoupon = char2num(table2cell(UniverseTable(rowNum,'CDS_fixedcoupon')));
                            fixedcoupon = fnan(fixedcoupon);
                            dcurve = table2cell(UniverseTable(rowNum,'CDS_dcurve'));
                            dcurve = fnan(dcurve);
                            if ~isempty(dcurve)
                                dcurve = IRcurves.(dcurve);
                            end
                            
                            cds_curve = table2cell(UniverseTable(rowNum,'CDS_cds_curve'));
                            cds_curve = fnan(cds_curve);
                            if ~isempty(cds_curve)
                                try
                                    cds_curve = CdsCurves.(cds_curve);
                                catch ME
                                    if strcmp(ME.identifier,'MATLAB:nonExistentField')
                                        disp('check: CDS curve not found: asset added to exceptions');
                                        I.FeedExcludedAssetsLog(assetParams.ticker_BBG,[cds_curve,': CDS curve not found in struct CdsCurves']);
                                        continue;
                                    else
                                        rethrow(ME);
                                    end
                                end
                            end
                            
                            FixedTtm = char2num(table2cell(UniverseTable(rowNum,'CDS_FixedTtm')));
                            FixedTtm = fnan(FixedTtm);
                            
                            AccrueCDS_coupon = logical(char2num(table2cell(UniverseTable(rowNum,'CDS_AccrueCoupon'))));
                            AccrueCDS_coupon = fnan(AccrueCDS_coupon);
                            
                            cds_cnt = cds_cnt + 1;
                            params_CDS.cds_mult = cds_mult;
                            params_CDS.cds_notional = cds_notional;
                            params_CDS.rolldates = rolldates;
                            params_CDS.fixedcoupon = fixedcoupon;
                            params_CDS.dcurve = dcurve;
                            params_CDS.cds_curve = cds_curve;
                            params_CDS.FixedTtm = FixedTtm;
                            params_CDS.AccrueCDS_coupon = AccrueCDS_coupon;
                            
                            toeval_BloombergError = {'e = CDS(cds_cnt).BloombergError;'}; % to detect error in collecting descriptive data from Bloomberg: e.g. INVALID security
                            toeval_1 = {'CDS(cds_cnt) = cds(assetParams,params_CDS);'};
                            toeval_2 = {'CDS(cds_cnt).Bloomberg_GetHistory(history_start_date, history_end_date, granularity, [], additional_params);'};
                            toeval_3 = {'CDS(cds_cnt).Price2Invariants(params_cds_ret);'};
                            toeval_deletion = {'CDS(cds_cnt)=[];'};
                            toeval_cntBack = {'cds_cnt = cds_cnt - 1;'};
                            
                        case 'irs'
                            clear swap_params Curves4ccySwap;
                            swap_params.FxCurve = (isplit(table2cell(UniverseTable(rowNum,'FxCurve'))));
                            FixedTenor = cell2mat(table2cell(UniverseTable(rowNum,'FixedTenor')));
                            StartDt = x2mdate(cell2mat(table2cell(UniverseTable(rowNum,'StartDt'))));
                            swap_params.ConstantTenor = cell2mat(table2cell(UniverseTable(rowNum,'ConstantTenor')));
                            swap_params.Notional = (isplit(table2cell(UniverseTable(rowNum,'Notional'))));
                            swap_params.ExchangeNotional = ((isplit(table2cell(UniverseTable(rowNum,'ExchangeNotional')))));
                            swap_params.LegType = (isplit(table2cell(UniverseTable(rowNum,'LegType'))));
                            swap_params.LegSide = (isplit(table2cell(UniverseTable(rowNum,'LegSide'))));
                            swap_params.LegRateSpread = (isplit(table2cell(UniverseTable(rowNum,'LegRateSpread'))));
                            swap_params.LegCurType = (isplit(table2cell(UniverseTable(rowNum,'LegCurType'))));
                            swap_params.DomesticCurrency = ((table2cell(UniverseTable(rowNum,'DomesticCrncy'))));
                            swap_params.LegFrequency = (isplit(table2cell(UniverseTable(rowNum,'LegFrequency'))));
                            swap_params.LegAccrual = (isplit(table2cell(UniverseTable(rowNum,'LegAccrual'))));
                            %                             swap_params.LegMonthLag = (isplit(table2cell(UniverseTable(rowNum,'LegMonthLag'))));
                            swap_params.DiscountCurve = (isplit(table2cell(UniverseTable(rowNum,'DiscountCurves'))));
                            swap_params.DealtFx = cell2mat(table2cell(UniverseTable(rowNum,'DealtFx')));
                            swap_params.ForwardCurve = (isplit(table2cell(UniverseTable(rowNum,'ForwardCurves'))));
                            swap_params.FixingCurve = (isplit(table2cell(UniverseTable(rowNum,'FixingCurves'))));
                            swap_params.ZeroCurves = unique([swap_params.ForwardCurve,swap_params.DiscountCurve]);
                            % Tenor and StartDate will by determined dynamically in the IRS subclass
                            % based on the  type of modeled obj (fixed date tenor or constant tenor),
                            % so now they are held empty
                            if isnan(FixedTenor) & isnan(StartDt) & ~isnan(swap_params.ConstantTenor)
                                swap_params.Tenor = swap_params.ConstantTenor;
                                swap_params.StartDate = [];
                            elseif isnan(swap_params.ConstantTenor) & ~isnan(FixedTenor) & ~isnan(StartDt)
                                swap_params.StartDate = StartDt;
                                swap_params.Tenor = FixedTenor;
                            end
                            
                            % need to identify the curves corresponding to
                            % the floating legs (in the inbput file they
                            % must reflect the ordering of the floating
                            % legs)
                            tmp = cellfun(@(x)strfind(x,'Float'),swap_params.LegType,'UniformOutput',0);
                            tmp = cell2mat(tmp);
                            nFloatingLegs = numel(tmp);
                            fpos = find(tmp);
                            nZeroCurves = numel(swap_params.ZeroCurves);
                            
                            % *********************************************
                            % A MIN SET OF CHECKS ON INPUTS CONSISTENCY
                            % 1) The input fields checked below must all
                            % have the same no of constituents (that
                            % corresponds to the no of legs)
                            if ~(numel(swap_params.Notional)==numel(swap_params.ExchangeNotional)/2 ...
                                    & numel(swap_params.Notional)==numel(swap_params.LegType)/2 ...
                                    & numel(swap_params.Notional)==numel(swap_params.LegSide)/2 ...
                                    & numel(swap_params.Notional)==numel(swap_params.LegRateSpread)/2 ...
                                    & numel(swap_params.Notional)==numel(swap_params.LegCurType)/2 ...
                                    & numel(swap_params.Notional)==numel(swap_params.LegFrequency)/2 ...
                                    & numel(swap_params.Notional)==numel(swap_params.LegAccrual)/2 ...
                                    & numel(swap_params.Notional)==numel(swap_params.DiscountCurve)/2)
                                m = msgbox('ERROR (swaps input: see class ReadFromIU_inputFile): There is no consistency between the no of consituents of some inputs parameters (execution terminated press a key to continue)' ...
                                    ,'Icon','warn','replace');
                                pause;
                                return
                            end
                            % 2) the field ExchangeNotional can only have
                            % the form "Yes,Yes" or "No,No" unless one of
                            % the legs is "Dead" (modeling a Bond)
                            out1 = I.Mappings4Checks(swap_params.ExchangeNotional,'ExchangeNotional');
                            outExch = out1(:,1) == out1(:,2); % True if Yes/Yes or No/No
                            out2 = I.Mappings4Checks(swap_params.LegSide,'LegSide');
                            dead =  ~out2(:,1) | ~out2(:,2); % True if at Least one leg is dead
                            dead(outExch) = 1; % when Yes/Yes or No/No 'Dead' does not matter
                            finalCheck = outExch | dead;
                            
                            % TODO: REWRITE CHECKS: we can have Yes/No
                            %                             if finalCheck
                            %                             else
                            %                                 m = msgbox('ERROR (swaps input: see class ReadFromIU_inputFile): for any swap constituent the ExchangeNotional can be different from Yes/Yes or No/No only when at least one leg is dead (execution terminated press a key to continue)' ...
                            %                                     ,'Icon','warn','replace');
                            %                                 pause;
                            %                                 return
                            %                             end
                            
                            % *********************************************
                            
                            % Curves4ccySwap is a struct array with 3 subfields:
                            for k=1:nZeroCurves
                                try
                                    Curves4ccySwap.ZeroCurves{k} = SWAP_curves.(swap_params.ZeroCurves{k});
                                catch ME
                                    if strcmp(ME.identifier,'MATLAB:nonExistentField')
                                        Curves4ccySwap.ZeroCurves{k} = IRcurves.(swap_params.ZeroCurves{k});
                                    else
                                        rethrow(ME);
                                    end
                                end
                            end
                            
                            % TODO: when cross currency swaps will be
                            % implemented add a check to see if there is
                            % one FX curve for each non EUR curve (need to
                            % add a 'currency' field to curves obj)
                            Curves4ccySwap.FxCurve = []; % for cross currency swaps: not used at the moment. TO DO: implement !
                            
                            swap_params.Curves4ccySwap = Curves4ccySwap;
                            
                            irs_cnt = irs_cnt + 1;
                            toeval_BloombergError = {'e = SB(irs_cnt).BloombergError;'}; % to detect error in collecting descriptive data from Bloomberg: e.g. INVALID security
                            toeval_1 = {'SB(irs_cnt) = irs(assetParams,swap_params);'};
                            toeval_2 = {'SB(irs_cnt).Bloomberg_GetHistory(history_start_date, history_end_date, granularity, [], []);'};
                            %                             toeval_2 = []; % ***** temp: while updating the method Bloomberg_GetHistory
                            
                        otherwise
                            emsg2 = ['WARNING: there is an unknown asset type'];
                            toeval_1 = {'et=true(1);'};
                            
                    end % switch on obj type
                    
                    % execute
                    emsg = ['There has been a problem when retrieving des data from Bloomberg (e.g. INVALID SECURITY): asset put into ExcludedAssetsLog'];
                    
                    try
                        eval(toeval_1{1});
                        eval(toeval_BloombergError{1}); % this generates the variable e
                        if e==1
                            % 'self-generated' error caught by the try-catch
                            % below (for uniformity of tratement). %TODO: now
                            % for CDS only, extend to other assets
                            error(emsg);
                        end
                        if exist('et') && et == 1
                            % 'self-generated' error caught by the try-catch
                            % below (for uniformity of tratement). Error
                            % generated in case of unknown asset type
                            error(emsg2);
                        end
                        
                    catch ME
                        if strcmp(ME.message,emsg)
                            I.FeedExcludedAssetsLog(assetParams.ticker_BBG,'No DES data from Bloomberg (probably [INVALID SECURITY])');
                            eval(toeval_deletion{1}); % as the asset has been created
                            eval(toeval_cntBack{1});
                            continue;
                        elseif strcmp(ME.message,emsg2)
                            I.FeedExcludedAssetsLog(assetParams.ticker_BBG,'Unknown asset type');
                            continue;
                        else
                            rethrow(ME);
                        end
                    end
                    
                    if ~isempty(toeval_2) && isempty(synthetic)
                        try
                            eval(toeval_2{1});
                        catch ME
                            % managedMsg{1} = string('Interpolation requires at least two sample points in each dimension.');
                            % managedMsg{2} = string("Reference to non-existent field 'dates'.");
                            
                            % equivalent to the above for matlab versions with no class "string"
                            managedMsg{1} = ['Interpolation requires at least two sample points in each dimension.'];
                            managedMsg{2} = ['Reference to non-existent field ',sprintf('''dates''.')];
                            
                            if strcmp(ME.message,managedMsg{1})
                                disp('Not enough curve pillars: asset put into ExcludedAssetsLog');
                                I.FeedExcludedAssetsLog(assetParams.ticker_BBG,'Not enough tenors in CDS object');
                                % at this point the command in toeval_1 has
                                % been executed already and the instance
                                % representing the asset has been created.
                                % Hence it is necessary to remove it and bring the counter one step back.
                                eval(toeval_deletion{1});
                                eval(toeval_cntBack{1});
                                continue;
                                
                            elseif strcmp(ME.message,char(managedMsg{2}))
                                disp([ticker{1}, ' a problem occurred when deriving historical timeseries']);
                                disp(['- most likely cause is absence of curve data']);
                                I.FeedExcludedAssetsLog(assetParams.ticker_BBG,'Likely missing curve data');
                                eval(toeval_deletion{1});
                                eval(toeval_cntBack{1});
                                continue;
                            else
                                I.FeedExcludedAssetsLog(assetParams.ticker_BBG,'Unknown issue');
                                managedMsg{1} = ['Unknown problem'];
                                eval(toeval_deletion{1});
                                eval(toeval_cntBack{1});
                                continue;
                            end
                        end % try
                    end
                    
                    try
                        if ~isempty(toeval_3)
                            eval(toeval_3{1});
                        end
                    catch ME
                        if strcmp(ME.identifier,'MATLAB:structRefFromNonStruct')
                            disp('probable missing vola surface obj: asset added to the Exceptions list');
                            I.FeedExcludedAssetsLog(assetParams.ticker_BBG,['Option excluded: probably because of missing vola Surface Obj']);
                            % at this point the command in toeval_1 has
                            % been executed already and the instance
                            % representing the asset has been created.
                            % Hence it is necessary to remove it and bring the counter one step back.
                            eval(toeval_deletion{1});
                            eval(toeval_cntBack{1});
                            continue;
                        elseif strcmp(ME.identifier,'finance:blscheck:NaNVolatility')
                            disp('NaN Values in historical implied volatility: asset added to the Exceptions list');
                            I.FeedExcludedAssetsLog(assetParams.ticker_BBG,['Option excluded: NaN values in implied vola']);
                            % at this point the command in toeval_1 has
                            % been executed already and the instance
                            % representing the asset has been created.
                            % Hence it is necessary to remove it and bring the counter one step back.
                            eval(toeval_deletion{1});
                            eval(toeval_cntBack{1});
                            continue;
                        else
                            disp('option excluded for unknown reason');
                            I.FeedExcludedAssetsLog(assetParams.ticker_BBG,['Option excluded: unknown reason']);
                            eval(toeval_deletion{1});
                            eval(toeval_cntBack{1});
                            continue;
                            % ** rethrow(ME);
                        end
                    end
                    
                    if ~isempty(toeval_4)
                        eval(toeval_4{1});
                    end
                    
                else
                    eof = true(1); % assume EOF is reached when there is a row that does not begin with the type of obj
                end
                
                if rowNum==size(UniverseTable,1)
                    eof = true(1);
                end
                
                % ************************
                % **** EQUITY PROXIES ****
                % ************************
                if strcmp(ObjType{1},'equity') && ...
                        min(E(equity_cnt).Invariants.Prices(:,1)) > datenum(I.InputParams.MinHistDate4Assets) % if not enough history
                    
                    % ** added by EB to proxy assets of type equity when
                    % they lack history 
                    
                    % Asset Class name
                    assetClass = 'E';
                    
                    % Asset name
                    assetName = strrep(E(equity_cnt).Invariants.Name, '_', ' ');
                    proxyMap  = I.InputParams.proxyParam.Equity.proxyMap;
                    
                        
                        % REGRESSOR:
                        % get data needed to build the proxy
                        autoProxy = E(equity_cnt).Specific_Attributes.REL_INDEX{1};
                        
                        if ismember(assetName,keys(proxyMap))
                            regressorName = proxyMap(assetName);  % (it is the main condition to test with TRY-CATCH)

                            %                             if isempty(regressorName) & ~isempty(autoProxy)
                            %                                 error('ReadFromIU_inputFile:EmptyEquityProxy',...
                            %                                     'Error. regressor name is empty%s.',class(n))
                            %                             else
                            %                                 continue;
                            %                             end
                        end
                        
                        if (~ismember(assetName,keys(proxyMap)) | isempty(regressorName)) & ~isempty(autoProxy)
                            
                            regressorName = [autoProxy,' Index'];
                        else
                            continue
                        end
                         

                        iu_params = I.InputParams;
                        tickersIU = I.InputParams.UniverseTable.Asset_ticker_BBG;
                        [~, loc] = ismember(assetName, tickersIU);
                        iu_params.UniverseTable = iu_params.UniverseTable(loc, :);
                        iu_params.UniverseTable.Asset_isproxy = 1;
                        iu_params.UniverseTable.Asset_ticker_BBG = regressorName; % Proxy ticker!
                        % Get Regressor data
                        try
                            I_reg = regressorMap(regressorName);
                        catch MM
                            if strcmp(MM.identifier,'MATLAB:Containers:Map:NoKey')
                                I_reg = ReadFromIU_inputFile(iu_params);
                                % To avoid multiple downloads
                                regressorMap(regressorName) = I_reg;
                            else
                                rethrow(MM);
                            end
                        end
                        
                        % PROXY:
                        % Asset params
                        proxyParam.Asset_Obj   = E(equity_cnt);
                        proxyParam.Asset_Name  = E(equity_cnt).Invariants.Name;
                        proxyParam.Asset_Ret   = E(equity_cnt).Invariants.Returns;
                        proxyParam.Asset_Price = E(equity_cnt).Invariants.Prices;
                        % Regressor params
                        proxyParam.Regressor_Obj   = I_reg.(assetClass);
                        proxyParam.Regressor_Name  = I_reg.(assetClass).Invariants.Name;
                        proxyParam.Regressor_Ret   = I_reg.(assetClass).Invariants.Returns;
                        proxyParam.Regressor_Price = I_reg.(assetClass).Invariants.Prices;
                        
                        % Returns type
                        proxyParam.retType = '';
                        % Other Setting
                        proxyParam.chunkSize  = 40;
                        proxyParam.firstCoeff = false(1); % true: apply alpha and beta of the first chunk to the past dates; false: otherwise
                        % Build Proxy (Prices and Returns)                       
                        uObject = Utilities(proxyParam);
                        uObject.buildEquityProxy;
                        % Output
                        proxyParam.Proxy_Ret   = uObject.Output.Proxy_Ret;
                        proxyParam.Proxy_Price = uObject.Output.Proxy_Price;
                        
                        disp(['Generating Asset: ', [proxyParam.Asset_Name ' >>> ' proxyParam.Regressor_Name]]);
                        
                                                
                        % ENFORCE PROXY:
                        % "enforceProxy" is a method of "Equity" class to adjust price and compute Invariants
                        paramsEP.proxyParam = proxyParam;
                        % Params needed as input for "Price2Invariants" methods
                        paramsEP.inputParams   = I.InputParams;
                        proxyParam.Asset_Obj.enforceProxy(paramsEP);
                        proxyParam.Proxy_Obj   = proxyParam.Asset_Obj;
                        proxyParam             = rmfield(proxyParam,'Asset_Obj');
                        proxyParam.Proxy_Ret   = proxyParam.Proxy_Obj.Invariants.Returns;
                        proxyParam.Proxy_Price = proxyParam.Proxy_Obj.Invariants.Prices;
                        % New time series
                        E(equity_cnt) = proxyParam.Proxy_Obj; % this passage should not be needed
                        

                          % Plot
%                         % 1) original asset
%                         Price_Orig  = proxyParam.Asset_Price(:,end);
%                         Price_OrigD = proxyParam.Asset_Price(:,1);
%                         Ret_Orig    = proxyParam.Asset_Ret(:,end);
%                         % 2) regressor asset
%                         Price_Regr  = proxyParam.Regressor_Obj.Invariants.Prices(:,end);
%                         Price_RegrD = proxyParam.Regressor_Obj.Invariants.Prices(:,1);
%                         Ret_Regr    = proxyParam.Regressor_Obj.Invariants.Returns(:,end);
%                         % 3) proxy
%                         Price_Proxy  = proxyParam.Proxy_Price(:,end);
%                         Price_ProxyD = proxyParam.Proxy_Price(:,1);
%                         Ret_Proxy    = proxyParam.Proxy_Ret(:,end);
%                         plot(Price_ProxyD, Price_Proxy, 'b', Price_OrigD, Price_Orig, 'r');
%                         title(['Orginal Asset:   ', strrep(proxyParam.Asset_Name,'_',' ')]);
%                         legend('Proxy','Asset','Location','southoutside');
%                         axlim = get(gca, 'XLim'); 
%                         aylim = get(gca, 'YLim'); 
%                         x_txt = min(axlim) + 0.05*diff(aylim); 
%                         y_txt = min(aylim) - 0.25*diff(aylim); 
%                         y_txt1 = min(aylim) - 0.35*diff(aylim); 
%                         text(x_txt, y_txt, ['Proxy size: ' num2str(size(Price_Proxy,1))]);
%                         text(x_txt, y_txt1, ['Asset size: ' num2str(size(Price_Orig,1))]);

                        continue
                        
                    
                    % ** EB
                    
                end % if ObjType is 'equity'
                
                % ************************
                % **** EQUITY PROXIES ****
                % ****     e n d      ****
                % ************************
                
            end % while not eof
            
            % *************************************************************
            % ******************  End Of Investment Universe Loading ******
            % *************************************************************
            % *************************************************************
            if exist('E','var') && ~isempty(E)
                I.E = E;
            end
            if exist('B','var') && ~isempty(B)
                I.B = B;
            end
            if exist('C','var') && ~isempty(C)
                I.C = C;
            end
            if exist('CDS','var') && ~isempty(CDS)
                I.CDS = CDS;
            end
            if exist('SB','var') && ~isempty(SB)
                I.SB = SB;
            end
            if exist('O','var') && ~isempty(O)
                I.O = O;
            end
            if exist('F','var') && ~isempty(F)
                I.F = F;
            end
            
            % I want to exclude assets whose history is not long enough
            if  ~isempty(I.InputParams.MinHistDate4Assets)
                I.AssetSelectionOnDates;
            end
            
            % I want to exclude assets whose history is not dense enough
            I.AssetSelectionOnDataDensity;
            
            
        end % constructor
        
        function out = Mappings4Checks(I,in,map_choice)
            s = size(in,2);
            r = 0;
            c = 0;
            for k=1:s
                
                r = r + ~c;
                c = c + 1;
                
                if strcmp(map_choice,'ExchangeNotional')
                    out(r,c) = I.ExchangeNotionalMap(in{k});
                elseif strcmp(map_choice,'LegSide')
                    out(r,c) = I.LegSideMap(in{k});
                end
                
                c = mod(c,2).*c;
            end
        end
        
        function AssetSelectionOnDates(I)
            % this function selects the assets to include in Universe
            % in case ~isempty(I.InputParams.MinHistDate4Assets)
            % the selection is done using this MinHistDate4Assets to
            % exclude assets that do not have a min history length.
            
            RemovedAssetLog = {};
            RemovedExternalInvariants = {};
            
            fldNames = fieldnames(I);
            nflds = numel(fldNames);
            
            %             % To avoid multiple download of regressor data
            %             regressorMap = containers.Map;
            
            for k=1:nflds % looping of the various types of assets (e.g. E for equities, Option_Vanilla for options, etc.)
                
                metaclassObj = metaclass(I.(fldNames{k}));
                
                if numel(metaclassObj.SuperclassList) && strcmp(metaclassObj.SuperclassList.Name,'InvestmentUniverse.asset') % only if is is a field of class 'asset'
                    
                    nOfAssets = numel(I.(fldNames{k})); % number of assets in the vector
                    toRemove = [];
                    
                    for y=1:nOfAssets % looping over all of the assets within the k-th type
                        
                        nOfInvariants = numel(I.(fldNames{k})(y).Invariants);
                        
                        for y1=1:nOfInvariants
                            
                            if  isempty(I.(fldNames{k})(y).Invariants(y1).Prices) || min(I.(fldNames{k})(y).Invariants(y1).Prices(:,1)) > ...
                                    datenum(I.InputParams.MinHistDate4Assets) % if any of the underlying invariants has not enough history
                                
                                
                                toRemove = [toRemove;y];
                                RemovedAssetLog = [RemovedAssetLog;I.(fldNames{k})(y).Reference_Info.ticker_BBG];
                                
                                % the external invariants whose history is too short (given 'MinHistDate4Assets') must  removed,
                                % OTHERWISE THEY would reduce the overall available dataset anyway
                                % (through the method .GetInvariantEmpiricalDistribution of class universe.m)
                                
                                if I.(fldNames{k})(y).Invariants(y1).External4AtHorizonModeling
                                    RemovedExternalInvariants = [RemovedExternalInvariants;I.(fldNames{k})(y).Invariants(y1).Name];
                                    I.Ext_RF.removeRiskFactors(I.(fldNames{k})(y).Invariants(y1).Name);
                                end
                                
                                
                                % ** break;
                                % cannot break here: need to iterate over all invariants to be sure
                                % to get rid of too short external invariants as well
                                
                            end % if
                            
                        end % loop on y1 (invariants)
                        
                    end % loop on y (assets)
                    
                    I.(fldNames{k})(toRemove) = [];
                end
            end
            
            RemovedAssetLog = unique(RemovedAssetLog);
            I.RemovedAssetLog = RemovedAssetLog;
            I.RemovedExternalInvariants = unique(RemovedExternalInvariants);
            
        end % AssetSelectionOnDates
        
        function AssetSelectionOnDataDensity(I)
            % this function selects the assets to include in Universe
            % the selection is done using the average interval between dates into
            % the asset price history, to remove assets with few data
            
            RemovedAssetLog = {};
            RemovedExternalInvariants = {};
            
            
            fldNames = fieldnames(I);
            nflds = numel(fldNames);
            
            
            for k=1:nflds % looping of the various types of assets (e.g. E for equities, Option_Vanilla for options, etc.)
                
                metaclassObj = metaclass(I.(fldNames{k}));
                
                if numel(metaclassObj.SuperclassList) && strcmp(metaclassObj.SuperclassList.Name,'InvestmentUniverse.asset') % only if is is a field of class 'asset'
                    
                    nOfAssets = numel(I.(fldNames{k})); % number of assets in the vector
                    toRemove = [];
                    
                    for y=1:nOfAssets % looping over all of the assets within the k-th type
                        
                        nOfInvariants = numel(I.(fldNames{k})(y).Invariants);
                        SparseDatas = [];
                        
                        for y1=1:nOfInvariants
                            
                            % 2 creteria to detect if an asset is not
                            % enouth dense:
                            % 1) there must be at least 80% of the business
                            % days filled
                            % 2) gaps no longer than 15 business days
       
                            dates = I.(fldNames{k})(y).Invariants(y1).Prices(:,1);
                            bdates = busdays(min(dates),max(dates));
                            DateDensity = numel(dates)/numel(bdates);
                            maxGap = max(diff(dates));
      
                            if  DateDensity < 0.75 |  maxGap > 60 % 0.80 e 15 usually
                                
                                toRemove = [toRemove;y];
                                RemovedAssetLog = [RemovedAssetLog;I.(fldNames{k})(y).Reference_Info.ticker_BBG];
                              
                            end % if
                            
                        end % loop on y1 (invariants)
                        
                    end % loop on y (assets)
                    
                    I.(fldNames{k})(toRemove) = [];
                end
            end
            
            if ~isempty(RemovedAssetLog)
                    % ** I.RemovedAssetLog(end+1,:) = unique(RemovedAssetLog);
                    I.RemovedAssetLog = [I.RemovedAssetLog;unique(RemovedAssetLog)];
            end
          
        end % AssetSelectionOnDataDensity
        
        function FeedExcludedAssetsLog(I,assetID,reason)
            % method used to fill in the log ExcludedAssetsLog, listing
            % assets that for some reason it was not possible to read
            % assetID: id of the excluded asset (ISIN, ticker, etc.)gi
            % reason for exclusion
            sz = size(I.ExcludedAssetsLog,1);
            sz = sz + 1;
            I.ExcludedAssetsLog{sz,1} = assetID;
            I.ExcludedAssetsLog{sz,2} = reason;
        end
    end % public methods
    
    methods (Static)
        function output = inputSplit(inputvar)
            
            if iscell(inputvar) % must be a cell array
                if isnan(inputvar{1})
                    output = [];
                    return
                end
                tmp = [];
                for i =1:length(inputvar)
                    tmp = strcat(tmp,inputvar{i},[',']);
                    
                end
                tmp = regexp(tmp,',','split');
                fempty = cellfun(@isempty,tmp,'UniformOutput',0);
                tmp(cell2mat(fempty))=[];
                output = tmp;
            else
                output = [];
            end
        end
        
        
        function output = nan2empty(inputvar)
            starting_inputvar = inputvar;
            if iscell(inputvar)
                inputvar = cell2mat(inputvar);
            end
            if isnan(inputvar)
                output = [];
            else
                output = inputvar;
            end
            
        end
        
        function output = chr2num(inputvar)
            
            if iscell(inputvar)
                inputvar = cell2mat(inputvar);
            end
            if isstr(inputvar)
                inputvar = str2num(inputvar);
            end
            output = inputvar;
        end
        
        function out = ParseMultipleObjInput(in)
            % cell array made of multiple strings separated by comma to be
            % parsed
            if ~iscell(in)
                if isnan(in) % if all NaNs
                    out = {};
                    return
                end
            end
            expression = '\w*';
            tmp = strjoin(in,',');
            [~, tmp1] = regexp(tmp,expression,'tokens','match','ignorecase');
            out = unique(tmp1');
        end % ParseMultipleObjInput
        
        function out = AppendAndClean(in,varargin)
            % INPUTs:
            % -> in: input cell array to which we want to append (can be
            % empty)
            % -> varargin: cell arrays to be appended: only non empty arrays will be
            % appended
            % **** DUPLICATES AND EMPTY CELLS ARE REMOVED ***
            out = in;
            for k=1:numel(varargin)
                if ~isempty(varargin{k}) % otherwise it means that it's empty
                    out = [out;varargin{k}];
                end
            end
            
            out = unique(out);
            aa1=cellfun(@isempty,out,'UniformOutput',0);
            out(cell2mat(aa1)) = []; % removing empty cells
            
        end % AppendAndClean
        
    end % static methods
    
end % classdef

