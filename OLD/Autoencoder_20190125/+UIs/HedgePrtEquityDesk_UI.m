classdef HedgePrtEquityDesk_UI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        HedgePrtEquityDeskUIFigure   matlab.ui.Figure
        SaveMenu                     matlab.ui.container.Menu
        TabGroup                     matlab.ui.container.TabGroup
        StocksTab                    matlab.ui.container.Tab
        StocksLabel                  matlab.ui.control.Label
        StockAddAssetButton          matlab.ui.control.Button
        StockClearAllButton          matlab.ui.control.Button
        TickerEditField_7Label       matlab.ui.control.Label
        StockTickerEditField         matlab.ui.control.EditField
        AllocationlowerboundEditField_7Label  matlab.ui.control.Label
        StockAllocationlowerboundEditField  matlab.ui.control.NumericEditField
        AllocationupperboundEditField_7Label  matlab.ui.control.Label
        StockAllocationupperboundEditField  matlab.ui.control.NumericEditField
        StockHedgingportfolioLabel   matlab.ui.control.Label
        StockHedgePrtTable           matlab.ui.control.Table
        StockClearSelectedButton     matlab.ui.control.Button
        StockSelectAllCheckBox       matlab.ui.control.CheckBox
        FuturesTab                   matlab.ui.container.Tab
        FuturesLabel                 matlab.ui.control.Label
        FutureAddAssetButton         matlab.ui.control.Button
        FutureClearAllButton         matlab.ui.control.Button
        FutureHedgingportfolioLabel  matlab.ui.control.Label
        FutureHedgePrtTable          matlab.ui.control.Table
        FutureClearSelectedButton    matlab.ui.control.Button
        FutureSelectAllCheckBox      matlab.ui.control.CheckBox
        TickerEditField_7Label_4     matlab.ui.control.Label
        FutureTickerEditField        matlab.ui.control.EditField
        AllocationlowerboundEditField_7Label_4  matlab.ui.control.Label
        FutureAllocationlowerboundEditField  matlab.ui.control.NumericEditField
        AllocationupperboundEditField_7Label_4  matlab.ui.control.Label
        FutureAllocationupperboundEditField  matlab.ui.control.NumericEditField
        OptionsTab                   matlab.ui.container.Tab
        OptionsLabel                 matlab.ui.control.Label
        OptionAddAssetButton         matlab.ui.control.Button
        OptionClearAllButton         matlab.ui.control.Button
        OptionHedgingportfolioLabel  matlab.ui.control.Label
        OptionHedgePrtTable          matlab.ui.control.Table
        OptionClearSelectedButton    matlab.ui.control.Button
        OptionSelectAllCheckBox      matlab.ui.control.CheckBox
        TickerEditField_7Label_5     matlab.ui.control.Label
        OptionTickerEditField        matlab.ui.control.EditField
        AllocationlowerboundEditField_7Label_5  matlab.ui.control.Label
        OptionAllocationlowerboundEditField  matlab.ui.control.NumericEditField
        AllocationupperboundEditField_7Label_5  matlab.ui.control.Label
        OptionAllocationupperboundEditField  matlab.ui.control.NumericEditField
    end

    properties (Access = public)
        AA_DashBoardApp     % AA_DashBoard app
        HedgePrt            % Structure containing all information about hedging portfolios
    end

    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, AA_DashBoardApp, HedgePrt)
            % Get the information coming from AA_DashBoardApp
            app.AA_DashBoardApp = AA_DashBoardApp;
            % Assign the HedgePrt structure coming from AA_DashBoardApp
            app.HedgePrt = HedgePrt;
            
            % If previously saved datas come from AA_DashboardApp, then they are loaded
            % N.B.: each cell array (e.g., app.HedgePrt.Stocks) has to be concateneted
            % with a cell array of "false" checkbox in the first column to be inserted
            % in its corresponding table (i.e., app.StockHedgePrtTable.Data)
            if ~isempty(app.HedgePrt)
                if isfield(app.HedgePrt,'Stocks')
                    numTicker = size(app.HedgePrt.Stocks,1);
                    falseChecks = {};
                    falseChecks(1:numTicker,1) = {false};
                    app.StockHedgePrtTable.Data = horzcat(falseChecks,app.HedgePrt.Stocks);
                end  
                if isfield(app.HedgePrt,'Futures')
                    numTicker = size(app.HedgePrt.Futures,1);
                    falseChecks = {};
                    falseChecks(1:numTicker,1) = {false};
                    app.FutureHedgePrtTable.Data = horzcat(falseChecks,app.HedgePrt.Futures);
                end
                if isfield(app.HedgePrt,'Options')
                    numTicker = size(app.HedgePrt.Options,1);
                    falseChecks = {};
                    falseChecks(1:numTicker,1) = {false};
                    app.OptionHedgePrtTable.Data = horzcat(falseChecks,app.HedgePrt.Options);
                end
            end    
        end

        % Close request function: HedgePrtEquityDeskUIFigure
        function HedgePrtEquityDeskUIFigureCloseRequest(app, event)
            % Ask the user to confirm the action
            choice = questdlg('Do you want to save the current modifications?','Closing','Yes','No','Yes');
                
            if strcmp(choice,'Yes')
                % If stocks, futures and options datas are not empty, then they are assigned 
                % to HedgePrt structure, otherwise the corresponding fields are removed.
                
                % Stocks
                if ~isempty(app.StockHedgePrtTable.Data)
                    app.HedgePrt.Stocks = app.StockHedgePrtTable.Data(:,2:end);
                else
                    if isfield(app.HedgePrt,'Stocks')
                        app.HedgePrt = rmfield(app.HedgePrt,'Stocks');
                    end    
                end   
                % Futures
                if ~isempty(app.FutureHedgePrtTable.Data)
                    app.HedgePrt.Futures = app.FutureHedgePrtTable.Data(:,2:end);
                else
                    if isfield(app.HedgePrt,'Futures')
                        app.HedgePrt = rmfield(app.HedgePrt,'Futures');
                    end    
                end
                % Options
                if ~isempty(app.OptionHedgePrtTable.Data)
                    app.HedgePrt.Options = app.OptionHedgePrtTable.Data(:,2:end);
                else
                    if isfield(app.HedgePrt,'Options')
                        app.HedgePrt = rmfield(app.HedgePrt,'Options');
                    end    
                end
                
                % HedgePrt structure in AA_DashBoardApp is updated with current datas
                updateHedgePrt(app.AA_DashBoardApp,app.HedgePrt);
                % HedgePrtTable in AA_DashBoardApp is updated
                updateHedgePrtTable(app.AA_DashBoardApp,app.HedgePrt);
                % Enable dashboard components and close current app
                enableAA_DashBoardComponents(app.AA_DashBoardApp);
                delete(app);
            elseif strcmp(choice,'No')
                % Enable dashboard components and close current app
                enableAA_DashBoardComponents(app.AA_DashBoardApp);
                delete(app);
            end
        end

        % Button pushed function: StockAddAssetButton
        function StockAddAssetButtonPushed(app, event)
            if isempty(app.StockHedgePrtTable.Data)
                app.StockHedgePrtTable.Data = {false, app.StockTickerEditField.Value, app.StockAllocationlowerboundEditField.Value, app.StockAllocationupperboundEditField.Value};
            else
                app.StockHedgePrtTable.Data = vertcat(app.StockHedgePrtTable.Data, {false, app.StockTickerEditField.Value, app.StockAllocationlowerboundEditField.Value, app.StockAllocationupperboundEditField.Value});
            end
            app.StockAllocationlowerboundEditField.Value = -1;
            app.StockAllocationupperboundEditField.Value = 1;
            app.StockTickerEditField.Value = '';
        end

        % Button pushed function: StockClearAllButton
        function StockClearAllButtonPushed(app, event)
            % Ask the user to confirm action
            choice = questdlg('Do you want to remove all stocks in your hedging portfolio?','Closing','Yes','No','Yes');
            
            if strcmp(choice,'Yes')
                % Remove all items in "app.StockHedgePrtTable"
                app.StockHedgePrtTable.Data = {};
            end
        end

        % Value changed function: StockSelectAllCheckBox
        function StockSelectAllCheckBoxValueChanged(app, event)
            % If the checkbox is selected, then all items in "app.StockHedgePrtTable"
            % are selected, if it is unchecked, all items are un-selected
            if ~isempty(app.StockHedgePrtTable.Data)
                if app.StockSelectAllCheckBox.Value == false
                    app.StockHedgePrtTable.Data(:,1) = {false};
                else
                    app.StockHedgePrtTable.Data(:,1) = {true};
                end
            end
        end

        % Button pushed function: StockClearSelectedButton
        function StockClearSelectedButtonPushed(app, event)
            % "allSelectedAssets" is a logic array containing ones where there
            % are the selected items in "app.StockHedgePrtTable", zeros otherwise
            allSelectedAssets = all([app.StockHedgePrtTable.Data{:,1}],1);
            % Clear the selected items
            app.StockHedgePrtTable.Data(allSelectedAssets,:) = [];
        end

        % Menu selected function: SaveMenu
        function SaveMenuSelected(app, event)
            % Ask the user to confirm the action
            choice = questdlg('Do you want to save current hedging datas?','Closing','Yes','No','Yes');
                
            if strcmp(choice,'Yes')
                % If stocks, futures and options datas are not empty, then they are assigned 
                % to HedgePrt structure, otherwise the corresponding fields are removed.
                % Stocks
                if ~isempty(app.StockHedgePrtTable.Data)
                    app.HedgePrt.Stocks = app.StockHedgePrtTable.Data(:,2:end);
                else
                    if isfield(app.HedgePrt,'Stocks')
                        app.HedgePrt = rmfield(app.HedgePrt,'Stocks');
                    end    
                end   
                % Futures
                if ~isempty(app.FutureHedgePrtTable.Data)
                    app.HedgePrt.Futures = app.FutureHedgePrtTable.Data(:,2:end);
                else
                    if isfield(app.HedgePrt,'Futures')
                        app.HedgePrt = rmfield(app.HedgePrt,'Futures');
                    end    
                end
                % Options
                if ~isempty(app.OptionHedgePrtTable.Data)
                    app.HedgePrt.Options = app.OptionHedgePrtTable.Data(:,2:end);
                else
                    if isfield(app.HedgePrt,'Options')
                        app.HedgePrt = rmfield(app.HedgePrt,'Options');
                    end    
                end
                % HedgePrt structure in AA_DashBoardApp is updated with current datas
                updateHedgePrt(app.AA_DashBoardApp,app.HedgePrt);
                % HedgePrtTable in AA_DashBoardApp is updated
                updateHedgePrtTable(app.AA_DashBoardApp,app.HedgePrt);
                % Enable dashboard components and close current app
                enableAA_DashBoardComponents(app.AA_DashBoardApp);
                delete(app);
            end
        end

        % Button pushed function: FutureAddAssetButton
        function FutureAddAssetButtonPushed(app, event)
            if isempty(app.FutureHedgePrtTable.Data)
                app.FutureHedgePrtTable.Data = {false, app.FutureTickerEditField.Value, app.FutureAllocationlowerboundEditField.Value, app.FutureAllocationupperboundEditField.Value};
            else
                app.FutureHedgePrtTable.Data = vertcat(app.FutureHedgePrtTable.Data, {false, app.FutureTickerEditField.Value, app.FutureAllocationlowerboundEditField.Value, app.FutureAllocationupperboundEditField.Value});
            end
            app.FutureAllocationlowerboundEditField.Value = -1;
            app.FutureAllocationupperboundEditField.Value = 1;
            app.FutureTickerEditField.Value = '';
        end

        % Button pushed function: FutureClearAllButton
        function FutureClearAllButtonPushed(app, event)
            % Ask the user to confirm action
            choice = questdlg('Do you want to remove all futures in your hedging portfolio?','Closing','Yes','No','Yes');
            
            if strcmp(choice,'Yes')
                % Remove all items in "app.FutureHedgePrtTable"
                app.FutureHedgePrtTable.Data = {};
            end
        end

        % Button pushed function: FutureClearSelectedButton
        function FutureClearSelectedButtonPushed(app, event)
            % "allSelectedAssets" is a logic array containing ones where there
            % are the selected items in "app.FutureHedgePrtTable", zeros otherwise
            allSelectedAssets = all([app.FutureHedgePrtTable.Data{:,1}],1);
            % Clear the selected items
            app.FutureHedgePrtTable.Data(allSelectedAssets,:) = [];
        end

        % Value changed function: FutureSelectAllCheckBox
        function FutureSelectAllCheckBoxValueChanged(app, event)
            % If the checkbox is selected, then all items in "app.FutureHedgePrtTable"
            % are selected, if it is unchecked, all items are un-selected
            if ~isempty(app.FutureHedgePrtTable.Data)
                if app.FutureSelectAllCheckBox.Value == false
                    app.FutureHedgePrtTable.Data(:,1) = {false};
                else
                    app.FutureHedgePrtTable.Data(:,1) = {true};
                end
            end
        end

        % Button pushed function: OptionAddAssetButton
        function OptionAddAssetButtonPushed(app, event)
            if isempty(app.OptionHedgePrtTable.Data)
                app.OptionHedgePrtTable.Data = {false, app.OptionTickerEditField.Value, app.OptionAllocationlowerboundEditField.Value, app.OptionAllocationupperboundEditField.Value};
            else
                app.OptionHedgePrtTable.Data = vertcat(app.OptionHedgePrtTable.Data, {false, app.OptionTickerEditField.Value, app.OptionAllocationlowerboundEditField.Value, app.OptionAllocationupperboundEditField.Value});
            end
            app.OptionAllocationlowerboundEditField.Value = -1;
            app.OptionAllocationupperboundEditField.Value = 1;
            app.OptionTickerEditField.Value = '';
        end

        % Button pushed function: OptionClearAllButton
        function OptionClearAllButtonPushed(app, event)
            % Ask the user to confirm action
            choice = questdlg('Do you want to remove all options in your hedging portfolio?','Closing','Yes','No','Yes');
            
            if strcmp(choice,'Yes')
                % Remove all items in "app.OptionHedgePrtTable"
                app.OptionHedgePrtTable.Data = {};
            end
        end

        % Button pushed function: OptionClearSelectedButton
        function OptionClearSelectedButtonPushed(app, event)
            % "allSelectedAssets" is a logic array containing ones where there
            % are the selected items in "app.OptionHedgePrtTable", zeros otherwise
            allSelectedAssets = all([app.OptionHedgePrtTable.Data{:,1}],1);
            % Clear the selected items
            app.OptionHedgePrtTable.Data(allSelectedAssets,:) = [];
        end

        % Value changed function: OptionSelectAllCheckBox
        function OptionSelectAllCheckBoxValueChanged(app, event)
            % If the checkbox is selected, then all items in "app.OptionHedgePrtTable"
            % are selected, if it is unchecked, all items are un-selected
            if ~isempty(app.OptionHedgePrtTable.Data)
                if app.OptionSelectAllCheckBox.Value == false
                    app.OptionHedgePrtTable.Data(:,1) = {false};
                else
                    app.OptionHedgePrtTable.Data(:,1) = {true};
                end
            end
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create HedgePrtEquityDeskUIFigure
            app.HedgePrtEquityDeskUIFigure = uifigure;
            app.HedgePrtEquityDeskUIFigure.Position = [100 100 924 585];
            app.HedgePrtEquityDeskUIFigure.Name = 'HedgePrtEquityDesk';
            app.HedgePrtEquityDeskUIFigure.Resize = 'off';
            app.HedgePrtEquityDeskUIFigure.CloseRequestFcn = createCallbackFcn(app, @HedgePrtEquityDeskUIFigureCloseRequest, true);

            % Create SaveMenu
            app.SaveMenu = uimenu(app.HedgePrtEquityDeskUIFigure);
            app.SaveMenu.MenuSelectedFcn = createCallbackFcn(app, @SaveMenuSelected, true);
            app.SaveMenu.Text = 'Save';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.HedgePrtEquityDeskUIFigure);
            app.TabGroup.TabLocation = 'left';
            app.TabGroup.Position = [1 23 924 563];

            % Create StocksTab
            app.StocksTab = uitab(app.TabGroup);
            app.StocksTab.Title = 'Stocks';

            % Create StocksLabel
            app.StocksLabel = uilabel(app.StocksTab);
            app.StocksLabel.VerticalAlignment = 'top';
            app.StocksLabel.FontSize = 22;
            app.StocksLabel.FontWeight = 'bold';
            app.StocksLabel.FontColor = [0.6392 0.0784 0.1804];
            app.StocksLabel.Position = [387 514 78 29];
            app.StocksLabel.Text = 'Stocks';

            % Create StockAddAssetButton
            app.StockAddAssetButton = uibutton(app.StocksTab, 'push');
            app.StockAddAssetButton.ButtonPushedFcn = createCallbackFcn(app, @StockAddAssetButtonPushed, true);
            app.StockAddAssetButton.FontSize = 14;
            app.StockAddAssetButton.Position = [74 269 158 25];
            app.StockAddAssetButton.Text = 'Add to Hedge Portfolio';

            % Create StockClearAllButton
            app.StockClearAllButton = uibutton(app.StocksTab, 'push');
            app.StockClearAllButton.ButtonPushedFcn = createCallbackFcn(app, @StockClearAllButtonPushed, true);
            app.StockClearAllButton.FontSize = 14;
            app.StockClearAllButton.Position = [715 238 108 25];
            app.StockClearAllButton.Text = 'Clear All';

            % Create TickerEditField_7Label
            app.TickerEditField_7Label = uilabel(app.StocksTab);
            app.TickerEditField_7Label.HorizontalAlignment = 'right';
            app.TickerEditField_7Label.VerticalAlignment = 'top';
            app.TickerEditField_7Label.FontSize = 14;
            app.TickerEditField_7Label.Position = [21 466 44 18];
            app.TickerEditField_7Label.Text = 'Ticker';

            % Create StockTickerEditField
            app.StockTickerEditField = uieditfield(app.StocksTab, 'text');
            app.StockTickerEditField.FontSize = 14;
            app.StockTickerEditField.Position = [80 465 204 22];

            % Create AllocationlowerboundEditField_7Label
            app.AllocationlowerboundEditField_7Label = uilabel(app.StocksTab);
            app.AllocationlowerboundEditField_7Label.HorizontalAlignment = 'right';
            app.AllocationlowerboundEditField_7Label.VerticalAlignment = 'top';
            app.AllocationlowerboundEditField_7Label.FontSize = 14;
            app.AllocationlowerboundEditField_7Label.Position = [21 399 148 18];
            app.AllocationlowerboundEditField_7Label.Text = 'Allocation lower bound';

            % Create StockAllocationlowerboundEditField
            app.StockAllocationlowerboundEditField = uieditfield(app.StocksTab, 'numeric');
            app.StockAllocationlowerboundEditField.Limits = [-Inf 0];
            app.StockAllocationlowerboundEditField.FontSize = 14;
            app.StockAllocationlowerboundEditField.Position = [184 398 100 22];
            app.StockAllocationlowerboundEditField.Value = -1;

            % Create AllocationupperboundEditField_7Label
            app.AllocationupperboundEditField_7Label = uilabel(app.StocksTab);
            app.AllocationupperboundEditField_7Label.HorizontalAlignment = 'right';
            app.AllocationupperboundEditField_7Label.VerticalAlignment = 'top';
            app.AllocationupperboundEditField_7Label.FontSize = 14;
            app.AllocationupperboundEditField_7Label.Position = [21 332 151 18];
            app.AllocationupperboundEditField_7Label.Text = 'Allocation upper bound';

            % Create StockAllocationupperboundEditField
            app.StockAllocationupperboundEditField = uieditfield(app.StocksTab, 'numeric');
            app.StockAllocationupperboundEditField.Limits = [0 Inf];
            app.StockAllocationupperboundEditField.FontSize = 14;
            app.StockAllocationupperboundEditField.Position = [184 331 100 22];
            app.StockAllocationupperboundEditField.Value = 1;

            % Create StockHedgingportfolioLabel
            app.StockHedgingportfolioLabel = uilabel(app.StocksTab);
            app.StockHedgingportfolioLabel.VerticalAlignment = 'top';
            app.StockHedgingportfolioLabel.FontSize = 14;
            app.StockHedgingportfolioLabel.Position = [327 465 126 20];
            app.StockHedgingportfolioLabel.Text = 'Hedging portfolio';

            % Create StockHedgePrtTable
            app.StockHedgePrtTable = uitable(app.StocksTab);
            app.StockHedgePrtTable.ColumnName = {''; 'Ticker'; 'Lower bound'; 'Upper bound'};
            app.StockHedgePrtTable.ColumnWidth = {30, 'auto', 90, 90};
            app.StockHedgePrtTable.RowName = {};
            app.StockHedgePrtTable.ColumnEditable = [true false false false];
            app.StockHedgePrtTable.FontSize = 14;
            app.StockHedgePrtTable.Position = [441 269 382 218];

            % Create StockClearSelectedButton
            app.StockClearSelectedButton = uibutton(app.StocksTab, 'push');
            app.StockClearSelectedButton.ButtonPushedFcn = createCallbackFcn(app, @StockClearSelectedButtonPushed, true);
            app.StockClearSelectedButton.FontSize = 14;
            app.StockClearSelectedButton.Position = [578 238 108 25];
            app.StockClearSelectedButton.Text = 'Clear Selected';

            % Create StockSelectAllCheckBox
            app.StockSelectAllCheckBox = uicheckbox(app.StocksTab);
            app.StockSelectAllCheckBox.ValueChangedFcn = createCallbackFcn(app, @StockSelectAllCheckBoxValueChanged, true);
            app.StockSelectAllCheckBox.Text = 'Select All';
            app.StockSelectAllCheckBox.FontSize = 14;
            app.StockSelectAllCheckBox.Position = [452 241 80 18];

            % Create FuturesTab
            app.FuturesTab = uitab(app.TabGroup);
            app.FuturesTab.Title = 'Futures';

            % Create FuturesLabel
            app.FuturesLabel = uilabel(app.FuturesTab);
            app.FuturesLabel.VerticalAlignment = 'top';
            app.FuturesLabel.FontSize = 22;
            app.FuturesLabel.FontWeight = 'bold';
            app.FuturesLabel.FontColor = [0.6392 0.0784 0.1804];
            app.FuturesLabel.Position = [387 514 86 29];
            app.FuturesLabel.Text = 'Futures';

            % Create FutureAddAssetButton
            app.FutureAddAssetButton = uibutton(app.FuturesTab, 'push');
            app.FutureAddAssetButton.ButtonPushedFcn = createCallbackFcn(app, @FutureAddAssetButtonPushed, true);
            app.FutureAddAssetButton.FontSize = 14;
            app.FutureAddAssetButton.Position = [74 269 158 25];
            app.FutureAddAssetButton.Text = 'Add to Hedge Portfolio';

            % Create FutureClearAllButton
            app.FutureClearAllButton = uibutton(app.FuturesTab, 'push');
            app.FutureClearAllButton.ButtonPushedFcn = createCallbackFcn(app, @FutureClearAllButtonPushed, true);
            app.FutureClearAllButton.FontSize = 14;
            app.FutureClearAllButton.Position = [715 238 108 25];
            app.FutureClearAllButton.Text = 'Clear All';

            % Create FutureHedgingportfolioLabel
            app.FutureHedgingportfolioLabel = uilabel(app.FuturesTab);
            app.FutureHedgingportfolioLabel.VerticalAlignment = 'top';
            app.FutureHedgingportfolioLabel.FontSize = 14;
            app.FutureHedgingportfolioLabel.Position = [327 465 126 20];
            app.FutureHedgingportfolioLabel.Text = 'Hedging portfolio';

            % Create FutureHedgePrtTable
            app.FutureHedgePrtTable = uitable(app.FuturesTab);
            app.FutureHedgePrtTable.ColumnName = {''; 'Ticker'; 'Lower bound'; 'Upper bound'};
            app.FutureHedgePrtTable.ColumnWidth = {30, 'auto', 90, 90};
            app.FutureHedgePrtTable.RowName = {};
            app.FutureHedgePrtTable.ColumnEditable = [true false false false];
            app.FutureHedgePrtTable.FontSize = 14;
            app.FutureHedgePrtTable.Position = [441 269 382 218];

            % Create FutureClearSelectedButton
            app.FutureClearSelectedButton = uibutton(app.FuturesTab, 'push');
            app.FutureClearSelectedButton.ButtonPushedFcn = createCallbackFcn(app, @FutureClearSelectedButtonPushed, true);
            app.FutureClearSelectedButton.FontSize = 14;
            app.FutureClearSelectedButton.Position = [578 238 108 25];
            app.FutureClearSelectedButton.Text = 'Clear Selected';

            % Create FutureSelectAllCheckBox
            app.FutureSelectAllCheckBox = uicheckbox(app.FuturesTab);
            app.FutureSelectAllCheckBox.ValueChangedFcn = createCallbackFcn(app, @FutureSelectAllCheckBoxValueChanged, true);
            app.FutureSelectAllCheckBox.Text = 'Select All';
            app.FutureSelectAllCheckBox.FontSize = 14;
            app.FutureSelectAllCheckBox.Position = [452 241 80 18];

            % Create TickerEditField_7Label_4
            app.TickerEditField_7Label_4 = uilabel(app.FuturesTab);
            app.TickerEditField_7Label_4.HorizontalAlignment = 'right';
            app.TickerEditField_7Label_4.VerticalAlignment = 'top';
            app.TickerEditField_7Label_4.FontSize = 14;
            app.TickerEditField_7Label_4.Position = [21 466 44 18];
            app.TickerEditField_7Label_4.Text = 'Ticker';

            % Create FutureTickerEditField
            app.FutureTickerEditField = uieditfield(app.FuturesTab, 'text');
            app.FutureTickerEditField.FontSize = 14;
            app.FutureTickerEditField.Position = [80 465 204 22];

            % Create AllocationlowerboundEditField_7Label_4
            app.AllocationlowerboundEditField_7Label_4 = uilabel(app.FuturesTab);
            app.AllocationlowerboundEditField_7Label_4.HorizontalAlignment = 'right';
            app.AllocationlowerboundEditField_7Label_4.VerticalAlignment = 'top';
            app.AllocationlowerboundEditField_7Label_4.FontSize = 14;
            app.AllocationlowerboundEditField_7Label_4.Position = [21 399 148 18];
            app.AllocationlowerboundEditField_7Label_4.Text = 'Allocation lower bound';

            % Create FutureAllocationlowerboundEditField
            app.FutureAllocationlowerboundEditField = uieditfield(app.FuturesTab, 'numeric');
            app.FutureAllocationlowerboundEditField.Limits = [-Inf 0];
            app.FutureAllocationlowerboundEditField.FontSize = 14;
            app.FutureAllocationlowerboundEditField.Position = [184 398 100 22];
            app.FutureAllocationlowerboundEditField.Value = -1;

            % Create AllocationupperboundEditField_7Label_4
            app.AllocationupperboundEditField_7Label_4 = uilabel(app.FuturesTab);
            app.AllocationupperboundEditField_7Label_4.HorizontalAlignment = 'right';
            app.AllocationupperboundEditField_7Label_4.VerticalAlignment = 'top';
            app.AllocationupperboundEditField_7Label_4.FontSize = 14;
            app.AllocationupperboundEditField_7Label_4.Position = [21 332 151 18];
            app.AllocationupperboundEditField_7Label_4.Text = 'Allocation upper bound';

            % Create FutureAllocationupperboundEditField
            app.FutureAllocationupperboundEditField = uieditfield(app.FuturesTab, 'numeric');
            app.FutureAllocationupperboundEditField.Limits = [0 Inf];
            app.FutureAllocationupperboundEditField.FontSize = 14;
            app.FutureAllocationupperboundEditField.Position = [184 331 100 22];
            app.FutureAllocationupperboundEditField.Value = 1;

            % Create OptionsTab
            app.OptionsTab = uitab(app.TabGroup);
            app.OptionsTab.Title = 'Options';

            % Create OptionsLabel
            app.OptionsLabel = uilabel(app.OptionsTab);
            app.OptionsLabel.VerticalAlignment = 'top';
            app.OptionsLabel.FontSize = 22;
            app.OptionsLabel.FontWeight = 'bold';
            app.OptionsLabel.FontColor = [0.6392 0.0784 0.1804];
            app.OptionsLabel.Enable = 'off';
            app.OptionsLabel.Position = [387 514 89 29];
            app.OptionsLabel.Text = 'Options';

            % Create OptionAddAssetButton
            app.OptionAddAssetButton = uibutton(app.OptionsTab, 'push');
            app.OptionAddAssetButton.ButtonPushedFcn = createCallbackFcn(app, @OptionAddAssetButtonPushed, true);
            app.OptionAddAssetButton.FontSize = 14;
            app.OptionAddAssetButton.Enable = 'off';
            app.OptionAddAssetButton.Position = [74 269 158 25];
            app.OptionAddAssetButton.Text = 'Add to Hedge Portfolio';

            % Create OptionClearAllButton
            app.OptionClearAllButton = uibutton(app.OptionsTab, 'push');
            app.OptionClearAllButton.ButtonPushedFcn = createCallbackFcn(app, @OptionClearAllButtonPushed, true);
            app.OptionClearAllButton.FontSize = 14;
            app.OptionClearAllButton.Enable = 'off';
            app.OptionClearAllButton.Position = [715 238 108 25];
            app.OptionClearAllButton.Text = 'Clear All';

            % Create OptionHedgingportfolioLabel
            app.OptionHedgingportfolioLabel = uilabel(app.OptionsTab);
            app.OptionHedgingportfolioLabel.VerticalAlignment = 'top';
            app.OptionHedgingportfolioLabel.FontSize = 14;
            app.OptionHedgingportfolioLabel.Enable = 'off';
            app.OptionHedgingportfolioLabel.Position = [327 465 126 20];
            app.OptionHedgingportfolioLabel.Text = 'Hedging portfolio';

            % Create OptionHedgePrtTable
            app.OptionHedgePrtTable = uitable(app.OptionsTab);
            app.OptionHedgePrtTable.ColumnName = {''; 'Ticker'; 'Lower bound'; 'Upper bound'};
            app.OptionHedgePrtTable.ColumnWidth = {30, 'auto', 90, 90};
            app.OptionHedgePrtTable.RowName = {};
            app.OptionHedgePrtTable.ColumnEditable = [true false false false];
            app.OptionHedgePrtTable.Enable = 'off';
            app.OptionHedgePrtTable.FontSize = 14;
            app.OptionHedgePrtTable.Position = [441 269 382 218];

            % Create OptionClearSelectedButton
            app.OptionClearSelectedButton = uibutton(app.OptionsTab, 'push');
            app.OptionClearSelectedButton.ButtonPushedFcn = createCallbackFcn(app, @OptionClearSelectedButtonPushed, true);
            app.OptionClearSelectedButton.FontSize = 14;
            app.OptionClearSelectedButton.Enable = 'off';
            app.OptionClearSelectedButton.Position = [578 238 108 25];
            app.OptionClearSelectedButton.Text = 'Clear Selected';

            % Create OptionSelectAllCheckBox
            app.OptionSelectAllCheckBox = uicheckbox(app.OptionsTab);
            app.OptionSelectAllCheckBox.ValueChangedFcn = createCallbackFcn(app, @OptionSelectAllCheckBoxValueChanged, true);
            app.OptionSelectAllCheckBox.Enable = 'off';
            app.OptionSelectAllCheckBox.Text = 'Select All';
            app.OptionSelectAllCheckBox.FontSize = 14;
            app.OptionSelectAllCheckBox.Position = [452 241 80 18];

            % Create TickerEditField_7Label_5
            app.TickerEditField_7Label_5 = uilabel(app.OptionsTab);
            app.TickerEditField_7Label_5.HorizontalAlignment = 'right';
            app.TickerEditField_7Label_5.VerticalAlignment = 'top';
            app.TickerEditField_7Label_5.FontSize = 14;
            app.TickerEditField_7Label_5.Enable = 'off';
            app.TickerEditField_7Label_5.Position = [21 466 44 18];
            app.TickerEditField_7Label_5.Text = 'Ticker';

            % Create OptionTickerEditField
            app.OptionTickerEditField = uieditfield(app.OptionsTab, 'text');
            app.OptionTickerEditField.FontSize = 14;
            app.OptionTickerEditField.Enable = 'off';
            app.OptionTickerEditField.Position = [80 465 204 22];

            % Create AllocationlowerboundEditField_7Label_5
            app.AllocationlowerboundEditField_7Label_5 = uilabel(app.OptionsTab);
            app.AllocationlowerboundEditField_7Label_5.HorizontalAlignment = 'right';
            app.AllocationlowerboundEditField_7Label_5.VerticalAlignment = 'top';
            app.AllocationlowerboundEditField_7Label_5.FontSize = 14;
            app.AllocationlowerboundEditField_7Label_5.Enable = 'off';
            app.AllocationlowerboundEditField_7Label_5.Position = [21 399 148 18];
            app.AllocationlowerboundEditField_7Label_5.Text = 'Allocation lower bound';

            % Create OptionAllocationlowerboundEditField
            app.OptionAllocationlowerboundEditField = uieditfield(app.OptionsTab, 'numeric');
            app.OptionAllocationlowerboundEditField.Limits = [-Inf 0];
            app.OptionAllocationlowerboundEditField.FontSize = 14;
            app.OptionAllocationlowerboundEditField.Enable = 'off';
            app.OptionAllocationlowerboundEditField.Position = [184 398 100 22];
            app.OptionAllocationlowerboundEditField.Value = -1;

            % Create AllocationupperboundEditField_7Label_5
            app.AllocationupperboundEditField_7Label_5 = uilabel(app.OptionsTab);
            app.AllocationupperboundEditField_7Label_5.HorizontalAlignment = 'right';
            app.AllocationupperboundEditField_7Label_5.VerticalAlignment = 'top';
            app.AllocationupperboundEditField_7Label_5.FontSize = 14;
            app.AllocationupperboundEditField_7Label_5.Enable = 'off';
            app.AllocationupperboundEditField_7Label_5.Position = [21 332 151 18];
            app.AllocationupperboundEditField_7Label_5.Text = 'Allocation upper bound';

            % Create OptionAllocationupperboundEditField
            app.OptionAllocationupperboundEditField = uieditfield(app.OptionsTab, 'numeric');
            app.OptionAllocationupperboundEditField.Limits = [0 Inf];
            app.OptionAllocationupperboundEditField.FontSize = 14;
            app.OptionAllocationupperboundEditField.Enable = 'off';
            app.OptionAllocationupperboundEditField.Position = [184 331 100 22];
            app.OptionAllocationupperboundEditField.Value = 1;
        end
    end

    methods (Access = public)

        % Construct app
        function app = HedgePrtEquityDesk_UI(varargin)

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
            delete(app.HedgePrtEquityDeskUIFigure)
        end
    end
end