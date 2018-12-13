% MainEncoder4AA.m: this is a prototype to be merged within the AA
% framework. The purpose is to get both dimension reduction and 1-st and
% 2nd order autocorreletion filtered out

close all; clear all; clc;
%% ************ INITIAL SETTINGS AND BLOOMBERG DATA DOWNLOAD *************

start_date = '01/01/2000';
end_date = '08/31/2018';

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

N_myFactors = size(IU.ticker,1); % when using 'external factor' not included in the AA

% % external factors (to add more explanatory variables)
% IU.ticker{10,1} = ['EURUSD Curncy'];           
% IU.ticker{11,1} = ['EURGBP Curncy'];           
% IU.ticker{12,1} = ['EURCHF Curncy']; 
% IU.ticker{13,1} = ['EURJPY Curncy']; 
% IU.ticker{14,1} = ['EURCNY Curncy']; 
% IU.ticker{15,1} = ['EURSGD Curncy']; 
% IU.ticker{16,1} = ['BRNT LN Equity']; 
% IU.ticker{17,1} = ['COPA LN Equity']; 
% IU.ticker{18,1} = ['V2X Index']; 
% IU.ticker{19,1} = ['WEAT LN Equity']; 
% IU.ticker{20,1} = ['TLT US Equity']; 
% IU.ticker{21,1} = ['SHY US Equity']; 
% IU.ticker{22,1} = ['SCHO US Equity']; 
% IU.ticker{23,1} = ['IBCX LN Equity']; 
% IU.ticker{24,1} = ['IEAG LN Equity']; 
% IU.ticker{25,1} = ['IEGL LN Equity']; 
% IU.ticker{26,1} = ['EURZAR Curncy']; 
% IU.ticker{27,1} = ['SNRFIN CDSI GEN 5Y Corp']; 
% IU.ticker{28,1} = ['NKY Index']; 
% IU.ticker{29,1} = ['KOSPI Index']; 
% IU.ticker{30,1} = ['SHCOMP Index']; 
% IU.ticker{31,1} = ['TOP40 Index']; 
% IU.ticker{32,1} = ['DAX Index']; 
% IU.ticker{33,1} = ['FTSEMIB Index']; 
% IU.ticker{34,1} = ['NDX Index']; 

N = numel(IU.ticker(:,1)); % # assets
%% *********** Get data from Bloomberg and compute invariants ************

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
X = [Invariants.data(:,1:N_myFactors)';(Invariants.data(:,1:N_myFactors)').^2] 

