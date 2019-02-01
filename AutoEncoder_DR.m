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
    % InputParams.multFactor4NumericalStability: this is used to scale the
    % data set to improve numerical stability during training (e.g. if this
    % parameter = 1000, than all data in the dataset are multiplied * 1000)
    
    properties (Constant)
        SeeNNtraining =   false(1); % true(1); % to see or not to see the nntraintool
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
       PreviousRunWeights = []; % used to store the set of optimal weights (see notes below)
       NormMetrics = []; % struct to host mean and std used to normalize data and then recats them into the original space
    end
    
    methods
        
        function AE = AutoEncoder_DR(TrainingSet1,InputParams) % constructor
           
            disp('creating the net');
            
            AE.NormMetrics.mu_X4AE = nanmean(TrainingSet1');
            AE.NormMetrics.std_X4AE = nanstd(TrainingSet1');
            normTrainingSet = bsxfun(@minus, TrainingSet1', AE.NormMetrics.mu_X4AE)';
            normTrainingSet = bsxfun(@times, normTrainingSet', 1./AE.NormMetrics.std_X4AE)';
         
            % Call the cunstructor of the net:
            AE.Net = ThreeLayerNet(normTrainingSet,InputParams);
            
            % import the net built
            % * AE.DeeperNet = AE.Net.DeeperNet; 
            
            % When working with timeseries in Matlab Neural Network it is better to use timeseries in cell array form,
            % where each cell corresponds to a point in time. Each cell can contain more than one observed feature wrt the
            % time it refers to. See comments to the function matrixTs2CellTs
            
            AE.InputParams = InputParams;
        end
        
        function TrainAE(AE,TrainingSet1)
            
             
            if AE.InputParams.SquareRet % in case we are interested in vola dependencies and autoregression
                
                tmp = TrainingSet1(1:AE.InputParams.N_myFactors,:);
                sqR = tmp.^2;
                TrainingSet1 = [TrainingSet1(1:AE.InputParams.N_myFactors,:); sqR; TrainingSet1(AE.InputParams.N_myFactors+1:end,:)];
                
                AE.NormMetrics.mu_X4AE = nanmean(TrainingSet1');
                AE.NormMetrics.std_X4AE = nanstd(TrainingSet1');
                normTrainingSet = bsxfun(@minus, TrainingSet1', AE.NormMetrics.mu_X4AE)';
                normTrainingSet = bsxfun(@times, normTrainingSet', 1./AE.NormMetrics.std_X4AE)';
                
                Target = normTrainingSet(1:AE.InputParams.N_myFactors*2,:);
                
                AE.NormMetrics.mu_X4AE_targets = AE.NormMetrics.mu_X4AE(1:AE.InputParams.N_myFactors*2);
                AE.NormMetrics.std_X4AE_targets = AE.NormMetrics.std_X4AE(1:AE.InputParams.N_myFactors*2);
                
            else
                
                AE.NormMetrics.mu_X4AE = nanmean(TrainingSet1');
                AE.NormMetrics.std_X4AE = nanstd(TrainingSet1');
                normTrainingSet = bsxfun(@minus, TrainingSet1', AE.NormMetrics.mu_X4AE)';
                normTrainingSet = bsxfun(@times, normTrainingSet', 1./AE.NormMetrics.std_X4AE)';
                
                Target = normTrainingSet(1:AE.InputParams.N_myFactors,:);
                AE.NormMetrics.mu_X4AE_targets = AE.NormMetrics.mu_X4AE(1:AE.InputParams.N_myFactors);
                AE.NormMetrics.std_X4AE_targets = AE.NormMetrics.std_X4AE(1:AE.InputParams.N_myFactors);
            end
            
            AE.TrainingSet = AE.matrixTs2CellTs(normTrainingSet.*AE.InputParams.multFactor4NumericalStability);
            AE.Targets = AE.matrixTs2CellTs(normTrainingSet.*AE.InputParams.multFactor4NumericalStability); % I want only the initial N_myFactors as targets and eventually the squared returns
            
            [Xs,Xi,Ai] = preparets(AE.Net.DeeperNet,AE.TrainingSet);
            
            AE.Net.DeeperNet.plotFcns = {'plotperform','plottrainstate','ploterrhist', ...
                                     'plotregression', 'plotfit'};
            AE.Net.DeeperNet.trainParam.epochs = AE.InputParams.MaxEpoch;
            AE.Net.DeeperNet.trainParam.max_fail = 10;
            AE.Net.DeeperNet.trainParam.showWindow = AE.SeeNNtraining;
            

            if isempty(AE.PreviousRunWeights) % GP
                % prepare the network for weights intialization
                AE.Net.DeeperNet.initFcn = 'initlay';
                % using Nguyen-Widrow init function for all layers
                AE.Net.DeeperNet.layers{1}.initFcn = 'initnw';
                AE.Net.DeeperNet.layers{2}.initFcn = 'initnw';
                AE.Net.DeeperNet.layers{3}.initFcn = 'initnw';
                init(AE.Net.DeeperNet);
            else % use previous weights
                init(AE.Net.DeeperNet);
                AE.Net.DeeperNet.IW = AE.PreviousRunWeights.IW;
                AE.Net.DeeperNet.LW = AE.PreviousRunWeights.LW;
                AE.Net.DeeperNet.b = AE.PreviousRunWeights.b;
            end
            AE.Net.DeeperNet.trainParam.delt_inc = 1.2;
            AE.Net.DeeperNet.trainParam.delt_dec = 0.5;
            AE.Net.DeeperNet.trainParam.min_grad = 1e-6;
            AE.Net.DeeperNet.trainParam.delta0 = 1e-4;
            AE.Net.DeeperNet.trainParam.deltamax = 10;
            AE.Net.DeeperNet.trainParam.goal = 0;
            
            % train in 2 steps: 1st standardizing the errors to have the
            % first attempt, 2nd without this standardisation to refine the
            % weight
            AE.Net.DeeperNet.performParam.normalization = 'standard';
            [AE.Net.DeeperNet,tr] = train(AE.Net.DeeperNet,AE.TrainingSet,AE.Targets,[],Ai);
            
            AE.Net.DeeperNet.performParam.normalization = 'none';        
            [AE.Net.DeeperNet,tr] = train(AE.Net.DeeperNet,AE.TrainingSet,AE.Targets,[],Ai);
            
            % to keep weights to speed up next trainings (with slightly different
            % training set)
            AE.PreviousRunWeights.IW = AE.Net.DeeperNet.IW;
            AE.PreviousRunWeights.LW = AE.Net.DeeperNet.LW;
            AE.PreviousRunWeights.b = AE.Net.DeeperNet.b;
            
            AE.OUT4Debug.AutoEncoder_DR.tr = tr;
            
            if AE.SeeNNtraining == true
                nntraintool('close')
            end
            
            % if no spot check has to take place these values will be kept                     
            AE.OptimalPerformance = NaN;
            AE.OptimalParameters = 0;   

        end % AutoEncoder_DR
        
        function [output,Xf,Af] = EncDecFunction(AE,InputX,op_type)
            
            % disp('Encoding or decoding');
            % this is a modified version of the function generated automatically by Matlab through
            % genFunction(net1,'testF'). It has been modified to parametrize some data
            % that are defined as constants in the Matlab version.
            
            %%%%%% INPUTS :
            %%%%%% X = n x t double array with the series of invariants
            %%%%%%     to be encoded/decoded (n series x t timesteps)
            %%%%%% op_type: 'encode' or 'decode'
            
            if strcmp(op_type,'encode')
                if AE.InputParams.SquareRet % in case we are interested in vola dependencies and autoregression
                    tmp = InputX(1:AE.InputParams.N_myFactors,:);
                    sqR = tmp.^2;
                    InputX = [InputX(1:AE.InputParams.N_myFactors,:); sqR; InputX(AE.InputParams.N_myFactors+1:end,:)];
                    
                    AE.NormMetrics.mu_X4AE = nanmean(InputX');
                    AE.NormMetrics.std_X4AE = nanstd(InputX');
                    normDataSet = bsxfun(@minus, InputX', AE.NormMetrics.mu_X4AE)';
                    normDataSet = bsxfun(@times, normDataSet', 1./AE.NormMetrics.std_X4AE)';
                    
                else
                    
                    AE.NormMetrics.mu_X4AE = nanmean(InputX');
                    AE.NormMetrics.std_X4AE = nanstd(InputX');
                    normDataSet = bsxfun(@minus, InputX', AE.NormMetrics.mu_X4AE)';
                    normDataSet = bsxfun(@times, normDataSet', 1./AE.NormMetrics.std_X4AE)';
                    
                    AE.NormMetrics.mu_X4AE_targets = AE.NormMetrics.mu_X4AE(1:AE.InputParams.N_myFactors*2);
                    AE.NormMetrics.std_X4AE_targets = AE.NormMetrics.std_X4AE(1:AE.InputParams.N_myFactors*2);
                end
            else
                normDataSet = InputX;
            end
% %             normDataSet = bsxfun(@minus, InputX', AE.NormMetrics.mu_X4AE)';
% %             normDataSet = bsxfun(@times, normDataSet', 1./AE.NormMetrics.std_X4AE)';
            
            [output,Xf,Af] = AE.Net.EncDecFunction(normDataSet,op_type);
            
            if strcmp(op_type,'decode')
                output = bsxfun(@times, output', AE.NormMetrics.std_X4AE_targets)';
                output = bsxfun(@plus, output', AE.NormMetrics.mu_X4AE_targets)';
            end
            
            
% % %             [output,Xf,Af] = AE.Net.EncDecFunctionVectorized(InputX,op_type);
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

    end
    
end % classdef
