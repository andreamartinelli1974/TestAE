classdef AA_Outputs < handle
    % this class is used to produce some test outputs for an object of
    % class Universe having a field like "Strategies.Dynamic_AA_1" containing
    % historical optimization backtest results
    
    
    properties
        AllocationsHistory;
        UniverseObj;
        TotReturnsAndRisk;
        BT_params;
        strategy;
    end
    
    methods
        function O = AA_Outputs(U,BT_params,strategy)
            % U must be an obj of class universe
            % S = U.Strategies.Dynamic_AA_1;
            O.UniverseObj = U;
            O.BT_params = BT_params;
            O.strategy = strategy;
        end
        
        function GetAllocationsHistory(O)
            % this method produces an output summarizing asset allocation
            % optimal weights on every optimization date
            
            % When a single target AA has been run  there i one AA at each
            % time over the backtesting window. When a full Efficient Frontier
            % optimization has run it is necessary to look for the Risk level selected
            % at each optimization time and then, based on it, look for the
            % corresponding allocation
            
            allocations = O.UniverseObj.Strategies.Dynamic_AA_1.Dynamic_Frontier_EP.Allocation;
            risk = O.UniverseObj.Strategies.Dynamic_AA_1.Dynamic_Frontier_EP.Risk;
            tracker = O.UniverseObj.Strategies.Dynamic_AA_1.AA_Optim_tracker;
            leg = O.UniverseObj.Assets_Legend(:,1);
            na = size(leg,1); % no of assets
            optim_no = size(tracker,1); % no of optimizations
            O.AllocationsHistory.AssetsNames = leg';
            
            for i= 1 : na
                O.AllocationsHistory.AssetsTypes{1,i} = cell2mat(O.UniverseObj.Assets(i,1).value.AssetType);   % Panos addition saving asset type to create new aggregate 24/10/2017
            end 
            
            names = fieldnames(allocations);
            % TODO: add type of optimizations and initial target / final
            % target / ExitFlag infos
            if size(O.UniverseObj.Strategies.Dynamic_AA_1.ExitFlags,2)==1
                % single point optim has been run. TODO: review all of this: now the IF is based on the no of exitflags
                % at each time since this equals the no of points on the EF,
                % but there should be a field  indicating whether it is a
                % single point or Full EF optimization
                
                for k=1:optim_no
                    for n=1:na
                        t = tracker(k,1);
                        a(k,1) = m2xdate(tracker(k,2)); % dates in xls numerical format
                        a(k,n+1) = allocations.(names{n})(t);
                    end
                end
                
            else % Full Eff Front Optim has been run
                for k=1:optim_no
                   
                    timeidx = tracker(k,1);
                    % look for selected risk in timeidx + 1 since by
                    % construction (in AA_BackTest method) the selected
                    % allocation kicks in one day after the optimization is
                    % made) TODO: CHECK AND REVIEW ALL THIS
                    if timeidx < size(O.UniverseObj.Strategies.Dynamic_AA_1.BackTest.SelectedSigma,1)
                        SelectedRisk = O.UniverseObj.Strategies.Dynamic_AA_1.BackTest.SelectedSigma(timeidx+1);
                        correspondingPtOnEF = find(risk(:,timeidx) <= SelectedRisk);
                        correspondingPtOnEF = correspondingPtOnEF(end);
                        correspondingPtOnEF = correspondingPtOnEF(1);
                    else
                        % it means that the latest optimization
                        % date is the same as the last date in the backtest
                        % window. So the new asset allocation will kick in
                        % the next day  and cannot be found in 
                        % O.UniverseObj.Strategies.Dynamic_AA_1.BackTest.SelectedSigma
                        % In this case we need to use  "Search_AA"
                        S = O.UniverseObj.Strategies.(O.strategy);
                        [ff,tgtfound] = O.UniverseObj.Search_AA(O.UniverseObj,O.BT_params,O.strategy,S,timeidx);
                        % SelectedRisk = O.UniverseObj.Strategies.Dynamic_AA_1.Dynamic_Frontier_EP.Risk(ff,timeidx);
                        correspondingPtOnEF = ff;
                    end
                    
                    
                    for n=1:na
                        % t = tracker(k,1);
                        a(k,1) = m2xdate(tracker(k,2)); % dates in xls numerical format
                        a(k,n+1) = allocations.(names{n})(correspondingPtOnEF,timeidx);
                    end
                end
            end
            O.AllocationsHistory.Allocations = a;
            
        end % GetAllocationsHistory
        
        function GetReturnAndRiskMetrics(O,period)
            
            % TODO: need to change here if using a different estimation horizon: make it explicit in the code
            % this must be changed and it must be possible to work using any estim horizon
            estim_horizon = 1;
            
            % This method calculates the performance of the dynamically
            % calculated optimal portfolios based on the backtested data in
            % O.UniverseObj.Strategies.Dynamic_AA_1.BackTest (and hence on the
            % parameters used for that specific backtest)
            
            % INPUT:
            % -> period: is the period that has to be used to calculate
            % tot returns and risk metrics (e.g. if I am working on daily data, period = 20
            % means that I want to see 30 days tot ret returns and risks)
            
            
            disp('Calculating Risk/Return metrics');
            
            % returns from t = 0 (first backtested date) in R and derive
            % the same tot return as seen every period and the period
            % returns
            R = O.UniverseObj.Strategies.Dynamic_AA_1.BackTest.TotReturn_2;
            % get only the significant 'piece' of R (over the backtested
            % period)
            fs = find(R~=0); % this could identify a time located after the backtest start (e.g. if initial tot ret is 0: TODO: use the backtest's start date to be more precise)
            fs = fs(1);
            R = R(fs:end);
            Rdates = O.UniverseObj.Strategies.Dynamic_AA_1.BackTest.Dates_Vector(fs:end);
            
            % to have here also the data the I have already in .BackTest
            % (plus some stats)
            fldname = ['period_',num2str(estim_horizon),'_days'];
            TotReturnsAndRisk.(fldname).dates = Rdates;
            TotReturnsAndRisk.(fldname).R = R;
            r = price2ret(1+R);
            TotReturnsAndRisk.(fldname).annualisedVola = 100*std(r).*(252./estim_horizon).^0.5;
            [TotReturnsAndRisk.(fldname).VaR95,TotReturnsAndRisk.(fldname).ES95] = O.VarES_calc(r,95);
            [TotReturnsAndRisk.(fldname).VaR99,TotReturnsAndRisk.(fldname).ES99] = O.VarES_calc(r,99);
            
            % 'as seen' every period units of time (units of time can be
            % 1 day only now (estimation horizon). TODO: this must be
            % changed and it must be possible to work on different estim
            % horizon
            fldname = ['period_',num2str(period),'_days'];
            indices = [size(R,1):-period:1];
            indices = fliplr(indices);
            Rnew = R(indices);
            TotReturnsAndRisk.(fldname).R = Rnew;
            rnew = price2ret(1+Rnew);
            TotReturnsAndRisk.(fldname).dates = Rdates(indices);
            TotReturnsAndRisk.(fldname).annualisedVola = 100*std(rnew).*(252./period).^0.5;
            [TotReturnsAndRisk.(fldname).VaR95,TotReturnsAndRisk.(fldname).ES95] = O.VarES_calc(rnew,95);
            [TotReturnsAndRisk.(fldname).VaR99,TotReturnsAndRisk.(fldname).ES99] = O.VarES_calc(rnew,99);
            
            O.TotReturnsAndRisk = TotReturnsAndRisk;
            
        end % GetReturnAndRiskMetrics
        
        function ExcelOutput(O,reportName, reportfileName, ChartLabel, ReportsDir)
            
            % Kill any excel processes
            tabNuminit = 4 ;
            tabNameinit = 'AA_History_';
            
            [taskstate, taskmsg] = system('tasklist|findstr "EXCEL.EXE"');
            if ~isempty(taskmsg)
                status = system('taskkill /F /IM EXCEL.EXE');
                % If it gets here, shutting down worked, (I think) unless it asked them to save any unchanged work and they said to cancel shutdown.
            end
            switch reportName
                
                case 'Report1'
                    
                    filename = [reportfileName '.xlsx'];
                    % Check if it exists and if you want to ovewrite.
                    if exist([ReportsDir filename], 'file') == 2   % Check if initialization parameter exist.
                        
                        %choice = questdlg('File exists. Are you sure you want to overwrite ?','Options','Yes', 'Continue to next tab','Cancel','Cancel');
                        choice = 'Continue to next tab';
                        switch choice
                            case 'Yes'
                                % Delete file and rerun function.
                                delete([ReportsDir filename]);
                                system('taskkill /F /IM EXCEL.EXE'); % Kill excel.
                                % Initialize parameters for
                                % ExcelOutputfun
                                tabName = [tabNameinit num2str(tabNuminit-2)];
                                tabNum = tabNuminit;
                                O.ExcelOutputfun(filename, tabName, tabNum, ChartLabel, ReportsDir);
                            case 'Continue to next tab' % Dont delete spreadsheet
                                system('taskkill /F /IM EXCEL.EXE'); % Kill excel.
                                O.ExcelOutputfun(filename, tabNameinit , tabNuminit, ChartLabel, ReportsDir);
                            case 'Cancel'
                                return;
                        end
                    else
                        % Run it Anyway if it does not exist
                        % Run it Anyway if it does not exist
                        % Initialize parameters for
                        % ExcelOutputfun
                        tabName = [tabNameinit num2str(tabNuminit-3)];
                        tabNum = tabNuminit;
                        O.ExcelOutputfun(filename,tabName, tabNum, ChartLabel, ReportsDir);
                        
                    end
                    
                case 'Report2'
                    
                    filename = [reportfileName '.xlsx'];
                    % Check if it exists and if you want to ovewrite.
                    if exist([ReportsDir filename], 'file') == 2   % Check if initialization parameter exist.
                        
                        system('taskkill /F /IM EXCEL.EXE'); % Kill excel.
                        O.ExcelOutputfun(filename, tabNameinit , tabNuminit, ChartLabel, ReportsDir);
                        
                    else
                        % Run it Anyway if it does not exist
                        % Initialize parameters for
                        % ExcelOutputfun
                        tabName = [tabNameinit num2str(tabNuminit-3)];
                        tabNum = tabNuminit;
                        O.ExcelOutputfun(filename,tabName, tabNum, ChartLabel, ReportsDir);
                        
                    end
                    
            end % end switch
        end % GetReturnAndRiskMetrics
        
        function ExcelOutputfun(O,filename, tabName, tabnum ,ChartLabel, ReportDir)
            numofcolumns = 1;
            % Data
            histAA_data = O.AllocationsHistory.Allocations;
            [rows,columns] = size(histAA_data); % Take some sizes for pasting
            
            % Headers
            histAA_data_headers = O.AllocationsHistory.AssetsNames;
            histAA_data_headers_type = O.AllocationsHistory.AssetsTypes;
            
            Ex = actxserver('Excel.Application');
            
            % if exists open -The case of adding a new tab -
            if exist([ReportDir filename], 'file') == 2
                
                ExWorkbooks = Ex.Workbooks;
                % Ex.Visible = 1;
                ExWorkbook = ExWorkbooks.Open([ReportDir filename]);
                ExSheets = Ex.ActiveWorkbook.Sheets;
                Sheet_Graph1 = get(ExSheets, 'Item' , 'Charts' );
                % Activate sheet Charts
                Sheet_Graph1.Activate;
                numofcolumnsRange = get(Ex.ActiveSheet, 'Range', 'A1'); % end location of matrix
                numofcolumns = numofcolumnsRange.Value;
                tabName = [tabName num2str(numofcolumns + 1)];
                tabnum = numofcolumns + 4;
            else
                %  if it does not exist create
                ExWorkbook = Ex.Workbooks.Add; % add workbook
            end
            % end
            % methods(ExWorkbook,'-full') TO GET LIST OF AVAILABLE
            % METHODS for obj of class actxserver
            % make the first sheet active
            ExSheets = Ex.ActiveWorkbook.Sheets;
            
            % Overwrite if the tab exists
            ExSheets.Add([],ExSheets.Item(ExSheets.Count));   % Make sure we add another sheet always
            %ExWorkbook.SaveAs([ReportDir filename]);
            ExSheets_1 = ExSheets.get('Item',tabnum);
            ExSheets_1.Name = tabName; % # rename nth sheet
            
            ExSheets_1.Activate;
            
            % Data location
            r1 = 'a2'; %start location of matrix
            r2 = get(Ex.Activesheet, 'Cells', rows + 1, columns); % end location of matrix
            ExRange = get(Ex.Activesheet, 'Range', r2,r1);
            ExRange.HorizontalAlignment = 3 ;
            ExRange.VerticalAlignment = 3;
            
            % Headers location
            r1h = 'b1'; %start location of matrix
            r2h = get(Ex.Activesheet, 'Cells',   1, columns); % end location of matrix
            ExRangeheader = get(Ex.Activesheet, 'Range', r2h,r1h);
            ExRangeheader.Interior.ColorIndex = 45;
            ExRangeheader.RowHeight = 45;
            ExRangeheader.ColumnWidth = 25;
            ExRangeheader.WrapText = 'True';
            ExRangeheader.HorizontalAlignment = -4108;
            ExRangeheader.VerticalAlignment = -4108;
            
            % First data Row location colouring
            r1 = 'A2'; %start location of matrix
            r2 = get(Ex.Activesheet, 'Cells',   2, columns); % end location of matrix
            ExRangeC2 = get(Ex.Activesheet, 'Range', r2,r1);
            ExRangeC2.Interior.ColorIndex = 6;
            
            % Name very first tab A1 and format
            ExRangeheaderA1 = get(Ex.Activesheet, 'Range', 'A1');
            ExRangeheaderA1.Value = 'Optimization Dates';
            ExRangeheaderA1.Font.Bold = 1;
            ExRangeheaderA1.ColumnWidth = 20;
            ExRangeheaderA1.WrapText = 'True';
            ExRangeheaderA1.HorizontalAlignment = -4108;
            ExRangeheaderA1.VerticalAlignment = -4108;
            
            % FreezePanes
            ExRangeheaderB2 = get(Ex.Activesheet, 'Range', 'B2');
            ExRangeheaderB2.Activate;
            ExRangeheaderB2.Select;
            ExRangeheaderB2.Application.ActiveWindow.FreezePanes = 1;
            
            % ExRange = Ex.Activesheet.get('Range','A1')
            % Sort histAA_data from the most recent o the oldest one as per GP
            % request.
            histAA_data_sort = sortrows(histAA_data,-1); % In descending order based on column 1.
            ExRange.Value = histAA_data_sort;
            ExRangeheader.Value = histAA_data_headers;
            
            % Format dates
            r1_dates = 'a2'; %start location of matrix
            r2_dates = get(Ex.Activesheet, 'Cells', rows + 1, 1); % end location of matrix
            ExRange_dates = get(Ex.Activesheet, 'Range', r2_dates,r1_dates);
            ExRange_dates.NumberFormat = 'dd/mm/yyyy';
            ExRange_dates.HorizontalAlignment = 3 ;
            ExRange_dates.VerticalAlignment = 3;
            
            % Format numbers
            r1_numbers = 'b2'; %start location of matrix
            r2_numbers = get(Ex.Activesheet, 'Cells', rows + 1, columns); % end location of matrix
            ExRange_dates = get(Ex.Activesheet, 'Range', r2_numbers,r1_numbers);
            ExRange_dates.NumberFormat = '#.00%';
            
            %% Export New Aggregate sheet
            
            % First gather information to output.
            % Titles & Values.
            % Alphabetical sorting
% % %             [histAA_data_headers_sorted IndexData] = sort(histAA_data_headers);
% % %             DataSortedLast = histAA_data_sort(1,2:end)';   
% % %             DataSortedLast = DataSortedLast(IndexData');   % Sorted Data.
% % %             histAA_data_headers_sorted = histAA_data_headers_sorted'; % Sorted Headers.
 
            % Decreasing Absolute weight sorting.
            mostRecentDate = histAA_data_sort(1,1);
            [DataSortedLast IndexData] = sort(abs(histAA_data_sort(1,2:end)),'descend');
            histAA_data_sort = histAA_data_sort(1,2:end);
            DataSortedLast = histAA_data_sort(IndexData)';
            histAA_data_headers_sorted = histAA_data_headers(IndexData)';   % Sorted Data.
            histAA_data_headers_type_sorted = histAA_data_headers_type(IndexData)'; 
            
            % Find unique types in histAA_data_headers_type_sorted. % New
            % code addition Panos 24/10/2017.
            [unique_data_types,~,c] = unique(histAA_data_headers_type_sorted);
            DataAggregate2 = accumarray(c,DataSortedLast);
             
            % Length of headers.
            datalength =  length(histAA_data_headers_sorted);
            datalength2 = length(unique_data_types);
             
            try % if it exists
                Sheet_Graph1 = get(ExSheets, 'Item' , 'Charts' );
                Sheet_Graph1.Activate;
                numofcolumnsRange = get(Ex.ActiveSheet, 'Range', 'A1'); % end location of matrix
                numofcolumns = numofcolumnsRange.Value;
            catch
                numofcolumns = 0;
            end
          %%  
            Sheet_Aggregate = get(ExSheets, 'Item' , 1);
            Sheet_Aggregate.Activate % To output.
            Sheet_Aggregate.Name = 'Aggregate';
            
            r1_aggregtitles = cell2mat(strcat(XLCol(1 + 2*numofcolumns) ,num2str(5))); %start location of matrix
            r2_aggregtitles = get(Ex.Activesheet, 'Cells', datalength+4, 1 + 2*numofcolumns); % end location of matrix
            AggregRangeTitles = get(Ex.Activesheet, 'Range', r2_aggregtitles,r1_aggregtitles);

            r1_aggregvalues = cell2mat(strcat(XLCol(2 + 2*numofcolumns) ,num2str(5))); %start location of matrix
            r2_aggregvalues = get(Ex.Activesheet, 'Cells', datalength+4, 2 + 2*numofcolumns); % end location of matrix
            AggregRangeValues = get(Ex.Activesheet, 'Range', r2_aggregvalues,r1_aggregvalues);

            AggregRangeTitles.Value = histAA_data_headers_sorted;
            AggregRangeValues.Value = DataSortedLast;
            set(AggregRangeValues.Font,'Bold', 1)
            
            % Format and Titles
            AggregRangeValues.NumberFormat = '#.00%'; % Make percentages
            AggregRangeValues.ColumnWidth = 10;
            AggregRangeTitles.ColumnWidth = 40;
            AggregRangeTitles.Interior.ColorIndex = 44;
            AggregRangeValues.Interior.ColorIndex = 44;
            Sheet_TitleLabel = get(Ex.Activesheet,'Cells', 3, 1 + 2*numofcolumns );
            set(Sheet_TitleLabel, 'Value', ChartLabel) ; % Name the charts
            set(Sheet_TitleLabel.Font,'Bold', 1)
            set(Sheet_TitleLabel.Font,'Size', 13)
            Sheet_TitleLabel.Interior.ColorIndex = 6;
            Sheet_TitleLabel2 = get(Ex.Activesheet,'Cells', 4, 1 + 2*numofcolumns );
            set(Sheet_TitleLabel2, 'Value', 'Historical Window: Expanding from t0') ; % Name the charts
            set(Sheet_TitleLabel2.Font,'Bold', 1)
            set(Sheet_TitleLabel2.Font,'Size', 13)
            % New Efficient Frontier Title.
            Sheet_TitleLabel3 = get(Ex.Activesheet,'Cells', 3, 1 + 2*numofcolumns );
            set(Sheet_TitleLabel3, 'Value', ['Latest Efficient Frontier: ' datestr(x2mdate(mostRecentDate))]) ; % Name the charts
            set(Sheet_TitleLabel3.Font,'Bold', 1)
            set(Sheet_TitleLabel3.Font,'Size', 13)
            
            %% Repeat for second aggregate Panos 24/10/2017
            Sheet_Aggregate = get(ExSheets, 'Item' , 2);
            Sheet_Aggregate.Activate % To output.
            Sheet_Aggregate.Name = 'Aggregate2';
            
            r1_aggregtitles = cell2mat(strcat(XLCol(1 + 2*numofcolumns) ,num2str(5))); %start location of matrix
            r2_aggregtitles = get(Ex.Activesheet, 'Cells', datalength2+4, 1 + 2*numofcolumns); % end location of matrix
            AggregRangeTitles = get(Ex.Activesheet, 'Range', r2_aggregtitles,r1_aggregtitles);

            r1_aggregvalues = cell2mat(strcat(XLCol(2 + 2*numofcolumns) ,num2str(5))); %start location of matrix
            r2_aggregvalues = get(Ex.Activesheet, 'Cells', datalength2+4, 2 + 2*numofcolumns); % end location of matrix
            AggregRangeValues = get(Ex.Activesheet, 'Range', r2_aggregvalues,r1_aggregvalues);

            AggregRangeTitles.Value = unique_data_types;
            AggregRangeValues.Value = DataAggregate2;
            set(AggregRangeValues.Font,'Bold', 1)
            
            % Format and Titles
            AggregRangeValues.NumberFormat = '#.00%'; % Make percentages
            AggregRangeValues.ColumnWidth = 10;
            AggregRangeTitles.ColumnWidth = 40;
            AggregRangeTitles.Interior.ColorIndex = 44;
            AggregRangeValues.Interior.ColorIndex = 44;
            Sheet_TitleLabel = get(Ex.Activesheet,'Cells', 3, 1 + 2*numofcolumns );
            set(Sheet_TitleLabel, 'Value', ChartLabel) ; % Name the charts
            set(Sheet_TitleLabel.Font,'Bold', 1)
            set(Sheet_TitleLabel.Font,'Size', 13)
            Sheet_TitleLabel.Interior.ColorIndex = 6;
            Sheet_TitleLabel2 = get(Ex.Activesheet,'Cells', 4, 1 + 2*numofcolumns );
            set(Sheet_TitleLabel2, 'Value', 'Historical Window: Expanding from t0') ; % Name the charts
            set(Sheet_TitleLabel2.Font,'Bold', 1)
            set(Sheet_TitleLabel2.Font,'Size', 13)
            % New Efficient Frontier Title.
            Sheet_TitleLabel3 = get(Ex.Activesheet,'Cells', 3, 1 + 2*numofcolumns );
            set(Sheet_TitleLabel3, 'Value', ['Latest Efficient Frontier: ' datestr(x2mdate(mostRecentDate))]) ; % Name the charts
            set(Sheet_TitleLabel3.Font,'Bold', 1)
            set(Sheet_TitleLabel3.Font,'Size', 13)
            
            %% Export Graphs
            % Count number of open figures without saving anything
            nfigs = get(0,'Children');
            nfigscount = length(nfigs); % Number of figure to export
            graphnumlist = [nfigs(1:6).Number];
            graphnumlistsorted = sort(graphnumlist);
            
            try % If the chart exist
                Sheet_Graph1 = get(ExSheets, 'Item' , 'Charts' );
                % Activate sheet Charts
                Sheet_Graph1.Activate;
                numofcolumnsRange = get(Ex.ActiveSheet, 'Range', 'A1'); % end location of matrix
                numofcolumns = numofcolumnsRange.Value;
            catch % if it does not exist.
                %                         ExSheets.Add([],ExSheets.Item(ExSheets.Count));
                Sheet_Graph1 = get(ExSheets, 'Item' , 3); % Sheet_Graph1 = get(ExSheets, 'Item' , 2);
                Sheet_Graph1.Name = 'Charts';
                numofcolumns = 0; % First column to be written in excel
                Sheet_Graph1.Activate;
            end
            
            % Add the title on the graphs
            Sheet_GraphLabel = get(Ex.Activesheet,'Cells', 2, numofcolumns*9 + 2 );
            set(Sheet_GraphLabel, 'Value', ChartLabel) ; % Name the charts
            set(Sheet_GraphLabel.Font,'Bold', 1)
            set(Sheet_GraphLabel.Font,'Size', 13)
            
            for count = 1 : nfigscount
                % Image name
                img = ['figure' num2str(graphnumlistsorted(count)) '.png'];
                
                % Select figure
                figure(graphnumlistsorted(count));
                print('-dpng', img);
                
                % Set it to visible
                % set(Ex,'Visible', 1);
                
                % Activate sheet Charts
                Sheet_Graph1.Activate;
                
                % Get a handle to Shapes for Sheet 10.
                Shapes = Sheet_Graph1.Shapes;
                
                % Add image
                Shapes.AddPicture([pwd '\' img] ,0,1,10+430*numofcolumns,40+ 340*(count-1),410, 300);  % Fixed the export size so that there is on overlap
                
                % GP delete img
                delete(img);
            end
            
            if nfigscount > 0 % Increase value only if there where graphs.
                % Update number of columns.
                Sheet_Graph1Range = get(Ex.Activesheet,'Range','A1');
                set(Sheet_Graph1Range, 'Value',  numofcolumns  + 1) ;  %Increment for number of columns.
            else
            end
            %% Save
            Ex.DisplayAlerts = false; % That di the trick
            ExWorkbook.SaveAs([ReportDir filename]);

            
            Close(ExWorkbook);
            Quit(Ex);
            delete(Ex);
            
        end
        
    end % public methods
    
    methods (Static)
        
        function [VaR,ES] = VarES_calc(data,conf)
            cutoff = 100-conf;
            q = prctile(data,cutoff);
            VaR = max(0,-q*100);
            ES = max(0,-mean(data(data<q))*100);
            
        end
        
    end % Static methods
    
end

