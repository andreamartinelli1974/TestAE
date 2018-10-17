classdef SettingsEquityDesk_UI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        SettingsEquityDeskUIFigure      matlab.ui.Figure
        SaveMenu                        matlab.ui.container.Menu
        SaveCurrentSettingsMenu         matlab.ui.container.Menu
        SaveCurrentAsGlobalSetupMenu    matlab.ui.container.Menu
        TabGroup                        matlab.ui.container.TabGroup
        GeneralTab                      matlab.ui.container.Tab
        BackTestOnlyCheckBox            matlab.ui.control.CheckBox
        MarginalRiskByAssetTypeCheckBox  matlab.ui.control.CheckBox
        EquityRelativeReturnsCheckBox   matlab.ui.control.CheckBox
        UseLogReturnsForEquityCheckBox  matlab.ui.control.CheckBox
        EraseRollingDatesReturnsForEquityCheckBox  matlab.ui.control.CheckBox
        CDSrelativeReturnsCheckBox      matlab.ui.control.CheckBox
        UseLogReturnsForCDSCheckBox     matlab.ui.control.CheckBox
        EraseRollingDatesReturnsForCDSCheckBox  matlab.ui.control.CheckBox
        QuickCDSrepricingCheckBox       matlab.ui.control.CheckBox
        AllportfoliosListBoxLabel       matlab.ui.control.Label
        AllPortfoliosListBox            matlab.ui.control.ListBox
        PrtusedbydefaultListBoxLabel    matlab.ui.control.Label
        PrtUsedByDefaultListBox         matlab.ui.control.ListBox
        AddPortfolioButton              matlab.ui.control.Button
        RemovePortfolioButton           matlab.ui.control.Button
        AddDefaultPortfolioButton       matlab.ui.control.Button
        RemoveDefualtPortfolioButton    matlab.ui.control.Button
        PortfolioToAddEditField         matlab.ui.control.EditField
        DefaultPrtToAddEditField        matlab.ui.control.EditField
        SetupDropDownLabel              matlab.ui.control.Label
        SetupListDropDown               matlab.ui.control.DropDown
        MarginalRiskByCountryCheckBox   matlab.ui.control.CheckBox
        MarginalRiskBySectorCheckBox    matlab.ui.control.CheckBox
        MarginalRiskBySingleAssetCheckBox  matlab.ui.control.CheckBox
        InvestmentuniversesheetnameEditFieldLabel  matlab.ui.control.Label
        InvestmentUniverseSheetNameEditField  matlab.ui.control.EditField
        InvestmenthorizondaysLabel      matlab.ui.control.Label
        InvestmentHorizonDaysEditField  matlab.ui.control.NumericEditField
        PriormovingwindowdaysEditFieldLabel  matlab.ui.control.Label
        PriorMovingWindowDaysEditField  matlab.ui.control.NumericEditField
        PriorinitiallookbackdaysEditFieldLabel  matlab.ui.control.Label
        PriorInitialLookBackDaysEditField  matlab.ui.control.NumericEditField
        MinfrequencyofpriorupdatedaysEditFieldLabel  matlab.ui.control.Label
        MinFrequencyOfPriorUpdateDaysEditField  matlab.ui.control.NumericEditField
        MinintervalchangesdaysEditFieldLabel  matlab.ui.control.Label
        MinIntervalChangesDaysEditField  matlab.ui.control.NumericEditField
        GranularityEditFieldLabel       matlab.ui.control.Label
        GranularityEditField            matlab.ui.control.EditField
        ProxyfilenameEditFieldLabel     matlab.ui.control.Label
        ProxyFileNameEditField          matlab.ui.control.EditField
        HVarwindowdaysEditFieldLabel    matlab.ui.control.Label
        HVarWindowDaysEditField         matlab.ui.control.NumericEditField
        GeneralLabel                    matlab.ui.control.Label
        BudgetEditFieldLabel            matlab.ui.control.Label
        BudgetEditField                 matlab.ui.control.NumericEditField
        ExpandingPriorWindowCheckBox    matlab.ui.control.CheckBox
        ExpandingHVarWindowCheckBox     matlab.ui.control.CheckBox
        EquityretextendedlagEditField_2Label  matlab.ui.control.Label
        EquityRetExtendedLagEditField   matlab.ui.control.NumericEditField
        EquityretlagEditFieldLabel      matlab.ui.control.Label
        EquityRetLagEditField           matlab.ui.control.NumericEditField
        CDSretlagEditFieldLabel         matlab.ui.control.Label
        CDSretLagEditField              matlab.ui.control.NumericEditField
        CDSretextendedlagEditFieldLabel  matlab.ui.control.Label
        CDSretExtendedLagEditField      matlab.ui.control.NumericEditField
        QuickCDSrepricingfrequencyEditFieldLabel  matlab.ui.control.Label
        QuickCDSrepricingFrequencyEditField  matlab.ui.control.NumericEditField
        RiskAnalysisCheckBox            matlab.ui.control.CheckBox
        RemoveselectedsetupButton       matlab.ui.control.Button
        LagforAAenforcementLabel        matlab.ui.control.Label
        Lag4AA_enforcementEditField     matlab.ui.control.NumericEditField
        DatesTab                        matlab.ui.container.Tab
        MinhistorystartdateEditFieldLabel  matlab.ui.control.Label
        MinHistoryStartDateEditField    matlab.ui.control.EditField
        HistorystartdateEditFieldLabel  matlab.ui.control.Label
        HistoryStartDateEditField       matlab.ui.control.EditField
        HistroyenddateEditFieldLabel    matlab.ui.control.Label
        HistoryEndDateEditField         matlab.ui.control.EditField
        FirstinvestmentdateEditFieldLabel  matlab.ui.control.Label
        FirstInvestmentDateEditField    matlab.ui.control.EditField
        DatesLabel                      matlab.ui.control.Label
        ViewsTab                        matlab.ui.container.Tab
        QuantSignalsCheckBox            matlab.ui.control.CheckBox
        QuantstrategynameEditFieldLabel  matlab.ui.control.Label
        QuantStrategyNameEditField      matlab.ui.control.EditField
        SubjectiveViewsCheckBox         matlab.ui.control.CheckBox
        SubjectiveviewsweightEditFieldLabel  matlab.ui.control.Label
        SubjectiveViewsWeightEditField  matlab.ui.control.NumericEditField
        QuantviewsweightEditFieldLabel  matlab.ui.control.Label
        QuantViewsWeightEditField       matlab.ui.control.NumericEditField
        PriorweightEditFieldLabel       matlab.ui.control.Label
        PriorWeightEditField            matlab.ui.control.NumericEditField
        ViewsLabel                      matlab.ui.control.Label
        DistributionModelTab            matlab.ui.container.Tab
        CalibrateTailsCheckBox          matlab.ui.control.CheckBox
        ConstanttailsthresholdEditFieldLabel  matlab.ui.control.Label
        ConstantTailsThresholdEditField  matlab.ui.control.NumericEditField
        CentralvaluesmodelDropDownLabel  matlab.ui.control.Label
        CentralValuesModelDropDown      matlab.ui.control.DropDown
        MintailoccurencesEditFieldLabel  matlab.ui.control.Label
        MinTailOccurencesEditField      matlab.ui.control.NumericEditField
        CopulaEstimationCheckBox        matlab.ui.control.CheckBox
        UseTcopulaCheckBox              matlab.ui.control.CheckBox
        MCsimulationslimitDropDownLabel  matlab.ui.control.Label
        MCsimulationsLimitDropDown      matlab.ui.control.DropDown
        ProbabilitythresholdforMCEditFieldLabel  matlab.ui.control.Label
        ProbabilityThresholdForMCEditField  matlab.ui.control.NumericEditField
        CopulaspacesimulationsEditFieldLabel  matlab.ui.control.Label
        CopulaSpaceSimulationsEditField  matlab.ui.control.NumericEditField
        ProjectionresamplingsimulationsEditFieldLabel  matlab.ui.control.Label
        ProjectionResamplingSimulationsEditField  matlab.ui.control.NumericEditField
        UseFullHistoryForTailsEstimationCheckBox  matlab.ui.control.CheckBox
        DistributionModelLabel          matlab.ui.control.Label
        OptimizationTab                 matlab.ui.container.Tab
        PortfoliosonefficientfrontierEditFieldLabel  matlab.ui.control.Label
        PortfoliosOnEfficientFrontierEditField  matlab.ui.control.NumericEditField
        MaxreturnforMVoptimizationEditFieldLabel  matlab.ui.control.Label
        MaxReturnForMVoptimizationEditField  matlab.ui.control.NumericEditField
        MESoptimizationCheckBox         matlab.ui.control.CheckBox
        ReturnvalueforsinglereturnMESoptimizationEditFieldLabel  matlab.ui.control.Label
        ReturnValueForSingleReturnMESoptimizationEditField  matlab.ui.control.NumericEditField
        ESvalueforsingleESMESoptimizationEditFieldLabel  matlab.ui.control.Label
        ESvalueForSingleESMESoptimizationEditField  matlab.ui.control.NumericEditField
        ESandVaRconfidencelevelEditFieldLabel  matlab.ui.control.Label
        ESandVaRconfidenceLevelEditField  matlab.ui.control.NumericEditField
        UseLinearizedOptimizerCheckBox  matlab.ui.control.CheckBox
        LinearizedoptimizertypeDropDownLabel  matlab.ui.control.Label
        LinearizedOptimizerTypeDropDown  matlab.ui.control.DropDown
        MaxriskfullefficeintfrontieroptimizationLabel  matlab.ui.control.Label
        MaxRiskFullEfficeintFrontierOptimizationEditField  matlab.ui.control.NumericEditField
        ESglobalMinimumPortfolioCheckBox  matlab.ui.control.CheckBox
        ComputeESonHistoricalDataCheckBox  matlab.ui.control.CheckBox
        TotalweightsconstraintEditFieldLabel  matlab.ui.control.Label
        TotalWeightsConstraintEditField  matlab.ui.control.NumericEditField
        MaxlongexposurebyassetEditFieldLabel  matlab.ui.control.Label
        MaxLongExposureByAssetEditField  matlab.ui.control.NumericEditField
        MaxshortexposurebyassetEditFieldLabel  matlab.ui.control.Label
        MaxShortExposureByAssetEditField  matlab.ui.control.NumericEditField
        AbsolutemaxshortexposureEditFieldLabel  matlab.ui.control.Label
        AbsoluteMaxShortExposureEditField  matlab.ui.control.NumericEditField
        AbsolutemaxlongexposureEditFieldLabel  matlab.ui.control.Label
        AbsoluteMaxLongExposureEditField  matlab.ui.control.NumericEditField
        ChangeOptimizationTargetWithNoConvergenceCheckBox  matlab.ui.control.CheckBox
        MaxtargetriskEditFieldLabel     matlab.ui.control.Label
        MaxTargetRiskEditField          matlab.ui.control.NumericEditField
        OptimizationriskstepEditFieldLabel  matlab.ui.control.Label
        OptimizationRiskStepEditField   matlab.ui.control.NumericEditField
        OptimizationLabel               matlab.ui.control.Label
        ReturnESSwitch                  matlab.ui.control.RockerSwitch
        NoConstraintCheckBox            matlab.ui.control.CheckBox
        RiskParityCheckBox              matlab.ui.control.CheckBox
        KeepcurrentPTFweightsCheckBox   matlab.ui.control.CheckBox
        NoConstraintCheckBox_MNE        matlab.ui.control.CheckBox
        MinNetExposureLabel             matlab.ui.control.Label
        MinNetExposureEditField         matlab.ui.control.NumericEditField
        GetfromcurrentPTFCheckBox       matlab.ui.control.CheckBox
        GetfromcurrentPTFCheckBox_MNE   matlab.ui.control.CheckBox
        ArmaGarchTab                    matlab.ui.container.Tab
        ArmaGarchCheckBox               matlab.ui.control.CheckBox
        ChunkslengthEditFieldLabel      matlab.ui.control.Label
        ChunksLengthEditField           matlab.ui.control.NumericEditField
        CleanGarchCalibrationCheckBox   matlab.ui.control.CheckBox
        ArmaGarchLabel                  matlab.ui.control.Label
        MovingWindowEditFieldLabel      matlab.ui.control.Label
        ARMAGARCH_movWinEditField       matlab.ui.control.NumericEditField
        OutputTab                       matlab.ui.container.Tab
        OutputForPdfReportsCheckBox     matlab.ui.control.CheckBox
        OutputLabel                     matlab.ui.control.Label
        ConfidencelevelusedforxlsoutputEditFieldLabel  matlab.ui.control.Label
        ConfidenceLevelUsedForXlsOutputEditField  matlab.ui.control.NumericEditField
        PathsTab                        matlab.ui.container.Tab
        DashboardBrowseButton           matlab.ui.control.Button
        EquityPTFToInvUniverseBrowseButton  matlab.ui.control.Button
        InvestmentUniverseBrowseButton  matlab.ui.control.Button
        OutputRiskBrowseButton          matlab.ui.control.Button
        DashboardLabel                  matlab.ui.control.Label
        DashboardPathAndFileNameEditField  matlab.ui.control.EditField
        EquityPTFToInvUniverseLabel     matlab.ui.control.Label
        EquityPTFToInvUpathAndFileNameEditField  matlab.ui.control.EditField
        InvestmentUniverseLabel         matlab.ui.control.Label
        InvestmentUniversePathAndFileNameEditField  matlab.ui.control.EditField
        OutputRiskMeasuresLabel         matlab.ui.control.Label
        OutRiskMeasuresPathAndFileNameEditField  matlab.ui.control.EditField
        PathsLabel                      matlab.ui.control.Label
        ReportDirectoryLabel            matlab.ui.control.Label
        ReportDirectoryPathEditField    matlab.ui.control.EditField
        ReportDirectoryBrowseButton     matlab.ui.control.Button
    end

    properties (Access = public)
        AA_DashBoardApp % AA_DashBoard app
        PathsAndFilesNames % Table read from "pathsDefinitions.xls"
        Settings % Structure containing setup and files paths
        ExposureFlag % Flag to manage Constrained total weight ann Min Net Exposure Relations
        ExposureFlagMNE % Flag to manage Constrained total weight ann Min Net Exposure Relations
    end

    methods (Access = public)
        
        % setComponentsValues function checks for all components types if any value has been saved
        % within componentValues structure, and assign them to the components.
        % If no component value has been saved in a app.Settings field, then a new app.Settings field is created and 
        % assigned the default value of the corresponding UI component.
        % N.B.: The settings structure fields names are strictly related to those given to the corresponding 
        % components of the UI (e.g., if component is "app.GranularityEditField", then the corresponding 
        % field is "app.Settings.Granularity", if component is "app.AllPortfoliosListBox", then the corresponding 
        % field is "app.Settings.AllPortfolios")
        function setComponentsValues(app,componentValues)
            settingsFieldsNames = fieldnames(app);
            for i=1:numel(settingsFieldsNames)
                if isa(app.(settingsFieldsNames{i}),'matlab.ui.control.CheckBox')
                    fieldName = strrep(settingsFieldsNames{i},'CheckBox','');
                    if ~isfield(componentValues,fieldName)   
                        componentValues.(fieldName) = app.(settingsFieldsNames{i}).Value;
                    else
                        app.(settingsFieldsNames{i}).Value = componentValues.(fieldName);
                    end
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.DropDown')
                    fieldName = strrep(settingsFieldsNames{i},'DropDown','');
                    if ~isfield(componentValues,fieldName)   
                        componentValues.(fieldName).Elements = app.(settingsFieldsNames{i}).Items;
                        componentValues.(fieldName).Val = app.(settingsFieldsNames{i}).Value;
                    else
                        app.(settingsFieldsNames{i}).Items = componentValues.(fieldName).Elements;
                        app.(settingsFieldsNames{i}).Value = componentValues.(fieldName).Val;
                    end
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.EditField')
                    fieldName = strrep(settingsFieldsNames{i},'EditField','');
                    if ~isfield(componentValues,fieldName)   
                        componentValues.(fieldName) = app.(settingsFieldsNames{i}).Value;
                    else
                        app.(settingsFieldsNames{i}).Value = componentValues.(fieldName);
                    end
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.NumericEditField')
                    fieldName = strrep(settingsFieldsNames{i},'EditField','');
                    if ~isfield(componentValues,fieldName)    
                        componentValues.(fieldName) = app.(settingsFieldsNames{i}).Value;
                    else
                        app.(settingsFieldsNames{i}).Value = componentValues.(fieldName);
                    end
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.Slider') 
                    fieldName = strrep(settingsFieldsNames{i},'Slider','');
                    if ~isfield(componentValues,fieldName)    
                        componentValues.(fieldName) = app.(settingsFieldsNames{i}).Value;
                    else
                        app.(settingsFieldsNames{i}).Value = componentValues.(fieldName);
                    end
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.Spinner') 
                    fieldName = strrep(settingsFieldsNames{i},'Spinner','');
                    if ~isfield(componentValues,fieldName)    
                        componentValues.(fieldName) = app.(settingsFieldsNames{i}).Value;
                    else
                        app.(settingsFieldsNames{i}).Value = componentValues.(fieldName);
                    end
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.Gauge') 
                    fieldName = strrep(settingsFieldsNames{i},'Gauge','');
                    if ~isfield(componentValues,fieldName)   
                        componentValues.(fieldName) = app.(settingsFieldsNames{i}).Value;
                    else
                        app.(settingsFieldsNames{i}).Value = componentValues.(fieldName);
                    end
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.NinetyDegreeGauge') 
                    fieldName = strrep(settingsFieldsNames{i},'NinetyDegreeGauge','');
                    if ~isfield(componentValues,fieldName)    
                        componentValues.(fieldName) = app.(settingsFieldsNames{i}).Value;
                    else
                        app.(settingsFieldsNames{i}).Value = componentValues.(fieldName);
                    end
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.LinearGauge')
                    fieldName = strrep(settingsFieldsNames{i},'LinearGauge','');
                    if ~isfield(componentValues,fieldName)   
                        componentValues.(fieldName) = app.(settingsFieldsNames{i}).Value;
                    else
                        app.(settingsFieldsNames{i}).Value = componentValues.(fieldName);
                    end
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.SemicircularGauge')
                    fieldName = strrep(settingsFieldsNames{i},'SemicircularGauge','');
                    if ~isfield(componentValues,fieldName)    
                        componentValues.(fieldName) = app.(settingsFieldsNames{i}).Value;
                    else
                        app.(settingsFieldsNames{i}).Value = componentValues.(fieldName);
                    end
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.Knob') 
                    fieldName = strrep(settingsFieldsNames{i},'Knob','');
                    if ~isfield(componentValues,fieldName)    
                        componentValues.(fieldName) = app.(settingsFieldsNames{i}).Value;
                    else
                        app.(settingsFieldsNames{i}).Value = componentValues.(fieldName);
                    end
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.Switch') 
                    fieldName = strrep(settingsFieldsNames{i},'Switch','');
                    if ~isfield(componentValues,fieldName)    
                        componentValues.(fieldName) = app.(settingsFieldsNames{i}).Value;
                    else
                        app.(settingsFieldsNames{i}).Value = componentValues.(fieldName);
                    end
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.RockerSwitch')
                    fieldName = strrep(settingsFieldsNames{i},'RockerSwitch','');
                    if ~isfield(componentValues,fieldName)    
                        componentValues.(fieldName) = app.(settingsFieldsNames{i}).Value;
                    else
                        app.(settingsFieldsNames{i}).Value = componentValues.(fieldName);
                    end
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.ToggleSwitch')
                    fieldName = strrep(settingsFieldsNames{i},'ToggleSwitch','');
                    if ~isfield(componentValues,fieldName)    
                        componentValues.(fieldName) = app.(settingsFieldsNames{i}).Value;
                    else
                        app.(settingsFieldsNames{i}).Value = componentValues.(fieldName);
                    end  
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.ListBox')
                    fieldName = strrep(settingsFieldsNames{i},'ListBox','');
                    if ~isfield(componentValues,fieldName)  
                        componentValues.(fieldName) = app.(settingsFieldsNames{i}).Items;
                    else
                        app.(settingsFieldsNames{i}).Items = componentValues.(fieldName);
                    end      
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.TextArea') 
                    fieldName = strrep(settingsFieldsNames{i},'TextArea','');
                    if ~isfield(componentValues,fieldName)    
                        componentValues.(fieldName) = app.(settingsFieldsNames{i}).Text;
                    else
                        app.(settingsFieldsNames{i}).Text = componentValues.(fieldName);
                    end   
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.Table')
                    fieldName = strrep(settingsFieldsNames{i},'Table','');
                    if ~isfield(componentValues,fieldName)    
                        componentValues.(fieldName) = app.(settingsFieldsNames{i}).Data;
                    else
                        app.(settingsFieldsNames{i}).Data = componentValues.(fieldName);
                    end
                end
            end
        end
    
        % Update settings structure with current UI components values
        function settings = updateSettings(app)
            settingsFieldsNames = fieldnames(app);
            for i=1:numel(settingsFieldsNames)
                if isa(app.(settingsFieldsNames{i}),'matlab.ui.control.CheckBox')
                    fieldName = strrep(settingsFieldsNames{i},'CheckBox','');
                    settings.(fieldName) = app.(settingsFieldsNames{i}).Value;
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.DropDown')
                    fieldName = strrep(settingsFieldsNames{i},'DropDown','');
                    settings.(fieldName).Elements = app.(settingsFieldsNames{i}).Items;
                    settings.(fieldName).Val = app.(settingsFieldsNames{i}).Value;
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.EditField')
                    fieldName = strrep(settingsFieldsNames{i},'EditField','');
                    settings.(fieldName) = app.(settingsFieldsNames{i}).Value;
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.NumericEditField')
                    fieldName = strrep(settingsFieldsNames{i},'EditField','');
                    settings.(fieldName) = app.(settingsFieldsNames{i}).Value;
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.Slider')
                    fieldName = strrep(settingsFieldsNames{i},'Slider','');
                    settings.(fieldName) = app.(settingsFieldsNames{i}).Value;
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.Spinner')
                    fieldName = strrep(settingsFieldsNames{i},'Spinner','');
                    settings.(fieldName) = app.(settingsFieldsNames{i}).Value;
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.Gauge')
                    fieldName = strrep(settingsFieldsNames{i},'Gauge','');
                    settings.(fieldName) = app.(settingsFieldsNames{i}).Value;
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.NinetyDegreeGauge')
                    fieldName = strrep(settingsFieldsNames{i},'NinetyDegreeGauge','');
                    settings.(fieldName) = app.(settingsFieldsNames{i}).Value;
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.LinearGauge')
                    fieldName = strrep(settingsFieldsNames{i},'LinearGauge','');
                    settings.(fieldName) = app.(settingsFieldsNames{i}).Value;
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.SemicircularGauge')
                    fieldName = strrep(settingsFieldsNames{i},'SemicircularGauge','');
                    settings.(fieldName) = app.(settingsFieldsNames{i}).Value;
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.Knob')
                    fieldName = strrep(settingsFieldsNames{i},'Knob','');
                    settings.(fieldName) = app.(settingsFieldsNames{i}).Value;
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.Switch')
                    fieldName = strrep(settingsFieldsNames{i},'Switch','');
                    settings.(fieldName) = app.(settingsFieldsNames{i}).Value;
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.RockerSwitch')
                    fieldName = strrep(settingsFieldsNames{i},'RockerSwitch','');
                    settings.(fieldName) = app.(settingsFieldsNames{i}).Value;
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.ToggleSwitch')
                    fieldName = strrep(settingsFieldsNames{i},'ToggleSwitch','');
                    settings.(fieldName) = app.(settingsFieldsNames{i}).Value;
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.ListBox')
                    fieldName = strrep(settingsFieldsNames{i},'ListBox','');
                    settings.(fieldName) = app.(settingsFieldsNames{i}).Items;
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.TextArea')
                    fieldName = strrep(settingsFieldsNames{i},'TextArea','');
                    settings.(fieldName) = app.(settingsFieldsNames{i}).Text;
                elseif isa(app.(settingsFieldsNames{i}),'matlab.ui.control.Table')
                    fieldName = strrep(settingsFieldsNames{i},'Table','');
                    settings.(fieldName) = app.(settingsFieldsNames{i}).Data;
                end
            end
        end
        
        % Give components values, this function set components relations. 
        % N.B.: this function simply executes all single components callbacks, so
        % when a new callback is added or a callback is modified, this must be updated
        function setComponentsRelations(app)
            app.ExposureFlag = 0;
            app.ExposureFlagMNE = 0;
            if app.ExpandingPriorWindowCheckBox.Value==true
                app.PriorMovingWindowDaysEditField.Enable = 'off';
                app.PriorInitialLookBackDaysEditField.Enable = 'on';
            else
                app.PriorMovingWindowDaysEditField.Enable = 'on';
                app.PriorInitialLookBackDaysEditField.Enable = 'off';
            end
            
            if app.ExpandingHVarWindowCheckBox.Value == true
                app.HVarWindowDaysEditField.Enable = 'off';
            else
                app.HVarWindowDaysEditField.Enable = 'on';
            end
            
            if app.QuickCDSrepricingCheckBox.Value == true
                app.QuickCDSrepricingFrequencyEditField.Enable = 'on';
            else
                app.QuickCDSrepricingFrequencyEditField.Enable = 'off';
            end
                
            
            if app.SubjectiveViewsCheckBox.Value == true
                app.SubjectiveViewsWeightEditField.Enable = 'on';
            else
                app.SubjectiveViewsWeightEditField.Enable = 'off';
            end
            
            if app.QuantSignalsCheckBox.Value == true
                app.QuantStrategyNameEditField.Enable = 'on';
                app.QuantViewsWeightEditField.Enable = 'on';
            else
                app.QuantStrategyNameEditField.Enable = 'off';
                app.QuantViewsWeightEditField.Enable = 'off';
            end
            
            if app.CalibrateTailsCheckBox.Value == true
                app.ConstantTailsThresholdEditField.Enable = 'off';
            else
                app.ConstantTailsThresholdEditField.Enable = 'on';
            end
            
            if app.CopulaEstimationCheckBox.Value == true
                app.UseTcopulaCheckBox.Enable = 'on';
            else
                app.UseTcopulaCheckBox.Enable = 'off';
            end
            
            if strcmp(app.MCsimulationsLimitDropDown.Value,'none')
                app.ProbabilityThresholdForMCEditField.Enable = 'off';
            elseif strcmp(app.MCsimulationsLimitDropDown.Value,'absprob')
                app.ProbabilityThresholdForMCEditField.Enable = 'on';
            end
            
            if app.MESoptimizationCheckBox.Value == true
                app.MaxReturnForMVoptimizationEditField.Enable = 'off'; 
                app.RiskParityCheckBox.Enable = 'off';
                app.RiskParityCheckBox.Value = false;
                app.MaxRiskFullEfficeintFrontierOptimizationEditField.Enable = 'on';
                if app.MaxRiskFullEfficeintFrontierOptimizationEditField.Value == 0
                    app.ESglobalMinimumPortfolioCheckBox.Enable = 'on';
                    if app.ESglobalMinimumPortfolioCheckBox.Value == false
                        app.ReturnESSwitch.Enable = 'on';
                        if strcmp(app.ReturnESSwitch.Value,'Return') 
                            app.ReturnValueForSingleReturnMESoptimizationEditField.Enable = 'on';
                            app.ESvalueForSingleESMESoptimizationEditField.Enable = 'off';
                        else
                            app.ReturnValueForSingleReturnMESoptimizationEditField.Enable = 'off';
                            app.ESvalueForSingleESMESoptimizationEditField.Enable = 'on';
                        end
                    end
                end    
            else
                app.MaxRiskFullEfficeintFrontierOptimizationEditField.Enable = 'off';
                app.ReturnESSwitch.Enable = 'off';                
                app.ReturnValueForSingleReturnMESoptimizationEditField.Enable = 'off';
                app.ESvalueForSingleESMESoptimizationEditField.Enable = 'off';
                app.ESglobalMinimumPortfolioCheckBox.Enable = 'off';
                app.MaxReturnForMVoptimizationEditField.Enable = 'on';
                app.RiskParityCheckBox.Enable = 'on';
            end
            
            if app.UseLinearizedOptimizerCheckBox.Value == true
                app.LinearizedOptimizerTypeDropDown.Enable = 'on';
            else
                app.LinearizedOptimizerTypeDropDown.Enable = 'off';
            end
            
            if app.ChangeOptimizationTargetWithNoConvergenceCheckBox.Value == true
                app.MaxTargetRiskEditField.Enable = 'on';
                app.OptimizationRiskStepEditField.Enable = 'on';
            else
                app.MaxTargetRiskEditField.Enable = 'off';
                app.OptimizationRiskStepEditField.Enable = 'off';
            end
            
            if app.NoConstraintCheckBox.Value
                app.ExposureFlag = 1;
                app.TotalWeightsConstraintEditField.Enable = 'off';
                app.GetfromcurrentPTFCheckBox.Enable = 'off';
                app.NoConstraintCheckBox_MNE.Enable = 'on';
                app.MinNetExposureEditField.Enable = 'on';
                app.GetfromcurrentPTFCheckBox_MNE.Enable = 'on';
            else
                app.TotalWeightsConstraintEditField.Enable = 'on';
                app.GetfromcurrentPTFCheckBox.Enable = 'on';
                if app.GetfromcurrentPTFCheckBox.Value
                    app.NoConstraintCheckBox.Enable = 'off';
                    app.TotalWeightsConstraintEditField.Enable = 'off';
                    app.NoConstraintCheckBox_MNE.Enable = 'off';
                    app.NoConstraintCheckBox_MNE.Value = 1;
                    app.MinNetExposureEditField.Enable = 'off';
                    app.GetfromcurrentPTFCheckBox_MNE.Enable = 'off';    
                end    
            end
            if app.NoConstraintCheckBox_MNE.Value
                app.ExposureFlag = 1;
                app.MinNetExposureEditField.Enable = 'off';
                app.GetfromcurrentPTFCheckBox_MNE.Enable = 'off';
                app.GetfromcurrentPTFCheckBox.Enable = 'on';
                if ~app.GetfromcurrentPTFCheckBox.Value
                    app.NoConstraintCheckBox.Enable = 'on';
                    app.TotalWeightsConstraintEditField.Enable = 'on';
                end
            else
                app.MinNetExposureEditField.Enable = 'on';
                app.GetfromcurrentPTFCheckBox_MNE.Enable = 'on';
                if app.GetfromcurrentPTFCheckBox_MNE.Value
                    app.NoConstraintCheckBox_MNE.Enable = 'off';
                    app.TotalWeightsConstraintEditField.Enable = 'off';
                    app.NoConstraintCheckBox.Enable = 'off';
                    app.NoConstraintCheckBox.Value = 1;
                    app.MinNetExposureEditField.Enable = 'off';
                    app.GetfromcurrentPTFCheckBox.Enable = 'off';
                end
            end
        end
    
    end

    methods (Access = private)
    
        
    end


    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, AA_DashBoardApp, AA_DashBoardSettings)
            % Get Information from AA_DashBoardApp
            app.AA_DashBoardApp = AA_DashBoardApp;
            app.Settings = AA_DashBoardSettings;
            % Set app components values with those coming from app.Settings
            setComponentsValues(app,app.Settings);
            % Set app components relations, given their values
            setComponentsRelations(app);
        end

        % Value changed function: SetupListDropDown
        function SetupListDropDownValueChanged(app, event)
            % On setup change, the selected setup structure is loaded and assigned to UI components
            selectedSetup = app.SetupListDropDown.Value;
            if ~isempty(selectedSetup)
                load(['UI_Data\setups\' selectedSetup '.mat'],'SettingsData');
                SettingsData{1}.SetupList.Elements = app.SetupListDropDown.Items;
                % Set app components values with those coming from SettingsData{1}
                setComponentsValues(app,SettingsData{1});
                % Update app.Settings values with those coming from the selected setup
                app.Settings = updateSettings(app);
                % Set app components relations, given their values
                setComponentsRelations(app);
            end
        end

        % Close request function: SettingsEquityDeskUIFigure
        function SettingsEquityDeskUIFigureCloseRequest(app, event)
            % Ask the user to confirm the action
            choice = questdlg('Do you want to use current settings?','Closing','Yes','No','Yes');
                
            if strcmp(choice,'Yes')
               % Update settings data structure 
               app.Settings = updateSettings(app);
               % Update settings in AA_DashBoardApp
               updateDashBoardAppSettings(app.AA_DashBoardApp,app.Settings);
               % Update portfolios list and default portfolios in AA_DashBoardUI
               updatePortfoliosDropDown(app.AA_DashBoardApp,app.Settings.AllPortfolios);
               updatePortfoliosList(app.AA_DashBoardApp,app.Settings.PrtUsedByDefault);
               
               warndlg('These settings will be valid only for the current session, and will be lost in case of Global Setup change','Current Settings Worning');
               uiwait
               
               % Re-enable AA_DashBoard components
               enableAA_DashBoardComponents(app.AA_DashBoardApp);
               % Close this app
               delete(app);
            elseif strcmp(choice,'No')
                % Re-Enable AA_DashBoardUI components
                enableAA_DashBoardComponents(app.AA_DashBoardApp);
                % Close this app
                delete(app);
            end   
        end

        % Button pushed function: DashboardBrowseButton
        function DashboardBrowseButtonPushed(app, event)
            % The user is asked to select a file, whose name is then edited
            [DashboardName,DashboardFolderName] = uigetfile('*.xl*');
            if DashboardName ~= 0
                DashboardName = fullfile(DashboardFolderName,DashboardName);
                app.DashboardPathAndFileNameEditField.Value = DashboardName;
            end
            app.SettingsEquityDeskUIFigure.Visible = 'off';
            app.SettingsEquityDeskUIFigure.Visible = 'on';
        end

        % Button pushed function: EquityPTFToInvUniverseBrowseButton
        function EquityPTFToInvUniverseBrowseButtonPushed(app, event)
            % The user is asked to select a file, whose name is then edited
            [EquityPTFToInvUnivName,EquityPTFToInvUnivFolderName] = uigetfile('*.xl*');
            if EquityPTFToInvUnivName ~= 0
                EquityPTFToInvUnivName = fullfile(EquityPTFToInvUnivFolderName,EquityPTFToInvUnivName);
                app.EquityPTFToInvUpathAndFileNameEditField.Value = EquityPTFToInvUnivName;
            end
            app.SettingsEquityDeskUIFigure.Visible = 'off';
            app.SettingsEquityDeskUIFigure.Visible = 'on';
        end

        % Button pushed function: InvestmentUniverseBrowseButton
        function InvestmentUniverseBrowseButtonPushed(app, event)
            [InvestmentUniverseName,InvestmentUniverseFolderName] = uigetfile('*.xl*');
            if InvestmentUniverseName ~= 0
                InvestmentUniverseName = fullfile(InvestmentUniverseFolderName,InvestmentUniverseName);
                app.InvestmentUniversePathAndFileNameEditField.Value = InvestmentUniverseName;
            end
            app.SettingsEquityDeskUIFigure.Visible = 'off';
            app.SettingsEquityDeskUIFigure.Visible = 'on';
        end

        % Button pushed function: OutputRiskBrowseButton
        function OutputRiskBrowseButtonPushed(app, event)
            [OutputRiskName,OutputRiskFolderName] = uigetfile('*.xl*');
            if OutputRiskName ~= 0
                OutputRiskName = fullfile(OutputRiskFolderName,OutputRiskName);
                app.OutRiskMeasuresPathAndFileNameEditField.Value = OutputRiskName;
            end
            app.SettingsEquityDeskUIFigure.Visible = 'off';
            app.SettingsEquityDeskUIFigure.Visible = 'on';
        end

        % Button pushed function: AddPortfolioButton
        function AddPortfolioButtonPushed(app, event)
            if ~isempty(app.PortfolioToAddEditField.Value)
                app.AllPortfoliosListBox.Items = [app.AllPortfoliosListBox.Items{:},{app.PortfolioToAddEditField.Value}];   
                app.PortfolioToAddEditField.Value = '';
            end
        end

        % Button pushed function: RemovePortfolioButton
        function RemovePortfolioButtonPushed(app, event)
            % If nothing in the list has been selected, then select the first item
            if isempty(app.AllPortfoliosListBox.Value)
                app.AllPortfoliosListBox.Value = app.AllPortfoliosListBox.Items(1);
            end    
            % If the portfolios list box is not empty, then the selected portfolio is removed from the list.
            if ~isempty(app.AllPortfoliosListBox.Items)
                SelectedPortfolioIndex = find(strcmp(app.AllPortfoliosListBox.Items,app.AllPortfoliosListBox.Value),1);
                app.AllPortfoliosListBox.Items(SelectedPortfolioIndex) = [];
            end   
        end

        % Button pushed function: AddDefaultPortfolioButton
        function AddDefaultPortfolioButtonPushed(app, event)
            if ~isempty(app.DefaultPrtToAddEditField.Value)
                app.PrtUsedByDefaultListBox.Items = [app.PrtUsedByDefaultListBox.Items{:},{app.DefaultPrtToAddEditField.Value}];   
                app.DefaultPrtToAddEditField.Value = '';
            end            
        end

        % Button pushed function: RemoveDefualtPortfolioButton
        function RemoveDefualtPortfolioButtonPushed(app, event)
            % If nothing in the list has been selected, then select the first item
            if isempty(app.PrtUsedByDefaultListBox.Value)
                app.PrtUsedByDefaultListBox.Value = app.PrtUsedByDefaultListBox.Items(1);
            end    
            % If the portfolios list box is not empty, then the selected portfolio is removed from the list.
            if ~isempty(app.PrtUsedByDefaultListBox.Items)
                SelectedPortfolioIndex = find(strcmp(app.PrtUsedByDefaultListBox.Items,app.PrtUsedByDefaultListBox.Value),1);
                app.PrtUsedByDefaultListBox.Items(SelectedPortfolioIndex) = [];
            end
        end

        % Value changed function: QuickCDSrepricingCheckBox
        function QuickCDSrepricingCheckBoxValueChanged(app, event)
            if app.QuickCDSrepricingCheckBox.Value == true
                app.QuickCDSrepricingFrequencyEditField.Enable = 'on';
            else
                app.QuickCDSrepricingFrequencyEditField.Enable = 'off';
            end
        end

        % Value changed function: SubjectiveViewsCheckBox
        function SubjectiveViewsCheckBoxValueChanged(app, event)
            if app.SubjectiveViewsCheckBox.Value == true
                app.SubjectiveViewsWeightEditField.Enable = 'on';
            else
                app.SubjectiveViewsWeightEditField.Enable = 'off';
                app.SubjectiveViewsWeightEditField.Value = 0;
                app.PriorWeightEditField.Value = 1 - app.QuantViewsWeightEditField.Value - app.SubjectiveViewsWeightEditField.Value;
            end
        end

        % Value changed function: QuantSignalsCheckBox
        function QuantSignalsCheckBoxValueChanged(app, event)
            if app.QuantSignalsCheckBox.Value == true
                app.QuantStrategyNameEditField.Enable = 'on';
                app.QuantViewsWeightEditField.Enable = 'on';
            else
                app.QuantStrategyNameEditField.Enable = 'off';
                app.QuantViewsWeightEditField.Enable = 'off';
                app.QuantViewsWeightEditField.Value = 0;
                app.PriorWeightEditField.Value = 1 - app.QuantViewsWeightEditField.Value - app.SubjectiveViewsWeightEditField.Value;
            end
        end

        % Value changed function: QuantViewsWeightEditField
        function QuantViewsWeightEditFieldValueChanged(app, event)
            priorWeigth = 1 - app.QuantViewsWeightEditField.Value - app.SubjectiveViewsWeightEditField.Value;
            if priorWeigth >= 0
                app.PriorWeightEditField.Value = priorWeigth;   
            else
                msg = msgbox('The sum of quantitative and subjective weigths cannot exceed 1');
                app.QuantViewsWeightEditField.Value = 0;
                app.PriorWeightEditField.Value = 1 - app.SubjectiveViewsWeightEditField.Value;
            end
        end

        % Value changed function: SubjectiveViewsWeightEditField
        function SubjectiveViewsWeightEditFieldValueChanged(app, event)
            priorWeigth = 1 - app.QuantViewsWeightEditField.Value - app.SubjectiveViewsWeightEditField.Value;
            if priorWeigth >= 0
                app.PriorWeightEditField.Value = priorWeigth;   
            else
                msg = msgbox('The sum of quantitative and subjective weigths cannot exceed 1');
                app.SubjectiveViewsWeightEditField.Value = 0;
                app.PriorWeightEditField.Value = 1 - app.QuantViewsWeightEditField.Value;
            end
        end

        % Value changed function: CalibrateTailsCheckBox
        function CalibrateTailsCheckBoxValueChanged(app, event)
            if app.CalibrateTailsCheckBox.Value == true
                app.ConstantTailsThresholdEditField.Enable = 'off';
            else
                app.ConstantTailsThresholdEditField.Enable = 'on';
            end
        end

        % Value changed function: CopulaEstimationCheckBox
        function CopulaEstimationCheckBoxValueChanged(app, event)
            if app.CopulaEstimationCheckBox.Value == true
                app.UseTcopulaCheckBox.Enable = 'on';
            else
                app.UseTcopulaCheckBox.Enable = 'off';
            end
        end

        % Value changed function: MCsimulationsLimitDropDown
        function MCsimulationsLimitDropDownValueChanged(app, event)
            if strcmp(app.MCsimulationsLimitDropDown.Value,'none')
                app.ProbabilityThresholdForMCEditField.Enable = 'off';
            elseif strcmp(app.MCsimulationsLimitDropDown.Value,'absprob')
                app.ProbabilityThresholdForMCEditField.Enable = 'on';                
            end
        end

        % Value changed function: MESoptimizationCheckBox
        function MESoptimizationCheckBoxValueChanged(app, event)
            if app.MESoptimizationCheckBox.Value == true
                app.MaxReturnForMVoptimizationEditField.Enable = 'off'; 
                app.RiskParityCheckBox.Enable = 'off';
                app.RiskParityCheckBox.Value = false;
                app.MaxRiskFullEfficeintFrontierOptimizationEditField.Enable = 'on';
                if app.MaxRiskFullEfficeintFrontierOptimizationEditField.Value == 0
                    app.ESglobalMinimumPortfolioCheckBox.Enable = 'on';
                    if app.ESglobalMinimumPortfolioCheckBox.Value == false
                        app.ReturnESSwitch.Enable = 'on';
                        if strcmp(app.ReturnESSwitch.Value,'Return') 
                            app.ReturnValueForSingleReturnMESoptimizationEditField.Enable = 'on';
                            app.ESvalueForSingleESMESoptimizationEditField.Enable = 'off';
                        else
                            app.ReturnValueForSingleReturnMESoptimizationEditField.Enable = 'off';
                            app.ESvalueForSingleESMESoptimizationEditField.Enable = 'on';
                        end
                    end
                end    
            else
                app.MaxRiskFullEfficeintFrontierOptimizationEditField.Enable = 'off';
                app.ReturnESSwitch.Enable = 'off';                
                app.ReturnValueForSingleReturnMESoptimizationEditField.Enable = 'off';
                app.ESvalueForSingleESMESoptimizationEditField.Enable = 'off';
                app.ESglobalMinimumPortfolioCheckBox.Enable = 'off';
                app.MaxReturnForMVoptimizationEditField.Enable = 'on';
                app.RiskParityCheckBox.Enable = 'on';
            end
        end

        % Value changed function: ReturnESSwitch
        function ReturnESSwitchValueChanged(app, event)
            if strcmp(app.ReturnESSwitch.Value,'Return') 
                app.ReturnValueForSingleReturnMESoptimizationEditField.Enable = 'on';
                app.ESvalueForSingleESMESoptimizationEditField.Enable = 'off';
            else
                app.ReturnValueForSingleReturnMESoptimizationEditField.Enable = 'off';
                app.ESvalueForSingleESMESoptimizationEditField.Enable = 'on';
            end
        end

        % Value changed function: ESglobalMinimumPortfolioCheckBox
        function ESglobalMinimumPortfolioCheckBoxValueChanged(app, event)
            if app.ESglobalMinimumPortfolioCheckBox.Value == false
                app.ReturnESSwitch.Enable = 'on';
                if strcmp(app.ReturnESSwitch.Value,'Return') 
                    app.ReturnValueForSingleReturnMESoptimizationEditField.Enable = 'on';
                    app.ESvalueForSingleESMESoptimizationEditField.Enable = 'off';
                else
                    app.ReturnValueForSingleReturnMESoptimizationEditField.Enable = 'off';
                    app.ESvalueForSingleESMESoptimizationEditField.Enable = 'on';
                end
                app.MaxReturnForMVoptimizationEditField.Enable = 'off'; 
            else
                app.ReturnESSwitch.Enable = 'off';                
                app.ReturnValueForSingleReturnMESoptimizationEditField.Enable = 'off';
                app.ESvalueForSingleESMESoptimizationEditField.Enable = 'off';
            end
        end

        % Value changed function: UseLinearizedOptimizerCheckBox
        function UseLinearizedOptimizerCheckBoxValueChanged(app, event)
            if app.UseLinearizedOptimizerCheckBox.Value == true
                app.LinearizedOptimizerTypeDropDown.Enable = 'on';
            else
                app.LinearizedOptimizerTypeDropDown.Enable = 'off';
            end
        end

        % Value changed function: 
        % ChangeOptimizationTargetWithNoConvergenceCheckBox
        function ChangeOptimizationTargetWithNoConvergenceCheckBoxValueChanged(app, event)
            if app.ChangeOptimizationTargetWithNoConvergenceCheckBox.Value == true
                app.MaxTargetRiskEditField.Enable = 'on';
                app.OptimizationRiskStepEditField.Enable = 'on';
            else
                app.MaxTargetRiskEditField.Enable = 'off';
                app.OptimizationRiskStepEditField.Enable = 'off';
            end
        end

        % Value changed function: ExpandingPriorWindowCheckBox
        function ExpandingPriorWindowCheckBoxValueChanged(app, event)
            if app.ExpandingPriorWindowCheckBox.Value == true
                app.PriorMovingWindowDaysEditField.Enable = 'off';
                app.PriorInitialLookBackDaysEditField.Enable = 'on';
            else
                app.PriorMovingWindowDaysEditField.Enable = 'on';
                app.PriorInitialLookBackDaysEditField.Enable = 'off';
            end
        end

        % Value changed function: ExpandingHVarWindowCheckBox
        function ExpandingHVarWindowCheckBoxValueChanged(app, event)
            if app.ExpandingHVarWindowCheckBox.Value == true
                app.HVarWindowDaysEditField.Enable = 'off';
            else
                app.HVarWindowDaysEditField.Enable = 'on';
            end
        end

        % Value changed function: CopulaSpaceSimulationsEditField
        function CopulaSpaceSimulationsEditFieldValueChanged(app, event)
            if app.CopulaSpaceSimulationsEditField.Value <= app.ProjectionResamplingSimulationsEditField.Value
                warningMsg = warndlg('The number of copula simulations cannot be equal or lower than the number of projection resampling simulations');
                app.CopulaSpaceSimulationsEditField.Value = app.ProjectionResamplingSimulationsEditField.Value + 1;
            end
        end

        % Value changed function: 
        % ProjectionResamplingSimulationsEditField
        function ProjectionResamplingSimulationsEditFieldValueChanged(app, event)
            if app.ProjectionResamplingSimulationsEditField.Value >= app.CopulaSpaceSimulationsEditField.Value
                warningMsg = warndlg('The number of projection resampling simulations cannot be equal or greater than the number of copula simulations');
                app.ProjectionResamplingSimulationsEditField.Value = app.CopulaSpaceSimulationsEditField.Value - 1;
            end
        end

        % Value changed function: RiskParityCheckBox
        function RiskParityCheckBoxValueChanged(app, event)
            if app.RiskParityCheckBox.Value == true
                app.MaxReturnForMVoptimizationEditField.Enable = 'off';
                app.MaxRiskFullEfficeintFrontierOptimizationEditField.Enable = 'off';
                app.ReturnValueForSingleReturnMESoptimizationEditField.Enable = 'off';
                app.ESvalueForSingleESMESoptimizationEditField.Enable = 'off';
                app.ESglobalMinimumPortfolioCheckBox.Enable = 'off';
                app.ReturnESSwitch.Enable = 'off';
                app.MESoptimizationCheckBox.Value = false;
                app.MESoptimizationCheckBox.Enable = 'off';
            else
                app.MESoptimizationCheckBox.Enable = 'on';
                app.MaxReturnForMVoptimizationEditField.Enable = 'on';
            end
        end

        % Menu selected function: SaveCurrentSettingsMenu
        function SaveCurrentSettingsMenuSelected(app, event)
            % Ask the user to confirm action
           choice = questdlg('Do you want to use the current settings?','Use Current settings','Yes','Cancel','Yes');
           
           if strcmp(choice,'Yes')
               % Update settings data structure 
               app.Settings = updateSettings(app);
               % Update settings in AA_DashBoardApp
               updateDashBoardAppSettings(app.AA_DashBoardApp,app.Settings);
               % Update portfolios list and default portfolios in AA_DashBoardUI
               updatePortfoliosDropDown(app.AA_DashBoardApp,app.Settings.AllPortfolios);
               updatePortfoliosList(app.AA_DashBoardApp,app.Settings.PrtUsedByDefault);
               
               warndlg('These settings will be valid only for the current session, and will be lost in case of Global Setup change','Current Settings Worning');
               uiwait
               
               % Re-enable AA_DashBoard components
               enableAA_DashBoardComponents(app.AA_DashBoardApp);
               % Close this app
               delete(app);
           end
        end

        % Menu selected function: SaveCurrentAsGlobalSetupMenu
        function SaveCurrentAsGlobalSetupMenuSelected(app, event)
            % Ask the user to insert setup name
            answer = inputdlg('Setup name: ','Save setup');
            
            if ~isempty(answer)
               % Update settings data structure 
               setupName = matlab.lang.makeValidName(answer{1});
               % Check if a setup with this name has been saved already. If it has, ask the user
               % if the old one has to be overwritten.
               findSetupNameLogical = strcmp(app.SetupListDropDown.Items,setupName);
               if sum(findSetupNameLogical)
                   choice = questdlg('A setup with this name has been saved already. Do you want to overwrite it?','Saving settings','Yes','Cancel','Yes');
                   
                   if strcmp(choice,'Yes')
                       app.SetupListDropDown.Value = app.SetupListDropDown.Items{findSetupNameLogical};
                       app.Settings = updateSettings(app);
                       SettingsData = {app.Settings};
                       save(['UI_Data\setups\' setupName '.mat'],'SettingsData');
                   end
               else
                   app.SetupListDropDown.Items = [app.SetupListDropDown.Items{:},{setupName}];
                   app.SetupListDropDown.Value = app.SetupListDropDown.Items{end};
                   app.Settings = updateSettings(app);
                   SettingsData = {app.Settings};
                   save(['UI_Data\setups\' setupName '.mat'],'SettingsData');
               end
               % Update settings in AA_DashBoardApp
               updateDashBoardAppSettings(app.AA_DashBoardApp,app.Settings);
               % Update portfolios list and default portfolios in AA_DashBoardUI
               updatePortfoliosDropDown(app.AA_DashBoardApp,app.Settings.AllPortfolios);
               updatePortfoliosList(app.AA_DashBoardApp,app.Settings.PrtUsedByDefault);
               
               % Re-enable AA_DashBoard components
               enableAA_DashBoardComponents(app.AA_DashBoardApp);
               % Close this app
               delete(app);
            end
        end

        % Button pushed function: RemoveselectedsetupButton
        function RemoveselectedsetupButtonPushed(app, event)
            % Ask the user to insert setup name
            answer = questdlg(['Do you want to remove ' app.SetupListDropDown.Value '?'],'Remove setup','Yes','No','No');
            
            if strcmp(answer,'Yes')
               % find setup name within the drop down and delete it. Then delete the .mat file
               setupNameToDelete = app.SetupListDropDown.Value;
               findSetupNameLogical = strcmp(app.SetupListDropDown.Items,setupNameToDelete);
               app.SetupListDropDown.Items(findSetupNameLogical) = [];
               delete(['UI_Data\setups\' setupNameToDelete '.mat']);
               if ~isempty(app.SetupListDropDown.Items)
                   app.SetupListDropDown.Value = app.SetupListDropDown.Items{1};
                   selectedSetup = app.SetupListDropDown.Value;
                   load(['UI_Data\setups\' selectedSetup '.mat'],'SettingsData');
                   SettingsData{1}.SetupList.Elements = app.SetupListDropDown.Items;
                   setComponentsValues(app,SettingsData{1});
                   app.Settings = updateSettings(app);
                   setComponentsRelations(app);
               end
            end
        end

        % Value changed function: NoConstraintCheckBox
        function NoConstraintCheckBoxValueChanged(app, event)
            if app.NoConstraintCheckBox.Value
                app.ExposureFlag = 1;
                app.TotalWeightsConstraintEditField.Enable = 'off';
                app.GetfromcurrentPTFCheckBox.Enable = 'off';
                if app.NoConstraintCheckBox_MNE.Value == 0;  
                    app.NoConstraintCheckBox_MNE.Enable = 'on';
                    app.MinNetExposureEditField.Enable = 'on';
                    app.GetfromcurrentPTFCheckBox_MNE.Enable = 'on';
                end
            else
                app.ExposureFlag = 0;
                app.TotalWeightsConstraintEditField.Enable = 'on';
                app.GetfromcurrentPTFCheckBox.Enable = 'on';     
            end
        end

        % Value changed function: 
        % MaxRiskFullEfficeintFrontierOptimizationEditField
        function MaxRiskFullEfficeintFrontierOptimizationEditFieldValueChanged(app, event)
            if app.MaxRiskFullEfficeintFrontierOptimizationEditField.Value ~= 0
                app.ReturnESSwitch.Enable = 'off';
                app.ReturnValueForSingleReturnMESoptimizationEditField.Enable = 'off';
                app.ESvalueForSingleESMESoptimizationEditField.Enable = 'off';
                app.ESglobalMinimumPortfolioCheckBox.Enable = 'off';
            else
                app.ESglobalMinimumPortfolioCheckBox.Enable = 'on';
                if app.ESglobalMinimumPortfolioCheckBox.Value == false
                    app.ReturnESSwitch.Enable = 'on';
                    if strcmp(app.ReturnESSwitch.Value,'Return')
                        app.ReturnValueForSingleReturnMESoptimizationEditField.Enable = 'on';
                        app.ESvalueForSingleESMESoptimizationEditField.Enable = 'off';
                    else
                        app.ReturnValueForSingleReturnMESoptimizationEditField.Enable = 'off';
                        app.ESvalueForSingleESMESoptimizationEditField.Enable = 'on';
                    end
                end
            end
        end

        % Value changed function: GetfromcurrentPTFCheckBox
        function GetfromcurrentPTFCheckBoxValueChanged(app, event)
            if app.GetfromcurrentPTFCheckBox.Value
                app.TotalWeightsConstraintEditField.Enable = 'off';
                app.NoConstraintCheckBox.Enable = 'off';
                app.NoConstraintCheckBox_MNE.Enable = 'off';
                app.NoConstraintCheckBox_MNE.Value = 1;
                app.MinNetExposureEditField.Enable = 'off';
                app.GetfromcurrentPTFCheckBox_MNE.Enable = 'off';
            else
                app.TotalWeightsConstraintEditField.Enable = 'on';
                app.NoConstraintCheckBox.Enable = 'on';
                app.NoConstraintCheckBox_MNE.Enable = 'on';
                if app.ExposureFlagMNE == 0
                    app.NoConstraintCheckBox_MNE.Value = 0;
                    app.MinNetExposureEditField.Enable = 'on';
                    app.GetfromcurrentPTFCheckBox_MNE.Enable = 'on';
                end
            end
        end

        % Value changed function: NoConstraintCheckBox_MNE
        function NoConstraintCheckBox_MNEValueChanged(app, event)
            if app.NoConstraintCheckBox_MNE.Value
                app.ExposureFlagMNE = 1;
                if app.NoConstraintCheckBox.Value == 0;
                    app.TotalWeightsConstraintEditField.Enable = 'on';
                    app.GetfromcurrentPTFCheckBox.Enable = 'on';
                    app.NoConstraintCheckBox.Enable = 'on';
                end
                app.MinNetExposureEditField.Enable = 'off';
                app.GetfromcurrentPTFCheckBox_MNE.Enable = 'off';
            else
                app.ExposureFlagMNE = 0;
                app.MinNetExposureEditField.Enable = 'on';
                app.GetfromcurrentPTFCheckBox_MNE.Enable = 'on';
            end
        end

        % Value changed function: GetfromcurrentPTFCheckBox_MNE
        function GetfromcurrentPTFCheckBox_MNEValueChanged(app, event)
            if app.GetfromcurrentPTFCheckBox_MNE.Value
                app.TotalWeightsConstraintEditField.Enable = 'off';
                app.NoConstraintCheckBox.Enable = 'off';
                app.NoConstraintCheckBox.Value = 1;
                app.NoConstraintCheckBox_MNE.Enable = 'off';
                app.MinNetExposureEditField.Enable = 'off';
                app.GetfromcurrentPTFCheckBox.Enable = 'off';
            else   
                if app.ExposureFlag == 0
                    app.NoConstraintCheckBox.Value = 0;
                    app.TotalWeightsConstraintEditField.Enable = 'on';
                    app.GetfromcurrentPTFCheckBox.Enable = 'on';
                end
                app.NoConstraintCheckBox.Enable = 'on';
                app.NoConstraintCheckBox_MNE.Enable = 'on';
                app.MinNetExposureEditField.Enable = 'on';
            end
        end

        % Button pushed function: ReportDirectoryBrowseButton
        function ReportDirectoryBrowseButtonPushed(app, event)
            ReportDirectoryPath = uigetdir('C:\Users\Giacomo\Documents\GitHub\AA_Project\AssetAllocation');
            if ReportDirectoryPath ~= 0
                app.ReportDirectoryPathEditField.Value = ReportDirectoryPath;
            end
            app.SettingsEquityDeskUIFigure.Visible = 'off';
            app.SettingsEquityDeskUIFigure.Visible = 'on';
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create SettingsEquityDeskUIFigure
            app.SettingsEquityDeskUIFigure = uifigure;
            app.SettingsEquityDeskUIFigure.Position = [100 100 961 727];
            app.SettingsEquityDeskUIFigure.Name = 'SettingsEquityDesk';
            app.SettingsEquityDeskUIFigure.Resize = 'off';
            app.SettingsEquityDeskUIFigure.CloseRequestFcn = createCallbackFcn(app, @SettingsEquityDeskUIFigureCloseRequest, true);

            % Create SaveMenu
            app.SaveMenu = uimenu(app.SettingsEquityDeskUIFigure);
            app.SaveMenu.Text = 'Save';

            % Create SaveCurrentSettingsMenu
            app.SaveCurrentSettingsMenu = uimenu(app.SaveMenu);
            app.SaveCurrentSettingsMenu.MenuSelectedFcn = createCallbackFcn(app, @SaveCurrentSettingsMenuSelected, true);
            app.SaveCurrentSettingsMenu.Text = 'Use current settings';

            % Create SaveCurrentAsGlobalSetupMenu
            app.SaveCurrentAsGlobalSetupMenu = uimenu(app.SaveMenu);
            app.SaveCurrentAsGlobalSetupMenu.MenuSelectedFcn = createCallbackFcn(app, @SaveCurrentAsGlobalSetupMenuSelected, true);
            app.SaveCurrentAsGlobalSetupMenu.Text = 'Save as global setup';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.SettingsEquityDeskUIFigure);
            app.TabGroup.TabLocation = 'left';
            app.TabGroup.Position = [0 -1 963 728];

            % Create GeneralTab
            app.GeneralTab = uitab(app.TabGroup);
            app.GeneralTab.Title = 'General              ';

            % Create BackTestOnlyCheckBox
            app.BackTestOnlyCheckBox = uicheckbox(app.GeneralTab);
            app.BackTestOnlyCheckBox.Text = 'Backtest only';
            app.BackTestOnlyCheckBox.FontSize = 14;
            app.BackTestOnlyCheckBox.Position = [60 313 105 22];

            % Create MarginalRiskByAssetTypeCheckBox
            app.MarginalRiskByAssetTypeCheckBox = uicheckbox(app.GeneralTab);
            app.MarginalRiskByAssetTypeCheckBox.Text = 'Marginal risk by asset type';
            app.MarginalRiskByAssetTypeCheckBox.FontSize = 14;
            app.MarginalRiskByAssetTypeCheckBox.Position = [60 493 187 22];

            % Create EquityRelativeReturnsCheckBox
            app.EquityRelativeReturnsCheckBox = uicheckbox(app.GeneralTab);
            app.EquityRelativeReturnsCheckBox.Text = 'Equity relative returns';
            app.EquityRelativeReturnsCheckBox.FontSize = 14;
            app.EquityRelativeReturnsCheckBox.Position = [60 283 158 22];

            % Create UseLogReturnsForEquityCheckBox
            app.UseLogReturnsForEquityCheckBox = uicheckbox(app.GeneralTab);
            app.UseLogReturnsForEquityCheckBox.Text = 'Use log returns for equity';
            app.UseLogReturnsForEquityCheckBox.FontSize = 14;
            app.UseLogReturnsForEquityCheckBox.Position = [60 253 179 22];

            % Create EraseRollingDatesReturnsForEquityCheckBox
            app.EraseRollingDatesReturnsForEquityCheckBox = uicheckbox(app.GeneralTab);
            app.EraseRollingDatesReturnsForEquityCheckBox.Text = 'Erase rolling dates returns for equity';
            app.EraseRollingDatesReturnsForEquityCheckBox.FontSize = 14;
            app.EraseRollingDatesReturnsForEquityCheckBox.Position = [60 223 249 22];

            % Create CDSrelativeReturnsCheckBox
            app.CDSrelativeReturnsCheckBox = uicheckbox(app.GeneralTab);
            app.CDSrelativeReturnsCheckBox.Text = 'CDS relative returns';
            app.CDSrelativeReturnsCheckBox.FontSize = 14;
            app.CDSrelativeReturnsCheckBox.Position = [60 193 148 22];

            % Create UseLogReturnsForCDSCheckBox
            app.UseLogReturnsForCDSCheckBox = uicheckbox(app.GeneralTab);
            app.UseLogReturnsForCDSCheckBox.Text = 'Use log returns for CDS';
            app.UseLogReturnsForCDSCheckBox.FontSize = 14;
            app.UseLogReturnsForCDSCheckBox.Position = [60 163 171 22];

            % Create EraseRollingDatesReturnsForCDSCheckBox
            app.EraseRollingDatesReturnsForCDSCheckBox = uicheckbox(app.GeneralTab);
            app.EraseRollingDatesReturnsForCDSCheckBox.Text = 'Erase rolling dates returns for CDS';
            app.EraseRollingDatesReturnsForCDSCheckBox.FontSize = 14;
            app.EraseRollingDatesReturnsForCDSCheckBox.Position = [60 133 241 22];

            % Create QuickCDSrepricingCheckBox
            app.QuickCDSrepricingCheckBox = uicheckbox(app.GeneralTab);
            app.QuickCDSrepricingCheckBox.ValueChangedFcn = createCallbackFcn(app, @QuickCDSrepricingCheckBoxValueChanged, true);
            app.QuickCDSrepricingCheckBox.Text = 'Quick CDS repricing';
            app.QuickCDSrepricingCheckBox.FontSize = 14;
            app.QuickCDSrepricingCheckBox.Position = [60 71 149 22];

            % Create AllportfoliosListBoxLabel
            app.AllportfoliosListBoxLabel = uilabel(app.GeneralTab);
            app.AllportfoliosListBoxLabel.HorizontalAlignment = 'right';
            app.AllportfoliosListBoxLabel.VerticalAlignment = 'top';
            app.AllportfoliosListBoxLabel.FontSize = 14;
            app.AllportfoliosListBoxLabel.Position = [160 615 82 22];
            app.AllportfoliosListBoxLabel.Text = 'All portfolios';

            % Create AllPortfoliosListBox
            app.AllPortfoliosListBox = uilistbox(app.GeneralTab);
            app.AllPortfoliosListBox.Items = {};
            app.AllPortfoliosListBox.FontSize = 14;
            app.AllPortfoliosListBox.Position = [251 538 117 101];
            app.AllPortfoliosListBox.Value = {};

            % Create PrtusedbydefaultListBoxLabel
            app.PrtusedbydefaultListBoxLabel = uilabel(app.GeneralTab);
            app.PrtusedbydefaultListBoxLabel.HorizontalAlignment = 'right';
            app.PrtusedbydefaultListBoxLabel.VerticalAlignment = 'top';
            app.PrtusedbydefaultListBoxLabel.FontSize = 14;
            app.PrtusedbydefaultListBoxLabel.Position = [532 615 122 22];
            app.PrtusedbydefaultListBoxLabel.Text = 'Prt used by default';

            % Create PrtUsedByDefaultListBox
            app.PrtUsedByDefaultListBox = uilistbox(app.GeneralTab);
            app.PrtUsedByDefaultListBox.Items = {};
            app.PrtUsedByDefaultListBox.FontSize = 14;
            app.PrtUsedByDefaultListBox.Position = [663 538 117 101];
            app.PrtUsedByDefaultListBox.Value = {};

            % Create AddPortfolioButton
            app.AddPortfolioButton = uibutton(app.GeneralTab, 'push');
            app.AddPortfolioButton.ButtonPushedFcn = createCallbackFcn(app, @AddPortfolioButtonPushed, true);
            app.AddPortfolioButton.FontSize = 14;
            app.AddPortfolioButton.Position = [60 581 100 26];
            app.AddPortfolioButton.Text = 'Add';

            % Create RemovePortfolioButton
            app.RemovePortfolioButton = uibutton(app.GeneralTab, 'push');
            app.RemovePortfolioButton.ButtonPushedFcn = createCallbackFcn(app, @RemovePortfolioButtonPushed, true);
            app.RemovePortfolioButton.FontSize = 14;
            app.RemovePortfolioButton.Position = [60 538 100 26];
            app.RemovePortfolioButton.Text = 'Remove';

            % Create AddDefaultPortfolioButton
            app.AddDefaultPortfolioButton = uibutton(app.GeneralTab, 'push');
            app.AddDefaultPortfolioButton.ButtonPushedFcn = createCallbackFcn(app, @AddDefaultPortfolioButtonPushed, true);
            app.AddDefaultPortfolioButton.FontSize = 14;
            app.AddDefaultPortfolioButton.Position = [432 581 100 26];
            app.AddDefaultPortfolioButton.Text = 'Add';

            % Create RemoveDefualtPortfolioButton
            app.RemoveDefualtPortfolioButton = uibutton(app.GeneralTab, 'push');
            app.RemoveDefualtPortfolioButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveDefualtPortfolioButtonPushed, true);
            app.RemoveDefualtPortfolioButton.FontSize = 14;
            app.RemoveDefualtPortfolioButton.Position = [432 538 100 26];
            app.RemoveDefualtPortfolioButton.Text = 'Remove';

            % Create PortfolioToAddEditField
            app.PortfolioToAddEditField = uieditfield(app.GeneralTab, 'text');
            app.PortfolioToAddEditField.FontSize = 14;
            app.PortfolioToAddEditField.Position = [60 617 100 22];

            % Create DefaultPrtToAddEditField
            app.DefaultPrtToAddEditField = uieditfield(app.GeneralTab, 'text');
            app.DefaultPrtToAddEditField.FontSize = 14;
            app.DefaultPrtToAddEditField.Position = [432 617 100 22];

            % Create SetupDropDownLabel
            app.SetupDropDownLabel = uilabel(app.GeneralTab);
            app.SetupDropDownLabel.BackgroundColor = [0.9294 0.6902 0.1294];
            app.SetupDropDownLabel.HorizontalAlignment = 'center';
            app.SetupDropDownLabel.VerticalAlignment = 'top';
            app.SetupDropDownLabel.FontSize = 16;
            app.SetupDropDownLabel.FontWeight = 'bold';
            app.SetupDropDownLabel.Position = [60 654 131 22];
            app.SetupDropDownLabel.Text = 'Setup';

            % Create SetupListDropDown
            app.SetupListDropDown = uidropdown(app.GeneralTab);
            app.SetupListDropDown.Items = {};
            app.SetupListDropDown.ValueChangedFcn = createCallbackFcn(app, @SetupListDropDownValueChanged, true);
            app.SetupListDropDown.FontSize = 16;
            app.SetupListDropDown.FontWeight = 'bold';
            app.SetupListDropDown.Position = [190 654 403 22];
            app.SetupListDropDown.Value = {};

            % Create MarginalRiskByCountryCheckBox
            app.MarginalRiskByCountryCheckBox = uicheckbox(app.GeneralTab);
            app.MarginalRiskByCountryCheckBox.Text = 'Marginal risk by country';
            app.MarginalRiskByCountryCheckBox.FontSize = 14;
            app.MarginalRiskByCountryCheckBox.Position = [60 463 170 22];

            % Create MarginalRiskBySectorCheckBox
            app.MarginalRiskBySectorCheckBox = uicheckbox(app.GeneralTab);
            app.MarginalRiskBySectorCheckBox.Text = 'Marginal risk by sector';
            app.MarginalRiskBySectorCheckBox.FontSize = 14;
            app.MarginalRiskBySectorCheckBox.Position = [60 433 162 22];

            % Create MarginalRiskBySingleAssetCheckBox
            app.MarginalRiskBySingleAssetCheckBox = uicheckbox(app.GeneralTab);
            app.MarginalRiskBySingleAssetCheckBox.Text = 'Marginal risk by single asset';
            app.MarginalRiskBySingleAssetCheckBox.FontSize = 14;
            app.MarginalRiskBySingleAssetCheckBox.Position = [60 403 199 22];

            % Create InvestmentuniversesheetnameEditFieldLabel
            app.InvestmentuniversesheetnameEditFieldLabel = uilabel(app.GeneralTab);
            app.InvestmentuniversesheetnameEditFieldLabel.HorizontalAlignment = 'right';
            app.InvestmentuniversesheetnameEditFieldLabel.VerticalAlignment = 'top';
            app.InvestmentuniversesheetnameEditFieldLabel.FontSize = 14;
            app.InvestmentuniversesheetnameEditFieldLabel.Position = [394 251 208 22];
            app.InvestmentuniversesheetnameEditFieldLabel.Text = 'Investment universe sheet name';

            % Create InvestmentUniverseSheetNameEditField
            app.InvestmentUniverseSheetNameEditField = uieditfield(app.GeneralTab, 'text');
            app.InvestmentUniverseSheetNameEditField.FontSize = 14;
            app.InvestmentUniverseSheetNameEditField.Position = [641 251 139 22];

            % Create InvestmenthorizondaysLabel
            app.InvestmenthorizondaysLabel = uilabel(app.GeneralTab);
            app.InvestmenthorizondaysLabel.HorizontalAlignment = 'right';
            app.InvestmenthorizondaysLabel.VerticalAlignment = 'top';
            app.InvestmenthorizondaysLabel.FontSize = 14;
            app.InvestmenthorizondaysLabel.Position = [395 493 164 22];
            app.InvestmenthorizondaysLabel.Text = 'Investment horizon (days)';

            % Create InvestmentHorizonDaysEditField
            app.InvestmentHorizonDaysEditField = uieditfield(app.GeneralTab, 'numeric');
            app.InvestmentHorizonDaysEditField.Limits = [1 Inf];
            app.InvestmentHorizonDaysEditField.FontSize = 14;
            app.InvestmentHorizonDaysEditField.Position = [641 493 139 22];
            app.InvestmentHorizonDaysEditField.Value = 1;

            % Create PriormovingwindowdaysEditFieldLabel
            app.PriormovingwindowdaysEditFieldLabel = uilabel(app.GeneralTab);
            app.PriormovingwindowdaysEditFieldLabel.HorizontalAlignment = 'right';
            app.PriormovingwindowdaysEditFieldLabel.VerticalAlignment = 'top';
            app.PriormovingwindowdaysEditFieldLabel.FontSize = 14;
            app.PriormovingwindowdaysEditFieldLabel.Position = [390 371 181 22];
            app.PriormovingwindowdaysEditFieldLabel.Text = ' Prior moving window (days)';

            % Create PriorMovingWindowDaysEditField
            app.PriorMovingWindowDaysEditField = uieditfield(app.GeneralTab, 'numeric');
            app.PriorMovingWindowDaysEditField.Limits = [1 Inf];
            app.PriorMovingWindowDaysEditField.FontSize = 14;
            app.PriorMovingWindowDaysEditField.Position = [641 371 139 22];
            app.PriorMovingWindowDaysEditField.Value = 1;

            % Create PriorinitiallookbackdaysEditFieldLabel
            app.PriorinitiallookbackdaysEditFieldLabel = uilabel(app.GeneralTab);
            app.PriorinitiallookbackdaysEditFieldLabel.HorizontalAlignment = 'right';
            app.PriorinitiallookbackdaysEditFieldLabel.VerticalAlignment = 'top';
            app.PriorinitiallookbackdaysEditFieldLabel.FontSize = 14;
            app.PriorinitiallookbackdaysEditFieldLabel.Position = [394 401 176 22];
            app.PriorinitiallookbackdaysEditFieldLabel.Text = 'Prior initial look back (days)';

            % Create PriorInitialLookBackDaysEditField
            app.PriorInitialLookBackDaysEditField = uieditfield(app.GeneralTab, 'numeric');
            app.PriorInitialLookBackDaysEditField.Limits = [0 Inf];
            app.PriorInitialLookBackDaysEditField.FontSize = 14;
            app.PriorInitialLookBackDaysEditField.Position = [641 402 139 22];

            % Create MinfrequencyofpriorupdatedaysEditFieldLabel
            app.MinfrequencyofpriorupdatedaysEditFieldLabel = uilabel(app.GeneralTab);
            app.MinfrequencyofpriorupdatedaysEditFieldLabel.HorizontalAlignment = 'right';
            app.MinfrequencyofpriorupdatedaysEditFieldLabel.VerticalAlignment = 'top';
            app.MinfrequencyofpriorupdatedaysEditFieldLabel.FontSize = 14;
            app.MinfrequencyofpriorupdatedaysEditFieldLabel.Position = [391 432 236 22];
            app.MinfrequencyofpriorupdatedaysEditFieldLabel.Text = 'Min. frequency of prior update (days)';

            % Create MinFrequencyOfPriorUpdateDaysEditField
            app.MinFrequencyOfPriorUpdateDaysEditField = uieditfield(app.GeneralTab, 'numeric');
            app.MinFrequencyOfPriorUpdateDaysEditField.Limits = [0 Inf];
            app.MinFrequencyOfPriorUpdateDaysEditField.FontSize = 14;
            app.MinFrequencyOfPriorUpdateDaysEditField.Position = [641 432 139 22];

            % Create MinintervalchangesdaysEditFieldLabel
            app.MinintervalchangesdaysEditFieldLabel = uilabel(app.GeneralTab);
            app.MinintervalchangesdaysEditFieldLabel.HorizontalAlignment = 'right';
            app.MinintervalchangesdaysEditFieldLabel.VerticalAlignment = 'top';
            app.MinintervalchangesdaysEditFieldLabel.FontSize = 14;
            app.MinintervalchangesdaysEditFieldLabel.Position = [394 462 180 22];
            app.MinintervalchangesdaysEditFieldLabel.Text = 'Min. interval changes (days)';

            % Create MinIntervalChangesDaysEditField
            app.MinIntervalChangesDaysEditField = uieditfield(app.GeneralTab, 'numeric');
            app.MinIntervalChangesDaysEditField.Limits = [0 Inf];
            app.MinIntervalChangesDaysEditField.FontSize = 14;
            app.MinIntervalChangesDaysEditField.Position = [641 462 139 22];

            % Create GranularityEditFieldLabel
            app.GranularityEditFieldLabel = uilabel(app.GeneralTab);
            app.GranularityEditFieldLabel.HorizontalAlignment = 'right';
            app.GranularityEditFieldLabel.VerticalAlignment = 'top';
            app.GranularityEditFieldLabel.FontSize = 14;
            app.GranularityEditFieldLabel.Position = [394 221 74 22];
            app.GranularityEditFieldLabel.Text = 'Granularity';

            % Create GranularityEditField
            app.GranularityEditField = uieditfield(app.GeneralTab, 'text');
            app.GranularityEditField.FontSize = 14;
            app.GranularityEditField.Position = [641 221 139 22];

            % Create ProxyfilenameEditFieldLabel
            app.ProxyfilenameEditFieldLabel = uilabel(app.GeneralTab);
            app.ProxyfilenameEditFieldLabel.HorizontalAlignment = 'right';
            app.ProxyfilenameEditFieldLabel.VerticalAlignment = 'top';
            app.ProxyfilenameEditFieldLabel.FontSize = 14;
            app.ProxyfilenameEditFieldLabel.Position = [394 281 102 22];
            app.ProxyfilenameEditFieldLabel.Text = 'Proxy file name';

            % Create ProxyFileNameEditField
            app.ProxyFileNameEditField = uieditfield(app.GeneralTab, 'text');
            app.ProxyFileNameEditField.FontSize = 14;
            app.ProxyFileNameEditField.Position = [641 281 139 22];

            % Create HVarwindowdaysEditFieldLabel
            app.HVarwindowdaysEditFieldLabel = uilabel(app.GeneralTab);
            app.HVarwindowdaysEditFieldLabel.HorizontalAlignment = 'right';
            app.HVarwindowdaysEditFieldLabel.VerticalAlignment = 'top';
            app.HVarwindowdaysEditFieldLabel.FontSize = 14;
            app.HVarwindowdaysEditFieldLabel.Position = [394 341 130 22];
            app.HVarwindowdaysEditFieldLabel.Text = 'HVar window (days)';

            % Create HVarWindowDaysEditField
            app.HVarWindowDaysEditField = uieditfield(app.GeneralTab, 'numeric');
            app.HVarWindowDaysEditField.Limits = [1 Inf];
            app.HVarWindowDaysEditField.FontSize = 14;
            app.HVarWindowDaysEditField.Position = [641 341 139 22];
            app.HVarWindowDaysEditField.Value = 1;

            % Create GeneralLabel
            app.GeneralLabel = uilabel(app.GeneralTab);
            app.GeneralLabel.FontSize = 26;
            app.GeneralLabel.FontWeight = 'bold';
            app.GeneralLabel.Position = [366 686 103 31];
            app.GeneralLabel.Text = 'General';

            % Create BudgetEditFieldLabel
            app.BudgetEditFieldLabel = uilabel(app.GeneralTab);
            app.BudgetEditFieldLabel.HorizontalAlignment = 'right';
            app.BudgetEditFieldLabel.VerticalAlignment = 'top';
            app.BudgetEditFieldLabel.FontSize = 14;
            app.BudgetEditFieldLabel.Position = [395 311 50 22];
            app.BudgetEditFieldLabel.Text = 'Budget';

            % Create BudgetEditField
            app.BudgetEditField = uieditfield(app.GeneralTab, 'numeric');
            app.BudgetEditField.Limits = [0 Inf];
            app.BudgetEditField.FontSize = 14;
            app.BudgetEditField.Position = [641 311 139 22];

            % Create ExpandingPriorWindowCheckBox
            app.ExpandingPriorWindowCheckBox = uicheckbox(app.GeneralTab);
            app.ExpandingPriorWindowCheckBox.ValueChangedFcn = createCallbackFcn(app, @ExpandingPriorWindowCheckBoxValueChanged, true);
            app.ExpandingPriorWindowCheckBox.Text = 'Expanding prior window';
            app.ExpandingPriorWindowCheckBox.FontSize = 14;
            app.ExpandingPriorWindowCheckBox.Position = [60 373 171 22];

            % Create ExpandingHVarWindowCheckBox
            app.ExpandingHVarWindowCheckBox = uicheckbox(app.GeneralTab);
            app.ExpandingHVarWindowCheckBox.ValueChangedFcn = createCallbackFcn(app, @ExpandingHVarWindowCheckBoxValueChanged, true);
            app.ExpandingHVarWindowCheckBox.Text = 'Expanding HVar window';
            app.ExpandingHVarWindowCheckBox.FontSize = 14;
            app.ExpandingHVarWindowCheckBox.Position = [60 343 174 22];

            % Create EquityretextendedlagEditField_2Label
            app.EquityretextendedlagEditField_2Label = uilabel(app.GeneralTab);
            app.EquityretextendedlagEditField_2Label.HorizontalAlignment = 'right';
            app.EquityretextendedlagEditField_2Label.FontSize = 14;
            app.EquityretextendedlagEditField_2Label.Position = [394 191 152 22];
            app.EquityretextendedlagEditField_2Label.Text = 'Equity ret. extended lag';

            % Create EquityRetExtendedLagEditField
            app.EquityRetExtendedLagEditField = uieditfield(app.GeneralTab, 'numeric');
            app.EquityRetExtendedLagEditField.Limits = [0 Inf];
            app.EquityRetExtendedLagEditField.FontSize = 14;
            app.EquityRetExtendedLagEditField.Position = [641 191 139 22];

            % Create EquityretlagEditFieldLabel
            app.EquityretlagEditFieldLabel = uilabel(app.GeneralTab);
            app.EquityretlagEditFieldLabel.HorizontalAlignment = 'right';
            app.EquityretlagEditFieldLabel.FontSize = 14;
            app.EquityretlagEditFieldLabel.Position = [394 161 91 22];
            app.EquityretlagEditFieldLabel.Text = 'Equity ret. lag';

            % Create EquityRetLagEditField
            app.EquityRetLagEditField = uieditfield(app.GeneralTab, 'numeric');
            app.EquityRetLagEditField.Limits = [0 Inf];
            app.EquityRetLagEditField.FontSize = 14;
            app.EquityRetLagEditField.Position = [641 161 139 22];

            % Create CDSretlagEditFieldLabel
            app.CDSretlagEditFieldLabel = uilabel(app.GeneralTab);
            app.CDSretlagEditFieldLabel.HorizontalAlignment = 'right';
            app.CDSretlagEditFieldLabel.FontSize = 14;
            app.CDSretlagEditFieldLabel.Position = [394 131 82 22];
            app.CDSretlagEditFieldLabel.Text = 'CDS ret. lag';

            % Create CDSretLagEditField
            app.CDSretLagEditField = uieditfield(app.GeneralTab, 'numeric');
            app.CDSretLagEditField.Limits = [0 Inf];
            app.CDSretLagEditField.FontSize = 14;
            app.CDSretLagEditField.Position = [641 131 139 22];

            % Create CDSretextendedlagEditFieldLabel
            app.CDSretextendedlagEditFieldLabel = uilabel(app.GeneralTab);
            app.CDSretextendedlagEditFieldLabel.HorizontalAlignment = 'right';
            app.CDSretextendedlagEditFieldLabel.FontSize = 14;
            app.CDSretextendedlagEditFieldLabel.Position = [395 101 143 22];
            app.CDSretextendedlagEditFieldLabel.Text = 'CDS ret. extended lag';

            % Create CDSretExtendedLagEditField
            app.CDSretExtendedLagEditField = uieditfield(app.GeneralTab, 'numeric');
            app.CDSretExtendedLagEditField.Limits = [0 Inf];
            app.CDSretExtendedLagEditField.FontSize = 14;
            app.CDSretExtendedLagEditField.Position = [641 101 139 22];

            % Create QuickCDSrepricingfrequencyEditFieldLabel
            app.QuickCDSrepricingfrequencyEditFieldLabel = uilabel(app.GeneralTab);
            app.QuickCDSrepricingfrequencyEditFieldLabel.HorizontalAlignment = 'right';
            app.QuickCDSrepricingfrequencyEditFieldLabel.FontSize = 14;
            app.QuickCDSrepricingfrequencyEditFieldLabel.Position = [394 71 199 22];
            app.QuickCDSrepricingfrequencyEditFieldLabel.Text = 'Quick CDS repricing frequency';

            % Create QuickCDSrepricingFrequencyEditField
            app.QuickCDSrepricingFrequencyEditField = uieditfield(app.GeneralTab, 'numeric');
            app.QuickCDSrepricingFrequencyEditField.Limits = [0 Inf];
            app.QuickCDSrepricingFrequencyEditField.FontSize = 14;
            app.QuickCDSrepricingFrequencyEditField.Position = [641 71 139 22];

            % Create RiskAnalysisCheckBox
            app.RiskAnalysisCheckBox = uicheckbox(app.GeneralTab);
            app.RiskAnalysisCheckBox.Text = 'Risk analysis ';
            app.RiskAnalysisCheckBox.FontSize = 14;
            app.RiskAnalysisCheckBox.Position = [60 101 107 22];

            % Create RemoveselectedsetupButton
            app.RemoveselectedsetupButton = uibutton(app.GeneralTab, 'push');
            app.RemoveselectedsetupButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveselectedsetupButtonPushed, true);
            app.RemoveselectedsetupButton.FontSize = 14;
            app.RemoveselectedsetupButton.Position = [601 654 179 22];
            app.RemoveselectedsetupButton.Text = 'Remove selected setup';

            % Create LagforAAenforcementLabel
            app.LagforAAenforcementLabel = uilabel(app.GeneralTab);
            app.LagforAAenforcementLabel.HorizontalAlignment = 'right';
            app.LagforAAenforcementLabel.FontSize = 14;
            app.LagforAAenforcementLabel.Position = [395 40 153 22];
            app.LagforAAenforcementLabel.Text = 'Lag for AA enforcement';

            % Create Lag4AA_enforcementEditField
            app.Lag4AA_enforcementEditField = uieditfield(app.GeneralTab, 'numeric');
            app.Lag4AA_enforcementEditField.Limits = [0 1];
            app.Lag4AA_enforcementEditField.FontSize = 14;
            app.Lag4AA_enforcementEditField.Position = [641 40 139 22];
            app.Lag4AA_enforcementEditField.Value = 1;

            % Create DatesTab
            app.DatesTab = uitab(app.TabGroup);
            app.DatesTab.Title = 'Dates';

            % Create MinhistorystartdateEditFieldLabel
            app.MinhistorystartdateEditFieldLabel = uilabel(app.DatesTab);
            app.MinhistorystartdateEditFieldLabel.HorizontalAlignment = 'right';
            app.MinhistorystartdateEditFieldLabel.VerticalAlignment = 'top';
            app.MinhistorystartdateEditFieldLabel.FontSize = 14;
            app.MinhistorystartdateEditFieldLabel.Position = [39 628 139 22];
            app.MinhistorystartdateEditFieldLabel.Text = 'Min. history start date';

            % Create MinHistoryStartDateEditField
            app.MinHistoryStartDateEditField = uieditfield(app.DatesTab, 'text');
            app.MinHistoryStartDateEditField.FontSize = 14;
            app.MinHistoryStartDateEditField.Position = [277 628 100 22];

            % Create HistorystartdateEditFieldLabel
            app.HistorystartdateEditFieldLabel = uilabel(app.DatesTab);
            app.HistorystartdateEditFieldLabel.HorizontalAlignment = 'right';
            app.HistorystartdateEditFieldLabel.VerticalAlignment = 'top';
            app.HistorystartdateEditFieldLabel.FontSize = 14;
            app.HistorystartdateEditFieldLabel.Position = [39 586 111 22];
            app.HistorystartdateEditFieldLabel.Text = 'History start date';

            % Create HistoryStartDateEditField
            app.HistoryStartDateEditField = uieditfield(app.DatesTab, 'text');
            app.HistoryStartDateEditField.FontSize = 14;
            app.HistoryStartDateEditField.Position = [277 586 100 22];

            % Create HistroyenddateEditFieldLabel
            app.HistroyenddateEditFieldLabel = uilabel(app.DatesTab);
            app.HistroyenddateEditFieldLabel.HorizontalAlignment = 'right';
            app.HistroyenddateEditFieldLabel.VerticalAlignment = 'top';
            app.HistroyenddateEditFieldLabel.FontSize = 14;
            app.HistroyenddateEditFieldLabel.Position = [39 544 107 22];
            app.HistroyenddateEditFieldLabel.Text = 'Histroy end date';

            % Create HistoryEndDateEditField
            app.HistoryEndDateEditField = uieditfield(app.DatesTab, 'text');
            app.HistoryEndDateEditField.FontSize = 14;
            app.HistoryEndDateEditField.Position = [277 544 100 22];

            % Create FirstinvestmentdateEditFieldLabel
            app.FirstinvestmentdateEditFieldLabel = uilabel(app.DatesTab);
            app.FirstinvestmentdateEditFieldLabel.HorizontalAlignment = 'right';
            app.FirstinvestmentdateEditFieldLabel.VerticalAlignment = 'top';
            app.FirstinvestmentdateEditFieldLabel.FontSize = 14;
            app.FirstinvestmentdateEditFieldLabel.Position = [39 504 135 22];
            app.FirstinvestmentdateEditFieldLabel.Text = 'First investment date';

            % Create FirstInvestmentDateEditField
            app.FirstInvestmentDateEditField = uieditfield(app.DatesTab, 'text');
            app.FirstInvestmentDateEditField.FontSize = 14;
            app.FirstInvestmentDateEditField.Position = [277 504 100 22];

            % Create DatesLabel
            app.DatesLabel = uilabel(app.DatesTab);
            app.DatesLabel.FontSize = 26;
            app.DatesLabel.FontWeight = 'bold';
            app.DatesLabel.Position = [381 685 76 31];
            app.DatesLabel.Text = 'Dates';

            % Create ViewsTab
            app.ViewsTab = uitab(app.TabGroup);
            app.ViewsTab.Title = 'Views';

            % Create QuantSignalsCheckBox
            app.QuantSignalsCheckBox = uicheckbox(app.ViewsTab);
            app.QuantSignalsCheckBox.ValueChangedFcn = createCallbackFcn(app, @QuantSignalsCheckBoxValueChanged, true);
            app.QuantSignalsCheckBox.Text = 'Quant. signals';
            app.QuantSignalsCheckBox.FontSize = 14;
            app.QuantSignalsCheckBox.Position = [387 525 111 22];

            % Create QuantstrategynameEditFieldLabel
            app.QuantstrategynameEditFieldLabel = uilabel(app.ViewsTab);
            app.QuantstrategynameEditFieldLabel.HorizontalAlignment = 'right';
            app.QuantstrategynameEditFieldLabel.VerticalAlignment = 'top';
            app.QuantstrategynameEditFieldLabel.FontSize = 14;
            app.QuantstrategynameEditFieldLabel.Position = [40 473 140 22];
            app.QuantstrategynameEditFieldLabel.Text = 'Quant. strategy name';

            % Create QuantStrategyNameEditField
            app.QuantStrategyNameEditField = uieditfield(app.ViewsTab, 'text');
            app.QuantStrategyNameEditField.FontSize = 14;
            app.QuantStrategyNameEditField.Enable = 'off';
            app.QuantStrategyNameEditField.Position = [229 473 100 22];

            % Create SubjectiveViewsCheckBox
            app.SubjectiveViewsCheckBox = uicheckbox(app.ViewsTab);
            app.SubjectiveViewsCheckBox.ValueChangedFcn = createCallbackFcn(app, @SubjectiveViewsCheckBoxValueChanged, true);
            app.SubjectiveViewsCheckBox.Text = 'Subjective views';
            app.SubjectiveViewsCheckBox.FontSize = 14;
            app.SubjectiveViewsCheckBox.Position = [387 577 126 22];

            % Create SubjectiveviewsweightEditFieldLabel
            app.SubjectiveviewsweightEditFieldLabel = uilabel(app.ViewsTab);
            app.SubjectiveviewsweightEditFieldLabel.HorizontalAlignment = 'right';
            app.SubjectiveviewsweightEditFieldLabel.VerticalAlignment = 'top';
            app.SubjectiveviewsweightEditFieldLabel.FontSize = 14;
            app.SubjectiveviewsweightEditFieldLabel.Position = [40 577 153 22];
            app.SubjectiveviewsweightEditFieldLabel.Text = 'Subjective views weight';

            % Create SubjectiveViewsWeightEditField
            app.SubjectiveViewsWeightEditField = uieditfield(app.ViewsTab, 'numeric');
            app.SubjectiveViewsWeightEditField.Limits = [0 1];
            app.SubjectiveViewsWeightEditField.ValueChangedFcn = createCallbackFcn(app, @SubjectiveViewsWeightEditFieldValueChanged, true);
            app.SubjectiveViewsWeightEditField.FontSize = 14;
            app.SubjectiveViewsWeightEditField.Enable = 'off';
            app.SubjectiveViewsWeightEditField.Position = [229 577 100 22];

            % Create QuantviewsweightEditFieldLabel
            app.QuantviewsweightEditFieldLabel = uilabel(app.ViewsTab);
            app.QuantviewsweightEditFieldLabel.HorizontalAlignment = 'right';
            app.QuantviewsweightEditFieldLabel.VerticalAlignment = 'top';
            app.QuantviewsweightEditFieldLabel.FontSize = 14;
            app.QuantviewsweightEditFieldLabel.Position = [40 525 131 22];
            app.QuantviewsweightEditFieldLabel.Text = 'Quant. views weight';

            % Create QuantViewsWeightEditField
            app.QuantViewsWeightEditField = uieditfield(app.ViewsTab, 'numeric');
            app.QuantViewsWeightEditField.Limits = [0 1];
            app.QuantViewsWeightEditField.ValueChangedFcn = createCallbackFcn(app, @QuantViewsWeightEditFieldValueChanged, true);
            app.QuantViewsWeightEditField.FontSize = 14;
            app.QuantViewsWeightEditField.Enable = 'off';
            app.QuantViewsWeightEditField.Position = [229 525 100 22];

            % Create PriorweightEditFieldLabel
            app.PriorweightEditFieldLabel = uilabel(app.ViewsTab);
            app.PriorweightEditFieldLabel.HorizontalAlignment = 'right';
            app.PriorweightEditFieldLabel.VerticalAlignment = 'top';
            app.PriorweightEditFieldLabel.FontSize = 14;
            app.PriorweightEditFieldLabel.Position = [40 629 79 22];
            app.PriorweightEditFieldLabel.Text = 'Prior weight';

            % Create PriorWeightEditField
            app.PriorWeightEditField = uieditfield(app.ViewsTab, 'numeric');
            app.PriorWeightEditField.Limits = [0 1];
            app.PriorWeightEditField.Editable = 'off';
            app.PriorWeightEditField.FontSize = 14;
            app.PriorWeightEditField.Position = [229 629 100 22];
            app.PriorWeightEditField.Value = 1;

            % Create ViewsLabel
            app.ViewsLabel = uilabel(app.ViewsTab);
            app.ViewsLabel.FontSize = 26;
            app.ViewsLabel.FontWeight = 'bold';
            app.ViewsLabel.Position = [380 685 79 31];
            app.ViewsLabel.Text = 'Views';

            % Create DistributionModelTab
            app.DistributionModelTab = uitab(app.TabGroup);
            app.DistributionModelTab.Title = 'Distribution Model';

            % Create CalibrateTailsCheckBox
            app.CalibrateTailsCheckBox = uicheckbox(app.DistributionModelTab);
            app.CalibrateTailsCheckBox.ValueChangedFcn = createCallbackFcn(app, @CalibrateTailsCheckBoxValueChanged, true);
            app.CalibrateTailsCheckBox.Text = 'Calibrate tails';
            app.CalibrateTailsCheckBox.FontSize = 14;
            app.CalibrateTailsCheckBox.Position = [508 634 107 22];

            % Create ConstanttailsthresholdEditFieldLabel
            app.ConstanttailsthresholdEditFieldLabel = uilabel(app.DistributionModelTab);
            app.ConstanttailsthresholdEditFieldLabel.HorizontalAlignment = 'right';
            app.ConstanttailsthresholdEditFieldLabel.VerticalAlignment = 'top';
            app.ConstanttailsthresholdEditFieldLabel.FontSize = 14;
            app.ConstanttailsthresholdEditFieldLabel.Position = [35 634 151 22];
            app.ConstanttailsthresholdEditFieldLabel.Text = 'Constant tails threshold';

            % Create ConstantTailsThresholdEditField
            app.ConstantTailsThresholdEditField = uieditfield(app.DistributionModelTab, 'numeric');
            app.ConstantTailsThresholdEditField.Limits = [0 Inf];
            app.ConstantTailsThresholdEditField.FontSize = 14;
            app.ConstantTailsThresholdEditField.Position = [265 634 100 22];

            % Create CentralvaluesmodelDropDownLabel
            app.CentralvaluesmodelDropDownLabel = uilabel(app.DistributionModelTab);
            app.CentralvaluesmodelDropDownLabel.HorizontalAlignment = 'right';
            app.CentralvaluesmodelDropDownLabel.VerticalAlignment = 'top';
            app.CentralvaluesmodelDropDownLabel.FontSize = 14;
            app.CentralvaluesmodelDropDownLabel.Position = [35 582 137 22];
            app.CentralvaluesmodelDropDownLabel.Text = 'Central values model';

            % Create CentralValuesModelDropDown
            app.CentralValuesModelDropDown = uidropdown(app.DistributionModelTab);
            app.CentralValuesModelDropDown.Items = {'ecdf', 'kernel'};
            app.CentralValuesModelDropDown.FontSize = 14;
            app.CentralValuesModelDropDown.Position = [265 582 100 22];
            app.CentralValuesModelDropDown.Value = 'ecdf';

            % Create MintailoccurencesEditFieldLabel
            app.MintailoccurencesEditFieldLabel = uilabel(app.DistributionModelTab);
            app.MintailoccurencesEditFieldLabel.HorizontalAlignment = 'right';
            app.MintailoccurencesEditFieldLabel.VerticalAlignment = 'top';
            app.MintailoccurencesEditFieldLabel.FontSize = 14;
            app.MintailoccurencesEditFieldLabel.Position = [35 530 129 22];
            app.MintailoccurencesEditFieldLabel.Text = 'Min. tail occurences';

            % Create MinTailOccurencesEditField
            app.MinTailOccurencesEditField = uieditfield(app.DistributionModelTab, 'numeric');
            app.MinTailOccurencesEditField.Limits = [10 Inf];
            app.MinTailOccurencesEditField.FontSize = 14;
            app.MinTailOccurencesEditField.Position = [265 530 100 22];
            app.MinTailOccurencesEditField.Value = 10;

            % Create CopulaEstimationCheckBox
            app.CopulaEstimationCheckBox = uicheckbox(app.DistributionModelTab);
            app.CopulaEstimationCheckBox.ValueChangedFcn = createCallbackFcn(app, @CopulaEstimationCheckBoxValueChanged, true);
            app.CopulaEstimationCheckBox.Text = 'Copula estimation';
            app.CopulaEstimationCheckBox.FontSize = 14;
            app.CopulaEstimationCheckBox.Position = [508 582 134 22];

            % Create UseTcopulaCheckBox
            app.UseTcopulaCheckBox = uicheckbox(app.DistributionModelTab);
            app.UseTcopulaCheckBox.Enable = 'off';
            app.UseTcopulaCheckBox.Text = 'Use T-copula';
            app.UseTcopulaCheckBox.FontSize = 14;
            app.UseTcopulaCheckBox.Position = [508 530 104 22];

            % Create MCsimulationslimitDropDownLabel
            app.MCsimulationslimitDropDownLabel = uilabel(app.DistributionModelTab);
            app.MCsimulationslimitDropDownLabel.HorizontalAlignment = 'right';
            app.MCsimulationslimitDropDownLabel.VerticalAlignment = 'top';
            app.MCsimulationslimitDropDownLabel.FontSize = 14;
            app.MCsimulationslimitDropDownLabel.Position = [508 477 130 22];
            app.MCsimulationslimitDropDownLabel.Text = 'MC simulations limit';

            % Create MCsimulationsLimitDropDown
            app.MCsimulationsLimitDropDown = uidropdown(app.DistributionModelTab);
            app.MCsimulationsLimitDropDown.Items = {'none', 'absprob'};
            app.MCsimulationsLimitDropDown.ValueChangedFcn = createCallbackFcn(app, @MCsimulationsLimitDropDownValueChanged, true);
            app.MCsimulationsLimitDropDown.FontSize = 14;
            app.MCsimulationsLimitDropDown.Position = [653 480 100 22];
            app.MCsimulationsLimitDropDown.Value = 'none';

            % Create ProbabilitythresholdforMCEditFieldLabel
            app.ProbabilitythresholdforMCEditFieldLabel = uilabel(app.DistributionModelTab);
            app.ProbabilitythresholdforMCEditFieldLabel.HorizontalAlignment = 'right';
            app.ProbabilitythresholdforMCEditFieldLabel.VerticalAlignment = 'top';
            app.ProbabilitythresholdforMCEditFieldLabel.FontSize = 14;
            app.ProbabilitythresholdforMCEditFieldLabel.Position = [35 478 178 22];
            app.ProbabilitythresholdforMCEditFieldLabel.Text = 'Probability threshold for MC';

            % Create ProbabilityThresholdForMCEditField
            app.ProbabilityThresholdForMCEditField = uieditfield(app.DistributionModelTab, 'numeric');
            app.ProbabilityThresholdForMCEditField.Limits = [0.0001 0.001];
            app.ProbabilityThresholdForMCEditField.FontSize = 14;
            app.ProbabilityThresholdForMCEditField.Enable = 'off';
            app.ProbabilityThresholdForMCEditField.Position = [265 478 100 22];
            app.ProbabilityThresholdForMCEditField.Value = 0.0001;

            % Create CopulaspacesimulationsEditFieldLabel
            app.CopulaspacesimulationsEditFieldLabel = uilabel(app.DistributionModelTab);
            app.CopulaspacesimulationsEditFieldLabel.HorizontalAlignment = 'right';
            app.CopulaspacesimulationsEditFieldLabel.VerticalAlignment = 'top';
            app.CopulaspacesimulationsEditFieldLabel.FontSize = 14;
            app.CopulaspacesimulationsEditFieldLabel.Position = [35 426 165 22];
            app.CopulaspacesimulationsEditFieldLabel.Text = 'Copula space simulations';

            % Create CopulaSpaceSimulationsEditField
            app.CopulaSpaceSimulationsEditField = uieditfield(app.DistributionModelTab, 'numeric');
            app.CopulaSpaceSimulationsEditField.Limits = [1000 100000];
            app.CopulaSpaceSimulationsEditField.ValueChangedFcn = createCallbackFcn(app, @CopulaSpaceSimulationsEditFieldValueChanged, true);
            app.CopulaSpaceSimulationsEditField.FontSize = 14;
            app.CopulaSpaceSimulationsEditField.Position = [265 426 100 22];
            app.CopulaSpaceSimulationsEditField.Value = 1000;

            % Create ProjectionresamplingsimulationsEditFieldLabel
            app.ProjectionresamplingsimulationsEditFieldLabel = uilabel(app.DistributionModelTab);
            app.ProjectionresamplingsimulationsEditFieldLabel.HorizontalAlignment = 'right';
            app.ProjectionresamplingsimulationsEditFieldLabel.VerticalAlignment = 'top';
            app.ProjectionresamplingsimulationsEditFieldLabel.FontSize = 14;
            app.ProjectionresamplingsimulationsEditFieldLabel.Position = [35 374 215 22];
            app.ProjectionresamplingsimulationsEditFieldLabel.Text = 'Projection resampling simulations';

            % Create ProjectionResamplingSimulationsEditField
            app.ProjectionResamplingSimulationsEditField = uieditfield(app.DistributionModelTab, 'numeric');
            app.ProjectionResamplingSimulationsEditField.Limits = [999 99999];
            app.ProjectionResamplingSimulationsEditField.ValueChangedFcn = createCallbackFcn(app, @ProjectionResamplingSimulationsEditFieldValueChanged, true);
            app.ProjectionResamplingSimulationsEditField.FontSize = 14;
            app.ProjectionResamplingSimulationsEditField.Position = [265 374 100 22];
            app.ProjectionResamplingSimulationsEditField.Value = 999;

            % Create UseFullHistoryForTailsEstimationCheckBox
            app.UseFullHistoryForTailsEstimationCheckBox = uicheckbox(app.DistributionModelTab);
            app.UseFullHistoryForTailsEstimationCheckBox.Text = 'Use full history for tails estimation';
            app.UseFullHistoryForTailsEstimationCheckBox.FontSize = 14;
            app.UseFullHistoryForTailsEstimationCheckBox.Position = [508 426 233 22];

            % Create DistributionModelLabel
            app.DistributionModelLabel = uilabel(app.DistributionModelTab);
            app.DistributionModelLabel.FontSize = 26;
            app.DistributionModelLabel.FontWeight = 'bold';
            app.DistributionModelLabel.Position = [301 687 237 31];
            app.DistributionModelLabel.Text = 'Distribution model';

            % Create OptimizationTab
            app.OptimizationTab = uitab(app.TabGroup);
            app.OptimizationTab.Title = 'Optimization';

            % Create PortfoliosonefficientfrontierEditFieldLabel
            app.PortfoliosonefficientfrontierEditFieldLabel = uilabel(app.OptimizationTab);
            app.PortfoliosonefficientfrontierEditFieldLabel.HorizontalAlignment = 'right';
            app.PortfoliosonefficientfrontierEditFieldLabel.VerticalAlignment = 'top';
            app.PortfoliosonefficientfrontierEditFieldLabel.FontSize = 14;
            app.PortfoliosonefficientfrontierEditFieldLabel.Position = [33 629 183 22];
            app.PortfoliosonefficientfrontierEditFieldLabel.Text = 'Portfolios on efficient frontier';

            % Create PortfoliosOnEfficientFrontierEditField
            app.PortfoliosOnEfficientFrontierEditField = uieditfield(app.OptimizationTab, 'numeric');
            app.PortfoliosOnEfficientFrontierEditField.Limits = [1 Inf];
            app.PortfoliosOnEfficientFrontierEditField.FontSize = 14;
            app.PortfoliosOnEfficientFrontierEditField.Position = [349 629 100 22];
            app.PortfoliosOnEfficientFrontierEditField.Value = 1;

            % Create MaxreturnforMVoptimizationEditFieldLabel
            app.MaxreturnforMVoptimizationEditFieldLabel = uilabel(app.OptimizationTab);
            app.MaxreturnforMVoptimizationEditFieldLabel.HorizontalAlignment = 'right';
            app.MaxreturnforMVoptimizationEditFieldLabel.VerticalAlignment = 'top';
            app.MaxreturnforMVoptimizationEditFieldLabel.FontSize = 14;
            app.MaxreturnforMVoptimizationEditFieldLabel.Position = [33 586 197 22];
            app.MaxreturnforMVoptimizationEditFieldLabel.Text = 'Max return for MV optimization';

            % Create MaxReturnForMVoptimizationEditField
            app.MaxReturnForMVoptimizationEditField = uieditfield(app.OptimizationTab, 'numeric');
            app.MaxReturnForMVoptimizationEditField.Limits = [0 Inf];
            app.MaxReturnForMVoptimizationEditField.FontSize = 14;
            app.MaxReturnForMVoptimizationEditField.Position = [349 586 100 22];

            % Create MESoptimizationCheckBox
            app.MESoptimizationCheckBox = uicheckbox(app.OptimizationTab);
            app.MESoptimizationCheckBox.ValueChangedFcn = createCallbackFcn(app, @MESoptimizationCheckBoxValueChanged, true);
            app.MESoptimizationCheckBox.Text = 'M-ES optimization';
            app.MESoptimizationCheckBox.FontSize = 14;
            app.MESoptimizationCheckBox.Position = [505 543 135 22];

            % Create ReturnvalueforsinglereturnMESoptimizationEditFieldLabel
            app.ReturnvalueforsinglereturnMESoptimizationEditFieldLabel = uilabel(app.OptimizationTab);
            app.ReturnvalueforsinglereturnMESoptimizationEditFieldLabel.HorizontalAlignment = 'right';
            app.ReturnvalueforsinglereturnMESoptimizationEditFieldLabel.VerticalAlignment = 'top';
            app.ReturnvalueforsinglereturnMESoptimizationEditFieldLabel.FontSize = 14;
            app.ReturnvalueforsinglereturnMESoptimizationEditFieldLabel.Position = [31 500 307 22];
            app.ReturnvalueforsinglereturnMESoptimizationEditFieldLabel.Text = 'Return value for single return M-ES optimization';

            % Create ReturnValueForSingleReturnMESoptimizationEditField
            app.ReturnValueForSingleReturnMESoptimizationEditField = uieditfield(app.OptimizationTab, 'numeric');
            app.ReturnValueForSingleReturnMESoptimizationEditField.Limits = [0 Inf];
            app.ReturnValueForSingleReturnMESoptimizationEditField.FontSize = 14;
            app.ReturnValueForSingleReturnMESoptimizationEditField.Enable = 'off';
            app.ReturnValueForSingleReturnMESoptimizationEditField.Position = [349 500 100 22];

            % Create ESvalueforsingleESMESoptimizationEditFieldLabel
            app.ESvalueforsingleESMESoptimizationEditFieldLabel = uilabel(app.OptimizationTab);
            app.ESvalueforsingleESMESoptimizationEditFieldLabel.HorizontalAlignment = 'right';
            app.ESvalueforsingleESMESoptimizationEditFieldLabel.VerticalAlignment = 'top';
            app.ESvalueforsingleESMESoptimizationEditFieldLabel.FontSize = 14;
            app.ESvalueforsingleESMESoptimizationEditFieldLabel.Position = [32 457 265 22];
            app.ESvalueforsingleESMESoptimizationEditFieldLabel.Text = 'ES value for single ES M-ES optimization';

            % Create ESvalueForSingleESMESoptimizationEditField
            app.ESvalueForSingleESMESoptimizationEditField = uieditfield(app.OptimizationTab, 'numeric');
            app.ESvalueForSingleESMESoptimizationEditField.Limits = [0 Inf];
            app.ESvalueForSingleESMESoptimizationEditField.FontSize = 14;
            app.ESvalueForSingleESMESoptimizationEditField.Enable = 'off';
            app.ESvalueForSingleESMESoptimizationEditField.Position = [349 457 100 22];

            % Create ESandVaRconfidencelevelEditFieldLabel
            app.ESandVaRconfidencelevelEditFieldLabel = uilabel(app.OptimizationTab);
            app.ESandVaRconfidencelevelEditFieldLabel.HorizontalAlignment = 'right';
            app.ESandVaRconfidencelevelEditFieldLabel.VerticalAlignment = 'top';
            app.ESandVaRconfidencelevelEditFieldLabel.FontSize = 14;
            app.ESandVaRconfidencelevelEditFieldLabel.Position = [33 417 186 22];
            app.ESandVaRconfidencelevelEditFieldLabel.Text = 'ES and VaR confidence level';

            % Create ESandVaRconfidenceLevelEditField
            app.ESandVaRconfidenceLevelEditField = uieditfield(app.OptimizationTab, 'numeric');
            app.ESandVaRconfidenceLevelEditField.Limits = [0.9 0.995];
            app.ESandVaRconfidenceLevelEditField.FontSize = 14;
            app.ESandVaRconfidenceLevelEditField.Position = [349 417 100 22];
            app.ESandVaRconfidenceLevelEditField.Value = 0.9;

            % Create UseLinearizedOptimizerCheckBox
            app.UseLinearizedOptimizerCheckBox = uicheckbox(app.OptimizationTab);
            app.UseLinearizedOptimizerCheckBox.ValueChangedFcn = createCallbackFcn(app, @UseLinearizedOptimizerCheckBoxValueChanged, true);
            app.UseLinearizedOptimizerCheckBox.Text = 'Use linearized optimizer';
            app.UseLinearizedOptimizerCheckBox.FontSize = 14;
            app.UseLinearizedOptimizerCheckBox.Position = [505 374 171 22];

            % Create LinearizedoptimizertypeDropDownLabel
            app.LinearizedoptimizertypeDropDownLabel = uilabel(app.OptimizationTab);
            app.LinearizedoptimizertypeDropDownLabel.HorizontalAlignment = 'right';
            app.LinearizedoptimizertypeDropDownLabel.VerticalAlignment = 'top';
            app.LinearizedoptimizertypeDropDownLabel.FontSize = 14;
            app.LinearizedoptimizertypeDropDownLabel.Position = [33 374 161 22];
            app.LinearizedoptimizertypeDropDownLabel.Text = 'Linearized optimizer type';

            % Create LinearizedOptimizerTypeDropDown
            app.LinearizedOptimizerTypeDropDown = uidropdown(app.OptimizationTab);
            app.LinearizedOptimizerTypeDropDown.Items = {'dual-simplex', 'interior-point'};
            app.LinearizedOptimizerTypeDropDown.Enable = 'off';
            app.LinearizedOptimizerTypeDropDown.FontSize = 14;
            app.LinearizedOptimizerTypeDropDown.Position = [349 374 100 22];
            app.LinearizedOptimizerTypeDropDown.Value = 'dual-simplex';

            % Create MaxriskfullefficeintfrontieroptimizationLabel
            app.MaxriskfullefficeintfrontieroptimizationLabel = uilabel(app.OptimizationTab);
            app.MaxriskfullefficeintfrontieroptimizationLabel.HorizontalAlignment = 'right';
            app.MaxriskfullefficeintfrontieroptimizationLabel.VerticalAlignment = 'top';
            app.MaxriskfullefficeintfrontieroptimizationLabel.FontSize = 14;
            app.MaxriskfullefficeintfrontieroptimizationLabel.Position = [31 543 260 22];
            app.MaxriskfullefficeintfrontieroptimizationLabel.Text = 'Max risk full efficeint frontier optimization';

            % Create MaxRiskFullEfficeintFrontierOptimizationEditField
            app.MaxRiskFullEfficeintFrontierOptimizationEditField = uieditfield(app.OptimizationTab, 'numeric');
            app.MaxRiskFullEfficeintFrontierOptimizationEditField.Limits = [0 Inf];
            app.MaxRiskFullEfficeintFrontierOptimizationEditField.ValueChangedFcn = createCallbackFcn(app, @MaxRiskFullEfficeintFrontierOptimizationEditFieldValueChanged, true);
            app.MaxRiskFullEfficeintFrontierOptimizationEditField.FontSize = 14;
            app.MaxRiskFullEfficeintFrontierOptimizationEditField.Enable = 'off';
            app.MaxRiskFullEfficeintFrontierOptimizationEditField.Position = [349 543 100 22];

            % Create ESglobalMinimumPortfolioCheckBox
            app.ESglobalMinimumPortfolioCheckBox = uicheckbox(app.OptimizationTab);
            app.ESglobalMinimumPortfolioCheckBox.ValueChangedFcn = createCallbackFcn(app, @ESglobalMinimumPortfolioCheckBoxValueChanged, true);
            app.ESglobalMinimumPortfolioCheckBox.Enable = 'off';
            app.ESglobalMinimumPortfolioCheckBox.Text = 'ES global minimum portfolio';
            app.ESglobalMinimumPortfolioCheckBox.FontSize = 14;
            app.ESglobalMinimumPortfolioCheckBox.Position = [505 478 197 22];

            % Create ComputeESonHistoricalDataCheckBox
            app.ComputeESonHistoricalDataCheckBox = uicheckbox(app.OptimizationTab);
            app.ComputeESonHistoricalDataCheckBox.Text = 'Compute ES on historical data';
            app.ComputeESonHistoricalDataCheckBox.FontSize = 14;
            app.ComputeESonHistoricalDataCheckBox.Position = [505 417 212 22];

            % Create TotalweightsconstraintEditFieldLabel
            app.TotalweightsconstraintEditFieldLabel = uilabel(app.OptimizationTab);
            app.TotalweightsconstraintEditFieldLabel.HorizontalAlignment = 'right';
            app.TotalweightsconstraintEditFieldLabel.VerticalAlignment = 'top';
            app.TotalweightsconstraintEditFieldLabel.FontSize = 14;
            app.TotalweightsconstraintEditFieldLabel.Position = [33 331 151 22];
            app.TotalweightsconstraintEditFieldLabel.Text = 'Total weights constraint';

            % Create TotalWeightsConstraintEditField
            app.TotalWeightsConstraintEditField = uieditfield(app.OptimizationTab, 'numeric');
            app.TotalWeightsConstraintEditField.Limits = [-3 3];
            app.TotalWeightsConstraintEditField.FontSize = 14;
            app.TotalWeightsConstraintEditField.Position = [349 331 100 22];

            % Create MaxlongexposurebyassetEditFieldLabel
            app.MaxlongexposurebyassetEditFieldLabel = uilabel(app.OptimizationTab);
            app.MaxlongexposurebyassetEditFieldLabel.HorizontalAlignment = 'right';
            app.MaxlongexposurebyassetEditFieldLabel.VerticalAlignment = 'top';
            app.MaxlongexposurebyassetEditFieldLabel.FontSize = 14;
            app.MaxlongexposurebyassetEditFieldLabel.Position = [33 245 179 22];
            app.MaxlongexposurebyassetEditFieldLabel.Text = 'Max long exposure by asset';

            % Create MaxLongExposureByAssetEditField
            app.MaxLongExposureByAssetEditField = uieditfield(app.OptimizationTab, 'numeric');
            app.MaxLongExposureByAssetEditField.Limits = [0 5];
            app.MaxLongExposureByAssetEditField.FontSize = 14;
            app.MaxLongExposureByAssetEditField.Position = [349 245 100 22];

            % Create MaxshortexposurebyassetEditFieldLabel
            app.MaxshortexposurebyassetEditFieldLabel = uilabel(app.OptimizationTab);
            app.MaxshortexposurebyassetEditFieldLabel.HorizontalAlignment = 'right';
            app.MaxshortexposurebyassetEditFieldLabel.VerticalAlignment = 'top';
            app.MaxshortexposurebyassetEditFieldLabel.FontSize = 14;
            app.MaxshortexposurebyassetEditFieldLabel.Position = [33 202 184 22];
            app.MaxshortexposurebyassetEditFieldLabel.Text = 'Max short exposure by asset';

            % Create MaxShortExposureByAssetEditField
            app.MaxShortExposureByAssetEditField = uieditfield(app.OptimizationTab, 'numeric');
            app.MaxShortExposureByAssetEditField.Limits = [-5 0];
            app.MaxShortExposureByAssetEditField.FontSize = 14;
            app.MaxShortExposureByAssetEditField.Position = [349 202 100 22];

            % Create AbsolutemaxshortexposureEditFieldLabel
            app.AbsolutemaxshortexposureEditFieldLabel = uilabel(app.OptimizationTab);
            app.AbsolutemaxshortexposureEditFieldLabel.HorizontalAlignment = 'right';
            app.AbsolutemaxshortexposureEditFieldLabel.VerticalAlignment = 'top';
            app.AbsolutemaxshortexposureEditFieldLabel.FontSize = 14;
            app.AbsolutemaxshortexposureEditFieldLabel.Position = [33 116 187 22];
            app.AbsolutemaxshortexposureEditFieldLabel.Text = 'Absolute max short exposure';

            % Create AbsoluteMaxShortExposureEditField
            app.AbsoluteMaxShortExposureEditField = uieditfield(app.OptimizationTab, 'numeric');
            app.AbsoluteMaxShortExposureEditField.Limits = [-Inf 0];
            app.AbsoluteMaxShortExposureEditField.FontSize = 14;
            app.AbsoluteMaxShortExposureEditField.Position = [349 116 100 22];

            % Create AbsolutemaxlongexposureEditFieldLabel
            app.AbsolutemaxlongexposureEditFieldLabel = uilabel(app.OptimizationTab);
            app.AbsolutemaxlongexposureEditFieldLabel.HorizontalAlignment = 'right';
            app.AbsolutemaxlongexposureEditFieldLabel.VerticalAlignment = 'top';
            app.AbsolutemaxlongexposureEditFieldLabel.FontSize = 14;
            app.AbsolutemaxlongexposureEditFieldLabel.Position = [33 159 182 22];
            app.AbsolutemaxlongexposureEditFieldLabel.Text = 'Absolute max long exposure';

            % Create AbsoluteMaxLongExposureEditField
            app.AbsoluteMaxLongExposureEditField = uieditfield(app.OptimizationTab, 'numeric');
            app.AbsoluteMaxLongExposureEditField.Limits = [0 Inf];
            app.AbsoluteMaxLongExposureEditField.FontSize = 14;
            app.AbsoluteMaxLongExposureEditField.Position = [349 159 100 22];

            % Create ChangeOptimizationTargetWithNoConvergenceCheckBox
            app.ChangeOptimizationTargetWithNoConvergenceCheckBox = uicheckbox(app.OptimizationTab);
            app.ChangeOptimizationTargetWithNoConvergenceCheckBox.ValueChangedFcn = createCallbackFcn(app, @ChangeOptimizationTargetWithNoConvergenceCheckBoxValueChanged, true);
            app.ChangeOptimizationTargetWithNoConvergenceCheckBox.Text = 'Change optimization target with no convergence';
            app.ChangeOptimizationTargetWithNoConvergenceCheckBox.FontSize = 14;
            app.ChangeOptimizationTargetWithNoConvergenceCheckBox.Position = [505 73 327 22];
            app.ChangeOptimizationTargetWithNoConvergenceCheckBox.Value = true;

            % Create MaxtargetriskEditFieldLabel
            app.MaxtargetriskEditFieldLabel = uilabel(app.OptimizationTab);
            app.MaxtargetriskEditFieldLabel.HorizontalAlignment = 'right';
            app.MaxtargetriskEditFieldLabel.VerticalAlignment = 'top';
            app.MaxtargetriskEditFieldLabel.FontSize = 14;
            app.MaxtargetriskEditFieldLabel.Position = [33 73 97 22];
            app.MaxtargetriskEditFieldLabel.Text = 'Max target risk';

            % Create MaxTargetRiskEditField
            app.MaxTargetRiskEditField = uieditfield(app.OptimizationTab, 'numeric');
            app.MaxTargetRiskEditField.FontSize = 14;
            app.MaxTargetRiskEditField.Enable = 'off';
            app.MaxTargetRiskEditField.Position = [349 73 100 22];

            % Create OptimizationriskstepEditFieldLabel
            app.OptimizationriskstepEditFieldLabel = uilabel(app.OptimizationTab);
            app.OptimizationriskstepEditFieldLabel.HorizontalAlignment = 'right';
            app.OptimizationriskstepEditFieldLabel.VerticalAlignment = 'top';
            app.OptimizationriskstepEditFieldLabel.FontSize = 14;
            app.OptimizationriskstepEditFieldLabel.Position = [33 30 139 22];
            app.OptimizationriskstepEditFieldLabel.Text = 'Optimization risk step';

            % Create OptimizationRiskStepEditField
            app.OptimizationRiskStepEditField = uieditfield(app.OptimizationTab, 'numeric');
            app.OptimizationRiskStepEditField.FontSize = 14;
            app.OptimizationRiskStepEditField.Enable = 'off';
            app.OptimizationRiskStepEditField.Position = [349 30 100 22];

            % Create OptimizationLabel
            app.OptimizationLabel = uilabel(app.OptimizationTab);
            app.OptimizationLabel.FontSize = 26;
            app.OptimizationLabel.FontWeight = 'bold';
            app.OptimizationLabel.Position = [338 688 163 31];
            app.OptimizationLabel.Text = 'Optimization';

            % Create ReturnESSwitch
            app.ReturnESSwitch = uiswitch(app.OptimizationTab, 'rocker');
            app.ReturnESSwitch.Items = {'ES', 'Return'};
            app.ReturnESSwitch.ValueChangedFcn = createCallbackFcn(app, @ReturnESSwitchValueChanged, true);
            app.ReturnESSwitch.Enable = 'off';
            app.ReturnESSwitch.FontSize = 11;
            app.ReturnESSwitch.Position = [469 474 13 30];
            app.ReturnESSwitch.Value = 'Return';

            % Create NoConstraintCheckBox
            app.NoConstraintCheckBox = uicheckbox(app.OptimizationTab);
            app.NoConstraintCheckBox.ValueChangedFcn = createCallbackFcn(app, @NoConstraintCheckBoxValueChanged, true);
            app.NoConstraintCheckBox.Text = 'No constraint';
            app.NoConstraintCheckBox.FontSize = 14;
            app.NoConstraintCheckBox.Position = [505 331 104 22];

            % Create RiskParityCheckBox
            app.RiskParityCheckBox = uicheckbox(app.OptimizationTab);
            app.RiskParityCheckBox.ValueChangedFcn = createCallbackFcn(app, @RiskParityCheckBoxValueChanged, true);
            app.RiskParityCheckBox.Text = 'Risk parity';
            app.RiskParityCheckBox.FontSize = 14;
            app.RiskParityCheckBox.Position = [505 586 87 22];

            % Create KeepcurrentPTFweightsCheckBox
            app.KeepcurrentPTFweightsCheckBox = uicheckbox(app.OptimizationTab);
            app.KeepcurrentPTFweightsCheckBox.Text = 'Keep current PTF weights';
            app.KeepcurrentPTFweightsCheckBox.FontSize = 14;
            app.KeepcurrentPTFweightsCheckBox.Position = [505 629 184 22];

            % Create NoConstraintCheckBox_MNE
            app.NoConstraintCheckBox_MNE = uicheckbox(app.OptimizationTab);
            app.NoConstraintCheckBox_MNE.ValueChangedFcn = createCallbackFcn(app, @NoConstraintCheckBox_MNEValueChanged, true);
            app.NoConstraintCheckBox_MNE.Text = 'No constraint';
            app.NoConstraintCheckBox_MNE.FontSize = 14;
            app.NoConstraintCheckBox_MNE.Position = [505 287 104 22];

            % Create MinNetExposureLabel
            app.MinNetExposureLabel = uilabel(app.OptimizationTab);
            app.MinNetExposureLabel.HorizontalAlignment = 'right';
            app.MinNetExposureLabel.VerticalAlignment = 'top';
            app.MinNetExposureLabel.FontSize = 14;
            app.MinNetExposureLabel.Position = [33 287 117 22];
            app.MinNetExposureLabel.Text = 'Min Net Exposure';

            % Create MinNetExposureEditField
            app.MinNetExposureEditField = uieditfield(app.OptimizationTab, 'numeric');
            app.MinNetExposureEditField.Limits = [-3 3];
            app.MinNetExposureEditField.FontSize = 14;
            app.MinNetExposureEditField.Position = [349 287 100 22];

            % Create GetfromcurrentPTFCheckBox
            app.GetfromcurrentPTFCheckBox = uicheckbox(app.OptimizationTab);
            app.GetfromcurrentPTFCheckBox.ValueChangedFcn = createCallbackFcn(app, @GetfromcurrentPTFCheckBoxValueChanged, true);
            app.GetfromcurrentPTFCheckBox.Text = 'Get from current PTF';
            app.GetfromcurrentPTFCheckBox.FontSize = 14;
            app.GetfromcurrentPTFCheckBox.Position = [618 331 154 22];

            % Create GetfromcurrentPTFCheckBox_MNE
            app.GetfromcurrentPTFCheckBox_MNE = uicheckbox(app.OptimizationTab);
            app.GetfromcurrentPTFCheckBox_MNE.ValueChangedFcn = createCallbackFcn(app, @GetfromcurrentPTFCheckBox_MNEValueChanged, true);
            app.GetfromcurrentPTFCheckBox_MNE.Text = 'Get from current PTF';
            app.GetfromcurrentPTFCheckBox_MNE.FontSize = 14;
            app.GetfromcurrentPTFCheckBox_MNE.Position = [618 287 154 22];

            % Create ArmaGarchTab
            app.ArmaGarchTab = uitab(app.TabGroup);
            app.ArmaGarchTab.Title = 'ArmaGarch';

            % Create ArmaGarchCheckBox
            app.ArmaGarchCheckBox = uicheckbox(app.ArmaGarchTab);
            app.ArmaGarchCheckBox.Text = 'ArmaGarch';
            app.ArmaGarchCheckBox.FontSize = 14;
            app.ArmaGarchCheckBox.Position = [372 628 94 22];

            % Create ChunkslengthEditFieldLabel
            app.ChunkslengthEditFieldLabel = uilabel(app.ArmaGarchTab);
            app.ChunkslengthEditFieldLabel.VerticalAlignment = 'top';
            app.ChunkslengthEditFieldLabel.FontSize = 14;
            app.ChunkslengthEditFieldLabel.Position = [37 630 95 22];
            app.ChunkslengthEditFieldLabel.Text = 'Chunks length';

            % Create ChunksLengthEditField
            app.ChunksLengthEditField = uieditfield(app.ArmaGarchTab, 'numeric');
            app.ChunksLengthEditField.Limits = [50 250];
            app.ChunksLengthEditField.FontSize = 14;
            app.ChunksLengthEditField.Position = [182 630 87 22];
            app.ChunksLengthEditField.Value = 50;

            % Create CleanGarchCalibrationCheckBox
            app.CleanGarchCalibrationCheckBox = uicheckbox(app.ArmaGarchTab);
            app.CleanGarchCalibrationCheckBox.Text = 'Clean Garch calibration';
            app.CleanGarchCalibrationCheckBox.FontSize = 14;
            app.CleanGarchCalibrationCheckBox.Position = [372 583 168 22];

            % Create ArmaGarchLabel
            app.ArmaGarchLabel = uilabel(app.ArmaGarchTab);
            app.ArmaGarchLabel.FontSize = 26;
            app.ArmaGarchLabel.FontWeight = 'bold';
            app.ArmaGarchLabel.Position = [346 689 147 31];
            app.ArmaGarchLabel.Text = 'ArmaGarch';

            % Create MovingWindowEditFieldLabel
            app.MovingWindowEditFieldLabel = uilabel(app.ArmaGarchTab);
            app.MovingWindowEditFieldLabel.FontSize = 14;
            app.MovingWindowEditFieldLabel.Position = [37 583 105 22];
            app.MovingWindowEditFieldLabel.Text = 'Moving Window';

            % Create ARMAGARCH_movWinEditField
            app.ARMAGARCH_movWinEditField = uieditfield(app.ArmaGarchTab, 'numeric');
            app.ARMAGARCH_movWinEditField.FontSize = 14;
            app.ARMAGARCH_movWinEditField.Position = [182 583 87 22];

            % Create OutputTab
            app.OutputTab = uitab(app.TabGroup);
            app.OutputTab.Title = 'Output';

            % Create OutputForPdfReportsCheckBox
            app.OutputForPdfReportsCheckBox = uicheckbox(app.OutputTab);
            app.OutputForPdfReportsCheckBox.Text = 'Output for pdf reports';
            app.OutputForPdfReportsCheckBox.FontSize = 14;
            app.OutputForPdfReportsCheckBox.Position = [524 634 155 22];

            % Create OutputLabel
            app.OutputLabel = uilabel(app.OutputTab);
            app.OutputLabel.FontSize = 26;
            app.OutputLabel.FontWeight = 'bold';
            app.OutputLabel.Position = [374 690 91 31];
            app.OutputLabel.Text = 'Output';

            % Create ConfidencelevelusedforxlsoutputEditFieldLabel
            app.ConfidencelevelusedforxlsoutputEditFieldLabel = uilabel(app.OutputTab);
            app.ConfidencelevelusedforxlsoutputEditFieldLabel.HorizontalAlignment = 'right';
            app.ConfidencelevelusedforxlsoutputEditFieldLabel.FontSize = 14;
            app.ConfidencelevelusedforxlsoutputEditFieldLabel.Position = [31 634 229 22];
            app.ConfidencelevelusedforxlsoutputEditFieldLabel.Text = 'Confidence level used for xls output';

            % Create ConfidenceLevelUsedForXlsOutputEditField
            app.ConfidenceLevelUsedForXlsOutputEditField = uieditfield(app.OutputTab, 'numeric');
            app.ConfidenceLevelUsedForXlsOutputEditField.Limits = [0.9 0.999];
            app.ConfidenceLevelUsedForXlsOutputEditField.FontSize = 14;
            app.ConfidenceLevelUsedForXlsOutputEditField.Position = [275 634 100 22];
            app.ConfidenceLevelUsedForXlsOutputEditField.Value = 0.9;

            % Create PathsTab
            app.PathsTab = uitab(app.TabGroup);
            app.PathsTab.Title = 'Paths';

            % Create DashboardBrowseButton
            app.DashboardBrowseButton = uibutton(app.PathsTab, 'push');
            app.DashboardBrowseButton.ButtonPushedFcn = createCallbackFcn(app, @DashboardBrowseButtonPushed, true);
            app.DashboardBrowseButton.FontSize = 14;
            app.DashboardBrowseButton.Position = [715 636 100 26];
            app.DashboardBrowseButton.Text = 'Browse...';

            % Create EquityPTFToInvUniverseBrowseButton
            app.EquityPTFToInvUniverseBrowseButton = uibutton(app.PathsTab, 'push');
            app.EquityPTFToInvUniverseBrowseButton.ButtonPushedFcn = createCallbackFcn(app, @EquityPTFToInvUniverseBrowseButtonPushed, true);
            app.EquityPTFToInvUniverseBrowseButton.FontSize = 14;
            app.EquityPTFToInvUniverseBrowseButton.Position = [715 563 100 26];
            app.EquityPTFToInvUniverseBrowseButton.Text = 'Browse...';

            % Create InvestmentUniverseBrowseButton
            app.InvestmentUniverseBrowseButton = uibutton(app.PathsTab, 'push');
            app.InvestmentUniverseBrowseButton.ButtonPushedFcn = createCallbackFcn(app, @InvestmentUniverseBrowseButtonPushed, true);
            app.InvestmentUniverseBrowseButton.FontSize = 14;
            app.InvestmentUniverseBrowseButton.Position = [715 490 100 26];
            app.InvestmentUniverseBrowseButton.Text = 'Browse...';

            % Create OutputRiskBrowseButton
            app.OutputRiskBrowseButton = uibutton(app.PathsTab, 'push');
            app.OutputRiskBrowseButton.ButtonPushedFcn = createCallbackFcn(app, @OutputRiskBrowseButtonPushed, true);
            app.OutputRiskBrowseButton.FontSize = 14;
            app.OutputRiskBrowseButton.Position = [715 417 100 26];
            app.OutputRiskBrowseButton.Text = 'Browse...';

            % Create DashboardLabel
            app.DashboardLabel = uilabel(app.PathsTab);
            app.DashboardLabel.VerticalAlignment = 'top';
            app.DashboardLabel.FontSize = 14;
            app.DashboardLabel.Position = [39 638 168 22];
            app.DashboardLabel.Text = 'Dashboard: ';

            % Create DashboardPathAndFileNameEditField
            app.DashboardPathAndFileNameEditField = uieditfield(app.PathsTab, 'text');
            app.DashboardPathAndFileNameEditField.Editable = 'off';
            app.DashboardPathAndFileNameEditField.FontSize = 14;
            app.DashboardPathAndFileNameEditField.Position = [206 638 498 22];

            % Create EquityPTFToInvUniverseLabel
            app.EquityPTFToInvUniverseLabel = uilabel(app.PathsTab);
            app.EquityPTFToInvUniverseLabel.VerticalAlignment = 'top';
            app.EquityPTFToInvUniverseLabel.FontSize = 14;
            app.EquityPTFToInvUniverseLabel.Position = [39 565 168 22];
            app.EquityPTFToInvUniverseLabel.Text = 'EquityPTFToInvUniverse:';

            % Create EquityPTFToInvUpathAndFileNameEditField
            app.EquityPTFToInvUpathAndFileNameEditField = uieditfield(app.PathsTab, 'text');
            app.EquityPTFToInvUpathAndFileNameEditField.Editable = 'off';
            app.EquityPTFToInvUpathAndFileNameEditField.FontSize = 14;
            app.EquityPTFToInvUpathAndFileNameEditField.Position = [206 565 498 22];

            % Create InvestmentUniverseLabel
            app.InvestmentUniverseLabel = uilabel(app.PathsTab);
            app.InvestmentUniverseLabel.VerticalAlignment = 'top';
            app.InvestmentUniverseLabel.FontSize = 14;
            app.InvestmentUniverseLabel.Position = [39 492 168 22];
            app.InvestmentUniverseLabel.Text = 'Investment Universe:';

            % Create InvestmentUniversePathAndFileNameEditField
            app.InvestmentUniversePathAndFileNameEditField = uieditfield(app.PathsTab, 'text');
            app.InvestmentUniversePathAndFileNameEditField.Editable = 'off';
            app.InvestmentUniversePathAndFileNameEditField.FontSize = 14;
            app.InvestmentUniversePathAndFileNameEditField.Position = [206 492 498 22];

            % Create OutputRiskMeasuresLabel
            app.OutputRiskMeasuresLabel = uilabel(app.PathsTab);
            app.OutputRiskMeasuresLabel.VerticalAlignment = 'top';
            app.OutputRiskMeasuresLabel.FontSize = 14;
            app.OutputRiskMeasuresLabel.Position = [39 419 168 22];
            app.OutputRiskMeasuresLabel.Text = 'Output Risk Measures:';

            % Create OutRiskMeasuresPathAndFileNameEditField
            app.OutRiskMeasuresPathAndFileNameEditField = uieditfield(app.PathsTab, 'text');
            app.OutRiskMeasuresPathAndFileNameEditField.Editable = 'off';
            app.OutRiskMeasuresPathAndFileNameEditField.FontSize = 14;
            app.OutRiskMeasuresPathAndFileNameEditField.Position = [206 419 498 22];

            % Create PathsLabel
            app.PathsLabel = uilabel(app.PathsTab);
            app.PathsLabel.FontSize = 26;
            app.PathsLabel.FontWeight = 'bold';
            app.PathsLabel.Position = [381 688 76 31];
            app.PathsLabel.Text = 'Paths';

            % Create ReportDirectoryLabel
            app.ReportDirectoryLabel = uilabel(app.PathsTab);
            app.ReportDirectoryLabel.VerticalAlignment = 'top';
            app.ReportDirectoryLabel.FontSize = 14;
            app.ReportDirectoryLabel.Position = [39 347 168 22];
            app.ReportDirectoryLabel.Text = 'Report Directory';

            % Create ReportDirectoryPathEditField
            app.ReportDirectoryPathEditField = uieditfield(app.PathsTab, 'text');
            app.ReportDirectoryPathEditField.Editable = 'off';
            app.ReportDirectoryPathEditField.FontSize = 14;
            app.ReportDirectoryPathEditField.Position = [206 347 498 22];

            % Create ReportDirectoryBrowseButton
            app.ReportDirectoryBrowseButton = uibutton(app.PathsTab, 'push');
            app.ReportDirectoryBrowseButton.ButtonPushedFcn = createCallbackFcn(app, @ReportDirectoryBrowseButtonPushed, true);
            app.ReportDirectoryBrowseButton.FontSize = 14;
            app.ReportDirectoryBrowseButton.Position = [715 345 100 26];
            app.ReportDirectoryBrowseButton.Text = 'Browse...';
        end
    end
    
    methods (Access = public)

        % Construct app
        function app = SettingsEquityDesk_UI(varargin)

            % Create and configure components
            createComponents(app)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.SettingsEquityDeskUIFigure)
        end
    end
end