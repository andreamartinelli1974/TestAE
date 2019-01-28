function ChartPriorPosteriorOutputs(R,chartName)
% This method produces some charts than can be used to print
% out the output to the screen
% INPUTs:
% -> chartName: if empty all the output charts will be plotted,
%    otherwise only the one corresponding to chartName will be plotted

otherParam = getParam4ChartAndTable(R);

% ALLOCATION SA
% Chart with only 'Current AA' in percentage
if strcmp(chartName,'AllocationsSA') || isempty(chartName)
    
    % Chart
    vector4BarChart   = [otherParam.allocTable.CurrentAA.*100];
    titParam.name     = {[otherParam.Label.universeName,' Analysis as of ',otherParam.ReferenceDate]};
    xParam.axisLabels = otherParam.allocTable.Assets;
    yParam.axisLabels = '% Allocations';
    legParam.title    = 'Current AA';
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% ALLOCATION SA MONETARY
% Chart with only 'Current AA' monetary
if strcmp(chartName,'AllocationsSAmon') || isempty(chartName)
    
    % Chart
    vector4BarChart   = [otherParam.allocTable.CurrentAA_mon];
    titParam.name     = {[otherParam.Label.universeName,' Analysis as of ',otherParam.ReferenceDate]};
    xParam.axisLabels = otherParam.allocTable.Assets;
    yParam.axisLabels = '$ Allocations';
    legParam.title    = 'Current AA';
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% ALLOCATION SA (COUNTRY)
% Chart with only 'Current AA' percentage
if strcmp(chartName,'AllocationsSAcountry') || isempty(chartName)
    
    % Chart
    vector4BarChart   = [otherParam.allocTable_Country.CurrentAA.*100];
    titParam.name     = {[otherParam.Label.universeName,' Analysis as of ',otherParam.ReferenceDate]};
    xParam.axisLabels = otherParam.allocTable_Country.Country;
    yParam.axisLabels = '% Country Allocations';
    legParam.title    = 'Current AA';
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% ALLOCATION SA (SECTOR)
% Chart with only 'Current AA' percentage
if strcmp(chartName,'AllocationsSAsector') || isempty(chartName)
    
    % Chart
    vector4BarChart   = [otherParam.allocTable_Sector.CurrentAA.*100];
    titParam.name     = {[otherParam.Label.universeName,' Analysis as of ',otherParam.ReferenceDate]};
    xParam.axisLabels = otherParam.allocTable_Sector.Sector;
    yParam.axisLabels = '% Sector Allocations';
    legParam.title    = 'Current AA';
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end


