classdef ThreeLayerNet < handle
    
    % This class build a Neural Network to be used by AutoEncoder_DR
    % This is a 3 Layer net, made by an autoencoder and a final softmax 
    % layer that has delays in input (to deal with autoregression)
    
    % the class has a constructor that build and train the network and the
    % encoder/decoder function
    
    properties (Constant)
        SeeNNtraining = true(1); % false(1); % to see or not to see the nntraintool
    end
    
    properties (SetAccess = immutable)
       InputParams = []; % set of parameters fot the AutoEncoder setup
    end
    
    properties
        Seed = []; % The autoencoder used to build the net object
        DeeperNet = []; % the net created from the autoencoder to expand the choice of params and features
        EncDecNet = []; % the net to be used by the encoder/decoder function (must be the same type of net of DeeperNet)
        AutoCorrFlag = []; % to store the lbqtest results for autoregression on encoded features
        HeteroscedFlag = [];  % to store the lbqtest0 results for heteroscedaticity on encoded features
        OUT4Debug = []; % for debugging and fine tuning purposes
    end
    
    methods
        
        function Obj = ThreeLayerNet(TrainingSet1,InputParams)
            % 2 main task:
            
            % a) train the native autoencoders & softnet:
            Obj.InputParams = InputParams;
            
            if Obj.InputParams.SquareRet % in case we are interested in vola dependencies and autoregression
                tmp = TrainingSet1(1:Obj.InputParams.N_myFactors,:);
                sqR = tmp.^2;
                TrainingSet1 = [TrainingSet1(1:Obj.InputParams.N_myFactors,:); sqR; TrainingSet1(Obj.InputParams.N_myFactors+1:end,:)];
                Target = TrainingSet1(1:Obj.InputParams.N_myFactors,:);
                TsqR = Target.^2;
                Target = [Target; TsqR];
            else
                Target = TrainingSet1(1:Obj.InputParams.N_myFactors,:);
            end
            
            % first layer
            Obj.Seed{1} = trainAutoencoder(TrainingSet1, Obj.InputParams.HiddenSize,...
                'EncoderTransferFunction','logsig',...
                'DecoderTransferFunction', 'purelin',...
                'L2WeightRegularization', 0.0,...
                'SparsityRegularization', 1,...
                'SparsityProportion', 0.4,...
                'ShowProgressWindow',Obj.SeeNNtraining,...
                'ScaleData', false,...
                'MaxEpoch', 1);
            
            TrainingSet2 = encode(Obj.Seed{1},TrainingSet1);
            if Obj.InputParams.SquareRet
                HiddenSize2 = Obj.InputParams.N_myFactors*2;
            else
                HiddenSize2 = Obj.InputParams.N_myFactors;
            end
            
            % second layer
            Obj.Seed{2} = trainAutoencoder(TrainingSet2, HiddenSize2,...
                'EncoderTransferFunction','logsig',...
                'DecoderTransferFunction', 'purelin',...
                'L2WeightRegularization', 0.0,...
                'SparsityRegularization', 1,...
                'SparsityProportion', 0.4,...
                'ShowProgressWindow',Obj.SeeNNtraining,...
                'ScaleData', false,...
                'MaxEpoch', 1);
            
            TrainingSet3 = encode(Obj.Seed{2},TrainingSet2);
            
            % third layer
            Obj.Seed{3} = trainSoftmaxLayer(TrainingSet3,Target,'LossFunction',...
                          'crossentropy','ShowProgressWindow',Obj.SeeNNtraining,'MaxEpoch', 1);
            
            % b) creates the net from the native autoencoder and set a
            % series of parameters:
            
            % Model training / testing / validation subsamples
            inet = stack(Obj.Seed{1},Obj.Seed{2},Obj.Seed{3}); % transforming into a Matlab neural network object type
            Obj.DeeperNet = network(inet);
            Obj.DeeperNet.divideFcn = Obj.InputParams.divideFcn; % Divide data
            Obj.DeeperNet.divideMode = Obj.InputParams.divideMode;
            % Divide up every sample
            % training, validation and test set proportions
            Obj.DeeperNet.divideParam.trainRatio = Obj.InputParams.divideParam.trainRatio;
            Obj.DeeperNet.divideParam.valRatio = Obj.InputParams.divideParam.valRatio;
            Obj.DeeperNet.divideParam.testRatio = Obj.InputParams.divideParam.testRatio;
            % ** net.performParam.normalization = 'standard';
            
            Obj.DeeperNet.performFcn = Obj.InputParams.LossFcn;
            
            if strcmp(Obj.DeeperNet.performFcn,'mse') || strcmp(Obj.DeeperNet.performFcn,'sse')
                % ADD A TAPPED DELAY LINE to introduce dependencies upon lagged input returns
                % available only with mse loss function
                Obj.DeeperNet.layerWeights{3,2}.delays = Obj.InputParams.Delays;
            end
            
            % transfer functions in the 2 layers (encoder/decoder)
            Obj.DeeperNet.layers{1}.transferFcn = Obj.InputParams.EncoderTransferFunction;
            Obj.DeeperNet.layers{2}.transferFcn = Obj.InputParams.DecoderTransferFunction;
            Obj.DeeperNet.layers{3}.transferFcn = Obj.InputParams.DecoderTransferFunction;
            
            % renaming layers for clarity
            Obj.DeeperNet.layers{1}.name = 'Encoder';
            Obj.DeeperNet.layers{2}.name = 'Decoder';
            Obj.DeeperNet.layers{3}.name = 'Time Delay Layer';
            
            % net1.trainFcn = 'trainscg'; % use with msesparse
            Obj.DeeperNet.trainFcn = Obj.InputParams.trainFcn; % use with mse
            
            if Obj.SeeNNtraining == true
                nntraintool('close')
            end
            
        end % constructror
        
        function [output,Xf,Af] = EncDecFunction(Obj,InputX,op_type)
            
            % this is a modified version of the function generated automatically by Matlab through
            % genFunction(net1,'testF'). It has been modified to parametrize some data
            % that are defined as constants in the Matlab version.
            
            %%%%%% INPUTS :
            %%%%%% InputX = n x t double array with the series of invariants
            %%%%%%     to be encoded/decoded (n series x t timesteps)
            %%%%%% op_type: 'encode' or 'decode'
            timeDelays = Obj.DeeperNet.layerWeights{3,2}.delays;
            
            if Obj.InputParams.SquareRet && strcmp(op_type,'encode')
                % in case we are interested in vola dependencies and autoregression
                % must be used only in the 'encode' input
                tmp = InputX(1:Obj.InputParams.N_myFactors,:);
                sqR = tmp.^2;
                InputX = [InputX(1:Obj.InputParams.N_myFactors,:); sqR; InputX(Obj.InputParams.N_myFactors+1:end,:)];
            end
            
            % Format Input Arguments
            if ~iscell(InputX)
                XX = Obj.matrixTs2CellTs(InputX);
            else
                XX = InputX;
            end
            
            [X,Xi,Ai] = preparets(Obj.DeeperNet,XX); % This function simplifies the task of
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
            bias_1 = Obj.DeeperNet.b{1};
            IW_1_1 = Obj.DeeperNet.IW{1,1};
            % decoder bias and weights
            bias_2 = Obj.DeeperNet.b{2};
            LW_2_1 =  Obj.DeeperNet.LW{2,1};
            bias_3 = Obj.DeeperNet.b{3};
            LW_3_2 =  Obj.DeeperNet.LW{3,2};
            
            % Layer Delay States
            Ad1 = [Ai(1,:) cell(1,1)];
            Ad2 = [Ai(2,:) cell(1,1)];
            Ad3 = [Ai(3,:) cell(1,1)];
            
            highestDelay = timeDelays(end);
            
            % Allocate Outputs
            output = cell(1,TS);
            
            % Time loop
            for ts=1:TS
                
                if strcmp(op_type,'encode') % when used for encoding    
                    
                    % Layer 1 of netObj.encoder
                    if strcmp(Obj.DeeperNet.layers{1}.transferFcn,'radbas')
                        output{1,ts} = radbas_apply(repmat(bias_1,1,Q) + IW_1_1*X{1,ts});
                    elseif strcmp(Obj.DeeperNet.layers{1}.transferFcn,'logsig')
                        output{1,ts} = logsig_apply(repmat(bias_1,1,Q) + IW_1_1*X{1,ts});
                    elseif strcmp(Obj.DeeperNet.layers{1}.transferFcn,'tansig')
                        output{1,ts} = tansig_apply(repmat(bias_1,1,Q) + IW_1_1*X{1,ts});
                    end
                    
                elseif strcmp(op_type,'decode') % when using for decoding
                    
                    % Rotating delay state position
                    adts = mod(ts+highestDelay-1,highestDelay+1)+1;
                    
                    % Layer 2
                    Ad1{adts} = X{1,ts};
                    tapdelay1 = cat(1,Ad1{mod(adts-0-1,highestDelay+1)+1});
                    Ad2{adts} = repmat(bias_2,1,Q) + LW_2_1*tapdelay1;
                    
                    % Layer 3
                    tapdelay2 = cat(1,Ad2{mod(adts-timeDelays-1,highestDelay+1)+1});
                    Ad3{adts} = repmat(bias_3,1,Q) + LW_3_2*tapdelay2;
                    
                    % Output 1
                    output{1,ts} = Ad3{adts};
                    
                end
            end % time loop
            
            % Final Delay States
            finalats = TS+(1: highestDelay);
            ats = mod(finalats-1,highestDelay+1)+1;
            Xf = cell(1,0);
            Af = cell(3,highestDelay);
            Af(1,:) = Ad1(:,ats);
            Af(2,:) = Ad2(:,ats);
            Af(3,:) = Ad3(:,ats);

            % Format Output Arguments
            output = cell2mat(output);
            
            % check for autocorrelation in features using lbqtest
            if strcmp(op_type,'encode') % when used for encoding
                nrFeature = size(output,1);
                Obj.AutoCorrFlag = zeros(nrFeature,8);
                Obj.HeteroscedFlag = zeros(nrFeature,8);
                for j = 1:nrFeature
                    [h,pValue,stat,cValue] = lbqtest(output(j,:),'lags',[1,2]);
                    Obj.AutoCorrFlag(j,:) = [h,pValue,stat,cValue];
                    [h,pValue,stat,cValue] = lbqtest(output(j,:).^2,'lags',[1,2]);
                    Obj.HeteroscedFlag(j,:) = [h,pValue,stat,cValue];
                end
            end
            
            %%% USEFUL FUNCTION
            
            % Radial Basis Transfer Function
            function a = radbas_apply(n,~)
                a = exp(-(n.*n));
            end
            % Log-Sigmoid Transfer Function
            function a = logsig_apply(n,~)
                a = 1 ./ (1 + exp(-n));
            end
            % Sigmoid Symmetric Transfer Function
            function a = tansig_apply(n,~)
                a = 2 ./ (1 + exp(-2*n)) - 1;
            end
            
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
    
end