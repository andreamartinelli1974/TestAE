function out = myoutRiskExcel(R)
% by F. Saporito (02.05.2018)

    % Flag for silent execution (no printing)
    silent_exec = false;
    
    if not(silent_exec)
        disp('');
        disp('');
        disp('###############################################');
        disp('outRiskExcel');
        disp('###############################################');
        disp('');
    end

    % Debug option, save risk object
    % if not(silent_exec)
    %   disp('Saving current RiskAnalytics Object to riskSaved.mat file');
    % end
    % save('riskSaved','R');

    % Input/Output Parameters
    % outFile = 'outputRisk.xlsx';
    % matPath = 'C:\Users\fsapo\Documents\Github\objects4ReportsMgmt\'; % debug
    % out = [matPath, outFile];
    out = R.params_AA.outRiskExcel;
    if not(silent_exec)
        disp(['Output File Path: ', out]);
    end

    % Input/Output Parameters
    % Load Saved Structure
    % matPath = 'C:\Users\fsapo\Documents\Github\objects4ReportsMgmt\';
    % out = [matPath, outFile];
    % matName = 'RiskAnalytics_Gatelab1_20180305';
    % loadedStruct = load([matPath, matName, '.mat']);
    % R = loadedStruct.(matName);

    % Historical Risk Sheet Name
    sheetHist = 'HistRisk';

    % Parametric Risk Sheet Name
    sheetPar = 'ParRisk';

    % Exception Sheet Name
    sheetException = 'Exceptions';

    % Scenario List Sheet Name
    sheetScenarioNames = 'ScenarioList';

    % Current Scenario Name
    %scenarioName = 'Scen1'
    scenarioName = R.ScenarioLabel.posterior;
    if isempty(scenarioName)
        scenarioName = 'No Scenario'; % it means that the AA has been launched without any scenario
    end

    % Current Full Scenario Name
    scenarioNameFull = R.ScenarioLabel.posteriorAllSingleAssetsViews;
    if isempty(scenarioNameFull)
        scenarioNameFull = 'No Scenario'; % it means that the AA has been launched without any scenario
    end
    if not(silent_exec)
        disp(['Full Scenario Name: ', scenarioNameFull]);
    end
    
    
    % Confidence Array (Scale 0-100)
    conf = 100*R.VaR_ES_confLevels;
    if not(silent_exec)
        confStr = num2str(conf(1)/100);
        for i=2:length(conf)
            confStr = [confStr, ', ', num2str(conf(i)/100)];
        end 
        disp(['Confidences:  [', confStr, ']']);
    end
    
    % Parametric Thresholds For STD computation
    parametric_thresholds = abs(norminv(1 - R.VaR_ES_confLevels));


    % Portfolio Name List
    ptfNames = cellstr(R.Output.PortfolioRiskMeasures.CurrentPtf. ...
        HistSim.HistScenariosProb.AtHorizon.PtfLevel. ...
        marginal_VaR{1, 1}.assetClass.typologyMap);
    global_name = cellstr(['Global Ptf_',strjoin(sort(ptfNames),'_')]);
    ptfNames = [global_name, ptfNames];
    if not(silent_exec)
        disp('Portfolios List:');
        disp(ptfNames);
    end
    
    
    if not(silent_exec)
        disp('');
        disp('Reading Risk Measures:');
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Historical VaR and ES
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if not(silent_exec)
        disp('	- Historical Risks');
    end
    
    VaRH_name = 'VaR_H';
    VaRH_name_conf = R.concatenate(VaRH_name, conf);
    VaRH = R.Output.PortfolioRiskMeasures.CurrentPtf. ...
        HistSim.HistScenariosProb.OnePeriod.PtfLevel.VaR;
    VaRH_Single_Ptf = [R.Output.PortfolioRiskMeasures.CurrentPtf. ...
        HistSim.HistScenariosProb.AtHorizon.PtfLevel. ...
        marginal_VaR{1, 1}.assetClass.data_SinglePtf; ...
        R.Output.PortfolioRiskMeasures.CurrentPtf. ...
        HistSim.HistScenariosProb.AtHorizon.PtfLevel. ...
        marginal_VaR{2, 1}.assetClass.data_SinglePtf]';
    VaRH = [VaRH; VaRH_Single_Ptf]; % Add global ptf risks to single portfolios

    ESH_name = 'ES_H';
    ESH_name_conf = R.concatenate(ESH_name, conf);
    ESH = R.Output.PortfolioRiskMeasures.CurrentPtf. ...
        HistSim.HistScenariosProb.OnePeriod.PtfLevel.ES;
    ESH_Single_Ptf = [R.Output.PortfolioRiskMeasures.CurrentPtf. ...
        HistSim.HistScenariosProb.AtHorizon.PtfLevel. ...
        marginal_ES{1, 1}.assetClass.data_SinglePtf; ...
        R.Output.PortfolioRiskMeasures.CurrentPtf. ...
        HistSim.HistScenariosProb.AtHorizon.PtfLevel. ...
        marginal_ES{2, 1}.assetClass.data_SinglePtf]';
    ESH = [ESH; ESH_Single_Ptf]; % Add global ptf risks to single portfolios

    VaRHM_name = 'VaR_H_Marginal';
    VaRHM_name_conf = R.concatenate(VaRHM_name, conf);
    VaRHM = [R.Output.PortfolioRiskMeasures.CurrentPtf. ...
        HistSim.HistScenariosProb.AtHorizon.PtfLevel. ...
        marginal_VaR{1, 1}.assetClass.data; ...
        R.Output.PortfolioRiskMeasures.CurrentPtf. ...
        HistSim.HistScenariosProb.AtHorizon.PtfLevel. ...
        marginal_VaR{2, 1}.assetClass.data]';

    VaRHM = [0, 0; VaRHM]; % Add 0 for global ptf Marginals

    ESHM_name = 'ES_H_Marginal';
    ESHM_name_conf = R.concatenate(ESHM_name, conf);
    ESHM = [R.Output.PortfolioRiskMeasures.CurrentPtf. ...
        HistSim.HistScenariosProb.AtHorizon.PtfLevel. ...
        marginal_ES{1, 1}.assetClass.data; ...
        R.Output.PortfolioRiskMeasures.CurrentPtf. ...
        HistSim.HistScenariosProb.AtHorizon.PtfLevel. ...
        marginal_ES{2, 1}.assetClass.data]';

    ESHM = [0, 0; ESHM]; % Add 0 for global ptf Marginals


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Parametric VaR and ES
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if not(silent_exec)
        disp('	- Parametrical Risks and Standard Deviations');
    end
    
    VaR_Par_name = 'VaR_Par';
    VaR_Par_name_conf = R.concatenate(VaR_Par_name, conf);
    VaR_Par = R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                Parametric.HistScenariosProb.OnePeriod.PtfLevel.VaR;
    VaR_Par_Single_Ptf = [R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                            Parametric.HistScenariosProb.OnePeriod.PtfLevel. ...
                            marginal_VaR{1, 1}.assetClass.data_SinglePtf; ...
                          R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                            Parametric.HistScenariosProb.OnePeriod.PtfLevel. ...
                            marginal_VaR{2, 1}.assetClass.data_SinglePtf]';
    VaR_Par = [VaR_Par; VaR_Par_Single_Ptf]; % Add global ptf risks to single portfolios

    ES_Par_name = 'ES_Par';
    ES_Par_name_conf = R.concatenate(ES_Par_name, conf);
    ES_Par = R.Output.PortfolioRiskMeasures.CurrentPtf. ...
               Parametric.HistScenariosProb.OnePeriod.PtfLevel.ES;
    ES_Par_Single_Ptf = [R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                           Parametric.HistScenariosProb.OnePeriod.PtfLevel. ...
                           marginal_ES{1, 1}.assetClass.data_SinglePtf; ...
                        R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                          Parametric.HistScenariosProb.OnePeriod.PtfLevel. ...
                          marginal_ES{2, 1}.assetClass.data_SinglePtf]';
    ES_Par = [ES_Par; ES_Par_Single_Ptf]; % Add global ptf risks to single portfolios



    STD_name = 'STD';
    STD_name_conf = R.concatenate(STD_name, conf);
    STD =  VaR_Par ./ parametric_thresholds;

    STD_Time2_name = 'STD_X2_';
    STD_Time2_name_conf = R.concatenate(STD_Time2_name, conf);
    STD_Time2 = 2 .* STD;
    
    
    VaR_Par_Prior_name = 'VaR_Par_Prior';
    VaR_Par_Prior_name_conf = R.concatenate(VaR_Par_Prior_name, conf);
    VaR_Par_Prior = R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                      Parametric.PriorProb.AtHorizon.PtfLevel.VaR;
    VaR_Par_Prior_Single_Ptf = [R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                                  Parametric.PriorProb.AtHorizon.PtfLevel. ...
                                  marginal_VaR{1, 1}.assetClass.data_SinglePtf; ...
                                R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                                  Parametric.PriorProb.AtHorizon.PtfLevel. ...
                                  marginal_VaR{2, 1}.assetClass.data_SinglePtf]';
    VaR_Par_Prior = [VaR_Par_Prior; VaR_Par_Prior_Single_Ptf]; % Add global ptf risks to single portfolios

    ES_Par_Prior_name = 'ES_Par_Prior';
    ES_Par_Prior_name_conf = R.concatenate(ES_Par_Prior_name, conf);
    ES_Par_Prior = R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                     Parametric.PriorProb.AtHorizon.PtfLevel.ES;
    ES_Par_Prior_Single_Ptf = [R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                                 Parametric.PriorProb.AtHorizon.PtfLevel. ...
                                 marginal_ES{1, 1}.assetClass.data_SinglePtf; ...
                                R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                                  Parametric.PriorProb.AtHorizon.PtfLevel. ...
                                  marginal_ES{2, 1}.assetClass.data_SinglePtf]';
    ES_Par_Prior = [ES_Par_Prior; ES_Par_Prior_Single_Ptf]; % Add global ptf risks to single portfolios
    
    
    VaR_Par_Posterior_name = 'VaR_Par_Posterior';
    VaR_Par_Posterior_name_conf = R.concatenate(VaR_Par_Posterior_name, conf);
    VaR_Par_Posterior = R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                          Parametric.PosteriorProb.AtHorizon.PtfLevel.VaR;
    VaR_Par_Posterior_Single_Ptf = [R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                                      Parametric.PosteriorProb.AtHorizon.PtfLevel. ...
                                      marginal_VaR{1, 1}.assetClass.data_SinglePtf; ...
                                   R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                                     Parametric.PosteriorProb.AtHorizon.PtfLevel. ...
                                     marginal_VaR{2, 1}.assetClass.data_SinglePtf]';
    VaR_Par_Posterior = [VaR_Par_Posterior; VaR_Par_Posterior_Single_Ptf]; % Add global ptf risks to single portfolios

    ES_Par_Posterior_name = 'ES_Par_Posterior';
    ES_Par_Posterior_name_conf = R.concatenate(ES_Par_Posterior_name, conf);
    ES_Par_Posterior = R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                         Parametric.PosteriorProb.AtHorizon.PtfLevel.ES;
    ES_Par_Posterior_Single_Ptf = [R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                                     Parametric.PosteriorProb.AtHorizon.PtfLevel. ...
                                     marginal_ES{1, 1}.assetClass.data_SinglePtf; ...
                                    R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                                      Parametric.PosteriorProb.AtHorizon.PtfLevel. ...
                                      marginal_ES{2, 1}.assetClass.data_SinglePtf]';
    ES_Par_Posterior = [ES_Par_Posterior; ES_Par_Posterior_Single_Ptf]; % Add global ptf risks to single portfolios
    

    % 		VaR_Par_M_name = 'VaR_Par_Marginal';
    % 		VaR_Par_M_name_conf = R.concatenate(VaR_Par_M_name, conf);
    % 		VaR_Par_M = [R.Output.PortfolioRiskMeasures.CurrentPtf. ...
    %                        Parametric.HistScenariosProb.AtHorizon.PtfLevel. ...
    %                        marginal_VaR{1, 1}.assetClass.data; ...
    %                      R.Output.PortfolioRiskMeasures.CurrentPtf. ...
    %                        Parametric.HistScenariosProb.AtHorizon.PtfLevel. ...
    %                        marginal_VaR{2, 1}.assetClass.data]';
    %
    %         VaR_Par_M = [0, 0; VaR_Par_M]; % Add 0 for global ptf Marginals
    %
    % 		ES_Par_M_name = 'ES_Par_Marginal';
    % 		ES_Par_M_name_conf = R.concatenate(ES_Par_M_name, conf);
    % 		ES_Par_M = [R.Output.PortfolioRiskMeasures.CurrentPtf. ...
    %                       Parametric.HistScenariosProb.AtHorizon.PtfLevel. ...
    %                       marginal_ES{1, 1}.assetClass.data; ...
    %                     R.Output.PortfolioRiskMeasures.CurrentPtf. ...
    %                       Parametric.HistScenariosProb.AtHorizon.PtfLevel. ...
    % 				      marginal_ES{2, 1}.assetClass.data]';
    %
    %         ES_Par_M = [0, 0; ES_Par_M]; % Add 0 for global ptf Marginals


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Simulated Risks Measures (Prior)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if not(silent_exec)
        disp('	- Simulated Risks (Prior)');
    end
    
    VaRS_Prior_name = 'VaR_Sim_Prior';
    VaRS_Prior_name_conf = R.concatenate(VaRS_Prior_name, conf);
    VaRS_Prior = R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                   Simulation.PriorProb.AtHorizon.PtfLevel.VaR;
    VaRS_Prior_SinglePtf = [R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                              Simulation.PriorProb.AtHorizon.PtfLevel. ...
                              marginal_VaR{1, 1}.assetClass.data_SinglePtf; ...
                            R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                              Simulation.PriorProb.AtHorizon.PtfLevel. ...
                              marginal_VaR{2, 1}.assetClass.data_SinglePtf]';
    VaRS_Prior = [VaRS_Prior; VaRS_Prior_SinglePtf]; % Add global ptf risks to single portfolios

    ESS_Prior_name = 'ES_Sim_Prior';
    ESS_Prior_name_conf = R.concatenate(ESS_Prior_name, conf);
    ESS_Prior = R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                  Simulation.PriorProb.AtHorizon.PtfLevel.ES;
    ESS_Prior_SinglePtf = [R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                             Simulation.PriorProb.AtHorizon.PtfLevel. ...
                             marginal_ES{1, 1}.assetClass.data_SinglePtf; ...
                           R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                             Simulation.PriorProb.AtHorizon.PtfLevel. ...
                             marginal_ES{2, 1}.assetClass.data_SinglePtf]';
    ESS_Prior = [ESS_Prior; ESS_Prior_SinglePtf]; % Add global ptf risks to single portfolios


    VaRSM_Prior_name = 'VaR_Sim_Prior_Marginal';
    VaRSM_Prior_name_conf = R.concatenate(VaRSM_Prior_name, conf);
    VaRSM_Prior = [R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                     Simulation.PriorProb.AtHorizon.PtfLevel. ...
                     marginal_VaR{1, 1}.assetClass.data; ...
                   R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                     Simulation.PriorProb.AtHorizon.PtfLevel. ...
                     marginal_VaR{2, 1}.assetClass.data]';
    VaRSM_Prior = [0, 0; VaRSM_Prior]; % Add 0 for global ptf Marginals

    ESSM_Prior_name = 'ES_Sim_Prior_Marginal';
    ESSM_Prior_name_conf = R.concatenate(ESSM_Prior_name, conf);
    ESSM_Prior = [R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                    Simulation.PriorProb.AtHorizon.PtfLevel. ...
                    marginal_ES{1, 1}.assetClass.data; ...
                  R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                    Simulation.PriorProb.AtHorizon.PtfLevel. ...
                    marginal_ES{2, 1}.assetClass.data]';
    ESSM_Prior = [0, 0; ESSM_Prior]; % Add 0 for global ptf Marginals



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Simulated Risks Measures (Posterior)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if not(silent_exec)
        disp('	- Simulated Risks (Posterior)');
    end
    
    VaRS_Posterior_name = 'VaR_Sim_Posterior';
    VaRS_Posterior_name_conf = R.concatenate(VaRS_Posterior_name, conf);
    VaRS_Posterior = R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                       Simulation.PosteriorProb.AtHorizon.PtfLevel.VaR;
    VaRS_Posterior_SinglePtf = [R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                                  Simulation.PosteriorProb.AtHorizon.PtfLevel. ...
                                  marginal_VaR{1, 1}.assetClass.data_SinglePtf; ...
                                R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                                  Simulation.PosteriorProb.AtHorizon.PtfLevel. ...
                                  marginal_VaR{2, 1}.assetClass.data_SinglePtf]';
    VaRS_Posterior = [VaRS_Posterior; VaRS_Posterior_SinglePtf]; % Add global ptf risks to single portfolios

    ESS_Posterior_name = 'ES_Sim_Posterior';
    ESS_Posterior_name_conf = R.concatenate(ESS_Posterior_name, conf);
    ESS_Posterior = R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                      Simulation.PosteriorProb.AtHorizon.PtfLevel.ES;
    ESS_Posterior_SinglePtf = [R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                                 Simulation.PosteriorProb.AtHorizon.PtfLevel. ...
                                 marginal_ES{1, 1}.assetClass.data_SinglePtf; ...
                               R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                                 Simulation.PosteriorProb.AtHorizon.PtfLevel. ...
                                 marginal_ES{2, 1}.assetClass.data_SinglePtf]';
    ESS_Posterior = [ESS_Posterior; ESS_Posterior_SinglePtf]; % Add global ptf risks to single portfolios


    VaRSM_Posterior_name = 'VaR_Sim_Posterior_Marginal';
    VaRSM_Posterior_name_conf = R.concatenate(VaRSM_Posterior_name, conf);
    VaRSM_Posterior = [R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                        Simulation.PosteriorProb.AtHorizon.PtfLevel. ...
                        marginal_VaR{1, 1}.assetClass.data; ...
                       R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                        Simulation.PosteriorProb.AtHorizon.PtfLevel. ...
                        marginal_VaR{2, 1}.assetClass.data]';

    VaRSM_Posterior = [0, 0; VaRSM_Posterior]; % Add 0 for global ptf Marginals

    ESSM_Posterior_name = 'ES_Sim_Posterior_Marginal';
    ESSM_Posterior_name_conf = R.concatenate(ESSM_Posterior_name, conf);
    ESSM_Posterior = [R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                        Simulation.PosteriorProb.AtHorizon.PtfLevel. ...
                        marginal_ES{1, 1}.assetClass.data; ...
                      R.Output.PortfolioRiskMeasures.CurrentPtf. ...
                        Simulation.PosteriorProb.AtHorizon.PtfLevel. ...
                        marginal_ES{2, 1}.assetClass.data]';

    ESSM_Posterior  = [0, 0; ESSM_Posterior]; % Add 0 for global ptf Marginals



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Exceptions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if not(silent_exec)
        disp('');
        disp('Reading Exceptions');
    end
    
    % CDS
    CDS = R.Output.Exceptions.Curves.CDS;
    if (isempty(CDS)) % No CDS
        CDS_Values = [];
        CDS_Exc = [];
    else % CDS Found
        CDS_Values = CDS(:, 1);
        if (size(CDS, 2) == 1) % No Exceptions Informations
            num = length(CDS_Values);
            CDS_Exc = cell(num,1);
            for i=1:num % Create an array of empty strings
                CDS_Exc{i} = '';
            end % End For i
        else % Exception Informations Present
            CDS_Exc = CDS(:, 2);
        end % End if-else
    end % End if-else

    RemovedAssets = R.Output.Exceptions.InvestmentUniverse.RemovedAssetLog;
    if (isempty(RemovedAssets)) % No RemovedAssets
        RemovedAssets_Values = [];
        RemovedAssets_Exc = [];
    else % RemovedAssets Found
        RemovedAssets_Values = RemovedAssets(:, 1);
        if (size(RemovedAssets, 2) == 1) % No Exceptions Informations
            num = length(RemovedAssets_Values);
            RemovedAssets_Exc = cell(num,1);
            for i=1:num % Create an array of empty strings
                RemovedAssets_Exc{i} = '';
            end % End For i
        else % Exception Informations Present
            RemovedAssets_Exc = RemovedAssets(:, 2);
        end % End if
    end % End if

    ExcludedAssets = R.Output.Exceptions.InvestmentUniverse.ExcludedAssetsLog;
    if (isempty(ExcludedAssets)) % No RemovedAssets
        ExcludedAssets_Values = [];
        ExcludedAssets_Exc = [];
    else % ExcludedAssets Found
        ExcludedAssets_Values = ExcludedAssets(:, 1);
        if (size(ExcludedAssets, 2) == 1) % No Exceptions Informations
            num = length(ExcludedAssets_Values);
            ExcludedAssets_Exc = cell(num,1);
            for i=1:num % Create an array of empty strings
                ExcludedAssets_Exc{i} = '';
            end % End For i
        else % Exception Informations Present
            ExcludedAssets_Exc = ExcludedAssets(:, 2);
        end % End if
    end % End if

    ExternalRisks = R.Output.Exceptions.ExternalRiskFactors;
    if (isempty(ExternalRisks)) % No ExternalRisks
        ExternalRisks_Values = [];
        ExternalRisks_Exc = [];
    else % ExternalRisks Found
        ExternalRisks_Values = ExternalRisks(:, 1);
        if (size(ExternalRisks, 2) == 1) % No Exceptions Informations
            num = length(ExternalRisks_Values);
            ExternalRisks_Exc = cell(num,1);
            for i=1:num % Create an array of empty strings
                ExternalRisks_Exc{i} = '';
            end % End For i
        else % Exception Informations Present
            ExternalRisks_Exc = ExternalRisks(:, 2);
        end % End if
    end % End if


    Err_Asset = [CDS_Values; ...
        RemovedAssets_Values; ...
        ExcludedAssets_Values; ...
        ExternalRisks_Values];

    Err_Exc = [CDS_Exc; ...
        RemovedAssets_Exc; ...
        ExcludedAssets_Exc; ...
        ExternalRisks_Exc];

    Error_Assets_Name = 'ErrorAssets';
    Exception_Type_Name = 'ExceptionType';


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Time and Date
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    [time, timeNoSpaces, date, dateNoSpaces] = timeStr();

    num = length(ptfNames);
    timeCell = cell(num,1);
    dateCell = cell(num,1);

    timeCell = repelem(str2num(timeNoSpaces), num)';
    dateCell = repelem(str2num(dateNoSpaces), num)';

    time_Name = 'Time';
    date_Name = 'Date';



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Cell Arrays
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if not(silent_exec)
        disp('Cell Arrays Creations');
    end
    
    % Cell Array with Historical Risks Values
    Values_Hist = num2cell([timeCell, dateCell, ...
        (R.Budget .* ... % This is to have monetized values
        [VaRH, ESH, ...
        VaRHM, ESHM])]);
    
    % Cell Array with Historical Risks Col Names
    Names_Hist = [time_Name, date_Name, ...
        VaRH_name_conf, ESH_name_conf, ...
        VaRHM_name_conf, ESHM_name_conf];

    % Cell Array with Parametric Risks Values
    Values_Parametric = num2cell([timeCell, dateCell, ...
        (R.Budget .* ... % This is to have monetized values
        [VaR_Par, ES_Par, ...
         STD, STD_Time2, ...
         VaR_Par_Prior, ES_Par_Prior, ...
         VaR_Par_Posterior, ES_Par_Posterior, ...
        ])]);

    % Cell Array with Parametric Risks Col Names
    Names_Parametric = [time_Name, date_Name, ...
                        VaR_Par_name_conf, ES_Par_name_conf, ...
                        STD_name_conf, STD_Time2_name_conf, ...
                        VaR_Par_Prior_name_conf, ES_Par_Prior_name_conf, ...
                        VaR_Par_Posterior_name_conf, ES_Par_Posterior_name_conf];

    % Cell Array with Simulated Risks Values
    Values_Risk = num2cell([timeCell, dateCell, ...
        (R.Budget .* ... % This is to have monetized values
        [VaRS_Prior, ESS_Prior, ...
        VaRS_Posterior, ESS_Posterior, ...
        VaRSM_Prior, ESSM_Prior, ...
        VaRSM_Posterior, ESSM_Posterior])]);
    
    % Cell Array with Simulated Risks Col Names
    Names_Risk = [time_Name, date_Name, ...
        VaRS_Prior_name_conf, ESS_Prior_name_conf, ...
        VaRS_Posterior_name_conf, ESS_Posterior_name_conf, ...
        VaRSM_Prior_name_conf, ESSM_Prior_name_conf, ...
        VaRSM_Posterior_name_conf, ESSM_Posterior_name_conf];
    
    % Cell Array with Exceptions Values (= Assets | Exc Type | Time | Date)
    num = length(Err_Asset);
    Values_E = [Err_Asset, ...
        Err_Exc, ...
        num2cell(repelem(str2num(timeNoSpaces), num)'), ...
        num2cell(repelem(str2num(dateNoSpaces), num)')];

    % Cell Array with Exceptions Col Names
    Names_E = {Error_Assets_Name, Exception_Type_Name, time_Name, date_Name};
    
    % Cell Array with Scenarios Values
    Values_Scen = {sheetHist, str2num(timeNoSpaces), str2num(dateNoSpaces); ...
        sheetPar, str2num(timeNoSpaces), str2num(dateNoSpaces); ...
        sheetException, str2num(timeNoSpaces), str2num(dateNoSpaces); ...
        sheetScenarioNames, str2num(timeNoSpaces), str2num(dateNoSpaces); ...
        scenarioNameFull, str2num(timeNoSpaces), str2num(dateNoSpaces)};

    % Cell Array with Scenarios Col Names
    Names_Scen_Col = {'FullScenarioName', ...
        time_Name, date_Name};
    
    % Cell Array with Scenarios Row Names
    Names_Scen_Row = {sheetHist, sheetPar, sheetException, ...
        sheetScenarioNames, scenarioName};

    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Final Tables
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    T_Hist = cell2table(Values_Hist, 'VariableNames', Names_Hist, 'RowNames', ptfNames);
    T_Hist.Properties.DimensionNames{1} = 'PTF';

    T_Parametric = cell2table(Values_Parametric, 'VariableNames', Names_Parametric, 'RowNames', ptfNames);
    T_Parametric.Properties.DimensionNames{1} = 'PTF';

    T_Risk = cell2table(Values_Risk, 'VariableNames', Names_Risk, 'RowNames', ptfNames);
    T_Risk.Properties.DimensionNames{1} = 'PTF';
    
    if isempty(Values_E)
        Values_Empty = cell(1,4);
        T_Exceptions = cell2table(Values_Empty, 'VariableNames', Names_E);
    else
        T_Exceptions = cell2table(Values_E, 'VariableNames', Names_E);
    end

    T_Scenarios = cell2table(Values_Scen, 'VariableNames', Names_Scen_Col, 'RowNames', Names_Scen_Row);
    T_Scenarios.Properties.DimensionNames{1} = 'SheetName';
    
    if not(silent_exec)
        disp('');
        disp('Tables Creation');
        disp('')
        T_Hist
        T_Parametric
        T_Risk
        T_Exceptions
        T_Scenarios
    end
   

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Excel Write
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    flagWrite = true;

    if flagWrite % If True Write Output to Excel File
           
        % Update Data With Old Files
        if exist(out, 'file')==2 % XLS Output File Already Exists
            
            if not(silent_exec)
                disp('');
                disp('Reading Pre-Existing Output File');
                disp('')
            end

            % Read XLS File Infos
            [~, sheetList] = xlsfinfo(out);

            % Update Scenario's Risk Data
            if any(strcmp(sheetList, scenarioName)) % Scenario Sheet Already Exists
                T_R_Old = readtable(out, 'Sheet', scenarioName, 'ReadRowNames', true);
                if (any(strcmp(T_R_Old.Properties.VariableNames, time_Name)) && ...
                        any(strcmp(T_R_Old.Properties.VariableNames, date_Name))) % Date and Time Exists
                    ports_new = T_Risk.Properties.RowNames; % List of all new portFolios
                    ports_new_ln = length(ports_new); % Number of all new portFolios
                    for i=1:ports_new_ln % Loop over every new portFolio
                        T_R_Old{ports_new{i}, :} = T_Risk{ports_new{i}, :};
                    end % End For over all new Portfolios
                    T_Risk = T_R_Old; % Switch Tables to reduce if/else branching
                end % End If Time and Date Set In Excel
            end % End If Scenario Exists

            % Update Historical Risks sheetHist
            if any(strcmp(sheetList, sheetHist)) % Scenario Sheet Already Exists
                T_H_Old = readtable(out, 'Sheet', sheetHist, 'ReadRowNames',true);
                if (any(strcmp(T_H_Old.Properties.VariableNames, time_Name)) && ...
                        any(strcmp(T_H_Old.Properties.VariableNames, date_Name))) % Date and Time Exists
                    ports_new = T_Hist.Properties.RowNames; % List of all new portFolios
                    ports_new_ln = length(ports_new); % Number of all new portFolios
                    for i=1:ports_new_ln % Loop over every read new portFolio
                        T_H_Old{ports_new{i}, :} = T_Hist{ports_new{i}, :}; % Update Old Table with New Values
                    end % End For over all old Portfolios
                    T_Hist = T_H_Old; % Switch Tables to reduce if/else branching
                end % End If Time and Date Set In Excel
            end % End If Historical Scenario Exists

            % Update Parametric Risks sheetPar
            if any(strcmp(sheetList, sheetPar)) % Scenario Sheet Already Exists
                T_P_Old = readtable(out, 'Sheet', sheetPar, 'ReadRowNames',true);
                if (any(strcmp(T_P_Old.Properties.VariableNames, time_Name)) && ...
                        any(strcmp(T_P_Old.Properties.VariableNames, date_Name))) % Date and Time Exists
                    ports_new = T_Parametric.Properties.RowNames; % List of all new portFolios
                    ports_new_ln = length(ports_new); % Number of all new portFolios
                    for i=1:ports_new_ln % Loop over every read new portFolio
                        T_P_Old{ports_new{i}, :} = T_Parametric{ports_new{i}, :}; % Update Old Table with New Values
                    end % End For over all old Portfolios
                    T_Parametric = T_P_Old; % Switch Tables to reduce if/else branching
                end % End If Time and Date Set In Excel
            end % End If Parametrical Scenario Exists

            % Update Exceptions
            if any(strcmp(sheetList, sheetException)) % Exception Sheet Already Exists
                [~,~,raw] = xlsread(out,sheetException); % Read Old Exceptions
                if ~isempty(raw) || size(raw,1) > 1 % Update if raw isn't empty and has more than 1 row
                    exc_old = raw(2:end, 1:4); % Remove names and further columns
                    Values_E = [exc_old; Values_E]; % Append new exceptions
                    T_Exceptions = cell2table(Values_E, 'VariableNames', Names_E); % Update Exceptions
                end
            end % End If Exception Sheet Exists

            % Update Scenario Names
            if any(strcmp(sheetList, sheetScenarioNames)) % Scenario Sheet Already Exists
                T_S_Old = readtable(out, 'Sheet', sheetScenarioNames, 'ReadRowNames',true);
                if (any(strcmp(T_S_Old.Properties.VariableNames, time_Name)) && ...
                        any(strcmp(T_S_Old.Properties.VariableNames, date_Name))) % Date and Time Exists
                    scen_new = T_Scenarios.Properties.RowNames; % List of all new scenarios
                    scen_new_ln = length(scen_new); % Number of all new scenarios
                    for i=1:scen_new_ln % Loop over every read new scenario
                        T_S_Old(scen_new{i}, :) = table2cell(T_Scenarios(scen_new{i}, :)); % Update Old Table with New Values
                    end % End For over all old scenarios
                    T_Scenarios = T_S_Old; % Switch Tables to reduce if/else branching
                end % End If Time and Date Set In Excel
            end % End If Parametrical Scenario Exists
            
             if not(silent_exec)
                disp('');
                disp('Updated Tables: ');
                disp('');
                T_Hist
                T_Parametric
                T_Risk
                T_Exceptions
                T_Scenarios
            end

        end % End If file Exist

        % Write Data To Excel File
        if not(silent_exec)
            disp(['Writing ', scenarioName, ' to Excel Output File']);
        end
        writetable(T_Hist, out, 'Sheet', sheetHist, 'WriteRowNames', true);
        writetable(T_Parametric, out, 'Sheet', sheetPar, 'WriteRowNames', true);
        writetable(T_Risk, out, 'Sheet', scenarioName, 'WriteRowNames', true);
        writetable(T_Exceptions, out, 'Sheet', sheetException);
        writetable(T_Scenarios, out, 'Sheet', sheetScenarioNames, 'WriteRowNames', true);


        % Delete default sheets:
        if not(silent_exec)
            disp('Cleaning output file:');
        end
        sheetNameEN = 'Sheet';
        sheetNameITA = 'Foglio';
        objExcel = actxserver('Excel.Application');
        objExcel.Workbooks.Open(out);
        for i=1:3
            try
                objExcel.ActiveWorkbook.Worksheets.Item([sheetNameEN, num2str(i)]).Delete;
            catch
                if not(silent_exec)
                    disp(['    - ', sheetNameEN, num2str(i), ' not found (So I dont need to delete it)']);
                end
            end
        end
        for i=1:3
            try
                objExcel.ActiveWorkbook.Worksheets.Item([sheetNameITA, num2str(i)]).Delete;
            catch
                if not(silent_exec)
                    disp(['    - ',sheetNameEN, num2str(i), ' not found (So I dont need to delete it)']);
                end
            end
        end
        % Save, close and clean up.
        objExcel.ActiveWorkbook.Save;
        objExcel.ActiveWorkbook.Close;
        objExcel.Quit;
        objExcel.delete;
    
    end % End If ExcelWrite Flag


end % outRiskExcel (F.sco)