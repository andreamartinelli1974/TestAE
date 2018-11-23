close all; clear all; clc;
start_date = '01/01/2000';
end_date = '08/31/2018';

userId = getenv('USERNAME');
path(path,['C:\Users\',userId,'\Documents\GitHub\Utilities\']);

DataFromBBG.save2disk = true(1); % True to save all Bloomberg calls to disk for future retrieval
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

%% BBG tickers
IU.ticker{1,1} = ['SPX Index'];             % equity
IU.ticker{2,1} = ['SX5E Index'];            % equity
IU.ticker{3,1} = ['IHYG LN Equity'];        % high yield EUR Corp
IU.ticker{4,1} = ['HYG US Equity'];         % high yield US Corp
IU.ticker{5,1} = ['IEGA LN Equity'];        % EUR Govt Bonds
IU.ticker{6,1} = ['IEF US Equity'];         % US 7-10 years Treasuries
IU.ticker{7,1} = ['EEM US Equity'];         % Emerging Mkts Bonds
IU.ticker{8,1} = ['IBGS IM Equity'];        % Short term EUR Govt Bonds
% external factors
IU.ticker{9,1} = ['VIX Index'];            % S&P volatility
IU.ticker{10,1} = ['EURUSD Curncy'];           
IU.ticker{11,1} = ['EURGBP Curncy'];           
IU.ticker{12,1} = ['EURCHF Curncy']; 
IU.ticker{13,1} = ['EURJPY Curncy']; 


N = numel(IU.ticker(:,1)); % # assets
N_myFactors = 8;

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

%% creates the autoencoders

X = Invariants.data'; % U2.Output.CleanPrices(:,2:end)'; %
J = size(X,2);

hiddenSize1 = 7;
autoenc1 = trainAutoencoder(X,hiddenSize1,...
    'EncoderTransferFunction','logsig', ...
    'DecoderTransferFunction','purelin', ...
    'L2WeightRegularization',0.00000,...
    'SparsityRegularization',2, ...
    'SparsityProportion',0.20, ...
    'ScaleData',true);

view(autoenc1); % to see the encoder structure

features1 = encode(autoenc1,X);

hiddenSize2 = 5;
autoenc2 = trainAutoencoder(features1,hiddenSize2,...
    'EncoderTransferFunction','logsig', ...
    'DecoderTransferFunction','purelin', ...
    'L2WeightRegularization',0.00000,...
    'SparsityRegularization',2, ...
    'SparsityProportion',0.20, ...
    'ScaleData',true);

%view(autoenc2); % to see the encoder structure

features2 = encode(autoenc2,features1);

hiddenSize3 = 7;
autoenc3 = trainAutoencoder(features2,hiddenSize3,...
    'EncoderTransferFunction','logsig', ...
    'DecoderTransferFunction','purelin', ...
    'L2WeightRegularization',0.00000,...
    'SparsityRegularization',2, ...
    'SparsityProportion',0.20, ...
    'ScaleData',true);

%view(autoenc3); % to see the encoder structure

features3 = encode(autoenc3,features2);

hiddenSize4 = N_myFactors;
autoenc4 = trainAutoencoder(features3,hiddenSize4,...
    'EncoderTransferFunction','logsig', ...
    'DecoderTransferFunction','purelin', ...
    'L2WeightRegularization',0.00000,...
    'SparsityRegularization',2, ...
    'SparsityProportion',0.20, ...
    'ScaleData',true);

%view(autoenc4); % to see the encoder structure

stackednet = stack(autoenc1,autoenc2,autoenc3,autoenc4);

%view(stackednet); % to see the encoder structure

%% Build the net
clear net net1

net = network(stackednet);
net.divideFcn = 'dividerand'; %  % Divide data randomly
net.divideMode = 'sample';  % Divide up every sample
% training, validation and test set proportions
net.divideParam.trainRatio = 70/100;
net.divideParam.valRatio = 15/100;
net.divideParam.testRatio = 15/100;
% net.performParam.normalization = 'standard';

% Plot Functions (see help nnplot)
net.plotFcns = {'plotperform','plottrainstate','ploterrhist', ...
    'plotregression', 'plotfit'};

targets = X(1:N_myFactors,:); % in application inputs and targets are the same

net1 = configure(net,[X;X.^2],targets); % to properly set inputs/outputs dimesions (based on X and targets)
% net1.IW = net.IW;
% net1.LW = net.LW;
% net1.b = net.b;

net1.trainParam.epochs = 5000;
net1.trainParam.max_fail = 8;
net1.trainParam.showWindow = false(1);

net1.layers{1}.transferFcn = 'logsig'; % 'radbas'; %
net1.layers{2}.transferFcn = 'logsig'; % 'radbas'; %
net1.layers{3}.transferFcn = 'purelin'; % 'radbas'; %
net1.layers{4}.transferFcn = 'purelin'; % 'radbas'; %

nntraintool
[net1,tr] = train(net1,[X;X.^2],targets);
% nntraintool('close');


%% Test the Network
X_hat_2 = net1([X;X.^2]);
% Y_hat = sim(net1,X);
e = gsubtract(targets,X_hat_2);
perf = perform(net1,X_hat_2,targets); % assess performance
% Training, Validation and Test sets Performance
trainTargets = targets .* tr.trainMask{1};
valTargets = targets .* tr.valMask{1};
testTargets = targets .* tr.testMask{1};
trainPerformance = perform(net1,trainTargets,X_hat_2)
trainPerformanceInSample = perform(net1,trainTargets,X_hat_2)
trainPerformanceTest = perform(net1,testTargets,X_hat_2)

valPerformance = perform(net1,valTargets,X_hat_2)
testPerformance = perform(net1,testTargets,X_hat_2)

% View the Network
view(net)

% Plots
figure, plotperform(tr)
figure, plottrainstate(tr)
figure, ploterrhist(e)
figure, plotregression(targets,X_hat_2)


figure;
subplot(3,3,1);
for k=1:N_myFactors
    subplot(3,3,k);
    plot(X(k,:),'b')
    hold on
    grid on
    plot(X_hat_2(k,:),'g')
end
