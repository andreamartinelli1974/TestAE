classdef AutoEncoder_DR < handle
    
    properties (Constant)
        SeeNNtraining = true(1); % to see or not to see the nntraintool
    end
    
    properties (SetAccess = immutable)
       TrainingSet = []; % set of data to train the AutoEncoder
       Targets = []; % set of data targets (could be different from the number of trainig set invariants)
       InputParams = []; % set of parameters fot the AutoEncoder setup
    end
    
    properties 
       Seed = []; % The autoencoder used to build the net object
       AutoEncNet = []; % the net created from the autoencoder to expand the choice of params and features
       OptimalParameters = []; % Optimal parameters for thr net to be found with a spot check test
       OptimalPerformance = []; % performance of the net with optimal parameters from spot check test
       InputSet2Encode = []; % Set of data to be encoded
       InputSet2Decode = []; % Set of data to be decoded
       
       CodedSet = []; % set of encoded data (with shrinked dimension)
       SimulatedSet = []; % set of decoded data (same dimension of the InputSet)
       OUT4Debug = []; % for debugging and fine tuning purposes
    end
    
    methods
        
        function AE = AutoEncoder_DR(TrainingSet,InputParams) % constructor
            % 2 main task:
            
            % a) train the native autoencoder:
            AE.InputParams = InputParams;
            AE.Seed = trainAutoencoder(TrainingSet, AE.InputParams.HiddenSize,...
                'EncoderTransferFunction','logsig',...
                'DecoderTransferFunction', 'purelin',...
                'L2WeightRegularization', 0.0,...
                'SparsityRegularization', 1,...
                'SparsityProportion', 0.4,...
                'MaxEpochs', 1000,...
                'ShowProgressWindow',AE.SeeNNtraining,...
                'ScaleData', true);
            
            % b) creates the net from the native autoencoder and set a
            % series of parameters:
            
            % Model training / testing / validation subsamples
            AE.AutoEncNet = network(AE.Seed); % transforming into a Matlab neural network object type
            AE.AutoEncNet.divideFcn = AE.InputParams.divideFcn; % Divide data
            AE.AutoEncNet.divideMode = AE.InputParams.divideMode;
            % Divide up every sample
            % training, validation and test set proportions
            AE.AutoEncNet.divideParam.trainRatio = AE.InputParams.divideParam.trainRatio;
            AE.AutoEncNet.divideParam.valRatio = AE.InputParams.divideParam.valRatio;
            AE.AutoEncNet.divideParam.testRatio = AE.InputParams.divideParam.testRatio;
            % ** net.performParam.normalization = 'standard';
            
            AE.AutoEncNet.performFcn = AE.InputParams.LossFcn;
            
            if strcmp(AE.AutoEncNet.performFcn,'mse')
                % ADD A TAPPED DELAY LINE to introduce dependencies upon lagged input returns
                % available only with mse loss function
                AE.AutoEncNet.inputWeights{1,1}.delays = AE.InputParams.Delays;
            end
            
            % transfer functions in the 2 layers (encoder/decoder)
            AE.AutoEncNet.layers{1}.transferFcn = AE.InputParams.EncoderTransferFunction; % 'radbas'; %
            AE.AutoEncNet.layers{2}.transferFcn = AE.InputParams.DecoderTransferFunction;
            
            % net1.trainFcn = 'trainscg'; % use with msesparse
            AE.AutoEncNet.trainFcn = AE.InputParams.trainFcn; % use with mse
            
            % When working with timeseries in Matlab Neural Network it is better to use timeseries in cell array form,
            % where each cell corresponds to a point in time. Each cell can contain more than one observed feature wrt the
            % time it refers to. See comments to the function matrixTs2CellTs
            AE.TrainingSet = AE.matrixTs2CellTs(TrainingSet);
            AE.Targets = AE.matrixTs2CellTs(TrainingSet(1:AE.InputParams.N_myFactors,:)); % I want only the initial N_myFactors as targets
            
        end % AutoEncoder_DR
        
        function parametersSpotCheck(AE)
            % The purpose of this function is to spotcheck several parameters
            % combinations for the neural network in 'net'
            % This function is called by EncodedTimeSeriesExample_WithDelays.mlx (see
            % comments in there for more details)
            
            % The batterys of test performed below is differentiated depending on
            % whether the 'mse' or 'msesparse' Loss Function is used, since they have
            % different parameters
            
            % INPUTS:
            % -> net: NN object as defined in EncodedTimeSeriesExample_WithDelays
            % -> XX: cell array of dimension [1xTime] representing a timeseries. Each cell
            % (point in time) can contain several values (features), defining a
            % timeseries of n-dimensional variables,
            % -> targets: cell array of dimension [1xTime] representing a timeseries.
            % Each point can have a dimension higher than 1, as above (not necessarily
            % the same dimension as the elements of XX)
            
            
            if strcmp(AE.AutoEncNet.performFcn,'msesparse') % WHEN USING 'msesparse' Loss Function
                
                % TOOD: parametrize and provide as an input
                % defining parameters combinations
                sparsityRegularization = [0:0.2:2];
                sparsity = [0.05:0.10:0.50];
                L2WeightRegularization = [10e-7:10e-3:0.1];
                
                testedParameters = [];
                performanceLog = [];
                
                ns = numel(sparsityRegularization);
                ns1 = numel(sparsity);
                nL = numel(L2WeightRegularization);
                
                checksTot = ns*ns1*nL;
                
                testedParameters = [];
                performanceLog = [];
                
                % 3 nested loops to test all the parameters combinaations defined
                % above
                for s=1:ns
                    for s1=1:ns1
                        for L=1:nL
                            % initializes the weights matrices, while building net1
                            % from net
                            net1 = configure(AE.AutoEncNet,AE.TrainingSet,AE.Targets);
                            
                            net1.trainParam.epochs = AE.InputParams.MaxEpoch;
                            net1.trainParam.max_fail = 8;
                            net1.trainParam.showWindow = AE.SeeNNtraining;
                            
                            % set the parameters for the current loop
                            net1.performParam.sparsityRegularization = sparsityRegularization(s);
                            net1.performParam.sparsity = sparsity(s1);
                            net1.performParam.L2WeightRegularization = L2WeightRegularization(L);
                            
                            % ****  TRAIN *****
                            [net1,tr] = train(net1,AE.TrainingSet,AE.Targets);
                            % nntraintool('close');
                            
                            % Test the Network
                            X_hat_2 = net1(AE.TrainingSet);
                            testTargets = cell2mat(AE.Targets) .* cell2mat(tr.testMask);
                            
                            testPerformance = perform(net1,testTargets,cell2mat(X_hat_2)); % measure of performance used for selection
                            
                            testedParameters = [testedParameters;[sparsityRegularization(s),sparsity(s1),L2WeightRegularization(L)]];
                            performanceLog = [performanceLog;testPerformance];
                        end
                    end
                end
                
            elseif strcmp(AE.AutoEncNet.performFcn,'mse') % WHEN USING 'mse' Loss Function
                
                % TOOD: parametrize and provide as an input
                regularization = [10e-7:10e-3:0.2];
                nL = numel(regularization);
                testedParameters = [];
                performanceLog = [];
                
                for L=1:nL
                    
                    % initializes the weights matrices, while building net1
                    % from net
                    net1 = configure(AE.AutoEncNet,AE.TrainingSet,AE.Targets);
                    
                    net1.trainParam.epochs = AE.InputParams.MaxEpoch;
                    net1.trainParam.max_fail = 8;
                    net1.trainParam.showWindow = AE.SeeNNtraining;
                    
                    % set the parameters for the current loop
                    net1.performParam.regularization = regularization(L);
                    
                    % ****  TRAIN *****
                    [net1,tr] = train(net1,AE.TrainingSet,AE.Targets);
                    % nntraintool('close');
                    
                    % Test the Network
                    X_hat_2 = net1(AE.TrainingSet);
                    testTargets = cell2mat(AE.Targets) .* cell2mat(tr.testMask);
                    
                    testPerformance = perform(net1,testTargets,cell2mat(X_hat_2)); % measure of performance used for selection
                    
                    testedParameters = [testedParameters;regularization(L)];
                    performanceLog = [performanceLog;testPerformance];
                    
                end
            end
            
            % optimal parameters
            [mn,mni] = min(abs(performanceLog));
            AE.OptimalPerformance = performanceLog(mni);
            AE.OptimalParameters = testedParameters(mni,:);
        end % parametersSpotCheck
        
        function SetNet(AE)
            
            if strcmp(AE.AutoEncNet.performFcn,'msesparse') % WHEN USING 'msesparse' Loss Function
                
                
                % initializes the weights matrices, while building net1
                % from net
                AE.AutoEncNet = configure(AE.AutoEncNet,AE.TrainingSet,AE.Targets);
                
                AE.AutoEncNet.trainParam.epochs = AE.InputParams.MaxEpoch;
                AE.AutoEncNet.trainParam.max_fail = 8;
                AE.AutoEncNet.trainParam.showWindow = AE.SeeNNtraining;
                
                % set the parameters for the current loop
                AE.AutoEncNet.performParam.sparsityRegularization =  AE.OptimalParameters(1);
                AE.AutoEncNet.performParam.sparsity =  AE.OptimalParameters(2);
                AE.AutoEncNet.performParam.L2WeightRegularization =  AE.OptimalParameters(3);
                
                % ****  TRAIN *****
                [AE.AutoEncNet,tr] = train(AE.AutoEncNet,AE.TrainingSet,AE.Targets);
                
                
                
            elseif strcmp(AE.AutoEncNet.performFcn,'mse') % WHEN USING 'mse' Loss Function
                
                
                % initializes the weights matrices, while building net1
                % from net
                AE.AutoEncNet = configure(AE.AutoEncNet,AE.TrainingSet,AE.Targets);
                
                AE.AutoEncNet.trainParam.epochs = AE.InputParams.MaxEpoch;
                AE.AutoEncNet.trainParam.max_fail = 8;
                AE.AutoEncNet.trainParam.showWindow = AE.SeeNNtraining;
                
                % set the parameters for the current loop
                AE.AutoEncNet.performParam.regularization = AE.OptimalParameters;
                
                % ****  TRAIN *****
                [AE.AutoEncNet,tr] = train(AE.AutoEncNet,AE.TrainingSet,AE.Targets);
                
            end
        end % SetNet
        
        function [output,Xf,Af] = EncDecWdelays_f(AE,InputX,op_type)
            
            % this is a modified version of the function generated automatically by Matlab through
            % genFunction(net1,'testF'). It has been modified to parametrize some data
            % that are defined as constants in the Matlab version.
            
            %%%%%% INPUTS : 
            %%%%%% X = n x t double array with the series of invariants
            %%%%%%     to be encoded/decoded (n series x t timesteps)
            %%%%%% op_type: 'encode' or 'decode'
            
            
            % Format Input Arguments
            if ~iscell(InputX)
                XX = AE.matrixTs2CellTs(InputX);
            else
                XX = InputX;
            end
            [X,Xi] = preparets(AE.AutoEncNet,XX); % This function simplifies the task of 
                                                  % reformatting input and target time series.
                                                  % It automatically shifts time series 
                                                  % to fill the initial input and layer delay states.
            
            % Dimensions
            TS = size(X,2); % timesteps
            if ~isempty(X)
                Q = size(X{1},2); % samples/series
            elseif ~isempty(Xi)
                Q = size(Xi{1},2);
            else
                Q = 0;
            end
            
            % encoder bias and weights
            bias_1 = AE.AutoEncNet.b{1};
            IW_1_1 = AE.AutoEncNet.IW{1,1};
            % decoder bias and weights
            bias_2 = AE.AutoEncNet.b{2};
            LW_2_1 =  AE.AutoEncNet.LW{2,1};
            
            if strcmp(op_type,'encode') % when used for encoding
                
                % preprocessing settings
                preproc.ymin = AE.AutoEncNet.inputs{1}.processSettings{1}.ymin;
                preproc.gain = AE.AutoEncNet.inputs{1}.processSettings{1}.gain;
                preproc.xoffset = AE.AutoEncNet.inputs{1}.processSettings{1}.xoffset;
                
            elseif strcmp(op_type,'decode') % when using for decoding
                
                % postprocessing settings
                postproc.gain = AE.AutoEncNet.output.processSettings{1}.gain;
                postproc.xoffset = AE.AutoEncNet.output.processSettings{1}.xoffset;
                postproc.ymin = AE.AutoEncNet.output.processSettings{1}.ymin;
                
            end
            
            highestDelay = AE.AutoEncNet.inputWeights{1}.delays(end);
            
            
            if highestDelay == 0 %%%%% case with no delays %%%%%%
                for ts=1:TS
                    if strcmp(op_type,'encode') % when used for encoding
                        % Input 1 of netObj.encoder
                        Xp1 = mapminmax_apply(X{1},preproc);
                        
                        % Layer 1 of netObj.encoder
                        if strcmp(AE.AutoEncNet.layers{1}.transferFcn,'radbas')
                            output{1,ts} = radbas_apply(repmat(bias_1,1,Q) + IW_1_1*Xp1); % features
                        elseif strcmp(AE.AutoEncNet.layers{1}.transferFcn,'logsig')
                            output{1,ts} = logsig_apply(repmat(bias_1,1,Q) + IW_1_1*Xp1);
                        end
                    elseif strcmp(op_type,'decode') % when using for decoding
                        % Layer 2 of netObj.decoder
                        a2 = repmat(bias_2,1,Q) + LW_2_1*X{ts};
                        % Output 1 of netObj.decoder
                        output{1,ts} = mapminmax_reverse(a2,postproc); % predicted X
                    end
                end % time loop
                
            else %%%%% case with delays %%%%%%
                if strcmp(op_type,'encode')
                    Xd1 = cell(1,highestDelay+1);
                    for n=1:highestDelay
                        Xd1{n} = mapminmax_apply(Xi{1,n},preproc);
                    end
                end
                
                % Allocate Outputs
                output = cell(1,TS);
                
                % Time loop
                for ts=1:TS
                    % Rotating delay state position
                    xdts = mod(ts+highestDelay-1,highestDelay+1)+1;
                    if strcmp(op_type,'encode') % when used for encoding
                        
                        % Input 1 of netObj.encoder
                        Xd1{xdts} = mapminmax_apply(X{1,ts},preproc);
                        
                        % Layer 1 of netObj.encoder
                        tapdelay1 = cat(1,Xd1{mod(xdts-AE.AutoEncNet.inputWeights{1,1}.delays-1,xdts)+1});
                        
                        if strcmp(AE.AutoEncNet.layers{1}.transferFcn,'radbas')
                            output{1,ts} = radbas_apply(repmat(bias_1,1,Q) + IW_1_1*tapdelay1);
                        elseif strcmp(AE.AutoEncNet.layers{1}.transferFcn,'logsig')
                            output{1,ts} = logsig_apply(repmat(bias_1,1,Q) + IW_1_1*tapdelay1);
                        end
                        
                    elseif strcmp(op_type,'decode') % when using for decoding
                        
                        % Layer 2
                        a2 = repmat(bias_2,1,Q) + LW_2_1*X{ts};
                        
                        % Output 1
                        output{1,ts} = mapminmax_reverse(a2,postproc);
                        
                    end
                end % time loop
               
                % Final Delay States
                finalxts = TS+(1: highestDelay);
                xits = finalxts(finalxts<=highestDelay);
                xts = finalxts(finalxts>highestDelay)-highestDelay;
                Xf = [Xi(:,xits) X(:,xts)];
                Af = cell(2,0);
                
            end
            % Format Output Arguments
            
            output = cell2mat(output);
            
            % Map Minimum and Maximum Input Processing Function
            function y = mapminmax_apply(x,settings)
                y = bsxfun(@minus,x,settings.xoffset);
                y = bsxfun(@times,y,settings.gain);
                y = bsxfun(@plus,y,settings.ymin);
            end
            
            % Map Minimum and Maximum Output Reverse-Processing Function
            function x = mapminmax_reverse(y,settings)
                x = bsxfun(@minus,y,settings.ymin);
                x = bsxfun(@rdivide,x,settings.gain);
                x = bsxfun(@plus,x,settings.xoffset);
            end
            
            % Radial Basis Transfer Function
            function a = radbas_apply(n,~)
                a = exp(-(n.*n));
            end
            % Log-Sigmoid Transfer Function
            function a = logsig_apply(n,~)
                a = 1 ./ (1 + exp(-n));
            end
        end %EncDecWdelays_f
        
    end % methods
    
    methods (Static)
        
        function XX = matrixTs2CellTs(X)
            % X contains timeseries data in its rows: so the dimension is [numOfTS x Time]
            % the loop below is based on the time dimension and for each time put in a
            % cell of a cell array the sample point for that time, where the sample
            % point has dimension numOfTS.
            % Basically can look at it as a timeseries of multidimensional datapoints
            % this is what should be provided to neural betwork objects in Matlab when
            % dealing with sequences
            
            for k=1:size(X,2)
                XX{k,:} = X(:,k);
            end
            
            % in the output the time dimension must be the 'horizontal' dim
            % so I want to get an horizontal cell vector, where each cell contains the
            % set of features that define a specific point in time
            XX = XX';
        end
    end
    
end % classdef
