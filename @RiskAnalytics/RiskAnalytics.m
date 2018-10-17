classdef RiskAnalytics < handle
    % created 03042017: created to handle VaR / ES calculations over the
    % projected simulated returns at the investment horizon. It will be
    % progressively expanded to incorporate more and more analytics
    % NOTE: each instance of this class refers to the AA results obtained
    % at a specific optimization date (at the moment the latest one
    % available)
    
    properties (Constant)
        % VaR-ES confidence levels
        VaR_ES_confLevels = [0.95 0.99];
        daysInYear = 252;
    end
    
    properties (Access = public)
        ReturnsPtf_prior;             % matrix of simulated portfolio (weighted) returns obtained with the prior prob EF
        ReturnsPtf_posterior;         % matrix of simulated portfolio (weighted) returns obtained with the posterior prob EF
        ReturnsPtf_current;           % matrix of simulated  'current' portfolio (weighted) returns
        ReturnsPtf_priorCurrentWgts;     %
        ReturnsPtf_posteriorCurrentWgts; %
        AssetsNames;                  % names of the active assets
        ScenarioLabel;                % label for the subj view scenario output
        Output;                       % to gather outputs
        Output4Reports;               % specifically designed to host tables to be put on xls using objects of class FigureToExcel
        SelectedPointOnEF;            % property used to store information about the point that has been selected on the efficient frontier for output purposes
    end
    
    properties (SetAccess = protected)
        ReferenceDate;
    end
    
    properties (SetAccess = immutable)
        Budget;                       % total initial wealth to be allocated (abs Tot Notional when running scenario analysis)
        Horizon;                      % Investment Horizon (in years)
        HorizonDays;                  % Investment Horizon (in days)
        AssetsReturns;                % [J,N] matrix of J simulated joint scenarios (returns) for N 'active' assets (under the PRIOR prob)
        PriorProb;                    % vector of J prior probabilities associated to the J scenarios above
        PosteriorProb;                % vector of J posterior probabilities associated to the J scenarios above
        SubjectiveViewsWeight;        % confidence in subj / quant / prior
        QuantViewsWgt;
        ConfInPrior;
        EfficientFrontier;            % vectors
        Weights;                      % sets of weights corresponding to the points on the efficient frontier
        Date;                         % date as of which the above data refers to
        EfficientFrontierWeights_prior;       % matrix of dimension Nptf x nAssets containing the optiomal weights fot the nAssets assets across the Nptf pts of the efficient frontier obtained using the prior prob
        EfficientFrontierWeights_posterior;   % matrix of dimension Nptf x nAssets containing the optiomal weights fot the nAssets assets across the Nptf pts of the efficient frontier obtained using the posterior prob
        RiskReturnCoordinates_Prior;        % Risk / Return targets associated to the portfolios on the efficient frontier (based on prior distrib)
        RiskReturnCoordinates_Posterior;    % Risk / Return targets associated to the portfolios on the efficient frontier (based on posterior distrib)
        ActiveAssets;                 % vector of dimension [1xNtot] whose elements are ones when the corresponding asset is active. Ntot is the tot no of assets (both active and non active)
        CurrentWgts;                  % fixed weights (optional): used for scenario analysis (and 'model portfolio') purposes;
        IncludedNotional;             % this is notional included in the analysis (determined by which assets and related 'CurrentWgts' have been processed)
        CurrentWeightsActiveAssets;   % vector of weights for active assets only
        params;                       % input parameters structure
        params_AA;                    % struct array of parameters used to run the method Dynamic_AA_1 of class universe.m
        IU;                           % gets the field IU (inv universe as read by ReadFromIU_inputFile) used to instanciate the obj of class universe
        CountryStrategyInfo;          % info to classify assets based on sector/ctry
        AssetType;
        weightsLim;                   % lower and upper limits for AA (WEIGHTS)
        HVaR_inputs;                  % to hold HVaR related information
        Exceptions;                   % summary of excluded assets / curves
        confLevelUsed4xlsOutput;      % VaR and ES confidence level used for XLS reports (must be in R.VaR_ES_confLevels)
        confLevelUsed4xlsOutput_idx;  % index of the conf level above within the array in R.VaR_ES_confLevels
    end
    
    methods
        
        % declaring public methods defined within @RiskAnalytics
        out = getParam4ChartAndTable(obj);
        plotBarChart(obj, in1, in2, in3, in4, in5, in6);
        ChartPriorPosteriorOutputs(obj,chartName);
        out = OutputTables4Report(obj,in1);
        out = OutputText4Report(obj, in1);
        out = outRiskExcel(obj);
        
        function R = RiskAnalytics(U,params) % CONSTRUCTOR
            % INPUTS:
            % U: obj of class Universe, having some  of the properties
            % created by the method Universe.Dynamic_AA_1.
            % These properties are:
            % -> U.Strategies.Dynamic_AA_1.ProjectedReturns
            % -> U.Strategies.Dynamic_AA_1.ProbabilityVector
            % -> U.Strategies.Dynamic_AA_1.ProbabilityVector_Posterior
            % -> U.Strategies.Dynamic_AA_1.H_dates_vector
            % -> U.Strategies.Dynamic_AA_1.Dynamic_Frontier_EP (some of its
            %    subfields)
            % params: struct of parameters used below to compute various risk metrics
            
            % ALL THE DATA TAKEN BELOW REFERS TO THE LATES OPTIMIZATION RUN
            % (when the RiskAnalytics class in instantiated). So I will use
            % 'end' to identify the location in time
            
            disp('Instantiating RiskAnalytics class');
            R.params = params;
            R.HVaR_inputs = params.HVaR;
            R.ScenarioLabel = params.ScenarioLabel; % name of the scenario
            % take the latest datasets in U.Strategies.Dynamic_AA_1
            % (corresponding to the latest optimization date)
            R.Budget = U.Strategies.Dynamic_AA_1.Budget;
            R.Horizon = U.Strategies.Dynamic_AA_1.Horizon;
            R.HorizonDays = U.Strategies.Dynamic_AA_1.HorizonDays;
            R.AssetsReturns = U.Strategies.Dynamic_AA_1.ProjectedReturns{end}; % 'end' means the latest proj returns vector
            R.PriorProb = U.Strategies.Dynamic_AA_1.ProbabilityVector_Prior{end}; % 'end' means the latest prior prob vector
            R.PosteriorProb = U.Strategies.Dynamic_AA_1.ProbabilityVector_Posterior{end}; % 'end' means the latest posterior prob vector
            R.ActiveAssets = U.Strategies.Dynamic_AA_1.Dynamic_Frontier_EP.Active_Assets(end,:);
            R.Date = U.Strategies.Dynamic_AA_1.H_dates_vector(end);
            R.RiskReturnCoordinates_Posterior.Return = U.Strategies.Dynamic_AA_1.Dynamic_Frontier_EP.ExpectedReturn(:,end);
            R.RiskReturnCoordinates_Posterior.Risk = U.Strategies.Dynamic_AA_1.Dynamic_Frontier_EP.Risk(:,end);
            R.RiskReturnCoordinates_Prior.Return = U.Strategies.Dynamic_AA_1.Dynamic_Frontier_EP_Prior.ExpectedReturn(:,end);
            R.RiskReturnCoordinates_Prior.Risk = U.Strategies.Dynamic_AA_1.Dynamic_Frontier_EP_Prior.Risk(:,end);
            R.SubjectiveViewsWeight = U.Strategies.Dynamic_AA_1.SubjectiveViewsWeight;
            R.QuantViewsWgt = U.Strategies.Dynamic_AA_1.UsedConfInQuantViews;
            R.ConfInPrior = U.Strategies.Dynamic_AA_1.ConfInPrior;
            R.CurrentWgts = U.Strategies.Dynamic_AA_1.DAA_params.CurrentWgts;
            R.IncludedNotional = sum(abs(R.CurrentWgts .* R.Budget));
            % assign the confidence level used for XLS reports property. If
            % the conf level in DAA_params.confLevelUsed4xlsOutput is not
            % in the set of values within the constant property R.VaR_ES_confLevels
            % the execution stops and an error msg is displayed
            fconf = find(R.VaR_ES_confLevels == U.Strategies.Dynamic_AA_1.DAA_params.confLevelUsed4xlsOutput);
            if isempty(fconf)
                m = msgbox(['The confidence level set forth in  DAA_params(',num2str(U.Strategies.Dynamic_AA_1.DAA_params.confLevelUsed4xlsOutput), ...
                    ' is not in the set of admissible conf levels (see RiskAnalytics property VaR_ES_confLevels)',] ...
                    ,'Icon','warn');
                waitfor(m);
                error('RiskAnalytics cannot be executed (check conf levels)');
            else
                R.confLevelUsed4xlsOutput = U.Strategies.Dynamic_AA_1.DAA_params.confLevelUsed4xlsOutput;
                R.confLevelUsed4xlsOutput_idx = fconf(1);
            end
            
            R.params_AA = U.Strategies.Dynamic_AA_1.DAA_params;
            R.IU = U.IU;
            R.CountryStrategyInfo = U.CountryStrategyInfo;
            R.AssetType = U.AssetType;
            R.weightsLim = U.Assets_Legend;
            R.Exceptions = U.Exceptions;
            R.Output.Exceptions = U.Exceptions; % % exceptions added to the final output structure
            
            % Computing the Weights of the Assets along the Efficient Frontier
            assetsIds = fieldnames(U.Strategies.Dynamic_AA_1.Dynamic_Frontier_EP.Allocation);
            assetsNames = U.Assets_Legend;
            nassets = numel(assetsIds);
            % Looping over all Assets to retrieve the optimal Weights along the Efficient Frontier
            cnt = 0;
            for k=1:nassets
                nm = assetsIds{k,1};
                % gathering all 'most recent' optimal weights for k-th
                % asset across all of the efficient frontier points, for
                % both prior and posterior Eff Frontiers
                if R.ActiveAssets(k) % if the k-th assets is active
                    cnt = cnt + 1;
                    EfficientFrontierWeights_posterior(:,cnt) = U.Strategies.Dynamic_AA_1.Dynamic_Frontier_EP.Allocation.(nm)(:,end);
                    EfficientFrontierWeights_prior(:,cnt) = U.Strategies.Dynamic_AA_1.Dynamic_Frontier_EP.Allocation4ScenarioAnalysis.(nm)(:,end);
                    CurrentWeightsActiveAssets(cnt,1) = R.CurrentWgts(k);
                    ActiveAssetsNames{cnt,1} = assetsNames{k};
                end
            end
            R.EfficientFrontierWeights_prior = EfficientFrontierWeights_prior;
            R.EfficientFrontierWeights_posterior = EfficientFrontierWeights_posterior;
            R.AssetsNames = ActiveAssetsNames;
            R.CurrentWeightsActiveAssets = CurrentWeightsActiveAssets;
        end
        
        function PortfolioRiskMeasures(R)
            % This method computes some risk measures (VaR, ES, etc...) for
            % all the portfolio an the efficient frontier (R.EfficientFrontierWeights),
            % under both the prior and the posterior probability measures
            [T,N] = size(R.AssetsReturns); % #scenarios, #assets
            
            R.ReferenceDate = R.Date; % adding to output the date to which allocations and risk measures refers to
            
            mar = mean(R.AssetsReturns); % mean returns by assets
            
            % expected return (dim is # scenarios x 1]
            % these vectors contains the expected returns obtained from
            % R.AssetsReturns under different probability measures (like
            % equally weighted portfolios under the various risk measures
            ER_prior = R.AssetsReturns'*R.PriorProb;
            ER_posterior = R.AssetsReturns'*R.PosteriorProb;
            
            % returns from all assets (dim is # scenarios x # assets) under
            % the different prob measures
            sprob = size(R.PriorProb,1);
            pPriorDiag = spdiags(R.PriorProb,0,sprob,sprob);
%             pPriorDiag_sqrt = spdiags(R.PriorProb.^0.5,0,sprob,sprob);
            Ret_allAssets_prior =  pPriorDiag * R.AssetsReturns; % diag(R.PriorProb)*R.AssetsReturns;
            ExpReturnAllAssetsPrior = sum(Ret_allAssets_prior);
            ER_currentPtf_priorProb = ExpReturnAllAssetsPrior * R.CurrentWeightsActiveAssets;
            ER_currentPtf_priorProb_allAssets = (ExpReturnAllAssetsPrior.*R.CurrentWeightsActiveAssets')';
            
            
            sprob = size(R.PosteriorProb,1);
            pPosteriorProbDiag = spdiags(R.PosteriorProb,0,sprob,sprob);
            Ret_allAssets_posterior = pPosteriorProbDiag*R.AssetsReturns;
            ExpReturnAllAssetsPosterior = sum(Ret_allAssets_posterior);
            ER_currentPtf_posteriorProb = ExpReturnAllAssetsPosterior * R.CurrentWeightsActiveAssets;
            ER_currentPtf_posteriorProb_allAssets = (ExpReturnAllAssetsPosterior.*R.CurrentWeightsActiveAssets')';

            priorReturnsCurrentWgts = R.AssetsReturns*R.CurrentWeightsActiveAssets;
            priorReturnsPriorWgts = R.AssetsReturns*R.EfficientFrontierWeights_prior';
            priorReturnsPosteriorWgts = R.AssetsReturns*R.EfficientFrontierWeights_posterior';
        
            
            covMatrix_prior = R.Covariance(R.AssetsReturns,R.PriorProb);
            covMatrix_posterior = R.Covariance(R.AssetsReturns,R.PosteriorProb);
            covMatrix_historical = cov(R.HVaR_inputs.R_sim_HVaRScenarios);
            
            disp(['Computing Risk Measures as of date ',datestr(R.Date)]);
            
            % No of Simulation
            NSim = size(R.AssetsReturns,1);
            % No of Portfolios on the Efficient Frontier
            NPtf = size(R.EfficientFrontierWeights_prior,1);
            
            % Needed within the loop below to compute Hist/Parametric Risk Measures
            ninv = @(x) norminv(1-x);
            HVaR_PtfReturns = R.HVaR_inputs.R_sim_HVaRScenarios * R.CurrentWeightsActiveAssets;
            HVaR_prob = 1 ./ R.HVaR_inputs.Length .* ones(R.HVaR_inputs.Length,1);
            parametric_thresholds = ninv(R.VaR_ES_confLevels);
            PtfStd_HistScen = (R.CurrentWeightsActiveAssets'*covMatrix_historical*R.CurrentWeightsActiveAssets).^0.5; % portfolio risk (STD)
            PtfMu_HistScen = mean(HVaR_PtfReturns);
            
            % *************************************************************
            % Computation of all Risk Measures for all of the confidence
            % levels in R.VaR_ES_confLevels START HERE
            % *************************************************************
            for c=1:numel(R.VaR_ES_confLevels) % for each confidence level
                
                conf = R.VaR_ES_confLevels(c);
                confFldName = ['ConfLevel_',strrep(num2str(conf),'.','_')];
                
                % *************************************************************
                % SIMULATION BASED RISK MEASURES COMPUTATION
                % Montecarlo Based Risk Measures calc starts here
                % *************************************************************
                
                % *************************************************************
                % *******         CURRENT PORTFOLIO MEASUREs         **********
                % *******         PRIOR WEIGHTS                        ********
                % *************************************************************
                
                % PRIOR MEASURES WITH CURRENT WEIGHTS

                % for parametric measures
                ptfStd_SimPrior = (R.CurrentWeightsActiveAssets'*covMatrix_prior*R.CurrentWeightsActiveAssets).^0.5; % portfolio risk (STD)
                mu_SimPrior = ER_currentPtf_priorProb;
                
                % ES-VaR calc under prior probability measure and using current weights
                [VaR,ES,VaRp,ESp] = R.riskMetrics(priorReturnsCurrentWgts,R.PriorProb,conf,ptfStd_SimPrior,mu_SimPrior);
                R.Output.PortfolioReturnMeasures.CurrentPtf.Simulation.PriorProb.AtHorizon.PtfLevel.ProjReturn = ...
                    ER_currentPtf_priorProb; % priorReturnsCurrentWgts'*R.PriorProb; % Portfolio return based on prior;
                R.Output.PortfolioReturnMeasures.CurrentPtf.Simulation.PriorProb.AtHorizon.AllAssets.ProjReturn = ...
                    ER_currentPtf_priorProb_allAssets; % R.CurrentWeightsActiveAssets.*(R.AssetsReturns'*R.PriorProb); % returns for each single asset
                R.Output.PortfolioRiskMeasures.CurrentPtf.Simulation.PriorProb.AtHorizon.PtfLevel.VaR(1,c) = VaR;
                R.Output.PortfolioRiskMeasures.CurrentPtf.Simulation.PriorProb.AtHorizon.PtfLevel.ES(1,c) = ES;
                
                R.Output.PortfolioRiskMeasures.CurrentPtf.Parametric.PriorProb.AtHorizon.PtfLevel.VaR(1,c) = VaRp;
                R.Output.PortfolioRiskMeasures.CurrentPtf.Parametric.PriorProb.AtHorizon.PtfLevel.ES(1,c) = ESp;
                
                % POSTERIOR MEASURES WITH CURRENT WEIGHTS
                % ES-VaR calc under posterior probability measure and using current weights
                
                % for parametric measures
                ptfStd_SimPost = (R.CurrentWeightsActiveAssets'*covMatrix_posterior*R.CurrentWeightsActiveAssets).^0.5; % portfolio risk (STD)
                mu_SimPost = ER_currentPtf_posteriorProb;
                
                [VaR,ES,VaRp,ESp] = R.riskMetrics(priorReturnsCurrentWgts,R.PosteriorProb,conf,ptfStd_SimPost,mu_SimPost);
                R.Output.PortfolioReturnMeasures.CurrentPtf.Simulation.PosteriorProb.AtHorizon.PtfLevel.projReturn = ...
                    ER_currentPtf_posteriorProb; % priorReturnsCurrentWgts'*R.PosteriorProb; % PORTFOLIO RETURN BASED ON POSTERIOR
                R.Output.PortfolioReturnMeasures.CurrentPtf.Simulation.PosteriorProb.AtHorizon.AllAssets.projReturn = ...
                    ER_currentPtf_posteriorProb_allAssets; %R.CurrentWeightsActiveAssets.*(R.AssetsReturns'*R.PosteriorProb); % returns for each single asset
                R.Output.PortfolioRiskMeasures.CurrentPtf.Simulation.PosteriorProb.AtHorizon.PtfLevel.VaR(1,c) = VaR;
                R.Output.PortfolioRiskMeasures.CurrentPtf.Simulation.PosteriorProb.AtHorizon.PtfLevel.ES(1,c) = ES;
                
                R.Output.PortfolioRiskMeasures.CurrentPtf.Parametric.PosteriorProb.AtHorizon.PtfLevel.VaR(1,c) = VaRp;
                R.Output.PortfolioRiskMeasures.CurrentPtf.Parametric.PosteriorProb.AtHorizon.PtfLevel.ES(1,c) = ESp;
                
                % Parametric Ptf Expected Return and Ptf Std along the
                % efficient frontier
                % *********************************************************
                
                
                % *************************************************************
                % *******          OPTIMAL PORTFOLIOS MEASUREs         ********
                % *******          PRIOR WEIGHTS                       ********
                % *************************************************************
                
                % ----> PRIOR PROBABILITIES 
                
                % before calculating OPTIMAL PORTFOLIOS MEASUREs I need to
                % compute the parametric expected return and std for each
                % ptf on the efficient frontier
                % TODO: CREATE A FUNCTION FOR THE LOOP BELOW (it is
                % repeated several times)
                
%                 ptfStd_ef = zeros(NPtf,1);
%                 mu_ef = zeros(NPtf,1);
%                 for n=1:NPtf
%                     W = R.EfficientFrontierWeights_prior(n,:)';
%                     ReturnsPtf_ef(:,1) = priorReturnsPriorWgts(:,n); %(Ret_allAssets_prior)*W;
%                     ptfStd_ef(n,1) = (W'*covMatrix_prior*W).^0.5; % portfolio risk (STD); 
%                     mu_ef(n,1) = mean(ReturnsPtf_ef);
%                 end
                
                W = R.EfficientFrontierWeights_prior;
                ReturnsPtf_ef = priorReturnsPriorWgts; %(Ret_allAssets_prior)*W;
                PriorP = R.PriorProb;
                [mu_ef, ptfStd_ef] = RiskAnalytics.mainStatIndicator(NPtf,W,ReturnsPtf_ef,PriorP,covMatrix_prior);
                                
                % PRIOR MEASURES WITH 'PRIOR BASED' WEIGHTS
                % ES-VaR calc under prior probability measure
                [VaR,ES,VaRp,ESp] = R.riskMetrics(priorReturnsPriorWgts,R.PriorProb,conf,ptfStd_ef,mu_ef);
                
                R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.PriorProb.AtHorizon.PtfLevel.ProjReturn = ...
                    priorReturnsPriorWgts'*R.PriorProb; % Efficient Portfolios Returns based on prior
                R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.PriorProb.AtHorizon.AllAssets.ProjReturn = ...
                    R.EfficientFrontierWeights_prior'.*(R.AssetsReturns'*R.PriorProb); % Efficient Portfolio Returns based on prior for each single asset
                R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.PriorProb.AtHorizon.PtfLevel.VaR(:,c) = VaR';
                R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.PriorProb.AtHorizon.PtfLevel.ES(:,c) = ES';
                
                R.Output.EfficientFrontiers.PriorOptimalPtf.Parametric.PriorProb.AtHorizon.PtfLevel.VaR(:,c) = VaRp;
                R.Output.EfficientFrontiers.PriorOptimalPtf.Parametric.PriorProb.AtHorizon.PtfLevel.ES(:,c) = ESp';
                
                % ----> POSTERIOR PROBABILITIES 
                
                % before calculating OPTIMAL PORTFOLIOS MEASUREs I need to
                % compute the parametric expected return and std for each
                % ptf on the efficient frontier
                
%                 ptfStd_ef = zeros(NPtf,1);
%                 mu_ef = zeros(NPtf,1);
%                 for n=1:NPtf
%                     W = R.EfficientFrontierWeights_prior(n,:)';
%                     ReturnsPtf_ef(:,1) = priorReturnsPriorWgts(:,n);
%                     ptfStd_ef(n,1) = (W'*covMatrix_posterior*W).^0.5; % portfolio risk (STD); 
%                     mu_ef(n,1) = mean(ReturnsPtf_ef);
%                 end
                
                W = R.EfficientFrontierWeights_prior;
                ReturnsPtf_ef = priorReturnsPriorWgts; %(Ret_allAssets_prior)*W;
                PostP = R.PosteriorProb;
                [mu_ef, ptfStd_ef] = RiskAnalytics.mainStatIndicator(NPtf,W,ReturnsPtf_ef,PostP,covMatrix_posterior);
                
                % POSTERIOR MEASURES WITH 'PRIOR BASED' WEIGHTS
                % VaR - ES on the 'prior' optimal portfolio using the 'posterior' probabilities:
                % this is to see how the prior portfolio risk would change due to the views
                [VaR,ES,VaRp,ESp] = R.riskMetrics(priorReturnsPriorWgts,R.PosteriorProb,conf,ptfStd_ef,mu_ef);
                R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.PosteriorProb.AtHorizon.PtfLevel.ProjReturn = ...
                    priorReturnsPriorWgts'*R.PosteriorProb; % Prior Efficient Portfolios Returns based on posterior
                R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.PosteriorProb.AtHorizon.AllAssets.ProjReturn = ...
                    R.EfficientFrontierWeights_prior'.*(R.AssetsReturns'*R.PosteriorProb); % Prior Efficient Portfolio Returns based on posterior for each single asset
                R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.PosteriorProb.AtHorizon.PtfLevel.VaR(:,c) = VaR';
                R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.PosteriorProb.AtHorizon.PtfLevel.ES(:,c) = ES';
                
                R.Output.EfficientFrontiers.PriorOptimalPtf.Parametric.PosteriorProb.AtHorizon.PtfLevel.VaR(:,c) = VaRp;
                R.Output.EfficientFrontiers.PriorOptimalPtf.Parametric.PosteriorProb.AtHorizon.PtfLevel.ES(:,c) = ESp;
                
                % *************************************************************
                % *******          OPTIMAL PORTFOLIOS MEASUREs         ********
                % *******          POSTERIOR WEIGHTS                   ********
                % *************************************************************
                
                % ----> PRIOR PROBABILITIES 
                
                % before calculating OPTIMAL PORTFOLIOS MEASUREs I need to
                % compute the parametric expected return and std for each
                % ptf on the efficient frontier
                
%                 ptfStd_ef = zeros(NPtf,1);
%                 mu_ef = zeros(NPtf,1);
%                  for n=1:NPtf
%                     W = R.EfficientFrontierWeights_posterior(n,:)';
%                     ReturnsPtf_ef(:,1) = priorReturnsPosteriorWgts(:,n);
%                     ptfStd_ef(n,1) = (W'*covMatrix_prior*W).^0.5; % portfolio risk (STD); 
%                     mu_ef(n,1) = mean(ReturnsPtf_ef);
%                  end
                 
                W = R.EfficientFrontierWeights_posterior;
                ReturnsPtf_ef = priorReturnsPosteriorWgts; %(Ret_allAssets_prior)*W;
                PriorP = R.PriorProb;
                [mu_ef, ptfStd_ef] = RiskAnalytics.mainStatIndicator(NPtf,W,ReturnsPtf_ef,PriorP,covMatrix_prior);
                
                 
                % PRIOR MEASURES WITH 'POSTERIOR BASED' WEIGHTS
                % ES-VaR calc under posterior probability measure
                [VaR,ES,VaRp,ESp] = R.riskMetrics(priorReturnsPosteriorWgts,R.PriorProb,conf,ptfStd_ef,mu_ef);
                R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.PriorProb.AtHorizon.PtfLevel.ProjReturn = ...
                    priorReturnsPosteriorWgts'*R.PriorProb; % Posterior Efficient Portfolios Returns based on prior prob
                R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.PriorProb.AtHorizon.AllAssets.ProjReturn = ...
                    R.EfficientFrontierWeights_posterior'.*(R.AssetsReturns'*R.PriorProb); % Posterior Efficient Portfolio Returns based on prior prob for each single asset
                R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.PriorProb.AtHorizon.PtfLevel.VaR(:,c) = VaR';
                R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.PriorProb.AtHorizon.PtfLevel.ES(:,c) = ES';
                
                R.Output.EfficientFrontiers.PosteriorOptimalPtf.Parametric.PriorProb.AtHorizon.PtfLevel.VaR(:,c) = VaRp;
                R.Output.EfficientFrontiers.PosteriorOptimalPtf.Parametric.PriorProb.AtHorizon.PtfLevel.ES(:,c) = ESp;
                
                
                % ----> POSTERIOR PROBABILITIES
                
                % POSTERIOR MEASURES WITH 'POSTERIOR BASED' WEIGHTS
                
                % before calculating OPTIMAL PORTFOLIOS MEASUREs I need to
                % compute the parametric expected return and std for each
                % ptf on the efficient frontier
                
%                 ptfStd_ef = zeros(NPtf,1);
%                 mu_ef = zeros(NPtf,1);
%                 for n=1:NPtf
%                     W = R.EfficientFrontierWeights_posterior(n,:)';
%                     ReturnsPtf_ef(:,1) = priorReturnsPosteriorWgts(:,n);
%                     ptfStd_ef(n,1) = (W'*covMatrix_posterior*W).^0.5; % portfolio risk (STD);
%                     mu_ef(n,1) = mean(ReturnsPtf_ef);
%                 end
                
                W = R.EfficientFrontierWeights_posterior;
                ReturnsPtf_ef = priorReturnsPosteriorWgts; %(Ret_allAssets_prior)*W;
                PostP = R.PosteriorProb;
                [mu_ef, ptfStd_ef] = RiskAnalytics.mainStatIndicator(NPtf,W,ReturnsPtf_ef,PostP,covMatrix_posterior);
                
                
                % ES-VaR calc under posterior probability measure
                [VaR,ES,VaRp,ESp] = R.riskMetrics(priorReturnsPosteriorWgts,R.PosteriorProb,conf,ptfStd_ef,mu_ef);
                R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.PosteriorProb.AtHorizon.PtfLevel.ProjReturn = ...
                    priorReturnsPosteriorWgts'*R.PosteriorProb; % Posterior Efficient Portfolios Returns based on posterior
                R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.PosteriorProb.AtHorizon.AllAssets.ProjReturn = ...
                    R.EfficientFrontierWeights_posterior'.*(R.AssetsReturns'*R.PosteriorProb); % Posterior Efficient Portfolio Returns based on posterior for each single asset
                R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.PosteriorProb.AtHorizon.PtfLevel.VaR(:,c) = VaR';
                R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.PosteriorProb.AtHorizon.PtfLevel.ES(:,c) = ES';
                
                R.Output.EfficientFrontiers.PosteriorOptimalPtf.Parametric.PosteriorProb.AtHorizon.PtfLevel.VaR(:,c) = VaRp;
                R.Output.EfficientFrontiers.PosteriorOptimalPtf.Parametric.PosteriorProb.AtHorizon.PtfLevel.ES(:,c) = ESp;
                
                R.ReturnsPtf_current   = priorReturnsCurrentWgts;
                R.ReturnsPtf_prior     = priorReturnsPriorWgts;
                % R.ReturnsPtf_posterior = posteriorReturnsPosteriorWgts;
                
                
                % ********************* SIMULATION BASED **********************
                % ******   MARGINAL VAR, MARGINAL EXPECTED SHORTFALL   ********
                % *************************************************************
                
                if  ~(sum(R.params_AA.MargRisk)==0) % if not all marginal risk flags are false
                    
                    % R.AssetsNames;                        -> Name of : 127 assets
                    % R.AssetsReturns;                      -> Return of: 24,000 scenarios and 127 assets
                    % R.CurrentWeightsActiveAssets          -> Current Weights of: 1 portfolios with 127 assets
                    % R.EfficientFrontierWeights_prior      -> Prior Weights of: 50 portfolios with 127 assets
                    % R.EfficientFrontierWeights_posterior  -> Posterior Weights of: 50 portfolios with 127 assets
                    % R.PriorProb                    -> Prior Probability of: 24,000 scenarios
                    % R.PosteriorProb                -> Posterior Probability of: 24,000 scenarios
                    
                    boolAct = (R.ActiveAssets == 1);
                    
                    % Asset Map: different typology to group assets
                    % based on the values of the booleans in
                    % R.params_AA.MargRisk the map 'assetMap' is built to
                    % determine which marinal risk measures will be
                    % computed
                    if R.params_AA.MargRisk(1)
                        mrParam.assetMap.assetClass   = R.AssetType(boolAct,:);
                    end
                    if R.params_AA.MargRisk(2)
                        mrParam.assetMap.assetCountry = [R.CountryStrategyInfo(boolAct,1) R.CountryStrategyInfo(boolAct,2)];
                    end
                    if R.params_AA.MargRisk(3)
                        mrParam.assetMap.assetSector  = [R.CountryStrategyInfo(boolAct,1) R.CountryStrategyInfo(boolAct,3)];
                    end
                    if R.params_AA.MargRisk(4)
                        mrParam.assetMap.allAsset     = [R.AssetsNames strcat(strcat(string(1:1:sum(boolAct))','_'), R.AssetsNames)];
                    end
                    
                    % Return of active assets
                    mrParam.returns_Current       = R.AssetsReturns;
                    
                    % Confidence level to compute risk metrics
                    mrParam.measureConfidence     = R.VaR_ES_confLevels(c);
                    
                    % calculate marginal risk measures using different probability settings
                    probSettings = {'PriorProb','PosteriorProb'};
                    
                    n_probSettings = numel(probSettings);
                    for np=1:n_probSettings
                        h = probSettings(np);
                        % Probability vector associated to scenarios
                        mrParam.probabilityToBeUsed     = R.(h{1}); % ***** using prior probabilities *****
                        mrParam.probabilityToBeUsedDescription = h{1}; % do not use spaces or any char that cannot be used within variable names
                        
                        % Marginal Risk Measures
                        % compute marginal risk measures for CurrentPtf
                        mrParam.weights        = R.CurrentWeightsActiveAssets';
                        mrParam.VaR            = R.Output.PortfolioRiskMeasures.CurrentPtf.Simulation.(h{1}).AtHorizon.PtfLevel.VaR(c);
                        mrParam.ES             = R.Output.PortfolioRiskMeasures.CurrentPtf.Simulation.(h{1}).AtHorizon.PtfLevel.ES(c);
                        mrParam.VaRp           = R.Output.PortfolioRiskMeasures.CurrentPtf.Parametric.(h{1}).AtHorizon.PtfLevel.VaR(c);
                        mrParam.ESp            = R.Output.PortfolioRiskMeasures.CurrentPtf.Parametric.(h{1}).AtHorizon.PtfLevel.ES(c);
                        mrParam.covmatrix      = covMatrix_prior;
                        mrParam.Returns  =      R.AssetsReturns;
                        
                        [marginal_VaR_sim, marginal_ES_sim, marginal_VaR_param, marginal_ES_param] ...
                            = RiskAnalytics.calcMarginalRisk(mrParam);
                        R.Output.PortfolioRiskMeasures.CurrentPtf.Simulation.(h{1}).AtHorizon.PtfLevel.marginal_VaR{c,1} = marginal_VaR_sim;
                        R.Output.PortfolioRiskMeasures.CurrentPtf.Simulation.(h{1}).AtHorizon.PtfLevel.marginal_ES{c,1} = marginal_ES_sim;
                        
                        R.Output.PortfolioRiskMeasures.CurrentPtf.Parametric.(h{1}).AtHorizon.PtfLevel.marginal_VaR{c,1} = marginal_VaR_param;
                        R.Output.PortfolioRiskMeasures.CurrentPtf.Parametric.(h{1}).AtHorizon.PtfLevel.marginal_ES{c,1} = marginal_ES_param;
                        
                        
                        % compute marginal risk measures for PriorOptimal Portfolios
                        % they need to be calculated for each ptf on the efficient frontier
                        % %                         for n=1:NPtf
                        mrParam.weights        = R.EfficientFrontierWeights_prior;
                        mrParam.VaR            = R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.(h{1}).AtHorizon.PtfLevel.VaR(:,c);
                        mrParam.ES             = R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.(h{1}).AtHorizon.PtfLevel.ES(:,c);
                        mrParam.VaRp           = R.Output.EfficientFrontiers.PriorOptimalPtf.Parametric.(h{1}).AtHorizon.PtfLevel.VaR(:,c);
                        mrParam.ESp            = R.Output.EfficientFrontiers.PriorOptimalPtf.Parametric.(h{1}).AtHorizon.PtfLevel.ES(:,c);
                        mrParam.covmatrix      = covMatrix_prior;
                        mrParam.Returns        = R.AssetsReturns;
                        
                        [marginal_VaR_sim, marginal_ES_sim, marginal_VaR_param, marginal_ES_param] ...
                            = RiskAnalytics.calcMarginalRisk(mrParam);
                        
                        R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.(h{1}).AtHorizon.PtfLevel.marginal_VaR{c,1} = marginal_VaR_sim;
                        R.Output.EfficientFrontiers.PriorOptimalPtf.Simulation.(h{1}).AtHorizon.PtfLevel.marginal_ES{c,1} = marginal_ES_sim;
                        
                        R.Output.EfficientFrontiers.PriorOptimalPtf.Parametric.(h{1}).AtHorizon.PtfLevel.marginal_VaR{c,1} = marginal_VaR_param;
                        R.Output.EfficientFrontiers.PriorOptimalPtf.Parametric.(h{1}).AtHorizon.PtfLevel.marginal_ES{c,1} = marginal_ES_param;
                        
                        % compute marginal risk measures for PosteriorOptimal Portfolios
                        mrParam.weights       = R.EfficientFrontierWeights_posterior;
                        mrParam.VaR           = R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).AtHorizon.PtfLevel.VaR(:,c);
                        mrParam.ES            = R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).AtHorizon.PtfLevel.ES(:,c);
                        mrParam.VaRp          = R.Output.EfficientFrontiers.PosteriorOptimalPtf.Parametric.(h{1}).AtHorizon.PtfLevel.VaR(:,c);
                        mrParam.ESp           = R.Output.EfficientFrontiers.PosteriorOptimalPtf.Parametric.(h{1}).AtHorizon.PtfLevel.ES(:,c);
                        mrParam.covmatrix     = covMatrix_posterior;
                        mrParam.Returns       = R.AssetsReturns;
                        
                        [marginal_VaR_sim, marginal_ES_sim, marginal_VaR_param, marginal_ES_param] = RiskAnalytics.calcMarginalRisk(mrParam);
                        
                        R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).AtHorizon.PtfLevel.marginal_VaR{c,1} = marginal_VaR_sim;
                        R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).AtHorizon.PtfLevel.marginal_ES{c,1} = marginal_ES_sim;
                        
                        R.Output.EfficientFrontiers.PosteriorOptimalPtf.Parametric.(h{1}).AtHorizon.PtfLevel.marginal_VaR{c,1} = marginal_VaR_param;
                        R.Output.EfficientFrontiers.PosteriorOptimalPtf.Parametric.(h{1}).AtHorizon.PtfLevel.marginal_ES{c,1} = marginal_ES_param;
                        
                        % apply square root of time to get the same
                        % measures for different time spans
                        % VaR
                        fnames = fieldnames(R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).AtHorizon.PtfLevel.marginal_VaR{c,1});
                        n_fnames = numel(fnames);
                        for k=1:n_fnames % need to do this for each possible set of marginal VaR / ES that has been calculated
                            % VaR
                            [annualisedMeasure,onePeriodMeasaure] = ...
                                RiskAnalytics.ReScaleRiskFromAtHorizon( ...
                                R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).AtHorizon.PtfLevel.marginal_VaR{c,1}.(fnames{k}).data, ...
                                R.Horizon,R.daysInYear);
                            R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).Annualised.PtfLevel.marginal_VaR{c,1}.(fnames{k}).data = annualisedMeasure;
                            R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).OnePeriod.PtfLevel.marginal_VaR{c,1}.(fnames{k}).data = onePeriodMeasaure;
                            % need to inherit the typologyMap field as well
                            R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).Annualised.PtfLevel.marginal_VaR{c,1}.(fnames{k}).typologyMap = ...
                                R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).AtHorizon.PtfLevel.marginal_VaR{c,1}.(fnames{k}).typologyMap;
                            R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).OnePeriod.PtfLevel.marginal_VaR{c,1}.(fnames{k}).typologyMap = ...
                                R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).AtHorizon.PtfLevel.marginal_VaR{c,1}.(fnames{k}).typologyMap;
                            
                            % ... and for single portfolios
                            % (check that the 'data_SinglePtf' field is
                            % there since we do not calculate marginal risk
                            % measures for all single ptf)
                            if isfield(R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).AtHorizon.PtfLevel.marginal_VaR{c,1}.(fnames{k}),'data_SinglePtf')
                                [annualisedMeasure,onePeriodMeasaure] = ...
                                    RiskAnalytics.ReScaleRiskFromAtHorizon( ...
                                    R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).AtHorizon.PtfLevel.marginal_VaR{c,1}.(fnames{k}).data_SinglePtf, ...
                                    R.Horizon,R.daysInYear);
                                R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).Annualised.PtfLevel.marginal_VaR{c,1}.(fnames{k}).data_SinglePtf = annualisedMeasure;
                                R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).OnePeriod.PtfLevel.marginal_VaR{c,1}.(fnames{k}).data_SinglePtf = onePeriodMeasaure;
                            end
                            
                            % ES
                            [annualisedMeasure,onePeriodMeasaure] = ...
                                RiskAnalytics.ReScaleRiskFromAtHorizon( ...
                                R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).AtHorizon.PtfLevel.marginal_ES{c,1}.(fnames{k}).data, ...
                                R.Horizon,R.daysInYear);
                            R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).Annualised.PtfLevel.marginal_ES{c,1}.(fnames{k}).data = annualisedMeasure;
                            R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).OnePeriod.PtfLevel.marginal_ES{c,1}.(fnames{k}).data = onePeriodMeasaure;
                            % need to inherit the typologyMap field as well
                            R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).Annualised.PtfLevel.marginal_ES{c,1}.(fnames{k}).typologyMap = ...
                                R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).AtHorizon.PtfLevel.marginal_ES{c,1}.(fnames{k}).typologyMap;
                            R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).OnePeriod.PtfLevel.marginal_ES{c,1}.(fnames{k}).typologyMap = ...
                                R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).AtHorizon.PtfLevel.marginal_ES{c,1}.(fnames{k}).typologyMap;
                            
                            % ... and for single portfolios
                            % (check that the 'data_SinglePtf' field is
                            % there since we do not calculate marginal risk
                            % measures for all single ptf)
                            if isfield(R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).AtHorizon.PtfLevel.marginal_ES{c,1}.(fnames{k}),'data_SinglePtf')
                                [annualisedMeasure,onePeriodMeasaure] = ...
                                    RiskAnalytics.ReScaleRiskFromAtHorizon( ...
                                    R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).AtHorizon.PtfLevel.marginal_ES{c,1}.(fnames{k}).data_SinglePtf, ...
                                    R.Horizon,R.daysInYear);
                                R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).Annualised.PtfLevel.marginal_ES{c,1}.(fnames{k}).data_SinglePtf = annualisedMeasure;
                                R.Output.EfficientFrontiers.PosteriorOptimalPtf.Simulation.(h{1}).OnePeriod.PtfLevel.marginal_ES{c,1}.(fnames{k}).data_SinglePtf = onePeriodMeasaure;
                            end
                        end % looping over fnames
                        % %                         end % looping over pèortfolios alonf the efficient frontier
                    end % loop over probability settings {'PriorProb','PosteriorProb'}
                    
                else
                    % NO MARGINAL RISK MEASURES ARE COMPUTED
                end % loop over probSettings
                
                % *************************************************************
                % ************  END OF SIMULATION BASED RISK MEASURES *********
                % *************************************************************
                
                
                % *************************************************************
                % ********  HISTORICAL AND PARAMETRIC RISK MEASURES ***********
                % ************  based on HISTORICAL SCENARIOS   ***************
                % historical and parametric VaR computation: these measures are
                % calculated as 1-period (normally 1-day) measures and then
                % re-scaled to the investment horizon
                % *************************************************************
                
                % Using prctile for VaR ES calcs rather than static method
                % R.calcES (or calcMarginalRisk): this is done for historical VaR to use Matlab's
                % prctile builtin interpolation method.
                % TODO: include interpolation tools into calcMarginalRisk and/or calcES
                
                % -> HISTORICAL MEASURES BASED ON R.HVaR_inputs.Length days
                nconf = size(R.VaR_ES_confLevels,2);
                HVaRs(c) = prctile(HVaR_PtfReturns,[1 - R.VaR_ES_confLevels(c)]*100);
                ESs(c) = mean(HVaR_PtfReturns(HVaR_PtfReturns<=HVaRs(c)));
                HVaRs(c) = max(0,-HVaRs(c));
                ESs(c) = max(0,-ESs(c));
                % Annualised and 'at Horizon' measures (assuming square root of time applies)
                [HVaRs_annualised(c),HVaRs_atHorizon(c)] = RiskAnalytics.ReScaleRiskFromOnePeriod(HVaRs(c),R.Horizon,R.daysInYear);
                [ESs_annualised(c),ESs_atHorizon(c)] = RiskAnalytics.ReScaleRiskFromOnePeriod(ESs(c),R.Horizon,R.daysInYear);
                
                % -> PARAMETRIC MEASURES BASED ON R.HVaR_inputs.Length days
                VaRs_parametric(c) = max(0,-((PtfMu_HistScen + parametric_thresholds(c)*PtfStd_HistScen)));
                ESs_parametric(c) = (1./(1-R.VaR_ES_confLevels(c))).*quad(ninv,R.VaR_ES_confLevels(c),0.9999999).*PtfStd_HistScen + PtfMu_HistScen;
                ESs_parametric(c) = max(0,-ESs_parametric(c));
                % Annualised and 'at Horizon' measures (assuming square root of time applies)
                [VaRs_parametric_annualised(c),VaRs_parametric_atHorizon(c)] = RiskAnalytics.ReScaleRiskFromOnePeriod(VaRs_parametric(c), R.Horizon,R.daysInYear);
                [ESs_parametric_annualised(c),ESs_parametric_atHorizon(c)] = RiskAnalytics.ReScaleRiskFromOnePeriod(ESs_parametric(c), R.Horizon,R.daysInYear);
                
                % ************** HISTORICAL SCENARIOS BASED *******************
                % ******   MARGINAL VAR, MARGINAL EXPECTED SHORTFALL   ********
                % ******       for current Ptf only at the moment      ********
                % *************************************************************
                
                if   ~(sum(R.params_AA.MargRisk)==0) % if not all marginal risk flags are false
                    % Confidence level to compute risk metrics
                    mrParam.measureConfidence = R.VaR_ES_confLevels(c);
                    % current ptf weights
                    mrParam.weights       = R.CurrentWeightsActiveAssets';
                    % Hist Returns for active assets
                    % mrParam.returns_Current = R.HVaR_inputs.R_sim_HVaRScenarios;
                    mrParam.VaR = HVaRs(c);
                    mrParam.ES = ESs(c);
                    mrParam.VaRp = VaRs_parametric(c);
                    mrParam.ESp = ESs_parametric(c);
                    mrParam.covmatrix     = covMatrix_historical;
                    mrParam.Returns       = R.HVaR_inputs.R_sim_HVaRScenarios;
                        
                    % Probability vector associated to scenarios
                    mrParam.probabilityToBeUsed = HVaR_prob;
                    mrParam.probabilityToBeUsedDescription = ['HistScenariosProb'];
                    [marginal_VaR_HistScenarios, marginal_ES_HistScenarios,marginal_VaR_HistScenarios_p, marginal_ES_HistScenarios_p] = ...
                        RiskAnalytics.calcMarginalRisk(mrParam);
                    R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.OnePeriod.PtfLevel.marginal_VaR{c,1} = marginal_VaR_HistScenarios;
                    R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.OnePeriod.PtfLevel.marginal_ES{c,1} = marginal_ES_HistScenarios;
                    R.Output.PortfolioRiskMeasures.CurrentPtf.Parametric.HistScenariosProb.OnePeriod.PtfLevel.marginal_VaR{c,1} = marginal_VaR_HistScenarios_p;
                    R.Output.PortfolioRiskMeasures.CurrentPtf.Parametric.HistScenariosProb.OnePeriod.PtfLevel.marginal_ES{c,1} = marginal_ES_HistScenarios_p;
                
                    % apply square root of time to get the same
                    % measures for different time spans
                    % VaR
                    fnames = fieldnames(R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.OnePeriod.PtfLevel.marginal_VaR{c,1});
                    n_fnames = numel(fnames);
                    for k=1:n_fnames % need to do this for each possible set of marginal VaR / ES that has been calculated
                        % VaR
                        [annualisedMeasure,atHorizonMeasure] = ...
                            RiskAnalytics.ReScaleRiskFromOnePeriod( ...
                            R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.OnePeriod.PtfLevel.marginal_VaR{c,1}.(fnames{k}).data, ...
                            R.Horizon,R.daysInYear);
                        R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.Annualised.PtfLevel.marginal_VaR{c,1}.(fnames{k}).data = annualisedMeasure;
                        R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.AtHorizon.PtfLevel.marginal_VaR{c,1}.(fnames{k}).data = atHorizonMeasure;
                        % ... and for single portfolios
                        % (check that the 'data_SinglePtf' field is
                        % there since we do not calculate marginal risk
                        % measures for all single ptf)
                        if isfield(R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.OnePeriod.PtfLevel.marginal_VaR{c,1}.(fnames{k}),'data_SinglePtf')
                            [annualisedMeasure,atHorizonMeasure] = ...
                                RiskAnalytics.ReScaleRiskFromOnePeriod( ...
                                R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.OnePeriod.PtfLevel.marginal_VaR{c,1}.(fnames{k}).data_SinglePtf, ...
                                R.Horizon,R.daysInYear);
                            R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.Annualised.PtfLevel.marginal_VaR{c,1}.(fnames{k}).data_SinglePtf = annualisedMeasure;
                            R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.AtHorizon.PtfLevel.marginal_VaR{c,1}.(fnames{k}).data_SinglePtf = atHorizonMeasure;
                        end
                        % need to inherit the typologyMap field as well
                        R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.Annualised.PtfLevel.marginal_VaR{c,1}.(fnames{k}).typologyMap = ...
                            R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.OnePeriod.PtfLevel.marginal_VaR{c,1}.(fnames{k}).typologyMap;
                        R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.AtHorizon.PtfLevel.marginal_VaR{c,1}.(fnames{k}).typologyMap = ...
                            R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.OnePeriod.PtfLevel.marginal_VaR{c,1}.(fnames{k}).typologyMap;
                        
                        % ES
                        [annualisedMeasure,atHorizonMeasure] = ...
                            RiskAnalytics.ReScaleRiskFromOnePeriod( ...
                            R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.OnePeriod.PtfLevel.marginal_ES{c,1}.(fnames{k}).data, ...
                            R.Horizon,R.daysInYear);
                        R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.Annualised.PtfLevel.marginal_ES{c,1}.(fnames{k}).data = annualisedMeasure;
                        R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.AtHorizon.PtfLevel.marginal_ES{c,1}.(fnames{k}).data = atHorizonMeasure;
                        % ... and for single portfolios
                        % (check that the 'data_SinglePtf' field is
                        % there since we do not calculate marginal risk
                        % measures for all single ptf)
                        if isfield(R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.OnePeriod.PtfLevel.marginal_ES{c,1}.(fnames{k}),'data_SinglePtf')
                            [annualisedMeasure,atHorizonMeasure] = ...
                                RiskAnalytics.ReScaleRiskFromOnePeriod( ...
                                R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.OnePeriod.PtfLevel.marginal_ES{c,1}.(fnames{k}).data_SinglePtf, ...
                                R.Horizon,R.daysInYear);
                            R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.Annualised.PtfLevel.marginal_ES{c,1}.(fnames{k}).data_SinglePtf = annualisedMeasure;
                            R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.AtHorizon.PtfLevel.marginal_ES{c,1}.(fnames{k}).data_SinglePtf = atHorizonMeasure;
                        end
                        % need to inherit the typologyMap field as well
                        R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.Annualised.PtfLevel.marginal_ES{c,1}.(fnames{k}).typologyMap = ...
                            R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.OnePeriod.PtfLevel.marginal_ES{c,1}.(fnames{k}).typologyMap;
                        R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.AtHorizon.PtfLevel.marginal_ES{c,1}.(fnames{k}).typologyMap = ...
                            R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.OnePeriod.PtfLevel.marginal_ES{c,1}.(fnames{k}).typologyMap;
                    end
                    
                else
                    % NO MARGINAL RISK MEASURES ARE COMPUTED
                end
                
                % HistSim
                R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.OnePeriod.PtfLevel.VaR(1,c) = HVaRs(c);
                R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.OnePeriod.PtfLevel.ES(1,c) = ESs(c);             
                R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.AtHorizon.PtfLevel.VaR(1,c) = HVaRs_atHorizon(c); % TODO: assuming that 1-period returns are 1-day returns (PARAMETRIZE)
                R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.AtHorizon.PtfLevel.ES(1,c) = ESs_atHorizon(c);
                R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.Annualised.PtfLevel.VaR(1,c) = HVaRs_annualised(c); % TODO: assuming that 1-period returns are 1-day returns (PARAMETRIZE)
                R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.Annualised.PtfLevel.ES(1,c) = ESs_annualised(c);
                
                % Parametric
                R.Output.PortfolioRiskMeasures.CurrentPtf.Parametric.HistScenariosProb.OnePeriod.PtfLevel.VaR(1,c) = VaRs_parametric(c);
                R.Output.PortfolioRiskMeasures.CurrentPtf.Parametric.HistScenariosProb.OnePeriod.PtfLevel.ES(1,c) = ESs_parametric(c);
                R.Output.PortfolioRiskMeasures.CurrentPtf.Parametric.HistScenariosProb.AtHorizon.PtfLevel.VaR(1,c) = VaRs_parametric_atHorizon(c);  % TODO: assuming that 1-period returns are 1-day returns (PARAMETRIZE)
                R.Output.PortfolioRiskMeasures.CurrentPtf.Parametric.HistScenariosProb.AtHorizon.PtfLevel.ES(1,c) = ESs_parametric_atHorizon(c);
                R.Output.PortfolioRiskMeasures.CurrentPtf.Parametric.HistScenariosProb.Annualised.PtfLevel.VaR(1,c) = VaRs_parametric_annualised(c); % TODO: assuming that 1-period returns are 1-day returns (PARAMETRIZE)
                R.Output.PortfolioRiskMeasures.CurrentPtf.Parametric.HistScenariosProb.Annualised.PtfLevel.ES(1,c) = ESs_parametric_annualised(c);
                
                
                % *************************************************************
                % ******  END OF HISTORICAL AND PARAMETRIC RISK MEASURES ******
                % *************************************************************
                
            end % for each confidence level
            
            % Adding both Prior and Posterior Asset Allocations to the output structure to make easier output production
            R.Output.Allocations.AssetNames = R.AssetsNames;
            R.Output.Allocations.PriorProb.Weights =  R.EfficientFrontierWeights_prior';
            R.Output.Allocations.PosteriorProb.Weights =  R.EfficientFrontierWeights_posterior';
            
        end % PortfolioRiskMeasures
        
        function T = QuickOutputTable(R,varargin)
            % This method allow to get an output table, given the argument
            % in varargin
            % varargin: must be strctured in a meaningful way, given the
            % logic embedded in the output struct array R.Output (see
            % 'RiskAnalytics_OutputStructure.xls' in the \DOC folder for
            % reference). In more details, varargin cells should be based
            % on the following structure:
            % 1) TYPE OF OUTPUT: one of: 'PortfolioReturnMeasures', PortfolioRiskMeasures, EfficientFrontiers
            % 2) PORTFOLIO: one of: 'CurrentPtf', 'PriorOptimalPtf', 'PosteriorOptimalPtf'
            % 3) METHODOLOGY: one of: 'Simulation', 'HistSim', 'Parametric'
            % 4) PROBABILITY MEASURE: one of: 'PriorProb', 'PosteriorProb', 'HistScenariosProb'
            % 5) TIME DIMENSION: one of: 'OnePeriod', 'AtHorizon', 'Annualised'
            % 6) GRANULARITY: one of: 'PtfLevel', 'AllAssets'
            % 7) MEASURE; one of: ProjReturn 'VaR', 'ES', 'marginal_VaR', 'marginal_ES'
            %    - add 'data' when using 'marginal_VaR' or 'marginal_ES' -
            
            % *** for example:
            % invoking this method with:
            % RiskAn.QuickOutputTable('PortfolioRiskMeasures','CurrentPtf','HistSim','HistScenariosProb','Annualised','PtfLevel')
            % will yield an output table summarizing the value contained in
            % the PtfLevel subfield of the following struct array
            % R.Output.PortfolioRiskMeasures.CurrentPtf.HistSim.HistScenariosProb.Annualised.PtfLevel
            % esempio x marginal VaR
            % RR.QuickOutputTable('PortfolioRiskMeasures','CurrentPtf','Simulation','PosteriorProb','AtHorizon','PtfLevel','marginal_VaR{1,1}','assetClass')
            
            
            N = nargin;
            tmp = [];
            for k=1:N-1
                tmp = [tmp,'.',varargin{k}];
            end
            try
                toEval = ['R.Output',tmp];
                T = eval(['struct2table(',toEval,')']);
            catch MM
                if strcmp(MM.identifier,'MATLAB:nonExistentField')
                    disp('The structure provided is not admissible given the current RiskAnalytics.Output structure');
                    T = ['INVALID STRUCTURE ',toEval];
                else
                    rethrow(MM);
                end
            end
        end
        
        function GetPointOnEF(R)
            % Identify the portfolio corresponding to a target risk = to riskLevel
            % The closest portfolio is used.
            % To this purpose I minimize the abs diff between portfolios on
            % the EF and my tarhet risk level
            % ON the PRIOR EFF FRONTIER
            
            % modified (GP) 30.5.2017: now the target riskLevel is asked to
            % the user everytime this method is invoked, to make it
            % possible getting different outputs using the same set of data
            % that have been placed in the object 'R' already
            
            % The selected portfolio will be used to generate the output
            % charts and tables created by the output methods (see below)
            
            % ask the user to provide the desired risk target: when
            % there is one portfolio only (no optimization occurred
            % because weights were all given) this portfolio will be
            % taken anyway, since inside the
            % 'ChartPriorPosteriorOutputs' method the closest point on the
            % efficient frontier (both prior and posterior) will be
            % selected
            % This choice is meaningless when there is 1 portfolio only (pure stress tests))
            
            % ***************
            if numel(R.RiskReturnCoordinates_Prior.Risk)>1
                prompt     = {['Enter (AS a PERCENTAGE, for example 3.5) risk target for scenario: ',R.ScenarioLabel.posterior, ...
                    'The LOWEST RISK on the prior EF is ', num2str(R.RiskReturnCoordinates_Prior.Risk(1)*100),'%', ...
                    'The HIGHEST RISK on the prior EF is ', num2str(R.RiskReturnCoordinates_Prior.Risk(end)*100),'%']};
                dlg_title  = 'Input';
                num_lines  = 1;
                defaultans = {'0'}; % by default will look for the portfolio with a risk closest to zero
                answer     = inputdlg(prompt,dlg_title,num_lines,defaultans);
                riskLevel  = str2double(cell2mat(answer))/100;
            else
                riskLevel = 0;
            end
            % ***************
            
            absdiff = abs(R.RiskReturnCoordinates_Prior.Risk-riskLevel);
            [~,mnp_i_prior] = min(absdiff);
            TargetedRisk_Prior = R.RiskReturnCoordinates_Prior.Risk(mnp_i_prior)*100;
            TargetedReturn_Prior = R.RiskReturnCoordinates_Prior.Return(mnp_i_prior)*100;
            % ON the POSTERIOR EFF FRONTIER
            absdiff = abs(R.RiskReturnCoordinates_Posterior.Risk-riskLevel);
            [~,mnp_i_post] = min(absdiff);
            TargetedRisk_Posterior = R.RiskReturnCoordinates_Posterior.Risk(mnp_i_post)*100;
            TargetedReturn_Posterior = R.RiskReturnCoordinates_Posterior.Return(mnp_i_post)*100;
            
            R.SelectedPointOnEF.riskLevel = riskLevel*100;
            
            R.SelectedPointOnEF.PortNoPrior = mnp_i_prior;
            R.SelectedPointOnEF.TargetedRisk_Prior = TargetedRisk_Prior;
            R.SelectedPointOnEF.TargetedReturn_Prior = TargetedReturn_Prior;
            
            R.SelectedPointOnEF.PortNoPosterior = mnp_i_post;
            R.SelectedPointOnEF.TargetedRisk_Posterior = TargetedRisk_Posterior;
            R.SelectedPointOnEF.TargetedReturn_Posterior = TargetedReturn_Posterior;
            
        end % GetPointOnEF
            
        
    end % methods (Public)
    
    
    methods (Static)
        
        function [VaR,es] = calcES(port_ret,prob,ConfLevel)
            % calcES.m computes ES and Value At Risk based on returns
            % distribution 'port_ret', probability vector 'prob' and
            % confidence interval 'ConfLevel'
            
            [port_ret_s,oidx] = sort(port_ret); % sort in asdcending orders
            prob_s = prob(oidx); % associate corresponding probabilities
            F = cumsum(prob_s); % CDF
            q = find(F<=(1-ConfLevel)); % TODO: make this more precise
            q = q(end); % quantile selection
            prc = port_ret_s(q); % ... corresponding return
            VaR = max(-prc,0);
            es =  mean(port_ret(port_ret<=prc));
            es = max(-es,0);
            
        end % calcES
        
        function [VaR, ES, VaR_parametric, ES_parametric] = riskMetrics(ret, prob, conf, ptfStd, mu)
            % This function computes Value At Risk and Expected Shortfall
            %
            % INPUT:
            % -> ret:  returns distribution (n_scen x n_ptf)
            % -> prob: probability vector (n_scen x 1)
            % -> conf: confidence interval
            % -> ptfStd, mu:  ptf STD and ptf
            % expected return needed to compute parametric risk measures
            
            % OUTPUT:
            % -> VaR: value at risk
            % -> ES: expected shortfall
            
            % introduced by EB (13022018): replaces and extendes the old
            % calcES to more dimensions
            
            nPtf = size(ret,2);
            
            if nPtf ==1
                
                % Sorting returns in asdcending orders
                [ret_ord, ret_Id] = sort(ret);
                
                % Associating corresponding probabilities
                prob_ord = prob(ret_Id);
                
                
                % Cumulative Distribution Function
                F = cumsum(prob_ord);
                
                % Identifing percentile in the matrix
                thresholdCL = (1-conf);
                q = find(F<=thresholdCL);
                if isempty(q)
                    % VaR and ES = 0 if F(1) is higher than thresholdCL
                    % TEMP: TODO: try to interpolate
                    VaR = 0;
                    ES = 0;
                    % **** parametric measures ****
                    [VaR_parametric,ES_parametric] = RiskAnalytics.VaR_parametric_Calculation(mu,ptfStd,conf);
                    return;
                end
                q = q(end); % the closest quantile on the 'left'
                
                % VaR
                VaR_tmp = ret_ord(q);
                VaR = max(-VaR_tmp,0);
                % ES
                ES_tmp =  mean(ret_ord(ret_ord<=VaR_tmp));
                ES = max(-ES_tmp,0);
                
            else
                
                % Sorting returns in asdcending orders
                [ret_ord, ret_Id] = sort(ret);
                
                % Associating corresponding probabilities
                prob = repmat(prob,1,nPtf);
                prob_ord = prob(ret_Id);
                
                % Cumulative Distribution Function
                F = cumsum(prob_ord);
                
                % Percentile number
                thresholdCL = (1-conf);
                
                % flatten CDF and look for jumps (if any) from where it is
                % <= thresholdCL to where it is >thresholdCL
                F1 = F(:);
                ff = find(F1(2:end)>thresholdCL & F1(1:end-1)<=thresholdCL); %
                F1(ff) = Inf; % put Inf to signal the row corresponding to the thresholdCL-centile return
                F2 = reshape(F1,size(F)); % back to the original shape
                mxF2 = max(F2); % where it is not Inf there is not the searched quantile
                no_quantile = find(~isinf(mxF2));
                yes_quantile = find(isinf(mxF2));
                VaR_tmp = zeros(1,nPtf);
                % VaR_tmp(no_quantile) = NaN;
                ES_tmp = zeros(1,nPtf);
                VaR_tmp(yes_quantile) = ret_ord(ff);
                % ES calculation
                tmp = ret-VaR_tmp;
                tmp1 = zeros(size(ret));
                tmp1(tmp<0) = 1;
                ES_tmp = sum(ret.*tmp1)./sum(tmp1);
                % TODO: for now I choose to set VaR and ES to NaN in the
                % no_quantile case. TRY TO Interpolate F
                VaR = max(-VaR_tmp,0);
                ES = max(-ES_tmp,0);
                VaR(no_quantile) = NaN;
                ES(no_quantile) = NaN;
            end
            
            % **** parametric measures ****
            [VaR_parametric,ES_parametric] = RiskAnalytics.VaR_parametric_Calculation(mu,ptfStd,conf);
                       
        end % riskMetrics
        
        function [VaR_parametric,ES_parametric] = VaR_parametric_Calculation(mu,ptfStd,conf)
            ninv=@(x) norminv(1-x);
            parametric_threshold = norminv(1 - conf);
            VaR_parametric = max(0,-((mu + parametric_threshold*ptfStd)));
            ES_parametric = (1./(1 - conf)).*quad(ninv, conf, 0.9999999).*ptfStd + mu;
            ES_parametric = max(0,-ES_parametric);
        end % VaR_parametric_Calculation
        
        
        function [marginalVaR, marginalES, marginalVaRp, marginalESp] = calcMarginalRisk(param)
            % This method computes Marginal Risk measures (Marginal VaR,
            % Marginal ES) according to differents possible goruping
            % variables (e.g. sector, country, ec.)
            %
            % **** INPUTs:
            % -> param.assetMap.: is a struct with different typology (e.g. param.assetMap.assetClass, param.assetMap.assetCountry..),
            %    in each of them the first column there must be the asset tickers and in the second one there must be the asset typology.
            %    (e.g. param.assetMap.assetCountry: [{'MITSUBISHI UFJ FINANCIAL GRO','AUTOGRILL SPA','ACCIONA SA', ..} ; {'JN','IT','SP'..}])
            % -> param.returns_Current: current returns of the active assets     (e.g. 24,000 X 127 assets)
            
            % -> param.weights: weights of active assets for the portfolio (or portfolios) to be used   (e.g. 1 portfolios X 127 assets or 50 portfolios X 127 assets)
            % -> param.probabilityToBeUsed: probability vector associated to scenarios  (e.g. 24,000 scenarios x 1)
            % -> param.probabilityToBeUsedDescription: descriptive field
            %                                          used to name outputs
            %                                          subfieldn (do not
            %                                          use spaces and chars
            %                                          not allowed within
            %                                          field/variables names)
            % -> param.measureConfidence: confidence level to compute VaR and ES
            % -> param.VaR: VaR of the portfolio (or portfolios to be used), no stress     (e.g. 1 portfolios X 1 measure or 50 portfolios X 1 measure)
            % -> param.ES:  ES of the portfolio (or portfolios to be used), no stress     (e.g. 1 portfolios X 1 measure or 50 portfolios X 1 measure)
            % -> param.covmatrix: the covariance matrix calculated with the
            %                     desired probability measure (should be
            %                     probabilityToBeUsed)
            % -> param.Returns:   returns to be used for partial VaR
            %                     calculations: they should be consistent
            %                     with the VaR and ES values provided with
            %                     regard to the whole portfolio
           
            
            % **** OUTPUTs:
            % marginalVaR: marginal VaR for each typology (assetMap) w.r.t.
            % the portfolio or portfolios being worked out
            % marginalES: marginal ES for each typology (assetMap) w.r.t.
            % the portfolio or portfolios being worked out
            
            % Classification
            assetMap = param.assetMap;
            % Returns
            % retCurrent    = param.returns_Current;
            % Weights
            wgtsCurrent   = param.weights; % dim: Num portfolios x Num Of Assets x 
            % Probabilities
            probabilityVector     = param.probabilityToBeUsed;
            % Confidence
            measureConf   = param.measureConfidence;
            % VaR
            currentPtfVaR   = param.VaR;
            currentPtfVaRp   = param.VaRp;
            % ES
            currentPtfES   = param.ES;
            currentPtfESp   = param.ESp;
            
            Returns = param.Returns;
            
            mapsType = fieldnames(assetMap);
            m = size(mapsType,1);
            
            % Looping on Maps (e.g. grouping variable, ... for example bt
            % country, sector, portfolio, etc)
            for i=1:m
                
                typologyMap = assetMap.(mapsType{i,1});
                [uniqueTypology, ~, id] = unique(string(typologyMap(:,2)),'stable');
                u = size(uniqueTypology,1);
                
                % Looping on Typology (e.g. within the grouping variables
                % here is a loop over all of its possible values... for
                % example when using 'country' as grouping vaiable, this
                % could be GE,IT, ... etc)
                for ntype=1:u
                     
                    posId = (ntype ~= id)';
                    Returns_posId = Returns(:,posId);
                    wgts_posId = wgtsCurrent(:,posId)';          % dim: no of assets by no of portfolios
                    ReturnsTmp2Ptf   = Returns_posId*wgts_posId; % dim: returns by no of portfolios
                    
                    % for parametric measures I need to
                    % compute the parametric expected return and std for each
                    % ptf on the efficient frontier using the appropriate
                    % probability measure
                    % ******
                    NPtf = size(ReturnsTmp2Ptf,2);
                    ptfStd_ef = zeros(NPtf,1);
                    mu_ef = zeros(NPtf,1);
                    covMatrix = param.covmatrix(:,posId);
                    covMatrix = covMatrix(posId,:);
                    for n=1:NPtf
                        W = wgts_posId(:,n);
                        ReturnsPtf_ef(:,1) = ReturnsTmp2Ptf(:,n);
                        ptfStd_ef(n,1) = (W'*covMatrix*W).^0.5; % portfolio risk (STD);
                        mu_ef(n,1) = mean(ReturnsPtf_ef); % ATT.N: here I sum since scenarios have been multiplied by probabilities
                    end
                    % ******
                    
                    % VaR calculations
                    [VaR_lackPtf.(mapsType{i,1}), ES_lackPtf.(mapsType{i,1}), VaRp_lackPtf.(mapsType{i,1}), ESp_lackPtf.(mapsType{i,1})] = ...
                        RiskAnalytics.riskMetrics(ReturnsTmp2Ptf, probabilityVector, measureConf,ptfStd_ef,mu_ef);
                    
                    % Marginal Risk Measures
                    if size(currentPtfVaR,2)==1
                        % must have row vectors here
                        currentPtfVaR = currentPtfVaR';
                    end
                    if size(currentPtfES,2)==1
                        % must have row vectors here
                        currentPtfES = currentPtfES';
                    end
                    marginalVaR.(mapsType{i,1}).data(:,ntype)   = currentPtfVaR - VaR_lackPtf.(mapsType{i,1});
                    marginalES.(mapsType{i,1}).data(:,ntype)    = currentPtfES  - ES_lackPtf.(mapsType{i,1});
                    
                    marginalVaRp.(mapsType{i,1}).data(:,ntype)   = currentPtfVaRp - VaR_lackPtf.(mapsType{i,1})';
                    marginalESp.(mapsType{i,1}).data(:,ntype)    = currentPtfESp  - ES_lackPtf.(mapsType{i,1})';
                    
                    % *****************************************************
                    % only when the grouping variable is 'assetClass' (used
                    % to differentiate portfolios) we calculate the single
                    % portfolio risk measures as well.
                    if strcmp(mapsType{i,1},'assetClass')
                        posId = (ntype == id)';
                        Returns_posId = Returns(:,posId);
                        wgts_posId = wgtsCurrent(:,posId)';          % dim: no of assets by no of portfolios
                        ReturnsTmp2Ptf   = Returns_posId*wgts_posId; % dim: returns by no of portfolios
                        
                        % for parametric measures I need to
                        % compute the parametric expected return and std for each
                        % ptf on the efficient frontier using the appropriate
                        % probability measure
                        % ******
                        NPtf = size(ReturnsTmp2Ptf,2);
                        ptfStd_ef = zeros(NPtf,1);
                        mu_ef = zeros(NPtf,1);
                        covMatrix = param.covmatrix(:,posId);
                        covMatrix = covMatrix(posId,:);
                        for n=1:NPtf
                            W = wgts_posId(:,n);
                            ReturnsPtf_ef(:,1) = ReturnsTmp2Ptf(:,n);
                            ptfStd_ef(n,1) = (W'*covMatrix*W).^0.5; % portfolio risk (STD);
                            mu_ef(n,1) = mean(ReturnsPtf_ef); % ATT.N: here I sum since scenarios have been multiplied by probabilities
                        end
                        % ******
                        
                        % VaR calculations
                        [VaR_SinglePtf.(mapsType{i,1}), ES_SinglePtf.(mapsType{i,1}), VaR_SinglePtf_p.(mapsType{i,1}), ES_SinglePtf_p.(mapsType{i,1})] = ...
                            RiskAnalytics.riskMetrics(ReturnsTmp2Ptf, probabilityVector, measureConf,ptfStd_ef,mu_ef);
                       
                        % Marginal Risk Measures
                        if size(currentPtfVaR,2)==1
                            % must have row vectors here
                            currentPtfVaR = currentPtfVaR';
                        end
                        if size(currentPtfES,2)==1
                            % must have row vectors here
                            currentPtfES = currentPtfES';
                        end
                        marginalVaR.(mapsType{i,1}).data_SinglePtf(:,ntype)   = VaR_SinglePtf.(mapsType{i,1});
                        marginalES.(mapsType{i,1}).data_SinglePtf(:,ntype)    = ES_SinglePtf.(mapsType{i,1});
                        
                        marginalVaRp.(mapsType{i,1}).data_SinglePtf(:,ntype)   = VaR_SinglePtf_p.(mapsType{i,1});
                        marginalESp.(mapsType{i,1}).data_SinglePtf(:,ntype)    = ES_SinglePtf_p.(mapsType{i,1});
                    end
                    % *****************************************************
                    
                end % for
                
                marginalVaR.(mapsType{i,1}).typologyMap = uniqueTypology';
                marginalES.(mapsType{i,1}).typologyMap = uniqueTypology';
                
            end % for
            
        end % function calcMarginalRisk
        
        function [annualisedMeasure,atHorizonMeasure] = ReScaleRiskFromOnePeriod(onePeriodMeasaure,Horizon,daysInYear)
            % Rescale risk measures based on square root of time rule
            atHorizonMeasure = onePeriodMeasaure.*(Horizon.*daysInYear).^0.5;
            annualisedMeasure = atHorizonMeasure.*(1./Horizon).^0.5;
        end % ReScaleRiskFromOnePeriod
        
        function [annualisedMeasure,onePeriodMeasaure] = ReScaleRiskFromAtHorizon(atHorizonMeasure,Horizon,daysInYear)
            % Rescale risk measures based on square root of time rule
            onePeriodMeasaure = atHorizonMeasure./(Horizon.*daysInYear).^0.5;
            annualisedMeasure = onePeriodMeasaure.*(daysInYear).^0.5;
        end % ReScaleRiskFromAtHorizon
        
        function name_arr = concatenate(name, conf)
            % by F. Saporito (23.2.2018)
            conf_num = length(conf);
            
            if (conf_num == 0)
                error('outRiskExcel::concatenate(): empty confidence array');
            end
            
            name_arr = cell(1,conf_num);
            
            for i=1:conf_num
                name_arr{i} = [name, num2str(conf(i))];
            end % End For i
            
        end % End Function
        
        function C = Covariance(X,p)
            % calc the covariance matrix of X, given the probability vector
            % p
            % -> X: [J*N] matrix of J scenarios x N assets
            % -> p: vector of dim J of probabilities associated to the J
            % scenarios in X
            MUs = mean(X);
            sprob = size(p,1);
            diag_p = spdiags(p,0,sprob,sprob);
            C = (X-MUs)'*diag_p*(X-MUs);
           
        end % Covariance
        
        function [ptfMu, ptfStd] = mainStatIndicator(nPtf,ptfWgts,ptfRet,scenProb,covMatrix)
            % This function compute portfolio mean and std dev
            % nPtf: numebr of portfolios
            % ptfWgts: portfolio weights (nPortfolio x nAssets)
            % ptfRet: portfolio returns for each scenario (nScenarios x nPortfolio)
            % covMatrix: asset covariance (nAssets x nAssets)
            
            ptfMu  = zeros(nPtf,1);
            ptfStd = zeros(nPtf,1);
            for n=1:nPtf
                W = ptfWgts(n,:)';
                % Output
                ptfMu(n,1) = scenProb'*ptfRet(:,n); % sum(scenProb.*ptfRet(:,n))
                ptfStd(n,1) = (W'*covMatrix*W).^0.5; % portfolio risk (STD);
            end
            
        end
        
        
    end % methods (Static)
    
end % classdef


