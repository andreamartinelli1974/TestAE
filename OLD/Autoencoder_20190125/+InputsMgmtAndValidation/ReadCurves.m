classdef ReadCurves < handle
    % this class extract the Curves data from Bloomberg or MDS.
    % INPUT:
    % RAparams collect the input params needed
    % RAparams.AllCurvesToBeGenerated = list of all names
    % RAparams.curves2beRead = struct with sheets names (from
    %                          InitialParameters)           
    % RAparams.filename = Investement Universe xls file with Curves details
    % RAparams.CDSfilename = CDS_MarketData.xlsm, for cds not in MDS
    % RAparams.path = path to save bootstrapped curves
    % RAparams.configFile4IRCB = file for IRCB configuration
    % RAparams.history_start_date = start date for the data extractions
    % RAparams.history_end_date = end date
    % RAparams.DataFromBBG = struct with BBG details
    % RAparams.DataFromMDS = struct with MDS details
    % RAparams.useVolaSaved = struct with CDS_Source and path to use saved vola
    % RCparams.IV_hdate = dates to build volatility surface from BBG option
    %                     prices
    
    
    properties
        Curves2beGenerated;
        Sheets2beRead;
        DataFromBBG;
        DataFromMDS;
        Dates;
        CDSfilename;
        Path;
        Curves;
        filename;
        File4IRCB;
        useVolaSaved;
        IV_hdate
    end
    
    methods
        %% CONSTRUCTOR %%
        function RC = ReadCurves(RCparams)
            RC.Curves2beGenerated = RCparams.AllCurvesToBeGenerated;
            RC.Sheets2beRead = RCparams.curves2beRead;
            RC.filename = RCparams.filename;
            RC.CDSfilename = RCparams.CDSfilename;
            RC.DataFromBBG = RCparams.DataFromBBG;
            RC.DataFromMDS = RCparams.DataFromMDS;
            RC.Dates.startDate = RCparams.history_start_date;
            RC.Dates.endDate = RCparams.history_end_date;
            RC.Path = RCparams.path;
            RC.File4IRCB = RCparams.configFile4IRCB;
            RC.useVolaSaved = RCparams.useVolaSaved;
            RC.IV_hdate = RCparams.IV_hdate;
            
            %RA.getCurves;
            
        end %constructor
        
        
        %% READING FUNCTIONS %%
        
        function getCurves(RC)
            RC.getCDS;
            RC.getIRCurves;
            RC.getSingleIDX;
            RC.getBTSRCurve;
            RC.getVolaObj;
        end
        
        function getCDS(RC)
            % ************************** CDS CURVES OBJECTS *************************
            CDScurves = [];
            ExcludedCDSLog = [];
            
            % OPENING XLS CONNECTION TO READ ALL CURVES DATA FOR CDS CURVES THAT WILL
            % NOT BE READ FROM BLOOMBERG
            exl = actxserver('excel.application');
            exlWkbk = exl.Workbooks;
            try
                exlFile = exlWkbk.Open(RC.CDSfilename); 
            catch
                disp([RC.CDSfilename,' file not found'])
            end
            
            % ********* CDS CURVES *********
            CDScurvesTable = readtable(RC.filename ,'Sheet', RC.Sheets2beRead.CDS_SheetName);
            
            L = size(CDScurvesTable,1);
            eof = false(1);
            rowNum = 0;
            
            while ~eof
                
                params_curve = [];
                rowNum = rowNum + 1;
                if rowNum > L
                    break;
                end
                
                % check if the curve is in RC.Curves2beGenerated
                curveName = cell2mat(table2cell(CDScurvesTable(rowNum,'name')));
                im = ismember(RC.Curves2beGenerated,curveName);
                if sum(im)==0
                    continue
                end
                
                if ~isempty(curveName)
                    params_curve.thresholdForInterpolating = cell2mat(table2cell(CDScurvesTable(rowNum,'thresholdForInterpolating')));
                    params_curve.extrapolate = (cell2mat(table2cell(CDScurvesTable(rowNum,'extrapolate'))));
                    params_curve.int_ext = cell2mat(table2cell(CDScurvesTable(rowNum,'Internal_External_RF')));
                    params_curve.RatesInputFormat = cell2mat(table2cell(CDScurvesTable(rowNum,'rates_input_format')));
                    params_curve.ToBeIncludedInInvariants = cell2mat(table2cell(CDScurvesTable(rowNum,'ToBeIncludedInInvariants')));
                    params_curve.tenorMapType = cell2mat(table2cell(CDScurvesTable(rowNum,'tenors_key_mapping')));
                    
                    % now we can have 0 for input from BBG, 0 for input from xls file,
                    % 2 for input from MDS
                    params_curve.excel_spread_input.flag = (cell2mat(table2cell(CDScurvesTable(rowNum,'excel'))));
                    
                    curveMaturities = table2cell(CDScurvesTable(rowNum,'maturities'));
                    curveMaturitiesIntoCell=regexp(curveMaturities,',','split');
                    ticker = cell2mat(table2cell(CDScurvesTable(rowNum,'ticker')));
                    priceSource = cell2mat(table2cell(CDScurvesTable(rowNum,'BBG_PriceSource')));
                    priceSource(isnan(priceSource))='';
                    priceSource = deblank(priceSource);
                    if ~isnan(priceSource) & numel(priceSource)>0; priceSource = [' ',priceSource]; end % adding a space when non empty
                    nmat = numel(curveMaturitiesIntoCell{1});
                    % build the 'curve_tickers' fields: tickers of all points oin the curve
                    % (the logic is the same as the one applied by Bloomberg)
                    clear curve_tickers;
                    if ~(params_curve.excel_spread_input.flag == 2) % if source is not MDS
                        for k=1:nmat
                            curve_tickers{k,1} = [ticker,' ',cell2mat(curveMaturitiesIntoCell{1}(k)),priceSource,' Corp']; % TODO parametrize the price source (e.g. 'CBIN')
                        end
                    else % see comments to the CDS_Curve constructor when data source is MDS
                        curve_tickers{1,1} = ticker;
                    end
                    
                    if params_curve.excel_spread_input.flag == 1 % source: xls file
                        ShName = cell2mat(table2cell(CDScurvesTable(rowNum,'sheetname')));
                        params_curve.excel_spread_input.manual_ticker = ShName;
                        params_curve.excel_spread_input.firstCDScol = cell2mat(table2cell(CDScurvesTable(rowNum,'firstColInXlsFile'))); % column where spreads vectors start in the input file
                        params_curve.excel_spread_input.lastCDScol =  cell2mat(table2cell(CDScurvesTable(rowNum,'lastColInXlsFile'))); % column where spreads vectors start in the input file
                        sheetMain = exlFile.Sheets.Item(ShName); % name of the sheet in the xls file
                        dat_range = GetXlsRange(sheetMain,cell2mat(table2cell(CDScurvesTable(rowNum,'dat_range'))));
                        params_curve.excel_spread_input.inputMatrix = sheetMain.Range(dat_range).value;
                        price_used = [];
                        
                    elseif params_curve.excel_spread_input.flag == 0 % source: Bloomberg
                        price_used = cell2mat(table2cell(CDScurvesTable(rowNum,'price_used')));
                        
                    elseif params_curve.excel_spread_input.flag == 2 % source: MDS
                        params_curve.docclause = cell2mat(table2cell(CDScurvesTable(rowNum,'MDS_DOCCLAUSE')));
                        price_used = [];
                        params_curve.curveMaturities = curveMaturitiesIntoCell{1};
                        params_curve.DataFromMDS = RC.DataFromMDS;
                        params_curve.tickerMDS = cell2mat(table2cell(CDScurvesTable(rowNum,'tickerMDS'))); % ticker needed to query the MDS Db
                    end
                    % Importing "ExternalRiskFactors" package needed to call:
                    % CDS_Curve.m
                    import ExternalRiskFactors.*;
                    CDScurves.(curveName) = CDS_Curve(ticker,RC.DataFromBBG,curve_tickers,RC.Dates,price_used,params_curve);
                    if ~isempty(CDScurves.(curveName).ExcludedCDS_CurvesLog)
                        ExcludedCDSLog = [ExcludedCDSLog;CDScurves.(curveName).ExcludedCDS_CurvesLog];
                        CDScurves = rmfield(CDScurves,curveName);
                    end
                else
                    eof = true(1); % assuming EOF when there is nothing in the field 'name'
                end
                
            end % ~eof
            
            % Quit(exl);
            % delete(exl);
            % clear exlFile;
            
            [taskstate, taskmsg] = system('tasklist|findstr "EXCEL.EXE"');
            if ~isempty(taskmsg)
                status = system('taskkill /F /IM EXCEL.EXE');
            end
            RC.Curves.CdsCurves = CDScurves;
            RC.Curves.ExcludedCDSLog = ExcludedCDSLog;
            
        end %function getCDS
        
        function getIRCurves(RC)
            % ************************ IR CURVES OBJECTS  ****************************
            % READING THE Investment Universe File, IR_Curves Sheet to build IR curves objects

            % TODO: 'internalize into IR_Curve the 3 input alternatives (BBG, xls, and MDS)
            %        managed below:
            %        and also add the one related to the output from bootsstrapped
            %        curves (see section below reading bootstrapped curve)

            IRcurves = [];
            IR_Curves.table = readtable(RC.filename,'Sheet',RC.Sheets2beRead.IR_SheetName);

            L = size(IR_Curves.table,1);

            
            eof = false(1);
            rowNum = 0;
            
            while ~eof
                
                IRC_params = [];
                extCdataparams = [];
                rowNum = rowNum + 1;
                if rowNum > L
                    break;
                end
                IRC_params.StartDate = RC.Dates.startDate;
                IRC_params.EndDate = RC.Dates.endDate;
                IRC_params.DataFromBBG = RC.DataFromBBG;
                
                curveName = cell2mat(table2cell(IR_Curves.table(rowNum,'name')));
                
                % check if the curve is in RC.Curves2beGenerated
                im = ismember(RC.Curves2beGenerated,curveName);
                if sum(im)==0
                    continue
                end
                
                if ~isempty(curveName)
                    IRC_params.CurveID = cell2mat(table2cell(IR_Curves.table(rowNum,'curve_id')));
                    IRC_params.ctype = cell2mat(table2cell(IR_Curves.table(rowNum,'ctype')));
                    IRC_params.TenorsKeyMapping_choice = cell2mat(table2cell(IR_Curves.table(rowNum,'tenors_key_mapping')));
                    IRC_params.BBG_YellowKey = cell2mat(table2cell(IR_Curves.table(rowNum,'bbg_yellowKey')));
                    IRC_params.invertBbgSigns = logical(cell2mat(table2cell(IR_Curves.table(rowNum,'invertBbgSigns'))));
                    IRC_params.RatesInputFormat = (cell2mat(table2cell(IR_Curves.table(rowNum,'rates_input_format'))));
                    IRC_params.RatesType = (cell2mat(table2cell(IR_Curves.table(rowNum,'rates_type'))));
                    IRC_params.int_ext = cell2mat(table2cell(IR_Curves.table(rowNum,'Internal_External_RF')));
                    IRC_params.ToBeIncludedInInvariants = cell2mat(table2cell(IR_Curves.table(rowNum,'ToBeIncludedInInvariants')));
                    IRC_params.BBG_tickerRoot = cell2mat(table2cell(IR_Curves.table(rowNum,'BBG_tickerRoot')));
                    
                    extCdataparams.XlsCurve.FileName = cell2mat(table2cell(IR_Curves.table(rowNum,'xlsCurve_filename')));
                    extCdataparams.XlsCurve.SheetName = cell2mat(table2cell(IR_Curves.table(rowNum,'xlsCurve_sheetname')));
                    
                    if strcmp(IRC_params.ctype,'file') &~isempty(extCdataparams.XlsCurve.FileName) % need to read curve's data from xls file
                        % if input is from file and there is an Excel file name ***
                        % *** INPUT FROM XLS FILE ***
                        U = Utilities(extCdataparams);
                        U.ReadCurveDataFromXls;
                        IRC_params.ExtSource = U.Output;
                    elseif strcmp(IRC_params.ctype,'MDS')
                        % *** INPUT from Mkt Data Server ***
                        % as above here I put in IRC_params.ExtSource the data that I
                        % want in the format produced by IR_Curves
                        disp('check');
                        uparams.startDate = RC.Dates.startDate;
                        uparams.endDate = RC.Dates.endDate;
                        uparams.curveName = curveName;
                        uparams.dataType = 'BvalData';
                        uparams.DataFromMDS.createLog = false(1);
                        uparams.DataFromMDS = RC.DataFromMDS;
                        uparams.DataFromMDS.fileMap{1,1} = 'MDS_BVAL_Curve.xlsx';
                        U = Utilities(uparams);
                        U.GetMdsData;
                        IRC_params.ExtSource = U.Output;
                    end
                    % Importing "ExternalRiskFactors" package needed to call:
                    % IR_Curve.m
                    import ExternalRiskFactors.*;
                    RC.Curves.IR_Curves.(curveName) = IR_Curve(IRC_params);
                else
                    eof = true(1); % assuming EOF when there is nothing in the field 'name'
                end
           
            end % ~eof

        end %function getIRCurves
        
        function getSingleIDX(RC)
            % ********************** SINGLE INDICES OBJECTS  *************************
            paramsSI.DataFromBBG = RC.DataFromBBG;
            paramsSI.start_dt = RC.Dates.startDate;
            paramsSI.end_dt = RC.Dates.endDate;
            
            Single_Indices = [];
            Single_Indices.table = readtable(RC.filename ,'Sheet', RC.Sheets2beRead.SingleIndices);
            
            L = size(Single_Indices.table,1);

            eof = false(1);
            rowNum = 0;
            
            while ~eof
                paramsSI.ticker  = [];
                paramsSI.isRate  = [];
                paramsSI.InputRatesFormat  = [];
                paramsSI.rate_type  = [];
                
                rowNum = rowNum + 1;
                if rowNum > L
                    break;
                end
                
                indexName = cell2mat(table2cell(Single_Indices.table(rowNum,'name')));
                
                % check if the curve is in RC.Curves2beGenerated
                im = ismember(RC.Curves2beGenerated,indexName);
                % if it has to be included within invariants we read it anyway (might be needed for views even if it is not mentioned within the Universe Table)
                % TODO: add a column to the Investment Universe worksheet to be able to
                % specify indices that must be read for views mgmt purposes. Otherwise
                % I could end up reading lots of uneeded Single Indices in the Single
                % Indices tables that are not used here
                if sum(im)==0 & ~(cell2mat(table2cell(Single_Indices.table(rowNum,'ToBeIncludedInInvariants'))) == 1) 
                    continue
                end
                
                if ~isempty(indexName)
                    paramsSI.ticker = cell2mat(table2cell(Single_Indices.table(rowNum,'ticker')));
                    paramsSI.isRate = cell2mat(table2cell(Single_Indices.table(rowNum,'isRate')));
                    paramsSI.InputRatesFormat = cell2mat(table2cell(Single_Indices.table(rowNum,'InputRatesFormat')));
                    paramsSI.rate_type = cell2mat(table2cell(Single_Indices.table(rowNum,'rate_type')));
                    paramsSI.int_ext = cell2mat(table2cell(Single_Indices.table(rowNum,'Internal_External_RF')));
                    paramsSI.ToBeIncludedInInvariants = cell2mat(table2cell(Single_Indices.table(rowNum,'ToBeIncludedInInvariants')));
                    % Importing "ExternalRiskFactors" package needed to call:
                    % SingleIndex.m
                    import ExternalRiskFactors.*;
                    RC.Curves.Single_Indices.(indexName) = SingleIndex(paramsSI);
                    
                else
                    eof = true(1); % assuming EOF when there is nothing in the field 'name'
                end
                
            end % ~eof
            
        end %function getSingleIDX
        
        function getBTSRCurve(RC)
            % ************************ BOOTSTRAPPED CURVES  **************************
            % builds all curves structures (to be used for bootstrappings)
            % (this set must comprise all the curves used in the Investment Universe)
            SWAP_curves = [];
            curveParam.configFile = RC.File4IRCB;
            curveParam.valDate = [];
            
            paramsBTS.DataFromBBG = RC.DataFromBBG;
            paramsBTS.StartDate = RC.Dates.startDate;
            paramsBTS.EndDate = RC.Dates.endDate;
            paramsBTS.historyPath = RC.Path;
            
            Curves2BeBtStrapped = readtable(RC.filename ,'Sheet', RC.Sheets2beRead.IRC2beBtStrapped);
            L = size(Curves2BeBtStrapped,1);
            
            eof = false(1);
            rowNum = 0;
            
            while ~eof
                
                rowNum = rowNum + 1;
                if rowNum > L
                    break;
                end
                
                curveName = cell2mat(table2cell(Curves2BeBtStrapped(rowNum,'name')));
                
                % check if the curve is in RC.Curves2beGenerated
                im = ismember(RC.Curves2beGenerated,curveName);
                if sum(im)==0
                    continue
                end
                
                if ~isempty(curveName)
                    
                    % IDENTIFY THE STRUCTURE OF THE CURVE TO BE BOOTSTRAPPED
                    paramsBTS.CurveID{1} = curveName;
                    paramsBTS.BBG_tickerRoot = [];
                    bstrapParam.depoDC = cell2mat(table2cell(Curves2BeBtStrapped(rowNum,'depoDC')));
                    bstrapParam.futureDC = cell2mat(table2cell(Curves2BeBtStrapped(rowNum,'futureDC')));
                    swapDCtmp = (table2cell(Curves2BeBtStrapped(rowNum,'swapDC')));
                    splitted = regexp(swapDCtmp,',','split');
                    bstrapParam.swapDC(1,:) = str2double(cell2mat(splitted{1}(1)));
                    bstrapParam.swapDC(1,2) = str2double(cell2mat(splitted{1}(2)));
                    
                    paramsBTS.rates_type = cell2mat(table2cell(Curves2BeBtStrapped(rowNum,'rates_type')));
                    paramsBTS.rates_input_format = cell2mat(table2cell(Curves2BeBtStrapped(rowNum,'rates_input_format')));
                    paramsBTS.int_ext = cell2mat(table2cell(Curves2BeBtStrapped(rowNum,'Internal_External_RF')));
                    paramsBTS.ToBeIncludedInInvariants = cell2mat(table2cell(Curves2BeBtStrapped(rowNum,'ToBeIncludedInInvariants')));
                    paramsBTS.tenors_key_mapping = cell2mat(table2cell(Curves2BeBtStrapped(rowNum,'tenors_key_mapping')));
                    paramsBTS.invertBbgSigns = cell2mat(table2cell(Curves2BeBtStrapped(rowNum,'invertBbgSigns')));
                    paramsBTS.bootPillChoice = cell2mat(table2cell(Curves2BeBtStrapped(rowNum,'PillarsStructure')));
                    
                    R = HistoricalRateCurve(paramsBTS, curveParam, bstrapParam);
                    
                    RC.Curves.SWAP_curves.(curveName) = R.rateCurve.(curveName);

                else
                    
                    eof = true(1); % assuming EOF when there is nothing in the field 'name'
                end
                
            end % ~eof
            
        end %function getBTSRCurve
        
        function getVolaObj(RC)
            % ************************* VOLATILITY  OBJECTS **************************

            VolaSurfaces = [];

            VolaEquityOpt.Table = readtable(RC.filename,'Sheet',RC.Sheets2beRead.VolaEquity);
            
            L = size(VolaEquityOpt.Table,1);
            
            eof = false(1);
            rowNum = 0;
            
            while ~eof
                underlying_ticker  = [];
                optionRootTicker = [];
                min_strike_increase = [];
                dec_digits = [];
                rfr = [];
                divYield = [];
                volaData_source = [];
                Internal_External_RF = [];
                ToBeIncludedInInvariants = [];
                
                rowNum = rowNum + 1;
                if rowNum > L
                    break;
                end
                
                volaName = cell2mat(table2cell(VolaEquityOpt.Table(rowNum,'name')));
                
                % check if the curve is in RC.Curves2beGenerated
                im = ismember(RC.Curves2beGenerated,volaName);
                if sum(im)==0
                    continue
                end
                
                if ~isempty(volaName)
                    underlying_ticker = cell2mat(table2cell(VolaEquityOpt.Table(rowNum,'underlying_ticker')));
                    optionRootTicker = cell2mat(table2cell(VolaEquityOpt.Table(rowNum,'optionRootTicker')));
                    
                    min_strike_increase = cell2mat(table2cell(VolaEquityOpt.Table(rowNum,'min_strike_increase')));
                    dec_digits = cell2mat(table2cell(VolaEquityOpt.Table(rowNum,'dec_digits')));
                    rfr = cell2mat(table2cell(VolaEquityOpt.Table(rowNum,'rfr')));
                    divYield = cell2mat(table2cell(VolaEquityOpt.Table(rowNum,'yield')));
                    volaData_source = cell2mat(table2cell(VolaEquityOpt.Table(rowNum,'volaData_source')));
                    Internal_External_RF = cell2mat(table2cell(VolaEquityOpt.Table(rowNum,'Internal_External_RF')));
                    ToBeIncludedInInvariants = cell2mat(table2cell(VolaEquityOpt.Table(rowNum,'ToBeIncludedInInvariants')));
                    
                    % for MDS surfaces the range of hist date is the same as the one
                    % used to generate the price history for all of the assets. For BBG
                    % tyoe vola we model the shape of the surface using a few days of
                    % data (as defined in Initial parameters 'IV_hdate' struct array)
                    % otherwise it would take too much time and risk to exceed the
                    % daily limit for BBG data
                    if strcmp(volaData_source,'BBG')
                        ImpliedVolaDatesRange = RC.IV_hdate;
                    elseif strcmp(volaData_source,'MDS')
                        ImpliedVolaDatesRange.start = RC.Dates.startDate;
                        ImpliedVolaDatesRange.end = RC.Dates.endDate;
                    end
                    RC.Curves.VolaSurfaces.(volaName) = ...
                        ImpliedVola_Surface(RC.DataFromBBG,RC.DataFromMDS,underlying_ticker,optionRootTicker,ImpliedVolaDatesRange, ...
                        min_strike_increase,dec_digits,rfr,divYield,volaData_source, RC.useVolaSaved);
                    RC.Curves.VolaSurfaces.(volaName).CalibrateSkewParams(1);
                    RC.Curves.VolaSurfaces.(volaName).IntExt = Internal_External_RF;
                    RC.Curves.VolaSurfaces.(volaName).ToBeIncludedInInvariants = ToBeIncludedInInvariants;
                    % to plot the surface based on estimated skew/ttm parameters
                    % underlyingATMsVolas = 0.20
                    % VolaSurfaces.V_SX5E.DrawEstimatedSurface(underlyingATMsVolas,3000);
                else
                    eof = true(1); % assuming EOF when there is nothing in the field 'name'
                end
                
            end % ~eof
                
        end %function getVolaObj
              
    end %methods
end

