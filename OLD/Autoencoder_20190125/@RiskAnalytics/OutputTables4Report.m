function outputTab = OutputTables4Report(R,tableName)
% This method is designed to create tables to be put within the
% structure Output4Reports (public property, see copmments above)
% INPUTs:
% -> tableName: the one corresponding to tableName will be plotted
R.Output4Reports = [];

otherParam = getParam4ChartAndTable(R);

% REFERENCE DATE
if strcmp(tableName,'ReferenceDate')
    
    outputTab.matrix = {otherParam.ReferenceDate, 'AA'};
    outputTab.colHeader = {'Reference Date','Model'};
    outputTab.format = {'char','char'};
    
    % Output
    R.Output4Reports.outputTab = outputTab;
    
    % ALLOCATION SA (SINGLE ASSETS)
    % Percentage - monetary
elseif strcmp(tableName,'AllocationsSA')
    
    %disp('Creating Prior/Posterior Allocations Table');
    R.Output4Reports.AssetAllocationTable = table(otherParam.allocTable.Assets,otherParam.allocTable.CurrentAA, otherParam.allocTable.CurrentAA_mon, ...
        'VariableNames',{'Assets','CurrentAA','CurrentAAmon'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.AssetAllocationTable);
    R.Output4Reports.outputTab.colHeader  = {'Assets','Current Percentage AA', 'Current Monetary AA' };
    R.Output4Reports.outputTab.format = {'char', 'percIconMapBorder', 'commaIconMapBorder'};
    
    
    % ALLOCATION SA (COUNTRY)
    % Percentage - monetary
elseif strcmp(tableName,'AllocationsSAcountry')
    
    R.Output4Reports.AssetAllocationTable = table(otherParam.allocTable_Country.Country, otherParam.allocTable_Country.CurrentAA, otherParam.allocTable_Country.CurrentAA_mon, ...
        'VariableNames',{'Country','CurrentAA','CurrentMonetaryAA'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.AssetAllocationTable);
    R.Output4Reports.outputTab.colHeader  = {'Country', 'Current Percentage AA','Current Monetary AA'};
    R.Output4Reports.outputTab.format = {'char', 'percIconMapBorder', 'commaIconMapBorder'};
    
    % ALLOCATION SA (SECTOR)
    % Percentage - monetary
elseif strcmp(tableName,'AllocationsSAsector')
    
    R.Output4Reports.AssetAllocationTable = table(otherParam.allocTable_Sector.Sector, otherParam.allocTable_Sector.CurrentAA, otherParam.allocTable_Sector.CurrentAA_mon, ...
        'VariableNames',{'Country','CurrentAA','CurrentMonetaryAA'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.AssetAllocationTable);
    R.Output4Reports.outputTab.colHeader = {'Country', 'Current Percentage AA','Current Monetary AA'};
    R.Output4Reports.outputTab.format = {'char', 'percIconMapBorder', 'commaIconMapBorder'};
    
    % ALLOCATION SA AGGREGATED (ASSET CLASS)
    % Percentage - monetary
elseif strcmp(tableName,'AllocationsSAaggr')
    
    %disp('Creating Prior/Posterior Allocations Table');
    
    R.Output4Reports.AssetAllocationTable = table(otherParam.allocTable_Class.AssetClass, otherParam.allocTable_Class.CurrentAA, otherParam.allocTable_Class.CurrentAA_mon, ...
        'VariableNames',{'AssetClass','CurrentAA','CurrentMonetaryAA'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.AssetAllocationTable);
    R.Output4Reports.outputTab.colHeader  = {'Asset Class','Current Percentage AA', 'Current Monetary AA' };
    R.Output4Reports.outputTab.format = {'char', 'perc2Bord', 'commaBorder'};
    
    % ALLOCATION SA AGGREGATED ABSOLUTE (ASSET CLASS)
    % Percentage - monetary
    % Absolute
elseif strcmp(tableName,'AllocationsSAaggrAbs')
    
    %disp('Creating Prior/Posterior Allocations Table');
    R.Output4Reports.AssetAllocationTable = table(otherParam.allocTable_Class.AssetClass, otherParam.allocTable_Class.CurrentAA_abs, otherParam.allocTable_Class.CurrentAA_mon_abs, ...
        'VariableNames',{'AssetClass','CurrentAA','CurrentMonetaryAA'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.AssetAllocationTable);
    R.Output4Reports.outputTab.colHeader  = {'Asset Class','Current Percentage AA', 'Current Monetary AA' };
    R.Output4Reports.outputTab.format = {'char', 'perc2Bord', 'commaBorder'};
    
    % ALLOCATION MODEL PTF (SINGLE ASSETS)
    % Percentage
elseif strcmp(tableName,'AllocationsMP')
    
    %disp('Creating Prior/Posterior Allocations Table');
    R.Output4Reports.AssetAllocationTable = table(otherParam.allocTable.Assets, otherParam.allocTable.CurrentAA, otherParam.allocTable.PriorAA, ...
        otherParam.allocTable.PosteriorAA, otherParam.allocTable.Diff1, otherParam.allocTable.Diff2,...
        'VariableNames',{'Assets','CurrentAA','PriorAA','PosteriorAA','Diff1','Diff2'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.AssetAllocationTable);
    R.Output4Reports.outputTab.colHeader  = {'Assets', '(1)   Current AA','(2)   Prior AA', '(3)   Posterior AA', ...
        '   (3)  -  (1) ', '   (3)  -  (2) '};
    R.Output4Reports.outputTab.format = {'char', 'percIconMap', 'percIconMap', 'percIconMap', 'percIconMapBorder', 'percIconMapBorder'};
    
    % ALLOCATION MODEL PTF (SINGLE ASSETS)
    % Monetary
elseif strcmp(tableName,'AllocationsMPmon')
    
    %disp('Creating Prior/Posterior Allocations Table');
    R.Output4Reports.AssetAllocationTable = table(otherParam.allocTable.Assets, otherParam.allocTable.CurrentAA_mon, otherParam.allocTable.PriorAA_mon, otherParam.allocTable.PosteriorAA_mon, ...
        otherParam.allocTable.Diff1_mon, otherParam.allocTable.Diff2_mon,...
        'VariableNames',{'Assets','CurrentAA','PriorAA','PosteriorAA','Diff1','Diff2'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.AssetAllocationTable);
    R.Output4Reports.outputTab.colHeader  = {'Assets', '(1)   Current AA','(2)   Prior AA', '(3)   Posterior AA', ...
        '   (3)  -  (1) ', '   (3)  -  (2) '};
    R.Output4Reports.outputTab.format = {'char', 'commaIconMap', 'commaIconMap', 'commaIconMap', 'commaIconMapBorder', 'commaIconMapBorder'};
    
    % ALLOCATION MODEL PTF AGGREGATED (ASSET CLASS)
    % Percentage
elseif strcmp(tableName,'AllocationsMPaggr')
    
    %disp('Creating Prior/Posterior Allocations Table');
    R.Output4Reports.AssetAllocationTable = table(otherParam.allocTable_Class.AssetClass, otherParam.allocTable_Class.CurrentAA, otherParam.allocTable_Class.PriorAA, otherParam.allocTable_Class.PosteriorAA, ...
        otherParam.allocTable_Class.Diff1, otherParam.allocTable_Class.Diff2,...
        'VariableNames',{'AssetClass','CurrentAA','PriorAA','PosteriorAA','Diff1','Diff2'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.AssetAllocationTable);
    R.Output4Reports.outputTab.colHeader  = {'Asset Class', '(1)   Current AA','(2)   Prior AA', '(3)   Posterior AA', ...
        '   (3)  -  (1) ', '   (3)  -  (2) '};
    R.Output4Reports.outputTab.format = {'char', 'perc2', 'perc2', 'perc2', 'perc2Bord', 'perc2Bord'};
    
    % ALLOCATION MODEL PTF AGGREGATED ABSOLUTE (ASSET CLASS)
    % Percentage
    % Absolute
elseif strcmp(tableName,'AllocationsMPaggrAbs')
    
    %disp('Creating Prior/Posterior Allocations Table');
    R.Output4Reports.AssetAllocationTable = table(otherParam.allocTable_Class.AssetClass, otherParam.allocTable_Class.CurrentAA_abs, otherParam.allocTable_Class.PriorAA_abs, otherParam.allocTable_Class.PosteriorAA_abs, ...
        otherParam.allocTable_Class.Diff1_abs, otherParam.allocTable_Class.Diff2_abs,...
        'VariableNames',{'AssetClass','CurrentAA','PriorAA','PosteriorAA','Diff1','Diff2'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.AssetAllocationTable);
    R.Output4Reports.outputTab.colHeader  = {'Asset Class', '(1)   Current AA','(2)   Prior AA', '(3)   Posterior AA', ...
        '   (3)  -  (1) ', '   (3)  -  (2) '};
    R.Output4Reports.outputTab.format = {'char', 'perc2', 'perc2', 'perc2', 'perc2Bord', 'perc2Bord'};
    
    % ALLOCATION MODEL PTF MONETARY AGGREGATED (ASSET CLASS)
    % Monetary
elseif strcmp(tableName,'AllocationsMPmonAggr')
    
    %disp('Creating Prior/Posterior Allocations Table');
    R.Output4Reports.AssetAllocationTable = table(otherParam.allocTable_Class.AssetClass, otherParam.allocTable_Class.CurrentAA_mon, otherParam.allocTable_Class.PriorAA_mon, otherParam.allocTable_Class.PosteriorAA_mon, ...
        otherParam.allocTable_Class.Diff1_mon, otherParam.allocTable_Class.Diff2_mon,...
        'VariableNames',{'AssetClass','CurrentAA','PriorAA','PosteriorAA','Diff1','Diff2'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.AssetAllocationTable);
    R.Output4Reports.outputTab.colHeader  = {'Asset Class', '(1)   Current AA','(2)   Prior AA', '(3)   Posterior AA', ...
        '   (3)  -  (1) ', '   (3)  -  (2) '};
    R.Output4Reports.outputTab.format = {'char', 'comma', 'comma', 'comma', 'commaBorder', 'commaBorder'};
    
    
    % ALLOCATION MODEL PTF MONETARY AGGREGATED ABSOLUTE (ASSET CLASS)
    % Monetary
    % Absolute
elseif strcmp(tableName,'AllocationsMPmonAggrAbs')
    
    %disp('Creating Prior/Posterior Allocations Table');
    R.Output4Reports.AssetAllocationTable = table(otherParam.allocTable_Class.AssetClass, otherParam.allocTable_Class.CurrentAA_mon_abs, otherParam.allocTable_Class.PriorAA_mon_abs, otherParam.allocTable_Class.PosteriorAA_mon_abs, ...
        otherParam.allocTable_Class.Diff1_mon_abs, otherParam.allocTable_Class.Diff2_mon_abs,...
        'VariableNames',{'AssetClass','CurrentAA','PriorAA','PosteriorAA','Diff1','Diff2'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.AssetAllocationTable);
    R.Output4Reports.outputTab.colHeader  = {'Asset Class', '(1)   Current AA','(2)   Prior AA', '(3)   Posterior AA', ...
        '   (3)  -  (1) ', '   (3)  -  (2) '};
    R.Output4Reports.outputTab.format = {'char', 'comma', 'comma', 'comma', 'commaBorder', 'commaBorder'};
    
    
    % ALLOCATION MODEL PTF (COUNTRY)
    % In percentage
elseif strcmp(tableName,'AllocationsMPcountry')
    
    %disp('Creating Prior/Posterior Allocations Table');
    R.Output4Reports.AssetAllocationTable = table(otherParam.allocTable_Country.Country, otherParam.allocTable_Country.CurrentAA, otherParam.allocTable_Country.PriorAA, otherParam.allocTable_Country.PosteriorAA, ...
        otherParam.allocTable_Country.Diff1, otherParam.allocTable_Country.Diff2,...
        'VariableNames',{'Country','CurrentAA','PriorAA','PosteriorAA','Diff1','Diff2'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.AssetAllocationTable);
    R.Output4Reports.outputTab.colHeader  = {'Country', '(1)   Current AA','(2)   Prior AA', '(3)   Posterior AA', ...
        '   (3)  -  (1) ', '   (3)  -  (2) '};
    R.Output4Reports.outputTab.format = {'char', 'percIconMap', 'percIconMap', 'percIconMap', 'percIconMapBorder', 'percIconMapBorder'};
    
    
    % ALLOCATION MODEL PTF (COUNTRY)
    % Monetary
elseif strcmp(tableName,'AllocationsMPcountryMon')
    
    %disp('Creating Prior/Posterior Allocations Table');
    R.Output4Reports.AssetAllocationTable = table(otherParam.allocTable_Country.Country, otherParam.allocTable_Country.CurrentAA_mon, otherParam.allocTable_Country.PriorAA_mon, otherParam.allocTable_Country.PosteriorAA_mon, ...
        otherParam.allocTable_Country.Diff1_mon, otherParam.allocTable_Country.Diff2_mon,...
        'VariableNames',{'Country','CurrentAA','PriorAA','PosteriorAA','Diff1','Diff2'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.AssetAllocationTable);
    R.Output4Reports.outputTab.colHeader  = {'Country', '(1)   Current AA','(2)   Prior AA', '(3)   Posterior AA', ...
        '   (3)  -  (1) ', '   (3)  -  (2) '};
    R.Output4Reports.outputTab.format = {'char', 'commaIconMap', 'commaIconMap', 'commaIconMap', 'commaIconMapBorder', 'commaIconMapBorder'};
    
    % ALLOCATION MODEL PTF (SECTOR)
    % In percentage
elseif strcmp(tableName,'AllocationsMPsector')
    
    %disp('Creating Prior/Posterior Allocations Table');
    R.Output4Reports.AssetAllocationTable = table(otherParam.allocTable_Sector.Sector, otherParam.allocTable_Sector.CurrentAA, otherParam.allocTable_Sector.PriorAA, otherParam.allocTable_Sector.PosteriorAA, ...
        otherParam.allocTable_Sector.Diff1, otherParam.allocTable_Sector.Diff2,...
        'VariableNames',{'Country','CurrentAA','PriorAA','PosteriorAA','Diff1','Diff2'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.AssetAllocationTable);
    R.Output4Reports.outputTab.colHeader  = {'Sector', '(1)   Current AA','(2)   Prior AA', '(3)   Posterior AA', ...
        '   (3)  -  (1) ', '   (3)  -  (2) '};
    R.Output4Reports.outputTab.format = {'char', 'percIconMap', 'percIconMap', 'percIconMap', 'percIconMapBorder', 'percIconMapBorder'};
    
    % ALLOCATION MODEL PTF (SECTOR)
    % Monetary
elseif strcmp(tableName,'AllocationsMPsectorMon')
    
    %disp('Creating Prior/Posterior Allocations Table');
    R.Output4Reports.AssetAllocationTable = table(otherParam.allocTable_Sector.Sector, otherParam.allocTable_Sector.CurrentAA_mon, otherParam.allocTable_Sector.PriorAA_mon, otherParam.allocTable_Sector.PosteriorAA_mon,...
        otherParam.allocTable_Sector.Diff1_mon, otherParam.allocTable_Sector.Diff2_mon,...
        'VariableNames',{'Country','CurrentAA','PriorAA','PosteriorAA','Diff1','Diff2'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.AssetAllocationTable);
    R.Output4Reports.outputTab.colHeader  = {'Country', '(1)   Current AA','(2)   Prior AA', '(3)   Posterior AA', ...
        '   (3)  -  (1) ', '   (3)  -  (2) '};
    R.Output4Reports.outputTab.format = {'char', 'commaIconMap', 'commaIconMap', 'commaIconMap', 'commaIconMapBorder', 'commaIconMapBorder'};
    
elseif strcmp(tableName,'AllocationsMP_AllAssets')
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(otherParam.allAssetsTable);
    R.Output4Reports.outputTab.colHeader  = {'Assets', 'Included Assets', 'Current AA %','Current AA €'};
    R.Output4Reports.outputTab.format = {'char', 'char', 'percIconMap', 'commaIconMap'};
    
    % MARGINAL VAR (ASSET CLASS)
elseif strcmp(tableName,'MargVaR_AssetClass')
    
    R.Output4Reports.MVaR_Table = table(otherParam.selectedMVaR_AssetClass_Table.Asset_Class, ...
        otherParam.selectedMVaR_AssetClass_Table.Current_MVaR, ...
        otherParam.selectedMVaR_AssetClass_Table.Prior_MVaR, ...
        otherParam.selectedMVaR_AssetClass_Table.Posterior_MVaR,...
        'VariableNames',{'Asset_Class','Current_MVaR','Prior_MVaR','Posterior_MVaR'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.MVaR_Table);
    R.Output4Reports.outputTab.colHeader  = {'Asset Class', 'Current MVAR','Prior MVAR', 'Posterior MVAR'};
    R.Output4Reports.outputTab.format = {'char', 'percIconMap', 'percIconMap', 'percIconMap'};
    
    % MARGINAL VAR (ASSET CLASS)
elseif strcmp(tableName,'MargVaR_AssetClass_SA')
    
    R.Output4Reports.MVaR_Table = table(otherParam.selectedMVaR_AssetClass_Table.Asset_Class, ...
        otherParam.selectedMVaR_AssetClass_Table.Current_MVaR, ...
        'VariableNames',{'Asset_Class','Current_MVaR'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.MVaR_Table);
    R.Output4Reports.outputTab.colHeader  = {'Asset Class', 'Current MVAR'};
    R.Output4Reports.outputTab.format = {'char', 'percIconMap'};
    
    % MARGINAL VAR (COUNTRY)
elseif strcmp(tableName,'MargVaR_Country')
    
    R.Output4Reports.MVaR_Table = table(otherParam.selectedMVaR_AssetCtry_Table.Asset_Ctry, ...
        otherParam.selectedMVaR_AssetCtry_Table.Current_MVaR, ...
        otherParam.selectedMVaR_AssetCtry_Table.Prior_MVaR, ...
        otherParam.selectedMVaR_AssetCtry_Table.Posterior_MVaR,...
        'VariableNames',{'Country','Current_MVaR','Prior_MVaR','Posterior_MVaR'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.MVaR_Table);
    R.Output4Reports.outputTab.colHeader  = {'Country', 'Current MVAR','Prior MVAR', 'Posterior MVAR'};
    R.Output4Reports.outputTab.format = {'char', 'percIconMap', 'percIconMap', 'percIconMap'};
    
    % MARGINAL VAR (COUNTRY)
elseif strcmp(tableName,'MargVaR_Country_SA')
    
    R.Output4Reports.MVaR_Table = table(otherParam.selectedMVaR_AssetCtry_Table.Asset_Ctry, ...
        otherParam.selectedMVaR_AssetCtry_Table.Current_MVaR, ...
        'VariableNames',{'Country','Current_MVaR'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.MVaR_Table);
    R.Output4Reports.outputTab.colHeader  = {'Country', 'Current MVAR'};
    R.Output4Reports.outputTab.format = {'char', 'percIconMap'};
    
    % MARGINAL VAR (SECTOR)
elseif strcmp(tableName,'MargVaR_Sector')
    
    R.Output4Reports.MVaR_Table = table(otherParam.selectedMVaR_AssetSect_Table.Asset_Sect, ...
        otherParam.selectedMVaR_AssetSect_Table.Current_MVaR, ...
        otherParam.selectedMVaR_AssetSect_Table.Prior_MVaR, ...
        otherParam.selectedMVaR_AssetSect_Table.Posterior_MVaR,...
        'VariableNames',{'Sector','Current_MVaR','Prior_MVaR','Posterior_MVaR'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.MVaR_Table);
    R.Output4Reports.outputTab.colHeader  = {'Sector', 'Current MVAR','Prior MVAR', 'Posterior MVAR'};
    R.Output4Reports.outputTab.format = {'char', 'percIconMap', 'percIconMap', 'percIconMap'};
    
    % MARGINAL VAR (SECTOR)
elseif strcmp(tableName,'MargVaR_Sector_SA')
    
    R.Output4Reports.MVaR_Table = table(otherParam.selectedMVaR_AssetSect_Table.Asset_Sect, ...
        otherParam.selectedMVaR_AssetSect_Table.Current_MVaR, ...
        'VariableNames',{'Sector','Current_MVaR'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.MVaR_Table);
    R.Output4Reports.outputTab.colHeader  = {'Sector', 'Current MVAR'};
    R.Output4Reports.outputTab.format = {'char', 'percIconMap'};
    
    
    % MARGINAL VAR (ALL ASSETS)
elseif strcmp(tableName,'MargVaR_All')
    
    R.Output4Reports.MVaR_Table = table(otherParam.selectedMVaR_AssetAll_Table.Asset_All, ...
        otherParam.selectedMVaR_AssetAll_Table.Current_MVaR, ...
        otherParam.selectedMVaR_AssetAll_Table.Prior_MVaR, ...
        otherParam.selectedMVaR_AssetAll_Table.Posterior_MVaR,...
        'VariableNames',{'All_Assets','Current_MVaR','Prior_MVaR','Posterior_MVaR'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.MVaR_Table);
    R.Output4Reports.outputTab.colHeader  = {'Assets', 'Current MVAR','Prior MVAR', 'Posterior MVAR'};
    R.Output4Reports.outputTab.format = {'char', 'percIconMap', 'percIconMap', 'percIconMap'};
    
    % MARGINAL VAR (ALL ASSETS)
elseif strcmp(tableName,'MargVaR_All_SA')
    
    R.Output4Reports.MVaR_Table = table(otherParam.selectedMVaR_AssetAll_Table.Asset_All, ...
        otherParam.selectedMVaR_AssetAll_Table.Current_MVaR, ...
        'VariableNames',{'All_Assets','Current_MVaR'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.MVaR_Table);
    R.Output4Reports.outputTab.colHeader  = {'Assets', 'Current MVAR'};
    R.Output4Reports.outputTab.format = {'char', 'percIconMap'};
    
    % MARGINAL VAR (ASSET CLASS)
elseif strcmp(tableName,'MargVaR_AssetClass_mon')
    
    R.Output4Reports.MVaR_Table = table(otherParam.selectedMVaR_AssetClass_Table.Asset_Class, ...
        otherParam.selectedMVaR_AssetClass_Table.Current_MVaR.*R.IncludedNotional, ...
        otherParam.selectedMVaR_AssetClass_Table.Prior_MVaR.*R.IncludedNotional, ...
        otherParam.selectedMVaR_AssetClass_Table.Posterior_MVaR.*R.IncludedNotional,...
        'VariableNames',{'Asset_Class','Current_MVaR','Prior_MVaR','Posterior_MVaR'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.MVaR_Table);
    R.Output4Reports.outputTab.colHeader  = {'Asset Class', 'Current MVAR','Prior MVAR', 'Posterior MVAR'};
    R.Output4Reports.outputTab.format = {'char', 'commaIconMap', 'commaIconMap', 'commaIconMap'};
    
    % MARGINAL VAR (ASSET CLASS)
elseif strcmp(tableName,'MargVaR_AssetClass_mon_SA')
    
    R.Output4Reports.MVaR_Table = table(otherParam.selectedMVaR_AssetClass_Table.Asset_Class, ...
        otherParam.selectedMVaR_AssetClass_Table.Current_MVaR.*R.IncludedNotional, ...
        'VariableNames',{'Asset_Class','Current_MVaR'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.MVaR_Table);
    R.Output4Reports.outputTab.colHeader  = {'Asset Class', 'Current MVAR'};
    R.Output4Reports.outputTab.format = {'char', 'commaIconMap'};
    
    % MARGINAL VAR (COUNTRY)
elseif strcmp(tableName,'MargVaR_Country_mon')
    
    R.Output4Reports.MVaR_Table = table(otherParam.selectedMVaR_AssetCtry_Table.Asset_Ctry, ...
        otherParam.selectedMVaR_AssetCtry_Table.Current_MVaR.*R.IncludedNotional, ...
        otherParam.selectedMVaR_AssetCtry_Table.Prior_MVaR.*R.IncludedNotional, ...
        otherParam.selectedMVaR_AssetCtry_Table.Posterior_MVaR.*R.IncludedNotional,...
        'VariableNames',{'Country','Current_MVaR','Prior_MVaR','Posterior_MVaR'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.MVaR_Table);
    R.Output4Reports.outputTab.colHeader  = {'Country', 'Current MVAR','Prior MVAR', 'Posterior MVAR'};
    R.Output4Reports.outputTab.format = {'char', 'commaIconMap', 'commaIconMap', 'commaIconMap'};
    
    % MARGINAL VAR (COUNTRY)
elseif strcmp(tableName,'MargVaR_Country_mon_SA')
    
    R.Output4Reports.MVaR_Table = table(otherParam.selectedMVaR_AssetCtry_Table.Asset_Ctry, ...
        otherParam.selectedMVaR_AssetCtry_Table.Current_MVaR.*R.IncludedNotional, ...
        'VariableNames',{'Country','Current_MVaR'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.MVaR_Table);
    R.Output4Reports.outputTab.colHeader  = {'Country', 'Current MVAR'};
    R.Output4Reports.outputTab.format = {'char', 'commaIconMap', 'commaIconMap', 'commaIconMap'};
    
    % MARGINAL VAR (SECTOR)
elseif strcmp(tableName,'MargVaR_Sector_mon')
    
    R.Output4Reports.MVaR_Table = table(otherParam.selectedMVaR_AssetSect_Table.Asset_Sect, ...
        otherParam.selectedMVaR_AssetSect_Table.Current_MVaR.*R.IncludedNotional, ...
        otherParam.selectedMVaR_AssetSect_Table.Prior_MVaR.*R.IncludedNotional, ...
        otherParam.selectedMVaR_AssetSect_Table.Posterior_MVaR.*R.IncludedNotional,...
        'VariableNames',{'Sector','Current_MVaR','Prior_MVaR','Posterior_MVaR'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.MVaR_Table);
    R.Output4Reports.outputTab.colHeader  = {'Sector', 'Current MVAR','Prior MVAR', 'Posterior MVAR'};
    R.Output4Reports.outputTab.format = {'char', 'commaIconMap', 'commaIconMap', 'commaIconMap'};
    
    % MARGINAL VAR (SECTOR)
elseif strcmp(tableName,'MargVaR_Sector_mon_SA')
    
    R.Output4Reports.MVaR_Table = table(otherParam.selectedMVaR_AssetSect_Table.Asset_Sect, ...
        otherParam.selectedMVaR_AssetSect_Table.Current_MVaR.*R.IncludedNotional, ...
        'VariableNames',{'Sector','Current_MVaR'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.MVaR_Table);
    R.Output4Reports.outputTab.colHeader  = {'Sector', 'Current MVAR'};
    R.Output4Reports.outputTab.format = {'char', 'commaIconMap'};
    
    % MARGINAL VAR (ALL ASSETS)
elseif strcmp(tableName,'MargVaR_All_mon')
    
    R.Output4Reports.MVaR_Table = table(otherParam.selectedMVaR_AssetAll_Table.Asset_All, ...
        otherParam.selectedMVaR_AssetAll_Table.Current_MVaR.*R.IncludedNotional, ...
        otherParam.selectedMVaR_AssetAll_Table.Prior_MVaR.*R.IncludedNotional, ...
        otherParam.selectedMVaR_AssetAll_Table.Posterior_MVaR.*R.IncludedNotional,...
        'VariableNames',{'All_Assets','Current_MVaR','Prior_MVaR','Posterior_MVaR'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.MVaR_Table);
    R.Output4Reports.outputTab.colHeader  = {'Assets', 'Current MVAR','Prior MVAR', 'Posterior MVAR'};
    R.Output4Reports.outputTab.format = {'char', 'commaIconMap', 'commaIconMap', 'commaIconMap'};
    
    % MARGINAL VAR (ALL ASSETS)
elseif strcmp(tableName,'MargVaR_All_mon_SA')
    
    R.Output4Reports.MVaR_Table = table(otherParam.selectedMVaR_AssetAll_Table.Asset_All, ...
        otherParam.selectedMVaR_AssetAll_Table.Current_MVaR.*R.IncludedNotional, ...
        'VariableNames',{'All_Assets','Current_MVaR'});
    
    % Output
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.MVaR_Table);
    R.Output4Reports.outputTab.colHeader  = {'Assets', 'Current MVAR'};
    R.Output4Reports.outputTab.format = {'char', 'commaIconMap'};
    
    % PRIOR AND POSTERIOR RETURNS FROM CURRENT PTF
elseif strcmp(tableName,'Return')
    
    %disp('Creating Prior/Posterior Marginal VaR Table');
    R.Output4Reports.MarginalRetTable = table(otherParam.measureTable.Assets, otherParam.measureTable.Prior_Wgt_RET, otherParam.measureTable.Posterior_Wgt_RET, otherParam.measureTable.Differences_RET,...
        'VariableNames',{'Assets','PriorMargRET','PosteriorMargRET','Diff'});
    
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.MarginalRetTable);
    R.Output4Reports.outputTab.colHeader  = {'Assets','Prior Wgt RET','Posterior Wgt RET','Differences'};
    R.Output4Reports.outputTab.format = {'char', 'percIconMap', 'percIconMap', 'percIconMapBorder'};
    
    % MARKET RETURNS FROM CURRENT PTF
elseif strcmp(tableName,'MktReturn')
    
    
    %disp('Creating Prior/Posterior Marginal VaR Table');
    R.Output4Reports.MarginalMktRetTable = table(otherParam.measureTable.Assets, otherParam.measureTable.MarketUnwgt_Posterior_RET,...
        'VariableNames',{'Assets', 'PosteriorMktRet'});
    
    R.Output4Reports.outputTab.matrix = table2cell(R.Output4Reports.MarginalMktRetTable);
    R.Output4Reports.outputTab.colHeader  = {'Assets','Market Unweighted posterior RET'};
    R.Output4Reports.outputTab.format = {'char', 'percIconMapBorder'};
    
    % PTF RISK SUMMARY CURR
elseif strcmp(tableName,'PortRiskSummary_CURR')
    
    % based on the chosen risk level
    firstCol  = {'Measures', ...
        'Current Portfolio VaR based on Prior',    'Current Portfolio VaR based on Posterior', ...
        'Current Portfolio ES based on Prior',     'Current Portfolio ES based on Posterior', ...
        'Current Portfolio Return based on Prior', 'Current Portfolio Return based on Posterior'}';
    secondCol = {'% amount', ...
        num2str(otherParam.selectedVaR_prior_curr), num2str(otherParam.selectedVaR_post_curr), ...
        num2str(otherParam.selectedES_prior_curr),  num2str(otherParam.selectedES_post_curr), ...
        num2str(otherParam.ProjReturn_Prior_curr),  num2str(otherParam.ProjReturn_post_curr)}';
    thirdCol  = {'€ amount', ...
        num2str(otherParam.selectedVaR_prior_curr*R.IncludedNotional), num2str(otherParam.selectedVaR_post_curr*R.IncludedNotional), ...
        num2str(otherParam.selectedES_prior_curr*R.IncludedNotional),  num2str(otherParam.selectedES_post_curr*R.IncludedNotional), ...
        num2str(otherParam.ProjReturn_Prior_curr*R.IncludedNotional),  num2str(otherParam.ProjReturn_post_curr*R.IncludedNotional)}';
    
    tableCurrentPRS = [firstCol, secondCol, thirdCol];
    
    % Table
    R.Output4Reports.outputTab.matrix = tableCurrentPRS(2:end,:);
    R.Output4Reports.outputTab.colHeader = tableCurrentPRS(1,:);
    R.Output4Reports.outputTab.format = {'char', 'perc2', 'comma'};
    
    % PTF RISK SUMMARY MP
elseif strcmp(tableName,'PortRiskSummary_MP')
    
    % based on the chosen risk level
    firstCol  = {'Measures', ...
        'VaR of Optimal Prior  Portfolio',       'VaR of Optimal Prior Portfolio SHOCKED', ...
        'VaR of Optimal Posterior Portfolio',    'VaR of Optimal Posterior Portfolio SHOCKED', ...
        'ES of Optimal Prior Portfolio',         'ES of Optimal Prior Portfolio SHOCKED', ...
        'ES of Optimal Posterior Portfolio',     'ES of Optimal Posterior Portfolio SHOCKED', ...
        'Return of Optimal Prior Portfolio',     'Return of Optimal Prior Portfolio SHOCKED', ...
        'Return of Optimal Posterior Portfolio', 'Return of Optimal Posterior Portfolio SHOCKED'}';
    secondCol = {'% amount', ...
        num2str(otherParam.selectedVaR_prior), num2str(otherParam.selectedVaR_prior_WithPostProb), ...
        num2str(otherParam.selectedVaR_posterior), num2str(otherParam.selectedVaR_posterior_WithPostProb), ...
        num2str(otherParam.selectedES_prior),  num2str(otherParam.selectedES_prior_WithPostProb),  ...
        num2str(otherParam.selectedES_posterior), num2str(otherParam.selectedES_posterior_WithPostProb), ...
        num2str(otherParam.ProjReturn_Prior),  num2str(otherParam.ProjReturn_PriorOnPostProb), ...
        num2str(otherParam.ProjReturn_Posterior), num2str(otherParam.ProjReturn_PosteriorOnPostProb)}';
    thirdCol  = {'€ amount', ...
        num2str(otherParam.selectedVaR_prior*R.IncludedNotional), num2str(otherParam.selectedVaR_prior_WithPostProb*R.IncludedNotional), ...
        num2str(otherParam.selectedVaR_posterior*R.IncludedNotional), num2str(otherParam.selectedVaR_posterior_WithPostProb*R.IncludedNotional),...
        num2str(otherParam.selectedES_prior*R.IncludedNotional),  num2str(otherParam.selectedES_prior_WithPostProb*R.IncludedNotional),  ...
        num2str(otherParam.selectedES_posterior*R.IncludedNotional), num2str(otherParam.selectedES_posterior_WithPostProb*R.IncludedNotional),...
        num2str(otherParam.ProjReturn_Prior*R.IncludedNotional),  num2str(otherParam.ProjReturn_PriorOnPostProb*R.IncludedNotional),  ...
        num2str(otherParam.ProjReturn_Posterior*R.IncludedNotional), num2str(otherParam.ProjReturn_PosteriorOnPostProb*R.IncludedNotional)}';
    tableModelPRS = [firstCol, secondCol, thirdCol];
    
    % Table
    R.Output4Reports.outputTab.matrix = tableModelPRS(2:end,:);
    R.Output4Reports.outputTab.colHeader = tableModelPRS(1,:);
    R.Output4Reports.outputTab.format = {'char', 'perc2', 'comma'};
    
    % RISK METHODOLOGY CURR
elseif strcmp(tableName,'RiskMethodology_CURR')
    
    % based on the chosen risk level
    firstCol  = {'Measures', ...
        'Current Portfolio VaR - Montecarlo Methodology', ...
        'Current Portfolio VaR - Historical Methodology', ...
        'Current Portfolio VaR - Parametric Methodology', ...
        'Current Portfolio ES - Montecarlo Methodology', ...
        'Current Portfolio ES - Historical Methodology', ...
        'Current Portfolio ES - Parametric Methodology'}';
    secondCol = {'% amount', ...
        num2str(otherParam.selectedVaR_prior_curr), ...
        num2str(otherParam.selectedVaR_prior_curr_Hist), ...
        num2str(otherParam.selectedVaR_prior_curr_Param),  ...
        num2str(otherParam.selectedES_prior_curr), ...
        num2str(otherParam.selectedES_prior_curr_Hist),  ...
        num2str(otherParam.selectedES_prior_curr_Param)}'; %TODO: num2str(otherParam.selectedES_prior_curr_Param)
    thirdCol  = {'€ amount', ...
        num2str(otherParam.selectedVaR_prior_curr*R.IncludedNotional), ...
        num2str(otherParam.selectedVaR_prior_curr_Hist*R.IncludedNotional), ...
        num2str(otherParam.selectedVaR_prior_curr_Param*R.IncludedNotional), ...
        num2str(otherParam.selectedES_prior_curr*R.IncludedNotional), ...
        num2str(otherParam.selectedES_prior_curr_Hist*R.IncludedNotional), ...
        num2str(otherParam.selectedES_prior_curr_Param*R.IncludedNotional)}'; %TODO: num2str(otherParam.selectedES_prior_curr_param*R.IncludedNotional)
    
    tableCurrentPRS = [firstCol, secondCol, thirdCol];
    
    % Table
    R.Output4Reports.outputTab.matrix = tableCurrentPRS(2:end,:);
    R.Output4Reports.outputTab.colHeader = tableCurrentPRS(1,:);
    R.Output4Reports.outputTab.format = {'char', 'perc2', 'comma'};
    
    % TARGET RISK
elseif strcmp(tableName,'TargetRisk')
    
    tableOut.matrix = table2cell(otherParam.TargetTable);
    tableOut.header = {'Risk Name','Risk Level'};
    
    R.Output4Reports.outputTab.matrix    = tableOut.matrix;
    R.Output4Reports.outputTab.colHeader = tableOut.header;
    R.Output4Reports.outputTab.format    = {'char', 'perc2Bord'};
    
    % SCENARIO
elseif strcmp(tableName,'Scenario')
    
    % Table
    tableOut.matrix = {otherParam.ReferenceDate, num2str(R.HorizonDays), num2str(R.Budget), num2str(R.IncludedNotional)};
    tableOut.header = {'Aod', ' Time Horizon (days)', 'Total Notional', '  Included Notional'};
    
    R.Output4Reports.outputTab.matrix    = tableOut.matrix;
    R.Output4Reports.outputTab.colHeader = tableOut.header;
    R.Output4Reports.outputTab.format    = {'char2', 'comma', 'comma', 'comma'};
    
    % VIEWS
elseif strcmp(tableName, 'View')
    
    % Table
    tableOut.matrix = {num2str(R.SubjectiveViewsWeight), num2str(R.QuantViewsWgt), num2str(R.ConfInPrior)};
    tableOut.header = {'Confidence in SUBJECTIVE View ', 'Confidence in QUANTITATIVE View ', 'Confidence in PRIOR '};
    
    R.Output4Reports.outputTab.matrix    = tableOut.matrix;
    R.Output4Reports.outputTab.colHeader = tableOut.header;
    R.Output4Reports.outputTab.format    = {'perc2', 'perc2', 'perc2'};
    
    % EXCLUDED ASSETS (INV. UNIV.)
elseif strcmp(tableName, 'ExcludedAssetsIU')
    
    Excp = R.Exceptions;
    Excp.InvestmentUniverse.ExcludedAssetsLog(:,2:end) = [];
    if ~isempty(Excp)
        tempT = struct2table(Excp.InvestmentUniverse,'AsArray',true);
        tempC = table2cell(tempT);
        nCol  = size(tempT,2);
        maxRows = max(cellfun(@(x) size(x,1),tempC));
        tempMatr = repmat({' '},maxRows,nCol);
        for i=1:nCol
            nRows = size((tempC{1,i}),1);
            if nRows==0
                tempMatr(1,i) = {' '};
            elseif nRows==1
                tempMatr{1,i} = tempC{1,i};
            elseif nRows>1
                tempMatr(1:nRows,i) = tempC{1,i};
            end
        end
        
        % Table
        tableOut.header = tempT.Properties.VariableNames;
        tableOut.matrix = tempMatr;
        tableOut.format = repmat({'char'},1,nCol);
    else
        tableOut.header = {'Investment Universe'};
        tableOut.matrix = {'All Assets valuated'};
        tableOut.format = {'char'};
    end
    
    R.Output4Reports.outputTab.matrix    = tableOut.matrix;
    R.Output4Reports.outputTab.colHeader = tableOut.header;
    R.Output4Reports.outputTab.format    = tableOut.format;
    
    
    % EXCLUDED ASSETS (CURVES)
elseif strcmp(tableName, 'ExcludedAssetsCRV')
    
    if ~isempty(R.Exceptions)
        tempT = struct2table(R.Exceptions.Curves,'AsArray',true);
        tempC = table2cell(tempT);
        nCol  = size(tempT,2);
        for i=1:nCol
            nRows = size((tempC{1,i}),1);
            tempMatr(1:nRows,i) = tempC{1,i};
        end
        
        % Table
        tableOut.header = tempT.Properties.VariableNames;
        tableOut.matrix = tempMatr;
        tableOut.format = repmat({'char'},1,nCol);
    else
        tableOut.header = {'Curves'};
        tableOut.matrix = {'All Assets valuated'};
        tableOut.format = {'char'};
    end
    
    R.Output4Reports.outputTab.matrix    = tableOut.matrix;
    R.Output4Reports.outputTab.colHeader = tableOut.header;
    R.Output4Reports.outputTab.format    = tableOut.format;
    
    % EXCLUDED ASSETS (RF)
elseif strcmp(tableName, 'ExcludedAssetsRF')
    
    if ~isempty(R.Exceptions)
        % Table
        tableOut.header = {'External Risk Factors'};
        tableOut.matrix = R.Exceptions.ExternalRiskFactors;
        tableOut.format = {'char'};
    else
        tableOut.header = {'External Risk Factors'};
        tableOut.matrix = {'All Assets valuated'};
        tableOut.format = {'char'};
    end
    
    R.Output4Reports.outputTab.matrix    = tableOut.matrix;
    R.Output4Reports.outputTab.colHeader = tableOut.header;
    R.Output4Reports.outputTab.format    = tableOut.format;
    
    % MODEL SETTINGS
elseif strcmp(tableName, 'ModelSettings')
    
    tablePerim = {'MinHistDate4Assets';'NumPortf';'calibrateTails';'CentralValuesModel';'copula_NoSim';...
        'ProjectionResampling_numsim';...
        'Priori_IntialLookback';'Priori_MovWin';'MinFreqOfPriorUpdate';'QuantSignals';'SubjectiveViews';...
        'MaxReturn4FullFrontier_MV';'ExpectedShortfall_EF';'ConstrainedTotWgts'};
    tableDescr = {'All the assets having an history starting after this date will be excluded '; ...
        'Number of portfolio in the Efficient Frontier';...
        'TRUE: if marginal distributions are modeled with GPD;';...
        '"kernel" or "ecdf" to model the central piece of the invariants marginal distributions';...
        'Number of joint simulated scenarios in copula space';...
        'The date to check if an invariant is too short (if InvariantBackwardsProxy is equal to 1)';...
        'Initial lookback window (if Prior_MovWin is equal to 0)';...
        '0: to use the full past dataset; n: length of the hist distrib used at each point in time (for rolling window)';...
        'Minimum frequency for updating historical information (in the absence of algo signal)';...
        'TRUE: to take into account algo signals or automatic views';...
        'TRUE: in case of subjective view';...
        'Maximum target risk on the efficient frontier';...
        '1: M-ES optimization space; 0: per MV optimization space';...
        'Maximum total exposure constraint'};
    
    n = size(tablePerim, 1);
    tableOut.matrix = cell(n,3);
    for i=1:n
        tableOut.matrix{i,1} = tablePerim{i,1};
        tableOut.matrix{i,2} = R.params_AA.(tablePerim{i,1});
        tableOut.matrix{i,3} = tableDescr{i,1};
    end
    
    % Table
    tableOut.header = {'Parameter Name', 'Parameter Value','Parameter Description'};
    
    R.Output4Reports.outputTab.matrix    = tableOut.matrix;
    R.Output4Reports.outputTab.colHeader = tableOut.header;
    R.Output4Reports.outputTab.format    = {'char','char','char'};
    
    % ASSETS CONSTRAINTS
elseif strcmp(tableName, 'AssetsConstraints')
    
    % %Assets constraints with respect to the active asset
    % lbWeights   = R.params_AA.AA_constraints.lb(1, boolPos)';
    % ubWeights   = R.params_AA.AA_constraints.ub(1, boolPos)';
    
    % Table
    % TODO: fill with the whole perimeter, not only for the
    % assets inclued in AA.
    tableOut.matrix = R.weightsLim;
    tableOut.header = {'Assets Name', 'Lower Bound', 'Upper Bound'};
    
    R.Output4Reports.outputTab.matrix    = tableOut.matrix;
    R.Output4Reports.outputTab.colHeader = tableOut.header;
    R.Output4Reports.outputTab.format    = {'char','perc2','perc2'};
    
end

outputTab = R.Output4Reports.outputTab;

end % OutputTables4Report

