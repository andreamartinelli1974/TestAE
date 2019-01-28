%%%%%  THIS IS THE PLAIN VANILLA TESTER FOR THE AutoEncoder_DR CLASS  %%%%%
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


%% GET THE DATA FROM BBG & SET THE UNIVERSE

% BBG tickers
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
IU.ticker{35,1} = ['ITRX XOVER CDSI GEN 5Y Corp']; 


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

%% CREATES THE AUTOENCODER OBJECT

TrainigSet = Invariants.data'; % U2.Output.CleanPrices(:,2:end)'; %

InputParams.HiddenSize = 5;
InputParams.N_myFactors = 8; % number of real factors to be modelled (must be the first n of the data set)
InputParams.EncoderTransferFunction = 'logsig'; %  'radbas'; %
InputParams.DecoderTransferFunction = 'purelin';
InputParams.MaxEpoch = 2500;
InputParams.ScaleData = true;
InputParams.divideFcn = 'dividerand'; % Divide data randomly
InputParams.divideMode = 'time'; % 'sample';
InputParams.divideParam.trainRatio = 70/100;
InputParams.divideParam.valRatio = 15/100;
InputParams.divideParam.testRatio = 15/100;
InputParams.Delays = [0 1 2 10];
InputParams.LossFcn = 'mse'; % 'msesparse'; % Loss function used to train the net 
InputParams.trainFcn = 'trainlm'; % use with mse
% InputParams.trainFcn = 'trainscg'; % use with msesparse

AutoEncoder = AutoEncoder_DR(TrainigSet, InputParams);

AutoEncoder.parametersSpotCheck;

AutoEncoder.SetNet;

features = AutoEncoder.EncDecFunction(TrainigSet,'encode');
x_pred = AutoEncoder.EncDecFunction(features,'decode');

highestDelay = InputParams.Delays(end); 

InputParams.Delays = [];
InputParams.LossFcn =  'msesparse'; % Loss function used to train the net 
InputParams.trainFcn = 'trainscg'; % use with msesparse

AutoEncoder2 = AutoEncoder_DR(TrainigSet, InputParams);

AutoEncoder2.parametersSpotCheck;

AutoEncoder2.SetNet;

features2 = AutoEncoder2.EncDecFunction(TrainigSet,'encode');
x_pred2 = AutoEncoder2.EncDecFunction(features,'decode');

%%
close all

% data plot
figure('Name','With Delay');
subplot(3,3,1);
for k=1:InputParams.N_myFactors
    subplot(3,3,k);
    plot(TrainigSet(k,highestDelay:end),'b')
    hold on
    grid on
    plot(x_pred(k,:),'g')
end

% cumulated returns (using exp() since log returns have been modeled)
figure('Name','With Delay');
subplot(3,3,1);
for k=1:InputParams.N_myFactors
    subplot(3,3,k);
    plot(exp(cumsum(TrainigSet(k,highestDelay:end))),'b')
    hold on
    grid on
    plot(exp(cumsum(x_pred(k,:))),'g')
end

figure('Name','Without Delay');
subplot(3,3,1);
for k=1:InputParams.N_myFactors
    subplot(3,3,k);
    plot(TrainigSet(k,:),'b')
    hold on
    grid on
    plot(x_pred2(k,:),'g')
end

figure('Name','Without Delay');
subplot(3,3,1);
for k=1:InputParams.N_myFactors
    subplot(3,3,k);
    plot(exp(cumsum(TrainigSet(k,:))),'b')
    hold on
    grid on
    plot(exp(cumsum(x_pred(k,:))),'g')
end


