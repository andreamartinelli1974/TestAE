classdef CreateScenarioEquityDesk_UI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        CreateScenarioEquityDeskUIFigure  matlab.ui.Figure
        SaveMenu                       matlab.ui.container.Menu
        SubjectnameLabel               matlab.ui.control.Label
        SubjectnameEditField           matlab.ui.control.EditField
        AssetsViewsDropDown            matlab.ui.control.DropDown
        AddViewButton                  matlab.ui.control.Button
        RemoveViewButton               matlab.ui.control.Button
        ClearViewsListButton           matlab.ui.control.Button
        RemoveSubjViewButton           matlab.ui.control.Button
        ClearSubjViewsListButton       matlab.ui.control.Button
        SubjectiveviewnameEditFieldLabel  matlab.ui.control.Label
        SubjectiveviewnameEditField    matlab.ui.control.EditField
        AssetsViewsListBox             matlab.ui.control.ListBox
        CreateSubjectiveViewButton     matlab.ui.control.Button
        CreateScenarioButton           matlab.ui.control.Button
        CreatedsubjectiveviewsListBoxLabel  matlab.ui.control.Label
        CreatedsubjectiveviewsListBox  matlab.ui.control.ListBox
        RemoveScenarioButton           matlab.ui.control.Button
        ClearScenariosListButton       matlab.ui.control.Button
        CreatedscenariosListBoxLabel   matlab.ui.control.Label
        ScenariosListBox               matlab.ui.control.ListBox
        ScenarionameEditFieldLabel     matlab.ui.control.Label
        ScenarionameEditField          matlab.ui.control.EditField
    end


    properties (Access = public)
        AA_DashBoardApp                 % AA_DashBoard app
        AA_DashBoardScenariosStructures % Scenarios structures coming from AA_DashBoard app
        SubjectsNames                   % To store the inserted subjects names for a given scenario
        SubjViewsNames                  % To store the inserted views names for a given scenario
        AssetsViewsNames                % To store the inserted single assets views for every subject and subj view
    end


    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, AA_DashBoardApp, AA_DashBoardScenariosStructures)
            % Get the information coming from AA_DashBoardApp
            app.AA_DashBoardApp = AA_DashBoardApp;
            app.AA_DashBoardScenariosStructures = AA_DashBoardScenariosStructures; % These are the scenarios structures 
            for i=1:numel(app.AA_DashBoardScenariosStructures)
                app.ScenariosListBox.Items{i} = cell2mat(fieldnames(app.AA_DashBoardScenariosStructures{i})); 
            end
            % Get all the views written within the sheet "Views"
            [~,views] = xlsread(app.AA_DashBoardApp.Settings.InvestmentUniversePathAndFileName,'Views','A:A');
            views(1) = [];
            % Fill the views drop down
            app.AssetsViewsDropDown.Items = views;
        end

        % Button pushed function: AddViewButton
        function AddViewButtonPushed(app, event)
            % Check if the view has been added already
            hasAssetViewBeenAddedBefore = find(strcmp(app.AssetsViewsListBox.Items,app.AssetsViewsDropDown.Value),1);
            % If it has not been added already, add it to the list
            if isempty(hasAssetViewBeenAddedBefore)
                ViewName = app.AssetsViewsDropDown.Value;
                app.AssetsViewsListBox.Items = [app.AssetsViewsListBox.Items{:},{ViewName}];
            end    
        end

        % Button pushed function: RemoveViewButton
        function RemoveViewButtonPushed(app, event)
            % If nothing in the list has been selected, then select the first item
            if isempty(app.AssetsViewsListBox.Value)
                app.AssetsViewsListBox.Value = app.AssetsViewsListBox.Items(1);
            end  
            % If the list is not empty, remove the selected item
            if ~isempty(app.AssetsViewsListBox.Items)
                SelectedView = find( strcmp(app.AssetsViewsListBox.Items,app.AssetsViewsListBox.Value),1 );
                app.AssetsViewsListBox.Items(SelectedView) = [];
            end    
        end

        % Button pushed function: ClearViewsListButton
        function ClearViewsListButtonPushed(app, event)
            if ~isempty(app.AssetsViewsListBox.Items)
                % Ask the user to confirm the action
                choice = questdlg('Are you sure you want to remove all the items?','Clear List','Yes','No','No');
                % Clear the list
                if strcmp(choice,'Yes')
                    app.AssetsViewsListBox.Items = {};
                end
            end
        end

        % Button pushed function: CreateSubjectiveViewButton
        function CreateSubjectiveViewButtonPushed(app, event)
            % If the single assets views list, the subject name and the subjective view
            % name have been set, then the subjective view is created.
            if ~isempty(app.AssetsViewsListBox.Items) && ...
               ~isempty(app.SubjectnameEditField.Value) && ...
               ~isempty(app.SubjectiveviewnameEditField.Value)
            
                % Get the list of the already created subjective views
                CreatedSubjectiveViews = app.CreatedsubjectiveviewsListBox.Items;
                % Get the subject name inserted by user, then add it to the list of thecreated subjects,
                % which is used to check that the user does not insert the same subject name two times
                % and to build "ScenarioStructure" in "CreateScenarioButton".
                % Same for the view name inserted by the user
                if isempty(CreatedSubjectiveViews)
                    app.SubjectsNames{1} = app.SubjectnameEditField.Value;
                    app.SubjViewsNames{1} = app.SubjectiveviewnameEditField.Value;
                    app.CreatedsubjectiveviewsListBox.Items = strcat(app.SubjectsNames{1},{' - '},app.SubjViewsNames{1},{': '},strjoin(app.AssetsViewsListBox.Items,', '));
                    % Make "app.SubjectsNames" a valid matlab variable name and update "app.AssetsViewsNames"
                    subjectNamesValidatedTmp = matlab.lang.makeValidName({app.SubjectsNames{1}});
                    subjectNamesValidated = subjectNamesValidatedTmp{1};
                    app.AssetsViewsNames.(subjectNamesValidated) = app.AssetsViewsListBox.Items;
                    % Clear "AssetsViewsListBox" and "SubjectnameEditField", update "SubjectiveviewnameEditField"
                    app.AssetsViewsListBox.Items = {};
                    app.SubjectnameEditField.Value = '';
                    app.SubjectiveviewnameEditField.Value = ['View' num2str(numel(app.CreatedsubjectiveviewsListBox.Items) + 1)];
                    app.CreateScenarioButton.Enable = 'on';
                else
                    NumOfCreatedSubjectiveViews = numel(CreatedSubjectiveViews);
                    % Check if the subject or view names have been used already
                    tmpSubjName = app.SubjectnameEditField.Value;
                    tmpViewName = app.SubjectiveviewnameEditField.Value;
                    subjectHasBeenCreatedIndex = find( strcmp(app.SubjectsNames,tmpSubjName),1 );
                    viewHasBeenCreatedIndex = find( strcmp(app.SubjViewsNames,tmpViewName),1 );
                    % If they have not been used before, then update the subjects and views names lists
                    if isempty( subjectHasBeenCreatedIndex )
                        if isempty( viewHasBeenCreatedIndex )
                            app.SubjectsNames{NumOfCreatedSubjectiveViews + 1} = tmpSubjName;
                            app.SubjViewsNames{NumOfCreatedSubjectiveViews + 1} = tmpViewName;
                            app.CreatedsubjectiveviewsListBox.Items = vertcat(app.CreatedsubjectiveviewsListBox.Items,strcat(app.SubjectsNames{NumOfCreatedSubjectiveViews + 1},{' - '},app.SubjViewsNames{NumOfCreatedSubjectiveViews + 1},{': '},strjoin(app.AssetsViewsListBox.Items,', ')));
                            % Make "app.SubjectsNames" a valid matlab variable name and update "app.AssetsViewsNames"
                            subjectNamesValidatedTmp = matlab.lang.makeValidName({app.SubjectsNames{NumOfCreatedSubjectiveViews + 1}});
                            subjectNamesValidated = subjectNamesValidatedTmp{1};
                            app.AssetsViewsNames.(subjectNamesValidated) = app.AssetsViewsListBox.Items;
                            % Clear "AssetsViewsListBox" and "SubjectnameEditField", update "SubjectiveviewnameEditField"
                            app.AssetsViewsListBox.Items = {};
                            app.SubjectnameEditField.Value = '';
                            app.SubjectiveviewnameEditField.Value = ['View' num2str(numel(app.CreatedsubjectiveviewsListBox.Items) + 1)];
                            app.CreateScenarioButton.Enable = 'on';
                        else 
                            questdlg('A view with this name has already been created','Cancelled','Ok','Ok');
                        end
                    else
                        questdlg('A subject with this name has already been created','Cancelled','Ok','Ok');
                    end    
                end
            else
                % If some field has not been compiled
                questdlg('One or more of the following fields are empty: subject name, subjective view name, subjective view list.','Cancelled','Ok','Ok');
            end
        end

        % Button pushed function: RemoveSubjViewButton
        function RemoveSubjViewButtonPushed(app, event)
            if ~isempty(app.CreatedsubjectiveviewsListBox.Items)
                % Ask the user to confirm the action
                choice = questdlg('Are you sure you want to remove this subjective view?','Remove Subjective View','Yes','No','No');
                % If confirmed and if the list of the already created subjective views is
                % not empty, then remove the subjective view with the inserted name
                if strcmp(choice,'Yes')
                    % If nothing in the list has been selected, then select the first item
                    if isempty(app.CreatedsubjectiveviewsListBox.Value)
                        app.CreatedsubjectiveviewsListBox.Value = app.CreatedsubjectiveviewsListBox.Items(1);
                    end   
                    % Get the selected subjective view index
                    SelectedSubjectiveView = find( strcmp(app.CreatedsubjectiveviewsListBox.Items,app.CreatedsubjectiveviewsListBox.Value),1 );
                    % Clear the selected subjective view
                    app.CreatedsubjectiveviewsListBox.Items(SelectedSubjectiveView) = [];
                    % Remove subject and view names from their lists
                    app.SubjectsNames(SelectedSubjectiveView) = [];
                    app.SubjViewsNames(SelectedSubjectiveView) = [];
                    if isempty(app.CreatedsubjectiveviewsListBox.Items)
                        app.CreateScenarioButton.Enable = 'off';
                    end   
                end 
            end
        end

        % Button pushed function: ClearSubjViewsListButton
        function ClearSubjViewsListButtonPushed(app, event)
            if ~isempty(app.CreatedsubjectiveviewsListBox.Items)
                % Ask the user to confirm action
                choice = questdlg('Are you sure you want to remove all the items?','Clear List','Yes','No','No');
                % Clear the list, the subjects names list and the views names list
                if strcmp(choice,'Yes')
                    app.CreatedsubjectiveviewsListBox.Items = {};
                    app.SubjectsNames = {};
                    app.SubjViewsNames = {};
                    app.SubjectiveviewnameEditField.Value = 'View1';
                    app.CreateScenarioButton.Enable = 'off';
                end
            end
        end

        % Button pushed function: CreateScenarioButton
        function CreateScenarioButtonPushed(app, event)
            % If a subjective view has been created at least, then create a new scenario
            if ~isempty(app.CreatedsubjectiveviewsListBox.Items) 
                    ScenarioLabel = app.ScenarionameEditField.Value;
                    % Check if a name has been inserted, otherwise exit the dialog box
                    if ~isempty(ScenarioLabel)
                        % A scenario with the same inserted name is searched in the created scenarios list box.
                        alreadyCreatedScenarioIndex = find( strcmp(app.ScenariosListBox.Items,ScenarioLabel),1 );
                        % If the inserted scenario name has never been used
                        if isempty(alreadyCreatedScenarioIndex)
                            % Ask the user to confirm the action
                            choice = questdlg(['Do you want to create ' ScenarioLabel ' ?'],'Create scenario','Yes','No','No');
                            
                            if strcmp(choice,'Yes')
                                % Make scenario name inserted by the user a valide matlab variable. Note that this is only used to bulid
                                % "ScenarioStructure", it is not visualized by the user
                                scenarioLabelValidatedTmp = matlab.lang.makeValidName({ScenarioLabel});
                                scenarioLabelValidated = scenarioLabelValidatedTmp{1};
                                ScenarioStructure.(scenarioLabelValidated).FieldsFromUser.UserScenarioLabel = ScenarioLabel;
                                ScenarioStructure.(scenarioLabelValidated).FieldsFromUser.UserSubjectsNames = app.SubjectsNames;
                                ScenarioStructure.(scenarioLabelValidated).FieldsFromUser.UserSubjViewsNames = app.SubjViewsNames;
                                
                                subjectsNamesValidated = matlab.lang.makeValidName(app.SubjectsNames);
                                subjViewsNamesValidated = matlab.lang.makeValidName(app.SubjViewsNames);
                                
                                % Create the ScenarioStructure
                                for i = 1:numel(subjectsNamesValidated)
                                    for j = 1:numel(app.AssetsViewsNames.(subjectsNamesValidated{i}))
                                        ScenarioStructure.(scenarioLabelValidated).(subjectsNamesValidated{i}).(subjViewsNamesValidated{i}){j} = app.AssetsViewsNames.(subjectsNamesValidated{i}){j};
                                    end
                                end    
                                % Append the new scenario to the ScenariosStructures coming from AA_DashBoardApp
                                if isempty( app.AA_DashBoardScenariosStructures )
                                    ScenarioIndex = 1;
                                else
                                    ScenarioIndex = numel(app.AA_DashBoardScenariosStructures) + 1;
                                end 
                                app.AA_DashBoardScenariosStructures{ScenarioIndex} = ScenarioStructure;
                                % Reset all fields
                                app.CreatedsubjectiveviewsListBox.Items = {};
                                app.SubjectsNames = {};
                                app.SubjViewsNames = {};
                                app.ScenarionameEditField.Value = '';
                                app.SubjectiveviewnameEditField.Value = 'View1';
                                for i=1:numel(app.AA_DashBoardScenariosStructures)
                                    app.ScenariosListBox.Items{i} = cell2mat(fieldnames(app.AA_DashBoardScenariosStructures{i})); 
                                end
                                app.CreateScenarioButton.Enable = 'off';
                            end
                        else
                            % If there is an already created scenario with the inserted name, ask the user again.
                            questdlg('A scenario with this name already exists','Name needed','Ok','Ok');
                        end
                    else 
                        % If the scenario name has not been inserted, ask the user again
                        questdlg('A name for scenario is needed','Name needed','Ok','Ok');
                    end          
            else
                % If no subjective view has been created
                questdlg('Subjective views list is empty','Cancelled','Ok','Ok');
            end    
        end

        % Close request function: CreateScenarioEquityDeskUIFigure
        function CreateScenarioEquityDeskUIFigureCloseRequest(app, event)
            % Ask the user to confirm the action
            choice = questdlg('Do you want to save current scenarios data?','Closing','Yes','No','Yes');
                
            if strcmp(choice,'Yes')
                % Update the AA_DashBoardApp ScenariosStructures
                updateScenarios(app.AA_DashBoardApp,app.AA_DashBoardScenariosStructures);    
                % Update SubjectiveScenariosTable within AA_DashBoardEquityDeskUI
                updateSubjectiveScenariosTable(app.AA_DashBoardApp,app.AA_DashBoardScenariosStructures);
                % Re-Enable AA_DashBoardUI components
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

        % Button pushed function: RemoveScenarioButton
        function RemoveScenarioButtonPushed(app, event)
            if ~isempty(app.ScenariosListBox.Items)
                % The user is asked to confirm action.
                choice = questdlg('Are you sure you want to remove this scenario?','Remove Scenario','Yes','No','No');
                % If the scenarios list box is not empty, then the selected scenario is removed from the list.
                if strcmp(choice,'Yes') && ~isempty(app.ScenariosListBox.Items)
                    % If nothing has been selected within the scenarios list, select the first item
                    if isempty(app.ScenariosListBox.Value)
                        app.ScenariosListBox.Value = app.ScenariosListBox.Items(1);
                    end    
                    % Remove the selected scenario                    
                    SelectedScenario = find( strcmp(app.ScenariosListBox.Items,app.ScenariosListBox.Value),1 );
                    app.ScenariosListBox.Items(SelectedScenario) = [];
                    % Remove scenario from ScenariosStructures cell array
                    app.AA_DashBoardScenariosStructures(SelectedScenario) = [];
                end   
            end
        end

        % Button pushed function: ClearScenariosListButton
        function ClearScenariosListButtonPushed(app, event)
            if ~isempty(app.ScenariosListBox.Items)
                % The user is asked to confirm action.
                choice = questdlg('Are you sure you want to remove all the items?','Clear List','Yes','No','No');
            
                % If action is confirmed, clear scenarios list and disable the Run button.
                if strcmp(choice,'Yes') 
                    app.ScenariosListBox.Items = {};
                    % Clear the ScenariosStructures cell array
                    app.AA_DashBoardScenariosStructures(:) = [];
                end
            end
        end

        % Menu selected function: SaveMenu
        function SaveMenuSelected(app, event)
            % Ask the user to confirm action
            choice = questdlg('Do you want to save the current scenarios?','Saving scenarios','Yes','Cancel','Yes');
           
            if strcmp(choice,'Yes')
                % Update the AA_DashBoardApp ScenariosStructures
                updateScenarios(app.AA_DashBoardApp,app.AA_DashBoardScenariosStructures);  
                % Update SubjectiveScenariosTable within AA_DashBoardEquityDeskUI
                updateSubjectiveScenariosTable(app.AA_DashBoardApp,app.AA_DashBoardScenariosStructures);
                % Re-Enable what has to be enabled
                enableAA_DashBoardComponents(app.AA_DashBoardApp);
                % Close this app
                delete(app);
            end      
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create CreateScenarioEquityDeskUIFigure
            app.CreateScenarioEquityDeskUIFigure = uifigure;
            app.CreateScenarioEquityDeskUIFigure.Position = [100 100 828 691];
            app.CreateScenarioEquityDeskUIFigure.Name = 'CreateScenarioEquityDesk';
            app.CreateScenarioEquityDeskUIFigure.Resize = 'off';
            app.CreateScenarioEquityDeskUIFigure.CloseRequestFcn = createCallbackFcn(app, @CreateScenarioEquityDeskUIFigureCloseRequest, true);

            % Create SaveMenu
            app.SaveMenu = uimenu(app.CreateScenarioEquityDeskUIFigure);
            app.SaveMenu.MenuSelectedFcn = createCallbackFcn(app, @SaveMenuSelected, true);
            app.SaveMenu.Text = 'Save';

            % Create SubjectnameLabel
            app.SubjectnameLabel = uilabel(app.CreateScenarioEquityDeskUIFigure);
            app.SubjectnameLabel.HorizontalAlignment = 'right';
            app.SubjectnameLabel.VerticalAlignment = 'top';
            app.SubjectnameLabel.FontSize = 14;
            app.SubjectnameLabel.Position = [113 638 102 18];
            app.SubjectnameLabel.Text = 'Subject name:';

            % Create SubjectnameEditField
            app.SubjectnameEditField = uieditfield(app.CreateScenarioEquityDeskUIFigure, 'text');
            app.SubjectnameEditField.HorizontalAlignment = 'center';
            app.SubjectnameEditField.FontSize = 14;
            app.SubjectnameEditField.Position = [244 636 346 22];
            app.SubjectnameEditField.Value = 'Insert subject name';

            % Create AssetsViewsDropDown
            app.AssetsViewsDropDown = uidropdown(app.CreateScenarioEquityDeskUIFigure);
            app.AssetsViewsDropDown.Items = {};
            app.AssetsViewsDropDown.FontSize = 16;
            app.AssetsViewsDropDown.Position = [53 545 163 30];
            app.AssetsViewsDropDown.Value = {};

            % Create AddViewButton
            app.AddViewButton = uibutton(app.CreateScenarioEquityDeskUIFigure, 'push');
            app.AddViewButton.ButtonPushedFcn = createCallbackFcn(app, @AddViewButtonPushed, true);
            app.AddViewButton.FontSize = 14;
            app.AddViewButton.Position = [52 501 164 31];
            app.AddViewButton.Text = 'Add View';

            % Create RemoveViewButton
            app.RemoveViewButton = uibutton(app.CreateScenarioEquityDeskUIFigure, 'push');
            app.RemoveViewButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveViewButtonPushed, true);
            app.RemoveViewButton.FontSize = 14;
            app.RemoveViewButton.Position = [52 457 164 31];
            app.RemoveViewButton.Text = 'Remove View';

            % Create ClearViewsListButton
            app.ClearViewsListButton = uibutton(app.CreateScenarioEquityDeskUIFigure, 'push');
            app.ClearViewsListButton.ButtonPushedFcn = createCallbackFcn(app, @ClearViewsListButtonPushed, true);
            app.ClearViewsListButton.FontSize = 14;
            app.ClearViewsListButton.Position = [52 413 164 31];
            app.ClearViewsListButton.Text = 'Clear Views List';

            % Create RemoveSubjViewButton
            app.RemoveSubjViewButton = uibutton(app.CreateScenarioEquityDeskUIFigure, 'push');
            app.RemoveSubjViewButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveSubjViewButtonPushed, true);
            app.RemoveSubjViewButton.FontSize = 14;
            app.RemoveSubjViewButton.Position = [52 317 162 31];
            app.RemoveSubjViewButton.Text = 'Remove Subj. View';

            % Create ClearSubjViewsListButton
            app.ClearSubjViewsListButton = uibutton(app.CreateScenarioEquityDeskUIFigure, 'push');
            app.ClearSubjViewsListButton.ButtonPushedFcn = createCallbackFcn(app, @ClearSubjViewsListButtonPushed, true);
            app.ClearSubjViewsListButton.FontSize = 14;
            app.ClearSubjViewsListButton.Position = [52 273 162 31];
            app.ClearSubjViewsListButton.Text = 'Clear Subj. Views List';

            % Create SubjectiveviewnameEditFieldLabel
            app.SubjectiveviewnameEditFieldLabel = uilabel(app.CreateScenarioEquityDeskUIFigure);
            app.SubjectiveviewnameEditFieldLabel.HorizontalAlignment = 'right';
            app.SubjectiveviewnameEditFieldLabel.VerticalAlignment = 'top';
            app.SubjectiveviewnameEditFieldLabel.FontSize = 14;
            app.SubjectiveviewnameEditFieldLabel.Position = [70 599 146 18];
            app.SubjectiveviewnameEditFieldLabel.Text = 'Subjective view name:';

            % Create SubjectiveviewnameEditField
            app.SubjectiveviewnameEditField = uieditfield(app.CreateScenarioEquityDeskUIFigure, 'text');
            app.SubjectiveviewnameEditField.HorizontalAlignment = 'center';
            app.SubjectiveviewnameEditField.FontSize = 14;
            app.SubjectiveviewnameEditField.Position = [244 597 346 22];
            app.SubjectiveviewnameEditField.Value = 'View1';

            % Create AssetsViewsListBox
            app.AssetsViewsListBox = uilistbox(app.CreateScenarioEquityDeskUIFigure);
            app.AssetsViewsListBox.Items = {};
            app.AssetsViewsListBox.FontSize = 14;
            app.AssetsViewsListBox.Position = [244 413 346 162];
            app.AssetsViewsListBox.Value = {};

            % Create CreateSubjectiveViewButton
            app.CreateSubjectiveViewButton = uibutton(app.CreateScenarioEquityDeskUIFigure, 'push');
            app.CreateSubjectiveViewButton.ButtonPushedFcn = createCallbackFcn(app, @CreateSubjectiveViewButtonPushed, true);
            app.CreateSubjectiveViewButton.FontSize = 14;
            app.CreateSubjectiveViewButton.Position = [621 413 161 35];
            app.CreateSubjectiveViewButton.Text = 'Create Subjective View';

            % Create CreateScenarioButton
            app.CreateScenarioButton = uibutton(app.CreateScenarioEquityDeskUIFigure, 'push');
            app.CreateScenarioButton.ButtonPushedFcn = createCallbackFcn(app, @CreateScenarioButtonPushed, true);
            app.CreateScenarioButton.BackgroundColor = [0.9608 0.9608 0.9608];
            app.CreateScenarioButton.FontSize = 14;
            app.CreateScenarioButton.Enable = 'off';
            app.CreateScenarioButton.Position = [621 182 161 35];
            app.CreateScenarioButton.Text = 'Create Scenario';

            % Create CreatedsubjectiveviewsListBoxLabel
            app.CreatedsubjectiveviewsListBoxLabel = uilabel(app.CreateScenarioEquityDeskUIFigure);
            app.CreatedsubjectiveviewsListBoxLabel.HorizontalAlignment = 'right';
            app.CreatedsubjectiveviewsListBoxLabel.VerticalAlignment = 'top';
            app.CreatedsubjectiveviewsListBoxLabel.FontSize = 14;
            app.CreatedsubjectiveviewsListBoxLabel.Position = [336 376 162 18];
            app.CreatedsubjectiveviewsListBoxLabel.Text = 'Created subjective views';

            % Create CreatedsubjectiveviewsListBox
            app.CreatedsubjectiveviewsListBox = uilistbox(app.CreateScenarioEquityDeskUIFigure);
            app.CreatedsubjectiveviewsListBox.Items = {};
            app.CreatedsubjectiveviewsListBox.FontSize = 14;
            app.CreatedsubjectiveviewsListBox.Position = [244 270 346 104];
            app.CreatedsubjectiveviewsListBox.Value = {};

            % Create RemoveScenarioButton
            app.RemoveScenarioButton = uibutton(app.CreateScenarioEquityDeskUIFigure, 'push');
            app.RemoveScenarioButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveScenarioButtonPushed, true);
            app.RemoveScenarioButton.FontSize = 14;
            app.RemoveScenarioButton.Position = [52 120 162 31];
            app.RemoveScenarioButton.Text = 'Remove Scenario';

            % Create ClearScenariosListButton
            app.ClearScenariosListButton = uibutton(app.CreateScenarioEquityDeskUIFigure, 'push');
            app.ClearScenariosListButton.ButtonPushedFcn = createCallbackFcn(app, @ClearScenariosListButtonPushed, true);
            app.ClearScenariosListButton.FontSize = 14;
            app.ClearScenariosListButton.Position = [52 47 162 31];
            app.ClearScenariosListButton.Text = 'Clear Scenarios List';

            % Create CreatedscenariosListBoxLabel
            app.CreatedscenariosListBoxLabel = uilabel(app.CreateScenarioEquityDeskUIFigure);
            app.CreatedscenariosListBoxLabel.HorizontalAlignment = 'center';
            app.CreatedscenariosListBoxLabel.VerticalAlignment = 'top';
            app.CreatedscenariosListBoxLabel.FontSize = 14;
            app.CreatedscenariosListBoxLabel.Position = [356 153 121 18];
            app.CreatedscenariosListBoxLabel.Text = 'Created scenarios';

            % Create ScenariosListBox
            app.ScenariosListBox = uilistbox(app.CreateScenarioEquityDeskUIFigure);
            app.ScenariosListBox.Items = {};
            app.ScenariosListBox.FontSize = 14;
            app.ScenariosListBox.Position = [244 47 346 104];
            app.ScenariosListBox.Value = {};

            % Create ScenarionameEditFieldLabel
            app.ScenarionameEditFieldLabel = uilabel(app.CreateScenarioEquityDeskUIFigure);
            app.ScenarionameEditFieldLabel.HorizontalAlignment = 'right';
            app.ScenarionameEditFieldLabel.VerticalAlignment = 'top';
            app.ScenarionameEditFieldLabel.FontSize = 16;
            app.ScenarionameEditFieldLabel.Position = [97 191 118 20];
            app.ScenarionameEditFieldLabel.Text = 'Scenario name:';

            % Create ScenarionameEditField
            app.ScenarionameEditField = uieditfield(app.CreateScenarioEquityDeskUIFigure, 'text');
            app.ScenarionameEditField.HorizontalAlignment = 'center';
            app.ScenarionameEditField.FontSize = 14;
            app.ScenarionameEditField.Position = [244 182 346 35];
            app.ScenarionameEditField.Value = 'Insert scenario name';
        end
    end

    methods (Access = public)

        % Construct app
        function app = CreateScenarioEquityDesk_UI(varargin)

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
            delete(app.CreateScenarioEquityDeskUIFigure)
        end
    end
end