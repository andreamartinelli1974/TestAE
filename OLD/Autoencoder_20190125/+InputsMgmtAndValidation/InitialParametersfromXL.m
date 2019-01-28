function DAA_params = InitialParametersfromXL(Pathparams ,desiredSetup)

% lists of CDD/IR curves and Single indices available
DAA_params.curves2beRead.CDS_SheetName = ['CDS_Curves']; % Sheet of Investment_Universe (empty if no CDS curves are needed)
DAA_params.curves2beRead.IR_SheetName = ['IR_Curves'];   % same for IR curves
DAA_params.curves2beRead.SingleIndices = ['Single_Indices']; % ... and single indices
DAA_params.curves2beRead.IRC2beBtStrapped = ['IRC2beBtStrapped']; % ... and curves to be used for bootstrapping
DAA_params.curves2beRead.VolaEquity = ['VolaEquity']; % ... and implied vola surfaces for equity options
DAA_params.configFile4IrCurvesBtStrap = ['Curve_Structure.xlsx'];
DAA_params.SetUpName = desiredSetup;


% Load AA parameters spreadsheet;
All_Parameters = readtable([Pathparams 'InitialParametersXLS.xlsm'],'ReadRowNames',true,'ReadVariableNames',false, ...
    'Sheet','All_Parameters');
% Choose setup and evaluate settings based on XLS file.
SelectedParams = All_Parameters({desiredSetup},:);
Allvars = table2cell(All_Parameters({'Setups/Portfolios'},:));
Allvalues = table2cell(SelectedParams);

% Read file containing path definitions for AA
All_Paths = readtable([Pathparams 'pathsDefinitions.xls'],'ReadRowNames',true,'ReadVariableNames',false, ...
    'Sheet','paths');
SelectedParamsTmp = All_Paths({desiredSetup},:);
AllvarsTmp = table2cell(All_Paths({'Row1'},:));
AllvaluesTmp = table2cell(SelectedParamsTmp);

% ... putting all together and assigining AA parameters
Allvars = [Allvars,AllvarsTmp];
Allvalues = [Allvalues,AllvaluesTmp];

for i =2:length(Allvars)
    %i
    %[Allvars{i} ,'=', Allvalues{i}] % For debugging purposes.
    disp(['Assigning parameter: ', [Allvars{i} ,'=', Allvalues{i}]]);
        eval([Allvars{i} ,'=', Allvalues{i}]);
    
end
DAA_params.Horizon = DAA_params.Horizon./252; % TO CONVERT IN YEARFRACT
end