function DAA_params = InitialParametersfromGUI(Settings)
    % lists of CDD/IR curves and Single indices available
    DAA_params.curves2beRead.CDS_SheetName = ['CDS_Curves']; % Sheet of Investment_Universe (empty if no CDS curves are needed)
    DAA_params.curves2beRead.IR_SheetName = ['IR_Curves'];   % same for IR curves
    DAA_params.curves2beRead.SingleIndices = ['Single_Indices']; % ... and single indices
    DAA_params.curves2beRead.IRC2beBtStrapped = ['IRC2beBtStrapped']; % ... and curves to be used for bootstrapping
    DAA_params.curves2beRead.VolaEquity = ['VolaEquity']; % ... and implied vola surfaces for equity options
    DAA_params.configFile4IrCurvesBtStrap = ['Curve_Structure.xlsx'];
    DAA_params.SetUpName = Settings.SetupList.Val;
    DAA_params.InvestmentUniverse_sheetName = Settings.InvestmentUniverseSheetName;
    DAA_params.BackTestOnly = Settings.BackTestOnly;
    DAA_params.riskAnalysisFlag = Settings.RiskAnalysis;
    DAA_params.lag4AA_enforcment = Settings.Lag4AA_enforcement;
    DAA_params.KeepcurrentPTFweights = Settings.KeepcurrentPTFweights;
    DAA_params.MinHistDate4Assets = Settings.MinHistoryStartDate;
    DAA_params.history_start_date = Settings.HistoryStartDate;
    DAA_params.history_end_date = Settings.HistoryEndDate;
    DAA_params.IV_hdate.start = '04/03/2018'; % NOT USED
    DAA_params.IV_hdate.end = '04/04/2018'; % NOT USED
    DAA_params.StartDay = Settings.FirstInvestmentDate;
    DAA_params.Horizon = Settings.InvestmentHorizonDays./252; % TO CONVERT IN YEARFRACT
    DAA_params.NumPortf = Settings.PortfoliosOnEfficientFrontier;
    DAA_params.Budget = Settings.Budget;
    DAA_params.use_rank_corr = 0; % NOT USED
    DAA_params.Hcharts = 0; % NOT USED
    DAA_params.tails_modelling_charts = 0;  % NOT USED
    DAA_params.calibrateTails = Settings.CalibrateTails;
    DAA_params.CentralValuesModel = Settings.CentralValuesModel.Val;
    DAA_params.ConstantTailsThreshold = Settings.ConstantTailsThreshold;
    DAA_params.MinTailSize  = Settings.MinTailOccurences;
    DAA_params.ConfLevel4TailCutoffOptim = 0.9; % NOT USED
    DAA_params.copula_sim = Settings.CopulaEstimation;
    DAA_params.useTcopula = Settings.UseTcopula;
    DAA_params.simbound = 50; % NOT USED
    DAA_params.MCsimLimSetting = Settings.MCsimulationsLimit.Val;
    DAA_params.ProbThreshold4MC = Settings.ProbabilityThresholdForMC;
    DAA_params.copula_NoSim = Settings.CopulaSpaceSimulations;
    DAA_params.ProjectionResampling_numsim = Settings.ProjectionResamplingSimulations;
    DAA_params.FullHist4TailsEstimation = Settings.UseFullHistoryForTailsEstimation;
    if Settings.ExpandingPriorWindow
        DAA_params.Priori_MovWin = 0;
    else 
        DAA_params.Priori_MovWin = Settings.PriorMovingWindowDays;
    end
    DAA_params.Priori_IntialLookback = Settings.PriorInitialLookBackDays;
    DAA_params.MinFreqOfPriorUpdate = Settings.MinFrequencyOfPriorUpdateDays;
    DAA_params.min_interval_changes = Settings.MinIntervalChangesDays;
    DAA_params.ARMAGARCH = Settings.ArmaGarch;
    DAA_params.ARMAGARCH_movWin = Settings.ARMAGARCH_movWin;
    DAA_params.chunksLength = Settings.ChunksLength;
    DAA_params.cleanGARCH = Settings.CleanGarchCalibration;
    DAA_params.QuantSignals = Settings.QuantSignals;
    DAA_params.QuantStrategyName = Settings.QuantStrategyName;
    DAA_params.SubjectiveViews = Settings.SubjectiveViews;
    DAA_params.SubjectiveViewsWeight = Settings.SubjectiveViewsWeight;
    DAA_params.QViewsWeight = Settings.QuantViewsWeight;
    DAA_params.PriorWeight = Settings.PriorWeight;
    DAA_params.copula_rho = 1; % NOT USED
    DAA_params.RiskBudgeting = Settings.RiskParity;
    DAA_params.MaxReturn4FullFrontier_MV = Settings.MaxReturnForMVoptimization;
    DAA_params.resampling_EffFront.flag = false(1); % NOT USED
    DAA_params.resampling_EffFront.nsim = 200; % NOT USED
    DAA_params.ExpectedShortfall_EF = Settings.MESoptimization;
    DAA_params.ExpectedShortfall_EF_options.MaxRisk4FullES_Frontier = Settings.MaxRiskFullEfficeintFrontierOptimization;
    if Settings.MESoptimization
        if Settings.MaxRiskFullEfficeintFrontierOptimization
            DAA_params.ExpectedShortfall_EF_options.SingleRet = Settings.ReturnValueForSingleReturnMESoptimization;
            DAA_params.ExpectedShortfall_EF_options.SingleES = Settings.ESvalueForSingleESMESoptimization;
            DAA_params.ExpectedShortfall_EF_options.GMES = Settings.ESglobalMinimumPortfolio;
        else
            if Settings.ESglobalMinimumPortfolio
                DAA_params.ExpectedShortfall_EF_options.SingleRet = [];
                DAA_params.ExpectedShortfall_EF_options.SingleES = [];
            else
                DAA_params.ExpectedShortfall_EF_options.GMES = [];
                if strcmp(Settings.ReturnES,'Return')
                    DAA_params.ExpectedShortfall_EF_options.SingleRet = Settings.ReturnValueForSingleReturnMESoptimization;
                    DAA_params.ExpectedShortfall_EF_options.SingleES = [];
                else
                    DAA_params.ExpectedShortfall_EF_options.SingleRet = [];
                    DAA_params.ExpectedShortfall_EF_options.SingleES = Settings.ESvalueForSingleESMESoptimization;
                end
            end
        end
    else
        DAA_params.ExpectedShortfall_EF_options.SingleRet = [];
        DAA_params.ExpectedShortfall_EF_options.SingleES = [];
        DAA_params.ExpectedShortfall_EF_options.GMES = [];
    end
    DAA_params.ExpectedShortfall_EF_options.ConfLevel = Settings.ESandVaRconfidenceLevel;
    DAA_params.ExpectedShortfall_EF_options.LinearizedOptimizer = Settings.UseLinearizedOptimizer;
    DAA_params.ExpectedShortfall_EF_options.LinProgAlgo = Settings.LinearizedOptimizerType.Val;
    DAA_params.ExpectedShortfall_EF_options.onFullHistDataSet = Settings.ComputeESonHistoricalData;
    if Settings.NoConstraint
        DAA_params.ConstrainedTotWgts = [];
    elseif Settings.GetfromcurrentPTF
        DAA_params.ConstrainedTotWgts = true(1);
    else
        DAA_params.ConstrainedTotWgts = Settings.TotalWeightsConstraint;
    end
    if Settings.NoConstraint_MNE
        DAA_params.MinNetExposure = [];
    elseif Settings.GetfromcurrentPTF_MNE
        DAA_params.MinNetExposure = true(1);
    else
        if Settings.NoConstraint
            DAA_params.MinNetExposure = Settings.MinNetExposure;
        else
            DAA_params.MinNetExposure = [];
        end
    end
    DAA_params.MaxLongShortExposure = [Settings.MaxLongExposureByAsset, Settings.MaxShortExposureByAsset];
    DAA_params.MinAbsShort_Exposure = Settings.AbsoluteMaxShortExposure;
    DAA_params.MaxAbsLong_Exposure = Settings.AbsoluteMaxLongExposure;
    DAA_params.AA_OptimChangeTarget.flag = Settings.ChangeOptimizationTargetWithNoConvergence;
    DAA_params.AA_OptimChangeTarget.limit = Settings.MaxTargetRisk;
    DAA_params.AA_OptimChangeTarget.step = Settings.OptimizationRiskStep;
    DAA_params.granularity = Settings.Granularity;
    DAA_params.params_Equity_ret.lag = Settings.EquityRetLag;
    DAA_params.params_Equity_ret.pct = Settings.EquityRelativeReturns;
    DAA_params.params_Equity_ret.logret = Settings.UseLogReturnsForEquity;
    DAA_params.params_Equity_ret.last_roll = 0; % NOT USED
    DAA_params.params_Equity_ret.EliminateFlag = Settings.EraseRollingDatesReturnsForEquity;
    DAA_params.params_Equity_ret.ExtendedLag = Settings.EquityRetExtendedLag;
    DAA_params.params_cds_ret.lag = Settings.CDSretLag;
    DAA_params.params_cds_ret.pct = Settings.CDSrelativeReturns;
    DAA_params.params_cds_ret.logret = Settings.UseLogReturnsForCDS;
    DAA_params.params_cds_ret.last_roll = 0; % NOT USED
    DAA_params.params_cds_ret.EliminateFlag = Settings.EraseRollingDatesReturnsForCDS;
    DAA_params.params_cds_ret.ExtendedLag = Settings.CDSretExtendedLag;
    DAA_params.additional_params.quickCDS = Settings.QuickCDSrepricing;
    DAA_params.additional_params.quickCDS_SDV01_recalcFreq = Settings.QuickCDSrepricingFrequency;
    DAA_params.proxyFileName_Equity = Settings.ProxyFileName;
    DAA_params.output4PdfReports = Settings.OutputForPdfReports;
    if Settings.ExpandingHVarWindow
        DAA_params.HVaRWindow = 0;
    else
        DAA_params.HVaRWindow = Settings.HVarWindowDays;
    end
    DAA_params.MargRisk = [Settings.MarginalRiskByAssetType,Settings.MarginalRiskByCountry,Settings.MarginalRiskBySector,Settings.MarginalRiskBySingleAsset];
    DAA_params.confLevelUsed4xlsOutput = Settings.ConfidenceLevelUsedForXlsOutput;
    DAA_params.equityDashBoardPathAndFileName = Settings.DashboardPathAndFileName;
    DAA_params.equityPTFToInvUniveresePathAndFileName = Settings.EquityPTFToInvUpathAndFileName;
    DAA_params.investmentUniversePathAndFileName = Settings.InvestmentUniversePathAndFileName;
    DAA_params.outRiskExcel = Settings.OutRiskMeasuresPathAndFileName;
    DAA_params.ReportDir = [Settings.ReportDirectoryPath '\'];
    % TODO: add this paths to GUI 
    DAA_params.CDSfilename = [cd '\Inputs\CDS_MarketData.xlsm'];
    DAA_params.HistBstrappedCurves = [cd '\HistBstrappedCurves\'];
    DAA_params.VolaSurfacesObjects = [cd '\VolaSurfacesObjects\'];
    DAA_params.ARGARCH = [cd '\ARGARCH\'];
    DAA_params.outRiskExcel = 'X:\SalaOp\EquityPTF\Dashboard\outRiskExcel\outputRisk.xlsx';
    DAA_params.impliedVolaMapPath = [cd '\Inputs\ImpliedVolaHashedMap\'];
end