% ALLOCATION SA AGGREGATED (ASSET CLASS)
% Chart with only 'Current AA' in percentage
if strcmp(chartName,'AllocationsSAaggr') || isempty(chartName)
    
    % Chart
    vector4BarChart   = [otherParam.allocTable_Class.CurrentAA.*100];
    titParam.name     = {[otherParam.Label.universeName,' Analysis as of ',otherParam.ReferenceDate]};
    xParam.axisLabels = otherParam.allocTable_Class.AssetClass;
    yParam.axisLabels = '% Aggregate Allocations';
    legParam.title    = 'Current AA';
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% ALLOCATION SA MONETARY AGGREGATED (ASSET CLASS)
% Chart with only 'Current AA' monetary
if strcmp(chartName,'AllocationsSAmonAggr') || isempty(chartName)
    
    % Chart
    vector4BarChart   = [otherParam.allocTable_Class.CurrentAA_mon];
    titParam.name     = {[otherParam.Label.universeName,' Analysis as of ',otherParam.ReferenceDate]};
    xParam.axisLabels = otherParam.allocTable_Class.AssetClass;
    yParam.axisLabels = '$ Aggregate Allocations';
    legParam.title    = 'Current AA';
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% ALLOCATION MODEL PTF
% Chart with 'Current AA','Prior AA' and 'Posterior AA' in percentage
if strcmp(chartName,'AllocationsMP') || isempty(chartName)
    
    % Chart
    vector4BarChart   = [otherParam.allocTable.CurrentAA.*100, otherParam.allocTable.PriorAA.*100, otherParam.allocTable.PosteriorAA.*100];
    titParam.name     = {otherParam.titChunk1; otherParam.titChunk2; otherParam.titChunk3};
    xParam.axisLabels = otherParam.allocTable.Assets;
    yParam.axisLabels = '% Allocations';
    legParam.title    = {'Current AA','Prior AA','Posterior AA'};
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% ALLOCATION MODEL PTF AGGREGATED (ASSET CLASS)
% Chart with 'Current AA','Prior AA' and 'Posterior AA' in percentage
if strcmp(chartName,'AllocationsMPaggr') || isempty(chartName)
    
    % Chart
    vector4BarChart   = [otherParam.allocTable_Class.CurrentAA.*100, otherParam.allocTable_Class.PriorAA.*100, otherParam.allocTable_Class.PosteriorAA.*100];
    titParam.name     = {otherParam.titChunk1; otherParam.titChunk2; otherParam.titChunk3};
    xParam.axisLabels = otherParam.allocTable_Class.AssetClass;
    yParam.axisLabels = '% Allocations';
    legParam.title    = {'Current AA','Prior AA','Posterior AA'};
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% ALLOCATION MODEL PTF (COUNTRY)
% Chart with 'Current AA','Prior AA' and 'Posterior AA' in percentage
if strcmp(chartName,'AllocationsMPcountry') || isempty(chartName)
    
    % Chart
    vector4BarChart   = [otherParam.allocTable_Country.CurrentAA.*100, otherParam.allocTable_Country.PriorAA.*100, otherParam.allocTable_Country.PosteriorAA.*100];
    titParam.name     = {otherParam.titChunk1; otherParam.titChunk2; otherParam.titChunk3};
    xParam.axisLabels = otherParam.allocTable_Country.Country;
    yParam.axisLabels = '% Allocations';
    legParam.title    = {'Current AA','Prior AA','Posterior AA'};
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% ALLOCATION MODEL PTF (SECTOR)
% Chart with 'Current AA','Prior AA' and 'Posterior AA' in percentage
if strcmp(chartName,'AllocationsMPsector') || isempty(chartName)
    
    % Chart
    vector4BarChart   = [otherParam.allocTable_Sector.CurrentAA.*100, otherParam.allocTable_Sector.PriorAA.*100, otherParam.allocTable_Sector.PosteriorAA.*100];
    titParam.name     = {otherParam.titChunk1; otherParam.titChunk2; otherParam.titChunk3};
    xParam.axisLabels = otherParam.allocTable_Sector.Sector;
    yParam.axisLabels = '% Allocations';
    legParam.title    = {'Current AA','Prior AA','Posterior AA'};
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% ALLOCATION MODEL PTF (SUB SECTOR)
% Chart with 'Current AA','Prior AA' and 'Posterior AA' in percentage
if strcmp(chartName,'AllocationsMPsubsector') || isempty(chartName)
    
    % Chart
    vector4BarChart   = [otherParam.allocTable_SubSector.CurrentAA.*100, otherParam.allocTable_SubSector.PriorAA.*100, otherParam.allocTable_SubSector.PosteriorAA.*100];
    titParam.name     = {otherParam.titChunk1; otherParam.titChunk2; otherParam.titChunk3};
    xParam.axisLabels = otherParam.allocTable_SubSector.SubSector;
    yParam.axisLabels = '% Allocations';
    legParam.title    = {'Current AA','Prior AA','Posterior AA'};
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% PORTFOLIO RISK MEASURES SA
if strcmp(chartName,'PortRiskSummary_SA') || isempty(chartName)
    
    varBars_SA = [otherParam.selectedVaR_prior_curr.*100, otherParam.selectedVaR_post_curr.*100];
    esBars_SA  = [otherParam.selectedES_prior_curr.*100, otherParam.selectedES_post_curr.*100];
    prBars_SA  = [otherParam.ProjReturn_Prior_curr.*100, otherParam.ProjReturn_post_curr.*100];
    
    % Chart
    vector4BarChart   = [varBars_SA; esBars_SA; prBars_SA];
    titParam.name     = {otherParam.titChunk1};
    xParam.axisLabels = {'Value At Risk','Expected ShortFall','Projected Return'};
    xParam.lineWidth  = 3;
    xParam.edgeColor  = 'red';
    xParam.barParam   = 2;
    yParam.axisLabels = 'Risk (%)';
    legParam.title    = {'Prior AA Current Portfolio','Posterior AA Current Portfolio'};
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
    xParam = rmfield(xParam, 'barParam');
    xParam = rmfield(xParam, 'lineWidth');
    
end

