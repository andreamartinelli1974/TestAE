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

%% creates the net

X = Invariants.data'; % U2.Output.CleanPrices(:,2:end)'; %
X2 = X.^2;
NetInputs = size(X,1);
targets = X(1:N_myFactors,:);
delays = [1,5,8];

clear mynet

mynet = network(1,6);

mynet.input.size = NetInputs*2;
mynet.layers{1}.size = 30;
mynet.layers{2}.size = 7;
mynet.layers{3}.size = 5;
mynet.layers{4}.size = 7;
mynet.layers{5}.size = 30;
mynet.layers{6}.size = N_myFactors;
mynet.biasConnect = true(6,1);

mynet.inputConnect(1,:) = 1;
mynet.outputConnect(6)= 1;
for i = 1:5
    mynet.layerConnect(i+1,i) = 1;
end
mynet.layerConnect(5,5) = 1;

mynet.layers{1}.transferFcn = 'logsig';
mynet.layers{2}.transferFcn = 'logsig';
mynet.layers{3}.transferFcn = 'logsig';
mynet.layers{4}.transferFcn = 'logsig';
mynet.layers{5}.transferFcn = 'logsig';

mynet.inputWeights{1,1}.delays = delays;
mynet.layerWeights{5,4}.delays = delays;
mynet.layerWeights{5,5}.delays = delays;

view(mynet);

for i=1:6
    mynet.layers{i}.initFcn = 'initwb';
end

mynet.divideFcn = 'dividerand'; % Divide data randomly
mynet.divideMode = 'time'; % 'sample';
mynet.divideParam.trainRatio = 70/100;
mynet.divideParam.valRatio = 15/100;
mynet.divideParam.testRatio = 15/100;
mynet.performFcn = 'sse'; % 'mse' % 'msesparse'; % Loss function used to train the net
mynet.trainFcn = 'trainrp'; % use with mse


mynet = configure(mynet,[X;X2],targets);
iwsize = size(mynet.iw{1,1});
mynet.iw{1,1}=rand(iwsize);
for i = 1:6
    sizeb=size(mynet.b{i});
    mynet.b{i}=rand(sizeb);
end
lwsize = numel(mynet.LW);
for i = 1:lwsize
    sizelw=size(mynet.LW{i});
    if sizelw(1)>0
        mynet.LW{i}=rand(sizelw);
    end
end


nntraintool
mynet.trainParam.min_grad = 1e-15;
mynet.trainParam.epochs = 2500;
mynet.trainOptions.ScaleData = true
[mynet1,tr] = train(mynet,[X;X2],targets);



%% Test the Network
X_hat_2 = mynet1([X;X2]);
% Y_hat = sim(net1,X);
e = gsubtract(targets,X_hat_2);
perf = perform(mynet1,X_hat_2,targets); % assess performance
% Training, Validation and Test sets Performance
trainTargets = targets .* tr.trainMask{1};
valTargets = targets .* tr.valMask{1};
testTargets = targets .* tr.testMask{1};
trainPerformance = perform(mynet1,trainTargets,X_hat_2)
trainPerformanceInSample = perform(mynet1,trainTargets,X_hat_2)
trainPerformanceTest = perform(mynet1,testTargets,X_hat_2)

valPerformance = perform(mynet1,valTargets,X_hat_2)
testPerformance = perform(mynet1,testTargets,X_hat_2)

% View the Network
view(mynet1)

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




