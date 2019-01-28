classdef AA_DashBoardEquityDesk_UI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        AA_DashboardEquityDeskUIFigure  matlab.ui.Figure
        ScenarioAnalysisMenu            matlab.ui.container.Menu
        SubjectiveScenarioMenu          matlab.ui.container.Menu
        HedgingMenu                     matlab.ui.container.Menu
        EquityMenu                      matlab.ui.container.Menu
        SettingsMenu                    matlab.ui.container.Menu
        ChangeSettingsMenu              matlab.ui.container.Menu
        TabGroup                        matlab.ui.container.TabGroup
        MainTab                         matlab.ui.container.Tab
        PortfoliosListLabel             matlab.ui.control.Label
        PortfoliosListBox               matlab.ui.control.ListBox
        PortfoliosDropDown              matlab.ui.control.DropDown
        AddPortfolioButton              matlab.ui.control.Button
        RemovePortfolioButton           matlab.ui.control.Button
        ClearPortfoliosListButton       matlab.ui.control.Button
        RunButton                       matlab.ui.control.Button
        SummaryTab                      matlab.ui.container.Tab
        HedgePortfolioTable             matlab.ui.control.Table
        SubjectiveScenariosTable        matlab.ui.control.Table
        ButtonGroup                     matlab.ui.container.ButtonGroup
        HedgePortfolioButton            matlab.ui.control.ToggleButton
        SubjectiveScenariosButton       matlab.ui.control.ToggleButton
    end


    properties (Access = public)
        AA_DashboardEquityDeskData  % All datas to be loaded when this UI is run
        SettingsApp                 % App to set settings
        Settings                    % Settings inherited from settings App
        CreateScenarioApp           % App to create a scenario
        ScenariosStructures         % Cell array of scenarios structures
        HedgePrtApp                 % App to add hedging portfolio
        HedgePrt                    % Hedging portfolio structure
        Closed = false(1)           % boolean used to understand when the GUI can be closed (e.g. in the main)
    end

    methods (Access = public)
        % To update AA_DashboardEquityDeskData loaded when this UI is run
        function updateAA_DashboardEquityDeskData(app)
            app.AA_DashboardEquityDeskData.Settings = app.Settings;
            app.AA_DashboardEquityDeskData.ScenariosStructures = app.ScenariosStructures;
            app.AA_DashboardEquityDeskData.HedgePrt = app.HedgePrt;
        end
        
        % To update portfolios drop-down with those coming from settings UI
        function updatePortfoliosDropDown(app,allPortfolios)
            app.PortfoliosDropDown.Items = allPortfolios;
        end
        
        % To update portfolios list used by default with those coming from settings UI
        function updatePortfoliosList(app,defaultPortfolios)
            app.PortfoliosListBox.Items = defaultPortfolios;
        end
        
        % To update settings coming from SettingsEquityDesk_UI
        function updateDashBoardAppSettings(app,settings)
            app.Settings = settings;
        end

        % To update scenarios coming from CreateScenarioEquityDesk_UI
        function updateScenarios(app,scenariosStructures)
            app.ScenariosStructures = scenariosStructures;
        end     
            
        % To update hedging portfolio coming from HedgePrtEquityDesk_UI
        function updateHedgePrt(app,hedgePrt)
            app.HedgePrt = hedgePrt;
        end
        
        % To update "HedgePortfolioTable" with data coming from HedgePrtEquityDesk_UI
        function updateHedgePrtTable(app,hedgePrt)
            assetTypes = fieldnames(hedgePrt);
            HedgePortfolioData = {};
            for i=1:length(assetTypes)
                for j=1:size(hedgePrt.(assetTypes{i}),1)
                    HedgePortfolioData = vertcat(HedgePortfolioData,{assetTypes{i},hedgePrt.(assetTypes{i}){j,1},hedgePrt.(assetTypes{i}){j,2},hedgePrt.(assetTypes{i}){j,3}});  
                end
            end
            app.HedgePortfolioTable.Data = HedgePortfolioData;    
        end    
    
        function updateSubjectiveScenariosTable(app,subjectiveScenarios)
            app.SubjectiveScenariosTable.Data = {};
            numOfScenarios = numel(subjectiveScenarios);
            for i=1:numOfScenarios
                scenarioLabel_tmp = fieldnames(subjectiveScenarios{i});
                scenarioLabel = scenarioLabel_tmp{1};
                subjectsNames = fieldnames(subjectiveScenarios{i}.(scenarioLabel));
                % Subjects contains "FieldsFromUser" field coming from scenario, here it is removed 
                subjectsNames(find(strcmp(subjectsNames,'FieldsFromUser'),1))=[];
                for j=1:numel(subjectsNames)
                   viewName_tmp = fieldnames(subjectiveScenarios{i}.(scenarioLabel).(subjectsNames{j}));
                   viewName = viewName_tmp{1};
                   subjectsAndViewsNames{j} = strjoin({subjectsNames{j},viewName},' - ');
                   allAssetsViews = strjoin(subjectiveScenarios{i}.(scenarioLabel).(subjectsNames{j}).(viewName),'; ');
                   app.SubjectiveScenariosTable.Data = vertcat(app.SubjectiveScenariosTable.Data,{scenarioLabel,subjectsAndViewsNames{j},allAssetsViews});
                end
            end
        end
        
        function disableAA_DashBoardComponents(app)
            % Disable all buttons and related components
            app.EquityMenu.Enable = 'off';
            app.ChangeSettingsMenu.Enable = 'off';
            app.SubjectiveScenarioMenu.Enable = 'off';
            app.RunButton.Enable = 'off';
        end
        
        function enableAA_DashBoardComponents(app)
            % Re-Enable what has to be enabled
            app.AA_DashboardEquityDeskUIFigure.Visible = 'off';
            app.AA_DashboardEquityDeskUIFigure.Visible = 'on';
            app.EquityMenu.Enable = 'on';
            app.ChangeSettingsMenu.Enable = 'on';
            app.SubjectiveScenarioMenu.Enable = 'on';
            if ~isempty(app.PortfoliosListBox.Items)
                app.RunButton.Enable = 'on';
            else
                app.RunButton.Enable = 'off';
            end
        end

        % function to update the app.Settings structure with default paths values
        function updateAppSettingsPaths(app)
            app.Settings.EquityPTFToInvUpathAndFileName = [cd,'\Inputs\EquityPTFtoInvestmentUniverse-totest.xlsm'];
            app.Settings.InvestmentUniversePathAndFileName = [cd,'\Inputs\Investment_Universe.xls'];
            app.Settings.OutRiskMeasuresPathAndFileName = [cd,'\Outputs\outRiskExcel\outputRisk.xslx'];
            app.Settings.ReportDirectoryPath = [cd,'\Outputs'];
        end
        
        % function to update a single setup paths values with default paths values
        function updateSetupPaths(app,setupFileName)
            load(['UI_Data\setups\' setupFileName],'SettingsData');
            SettingsData{1}.EquityPTFToInvUpathAndFileName = [cd,'\Inputs\EquityPTFtoInvestmentUniverse-totest.xlsm'];
            SettingsData{1}.InvestmentUniversePathAndFileName = [cd,'\Inputs\Investment_Universe.xls'];
            SettingsData{1}.OutRiskMeasuresPathAndFileName = [cd,'\Outputs\outRiskExcel\outputRisk.xlsx'];
            SettingsData{1}.ReportDirectoryPath = [cd,'\Outputs'];
            save(['UI_Data\setups\' setupFileName],'SettingsData');
            clear SettingsData;
        end
    
        % function to update the app.Settings structure with default dates values
        function updateAppSettingsDates(app)
            app.Settings.HistoryEndDate = datestr(busdate(datetime('today'),-1),'mm/dd/yyyy');
            app.Settings.FirstInvestmentDate = datestr(busdate(datetime('today'),-1),'mm/dd/yyyy');
        end
    
        % function to update a single setup paths values with default dates values
        function updateSetupDates(app,setupFileName)
            load(['UI_Data\setups\' setupFileName],'SettingsData');
            SettingsData{1}.HistoryEndDate = datestr(busdate(datetime('today'),-1),'mm/dd/yyyy');
            SettingsData{1}.FirstInvestmentDate = datestr(busdate(datetime('today'),-1),'mm/dd/yyyy');
            save(['UI_Data\setups\' setupFileName],'SettingsData');
            clear SettingsData;
        end
        
    end % end public methods

    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % Load saved UI datas
            if exist('UI_Data/AA_DashboardEquityDeskData.mat','file') ~= 0
                load UI_Data/AA_DashboardEquityDeskData.mat AA_DashboardEquityDeskData;
                app.AA_DashboardEquityDeskData = AA_DashboardEquityDeskData;
                app.Settings = app.AA_DashboardEquityDeskData.Settings;
                app.ScenariosStructures = app.AA_DashboardEquityDeskData.ScenariosStructures;
                app.HedgePrt = app.AA_DashboardEquityDeskData.HedgePrt;
                % Set the list of portfolios names to fill the drop-down menu
                app.PortfoliosDropDown.Items = app.Settings.AllPortfolios;
                % Fill the portfolios list box
                app.PortfoliosListBox.Items = app.Settings.PrtUsedByDefault;
            else
                app.AA_DashboardEquityDeskData = struct;
                app.Settings = struct;
                app.ScenariosStructures = {};
                app.HedgePrt = struct;
            end
            
            % Check if userId.mat has been saved. If it has, then check if current userId
            % is that which has been previously saved. If the user has never used this app 
            % then save the new userId and update paths in app.Settings and for all saved setups.
            % Do the same if no userId.mat has previously been saved.
            setupFolderInfo = dir('UI_Data/setups');
            if exist('UI_Data/userId.mat','file') ~= 0
                load UI_Data/userId.mat userId;
                if ~strcmp(getenv('username'),userId)
                    userId = getenv('username');
                    save('UI_Data/userId.mat','userId');
                    updateAppSettingsPaths(app);
                    % If setups folder is not empty, update setups
                    if numel(setupFolderInfo) > 2
                        for i=3:numel(setupFolderInfo)
                            updateSetupPaths(app,setupFolderInfo(i).name);
                        end
                    end
                end
            else
                userId = getenv('username');
                save('UI_Data/userId.mat','userId');
                updateAppSettingsPaths(app);
                % If setups folder is not empty, update setups
                if numel(setupFolderInfo) > 2
                    for i=3:numel(setupFolderInfo)
                        updateSetupPaths(app,setupFolderInfo(i).name);
                    end
                end
            end
            
            % Update dates for UI settings and for each setup. To do this,
            % check if this is the first run of today, then update dates if it is.
            % Otherwise do not update anything
            if exist('UI_Data/currentDate.mat','file') ~= 0
                load UI_Data/currentDate.mat 
                if ~strcmp(currentDate,datestr(today,'mm/dd/yyyy'))
                    currentDate = datestr(today,'mm/dd/yyyy');
                    save('UI_Data/currentDate.mat','currentDate');
                    updateAppSettingsDates(app);
                    % If setups folder is not empty, update dates
                    if numel(setupFolderInfo) > 2
                        for i=3:numel(setupFolderInfo)
                            updateSetupDates(app,setupFolderInfo(i).name);
                        end
                    end
                end
            else
                currentDate = datestr(today,'mm/dd/yyyy');
                save('UI_Data/currentDate.mat','currentDate');
                updateAppSettingsDates(app);
                % If setups folder is not empty, update dates
                if numel(setupFolderInfo) > 2
                    for i=3:numel(setupFolderInfo)
                        updateSetupDates(app,setupFolderInfo(i).name);
                    end
                end
            end

            % Fill HedgePrtTable with previously saved data
            updateHedgePrtTable(app,app.HedgePrt);
            % Fill SubjectiveScenariosTable with previously saved data
            updateSubjectiveScenariosTable(app,app.ScenariosStructures);
            % Enable Run button if PortfoliosListBox is not empty
            if ~isempty(app.PortfoliosListBox.Items)
                app.RunButton.Enable = 'on';
            end
        end

        % Close request function: AA_DashboardEquityDeskUIFigure
        function AA_DashboardEquityDeskUIFigureCloseRequest(app, event)
            % Ask the user to confirm action
            choice = questdlg('Are you sure you want to close?','Closing','Yes','No','No');
            
            if strcmp(choice,'Yes')
                % Save current data
                updateAA_DashboardEquityDeskData(app);
                AA_DashboardEquityDeskData = app.AA_DashboardEquityDeskData;
                save UI_Data/AA_DashboardEquityDeskData.mat AA_DashboardEquityDeskData;
                % Delete all apps
                delete(app.CreateScenarioApp);
                delete(app.SettingsApp);
                delete(app.HedgePrtApp);
                delete(app);
            end
        end

        % Button pushed function: AddPortfolioButton
        function AddPortfolioButtonPushed(app, event)
            % Check if the selected portfolio has been added already
            hasPortfolioBeenAddedBefore = find(strcmp(app.PortfoliosListBox.Items,app.PortfoliosDropDown.Value),1);
            
            if isempty(hasPortfolioBeenAddedBefore)
                % Append the selected portfolio to the list of the already added portfolios
                app.PortfoliosListBox.Items = [app.PortfoliosListBox.Items{:},{app.PortfoliosDropDown.Value}];
                app.RunButton.Enable = 'on';
            end     
        end

        % Button pushed function: RemovePortfolioButton
        function RemovePortfolioButtonPushed(app, event)
            % If nothing in the list has been selected, then select the first item
            if isempty(app.PortfoliosListBox.Value)
                app.PortfoliosListBox.Value = app.PortfoliosListBox.Items(1);
            end    
            % If the portfolios list box is not empty, then the selected portfolio is removed from the list.
            if ~isempty(app.PortfoliosListBox.Items)
                SelectedPortfolioIndex = find(strcmp(app.PortfoliosListBox.Items,app.PortfoliosListBox.Value),1);
                app.PortfoliosListBox.Items(SelectedPortfolioIndex) = [];
            end   
            % If the portfolios list box is empty (after removal), disable the Run button
            if isempty(app.PortfoliosListBox.Items)
                app.RunButton.Enable = 'off';
            end
        end

        % Button pushed function: ClearPortfoliosListButton
        function ClearPortfoliosListButtonPushed(app, event)
            if ~isempty(app.PortfoliosListBox.Items)
                % The user is asked to confirm the action.
                choice = questdlg('Are you sure you want to remove all the items?','Clear List','Yes','No','No');
            
                % If action is confirmed, clear portfolios list and disable the Run button. 
                if strcmp(choice,'Yes') 
                    app.PortfoliosListBox.Items = {};
                    app.RunButton.Enable = 'off';
                end
            end
        end

        % Menu selected function: ChangeSettingsMenu
        function ChangeSettingsMenuSelected(app, event)
            % Disable all buttons and related components
            disableAA_DashBoardComponents(app); 
            % Create SettingsEquityDesk_UI object
            app.SettingsApp = UIs.SettingsEquityDesk_UI(app,app.Settings);                 
        end

        % Button pushed function: RunButton
        function RunButtonPushed(app, event)
            % Ask the user to confirm action
            choice = questdlg(['Would you like to run AA_DashBoard with the ' app.Settings.SetupList.Val ' setup?'],'Confirm Run','Yes','No','Yes');

            % If the action is confirmed, then the AA_main code is run.
            switch choice
                case 'Yes'
                    % Disable all buttons in AA_DashBoarApp
                    disableAA_DashBoardComponents(app);
                    
                    updateAA_DashboardEquityDeskData(app);
                    AA_DashboardEquityDeskData = app.AA_DashboardEquityDeskData;
                    save UI_Data/AA_DashboardEquityDeskData.mat AA_DashboardEquityDeskData;
                    
                    % Set Closed property to true
                    app.Closed = true(1);
                case 'No'
                    questdlg('Run cancelled','Cancelled','Ok','Ok');
            end
        end

        % Menu selected function: EquityMenu
        function EquityMenuSelected(app, event)
            % Disable all buttons and related components
            disableAA_DashBoardComponents(app); 
            % Create HedgePrtEquityDesk_UI object
            app.HedgePrtApp = UIs.HedgePrtEquityDesk_UI(app,app.HedgePrt);  
        end

        % Menu selected function: SubjectiveScenarioMenu
        function SubjectiveScenarioMenuSelected(app, event)
            % Disable all buttons and related components
            disableAA_DashBoardComponents(app);
            % Open CreateScenarioEquityDesk_UI
            app.CreateScenarioApp = UIs.CreateScenarioEquityDesk_UI(app,app.ScenariosStructures);  
        end

        % Selection changed function: ButtonGroup
        function ButtonGroupSelectionChanged(app, event)
            selectedButton = app.ButtonGroup.SelectedObject;
            
            if strcmp(selectedButton.Text,'Hedge Portfolio')
                app.HedgePortfolioTable.Visible = 'on';
                app.SubjectiveScenariosTable.Visible = 'off';
            elseif strcmp(selectedButton.Text,'Subjective Scenarios')
                app.SubjectiveScenariosTable.Visible = 'on';
                app.HedgePortfolioTable.Visible = 'off';
            end    
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create AA_DashboardEquityDeskUIFigure
            app.AA_DashboardEquityDeskUIFigure = uifigure;
            app.AA_DashboardEquityDeskUIFigure.Position = [100 100 877 541];
            app.AA_DashboardEquityDeskUIFigure.Name = 'AA_DashboardEquityDesk';
            app.AA_DashboardEquityDeskUIFigure.Resize = 'off';
            app.AA_DashboardEquityDeskUIFigure.CloseRequestFcn = createCallbackFcn(app, @AA_DashboardEquityDeskUIFigureCloseRequest, true);

            % Create ScenarioAnalysisMenu
            app.ScenarioAnalysisMenu = uimenu(app.AA_DashboardEquityDeskUIFigure);
            app.ScenarioAnalysisMenu.Text = 'Scenario Analysis';

            % Create SubjectiveScenarioMenu
            app.SubjectiveScenarioMenu = uimenu(app.ScenarioAnalysisMenu);
            app.SubjectiveScenarioMenu.MenuSelectedFcn = createCallbackFcn(app, @SubjectiveScenarioMenuSelected, true);
            app.SubjectiveScenarioMenu.Text = 'Subjective Scenario';

            % Create HedgingMenu
            app.HedgingMenu = uimenu(app.AA_DashboardEquityDeskUIFigure);
            app.HedgingMenu.Text = 'Hedging';

            % Create EquityMenu
            app.EquityMenu = uimenu(app.HedgingMenu);
            app.EquityMenu.MenuSelectedFcn = createCallbackFcn(app, @EquityMenuSelected, true);
            app.EquityMenu.Text = 'Equity';

            % Create SettingsMenu
            app.SettingsMenu = uimenu(app.AA_DashboardEquityDeskUIFigure);
            app.SettingsMenu.Text = 'Settings';

            % Create ChangeSettingsMenu
            app.ChangeSettingsMenu = uimenu(app.SettingsMenu);
            app.ChangeSettingsMenu.MenuSelectedFcn = createCallbackFcn(app, @ChangeSettingsMenuSelected, true);
            app.ChangeSettingsMenu.Text = 'Change settings';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.AA_DashboardEquityDeskUIFigure);
            app.TabGroup.TabLocation = 'bottom';
            app.TabGroup.Position = [0 1 877 541];

            % Create MainTab
            app.MainTab = uitab(app.TabGroup);
            app.MainTab.Title = 'Main';

            % Create PortfoliosListLabel
            app.PortfoliosListLabel = uilabel(app.MainTab);
            app.PortfoliosListLabel.HorizontalAlignment = 'right';
            app.PortfoliosListLabel.VerticalAlignment = 'top';
            app.PortfoliosListLabel.FontSize = 14;
            app.PortfoliosListLabel.Position = [339 428 94 18];
            app.PortfoliosListLabel.Text = ' Portfolios List';

            % Create PortfoliosListBox
            app.PortfoliosListBox = uilistbox(app.MainTab);
            app.PortfoliosListBox.Items = {};
            app.PortfoliosListBox.FontSize = 14;
            app.PortfoliosListBox.Position = [443 226 291 222];
            app.PortfoliosListBox.Value = {};

            % Create PortfoliosDropDown
            app.PortfoliosDropDown = uidropdown(app.MainTab);
            app.PortfoliosDropDown.Items = {};
            app.PortfoliosDropDown.FontSize = 14;
            app.PortfoliosDropDown.Position = [145 414 159 34];
            app.PortfoliosDropDown.Value = {};

            % Create AddPortfolioButton
            app.AddPortfolioButton = uibutton(app.MainTab, 'push');
            app.AddPortfolioButton.ButtonPushedFcn = createCallbackFcn(app, @AddPortfolioButtonPushed, true);
            app.AddPortfolioButton.FontSize = 14;
            app.AddPortfolioButton.Position = [145 352 159 32];
            app.AddPortfolioButton.Text = 'Add Portfolio';

            % Create RemovePortfolioButton
            app.RemovePortfolioButton = uibutton(app.MainTab, 'push');
            app.RemovePortfolioButton.ButtonPushedFcn = createCallbackFcn(app, @RemovePortfolioButtonPushed, true);
            app.RemovePortfolioButton.FontSize = 14;
            app.RemovePortfolioButton.Position = [145 288 159 32];
            app.RemovePortfolioButton.Text = 'Remove Portfolio';

            % Create ClearPortfoliosListButton
            app.ClearPortfoliosListButton = uibutton(app.MainTab, 'push');
            app.ClearPortfoliosListButton.ButtonPushedFcn = createCallbackFcn(app, @ClearPortfoliosListButtonPushed, true);
            app.ClearPortfoliosListButton.FontSize = 14;
            app.ClearPortfoliosListButton.Position = [145 226 159 32];
            app.ClearPortfoliosListButton.Text = 'Clear Portfolios List';

            % Create RunButton
            app.RunButton = uibutton(app.MainTab, 'push');
            app.RunButton.ButtonPushedFcn = createCallbackFcn(app, @RunButtonPushed, true);
            app.RunButton.BackgroundColor = [0.2 0.3294 0.102];
            app.RunButton.FontSize = 18;
            app.RunButton.FontWeight = 'bold';
            app.RunButton.Enable = 'off';
            app.RunButton.Position = [382 95 114 67];
            app.RunButton.Text = 'Run';

            % Create SummaryTab
            app.SummaryTab = uitab(app.TabGroup);
            app.SummaryTab.Title = 'Summary';

            % Create HedgePortfolioTable
            app.HedgePortfolioTable = uitable(app.SummaryTab);
            app.HedgePortfolioTable.ColumnName = {'Type'; 'Ticker'; 'L. bound'; 'U. bound'};
            app.HedgePortfolioTable.ColumnWidth = {120, 'auto', 120, 120};
            app.HedgePortfolioTable.RowName = {};
            app.HedgePortfolioTable.FontSize = 14;
            app.HedgePortfolioTable.Position = [198 63 647 424];

            % Create SubjectiveScenariosTable
            app.SubjectiveScenariosTable = uitable(app.SummaryTab);
            app.SubjectiveScenariosTable.ColumnName = {'Scenario Name'; 'Subject&View Name'; 'Views'};
            app.SubjectiveScenariosTable.ColumnWidth = {175, 175, 'auto'};
            app.SubjectiveScenariosTable.RowName = {};
            app.SubjectiveScenariosTable.FontSize = 14;
            app.SubjectiveScenariosTable.Position = [198 63 647 424];

            % Create ButtonGroup
            app.ButtonGroup = uibuttongroup(app.SummaryTab);
            app.ButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @ButtonGroupSelectionChanged, true);
            app.ButtonGroup.TitlePosition = 'centertop';
            app.ButtonGroup.BackgroundColor = [0.9412 0.9412 0.9412];
            app.ButtonGroup.FontSize = 14;
            app.ButtonGroup.Position = [33 439 155 48];

            % Create HedgePortfolioButton
            app.HedgePortfolioButton = uitogglebutton(app.ButtonGroup);
            app.HedgePortfolioButton.Text = 'Hedge Portfolio';
            app.HedgePortfolioButton.BackgroundColor = [1 1 1];
            app.HedgePortfolioButton.FontSize = 14;
            app.HedgePortfolioButton.Position = [0 -1 155 25];

            % Create SubjectiveScenariosButton
            app.SubjectiveScenariosButton = uitogglebutton(app.ButtonGroup);
            app.SubjectiveScenariosButton.Text = 'Subjective Scenarios';
            app.SubjectiveScenariosButton.BackgroundColor = [1 1 1];
            app.SubjectiveScenariosButton.FontSize = 14;
            app.SubjectiveScenariosButton.Position = [0 23 155 25];
            app.SubjectiveScenariosButton.Value = true;
        end
    end

    methods (Access = public)

        % Construct app
        function app = AA_DashBoardEquityDesk_UI

            % Create and configure components
            createComponents(app)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.AA_DashboardEquityDeskUIFigure)
        end
    end
end