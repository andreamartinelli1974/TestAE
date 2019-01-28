function [optimalParameters,optimalPerformance] = parametersSpotCheck(net,XX,targets)
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
    regularization = [10e-7:10e-3:0.2];
    nL = numel(regularization);
    testedParameters = [];
    performanceLog = [];
    
    for L=1:nL
        
        % initializes the weights matrices, while building net1
        % from net
        net1 = configure(net,XX,targets);
        
        net1.trainParam.epochs = 2000;
        net1.trainParam.max_fail = 8;
        net1.trainParam.showWindow = false(1);
        
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

