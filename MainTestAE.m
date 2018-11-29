clc
close all
clear all

userId = getenv('USERNAME');

addpath(['C:\Users\' userId '\Documents\GitHub\Utilities\'], ...
    ['C:\Users\' userId '\Documents\GitHub\AA_Project\Cointegration\EngleGranger\'], ...
    ['C:\Users\' userId '\Documents\GitHub\Utilities\RatesUtilities\'], ...
    ['C:\Users\' userId '\Documents\GitHub\Utilities\Mds\'], ...
    ['C:\Users\' userId '\Documents\GitHub\Utilities\Pca\'], ...
    ['C:\Users\' userId '\Documents\GitHub\Utilities\Regressions\'], ...
    ['C:\Users\' userId '\Documents\GitHub\AA_Project\AssetAllocation\SwapClass\'], ...
    ['C:\Users\' userId '\Documents\GitHub\AA_Project\AssetAllocation\FigExport\'], ...
    ['C:\Users\' userId '\Documents\GitHub\ReportsMgmt']);

datapath = 'C:\Program Files\MATLAB\R2018a\work\IMI\AutoEncoderData\';

import InvestmentUniverse.*;
load([datapath,'DAA_paramsSmall'])
DAA_params.StartDay = '1/2/2018';
load([datapath,'UniverseSmall']);
AssetLegend = Universe_1.AllInvariants.NamesSet;
save([datapath,'AssetLegend',datestr(date,'yyyymmdd')]);

%% getting some 'names' needed for output purposes

DAA_params.RiskBudgeting = false(1);  
DAA_params.riskAnalysisFlag = 0;

% BackTest outputs to Excel
if DAA_params.QuantSignals
    qS_string = ' - with Algo Signals';
else
    if DAA_params.RiskBudgeting == 1
        optimSpace = ['Risk Budgeting'];
    else
        if DAA_params.ExpectedShortfall_EF == 1
            optimSpace = ['ES/Return space'];
        else
            optimSpace = ['Variance/Return space'];
        end
    end
end

numtest = 2;

for ii = 1:numtest
    
    
    if ii == 1
        DAA_params.AEafterResampling =  false(1);
    else
        DAA_params.AEafterResampling = true(1);
    end
    
    AEparams.HiddenSize = 5;
    AEparams.N_myFactors = numel(AssetLegend); % number of real factors to be modelled (must be the first n of the data set)
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
    
    DAA_params.AEparams = AEparams;
    
    DAA_params.ARMAGARCH = 0;
    DAA_params.Priori_MovWin = 400;
    %DAA_params.MinFreqOfPriorUpdate = 10;   
    
    DAA_params.UseAutoEncoder = true;
    Universe_1.Dynamic_AA_1(DAA_params,[]);
    
    Universe_1.Debug.AE.WITH.AEparams= AEparams;
    AEdataWITH(ii) = Universe_1.Debug.AE.WITH;
    
    close all
    import OutputsMgmt.*;
    
    BT_params.targetType =  'level';
    % BT_params.target =  [0.0 inf];
    BT_params.target =  [0.002 0.004];
    
    BT_params.targetName = ['Risk']; % ['ExpectedReturn']; % 
    BT_params.FixRebalThreshold = Inf; %0.10; % size of the outbalance for a single asset to be considered for the purpose of rebalancing
    BT_params.FixedRebalCost_pct = 0.00001; % fixed % rebal cost0
    BT_params.MinOutW_Assets = 10; % min no of assets that need to be rebalanced
    BT_params.VolaAndES_window = 100; % rolling window used to compute moving std and ES for the portfolio equity line
    Universe_1.AA_BackTest(['Dynamic_AA_1'],BT_params);
    
    % BackTest outputs to Excel
    if DAA_params.QuantSignals
        qS_string = ' - with Algo Signals';
    else
        qS_string = '';
    end
    
    Label4Output = [DAA_params.SetUpName,' in ',optimSpace,' Target: ',BT_params.targetName,' Hiddensize=',num2str(AEparams.HiddenSize),' - selected range = ',num2str(BT_params.target(1)*100),'% - ',num2str(BT_params.target(2)*100),'%'];
    
    clear outputs;
    
    outputs = AA_Outputs(Universe_1,BT_params,['Dynamic_AA_1']);
    outputs.GetAllocationsHistory;
    outputs.GetReturnAndRiskMetrics(10);
    
    reportFileName = [DAA_params.SetUpName,'_AE_',datestr(date,'yyyymmdd')];
    
    outputs.ExcelOutput('Report1',reportFileName,Label4Output,DAA_params.ReportDir);
    
    close all
end % for

save([datapath,'AEdataWITH',datestr(date,'yyyymmdd')],'AEdataWITH','-v7.3');

%%

DAA_params.ARMAGARCH = 1;
DAA_params.UseAutoEncoder = false;
Universe_1.Dynamic_AA_1(DAA_params,[]);

AEdataWITHOUT = Universe_1.Debug.AE.WITHOUT;

save([datapath,'AEdataWITHOUT',datestr(date,'yyyymmdd')],'AEdataWITHOUT','-v7.3');

Universe_1.AA_BackTest(['Dynamic_AA_1'],BT_params);

if strcmp(BT_params.targetType,'level')
    Label4Output = [DAA_params.SetUpName,' in ',optimSpace,' Target: ',BT_params.targetName,' - selected range = ',num2str(BT_params.target(1)*100),'% - ',num2str(BT_params.target(2)*100),'%'];
elseif strcmp(BT_params.targetType,'quantile')
    Label4Output = [DAA_params.SetUpName,' in ',optimSpace,' Target (BASED ON FIXED SELECTED QUANTILE): selected measure: ',BT_params.targetName,' - selected quantile = ',num2str(BT_params.target(1)),'%'];
end

clear outputs;
outputs = AA_Outputs(Universe_1,BT_params,['Dynamic_AA_1']);
outputs.GetAllocationsHistory;
outputs.GetReturnAndRiskMetrics(10);

reportFileName = [DAA_params.SetUpName,'_AE_',datestr(date,'yyyymmdd')];

outputs.ExcelOutput('Report1',reportFileName,Label4Output,DAA_params.ReportDir);

close all    
    
    