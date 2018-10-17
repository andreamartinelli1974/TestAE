function param = getParam4ChartAndTable(R)

% This method allows to get variables need to plot Charts and to create Table
% Input:
% --> R: RiskAnalytics object
% Output:
% param: chart and table parameters

% VaR and ES confidence level used within charts
confLevel_idx = R.confLevelUsed4xlsOutput_idx;
confLevel = R.confLevelUsed4xlsOutput;

% Scenario Label
param.Label = R.ScenarioLabel;
% Reference Date
param.ReferenceDate = datestr(R.Date);

% TARGET PORTFOLIO
% Targets based on the chosen risk level
param.mnp_i_prior = R.SelectedPointOnEF.PortNoPrior;
param.mnp_i_post  = R.SelectedPointOnEF.PortNoPosterior;
% Target Risk - Prior and Posterior
param.TargetedRisk_Prior     = R.SelectedPointOnEF.TargetedRisk_Prior;
param.TargetedRisk_Posterior = R.SelectedPointOnEF.TargetedRisk_Posterior;
% Target Return - Prior and Posterior
param.TargetedReturn_Prior     = R.SelectedPointOnEF.TargetedReturn_Prior;
param.TargetedReturn_Posterior = R.SelectedPointOnEF.TargetedReturn_Posterior;
% Title Label for Charts
param.titChunk1  = [param.Label.universeName,' optimal AA as of ',param.ReferenceDate];
param.titChunk2  = ['PRIOR ---> Target Risk: ',num2str(param.TargetedRisk_Prior,'%.2f'), ...
    '%  -  Target Return: ',num2str(param.TargetedReturn_Prior,'%.2f'),'%'];
param.titChunk3  = ['POSTERIOR ---> Target Risk (closest): ',num2str(param.TargetedRisk_Posterior,'%.2f'), ...
    '%  -  Target Return: ',num2str(param.TargetedReturn_Posterior,'%.2f'),'%'];
% Target Level
targetLabel = {'Selected Risk Target','Prior Risk Target','Posterior Risk Target'}';
targetValue = {R.SelectedPointOnEF.riskLevel./100, R.SelectedPointOnEF.TargetedRisk_Prior./100, R.SelectedPointOnEF.TargetedRisk_Posterior./100}'; % TODO: ADD SELECTED RISK LEVEL
param.TargetTable = table(targetLabel, targetValue, 'VariableNames',{'RiskName', 'RiskLevel'});