% PORTFOLIO RISK MEASURES MP
if strcmp(chartName,'PortRiskSummary_MP') || isempty(chartName) % x Model Portfolio
    
    varBars_MP = [otherParam.selectedVaR_prior_curr.*100, otherParam.selectedVaR_post_curr.*100, ...
        otherParam.selectedVaR_prior.*100, otherParam.selectedVaR_prior_WithPostProb.*100, ...
        otherParam.selectedVaR_posterior.*100, otherParam.selectedVaR_posterior_WithPostProb.*100];
    esBars_MP  = [otherParam.selectedES_prior_curr.*100, otherParam.selectedES_post_curr.*100, ...
        otherParam.selectedES_prior.*100, otherParam.selectedES_prior_WithPostProb.*100, ...
        otherParam.selectedES_posterior.*100, otherParam.selectedES_posterior_WithPostProb.*100];
    prBars_SA  = [otherParam.ProjReturn_Prior_curr.*100, otherParam.ProjReturn_post_curr.*100, ...
        otherParam.ProjReturn_Prior.*100, otherParam.ProjReturn_PriorOnPostProb.*100, ...
        otherParam.ProjReturn_Posterior.*100, otherParam.ProjReturn_PosteriorOnPostProb.*100];
    
    % Chart
    vector4BarChart   = [varBars_MP; esBars_MP; prBars_SA];
    titParam.name     = {otherParam.titChunk1; otherParam.titChunk2; otherParam.titChunk3};
    xParam.axisLabels = {'Value At Risk','Expected ShortFall','Projected Return'};
    xParam.lineWidth  = 3;
    xParam.edgeColor  = 'red';
    xParam.barParam   = 5;
    yParam.axisLabels = 'Risk (%)';
    legParam.title    = {'Current PTF with Prior Prob','Current PTF with Posterior Prob', ...
                         'Optimal Prior PTF with Prior Prob', 'Optimal Prior PTF with Posterior Prob', ...
                         'Optimal Posterior PTF with Prior Prob', 'Optimal Posterior PTF with Posterior Prob' };
    legParam.location = 'southwest';

%     legParam.title    = {'Prior AA Current Portfolio','Posterior AA Current Portfolio', ...
%         'Prior AA Portfolio', 'Prior AA Portfolio Shocked', ...
%         'Posterior AA Portfolio', 'Posterior AA Portfolio Shocked' };
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
    xParam = rmfield(xParam, 'barParam');
    xParam = rmfield(xParam, 'lineWidth');
    
end

% RISK METHODOLOGY CURR
if strcmp(chartName,'RiskMethodology_CURR') || isempty(chartName)
    
    varBars_SA = [otherParam.selectedVaR_prior_curr.*100, otherParam.selectedVaR_prior_curr_Hist.*100, otherParam.selectedVaR_prior_curr_Param.*100];
    esBars_SA  = [otherParam.selectedES_prior_curr.*100, otherParam.selectedES_prior_curr_Hist.*100, otherParam.selectedES_prior_curr_Param.*100];
    
    % Chart
    vector4BarChart   = [varBars_SA; esBars_SA];
    titParam.name     = {otherParam.titChunk1};
    xParam.axisLabels = {'Value At Risk','Expected ShortFall'};
    xParam.lineWidth  = 3;
    xParam.edgeColor  = 'red';
    xParam.barParam   = 1;
    yParam.axisLabels = 'Risk (%)';
    legParam.title    = {'Montecarlo Methodology','Historical Methodology', 'Parametric Methodology'};
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
    xParam = rmfield(xParam, 'barParam');
    xParam = rmfield(xParam, 'lineWidth');
    
end

% RETURN
if strcmp(chartName,'Return') || isempty(chartName)
    
    % Chart
    vector4BarChart   = [otherParam.selectedRET_prior,otherParam.selectedRET_posterior];
    titParam.name     = {[otherParam.Label.universeName,' as of ',otherParam.ReferenceDate,' - Projected RET']; otherParam.titChunk2; otherParam.titChunk3};
    xParam.axisLabels = otherParam.allocTable.Assets;
    yParam.axisLabels = 'RET (%)';
    legParam.title    = {'Prior based Returns','Posterior (Incorporating Views) based Projected Return'};
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

