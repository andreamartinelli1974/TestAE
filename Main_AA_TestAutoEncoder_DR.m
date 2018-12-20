% MainEncoder4AA.m: this is a prototype to be merged within the AA
% framework. The purpose is to get both dimension reduction and 1-st and
% 2nd order autocorreletion filtered out

close all; clear all; clc;
%% ************ INITIAL SETTINGS AND BLOOMBERG DATA DOWNLOAD *************

start_date = '01/01/2001';
end_date = '11/30/2018';

NeuronsNo = 5; % # neurons used 
useExternalFactors = true;
useSquaredMyFactorsInTargets = true;

userId = getenv('USERNAME');
path(path,['C:\Users\',userId,'\Documents\GitHub\Utilities\']);

DataFromBBG.save2disk = false(1); % True to save all Bloomberg calls to disk for future retrieval
DataFromBBG.folder = [cd,'\BloombergCallsData\'];

if DataFromBBG.save2disk
    if exist('BloombergCallsData','dir')==7
        rmdir(DataFromBBG.folder(1:end-1),'s');
    end
    mkdir(DataFromBBG.folder(1:end-1));
end

try
    % * javaaddpath('C:\blp\DAPI\blpapi3.jar');
    DataFromBBG.BBG_conn = blp; % throw error when Bloomberg is not installed
    pause(2);
    while isempty(DataFromBBG.BBG_conn) % ~isconnection(DataFromBBG.BBG_conn)
        pause(2);
    end
    
    DataFromBBG.NOBBG = false(1); % True when Bloomberg is NOT available and to use previopusly saved data
    
catch ME
    DataFromBBG.BBG_conn = [];
    DataFromBBG.NOBBG = true(1); % if true (on machines with no BBG terminal), data are recovered from previously saved files (.save2disk option above)
end

%%  **************** Investment Universe Setup *****************

% BBG tickers
IU.ticker{1,1} = ['SPX Index'];             
IU.ticker{2,1} = ['SX5E Index'];           
IU.ticker{3,1} = ['HSI Index'];        
IU.ticker{4,1} = ['HYG US Equity'];        
IU.ticker{5,1} = ['VXN Index'];             
IU.ticker{6,1} = ['INDU Index'];        
IU.ticker{7,1} = ['EEM US Equity'];         
IU.ticker{8,1} = ['VIX Index'];              
IU.ticker{9,1} = ['NDX Index']; 

% IU.ticker{1,1} = ['AAPL US Equity'];             
% IU.ticker{2,1} = ['BAYN GR Equity'];           
% IU.ticker{3,1} = ['FTSEMIB Index'];        
% IU.ticker{4,1} = ['SXKP Index'];        
% IU.ticker{5,1} = ['G IM EQUITY'];             
% IU.ticker{6,1} = ['GE US EQUITY'];        
% IU.ticker{7,1} = ['TRIP US Equity'];         
% IU.ticker{8,1} = ['CF1 Index'];              
% IU.ticker{9,1} = ['ST1 Index']; 


N_myFactors = size(IU.ticker,1); % when using 'external factor' not included in the AA

% external factors (to add more explanatory variables)
IU.ticker{10,1} = ['EURUSD Curncy'];           
IU.ticker{11,1} = ['EURGBP Curncy'];           
IU.ticker{12,1} = ['EURCHF Curncy']; 
IU.ticker{13,1} = ['EURJPY Curncy']; 
IU.ticker{14,1} = ['EURCNY Curncy']; 
IU.ticker{15,1} = ['EURSGD Curncy']; 
IU.ticker{16,1} = ['BRNT LN Equity']; 
IU.ticker{17,1} = ['COPA LN Equity']; 
IU.ticker{18,1} = ['V2X Index']; 
IU.ticker{19,1} = ['WEAT LN Equity']; 
IU.ticker{20,1} = ['TLT US Equity']; 
IU.ticker{21,1} = ['SHY US Equity']; 
IU.ticker{22,1} = ['SCHO US Equity']; 
IU.ticker{23,1} = ['IBCX LN Equity']; 
IU.ticker{24,1} = ['IEAG LN Equity']; 
IU.ticker{25,1} = ['IEGL LN Equity']; 
IU.ticker{26,1} = ['EURZAR Curncy']; 
IU.ticker{27,1} = ['SNRFIN CDSI GEN 5Y Corp']; 
IU.ticker{28,1} = ['NKY Index']; 
IU.ticker{29,1} = ['KOSPI Index']; 
IU.ticker{30,1} = ['SHCOMP Index']; 
IU.ticker{31,1} = ['TOP40 Index']; 
IU.ticker{32,1} = ['DAX Index']; 
IU.ticker{33,1} = ['FTSEMIB Index']; 
IU.ticker{34,1} = ['NDX Index']; 

N = numel(IU.ticker(:,1)); % # assets
%% *********** Get data from Bloomberg and compute invariants ************
disp('creates the invariants')

uparams.DataFromBBG = DataFromBBG;
uparams.ticker = [IU.ticker(:,1)];
uparams.fields = 'LAST_PRICE';
uparams.history_start_date = start_date;
uparams.history_end_date = end_date;
uparams.granularity = 'DAILY';
U = Utilities(uparams);
U.GetHistPrices;

% get prices on a set of common dates
clear uparams;
uparams.inputTS = U.Output.HistInfo;
uparams.op_type = ['intersect'];
Util = Utilities(uparams);
Util.GetCommonDataSet;

% use Utilities.RetCalc to get invariants and manage rollover jumps when needed
%  no rollovers correction needed
clear uparams;
uparams.data1 = [Util.Output.DataSet.dates,Util.Output.DataSet.data];
uparams.data2 = [];
uparams.lag = 1;
uparams.pct = 1;
uparams.logret = 1;
uparams.rolldates = [];
uparams.last_roll = [];
uparams.EliminateFlag = [];
uparams.ExtendedLag = 3;
U2 = Utilities(uparams);
U2.RetCalc;

Invariants.data  = U2.Output.CleanRet(:,2:end);
Invariants.dates = U2.Output.CleanRet(:,1);
Invariants.names = IU.ticker(:,1);

%% **********************   AUTOENCODER  SET UP *************************
% This is done only to simplify the setup of a neural network structure, by
% building an autopencoder with the desired number og layer and then
% transforming it (through network(encoder))  into a NN structure

% Input DataSet

% returns and squared returns for the 'core' dataset (my factors only)
X = [Invariants.data(:,1:N_myFactors)';(Invariants.data(:,1:N_myFactors)').^2]; 
trainingset = Invariants.data(:,1:N_myFactors)';

% optionally add external explanatory data
if useExternalFactors
    X = [X;Invariants.data(:,N_myFactors+1:end)'];
    trainingset = [trainingset;Invariants.data(:,N_myFactors+1:end)'];
end

targets = (X(1:N_myFactors,:));
% optionally add the squared residulas to t6he targets (always used in the
% input dataset)
if useSquaredMyFactorsInTargets
    targets = [targets;(Invariants.data(:,1:N_myFactors)').^2];
end

%setup of cell array
XX = matrixTs2CellTs(X);
targets = matrixTs2CellTs(targets);

disp('creates the basic net')
% creation of the AutoEncoder object
AEparams.HiddenSize = 5;
AEparams.N_myFactors = N_myFactors; % numel(AssetLegend); % number of real factors to be modelled (must be the first n of the data set)
AEparams.EncoderTransferFunction = 'logsig'; %  'radbas'; %
AEparams.DecoderTransferFunction = 'purelin';
AEparams.MaxEpoch = 2500;
AEparams.ScaleData = false; % true;
AEparams.divideFcn = 'dividerand'; % Divide data randomly
AEparams.divideMode = 'time'; % 'sample';
AEparams.divideParam.trainRatio = 70/100;
AEparams.divideParam.valRatio = 15/100;
AEparams.divideParam.testRatio = 15/100;
AEparams.Delays = [0 1 2 3];
AEparams.LossFcn = 'mse'; % 'sse'; % 'msesparse'; % Loss function used to train the net
AEparams.trainFcn = 'trainlm'; % 'trainrp'; % use with mse / sse
% v.trainFcn = 'trainscg'; % use with msesparse
AEparams.SquareRet =  true(1); % false(1); %  use also the suared returns in input to catch vola autoreg

AutoEncoder = AutoEncoder_DR(trainingset, AEparams);

%view(AutoEncoder.DeeperNet);

% Test the Network
disp('test the net')
X_hat = AutoEncoder.DeeperNet(XX);

X_hat = cell2mat(X_hat);
figure;
subplot(3,3,1);
for k=1:N_myFactors
    subplot(3,3,k);
    plot(X(k,:),'b')
    hold on
    grid on
    plot(X_hat(k,:),'g')
end

features =  AutoEncoder.EncDecFunction(trainingset,'encode')';
x_pred =  AutoEncoder.EncDecFunction(features','decode')';

% TEST: compare input data with estimated ones

figure;
subplot(3,3,1);
for k=1:N_myFactors
    subplot(3,3,k);
    plot(X(k,:),'b')
    hold on
    grid on
    plot(x_pred(:,k),'g')
end



%% *********************    PARAMETERS SPOT-CHECK    **********************
% this is basically a repetition of the step above, but with a fine tuning
% of the network parameters (some of them) through parametersSpotCheck.m
disp('spot-check')
AutoEncoder.parametersSpotCheck(trainingset);

disp('set the final net')
AutoEncoder.SetNet(trainingset);

%test the Network
X_hat = AutoEncoder.DeeperNet(XX);
e2 = gsubtract(targets,X_hat);
perf2 = perform(AutoEncoder.DeeperNet,X_hat,targets) % assess performance

% ************ Training, Validation and Test sets Performance *************

figure, plotperform(AutoEncoder.OUT4Debug.SetNet.tr)

X_hat = cell2mat(X_hat);
figure;
subplot(3,3,1);
for kk=1:N_myFactors
    subplot(3,3,kk);
    plot(X(kk,10:end),'b')
    hold on
    grid on
    plot(X_hat(kk,10:end),'g')
end

figure, plotperform(AutoEncoder.OUT4Debug.SetNet.tr)
figure, plottrainstate(AutoEncoder.OUT4Debug.SetNet.tr)
figure, ploterrhist(e2)
figure, plotregression(targets,X_hat)
%% ********* Use the network and its settings to encode / decode **********
% Once the NN has been trained it can be used through
% EncDec3LayersWdelays_f.m, either for encoding or decoding purposes

% For example, in AA framework one might be willing doing the following:
% 1) use EncDec3LayersWdelays_f with 'encode' to extract i.i.d. features
% 2) use these features to model tails, nultivariate distribution, etc.,
% .... simulate new features
% 3) use simulated features to get back to the original space using 
% ncDec3LayersWdelays_f with 'decode'

% ** genFunction(net1,'xxxxxF'); % this can be used to understand how to write a function like 'EncDec3LayersWdelays_f' to use the network

disp('test the net')
features =  AutoEncoder.EncDecFunction(trainingset,'encode')';
x_pred =  AutoEncoder.EncDecFunction(features','decode')';


%% 
% Obviously x_pred is shorter than the original X by 'highestDelay' elements, 
% since to make the first prediction (1st element in x_pred) the features for  
% the 
% 
% previous  'highestDelay' days are needed.

figure;
subplot(3,3,1);
for k=1:N_myFactors
    subplot(3,3,k);
    plot(X(k,10:end),'b')
    hold on
    grid on
    plot(x_pred(10:end,k),'g')
end

% cumulated returns (using exp() since log returns have been modeled)
figure;
subplot(3,3,1);
for k=1:N_myFactors
    subplot(3,3,k);
    plot(exp(cumsum(X(k,10:end))),'b')
    hold on
    grid on
    plot(exp(cumsum(x_pred(10:end,k))),'g')
end

%% .... a few more tests on 'features' autocorrelations, compared to initial one

% F = cell2mat(features);
%     corr((X(1,2:end)').^2,(X(1,1:end-1)').^2)
%     corr((F(1,2:end)').^2,(F(1,1:end-1)').^2)
%     corr((X(1,2:end)').^2,(X(1,1:end-1)').^2)
%     corr((F(1,2:end)').^2,(F(1,1:end-1)').^2)
%   [h,pval]=lbqtest(F(2,:).^2,'Lags',[1:4],'alpha',0.01)
%   [h,pval]=lbqtest(F(2,:).^2,'Lags',[1:4],'alpha',0.01)


% use Akaike and Bayesian information ratio to assess usefulness of arima model with
% original data

numObs = size(X,2)
options   = optimoptions(@fmincon, 'Display'  , 'off', 'Diagnostics', 'off', ...
    'Algorithm', 'interior-point', 'TolCon', 1e-6,'MaxIterations',3000,'OptimalityTolerance',1e-07,'StepTolerance',1e-07);
model = arima('Constant',NaN,'ARLags', 1,'MALags', [],'Distribution', ...
    'Gaussian', 'Variance', garch(1,1));
NoModel = arima('Constant',NaN)

clear aicNoModel bicNoModel aicModel bicModel;
for k=1:N_myFactors
    
    % ***********  using the model
    R = X(k,:)';
    [fittedM, fittedCov, logL ,fitInfo] = estimate(model,  R, 'options', options);
    
    % *[residuals_temp, variances_temp, LogL] = infer(fittedM,  R);%, ...
    %                             'Y0',R0,'E0',EPS0,'V0',V0);
    % std_residuals_temp = residuals_temp./sqrt(variances_temp);
    
    [aicModel(k),bicModel(k)] = aicbic(logL,5,numObs);
    
    % ***********  NO model
    [fittedM, fittedCov, logLNoModel ,fitInfo] = estimate(NoModel,  R, 'options', options);
    [aicNoModel(k),bicNoModel(k)] = aicbic(logLNoModel,2,numObs);
end

% choose the model with the lowest ratio: the inequalities below yield 1
% when using 'model' must be preferred
aicModel<aicNoModel
bicModel<bicNoModel


%%
% .... same thing wrt features
F = features';
nf = size(F,1);
clear aicNoModel_F bicNoModel_F aicModel_F bicModel_F;

for k=1:nf
    % ***********  using the model
    R = F(k,:)';
    [fittedM, fittedCov, logL ,fitInfo] = estimate(model,  R, 'options', options);
    [aicModel_F(k),bicModel_F(k)] = aicbic(logL,5,numObs);
    [residuals_temp, variances_temp] = infer(fittedM,  R);
    std_residuals_temp = residuals_temp./sqrt(variances_temp);
    % ***********  NO model
    [fittedM, fittedCov, logLNoModel ,fitInfo] = estimate(NoModel,  R, 'options', options);
    [aicNoModel_F(k),bicNoModel_F(k)] = aicbic(logLNoModel,2,numObs);
end

% choose the model with the lowest ratio: the inequalities below yield 1
% when using 'model' must be preferred
aicModel_F<aicNoModel_F
bicModel_F<bicNoModel_F

%%
% comparing correlations structures
C_hat=corr(x_pred(1:N_myFactors,:)')
C_true = corr(X(1:N_myFactors,:)')
dd = C_true - C_hat;

figure; hold on; grid on;
plot(dd)
plot(mean(dd),'Color','r','LineWidth',4)

%% USEFULL FUNCTION %%
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