% optionally add external explanatory data
if useExternalFactors
    X = [X;Invariants.data(:,N_myFactors+1:end)'];
end
 

targets = (X(1:N_myFactors,:));
% optionally add the squared residulas to t6he targets (always used in the
% input dataset)
if useSquaredMyFactorsInTargets
    targets = [targets;(Invariants.data(:,1:N_myFactors)').^2];
end

J = size(X,2);

hiddenSize_1 = NeuronsNo;
autoenc1 = trainAutoencoder(X,hiddenSize_1,...
    'EncoderTransferFunction','logsig', ...
    'DecoderTransferFunction','purelin', ...
    'L2WeightRegularization',0.00000,...
    'SparsityRegularization',1, ...
    'SparsityProportion',0.40, ...
    'ScaleData',false);

% Extract the features in the hidden layer.
features1 = encode(autoenc1,X); % [13x178] input encoded into [10x178] signals matrix

% 2nd encoding layer layer
if ~useSquaredMyFactorsInTargets
    hiddenSize_2 = N_myFactors; 
else
    hiddenSize_2 = N_myFactors*2; 
end

autoenc2 = trainAutoencoder(features1,hiddenSize_2,...
    'EncoderTransferFunction','logsig', ...
    'DecoderTransferFunction','purelin', ...
    'L2WeightRegularization',0.00000,...
    'SparsityRegularization',1, ...
    'SparsityProportion',0.40, ...
    'ScaleData',false);


features2 = encode(autoenc2,features1);
softnet = trainSoftmaxLayer(features2,X,'LossFunction','crossentropy');

% deeper network used for conversion into a NN struct
% then the NN struct will be fine tuned to reflect the specific needs
deeperNet = stack(autoenc1,autoenc2,softnet);

% ** deeperNet = train(deeperNet,X,X); % no need to train this obj
% ** X_hat = decode(autoenc2,features1); % to get back to the original dataset

%% *** CONVERT THE AUTOENCODER INTO A NEURAL NETWORK OBJECT ***
%      and fine tune its parameters
%  (then use the function EncDec3LayersWdelays_f to use it for encoding / decoding)

% When working with timeseries in Matlab Neural Network it is better to use 
% timeseries in cell array form, where each cell corresponds to a point in
% time. Each cell can contain more than one observed feature wrt the time 
% it refers to. See comments to the function matrixTs2CellTs
XX = matrixTs2CellTs(X);
targets = matrixTs2CellTs(targets); 

% Model training / testing / validation subsamples
net = network(deeperNet); % transforming into a Matlab neural network object type

net.divideFcn = 'dividerand'; %  % Divide data randomly
% training, validation and test set proportions
net.divideParam.trainRatio = 70/100;
net.divideParam.valRatio = 15/100;
net.divideParam.testRatio = 15/100;

% an alternative to 'dividerand'
% net.divideFcn = 'divideind'; % 'dividerand'; %  % Divide data randomly
% net.divideMode = 'time'; % 'sample';  % Divide up every sample or in terms of times
% % training, validation and test set proportions
% net.divideParam.trainInd = [1:2000];
% net.divideParam.valInd = [2001:2300];
% net.divideParam.testInd = [2301:2600];

net.divideMode = 'time'; % 'sample';  % Divide up every sample or in terms of times

% ** net.performParam.normalization = 'standard';

% Plot Functions (see help nnplot) to be used
net.plotFcns = {'plotperform','plottrainstate','ploterrhist', ...
    'plotregression', 'plotfit'};

% activation  functions definitions
net.layers{1}.transferFcn = 'tansig';
net.layers{2}.transferFcn = 'purelin';
net.layers{3}.transferFcn = 'purelin';

% time delay in 3rd layer (from 2nd one output)
net.layerWeights{3,2}.delays = [0:3];

% renaming layers for clarity
net.layers{1}.name = 'Encoder'
net.layers{2}.name = 'Decoder'
net.layers{3}.name = 'Time Delays Layer'

view(net);


%% ********************** IMPORTANTS NETWORK SETTINGS *********************
% Here the network Loss function and the transfer functions for both layers 
% are chosen % Also the training function is chosen below: Scaled conjugate 
% gradient backpropagation is faster bat can be less accurate than the full
% *Levenberg-Marquardt *backpropagation.

% ***** USING msesparse es Loss Function *****
% (no delayed nodes allowed with msesparse)
% net.performFcn = 'msesparse';
% net.performParam.sparsityRegularization=0;%0;
% net.performParam.sparsity = 0.0; % 0.050;
% net.performParam.L2WeightRegularization=0.000000;

% ***** USING mse Loss Function *****
net.performFcn =  'mse'; %'sse'; %
net.performParam.regularization=1e-7; % with mse

% net1.trainFcn = 'trainscg'; % use with msesparse
net.trainFcn = 'trainlm'; % 'trainlm'; % use with mse

%% ********* INITIAL TRAINING (for test) and PLOTTING RESULTS *************
net1 = configure(net,XX,targets);
net1.trainParam.epochs = 2000;
net1.trainParam.max_fail = 6;
net1.trainParam.showWindow = true(1);
net1.performParam.regularization = 10e-7;

[Xs,Xi,Ai] = preparets(net1,XX);

tic
[net1,tr] = train(net1,XX,targets,[],Ai);
toc

% Test the Network
X_hat_2 = net1(XX);

X_hat_2 = cell2mat(X_hat_2);
figure;
subplot(3,3,1);
for k=1:N_myFactors
    subplot(3,3,k);
    plot(X(k,:),'b')
    hold on
    grid on
    plot(X_hat_2(k,:),'g')
end


% * genFunction(net1,'testFnew'); % USED TO HELP WRITING EncDec3LayersWdelays_f.M
% * [Y,Xf,Af] = testFnew(XX,[],Ai,original_x);

% prepare data with delays
[Xs,Xi,Ai] = preparets(net1,XX);

% use EncDec3LayersWdelays_f to separately:
% 1) extract encoded features
features = EncDec3LayersWdelays_f(net1,XX,[],Ai,'encode');
% 2) getting back to trhe original space while also accounting for
% cross-time and cross sectional autocorrelations and correlations
x_pred = EncDec3LayersWdelays_f(net1,features,[],Ai,'decode');
x_pred = cell2mat(x_pred);

% TEST: compare input data with estimated ones
figure;
subplot(3,3,1);
for k=1:N_myFactors
    subplot(3,3,k);
    plot(X(k,:),'b')
    hold on
    grid on
    plot(x_pred(k,:),'g')
end



%% *********************    PARAMETERS SPOT-CHECK    **********************
% this is basically a repetition of the step above, but with a fine tuning
% of the network parameters (some of them) through parametersSpotCheck.m

tic
[optimalParameters,optimalPerformance] = parametersSpotCheck(net,XX,targets);
toc

net1 = configure(net,XX,targets); % to properly set inputs/outputs dimesions (based on X and targets)

net1.trainParam.epochs = 2000;
net1.trainParam.max_fail = 8;
net1.trainParam.showWindow = false(1);

if strcmp(net.performFcn,'mse')
    net1.performParam.regularization = optimalParameters(1);
elseif strcmp(net.performFcn,'msesparse')
    net1.performParam.sparsityRegularization = optimalParameters(1);
    net1.performParam.sparsity = optimalParameters(2);
    net1.performParam.L2WeightRegularization = optimalParameters(3);
end
 
[Xs,Xi,Ai] = preparets(net1,XX);
tic
[net1,tr] = train(net1,XX,targets,[],Ai);
toc
% nntraintool('close');

% Test the Network
X_hat_2 = net1(XX);
% * Y_hat = sim(net1,X);
e = gsubtract(targets,X_hat_2);
perf = perform(net1,X_hat_2,targets) % assess performance

% ************ Training, Validation and Test sets Performance *************
trainTargets = cell2mat(targets) .* cell2mat(tr.trainMask);
valTargets = cell2mat(targets) .* cell2mat(tr.valMask);
testTargets = cell2mat(targets) .* cell2mat(tr.testMask);
trainPerformance = perform(net1,trainTargets,cell2mat(X_hat_2));
trainPerformanceInSample = perform(net1,trainTargets,cell2mat(X_hat_2))
trainPerformanceTest = perform(net1,testTargets,cell2mat(X_hat_2))

valPerformance = perform(net1,valTargets,cell2mat(X_hat_2))
testPerformance = perform(net1,testTargets,cell2mat(X_hat_2))

% View the Network
view(net1)

% Plots
figure, plotperform(tr)

X_hat_2 = cell2mat(X_hat_2);
figure;
subplot(3,3,1);
for k=1:N_myFactors
    subplot(3,3,k);
    plot(X(k,:),'b')
    hold on
    grid on
    plot(X_hat_2(k,:),'g')
end

figure, plotperform(tr)
figure, plottrainstate(tr)
figure, ploterrhist(e)
figure, plotregression(targets,X_hat_2)
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
 
[Xs,Xi,Ai] = preparets(net1,XX);
features = EncDec3LayersWdelays_f(net1,XX,[],Ai,'encode');
x_pred = EncDec3LayersWdelays_f(net1,features,[],Ai,'decode');
x_pred = cell2mat(x_pred);

highestDelay = net1.layerWeights{3,2}.delays(end); % highest delay used

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
    plot(X(k,1:end),'b')
    hold on
    grid on
    plot(x_pred(k,:),'g')
end

% cumulated returns (using exp() since log returns have been modeled)
figure;
subplot(3,3,1);
for k=1:N_myFactors
    subplot(3,3,k);
    plot(exp(cumsum(X(k,1:end))),'b')
    hold on
    grid on
    plot(exp(cumsum(x_pred(k,:))),'g')
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
F = cell2mat(features);
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
C_hat=corr(x_pred(1:N_myFactors,:)');
C_true = corr(X(1:N_myFactors,:)')
dd = C_true - C_hat;

figure; hold on; grid on;
plot(dd)
plot(mean(dd),'Color','r','LineWidth',4)
