classdef AutoEncoder_DR < handle
    
    % This class build a Neural Network starting from the AutoEncoder
    % matlab native class.
    % The net could be used as dimension reductor
    % there are 4 main methods:
    % 1) the constructor: build the plain vanilla autoencoder and uses it to
    % create the neural network. Then set all the params from InputParams
    % 2) parametersSpotCheck: look for the best combination of parameters
    % such SparsityRegularization, L2WeightRegularization for the net
    % 3) SetNet: set and train the effective net using the optimal parameters found
    % with parametersSpotCheck
    % 4) EncDecFunction: encode and decode data using the effective net.
    % Could be used with or without delay without specifying it.
    
    % Inputs for the class constructor:
    %
    % TrainingSet: array of data, n invariant x t times
    %
    % InputParams.HiddenSize: hidden size of the net
    % InputParams.N_myFactors: number of real factors to be modelled (must be the first n of the data set)
    % InputParams.EncoderTransferFunction: could be 'logsig' of 'radbas'
    % InputParams.DecoderTransferFunction: at the moment only 'purelin';
    % InputParams.MaxEpoch: Max epoch for net training (tha same for any training in the class)
    % InputParams.ScaleData: true - false (true is the best for non-normalized data)
    % InputParams.divideFcn: 'dividerand' Divide data randomly (other possibilities could be found in matlab help
    % InputParams.divideMode: 'time' or 'sample' (time is our choise);
    % InputParams.divideParam.trainRatio: % of data set used for training 
    % InputParams.divideParam.valRatio: % of data set used for validation
    % InputParams.divideParam.testRatio: % of data set used for testing
    % InputParams.Delays: time delays to be used as input (eg [0 1 2 10])
    % InputParams.LossFcn: 'mse'; % 'msesparse'; % Loss function used to train the net (with delays only mse is allowed)
    % InputParams.trainFcn = 'trainlm'; % used with mse
    % InputParams.trainFcn = 'trainscg'; % used with msesparse
    % InputParams.SquareRet = true(1); % false(1) % use also the suared returns in input to catch vola autoreg
    
    properties (Constant)
        SeeNNtraining =   true(1); % false(1); % to see or not to see the nntraintool
    end
    
    properties (SetAccess = immutable)
       InputParams = []; % set of parameters fot the AutoEncoder setup
    end
    
    properties 
       Net = []; % this is the object used to build the net and the encoder/decoder functions
       TrainingSet = []; % set of data to train the AutoEncoder
       Targets = []; % set of data targets (could be different from the number of trainig set invariants)
       OptimalParameters = []; % Optimal parameters for thr net to be found with a spot check test
       OptimalPerformance = []; % performance of the net with optimal parameters from spot check test
       OUT4Debug = []; % for debugging and fine tuning purposes
    end
    
    methods
        
        function AE = AutoEncoder_DR(TrainingSet1,InputParams) % constructor
            
            
         
            % Call the cunstructor of the net:
            AE.Net = ThreeLayerNet(TrainingSet1,InputParams);
            
            % import the net built
            %AE.DeeperNet = AE.Net.DeeperNet; 
            
            % When working with timeseries in Matlab Neural Network it is better to use timeseries in cell array form,
            % where each cell corresponds to a point in time. Each cell can contain more than one observed feature wrt the
            % time it refers to. See comments to the function matrixTs2CellTs
            
            AE.InputParams = InputParams;
            
            if AE.InputParams.SquareRet % in case we are interested in vola dependencies and autoregression
                tmp = TrainingSet1(1:AE.InputParams.N_myFactors,:);
                sqR = tmp.^2;
                TrainingSet1 = [TrainingSet1(1:AE.InputParams.N_myFactors,:); sqR; TrainingSet1(AE.InputParams.N_myFactors+1:end,:)];
                Target = TrainingSet1(1:AE.InputParams.N_myFactors,:);
                TsqR = Target.^2;
                Target = [Target; TsqR];
            else
                Target = TrainingSet1(1:AE.InputParams.N_myFactors,:);
            end
            
            AE.TrainingSet = AE.matrixTs2CellTs(TrainingSet1);
            AE.Targets = AE.matrixTs2CellTs(Target); % I want only the initial N_myFactors as targets and eventually the squared returns    
            
            [Xs,Xi,Ai] = preparets(AE.Net.DeeperNet,AE.TrainingSet);
            
            AE.Net.DeeperNet.plotFcns = {'plotperform','plottrainstate','ploterrhist', ...
                                     'plotregression', 'plotfit'};
            
            [AE.Net.DeeperNet,tr] = train(AE.Net.DeeperNet,AE.TrainingSet,AE.Targets,[],Ai);
            
            AE.OUT4Debug.AutoEncoder_DR.tr = tr;
            
            if AE.SeeNNtraining == true
                nntraintool('close')
            end

        end % AutoEncoder_DR
        
        function parametersSpotCheck(AE,TrainingSet)
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
            
            if ~isempty(TrainingSet)
                if AE.InputParams.SquareRet % in case we are interested in vola dependencies and autoregression
                    tmp = TrainingSet(1:AE.InputParams.N_myFactors,:);
                    sqR = tmp.^2;
                    TrainingSet = [TrainingSet(1:AE.InputParams.N_myFactors,:); sqR; TrainingSet(AE.InputParams.N_myFactors+1:end,:)];
                    Target = TrainingSet(1:AE.InputParams.N_myFactors,:);
                    TsqR = Target.^2;
                    Target = [Target; TsqR];
                else
                    Target = TrainingSet(1:AE.InputParams.N_myFactors,:);
                end
            
                TrainingSet = AE.matrixTs2CellTs(TrainingSet);
                Target = AE.matrixTs2CellTs(Target); % I want only the initial N_myFactors as targets end eventually the squared returns
            end
            
            [optimalParameters,optimalPerformance] =  AE.parametersSC(AE.Net.DeeperNet,TrainingSet,Target);
            AE.OptimalPerformance = optimalPerformance;
            AE.OptimalParameters = optimalParameters;

            
%             if strcmp(AE.Net.DeeperNet.performFcn,'msesparse')  % WHEN USING 'msesparse' Loss Function
%                 
%                 % TOOD: parametrize and provide as an input
%                 % defining parameters combinations
%                 sparsityRegularization = [0:0.2:2];
%                 sparsity = [0.05:0.10:0.50];
%                 L2WeightRegularization = [10e-7:10e-3:0.1];
%                 
%                 testedParameters = [];
%                 performanceLog = [];
%                 
%                 ns = numel(sparsityRegularization);
%                 ns1 = numel(sparsity);
%                 nL = numel(L2WeightRegularization);
%                 
%                 checksTot = ns*ns1*nL;
%                 
%                 testedParameters = [];
%                 performanceLog = [];
%                 
%                 % 3 nested loops to test all the parameters combinaations defined
%                 % above
%                 for s=1:ns
%                     for s1=1:ns1
%                         for L=1:nL
%                             % initializes the weights matrices, while building net1
%                             % from net
%                             net1 = configure(AE.Net.DeeperNet,TrainingSet,Target);
%                             
%                             net1.trainParam.epochs = AE.InputParams.MaxEpoch;
%                             net1.trainParam.max_fail = 8;
%                             net1.trainParam.showWindow = AE.SeeNNtraining;
%                             
%                             % set the parameters for the current loop
%                             net1.performParam.sparsityRegularization = sparsityRegularization(s);
%                             net1.performParam.sparsity = sparsity(s1);
%                             net1.performParam.L2WeightRegularization = L2WeightRegularization(L);
%                             
%                             % ****  TRAIN *****
%                             [Xs,Xi,Ai] = preparets(net1,TrainingSet);
%                             [net1,tr] = train(net1,TrainingSet,Target,Xi,Ai,'useParallel','yes','reduction',2);
%                             
%                             AE.OUT4Debug.parametersSpotCheck.tr{L} = tr;
%                             % nntraintool('close');
%                             
%                             % Test the Network
%                             X_hat_2 = net1(TrainingSet);
%                             testTargets = cell2mat(Targets) .* cell2mat(tr.testMask);
%                             
%                             testPerformance = perform(net1,testTargets,cell2mat(X_hat_2)); % measure of performance used for selection
%                             
%                             testedParameters = [testedParameters;[sparsityRegularization(s),sparsity(s1),L2WeightRegularization(L)]];
%                             performanceLog = [performanceLog;testPerformance];
%                         end
%                     end
%                 end
%                 
%             elseif strcmp(AE.Net.DeeperNet.performFcn,'mse') || strcmp(AE.Net.DeeperNet.performFcn,'sse')  % WHEN USING 'mse' Loss Function
%                 
%                 % TOOD: parametrize and provide as an input
%                 regularization = [10e-7:10e-3:0.2];
%                 nL = numel(regularization);
%                 testedParameters = [];
%                 performanceLog = [];
%                 
%                 for L=1:nL
%                     
%                     % initializes the weights matrices, while building net1
%                     % from net
%                     net1 = configure(AE.Net.DeeperNet,TrainingSet,Target);
%                     
%                     net1.trainParam.epochs = AE.InputParams.MaxEpoch;
%                     net1.trainParam.max_fail = 10;
%                     net1.trainParam.mu_max = 1.00e+20;
%                     net1.trainParam.showWindow = AE.SeeNNtraining;
%                     
%                     % set the parameters for the current loop
%                     net1.performParam.regularization = regularization(L);
%                     
%                     % ****  TRAIN *****
%                     [Xs,Xi,Ai] = preparets(net1,AE.TrainingSet);
%                     [net1,tr] = train(net1,TrainingSet,Target,Xi,Ai); %,'useParallel','yes','reduction',2);
%                     
%                     AE.OUT4Debug.parametersSpotCheck.tr{L} = tr;
%                     % nntraintool('close');
%                     
%                     % Test the Network
%                     X_hat_2 = net1(TrainingSet);
%                     testTargets = cell2mat(Target) .* cell2mat(tr.testMask);
%                     
%                     testPerformance = perform(net1,testTargets,cell2mat(X_hat_2)); % measure of performance used for selection
%                     
%                     testedParameters = [testedParameters;regularization(L)];
%                     performanceLog = [performanceLog;testPerformance];
%                     
%                 end
%             end
%             
%             % optimal parameters
%             [mn,mni] = min(abs(performanceLog));
%             AE.OptimalPerformance = performanceLog(mni);
%             AE.OptimalParameters = testedParameters(mni,:);

            if AE.SeeNNtraining == true
                nntraintool('close')
            end
            
        end % parametersSpotCheck
        
        function SetNet(AE,TrainingSet)
            
            if ~isempty(TrainingSet)
                if AE.InputParams.SquareRet % in case we are interested in vola dependencies and autoregression
                    tmp = TrainingSet(1:AE.InputParams.N_myFactors,:);
                    sqR = tmp.^2;
                    TrainingSet = [TrainingSet(1:AE.InputParams.N_myFactors,:); sqR; TrainingSet(AE.InputParams.N_myFactors+1:end,:)];
                    Target = TrainingSet(1:AE.InputParams.N_myFactors,:);
                    TsqR = Target.^2;
                    Target = [Target; TsqR];
                else
                    Target = TrainingSet(1:AE.InputParams.N_myFactors,:);
                end
                AE.TrainingSet = AE.matrixTs2CellTs(TrainingSet);
                AE.Targets = AE.matrixTs2CellTs(Target); % I want only the initial N_myFactors as targets
            end
            
            % initializes the weights matrices, while building net1
            % from net
            AE.Net.DeeperNet = configure(AE.Net.DeeperNet,AE.TrainingSet,AE.Targets);
            
            AE.Net.DeeperNet.trainParam.epochs = AE.InputParams.MaxEpoch;
            AE.Net.DeeperNet.trainParam.max_fail = 10;
            AE.Net.DeeperNet.trainParam.mu_max = 1.00e+50;
            AE.Net.DeeperNet.trainParam.showWindow = AE.SeeNNtraining;
            AE.Net.DeeperNet.plotFcns = {'plotperform','plottrainstate','ploterrhist', ...
                                     'plotregression', 'plotfit'};
            
            if strcmp(AE.Net.DeeperNet.performFcn,'msesparse') % WHEN USING 'msesparse' Loss Function
                % set the parameters for the current loop
                AE.Net.DeeperNet.performParam.sparsityRegularization =  AE.OptimalParameters(1);
                AE.Net.DeeperNet.performParam.sparsity =  AE.OptimalParameters(2);
                AE.Net.DeeperNet.performParam.L2WeightRegularization =  AE.OptimalParameters(3); 
            elseif strcmp(AE.Net.DeeperNet.performFcn,'mse') || strcmp(AE.Net.DeeperNet.performFcn,'sse') % WHEN USING 'mse' Loss Function
                % set the parameters for the current loop
                AE.Net.DeeperNet.performParam.regularization = AE.OptimalParameters;
            end
            
            % ****  TRAIN *****
            [Xs,Xi,Ai] = preparets(AE.Net.DeeperNet,AE.TrainingSet);
            [AE.Net.DeeperNet,tr] = train(AE.Net.DeeperNet,AE.TrainingSet,AE.Targets,Xi,Ai);%,'useParallel','yes','reduction',2);
            
            AE.OUT4Debug.SetNet.tr = tr;
            
            if AE.SeeNNtraining == true
                nntraintool('close')
            end
            
        end % SetNet
        
        function [output,Xf,Af] = EncDecFunction(AE,InputX,op_type)
            
            % this is a modified version of the function generated automatically by Matlab through
            % genFunction(net1,'testF'). It has been modified to parametrize some data
            % that are defined as constants in the Matlab version.
            
            %%%%%% INPUTS :
            %%%%%% X = n x t double array with the series of invariants
            %%%%%%     to be encoded/decoded (n series x t timesteps)
            %%%%%% op_type: 'encode' or 'decode'
            
            [output,Xf,Af] = AE.Net.EncDecFunction(InputX,op_type);
            
        end %EncDecFunction
        
    end % methods
    
    methods (Static)
        
        function XX = matrixTs2CellTs(X)
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
        end    % X contains timeseries data in its rows: so the dimension is [numOfTS x Time]
  
        
        
        function [optimalParameters,optimalPerformance] = parametersSC(net,XX,targets)
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
            
            
            clear testPerformance testedParameters performanceLog;
            
            if strcmp(net.performFcn,'msesparse') % WHEN USING 'msesparse' Loss Function
                
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
                            net1 = configure(net,XX,targets);
                            
                            net1.trainParam.epochs = 2000;
                            net1.trainParam.max_fail = 6;
                            net1.trainParam.showWindow = false(1);
                            
                            % set the parameters for the current loop
                            net1.performParam.sparsityRegularization = sparsityRegularization(s);
                            net1.performParam.sparsity = sparsity(s1);
                            net1.performParam.L2WeightRegularization = L2WeightRegularization(L);
                            
                            % ****  TRAIN *****
                            [Xs,Xi,Ai] = preparets(net1,XX);
                            [net1,tr] = train(net1,XX,targets,Xi,Ai);
                            % nntraintool('close');
                            
                            % Test the Network
                            X_hat_2 = net1(XX);
                            testTargets = cell2mat(targets) .* cell2mat(tr.testMask);
                            
                            testPerformance = perform(net1,testTargets,cell2mat(X_hat_2)); % measure of performance used for selection
                            
                            testedParameters = [testedParameters;[sparsityRegularization(s),sparsity(s1),L2WeightRegularization(L)]];
                            performanceLog = [performanceLog;testPerformance];
                        end
                    end
                end
                
            elseif strcmp(net.performFcn,'mse') | strcmp(net.performFcn,'sse') % WHEN USING 'mse' Loss Function
                
                % TOOD: parametrize and provide as an input
                regularization = [10e-7:3*10e-3:0.6];
                nL = numel(regularization);
                testedParameters = [];
                performanceLog = [];
                
                for L=1:nL
                    
                    % initializes the weights matrices, while building net1
                    % from net
                    net1 = configure(net,XX,targets);
                    
                    net1.trainParam.epochs = 2000;
                    net1.trainParam.max_fail = 8;
                    %net1.trainParam.showWindow = false(1);
                    
                    % set the parameters for the current loop
                    net1.performParam.regularization = regularization(L);
                    
                    % ****  TRAIN *****
                    [Xs,Xi,Ai] = preparets(net1,XX);
                    [net1,tr] = train(net1,XX,targets,Xi,Ai);
                    % nntraintool('close');
                    
                    % Test the Network
                    X_hat_2 = net1(XX);
                    testTargets = cell2mat(targets) .* cell2mat(tr.testMask);
                    
                    testPerformance = perform(net1,testTargets,cell2mat(X_hat_2)); % measure of performance used for selection
                    
                    testedParameters = [testedParameters;regularization(L)];
                    performanceLog = [performanceLog;testPerformance];
                    
                end
            end
            
            % optimal parameters
            [mn,mni] = min(abs(performanceLog));
            optimalPerformance = performanceLog(mni);
            optimalParameters = testedParameters(mni,:);
        end
    end
    
end % classdef