if strcmp(chartName,'Ret_NoTitle') || isempty(chartName) % same as the above one, but does not print the full title on top of the chart
    
    % Chart
    vector4BarChart   = [otherParam.selectedRET_prior, otherParam.selectedRET_posterior];
    titParam.name     = {[otherParam.Label.universeName,' as of ',otherParam.ReferenceDate,' - Projected RET']};
    xParam.axisLabels = otherParam.allocTable.Assets;
    yParam.axisLabels = 'Marginal RET (%)';
    legParam.title    = {'Prior based Returns','Posterior (Incorporating Views) based Projected Return'};
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% **************************

% MARGINAL VAR: current ptf - asset class
if (R.params_AA.MargRisk(1)) && (strcmp(chartName,'MargVaR_CurrPtf_Class') || isempty(chartName))
    
    % Chart
    vector4BarChart   = [otherParam.selectedMVaR_AssetClass_curr.*100];
    titParam.name     = {[otherParam.Label.universeName,' as of ',otherParam.ReferenceDate,' - Projected Marginal VaR']};
    xParam.axisLabels = cellstr(otherParam.selectedMVaR_AssetClass_Map)';
    yParam.axisLabels = 'Marginal VaR (%)';
    legParam.title    = {'Marginal VaR on Current Portfolio'};
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% MARGINAL VAR: prior ptf - asset class
if (R.params_AA.MargRisk(1)) && (strcmp(chartName,'MargVaR_PriorPtf_Class') || isempty(chartName))
    
    % Chart
    vector4BarChart   = [otherParam.selectedMVaR_AssetClass_prior.*100];
    titParam.name     = {[otherParam.Label.universeName,' as of ',otherParam.ReferenceDate,' - Projected Marginal VaR']};
    xParam.axisLabels = cellstr(otherParam.selectedMVaR_AssetClass_Map)';
    yParam.axisLabels = 'Marginal VaR (%)';
    legParam.title    = {'Marginal VaR on Prior Portfolio'};
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% MARGINAL VAR: posterior ptf - asset class
if (R.params_AA.MargRisk(1)) && (strcmp(chartName,'MargVaR_PostPtf_Class') || isempty(chartName))
    
    % Chart
    vector4BarChart   = [otherParam.selectedMVaR_AssetClass_posterior.*100];
    titParam.name     = {[otherParam.Label.universeName,' as of ',otherParam.ReferenceDate,' - Projected Marginal VaR']};
    xParam.axisLabels = cellstr(otherParam.selectedMVaR_AssetClass_Map)';
    yParam.axisLabels = 'Marginal VaR (%)';
    legParam.title    = {'Marginal VaR on Posterior Portfolio'};
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% MARGINAL VAR: current ptf - asset country
if (R.params_AA.MargRisk(2)) && (strcmp(chartName,'MargVaR_CurrPtf_Ctry') || isempty(chartName))
    
    % Chart
    vector4BarChart   = [otherParam.selectedMVaR_AssetCtry_curr.*100];
    titParam.name     = {[otherParam.Label.universeName,' as of ',otherParam.ReferenceDate,' - Projected Marginal VaR']};
    xParam.axisLabels = cellstr(otherParam.selectedMVaR_AssetCtry_Map)';
    yParam.axisLabels = 'Marginal VaR (%)';
    legParam.title    = {'Marginal VaR on Current Portfolio'};
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% MARGINAL VAR: prior ptf - asset country
if (R.params_AA.MargRisk(2)) && (strcmp(chartName,'MargVaR_PriorPtf_Ctry') || isempty(chartName))
    
    % Chart
    vector4BarChart   = [otherParam.selectedMVaR_AssetCtry_prior.*100];
    titParam.name     = {[otherParam.Label.universeName,' as of ',otherParam.ReferenceDate,' - Projected Marginal VaR']};
    xParam.axisLabels = cellstr(otherParam.selectedMVaR_AssetCtry_Map)';
    yParam.axisLabels = 'Marginal VaR (%)';
    legParam.title    = {'Marginal VaR on Prior Portfolio'};
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% MARGINAL VAR: posterior ptf - asset country
if (R.params_AA.MargRisk(2)) && (strcmp(chartName,'MargVaR_PostPtf_Ctry') || isempty(chartName))
    
    % Chart
    vector4BarChart   = [otherParam.selectedMVaR_AssetCtry_posterior.*100];
    titParam.name     = {[otherParam.Label.universeName,' as of ',otherParam.ReferenceDate,' - Projected Marginal VaR']};
    xParam.axisLabels = cellstr(otherParam.selectedMVaR_AssetCtry_Map)';
    yParam.axisLabels = 'Marginal VaR (%)';
    legParam.title    = {'Marginal VaR on Posterior Portfolio'};
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% MARGINAL VAR: current ptf - asset sector
if (R.params_AA.MargRisk(3)) && (strcmp(chartName,'MargVaR_CurrPtf_Sect') || isempty(chartName))
    
    % Chart
    vector4BarChart   = [otherParam.selectedMVaR_AssetSect_curr.*100];
    titParam.name     = {[otherParam.Label.universeName,' as of ',otherParam.ReferenceDate,' - Projected Marginal VaR']};
    xParam.axisLabels = cellstr(otherParam.selectedMVaR_AssetSect_Map)';
    yParam.axisLabels = 'Marginal VaR (%)';
    legParam.title    = {'Marginal VaR on Current Portfolio'};
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% MARGINAL VAR: prior ptf - asset sector
if (R.params_AA.MargRisk(3)) && (strcmp(chartName,'MargVaR_PriorPtf_Sect') || isempty(chartName))
    
    % Chart
    vector4BarChart   = [otherParam.selectedMVaR_AssetSect_prior.*100];
    titParam.name     = {[otherParam.Label.universeName,' as of ',otherParam.ReferenceDate,' - Projected Marginal VaR']};
    xParam.axisLabels = cellstr(otherParam.selectedMVaR_AssetSect_Map)';
    yParam.axisLabels = 'Marginal VaR (%)';
    legParam.title    = {'Marginal VaR on Prior Portfolio'};
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% MARGINAL VAR: posterior ptf - asset sector
if (R.params_AA.MargRisk(3)) && (strcmp(chartName,'MargVaR_PostPtf_Sect') || isempty(chartName))
    
    % Chart
    vector4BarChart   = [otherParam.selectedMVaR_AssetSect_posterior.*100];
    titParam.name     = {[otherParam.Label.universeName,' as of ',otherParam.ReferenceDate,' - Projected Marginal VaR']};
    xParam.axisLabels = cellstr(otherParam.selectedMVaR_AssetSect_Map)';
    yParam.axisLabels = 'Marginal VaR (%)';
    legParam.title    = {'Marginal VaR on Posterior Portfolio'};
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% MARGINAL VAR: current ptf - all asset
if (R.params_AA.MargRisk(4)) && (strcmp(chartName,'MargVaR_CurrPtf_All') || isempty(chartName))
    
    % Chart
    vector4BarChart   = [otherParam.selectedMVaR_AssetAll_curr.*100];
    titParam.name     = {[otherParam.Label.universeName,' as of ',otherParam.ReferenceDate,' - Projected Marginal VaR']};
    xParam.axisLabels = cellstr(otherParam.selectedMVaR_AssetAll_Map)';
    yParam.axisLabels = 'Marginal VaR (%)';
    legParam.title    = {'Marginal VaR on Current Portfolio'};
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% MARGINAL VAR: prior ptf - all asset
if (R.params_AA.MargRisk(4)) && (strcmp(chartName,'MargVaR_PriorPtf_All') || isempty(chartName))
    
    % Chart
    vector4BarChart   = [otherParam.selectedMVaR_AssetAll_prior.*100];
    titParam.name     = {[otherParam.Label.universeName,' as of ',otherParam.ReferenceDate,' - Projected Marginal VaR']};
    xParam.axisLabels = cellstr(otherParam.selectedMVaR_AssetAll_Map)';
    yParam.axisLabels = 'Marginal VaR (%)';
    legParam.title    = {'Marginal VaR on Prior Portfolio'};
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% MARGINAL VAR: posterior ptf - all asset
if (R.params_AA.MargRisk(4)) && (strcmp(chartName,'MargVaR_PostPtf_All') || isempty(chartName))
    
    % Chart
    vector4BarChart   = [otherParam.selectedMVaR_AssetAll_posterior.*100];
    titParam.name     = {[otherParam.Label.universeName,' as of ',otherParam.ReferenceDate,' - Projected Marginal VaR']};
    xParam.axisLabels = cellstr(otherParam.selectedMVaR_AssetAll_Map)';
    yParam.axisLabels = 'Marginal VaR (%)';
    legParam.title    = {'Marginal VaR on Posterior Portfolio'};
    
    plotBarChart(R, [], vector4BarChart, titParam, xParam, yParam, legParam);
    
end

% *************************

end % ChartPriorPosteriorOutputs method

