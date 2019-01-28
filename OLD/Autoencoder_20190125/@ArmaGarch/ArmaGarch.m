classdef ArmaGarch < handle
    % class ArmaGarch: designed to model ARIMA-GARCH features wrt to single
    % timeseries. This class also allows to progressively
    % save the output for a single timeseries (given a certain setup). The
    % logic here is to save to disk,  in a map, all fitted models for each
    % invariant (one model per chunk). The filename used to save the map
    % and to reload a saved map is fully determined by the history starting
    % date and by the length of the chunk.
    
    properties
    end
    
    properties (Constant)
    end
    
    properties (SetAccess = immutable)
        RawInputSeries; % cell array of raw invariants' timeseries
        GarchParams;    % ar-garch main params
        ArmaGarchFileName; % this is the file name used to save all the garch models sharing the same set of 'garchParams'
        Folder; % folder used to save AR_GARCH models
    end
    
    properties (SetObservable = true)
    end
    
    properties (Abstract, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
        ARMA_GARCH_filtering; % main output structure
    end
    
    methods
        
        % declaration (defined within @ArmaGarch)
        result = checkARGARCH_OptimOutput(obj,currentModel,optimExitFlag);
        
        function U = ArmaGarch(universeObj, garchParams)
            U.RawInputSeries = universeObj.AllInvariants.InvariantsAndPricesCollectionsRawData.Returns;
            U.GarchParams = garchParams;
            % name of the file that will gather all the single invariants'
            % models having the same historical sarting date and using the
            % same chunk's length and (added 8.6.18)  the using the same
            % moving window parameter
            U.ArmaGarchFileName = ['Hstart_',num2str(garchParams.historyStartDt), ...
                'chunksLength',num2str(garchParams.chunksLength),'_movWin_',num2str(U.GarchParams.movWin),'.mat'];
            U.Folder = garchParams.folder;
            
            U.ARMAGARCH_filtering(universeObj);
        end % constructor
        
        
        function ARMAGARCH_filtering(U,universeObj)
            model_Constant = arima('Constant', 1, 'Distribution', 't');
            
            options   = optimoptions(@fmincon, 'Display'  , 'off', 'Diagnostics', 'off', ...
                'Algorithm', 'interior-point', 'TolCon', 1e-6,'MaxIterations',3000,'OptimalityTolerance',1e-07,'StepTolerance',1e-07);
            nTs = numel(U.RawInputSeries); % no of timeseries to be modeled in AR-GARCH terms
            L = nTs; % no of timeseries
            
            filename = [U.Folder,U.ArmaGarchFileName];
            try
                if U.GarchParams.cleanGARCH==1 % clean the archive
                    delete(filename);
                end
                load(filename); % load the whole map
            catch MM
                if strcmp(MM.identifier,'MATLAB:load:couldNotReadFile') % the map does not exists
                    disp('*** Forcing AR-GARCH refit because of no previously saved file ***');
                    mapInvariantsToFit = containers.Map;
                else
                    rethrow(MM);
                end
            end
            
            SUMMARY_OUT = struct('initializationField',[]);
            
            % *** PARFOR sliced variables ***
            fit = cell(L,1);
            info = cell(L,1);
            fitcov = cell(L,1);
            rangeOfChunkDates = cell(L,1);
            LBQ_statistic = cell(L,1);
            LBQ_squaredstatistic = cell(L,1);
            LillieTest  = cell(L,1);
            % ** equityAssetFlag = cell(L,1);
            InvariantsNamesSet = cell(L,1);
            N = cell(L,1); % to hold the length of each timeseries
            meanUncond = cell(L,1);
            varianceUncond = cell(L,1);
            datesVector = cell(L,1);
            chunks = cell(L,1);
            modelName = cell(L,1);
            InvariantsNamesSet = universeObj.AllInvariants.NamesSet;
            
            chunksLength = U.GarchParams.chunksLength;
            winLength = chunksLength;
            movWin = U.GarchParams.movWin; % if 0 then use the whole available history at each point in time
            
            % *** PARFOR temporary variables ***
            ngarch = 1;
            narch = 1;
            model = [];
            % ********************************
            % dont'use true(1) for now. Needs to be fully tested (read
            % Matlab doc in detail). Also the refiltering 'piece' should be
            % modified accordingly
            useEgarch = false(1);
            % ********************************
            rawdata = U.RawInputSeries;
            modelObjName = [];
            latestCommonDate = universeObj.AllInvariants.Dates(end);
            
            % prepare unconditional mean and variance timeseries
            for i = 1:L
                n = size(rawdata{i, 1},1);
                for t = movWin+1:n
                    if movWin==0
                        startPt = 1;
                    else
                        startPt = t-movWin;
                    end
                    meanUncond{i,1}(t,:) = mean(rawdata{i, 1}(startPt:t,2));
                    varianceUncond{i,1}(t,:) = var(rawdata{i, 1}(startPt:t,2));
                end
                % feed the initial segment with 2nd mov window data (introducing forward looking
                % bias wrt this segment only)
                meanUncond{i,1}(1:movWin,:) = repmat(mean(meanUncond{i,1}(movWin+1:movWin*2,:)),movWin,1);
                varianceUncond{i,1}(1:movWin,:) = repmat(mean(varianceUncond{i,1}(movWin+1:movWin*2,:)),movWin,1);
                
            end
            
            parfor i = 1:L
            % ** for i = 1:L % for DEBUG purposes
                N{i} = size(rawdata{i, 1},1);
                chunks{i,1} = ceil(size(rawdata{i, 1},1)/chunksLength);
                datesVector{i} = rawdata{i, 1}(:,1); % vector of dates for the i-th invariant
                
                for j = 1:chunks{i,1}
                    
                    if movWin==0
                        startPt = 1;
                    else
                        startPt = max(min(j*chunksLength,size(rawdata{i, 1},1)) - movWin + 1,1);
                    end
                    
                    if ismember(InvariantsNamesSet{i},keys(mapInvariantsToFit)) % if the invariant has been mapped already
                        
                        % ***********  pre-condition on dates *************
                        % Here I want to be sure that the set of dates for
                        % the invariant I am working on is the same as it
                        % was as of the previous execution (wrt to the
                        % shortest vector between current invariant
                        % timeseries and saved invariant's timeseries). In
                        % theory this fact should be guaranteed by the
                        % condition on the same initial date (upon which
                        % 'filename' is based) and the same chunk'slength, but
                        % checking it futher can make the process more
                        % robust and resilient to errors / changes in BBG
                        % input data for a given ticker
                        tmpStruct = mapInvariantsToFit(InvariantsNamesSet{i});
                        l1 = size(datesVector{i}(:,1),1);
                        l2 = size(tmpStruct.datesVector(:,1),1);
                        mxL = min(l1,l2);
                        l1 = min(mxL,l1);
                        l2 = min(mxL,l2);
                        
                        conditionOnDates = datesVector{i}(1:l1,1) == tmpStruct.datesVector(1:l2,1);
                        % *************************************************
                        
                        if conditionOnDates
                            
                            if ismember(j,tmpStruct.mapDates2Chunk(:,3)) & j < chunks{i,1}
                                % if the current chunk exists and is not
                                % the last one it means that it is a
                                % 'complete' chunk and there is no need to
                                % update it
                                tmp = mapInvariantsToFit(InvariantsNamesSet{i});
                                tempStruct{i}{j} = tmp.fitStruct{j} ;
                                disp(['Fit of ' InvariantsNamesSet{i}  '_partition:' num2str(j),' detected: fitting skipped']);
                                continue
                                
                            else
                                
                                % ******** GO AHEAD *********
                                % in practice if the chunk does not exist
                                % or it it is the last one then the fit is
                                % performed: the latest chunk is always
                                % updated. TODO: this behaviour may be
                                % improved since the chunk is won't be really  used
                                % until it is complete -> the fit could be
                                % done only when it is needed to make the
                                % chunk complete
                            end
                        end % conditionOnDates if
                    end % if the i-th invariant  is in the map
                    
                    % *** model fit: i-th invariant and j-th chunk
                    disp(['Fitting ' InvariantsNamesSet{i}  '_partition:' num2str(j)]);
                    LBQ_statistic{i}{j} = lbqtest(rawdata{i, 1}(startPt:min(j*chunksLength,size(rawdata{i, 1},1)),2));
                   
                    % measuring correlation of squared returns
                    lbq = lbqtest(rawdata{i, 1}(startPt:min(j*chunksLength,size(rawdata{i, 1},1)),2).^2); % ,'lags',[1 2 3 4 5]);
                    LBQ_squaredstatistic{i}{j} = lbq;
                    LillieTest{i}{j} = lillietest(rawdata{i, 1}(startPt:min(j*chunksLength,size(rawdata{i, 1},1)),2)); % perform Lillie test for normality
                    sLBQ = sum(LBQ_squaredstatistic{i}{j});
                    
                    if (LBQ_statistic{i}{j} == 1 && sLBQ >= 1 )
                        modelType = 'arima';
                        offsetTerm =[];
                        constTerm =  [sprintf(['''Constant''']),',NaN',','];
                        
                        if useEgarch
                            varianceTerm = sprintf([',','''Variance''',',egarch(ngarch,narch)']);
                            
                            % ** if LillieTest{i}{j} == 0        % if normally distributed
                            distribution = sprintf('''Gaussian''');
                            model = arima('Constant',NaN,'ARLags', 1,'MALags', [],'Distribution', ...
                                'Gaussian', 'Variance', egarch(ngarch,narch));
                            % ** elseif LillieTest{i}{j} == 1    % if not normally distributed
                            % ** distribution = sprintf('''t''');3
                            % ** model = arima('Constant',NaN,'ARLags', 1,'MALags', [],'Distribution', 't', 'Variance', egarch(ngarch,narch));
                            % ** end
                        elseif ~useEgarch
                            % ** if LillieTest{i}{j} == 0        % if normally distributed
                            distribution = sprintf('''Gaussian''');
                            model = arima('Constant',NaN,'ARLags', 1,'MALags', [],'Distribution', ...
                                'Gaussian', 'Variance', garch(ngarch,narch));
                            % ** elseif LillieTest{i}{j} == 1    % if not normally distributed
                            % ** distribution = sprintf('''t''');
                            % ** model = arima('Constant',NaN,'ARLags', 1,'MALags', [],'Distribution', 't', 'Variance', garch(ngarch,narch));
                            % ** end
                            
                        end
                        
                    elseif (LBQ_statistic{i}{j} == 1 && sLBQ == 0 ) % no autocorrelation of variance present.
                        
                        modelType = 'arima';
                        varianceTerm = [];
                        arlagsTerm = [];
                        garchlagsTerm = [];
                        offsetTerm =[];
                        constTerm =  [sprintf(['''Constant''']),',NaN',','];
                        
                        % ** if LillieTest{i}{j} == 0            % if normally distributed
                        distribution = sprintf('''Gaussian''');
                        model = arima('Constant',NaN,'ARLags', 1,'MALags', [],'Distribution', 'Gaussian');
                        % ** elseif LillieTest{i}{j} == 1        % if not normally distributed
                        % ** distribution = sprintf('''t''');
                        % ** model = arima('Constant',NaN,'ARLags', 1,'MALags', [],'Distribution', 't');
                        % ** end
                        
                    elseif (LBQ_statistic{i}{j} == 0 && sLBQ >= 1 ) % no autocorrelation of returns
                        varianceTerm = [];
                        arlagsTerm = [];
                        garchlagsTerm = [sprintf(['''GARCHLags''']),',ngarch',','];
                        archlagsTerm = [sprintf(['''ARCHLags''']),',narch',','];
                        offsetTerm = [sprintf(['''Offset''']),',NaN',','];
                        constTerm = [];
                        
                        modelType = 'garch';
                        if useEgarch
                            % ** if LillieTest{i}{j} == 0        % if normally distributed
                            distribution = sprintf('''Gaussian''');
                            model = egarch('GARCHLags',[1:1:ngarch],'ARCHLags',[1:1:narch],'Offset',NaN,'Distribution', 'Gaussian');
                            % ** elseif LillieTest{i}{j} == 1    % if not normally distributed
                            % ** distribution = sprintf('''t''');
                            % ** model = egarch('GARCHLags',[1:1:ngarch],'ARCHLags',[1:1:narch],'Offset',NaN,'Distribution', 't');
                            % ** end
                            %                             end
                        elseif ~useEgarch
                            % ** if LillieTest{i}{j} == 0        % if normally distributed
                            distribution = sprintf('''Gaussian''');
                            model = garch('GARCHLags',[1:1:ngarch],'ARCHLags',[1:1:narch],'Offset',NaN,'Distribution', 'Gaussian');
                            % ** elseif LillieTest{i}{j} == 1    % if not normally distributed
                            % ** distribution = sprintf('''t''');
                            % ** model = garch('GARCHLags',[1:1:ngarch],'ARCHLags',[1:1:narch],'Offset',NaN,'Distribution', 't');
                            % ** end
                        end
                        
                    elseif (LBQ_statistic{i}{j} == 0 && sLBQ == 0 ) % NO AUTOCORR in returns and variances (NO MODEL)
                        model = [];
                    end
                    
                    
                    % if both tests are 0 then the
                    % variable 'model' is set to 'none' (it will be used later, when doing
                    % re-filtering, to understand which refiltering has to
                    % be applied)
                    done = false(1);
                    while ~done
                        if ~isempty(model)
                            mc = metaclass(model);
                            % FOR AR-GARCH MODEL ESTIMATION PURPOSES EACH
                            % CHUNK IS ASSUMED TO START ALWAYS AT TIME 1
                            % (for now) - TODO: expand to allow rolling
                            % windows
                            try
                                if strcmp(mc.Name,'gjr') | strcmp(mc.Name,'garch') | strcmp(mc.Name,'egarch') % using intial guess for variance models
                                    [fit{i}{j}, fitcov{i}{j}, ~,info{i}{j}] = ...
                                        estimate(model,  rawdata{i, 1}(startPt:min(j*chunksLength, ...
                                        size(rawdata{i, 1},1)),2), 'options', options, ...
                                        'GARCH0',0.40.*ones(1,ngarch), 'ARCH0', 0.40.*ones(1,narch)); % Make sure to multiply returns by 100 for stability.
                                else
                                    [fit{i}{j}, fitcov{i}{j}, ~,info{i}{j}] = ...
                                        estimate(model,  rawdata{i, 1}(startPt:min(j*chunksLength,size(rawdata{i, 1},1)),2), ...
                                        'options', options); % Make sure to multiply returns by 100 for stability.
                                end
                                done = true(1); % done if no error was triggered at estimation
                            catch ARGARCH_estimateErrors
                                if strcmp(ARGARCH_estimateErrors.identifier,'econ:arima:estimate:InvalidVarianceModel') ...
                                        | strcmp(ARGARCH_estimateErrors.identifier,'econ:garch:estimate:InvalidVarianceModel')
                                    % NOT USING DISTIRBUTIONS OTHER THAN THE GAUSSIAN FOR NOW
                                    %                                 % sometimes, when using t-distrib based max
                                    %                                 % likelyhood, convergence is not achieved.
                                    %                                 % So here I try with a Gaussian distrib.
                                    %                                 % and rethrow the error if it doesn't work
                                    %                                 model.Distribution='Gaussian';
                                    %                                 if strcmp(mc.Name,'gjr') | strcmp(mc.Name,'garch') | strcmp(mc.Name,'egarch')
                                    %                                     [fit{i}{j}, fitcov{i}{j}, ~,info{i}{j}] = ...
                                    %                                         estimate(model,  rawdata{i, 1}(1:min(j*chunksLength,size(rawdata{i, 1},1)),2), 'print', false, 'options', options,'GARCH0',0.40.*ones(1,ngarch), 'ARCH0', 0.40.*ones(1,narch)); % Make sure to multiply returns by 100 for stability.
                                    %                                 else
                                    %                                     [fit{i}{j}, fitcov{i}{j}, ~,info{i}{j}] = ...
                                    %                                         estimate(model,  rawdata{i, 1}(1:min(j*chunksLength,size(rawdata{i, 1},1)),2), 'print', false, 'options', options); % Make sure to multiply returns by 100 for stability.
                                    %                                 end
                                    model = []; % estimation was not succesfully: NO MODEL
                                    continue; % go to the while ~done
                                else
                                    % UNHANDLED EXCEPTIONS (TODO: use a cell
                                    % array or move the unhandled exception
                                    % mgmt outside the parfor)
                                    %                                 U.Errors.unhandled.errorCode = ARGARCH_estimateErrors;
                                    %                                 U.Errors.unhandled.specificFeatures.codeSection = 'ARGARCH estimate';
                                    %                                 U.Errors.unhandled.specificFeatures.invariantName = InvariantsNamesSet{i};
                                    %                                 U.Errors.unhandled.specificFeatures.chunkNo = j;
                                    rethrow(ARGARCH_estimateErrors);
                                end
                                
                            end % try estimation - catch
                            
                            modelAccepted = U.checkARGARCH_OptimOutput(fit{i}{j},info{i}{j}.exitflag); % check optim results
                            mc = metaclass(fit{i}{j}); % to get metaclass properties
                            modelName{i}{j} = mc.Name;
                            
                            if ~modelAccepted
                                fit{i}{j} = model_Constant; % not used: the purpose is to fill fit{i}{j} to avoid problems with the mapping
                                fitcov{i}{j} = [];
                                modelName{i}{j} = 'none';
                                disp('***** NO MODEL  ******');
                            end
                            
                        elseif isempty(model) % no AR-GARCH features detected or estimation was not succesful
                            
                            fit{i}{j} = model_Constant; % not used: the purpose is to fill fit{i}{j} to avoid problems with the mapping
                            fitcov{i}{j} = [];
                            info{i}{j} = [];
                            modelName{i}{j} = 'none';
                            disp('***** NO MODEL  ******');
                            done = true(1);
                            
                        end
                    end % while done
                    
                    % update the structure
                    rangeOfChunkDates{i}{j} = [rawdata{i, 1}((j-1).*chunksLength + 1,1), ...
                        rawdata{i, 1}(min( size(rawdata{i, 1},1),j.*chunksLength ),1)]; % start/end date for current chunk
                    tempStruct{i}{j}.name4SUMMARY_OUT_struct = strrep(['Fitting_' InvariantsNamesSet{i} '_partition_' num2str(j)],'/','_');
                    tempStruct{i}{j}.name = ['Fitting_' InvariantsNamesSet{i} '_partition:' num2str(j)];
                    tempStruct{i}{j}.model = modelName{i}{j};
                    tempStruct{i}{j}.fit = fit{i}{j};
                    tempStruct{i}{j}.rangeOfChunkDates = rangeOfChunkDates{i}{j};
                    tempStruct{i}{j}.fitcov = fitcov{i}{j};
                    tempStruct{i}{j}.LBQ_statistic = LBQ_statistic{i}{j};
                    tempStruct{i}{j}.LBQ_squaredstatistic = LBQ_squaredstatistic{i}{j};
                    tempStruct{i}{j}.LillieTest = LillieTest{i}{j};
                    tempStruct{i}{j}.info = info{i}{j};
                    
                    % *** end of model fit: i-th invariant and j-th chunk
                    
                end % j-loop (chunks)
                
            end % i-loop  (invariants)
            
     
            
            ncells = numel(tempStruct);
            
            % update the map that will be save to disk
            % ****************************************
            for i=1:ncells
                tmp = [];
                for k=1:numel(tempStruct{i})
                    % associating the start/end dates of each
                    % chunk to the corresponding chun number
                    % (used when refiltering)
                    tmp.mapDates2Chunk(k,:) = [tempStruct{i}{k}.rangeOfChunkDates,k];
                    
                end
                tmp.fitStruct = tempStruct{i};
                tmp.datesVector = datesVector{i}; % save the vector of dates over whichthe current invariant has been modeled wrt to AR-GARCH features
                mapInvariantsToFit(InvariantsNamesSet{i}) = tmp;
                MapDatesToChunks{i} = tmp.mapDates2Chunk; % needed for refiltering in universe.Dynamic_AA
            end
            
            disp('Saving the updated ARMA-GARCH structure to disk');
            save(filename,'mapInvariantsToFit');
            % ****************************************
            
            % updating main output structure (USED TO SAVE AND THEN
            % RETRIEVE Garch models and data from inference)
            ncells = numel(tempStruct);
            
            % THE STRUCT BELOW IS KEPT FOR BACKWARD COMPATIBILITY ONLY:
            % there is no real need for it
            for i=1:ncells
                if ~isempty(tempStruct{i})
                    for j=1:numel(tempStruct{i})
                        if isstruct(tempStruct{i}{j})
                            SUMMARY_OUT.(tempStruct{i}{j}.name4SUMMARY_OUT_struct).name = tempStruct{i}{j}.name4SUMMARY_OUT_struct;
                            SUMMARY_OUT.(tempStruct{i}{j}.name4SUMMARY_OUT_struct).model = tempStruct{i}{j}.model;
                            SUMMARY_OUT.(tempStruct{i}{j}.name4SUMMARY_OUT_struct).fit = tempStruct{i}{j}.fit;
                            SUMMARY_OUT.(tempStruct{i}{j}.name4SUMMARY_OUT_struct).rangeOfChunkDates = tempStruct{i}{j}.rangeOfChunkDates;
                            SUMMARY_OUT.(tempStruct{i}{j}.name4SUMMARY_OUT_struct).fitcov = tempStruct{i}{j}.fitcov;
                            SUMMARY_OUT.(tempStruct{i}{j}.name4SUMMARY_OUT_struct).LBQ_statistic = tempStruct{i}{j}.LBQ_statistic;
                            SUMMARY_OUT.(tempStruct{i}{j}.name4SUMMARY_OUT_struct).LBQ_squaredstatistic = tempStruct{i}{j}.LBQ_squaredstatistic;
                            SUMMARY_OUT.(tempStruct{i}{j}.name4SUMMARY_OUT_struct).LillieTest = tempStruct{i}{j}.LillieTest;
                            SUMMARY_OUT.(tempStruct{i}{j}.name4SUMMARY_OUT_struct).info = tempStruct{i}{j}.info;
                        end
                    end % j
                end
            end % i for
            
            % END OF ESTIMATION STAGE *************************************
            
            % START OF INFERENCE STAGE ************************************
            %% Construct residuals, variances and standardized residuals.
            % LOGIC: each chunk uses the model estimated on the previous
            % chunk (j-1) data. Hence the j-1 model fit is used to get
            % conditional variances, residuals and standardized residuals
            % w.r.t. the current chunk. The current chunk dataset
            % incorporates previous chunk dataset
            residuals = cell(L,1); % zeros(N,L);
            variances = cell(L,1); %zeros(N,L);
            std_residuals = cell(L,1); %zeros(N,L);
            constant = cell(L,1); %zeros(N,L);
            
            disp('Filtering invariants AR-GARCH components');
            
            for i=1:L
                
                % 1st chunk only
                % ***************
                j = 1;
                currentChunkRowIndices{i,1} = [(j-1)*chunksLength+1 : 1 :min((j)*chunksLength,size(rawdata{i, 1},1))];
                dates_currentChunk = rawdata{i, 1}(currentChunkRowIndices{i,1},1);
                residuals{i,1}(1:chunksLength,1:2) = [dates_currentChunk,rawdata{i, 1}(1:chunksLength,2) - meanUncond{i,1}(1:chunksLength)];
                variances{i,1}(1:chunksLength,1:2)  = [dates_currentChunk,varianceUncond{i,1}(1:chunksLength)];
                std_residuals{i,1}(1:chunksLength,1:2)  =  [dates_currentChunk,residuals{i,1}(1:chunksLength,2)./sqrt(variances{i,1}(1:chunksLength,2))];
                constant{i,1}(1:chunksLength,i) = 0;
                % ***************
                
                % ... subsequent chunks ...
                % main logic:
                % for example, if num of hist obs (L) is 1403 and the
                % chunkLength is 100 I want j to go from 2 to 15, since the
                % 15th chunk will use the model estimated on the 14th
                % chunk
                for j = 2 : chunks{i}
                    currentChunkRowIndices{i,1} = [(j-1)*chunksLength+1 : 1 :min((j)*chunksLength,size(rawdata{i, 1},1))];
                    dates_currentChunk = rawdata{i, 1}(currentChunkRowIndices{i,1},1);
                    
                    modelObjName = ['Fitting_' InvariantsNamesSet{i} '_partition_' num2str(j-1)]; % name of the field of SUMMARY_OUT to be searched
                    modelObjName = strrep(modelObjName,'/','_'); % to deal with names like BP/_LN_Equity
                    
                    chunkStartTime = currentChunkRowIndices{i,1}(1);
                    chunkEndTime = currentChunkRowIndices{i,1}(end);
                    objUsed = SUMMARY_OUT.(modelObjName);
                    modelUsed = objUsed.fit;
                    
                    % IMPORTANT: here I draw R,MU and VAR from a dataset
                    % starting from time t=1 (modelUsed has been estimated
                    % in the same manner, from time 1 to the end of the preceding complete chunk)
                    
                    R = rawdata{i, 1}(currentChunkRowIndices{i,1},2);     % realized returns chunk(vector)
                    MU = meanUncond{i}(currentChunkRowIndices{i,1});      % unconditional mean for returns (vector)
                    VAR = varianceUncond{i,1}(currentChunkRowIndices{i}); % unconditional variance for returns (vector)
                    
                    % seeds values for inference
                    V0 = (variances{i,1}(currentChunkRowIndices{i}(1)-2:currentChunkRowIndices{i}(1)-1,2))';   % variances 'seed' (scalar)
                    EPS0 = (residuals{i,1}(currentChunkRowIndices{i}(1)-2:currentChunkRowIndices{i}(1)-1,2))'; % innovations 'seed' (scalar)
                    R0 = (rawdata{i,1}(currentChunkRowIndices{i}(1)-2:currentChunkRowIndices{i}(1)-1,2));     % returns 'seed' (scalar)
                    
                    if strcmp(objUsed.model,'garch') |  strcmp(objUsed.model,'gjr') |  strcmp(objUsed.model,'egarch')
                        modelUsed.Offset = meanUncond{i,1}(end);
                        
                        alpha = ArmaGarch.getalpha(modelUsed);
                        beta = ArmaGarch.getbeta(modelUsed);
                        
                        if strcmp(objUsed.model,'garch')
                            varianceModelConstant = varianceUncond{i,1}(end).*(1-alpha-beta);
                            modelUsed.Constant = varianceModelConstant; % variance 'drift'
                        elseif strcmp(objUsed.model,'gjr')
                            leverage = ArmaGarch.getleverage(modelUsed);
                            varianceModelConstant = varianceUncond{i,1}(end).*(1-alpha-beta-0.5.*leverage);
                            modelUsed.Constant = varianceModelConstant; % variance 'drift'
                        elseif strcmp(objUsed.model,'egarch') % ** NOT USED FOR NOW
                            % REVIEW
                            varianceModelConstant = log(varianceUncond{i,1}(end)).*(1-modelUsed.GARCH{1}-modelUsed.ARCH{1}-0.5.*modelUsed.Leverage{1});
                        else
                            modelUsed.Variance = VAR(end);
                        end
                        
                        [variances_temp,LogL] = infer(modelUsed, R, 'E0',EPS0,'V0',V0);
                        
                        residuals_temp = R - modelUsed.Offset;
                        std_residuals_temp = residuals_temp./sqrt(variances_temp);
                        
                    elseif strcmp(objUsed.model,'arima')
                        
                        modelUsed.Constant = meanUncond{i,1}(end).*(1-modelUsed.AR{1});
                     
                        mcv = metaclass(modelUsed.Variance); % variance model metaclass
                        
                        if strcmp(mcv.Name,'garch') | strcmp(mcv.Name,'gjr') | strcmp(mcv.Name,'egarch')
                            alpha = ArmaGarch.getalpha(modelUsed.Variance);
                            beta = ArmaGarch.getbeta(modelUsed.Variance);
                        end
                            
                        if strcmp(mcv.Name,'garch')
                            varianceModelConstant = varianceUncond{i,1}(end).*(1-alpha-beta);
                            modelUsed.Variance.Constant = varianceModelConstant; % variance 'drift'
                        elseif strcmp(mcv.Name,'gjr')
                            leverage = ArmaGarch.getleverage(modelUsed.Variance);
                            varianceModelConstant = varianceUncond{i,1}(end).*(1-alpha-beta-0.5.*leverage);
                            modelUsed.Variance.Constant = varianceModelConstant; % variance 'drift'
                        elseif strcmp(mcv.Name,'egarch') % ** NOT USED FOR NOW
                            % REVIEW
                            varianceModelConstant = log(varianceUncond{i,1}(end)).*(1-modelUsed.Variance.GARCH{1}-modelUsed.Variance.ARCH{1});
                        else
                            modelUsed.Variance = VAR(end);
                        end
                        
                        [residuals_temp, variances_temp, LogL] = infer(modelUsed, R, ...
                            'Y0',R0,'E0',EPS0,'V0',V0);
                        std_residuals_temp = residuals_temp./sqrt(variances_temp);
                        
                    elseif strcmp(objUsed.model,'none') % HERE WE'LL USE ORIGINAL RETURNS
                        residuals_temp = R - MU; % here we use the 'original' returns %
                        variances_temp = VAR;
                        std_residuals_temp = residuals_temp./sqrt(variances_temp);
                    end
                    
                    residuals{i,1}(currentChunkRowIndices{i},1:2) =  [dates_currentChunk,residuals_temp];
                    variances{i,1}(currentChunkRowIndices{i},1:2) =  [dates_currentChunk,variances_temp];
                    std_residuals{i,1}(currentChunkRowIndices{i},1:2) =  [dates_currentChunk,std_residuals_temp];
                    
                    clear residuals_temp variances_temp std_residuals_temp const_temp;
                    
                end % FOR on j:1:chunks (# of chunks)
                
            end % FOR on i=1:L (# of invariants)
            
            
            % here I want to allign the GARCH output used within rhe current AA run to
            % the set of common invariants' dates
            upar.inputTS = [rawdata;residuals;variances;std_residuals]';
            upar.op_type = 'fillUsingNearest';
            upar.referenceDatesVector = universeObj.AllInvariants.Dates ;
            Util = Utilities(upar);
            Util.GetCommonDataSet;
            
            returns = Util.Output.DataSet.data(:,1:L);
            residuals = Util.Output.DataSet.data(:,L+1:2*L);
            variances = Util.Output.DataSet.data(:,2*L+1:3*L);
            std_residuals = Util.Output.DataSet.data(:,3*L+1:4*L);
            % in very rare cases I have NaNs in std_residuals, most
            % probably due to dividing residuals by 'zero' variance at the
            % beginning of the timeseries. TODO: inestigate this further
            std_residuals(1,isnan(std_residuals(1,:))) = 0;

            U.ARMA_GARCH_filtering.residuals = residuals;
            U.ARMA_GARCH_filtering.returns = returns;
            U.ARMA_GARCH_filtering.variances = variances;
            U.ARMA_GARCH_filtering.std_residuals = std_residuals;
            U.ARMA_GARCH_filtering.SUMMARY_OUT = SUMMARY_OUT;
            U.ARMA_GARCH_filtering.MapDatesToChunks = MapDatesToChunks;
            
        end % ARMAGARCH_filtering
        
        
    end % publc methods
    
    methods (Static)
        function out = getalpha(currentVarModel)
            if numel(currentVarModel.GARCH)>0
                out = currentVarModel.GARCH{1};
            else
                out = 0;
            end
        end
        
        function out = getbeta(currentVarModel)
            if numel(currentVarModel.ARCH)>0
                out = currentVarModel.ARCH{1};
            else
                out = 0;
            end
        end
        
        function out = getleverage(currentVarModel)
            if numel(currentVarModel.Leverage)>0
                out = currentVarModel.Leverage{1};
            else
                out = 0;
            end
        end
    end % static methods
    
end % classdef


% **********
% **********

