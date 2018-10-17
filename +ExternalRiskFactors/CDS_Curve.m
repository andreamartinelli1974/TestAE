classdef CDS_Curve < handle
    % Instances of this class gather historical data for a given CDS curve
    properties
        Curve = []; % main output
        ExcludedCDS_CurvesLog; % to manage cases when we exit the function without building the curve due to  problems with data for example
    end
    
    % TODO: add a property to this and similar classes (e.g. IR_Curve)
    %  indicating the fromat of data (e.g. if rates are percentages, bps or
    %  fractions)
    
    properties (Constant)
        % the default format for rates in this class is 'percentage' (e.g. 2
        % means 2%) if the input format is different then it will be converted into
        % 'p' format
        RatesFormat = 'p';
        
        % mapping curve tenors (from Bloomberg) to year fraction terms
        TenorsKeySet1 =  {'3 MO', '6 MO', '1 YR', '2 YR', '3 YR', '4 YR', '5 YR', ...
            '7 YR', '10 Y', '15 Y', '20 Y', '30 Y'};
        TenorsKeySet4xlsFiles1 =  {'3 spreadm', '6 spreadm', '1 spready', '2 spready', '3 spready', '4 spready', '5 spready', ...
            '7 spready', '10 spready', '15 spready', '20 spready', '30 spready'};
        TenorsValueSet1 = [0.25 0.50 1 2 3 4 5 7 10 15 20 30];
        
        TenorsKeySet2 =  {'3 MO', '6 MO', '1 YR', '2 YR', '3 YR', '4 YR', '5 YR', ...
            '6 YR', '7 YR', '8 YR', '9 YR', '10 Y', '15 Y', '20 Y', '25 Y', '30 Y'};
        TenorsKeySet4xlsFiles2 =  {'91 D', '182 D', '365 D', '730 D', '1095 D', '1460 D', '1825 D', ...
            '2190 D', '2555 D', '2920 D', '3285 D', '3650 D', '5475 D', '7300 D', '9125 D', '10950 D'};
        TenorsValueSet2 = [0.25 , 0.5 , 1 , 2 , 3 , 4 , 5 , 6 , 7 , 8 , 9 , 10 , 15 , 20 , 25 , 30];
        
        % Mapping of MDS year fraction representation into Bloomberg year
        % fraction representation for CDS ticker construction (this is needed when using MDS data source
        % to be able to create 'C.Curve.Tickers2ColumnsMap' mapping that is
        % created when using BBG or XLS data (this mapping is then used
        % within the class asset.m to identify specific risk factors
        % defined as credit spreads)
        MdsTenorSet1 = {'x6M', 'x1Y', 'x2Y', 'x3Y', 'x4Y', 'x5Y', 'x7Y', 'x10Y', 'x15Y', 'x20Y', 'x30Y'};
        MdsTenorSet2 = {'x91'; 'x182'; 'x365'; 'x730'; 'x1095'; 'x1460'; 'x1825'; ...
            'x2190'; 'x2555'; 'x2920'; 'x3285'; 'x3650'; 'x5475'; 'x7300'; 'x9125';'x10950'};
        BloombergValueSet1 = {'6M', '1Y', '2Y', '3Y', '4Y', '5Y', '7Y', '10Y', '15Y', '20Y', '30Y'};
        BloombergValueSet2 = {'3M', '6M', '1Y', '2Y', '3Y', '4Y', '5Y', '6Y', '7Y', '8Y', '9Y', '10Y', '15Y', '20Y', '25Y', '30Y'};
        
        % put here a list of complete tokens that can appear in the Bloomberg  CDS
        % ticker name (e.g. AEGON CDS EUR SR 5Y D14 Corp). This is needed
        % later to insert the tenor (e.g. "5Y") before the token, since
        % this is the correct syntax, otherwise there could be problem
        % later when matchin the CDS name taken from Bloomberg with the
        % label of specific tenors on the curve
        ISDA_typeToken = {'D11','D14','SPRD'};
    end
    
    properties (SetAccess = private)
        TenorsMap_xlsString2BBGstring;
    end
    
    properties (SetAccess = immutable) % solo il constructor può modificare queste proprietà
        curve_tickers = []; % Bloomberg ticker for the zero curve
        Names = []; % derived from the previous field
        StartDate = []; % first date of the historical range
        EndDate = []; % last date of the historical range
        Filename = []; % name of the .mat file used to store hist data
        DataFromBBG = []; % Bloomberg connection
        TenorsMap  = []; % Tenor
        TenorsMap4xlsFiles; % tenors map for xls file input
        Name = []; % name of the curve (as an input). Important since it will be used to reference the invariants
        PriceUsed = [];
        IntExt = []; % Internal/External risk factor
        ToBeIncludedInInvariants = [];
        RatesInputFormat = [];
        tenorMapType; % only for input from Excel allows to define the map based on the input format used (2 available for now)
        CurveInputParams;
        MapMdstenorsToBBG;
    end
    
    methods
        function C = CDS_Curve(name,DataFromBBG,curve_tickers,historical_window,price_used,params_CDS_crv) % constructor
            % name: name of the curve: USE THE ROOT COMMON TO THE tickers
            % listed in curve_tickers: eg ITRX EUR CDSI GEN if the vector
            % of tickers is {'ITRX EUR CDSI GEN 3Y Corp';'ITRX EUR CDSI GEN 5Y Corp'
            % 'ITRX EUR CDSI GEN 7Y Corp';'ITRX EUR CDSI GEN 10Y Corp'}
            % DataFromBBG: BBG connection object and data access options
            % (see class Utilities'comments for more details)
            % curve_tickers: a cell array of tickers identitying the
            % various tenors. NEW (310717 - GP): when using MDS as data
            % source then 'curve_tickers' will contain only the generic BBG
            % ticker for the curve, with no maturity indication. Then the
            % series of Bloomberg tickers will be built below (since the
            % mapping MdsTenorSet / BloombergValueSet is needed
            % historical_window: struct containing start date and end dates in the format mm/dd/yyyy (< than current date: no checks implemented)
            % price_used:  'ROLL_ADJUSTED_MID_PRICE' or 'LAST_PRICE'
            % under struct params_CDS_crv:
            % excel_spread_input.flag: true(1) if input credit spreads must
            % be read from xls. In this case the following fields must be
            % provided as well
            % .excel_spread_input.manual_ticker
            % .extrapolate and .thresholdForInterpolating are parameters
            % needed to invoke the method "InterpolationMixed" of class
            % Utilities
            % .excel_spread_input.inputMatrix: this the matrix of credit
            % spreads that must be provided (usually reading from an open
            % xls connection interface)
            % .RatesInputFormat: format of the inputs read from the input
            % source: 'f' for fraction (e.g. 0.02 means 2%), 'bps' for
            % basis points, 'p' for percentage (e.g. 10 means 10%)
            % int_ext: 'External' if the curve has to be included in the
            % External Risk Factors obj of class External_Risk_Factors that
            % will be created within  AA_DashBoard
            % ToBeIncludedInInvariants:  this parameters specify if, when
            % int_ext == 'External', it has to be included within the
            % AllInvariants matrix of the obj of class universe (in this
            % case it will be included in the semiparametric distribution
            % modeling, resampling, projection to the horizon process)
            
            C.CurveInputParams = params_CDS_crv;
            C.Name = name;
            C.curve_tickers = curve_tickers;
            C.DataFromBBG = DataFromBBG;
            C.StartDate = historical_window.startDate;
            C.EndDate = historical_window.endDate;
            C.tenorMapType = params_CDS_crv.tenorMapType;
            switch C.tenorMapType
                case 1
                    C.TenorsMap = containers.Map(C.TenorsKeySet1, C.TenorsValueSet1);
                    C.TenorsMap4xlsFiles = containers.Map(C.TenorsKeySet4xlsFiles1, C.TenorsValueSet1);
                    C.TenorsMap_xlsString2BBGstring = containers.Map(C.TenorsKeySet4xlsFiles1, C.TenorsKeySet1);
                    C.MapMdstenorsToBBG = containers.Map(C.MdsTenorSet1, C.BloombergValueSet1);
                case 2
                    C.TenorsMap = containers.Map(C.TenorsKeySet2, C.TenorsValueSet2);
                    C.TenorsMap4xlsFiles = containers.Map(C.TenorsKeySet4xlsFiles2, C.TenorsValueSet2);
                    C.TenorsMap_xlsString2BBGstring = containers.Map(C.TenorsKeySet4xlsFiles2, C.TenorsKeySet2);
                    C.MapMdstenorsToBBG = containers.Map(C.MdsTenorSet2, C.BloombergValueSet2);
                otherwise
                    error('Wrong "C.tenorMapType" value');
            end
            C.PriceUsed = price_used;
            C.IntExt = params_CDS_crv.int_ext;
            if isfield(params_CDS_crv,'ToBeIncludedInInvariants')
                % to avoid exceptions if this input field is not provided
                % (e.g. it is needed for AA purposes, when instances of the
                % the class are used as inputs to objects of class
                % univesr, but it is not needed for FA for example)
                I.ToBeIncludedInInvariants = params_CDS_crv.ToBeIncludedInInvariants;
            end
            C.RatesInputFormat = params_CDS_crv.RatesInputFormat;
            
            s = size(C.curve_tickers,1);
            cnt = 0;
            col2delete = [];
            
            if params_CDS_crv.excel_spread_input.flag ~= 2 % if data NOT from MDS
                
                for k=1:s
                    disp(['Build dataset for CDS tenor: ',curve_tickers{k,1}]);
                    % downloading term (tenor) and its mapping to year
                    % fractions
                    
                    % *****************  DATA FROM BLOOMBERG ******************
                    if params_CDS_crv.excel_spread_input.flag == 0 % data from BBG
                        % getting Bloomberg static data through an instance
                        % of class Utility
                        uparam.DataFromBBG = DataFromBBG;
                        uparam.ticker = curve_tickers{k,1};
                        uparam.fields = {'CDS_TERM'};
                        uparam.override_fields = [];
                        uparam.override_values = [];
                        U = Utilities(uparam);
                        U.GetBBG_StaticData;
                        d = U.Output.BBG_getdata;
                        
                        % [d,~] = getdata(BBGconn,curve_tickers{k,1},{'CDS_TERM'});
                        % temporary: sometimes 'getdata' returns an empty field for
                        % CDS_TERM: in this case for now ask directly to the user
                        if isempty(d.CDS_TERM{1})
                            col2delete = [col2delete,k];
                            continue;
                        end
                        
                        % getting historical data through
                        % an instance of class Utilities
                        uparam.DataFromBBG = C.DataFromBBG;
                        uparam.ticker = curve_tickers{k,1};
                        uparam.fields = C.PriceUsed;
                        uparam.history_start_date = C.StartDate;
                        uparam.history_end_date = C.EndDate;
                        uparam.granularity = ['daily'];
                        U = Utilities(uparam);
                        U.GetHistPrices;
                        d1 = U.Output.HistInfo;
                        % [d1,~] = history(C.BBGconn,curve_tickers{k,1},C.PriceUsed,startdt,today,'daily');
                        if isempty(d1)
                            col2delete = [col2delete,k];
                            continue;
                        end
                        
                        switch C.RatesInputFormat
                            case 'f'
                                d1(:,2) = d1(:,2).*100;
                            case 'bps'
                                d1(:,2) = d1(:,2)./100;
                            case 'p'
                                % nothing to do: this is the default
                        end
                        
                        cnt = cnt + 1;
                        tenors{cnt,1} = d.CDS_TERM{1};
                        
                        % ******************  DATA FROM EXCEL ********************
                    elseif params_CDS_crv.excel_spread_input.flag == 1 % data from xls files
                        if k== 1 % read the full table only initially
                            
                            T = cell2table(params_CDS_crv.excel_spread_input.inputMatrix,'VariableNames', ...
                                params_CDS_crv.excel_spread_input.inputMatrix(1,:));
                            T(1,:) = [];
                            nanPos = isnan(cell2mat(table2cell(T(:,1))));
                            T(nanPos,:)=[];
                            
                            allflds = fieldnames(T);
                            tenorflds0 = allflds(params_CDS_crv.excel_spread_input.firstCDScol:params_CDS_crv.excel_spread_input.lastCDScol);
                            tenorflds = strrep(tenorflds0,'x',''); % removing the 'x' that Matlab uses as a first char when the fieldname starts with a number
                            % this is to add back to the name of the tenor the
                            % space that Matlab removes from the names of the
                            % columns in T
                            tenorflds_adj = arrayfun(@(x) [regexprep(x,'\D',''),' ' ,regexprep(x,'\d','')], tenorflds,'UniformOutput',false(1));
                            % dates vector (it is the same across all pillars)
                            dates = T.('ref_date');
                            dates_n = x2mdate(cell2mat(dates));
                            d1(:,1) = dates_n;
                            
                        end
                        
                        tenors{k,1} =  C.TenorsMap_xlsString2BBGstring(cell2mat(tenorflds_adj{k}));
                        
                        % history from T
                        if ~iscell(T.(tenorflds0{k}))
                            tmp = T.(tenorflds0{k});
                            d1(:,2) = tmp(1:size(d1,1));
                            
                        else
                            aa = T.(tenorflds0{k});
                            l = cellfun(@length,aa);
                            aa(l==0) = {'NaN'};
                            bb = zeros(size(aa,1),1);
                            for ii=1:size(aa,1)
                                if strcmp(aa{ii,1},'NaN')
                                    bb(ii,1)=str2double(aa(ii,1));
                                else
                                    bb(ii,1)=cell2mat(aa(ii,1));
                                end
                            end
                            d1(:,2)=bb;
                        end
                        
                        switch C.RatesInputFormat
                            case 'f'
                                d1(:,2) = d1(:,2).*100;
                            case 'bps'
                                d1(:,2) = d1(:,2)./100;
                            case 'p'
                                % nothing to do: this is the default
                        end
                        
                        cnt = k;
                        
                    end % if on input flag for xls or BBG sources
                    
                    tenors_yf(cnt,1) = C.TenorsMap(tenors{cnt,1}); % corresponding number in year fraction terms
                    
                    nm{cnt,1} = ['cds_',strrep(tenors{cnt,1},' ','_')]; % name of the fts
                    %fts.(nm{cnt,1}) = fints(d1(:,1),d1(:,2),nm{cnt,1},'daily');
                    fts.(nm{cnt,1}) = timetable(datetime(d1(:,1), 'ConvertFrom', 'datenum'),d1(:,2),'VariableNames',{nm{cnt,1}});
                    if cnt==1
                        allfts = fts.(nm{cnt,1});
                    else
                        % merging fts (leaving NaN where there is no data)
                        %allfts = merge(allfts,fts.(nm{cnt,1}),'DateSetMethod','union','DataSetMethod','closest','SortColumns',0);
                        allfts = outerjoin(allfts,fts.(nm{cnt,1}),'MergeKeys',true);
                        allfts = fillmissing(allfts,'nearest');
                    end
                    
                    
                end % 
                
                % *************  INTERP AND OUTLIERS TREATMENT ****************
                % (for MDS this is done within the Utilities' method directly)
                C.curve_tickers(col2delete,:)=[]; % eliminating uanavailable tenors from the initial list
                
                fdd = find(datenum(allfts.Time)>=datenum(C.StartDate) & datenum(allfts.Time)<=datenum(C.EndDate)); % selecting dataset consistent with desired initial/final hist dates
                try
                    C.Curve.tenors = tenors;
                catch ME
                    % ManagedErrorMsg = "Undefined function or variable 'tenors'."
                    ManagedErrorMsg = ['Undefined function or variable ',sprintf('''tenors''.')]; % equivalent to the above for matlab versions with no class "string"
                    if strcmp(ME.message,ManagedErrorMsg)
                        curve_tickers{k,1}
                        C.FeedExcludedCDS_CurvesLog(curve_tickers{k,1},'tenor not available for this curve: CURVE excluded');
                        return;
                    else
                        rethrow(ME);
                    end
                end
                C.Curve.tenors_yf = tenors_yf;
                %C.Curve.dates = allfts.dates(fdd);
                C.Curve.dates = datenum(allfts.Time(fdd));
                
                %tmpa = fts2mat(allfts);
                %C.Curve.CDS = tmpa(fdd,:);
                tmpa = allfts.Variables;
                C.Curve.CDS = tmpa(fdd,:);
                % create a map of tenors'tickers to the column number of the
                % corresponding timeseries in C.Curve.CDS
                KeySet =   C.curve_tickers;
                ValueSet = [1:1:size(allfts,2)];
                C.Curve.Tickers2ColumnsMap = containers.Map(KeySet,ValueSet);
                
                % C.Curve.CDS may contain several NaN values: need to fill in
                % those missing values. The approach is: Use method
                % InterpolationMixed of class Utilities
                disp('Interpolating CDS curves to fill in missing values');
                up.interType = 'linear';
                up.thresholdForInterpolating = C.CurveInputParams.thresholdForInterpolating; % TODO: parametrize
                up.extrapolate = C.CurveInputParams.extrapolate; % TODO: parametrize
                up.hCurve = C.Curve.CDS;
                up.tenors = tenors_yf;
                % instantiating obj of class Utilities to perform Mixed Interp
                U = Utilities(up);
                U.InterpolationMixed;
                
                % detection and removal of outliers: IMPORTANT: this search and
                % removal is limited to prices corresponding to NaN values in
                % the matrix C.Curve.CDS (inpu4t to the interpolation step
                % above). This is because I only want to remove outliers that
                % were generated by the interpolation (it shoudn't happen
                % anymore, but in the past it occurred a few times due to the
                % use of extrapolation)
                % ** upar.rawMatrix = U.Output.MixedInterpolatedMatrix;
                % ** upar.origMatrix = C.Curve.CDS;
                % ** upar.stdMult = 5;
                % ** upar.rwSize = [];
                % ** upar.replaceWith = 0;
                % ** upar.initalWindow = 200; % TODO: parametrize this (if there no at least 200 datapts this will cause an error)
                % ** U = Utilities(upar);
                % ** U.replaceOutlier;
                % ** C.Curve.CDS_interp = U.Output.adjPriceMatrix;
                
                % *****************  outliers processing **********************
                C.Curve.CDS_interp = filloutliers(C.Curve.CDS,'previous','movmedian',60,'ThresholdFactor',5);
                % *************************************************************
                
                % use this instead of C.Curve.CDS_interp = U.adjPriceMatrix;  to skip
                
                % the outliers detection and replacement step
                % C.Curve.CDS_interp = U.Output.MixedInterpolatedMatrix; %
                
                % identify NaNs on any row and remove all rows with NaN values
                % (should be concentrated within an initial set of rows after
                % the Mixed interpolation above has been performed)
                S = sum(C.Curve.CDS_interp,2);
                fnan = find(isnan(S));
                C.Curve.CDS_interp(fnan,:) = [];
                C.Curve.raw_dates = C.Curve.dates; % put here the vector of dates corresponding to uninterpolated data in.CDS
                C.Curve.dates(fnan,:) = [];
                
                % ******************  DATA FROM MDS *******************
            elseif params_CDS_crv.excel_spread_input.flag == 2 % data from MDS
                % in this case data are read from the Market Data
                % Server using an ad hoc Utilities'method
                % (GetMdsData)
                clear uparam;
                uparam.server =  'cvai0apcf01rp:90';
                uparam.docclause{1,1} = params_CDS_crv.docclause;
                uparam.creditIndex{1,1} = params_CDS_crv.tickerMDS; % curve_tickers{1};
                uparam.creditIndex{1,2} = params_CDS_crv.curveMaturities;
                uparam.tenors_key_mapping = params_CDS_crv.tenorMapType;
                uparam.startDate = datestr(datenum(historical_window.startDate,'mm/dd/yyyy'), 'yyyy-mm-dd');
                uparam.endDate   = datestr(datenum(historical_window.endDate,'mm/dd/yyyy'), 'yyyy-mm-dd');
                uparam.dataType  = 'CDS';
                uparam.DataFromMDS.NOMDS     = params_CDS_crv.DataFromMDS.NOMDS;
                uparam.DataFromMDS.save2disk = params_CDS_crv.DataFromMDS.save2disk;
                uparam.DataFromMDS.folder    = params_CDS_crv.DataFromMDS.folder;
                uparam.interp = true(1);
                uparam.extrapolate = C.CurveInputParams.extrapolate; % 3
                uparam.thresholdForInterpolating = params_CDS_crv.thresholdForInterpolating;
                disp(['Downloading Credit Default Spread from MDS: ' curve_tickers{1}]);
                U = Utilities(uparam);
                U.GetMdsData;
                
                C.Curve = U.Output.Curve;
                
                switch C.RatesInputFormat
                    case 'f'
                        C.Curve.CDS   = C.Curve.CDS.*100;
                        C.Curve.CDS_interp   = C.Curve.CDS_interp.*100;
                    case 'bps'
                        C.Curve.CDS = C.Curve.CDS./100;
                        C.Curve.CDS_interp = C.Curve.CDS_interp./100;
                    case 'p'
                        % nothing to do: this is the default
                end
                
                % rebuild the property C.curve_tickers in the same way as
                % it is done when data comes from BBG or xls
                ticker_root = C.curve_tickers;
                
                % needed to postpone the indicator of the ISDA standard (if
                % any), e.g. 'D14' to the tenor (see loop below)
                look4token =  ismember(C.ISDA_typeToken,strtrim(ticker_root{1}(end-3:end)));
                look4token = find(look4token);
                if ~isempty(look4token)
                    ISDA_token = C.ISDA_typeToken{look4token};
                else
                    ISDA_token = '';
                end
                
                cntObj = 0;
                for obj = params_CDS_crv.curveMaturities
                   cntObj = cntObj + 1;
                   tick = ticker_root{1};
                   tick = strtrim(strrep(tick,ISDA_token,''));
                   C.curve_tickers{cntObj,1} = [strtrim([tick, ' ', C.MapMdstenorsToBBG(obj{1}),' ',ISDA_token]), ' Corp'];
                end
                
                % create a map of tenors'tickers to the column number of the
                % corresponding timeseries in C.Curve.CDS
                KeySet =   C.curve_tickers;
                ValueSet = [1:1:cntObj];
                C.Curve.Tickers2ColumnsMap = containers.Map(KeySet,ValueSet);
                
                
            end % if on input flag for MDS or BBG/xls sources
            
            
            C.Curve.RatesFormat = C.RatesFormat;
        end % CDS_Curve
        
        function FeedExcludedCDS_CurvesLog(C,curveComponentID,reason)
            % method used to fill in the log ExcludedAssetsLog, listing
            % assets that for some reason it was not possible to read
            % curveComponentID: id of the excluded curtve component
            % reason for exclusion
            sz = size(C.ExcludedCDS_CurvesLog,1);
            sz = sz + 1;
            C.ExcludedCDS_CurvesLog{sz,1} = curveComponentID;
            C.ExcludedCDS_CurvesLog{sz,2} = reason;
        end
        
    end % methods
    
end
