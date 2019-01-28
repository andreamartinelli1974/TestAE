classdef TailsCoDependence < handle
    % Class built to quantify dependence structure in the tails using tails
    % modeling / copula from class EVT_CopulaSim
    
    properties (SetAccess = immutable)
        
        inputParams = []; % set of initial parameters;
        inputData = []; % input data (see comments below)
        Names = []; % set of names associated to data{1} (for charting)
        DepName = []; % name associated to data{2} (for charting)
    end
    
    properties
        EVT; % cell vectors of instances of the class EVT_CopulaSim used to model each pair of data x and y (see below)
        SimX; % cell vectors of simulated x,y pairs
        % main outputs: cell arrays of vectors containing tails codependence for various levels of tails cutoff
        LAMBDA_lower;
        LAMBDA_upper;
    end
    
    methods
        
        % CONSTRUCTOR
        function T = TailsCoDependence(data,names,depName,params)
            % INPUTS:
            % -> data: must be a row vector of 2 cell arrays: the first one
            % containing a matrix [TXN] of T observations for N variables
            % (typically the independent variables or factors from
            % factors/regression analysis). The second cell must contain a
            % single vector of observation (typically  a 'dependent'
            % variable) of size [Tx1];
            % -> names: set of names associated to the matrix in data{1}
            % (one name for each column vector)
            % -> params: struct array whose fields are the following
            % parameters:
            % -> .evt_params: parameters needed to instantiate class
            % EVT_CopulaSim (see notes there)
            % -> added later (21.4.18) by GP: 'params' can have one more
            % field ('noEVT') that means that no tails modeling, GPD
            % modeling and copula fittting will be used and that the
            % dataset provided in 'data' will be used as it is. This is
            % used, e.g., to run this kind of analysys on raw historical
            % data. If this is the case then params.noEVT must evaluate to
            % true(1)
            % -> depName: char input containing the name od the single
            % dependent variable (using only for charts titles)
            
            T.inputParams = params;
            T.inputData = data;
            T.Names = names;
            T.DepName = depName;
            
            if isfield(params,'noEVT') && params.noEVT
                
                N = size(data{1},2);
                % cycling over the N columns of data{1} to study the tails
                % codependency structure between them and the data in data{2}
                x = data{2}; % this one does not change
                
                % LOGIC: the cycle below fits a copula (after tails cutoff
                % optimization and GPD fit for the tails) for each pair
                % Portfolio - Single Factors. So what we have in
                % evt.parametrizedDistributions{1} will always be a simulation
                % regarding the portfolio
                for n=1:N
                    y = data{1}(:,n);
                    %                     inputToEVT = [x,y];
                    
                    %                     import Optimizations.*;
                    %                     evt = EVT_CopulaSim(inputToEVT,[],params.evt_params);
                    %                     evt.FitCopulaAndSimulate;
                    %
                    %                     T.SimX{n,1} = evt.Simulated_X;
                    %                     T.EVT{n,1} = evt;
                    % for the pair being worked out perform tails codependence
                    % calculations
                    % ****************** TODO: the 2 FOR below are repeated:
                    % make a single method
                    % upper tail
                    cnt = 0;
                    noOfRealizations = size(y,1);
                    for threshold=0.70:0.01:0.99
                        cutoff1 = prctile(x,threshold*100); % evt.parametrizedDistributions{1}.icdf(threshold); % for the portfolio
                        x1 = find(x(:,1)>=cutoff1);
                        px1 = numel(x1)./noOfRealizations;
                        
                        cutoff2 = prctile(y,threshold*100); % evt.parametrizedDistributions{2}.icdf(threshold); % for the single n-th factor
                        x1x2 = find(x>=cutoff1 & y>=cutoff2 );
                        px1x2 = numel(x1x2)./noOfRealizations;
                        
                        cnt = cnt + 1;
                        LAMBDA_upper(cnt,1) = threshold;
                        LAMBDA_upper(cnt,2) = px1x2./px1;
                        
                    end
                    %                 fnan = find(isnan(LAMBDA_upper(:,2)));
                    %                 LAMBDA_upper(fnan,:) = [];
                    
                    % lower tail
                    cnt = 0;
                    for threshold=0.30:-0.01:0.01
                        cutoff1 = prctile(x,threshold*100); % evt.parametrizedDistributions{1}.icdf(threshold);
                        x1 = find(x(:,1)<=cutoff1);
                        px1 = numel(x1)./noOfRealizations;
                        
                        cutoff2 = prctile(y,threshold*100); % evt.parametrizedDistributions{2}.icdf(threshold);
                        x1x2 = find(x<=cutoff1 & y<=cutoff2 );
                        px1x2 = numel(x1x2)./noOfRealizations;
                        
                        cnt = cnt + 1;
                        LAMBDA_lower(cnt,1) = threshold;
                        LAMBDA_lower(cnt,2) = px1x2./px1;
                        
                    end
                    %                 fnan = find(isnan(LAMBDA_lower(:,2)));
                    %                 LAMBDA_lower(fnan,:) = [];
                    % ******************
                    
                    T.LAMBDA_lower{n,1} = LAMBDA_lower;
                    T.LAMBDA_upper{n,1} = LAMBDA_upper;
                    
                end % n FOR
                
                % ***********************************************************
            else % if EVT modeling must be run
                % ***********************************************************
                N = size(data{1},2);
                % cycling over the N columns of data{1} to study the tails
                % codependency structure between them and the data in data{2}
                x = data{2}; % this one does not change
                
                % LOGIC: the cycle below fits a copula (after tails cutoff
                % optimization and GPD fit for the tails) for each pair
                % Portfolio - Single Factors. So what we have in
                % evt.parametrizedDistributions{1} will always be a simulation
                % regarding the portfolio
                for n=1:N
                    y = data{1}(:,n);
                    inputToEVT = [x,y];
                    
                    import Optimizations.*;
                    evt = EVT_CopulaSim(inputToEVT,[],params.evt_params);
                    evt.FitCopulaAndSimulate;
                    
                    T.SimX{n,1} = evt.Simulated_X;
                    T.EVT{n,1} = evt;
                    % for the pair being worked out perform tails codependence
                    % calculations
                    % ****************** TODO: the 2 FOR below are repeated:
                    % make a single method
                    % upper tail
                    cnt = 0;
                    noOfRealizations = size(evt.Simulated_X,1);
                    for threshold=0.70:0.01:0.99
                        cutoff1 = evt.parametrizedDistributions{1}.icdf(threshold); % for the portfolio
                        x1 = find(evt.Simulated_X(:,1)>=cutoff1);
                        px1 = numel(x1)./noOfRealizations;
                        
                        cutoff2 = evt.parametrizedDistributions{2}.icdf(threshold); % for the single n-th factor
                        x1x2 = find(evt.Simulated_X(:,1)>=cutoff1 & evt.Simulated_X(:,2)>=cutoff2 );
                        px1x2 = numel(x1x2)./noOfRealizations;
                        
                        cnt = cnt + 1;
                        LAMBDA_upper(cnt,1) = threshold;
                        LAMBDA_upper(cnt,2) = px1x2./px1;
                        
                    end
                    %                 fnan = find(isnan(LAMBDA_upper(:,2)));
                    %                 LAMBDA_upper(fnan,:) = [];
                    
                    % lower tail
                    cnt = 0;
                    for threshold=0.30:-0.01:0.01
                        cutoff1 = evt.parametrizedDistributions{1}.icdf(threshold);
                        x1 = find(evt.Simulated_X(:,1)<=cutoff1);
                        px1 = numel(x1)./noOfRealizations;
                        
                        cutoff2 = evt.parametrizedDistributions{2}.icdf(threshold);
                        x1x2 = find(evt.Simulated_X(:,1)<=cutoff1 & evt.Simulated_X(:,2)<=cutoff2 );
                        px1x2 = numel(x1x2)./noOfRealizations;
                        
                        cnt = cnt + 1;
                        LAMBDA_lower(cnt,1) = threshold;
                        LAMBDA_lower(cnt,2) = px1x2./px1;
                        
                    end
                    %                 fnan = find(isnan(LAMBDA_lower(:,2)));
                    %                 LAMBDA_lower(fnan,:) = [];
                    % ******************
                    
                    T.LAMBDA_lower{n,1} = LAMBDA_lower;
                    T.LAMBDA_upper{n,1} = LAMBDA_upper;
                    
                end % n FOR
                
            end % if on params.noEVT flag
        end % constructor
        
        
        % PLOT TAILS DEPENDENCIES
        function PlotTailsDependencies(T, chartName, T2)
            
            disp('Plotting Tails Co_dependencies');
            
            switch chartName
                
                case 'Lower'
                    
                    lambda   = T.LAMBDA_lower;
                    cfNames  = T.Names;
                    xSteps   = 0:0.02:0.30;
                    xReverse = 'normal'; % 'reverse';
                    tmpT = strrep(strcat(strcat('between "', T.DepName), '" and list of assets shown in the chart legend'),'_',' ');
                    tNames   = {'LOWER Tail Dependence:' ; tmpT(1)};
                    compareM = 0;
                    step2    = 0;
                    
                    plotDependencies;
                    
                case 'Upper'
                    
                    lambda   = T.LAMBDA_upper;
                    cfNames  = T.Names;
                    xSteps   = 0.70:0.02:1;
                    xReverse = 'normal';
                    tmpT = strrep(strcat(strcat('between "', T.DepName), '" and list of assets shown in the chart legend'),'_',' ');
                    tNames   = {'UPPER Tail Dependence:' ; tmpT(1)};
                    compareM = 0;
                    step2    = 0;
                    
                    plotDependencies;
                    
                case 'CompareL'
                    
                    lambda   = T.LAMBDA_lower;
                    cfNames  = T.Names;
                    xSteps   = 0:0.02:0.30;
                    xReverse = 'normal'; % 'reverse';
                    tmpT = strrep(strcat(strcat('between "', T.DepName), '" and list of assets shown in the chart legend'),'_',' ');
                    tNames   = {'LOWER Tail Dependence:' ; tmpT(1)};
                    compareM = 1;
                    step2    = 0;
                    
                    plotDependencies;
                    
                    clear lambda;
                    clear cfNames;
                    
                    lambda   = T2.LAMBDA_lower;
                    cfNames  = T2.Names;
                    compareM = 1;
                    step2    = 1;
                    
                    plotDependencies;
                    
                case 'CompareU'
                    
                    lambda   = T.LAMBDA_upper;
                    cfNames  = T.Names;
                    xSteps   = 0.70:0.02:1;
                    xReverse = 'normal'; % 'reverse';
                    tmpT = strrep(strcat(strcat('between "', T.DepName), '" and list of assets shown in the chart legend'),'_',' ');
                    tNames   = {'UPPER Tail Dependence:' ; tmpT(1)};
                    compareM = 1;
                    step2    = 0;
                    
                    plotDependencies;
                    
                    clear lambda;
                    clear cfNames;
                    
                    lambda   = T2.LAMBDA_upper;
                    cfNames  = T2.Names;
                    compareM = 1;
                    step2    = 1;
                    
                    plotDependencies;
                    
            end % switch
            
            % PLOT DEPENDENCIES: nested function
            function plotDependencies
                
                lineStyle = '-';
                
                check = compareM * step2;
                
                if check==0                                                 % Plot HISTORICAL Methodology or Single Methodology
                    
                    % Figure
                    figure('OuterPosition', [230 230 850 610])
                    %xy = axes;
                    grid on;
                    hold on;
                    legendName = strrep(cfNames,'_',' ');
                    
                elseif check==1                                             % Plot SIMULATED Methodology in addition to HISTORICAL one
                    
                    lineStyle = '--';
                    
                    % Legend
                    lName = strrep(cfNames,'_',' ');
                    legendName1 = cellfun(@(x) strcat(x,' Hist'),lName,'UniformOutput',false);
                    legendName2 = cellfun(@(x) strcat(x,' Simul'),lName,'UniformOutput',false);
                    legendName = [legendName1; legendName2];
                    
                end
                
                
                % Color
                colorsType = 'brgkcym';
                colorCounter = 0;
                
                % X: Percentile
                X = lambda{1,1}(:,1); % the x-axis is the same for all lower tails charts
                n = size(lambda, 1);  % no of lower tails charts
                for c = 1:n
                    colorCounter = colorCounter + 1;
                    if colorCounter > numel(colorsType) % to reset colors counter when all available colors have been used
                        colorCounter = 1;
                    end
                    % Y: Lambda
                    Y = lambda{c,1}(:,2);
                    plot(X, Y, 'Color', colorsType(colorCounter), 'LineStyle', lineStyle, 'LineWidth', 2)
                end
                
                % X
                set(gca, 'XTick', xSteps);
                set(gca, 'XDir', xReverse);
                set(gca, 'XTickLabelRotation', 45);
                xlabel('Percentile');
                
                % Y
                ylabel('Dependence');
                
                % Legend
                legend(legendName, 'FontSize', 8);
                
                % Title
                title(tNames, 'FontSize', 12, 'Units', 'normalized', 'HorizontalAlignment', 'left', 'Position', [0.1 1]);
                
            end
            
        end % PlotTailsDependencies
        
        
        function outputText = Text4Report(T)
            % this method is designed to create a string/description
            T.Names;
            
            if strcmp(tableName,'TextBox')
                
                text = 'Description of codependencies features';
                
            end
            
            outputText = text;
            
        end % Text4Report
        
    end % public methods
    
    
    methods (Static)
        
        function compareHistSimTailsDependencies(HistTailObj,SimTailObj,lambdaChoice)
            
            % This static method is useful to compare Historical Method
            % with Simulated one in the same chart
            %
            % INPUT:
            % HistTailObj:  first object must be the Historical one
            % SimTailObj:   second object must be the Simulated one
            % lambdaChoice: it could be 'CompareL' or 'CompareU'
            
            HistTailObj.PlotTailsDependencies(lambdaChoice,SimTailObj);
            
        end
    end
    
end

