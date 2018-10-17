classdef xlsInputParamsValidation < InputsMgmtAndValidation.DataValidation
    % implementation of the abstract DataValidation class designed to
    % validate input parameters provided by external xls file (see
    % InitialParametersfromXL.m)
    
    properties (SetAccess = protected)
        dataValidated;
    end
    
    methods
        function  PV = xlsInputParamsValidation(data2Validate)
            PV = PV@InputsMgmtAndValidation.DataValidation(data2Validate);
            PV.dataValidated.Valid = true(1);
            PV.dataValidated = data2Validate;
            PV.Validate;
            
        end % constructor
        
        function Validate(PV)
            disp('Inputs Validation: initial parameters');
            
            
            errorCnt = 0; % not used for now
            warningCnt = 0; % not used for now
            
            % consistency between 'SubjectiveViews ' and
            % 'ScenariosStructures'
            subjViews = PV.data2Validate.SubjectiveViews;
            scenarioStruct = PV.data2Validate.ScenariosStructures;
            if subjViews & isempty(scenarioStruct)
               warningCnt = warningCnt + 1;
               WarningMsg = ['The SubjectiveViews flag is set to true, but no subjective views have been provided - THE FLAG WILL AUTOMATICALLY BE SET TO false'];
               PV.dataValidated.Warning.identifier  = 'xlsInputParamsValidation:InconsistentScenariosStructAndSubjViewsFlag';
               PV.dataValidated.Warning.message = WarningMsg;
               PV.dataValidated.SubjectiveViews = false(1); % AUTOMATIC CORRECTION 
               PV.dataValidated.SubjectiveViewsWeight = 0; % AUTOMATIC CORRECTION 
               PV.dataValidated.PriorWeight = 1; % AUTOMATIC CORRECTION
               PV.WarningsTriggers = true(1); % trigger warning mgmt
               
            elseif ~subjViews & ~isempty(scenarioStruct)
               warningCnt = warningCnt + 1;
               WarningMsg = ['The SubjectiveViews flag is set to false, but subjective views have been provided - THE FLAG WILL AUTOMATICALLY BE SET TO true'];
               PV.dataValidated.Warning.identifier  = 'xlsInputParamsValidation:InconsistentScenariosStructAndSubjViewsFlag';
               PV.dataValidated.Warning.message = WarningMsg;
               PV.dataValidated.SubjectiveViews = true(1); % AUTOMATIC CORRECTION 
               PV.WarningsTriggers = true(1); % trigger warning mgmt
            end
            
            if ~PV.data2Validate.riskAnalysisFlag
                if datenum(PV.data2Validate.history_end_date) == datenum(PV.data2Validate.StartDay)
                    warningCnt = warningCnt + 1;
                    WarningMsg = ['Backtest is not possible if the investment start date = history end date - THE START INVESTMENT DATE WILL BE PUT 10 -MIN INTERVAL CHANGES- BEFORE THE HISTORY END DATE'];
                    PV.dataValidated.Warning.identifier  = 'inputDatesValidation:InconsistentSartDayAndBacktestFlag';
                    PV.dataValidated.Warning.message = WarningMsg;
                    
                    HED = datenum(PV.data2Validate.history_end_date);
                    MIC = PV.data2Validate.min_interval_changes;
                    StartDay = HED - 10*MIC;
                    while ~isbusday(StartDay)
                        StartDay = busdate(StartDay,-1);
                    end
                    PV.dataValidated.StartDay = datestr(StartDay); % AUTOMATIC CORRECTION
                    PV.WarningsTriggers = true(1); % trigger warning mgmt
                end
            end
            
            % WARNING on ConstrainedTotWgts
%             ConstrTotWgts = PV.data2Validate.ConstrainedTotWgts;
%             if isempty(ConstrTotWgts)
%                 warningCnt = warningCnt + 1;
%                 WarningMsg = ['The Constrained total weight of the Optimized Portfolio is empty: if a total net exposure of the optimized portfolio is needed, must be indicated in this field (1.0 = 100% net long)'];
%                 PV.dataValidated.Warning.identifier  = 'xlsInputParamsValidation:ConstrainedTotWgtsEmpty';
%                 PV.dataValidated.Warning.message = WarningMsg;
%                 PV.WarningsTriggers = true(1); % trigger warning mgmt
%             end
           
            % ... APPEND MORE ERRORS/WARNINGS MGMT
            
        end % method Validate
    end % methods
    
end % classdef

