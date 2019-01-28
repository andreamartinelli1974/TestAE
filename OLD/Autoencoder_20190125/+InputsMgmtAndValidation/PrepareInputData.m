classdef PrepareInputData < handle
    %PrepareInputData class:
    %this class is used to prepare datas coming from the dashboard and
    %createing the InvestmentUniverse file
    
    properties(SetAccess = immutable)
        portfolioName;
        dashboardPath;
        inputExcelPath;
        outputExcelPath;
        constantMoneyness;
        constantTimeToExpiry;
        includeSpacAndDirgen;
        addIdenticalAssets;
    end
    
    properties(SetAccess = private)
        notionalAmountsArray;
        totalNotionalAmount;
        notionalAmountsAllAssetsArray;
        totalNotionalAmountAllAssets;
        totalNotionalsDifference;
        notionalAmountsArrayWSign;
        totalNotionalAmountWSigh
        totalNetLong;
    end
    
    methods
        %Constructor
        function PrepareInputDatas = PrepareInputData(portfolioName, ...
                dashboardPath, ...
                inputExcelPath, ...
                outputExcelPath, ...
                constantMoneyness, ...
                constantTimeToExpiry, ...
                includeSpacAndDirgen, ...
                addIdenticalAssets)
            
            PrepareInputDatas.portfolioName = portfolioName;
            PrepareInputDatas.dashboardPath = [dashboardPath];
            PrepareInputDatas.inputExcelPath = inputExcelPath;
            PrepareInputDatas.outputExcelPath = outputExcelPath;
            PrepareInputDatas.constantMoneyness = constantMoneyness;
            PrepareInputDatas.constantTimeToExpiry = constantTimeToExpiry;
            PrepareInputDatas.includeSpacAndDirgen = includeSpacAndDirgen;
            PrepareInputDatas.addIdenticalAssets = addIdenticalAssets;
        end %end constructor
        
        % activateMacros opens the EquityPTFtoInvestmentUniverse.xlsm file
        % and run its VBA macros
        function activateMacros(PrepareInputDatas)
            
            activePID = getpidof('EXCEL.EXE');
            
            Excel = actxserver('Excel.Application');
            
            currentPID = getpidof('EXCEL.EXE');
            toClosePID = setdiff(currentPID,activePID);
            
            Excel.DisplayAlerts = false;
            %%% THIS IS A TRICK TO PROPERLY LOAD BLOOMMBERG API IN EXCEL %%
            noAddins = Excel.Application.Addins.count;
            for i = 1:noAddins
                AddinsName{i} = Excel.Application.AddIns.Item(i).Name;
            end
            
            MyAdd = find(strcmpi(AddinsName,'BloombergUI.xla'));
            Excel.Application.AddIns.Item(MyAdd).Installed = false;
            Excel.Application.AddIns.Item(MyAdd).Installed = true;
            
            noAddins2 = Excel.Application.Addins2.count;
            for i = 1:noAddins2
                AddinsName2{i} = Excel.Application.AddIns2.Item(i).Name;
            end
            MyAdd2 = find(~ismember(AddinsName2,AddinsName));
            
            for i=1:numel(MyAdd2)
                Excel.Application.AddIns2.Item(MyAdd2(i)).Installed=true;
            end
            
            aTemp = Excel.workbooks.Add(); aTemp.Close();
            workbook = Excel.Workbooks.Open(PrepareInputDatas.inputExcelPath);
            %%% END OF TRICK
            
            exclerrFlag = true;
            errCounter = 0;
            while exclerrFlag
                try
                    %Excel.Visible = 0;
                    
                    workbook.Activate;
                    disp('Launching FileOpen Macro')
                    Excel.Application.Run('FileOpen', PrepareInputDatas.portfolioName, ...
                        PrepareInputDatas.dashboardPath, PrepareInputDatas.includeSpacAndDirgen);
                    disp('Pausing 120 Seconds')
                    pause(120);
                    exclerrFlag = false;
                catch exclerr
                    errCounter = errCounter +1;
                    pause(10);
                    if errCounter == 10
                        disp('Excels Error occurred too many times ')
                        rethrow(exclerr)
                        for i=1:numel(toClosePID)
                            system(['taskkill /F /PID ' num2str(toClosePID(i))]);
                        end
                        exclerrFlag = false;
                    end
                end % try
            end % while exclerrFlag
            exclerrFlag = true;
            errCounter = 0;
            while exclerrFlag
                try
                    workbook.Activate;
                    disp('Launching FileCopy Macro')
                    Excel.Application.Run('FileCopy', PrepareInputDatas.portfolioName, ...
                        PrepareInputDatas.dashboardPath, PrepareInputDatas.includeSpacAndDirgen);
                    disp('Pausing 120 Seconds')
                    pause(120);
                    exclerrFlag = false;
                catch exclerr
                    errCounter = errCounter +1;
                    pause(10);
                    if errCounter == 10
                        disp('Excels Error occurred too many times ')
                        rethrow(exclerr)
                        for i=1:numel(toClosePID)
                            system(['taskkill /F /PID ' num2str(toClosePID(i))]);
                        end
                        exclerrFlag = false;
                    end
                end % try
            end % while exclerrFlag
            
            exclerrFlag = true;
            errCounter = 0;
            while exclerrFlag
                try
                    disp('Launching GetInvUniverseTable Macro')
                    Excel.Application.Run('GetInvUniverseTable', PrepareInputDatas.constantMoneyness, ...
                        PrepareInputDatas.constantTimeToExpiry, PrepareInputDatas.addIdenticalAssets);
                    pause(3); % gp
                    exclerrFlag = false;
                catch exclerr
                    errCounter = errCounter +1;
                    pause(10);
                    if errCounter == 10
                        disp('Excels Error occurred too many times ')
                        rethrow(exclerr)
                        for i=1:numel(toClosePID)
                            system(['taskkill /F /PID ' num2str(toClosePID(i))]);
                        end
                        exclerrFlag = false;
                    end
                end % try
            end % while exclerrFlag
            exclerrFlag = true;
            errCounter = 0;
            while exclerrFlag
                try
                    disp('Launching VolaToCopy Macro')
                    Excel.Application.Run('VolaToCopy');
                    exclerrFlag = false;
                catch exclerr
                    errCounter = errCounter +1;
                    pause(10);
                    if errCounter == 10
                        disp('Excels Error occurred too many times ')
                        rethrow(exclerr)
                        for i=1:numel(toClosePID)
                            system(['taskkill /F /PID ' num2str(toClosePID(i))]);
                        end
                        exclerrFlag = false;
                    end
                end % try
            end % while exclerrFlag
            exclerrFlag = true;
            errCounter = 0;
            while exclerrFlag
                try
                    disp('Launching CopyToInvestmentUniverse Macro')
                    Excel.Application.Run('CopyToInvestmentUniverse', PrepareInputDatas.inputExcelPath, PrepareInputDatas.outputExcelPath);
                    exclerrFlag = false;
                catch exclerr
                    errCounter = errCounter +1;
                    pause(10);
                    if errCounter == 10
                        disp('Excels Error occurred too many times ')
                        rethrow(exclerr)
                        for i=1:numel(toClosePID)
                            system(['taskkill /F /PID ' num2str(toClosePID(i))]);
                        end
                        exclerrFlag = false;
                    end
                end % try
            end % while exclerrFlag
            workbook.Save;
            workbook.Close(false);
            Excel.DisplayAlerts = true;
            Excel.Quit;
            
            for i=1:numel(toClosePID)
                system(['taskkill /F /PID ' num2str(toClosePID(i))]);
            end
            
        end  %end activateMacros
        
        % sumNotionalAmounts calculates total notional amount,
        % total notional amount with the "LOG" sheet assets included,
        % and the difference of these two notionals
        function sumNotionalAmounts(PrepareInputDatas)
            
            activePID = getpidof('EXCEL.EXE');
            
            PrepareInputDatas.notionalAmountsArray = xlsread(PrepareInputDatas.inputExcelPath, 'InvestmentUniverse','BF:BF');
            PrepareInputDatas.notionalAmountsArrayWSign = xlsread(PrepareInputDatas.inputExcelPath, 'InvestmentUniverse','BG:BG');
            PrepareInputDatas.notionalAmountsAllAssetsArray = xlsread(PrepareInputDatas.inputExcelPath, 'LOG','BF:BF');
            PrepareInputDatas.totalNotionalAmount = sum(PrepareInputDatas.notionalAmountsArray);
            PrepareInputDatas.totalNotionalAmountWSigh = sum(PrepareInputDatas.notionalAmountsArrayWSign);
            PrepareInputDatas.totalNotionalAmountAllAssets = sum(PrepareInputDatas.notionalAmountsAllAssetsArray);
            PrepareInputDatas.totalNotionalAmountAllAssets = PrepareInputDatas.totalNotionalAmountAllAssets + PrepareInputDatas.totalNotionalAmount;
            PrepareInputDatas.totalNotionalsDifference = PrepareInputDatas.totalNotionalAmountAllAssets - PrepareInputDatas.totalNotionalAmount;
            PrepareInputDatas.totalNetLong = PrepareInputDatas.totalNotionalAmountWSigh/PrepareInputDatas.totalNotionalAmount;

            currentPID = getpidof('EXCEL.EXE');
            toClosePID = setdiff(currentPID,activePID);
            for i=1:numel(toClosePID)
                system(['taskkill /F /PID ' num2str(toClosePID(i))]);
            end

        end %end sumNotionalAmounts
        
    end %end methods
    
end %end classdef

