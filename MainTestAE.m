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
load([datapath,'DAA_paramsTest'])
DAA_params.StartDay = '5/2/2018';
load([datapath,'UniverseTest']);
AssetLegend = Universe_1.AllInvariants.NamesSet;
save([datapath,'AssetLegend'])

for ii = 1:1
    AEparams.HiddenSize = 5;
    AEparams.N_myFactors = numel(AssetLegend); % number of real factors to be modelled (must be the first n of the data set)
    AEparams.EncoderTransferFunction = 'logsig'; %  'radbas'; %
    AEparams.DecoderTransferFunction = 'purelin';
    AEparams.MaxEpoch = 2500;
    AEparams.ScaleData = true;
    AEparams.divideFcn = 'dividerand'; % Divide data randomly
    AEparams.divideMode = 'time'; % 'sample';
    AEparams.divideParam.trainRatio = 70/100;
    AEparams.divideParam.valRatio = 15/100;
    AEparams.divideParam.testRatio = 15/100;
    AEparams.Delays = [0 1 2 10];
    AEparams.LossFcn = 'mse'; % 'msesparse'; % Loss function used to train the net
    AEparams.trainFcn = 'trainlm'; % use with mse
    % v.trainFcn = 'trainscg'; % use with msesparse
    
    DAA_params.AEparams = AEparams;
    
    %DAA_params.ARMAGARCH = 0;
    DAA_params.UseAutoEncoder = true;
    Universe_1.Dynamic_AA_1(DAA_params,[]);
    
    Universe_1.Debug.AE.WITH.AEparams= AEparams;
    AEdataWITH(ii) = Universe_1.Debug.AE.WITH;
  
    
end

save([datapath,'AEdataWITH_1'],'AEdataWITH','-v7.3');

DAA_params.ARMAGARCH = 1;
DAA_params.UseAutoEncoder = false;
Universe_1.Dynamic_AA_1(DAA_params,[]);

AEdataWITHOUT = Universe_1.Debug.AE.WITHOUT;

save([datapath,'AEdataWITHOUT_1'],'AEdataWITHOUT','-v7.3');