% CURRENT WEIGHTS
boolPos = (R.ActiveAssets==1);
% Current %
param.CurrentWeights = R.CurrentWgts(1, boolPos)';
% Current $
param.CurrentWeights_Mon = R.CurrentWgts(1, boolPos)'.*R.Budget;
% Current % abs
param.CurrentWeights_Abs = abs(R.CurrentWgts(1, boolPos)');
% Current $ abs
param.CurrentWeights_Mon_Abs = abs(param.CurrentWeights.* R.Budget);

% PRIOR WEIGHTS
% Prior %
param.selectedAA_priorPer = R.Output.Allocations.PriorProb.Weights(:,param.mnp_i_prior);
% Prior $
param.selectedAA_prior_Mon = R.Output.Allocations.PriorProb.Weights(:,param.mnp_i_prior).* R.Budget;
% Prior % abs
param.selectedAA_prior_Abs_Per = abs(R.Output.Allocations.PriorProb.Weights(:,param.mnp_i_prior));
% Prior $ abs
param.selectedAA_prior_Abs_Mon = abs(R.Output.Allocations.PriorProb.Weights(:,param.mnp_i_prior).* R.Budget);

% POSTERIOR WEIGHTS
% Posterior %
param.selectedAA_posteriorPer = R.Output.Allocations.PosteriorProb.Weights(:,param.mnp_i_post);
% Posterior $
param.selectedAA_posterior_Mon = R.Output.Allocations.PosteriorProb.Weights(:,param.mnp_i_post).* R.Budget;
% Posterior % abs
param.selectedAA_posterior_Abs_Per = abs(R.Output.Allocations.PosteriorProb.Weights(:,param.mnp_i_post));
% Posterior $ abs
param.selectedAA_posterior_Abs_Mon = abs(R.Output.Allocations.PosteriorProb.Weights(:,param.mnp_i_post).* R.Budget);

% RISK MEASURES
% Current/Prior/Posterior Portfolio VaR/ES/Ret (portfolio selection on the eff frontier)
% VaR
param.selectedVaR_prior_curr         = R.Output.PortfolioRiskMeasures.CurrentPtf.Simulation.PriorProb.AtHorizon.PtfLevel.VaR(confLevel_idx);
param.selectedVaR_post_curr          = R.Output.PortfolioRiskMeasures.CurrentPtf.Simulation.PosteriorProb.AtHorizon.PtfLevel.VaR(1,confLevel_idx);
param.selectedVaR_prior              = R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.PriorProb.AtHorizon.PtfLevel.VaR(param.mnp_i_prior);
param.selectedVaR_prior_WithPostProb = R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.PosteriorProb.AtHorizon.PtfLevel.VaR(param.mnp_i_prior);
param.selectedVaR_posterior              = R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.PriorProb.AtHorizon.PtfLevel.VaR(param.mnp_i_post);
param.selectedVaR_posterior_WithPostProb = R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.PosteriorProb.AtHorizon.PtfLevel.VaR(param.mnp_i_post);
% ES
param.selectedES_prior_curr         = R.Output.PortfolioRiskMeasures.CurrentPtf.Simulation.PriorProb.AtHorizon.PtfLevel.ES(confLevel_idx);
param.selectedES_post_curr          = R.Output.PortfolioRiskMeasures.CurrentPtf.Simulation.PosteriorProb.AtHorizon.PtfLevel.ES(1,confLevel_idx);
param.selectedES_prior              = R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.PriorProb.AtHorizon.PtfLevel.ES(param.mnp_i_prior);
param.selectedES_prior_WithPostProb = R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.PosteriorProb.AtHorizon.PtfLevel.ES(param.mnp_i_prior);
param.selectedES_posterior          = R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.PriorProb.AtHorizon.PtfLevel.ES(param.mnp_i_post);
param.selectedES_posterior_WithPostProb = R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.PosteriorProb.AtHorizon.PtfLevel.ES(param.mnp_i_post);
% Ret
param.ProjReturn_Prior_curr      = R.Output.PortfolioReturnMeasures.CurrentPtf.Simulation.PriorProb.AtHorizon.PtfLevel.ProjReturn;
param.ProjReturn_post_curr       = R.Output.PortfolioReturnMeasures.CurrentPtf.Simulation.PosteriorProb.AtHorizon.PtfLevel.projReturn;
param.ProjReturn_Prior           = R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.PriorProb.AtHorizon.PtfLevel.ProjReturn(param.mnp_i_prior);
param.ProjReturn_PriorOnPostProb = R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.PosteriorProb.AtHorizon.PtfLevel.ProjReturn(param.mnp_i_prior);
param.ProjReturn_Posterior       = R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.PriorProb.AtHorizon.PtfLevel.ProjReturn(param.mnp_i_post);
param.ProjReturn_PosteriorOnPostProb =  R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.PosteriorProb.AtHorizon.PtfLevel.ProjReturn(param.mnp_i_post);
% Marginal VaR
%param.selectedMVaR_prior = R.Output.PortfolioRiskMeasures.MarginalVaR.priorProb(param.mnp_i_prior,:)';
%param.selectedMVaR_posterior = R.Output.PortfolioRiskMeasures.MarginalVaR.posteriorProb(param.mnp_i_post,:)';
% Marginal ES
%param.selectedMES_prior = R.Output.PortfolioRiskMeasures.MarginalES.priorProb(param.mnp_i_prior,:)';
%param.selectedMES_posterior = R.Output.PortfolioRiskMeasures.MarginalES.posteriorProb(param.mnp_i_post,:)';
% Projected Ret
%param.selectedRET_prior = R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.PriorProb.AtHorizon.AllAssets.ProjReturn;
param.selectedRET_prior     = R.Output.PortfolioReturnMeasures.CurrentPtf.Simulation.PriorProb.AtHorizon.AllAssets.ProjReturn;
param.selectedRET_posterior = R.Output.PortfolioReturnMeasures.CurrentPtf.Simulation.PosteriorProb.AtHorizon.AllAssets.projReturn;
% Market Ret
param.MarketRet = R.Output.PortfolioReturnMeasures.CurrentPtf.Simulation.PosteriorProb.AtHorizon.AllAssets.projReturn./ param.CurrentWeights;
% Historical Methodology
param.selectedVaR_prior_curr_Hist = R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.AtHorizon.PtfLevel.VaR(confLevel_idx);
param.selectedES_prior_curr_Hist  = R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.AtHorizon.PtfLevel.ES(confLevel_idx);
% Parametric Methodology
param.selectedVaR_prior_curr_Param = R.Output.PortfolioRiskMeasures.CurrentPtf.Parametric.HistScenariosProb.AtHorizon.PtfLevel.VaR(confLevel_idx);
param.selectedES_prior_curr_Param  = R.Output.PortfolioRiskMeasures.CurrentPtf.Parametric.HistScenariosProb.AtHorizon.PtfLevel.ES(confLevel_idx);

if  ~(sum(R.params_AA.MargRisk)==0) % if not all marginal risk flags are false
    % Marginal Risk Measures: asset class
    if R.params_AA.MargRisk(1)
        param.selectedMVaR_AssetClass_curr = R.Output.PortfolioRiskMeasures.CurrentPtf.Simulation.PriorProb.AtHorizon.PtfLevel.marginal_VaR{confLevel_idx,1}.assetClass.data(1,:)';
        param.selectedMVaR_AssetClass_prior = R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.PriorProb.AtHorizon.PtfLevel.marginal_VaR{confLevel_idx,1}.assetClass.data(param.mnp_i_prior,:)';
        param.selectedMVaR_AssetClass_posterior = R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.PriorProb.AtHorizon.PtfLevel.marginal_VaR{confLevel_idx,1}.assetClass.data(param.mnp_i_post,:)';
        param.selectedMVaR_AssetClass_Map = R.Output.PortfolioRiskMeasures.CurrentPtf.Simulation.PriorProb.AtHorizon.PtfLevel.marginal_VaR{confLevel_idx,1}.assetClass.typologyMap(1,:)';
        param.selectedMVaR_AssetClass_Table = table(cellstr(param.selectedMVaR_AssetClass_Map), param.selectedMVaR_AssetClass_curr, ...
            param.selectedMVaR_AssetClass_prior,param.selectedMVaR_AssetClass_posterior, ...
            'VariableNames',{'Asset_Class','Current_MVaR','Prior_MVaR','Posterior_MVaR'});
    end
    % Marginal Risk Measures: asset country
    if R.params_AA.MargRisk(2)
        param.selectedMVaR_AssetCtry_curr = R.Output.PortfolioRiskMeasures.CurrentPtf.Simulation.PriorProb.AtHorizon.PtfLevel.marginal_VaR{confLevel_idx,1}.assetCountry.data(1,:)';
        param.selectedMVaR_AssetCtry_prior = R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.PriorProb.AtHorizon.PtfLevel.marginal_VaR{confLevel_idx,1}.assetCountry.data(param.mnp_i_prior,:)';
        param.selectedMVaR_AssetCtry_posterior = R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.PriorProb.AtHorizon.PtfLevel.marginal_VaR{confLevel_idx,1}.assetCountry.data(param.mnp_i_post,:)';
        param.selectedMVaR_AssetCtry_Map = R.Output.PortfolioRiskMeasures.CurrentPtf.Simulation.PriorProb.AtHorizon.PtfLevel.marginal_VaR{confLevel_idx,1}.assetCountry.typologyMap(1,:)';
        param.selectedMVaR_AssetCtry_Table = table(cellstr(param.selectedMVaR_AssetCtry_Map), param.selectedMVaR_AssetCtry_curr, ...
            param.selectedMVaR_AssetCtry_prior,param.selectedMVaR_AssetCtry_posterior, ...
            'VariableNames',{'Asset_Ctry','Current_MVaR','Prior_MVaR','Posterior_MVaR'});
    end
    % Marginal Risk Measures: asset sector
    if R.params_AA.MargRisk(3)
        param.selectedMVaR_AssetSect_curr = R.Output.PortfolioRiskMeasures.CurrentPtf.Simulation.PriorProb.AtHorizon.PtfLevel.marginal_VaR{confLevel_idx,1}.assetSector.data(1,:)';
        param.selectedMVaR_AssetSect_prior = R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.PriorProb.AtHorizon.PtfLevel.marginal_VaR{confLevel_idx,1}.assetSector.data(param.mnp_i_prior,:)';
        param.selectedMVaR_AssetSect_posterior = R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.PriorProb.AtHorizon.PtfLevel.marginal_VaR{confLevel_idx,1}.assetSector.data(param.mnp_i_post,:)';
        param.selectedMVaR_AssetSect_Map = R.Output.PortfolioRiskMeasures.CurrentPtf.Simulation.PriorProb.AtHorizon.PtfLevel.marginal_VaR{confLevel_idx,1}.assetSector.typologyMap(1,:)';
        param.selectedMVaR_AssetSect_Table = table(cellstr(param.selectedMVaR_AssetSect_Map), param.selectedMVaR_AssetSect_curr, ...
            param.selectedMVaR_AssetSect_prior,param.selectedMVaR_AssetSect_posterior, ...
            'VariableNames',{'Asset_Sect','Current_MVaR','Prior_MVaR','Posterior_MVaR'});
    end
    
    % Marginal Risk Measures: all asset
    if R.params_AA.MargRisk(4)
        param.selectedMVaR_AssetAll_curr = R.Output.PortfolioRiskMeasures.CurrentPtf.Simulation.PriorProb.AtHorizon.PtfLevel.marginal_VaR{confLevel_idx,1}.allAsset.data(1,:)';
        param.selectedMVaR_AssetAll_prior = R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.PriorProb.AtHorizon.PtfLevel.marginal_VaR{confLevel_idx,1}.allAsset.data(param.mnp_i_prior,:)';
        param.selectedMVaR_AssetAll_posterior = R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.PriorProb.AtHorizon.PtfLevel.marginal_VaR{confLevel_idx,1}.allAsset.data(param.mnp_i_post,:)';
        param.selectedMVaR_AssetAll_Map = R.Output.PortfolioRiskMeasures.CurrentPtf.Simulation.PriorProb.AtHorizon.PtfLevel.marginal_VaR{confLevel_idx,1}.allAsset.typologyMap(1,:)';
        param.selectedMVaR_AssetAll_Table = table(cellstr(param.selectedMVaR_AssetAll_Map), param.selectedMVaR_AssetAll_curr, ...
            param.selectedMVaR_AssetAll_prior,param.selectedMVaR_AssetAll_posterior, ...
            'VariableNames',{'Asset_All','Current_MVaR','Prior_MVaR','Posterior_MVaR'});
    end
end

% ALL ASSETS WEIGHTS
bool1  = ~ismember(R.IU.InputParams.UniverseTable.Asset_ticker_BBG,R.IU.RemovedAssetLog);
bool2  = ~strcmp(R.IU.InputParams.UniverseTable.Asset_asset_type,'noPtf');
logAll = logical(bool1.*bool2);
allNames   = R.IU.InputParams.UniverseTable.Asset_ticker_BBG;
allWeights = R.IU.InputParams.UniverseTable.Asset_currentAA_optional;
param.allAssetsTable = table(allNames, logAll, allWeights, allWeights.*R.Budget, ...
    'VariableNames',{'Assets','Included_Assets','CurrentAA_Perc','CurrentAA_Mon'});

% ALLOCATIONS
param.allocations = R.Output.Allocations;
% Asset Names
param.AssetNames = param.allocations.AssetNames;
param.AssetNamesAdj = strrep(strrep(param.AssetNames,' ','_'),',','');
% Country, Sector, Sub-Sector
param.mapInfo = R.CountryStrategyInfo;
mapInfoAdj = cellfun(@(x) strrep(strrep(x(:,1),' ', '_'),',',''), param.mapInfo);
% boolId = ismember(mapInfoAdj(:,1), AssetNames);
[~,boolId] = ismember(param.AssetNames,mapInfoAdj(:,1));
param.AssetCountry   = mapInfoAdj(boolId,2);
param.AssetSector    = mapInfoAdj(boolId,3);
param.AssetSubSector = mapInfoAdj(boolId,4);
% Asset Class
param.AssetTypology = R.AssetType;
AssetTypology = table2cell(cell2table(param.AssetTypology));
param.AssetTypologyAdj = AssetTypology;
param.AssetTypologyAdj(:,1) = strrep(strrep(AssetTypology(:,1),' ','_'),',','');
% boolPosA = ismember(AssetTypologyAdj(:,1), AssetNames);
[~,boolPosA] = ismember(param.AssetNames,param.AssetTypologyAdj(:,1));
param.AssetClass = param.AssetTypologyAdj(boolPosA,2);
% Allocation Table
param.allocTable = table(param.AssetNamesAdj, ...
    param.AssetCountry, param.AssetSector, param.AssetSubSector, param.AssetClass, ...
    param.CurrentWeights, param.selectedAA_priorPer, param.selectedAA_posteriorPer, ...
    param.CurrentWeights_Mon, param.selectedAA_prior_Mon, param.selectedAA_posterior_Mon, ...
    param.CurrentWeights_Abs , param.selectedAA_prior_Abs_Per, param.selectedAA_posterior_Abs_Per, ...
    param.CurrentWeights_Mon_Abs, param.selectedAA_prior_Abs_Mon, param.selectedAA_posterior_Abs_Mon, ...
    'VariableNames',{'Assets', ...
    'Country','Sector','SubSector','AssetClass', ...
    'CurrentAA','PriorAA','PosteriorAA',...
    'CurrentAA_mon','PriorAA_mon','PosteriorAA_mon',...
    'CurrentAA_abs','PriorAA_abs','PosteriorAA_abs', ...
    'CurrentAA_mon_abs','PriorAA_mon_abs','PosteriorAA_mon_abs'});
% Diff %
param.allocTable.Diff1 = (param.allocTable.PosteriorAA - param.allocTable.CurrentAA);
param.allocTable.Diff2 = (param.allocTable.PosteriorAA - param.allocTable.PriorAA);
% Diff $
param.allocTable.Diff1_mon = (param.allocTable.PosteriorAA_mon - param.allocTable.CurrentAA_mon);
param.allocTable.Diff2_mon = (param.allocTable.PosteriorAA_mon - param.allocTable.PriorAA_mon);
% Diff % abs
param.allocTable.Diff1_abs = (param.allocTable.PosteriorAA_abs - param.allocTable.CurrentAA_abs);
param.allocTable.Diff2_abs = (param.allocTable.PosteriorAA_abs - param.allocTable.PriorAA_abs);
% Diff $ abs
param.allocTable.Diff1_mon_abs = (param.allocTable.PosteriorAA_mon_abs - param.allocTable.CurrentAA_mon_abs);
param.allocTable.Diff2_mon_abs = (param.allocTable.PosteriorAA_mon_abs - param.allocTable.PriorAA_mon_abs);
% Allocation Country
param.allocTable_Country = varfun(@sum, param.allocTable, 'GroupingVariables',{'Country'}, 'InputVariables', ...
    {'CurrentAA','PriorAA','PosteriorAA', 'Diff1', 'Diff2', ...
    'CurrentAA_mon','PriorAA_mon','PosteriorAA_mon', 'Diff1_mon', 'Diff2_mon',...
    'CurrentAA_abs','PriorAA_abs','PosteriorAA_abs', 'Diff1_abs', 'Diff2_abs',...
    'CurrentAA_mon_abs','PriorAA_mon_abs','PosteriorAA_mon_abs', 'Diff1_mon_abs', 'Diff2_mon_abs',});
param.allocTable_Country.GroupCount = [];
param.allocTable_Country.Properties.VariableNames = strrep(param.allocTable_Country.Properties.VariableNames, 'sum_', '');
% Allocation Sector
param.allocTable_Sector = varfun(@sum, param.allocTable, 'GroupingVariables',{'Sector'},'InputVariables', ...
    {'CurrentAA','PriorAA','PosteriorAA', 'Diff1', 'Diff2', ...
    'CurrentAA_mon','PriorAA_mon','PosteriorAA_mon', 'Diff1_mon', 'Diff2_mon',...
    'CurrentAA_abs','PriorAA_abs','PosteriorAA_abs', 'Diff1_abs', 'Diff2_abs',...
    'CurrentAA_mon_abs','PriorAA_mon_abs','PosteriorAA_mon_abs', 'Diff1_mon_abs', 'Diff2_mon_abs',});
param.allocTable_Sector.GroupCount = [];
param.allocTable_Sector.Properties.VariableNames = strrep(param.allocTable_Sector.Properties.VariableNames, 'sum_', '');
% Allocation SubSector
param.allocTable_SubSector = varfun(@sum, param.allocTable, 'GroupingVariables',{'SubSector'},'InputVariables', ...
    {'CurrentAA','PriorAA','PosteriorAA', 'Diff1', 'Diff2', ...
    'CurrentAA_mon','PriorAA_mon','PosteriorAA_mon', 'Diff1_mon', 'Diff2_mon',...
    'CurrentAA_abs','PriorAA_abs','PosteriorAA_abs', 'Diff1_abs', 'Diff2_abs',...
    'CurrentAA_mon_abs','PriorAA_mon_abs','PosteriorAA_mon_abs', 'Diff1_mon_abs', 'Diff2_mon_abs',});
param.allocTable_SubSector.GroupCount = [];
param.allocTable_SubSector.Properties.VariableNames = strrep(param.allocTable_SubSector.Properties.VariableNames, 'sum_', '');
% Allocation Class
param.allocTable_Class = varfun(@sum, param.allocTable, 'GroupingVariables',{'AssetClass'},'InputVariables', ...
    {'CurrentAA','PriorAA','PosteriorAA', 'Diff1', 'Diff2', ...
    'CurrentAA_mon','PriorAA_mon','PosteriorAA_mon', 'Diff1_mon', 'Diff2_mon',...
    'CurrentAA_abs','PriorAA_abs','PosteriorAA_abs', 'Diff1_abs', 'Diff2_abs',...
    'CurrentAA_mon_abs','PriorAA_mon_abs','PosteriorAA_mon_abs', 'Diff1_mon_abs', 'Diff2_mon_abs',});
param.allocTable_Class.GroupCount = [];
param.allocTable_Class.Properties.VariableNames = strrep(param.allocTable_Class.Properties.VariableNames, 'sum_', '');

% Risk Measure Breakdown
if R.params_AA.MargRisk(4)
    param.selectedMVaR_Diff = param.selectedMVaR_AssetAll_posterior - param.selectedMVaR_AssetAll_prior;
    param.selectedRET_Diff = param.selectedRET_posterior - param.selectedRET_prior;
    param.measureTable = table(param.AssetNamesAdj, ...
        param.selectedMVaR_AssetAll_prior,param.selectedMVaR_AssetAll_posterior, param.selectedMVaR_Diff,...
        param.selectedRET_prior,param.selectedRET_posterior, param.selectedRET_Diff,...
        param.MarketRet,...
        'VariableNames',{'Assets', ...
        'Prior_MVaR','Posterior_MVaR','Differences_MVaR', ...
        'Prior_Wgt_RET','Posterior_Wgt_RET','Differences_RET',...
        'MarketUnwgt_Posterior_RET'});
end
end