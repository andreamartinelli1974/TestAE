classdef RiskBudgetPTF < handle
    % classe to build a portfolio that follow a risk budgeting constraint
    % Based on: B.Bruder, T.Roncalli
    % "Managing Risk Exposures using the Risk Budgeting Approach"
    % the class use a multivariate optimization to find the weights 
    % of the portfolio
    % the class mimic the input structure and the output structure of
    % EfficientFrontier.m
    
    properties
        RB_Return;
        RB_Risk;
        RB_Composition;
        MarginalRisks;
        Exitflag;
        Errors;
        OtherOutputs;
    end
    properties (SetAccess = immutable)
        params = [];
    end
    
    methods
        % CONSTRUCTOR %
        function RB = RiskBudgetPTF(params)
            % params is a struct array with the following fields:
            % params.covs = covariance matrix
            % params.budgets = array of the risk budget of any asset
            % params.AA_constraints.ub = upper bounds for the allocation
            % (array with the bounds for any asset)
            % params.AA_constraints.lb = lower bounds for the allocation
            % (same as ub)
            % RB.params.MaxLongShortExposure = max long and short exposure
            % for the whole portfolio (array)
            % params.ExpectedValues = array with the expected returns for
            % any asset at the investment horizon
            % params.CurrentWgts = array with the urrent weight of any
            % asset
            
            % TO INSERT A ASSET LEGEND INTO THE OUTPUT (not yet used)
            % params.ActiveAssets =active assets
            % params.Assets_Legend_active = names of the active assets
            
            RB.params = params;
        end
        
        function PtfBuilding(RB)
            % Risk Budgeting ptf building function
            % Having the vector of desired Risk Budgets for any asset
            % this function calculates the weights for any asset in the ptf
            
            warning off;
            
            
            % external params
            Covariance = RB.params.covs;
            RBudgets = RB.params.budgets;
            UpperBound = RB.params.AA_constraints.ub;
            LowerBound = RB.params.AA_constraints.lb;
            MaxLongShortExposure = RB.params.MaxLongShortExposure';
            Exposure = RB.params.ConstrainedTotWgts;
            ExpectedValues = RB.params.ExpectedValues;
            CurrentWgts = RB.params.CurrentWgts;
            equalWeightsFlag = RB.params.equalWeightsFlag;
            MinNetExposure = RB.params.MinNetExposure;
            
            if ~equalWeightsFlag
                ErrorMsg = [];
                
                NofAssets = size(Covariance,2);
                
                if isempty(RBudgets) % just in case not defined before: Risk parity option
                    RBudgets = 1/NofAssets*ones(NofAssets,1);
                end
                
                % check for zero risk budget asset: they must be excluded from
                % the optimization ad included at the end of the process with 0 weight
                
                nonzeroRB_Assets = find(RBudgets);
                NofNonZeroA = numel(nonzeroRB_Assets);
                
                zeroRB_Assets = find(~RBudgets);
                NofZeroA = numel(zeroRB_Assets);
                
                CovarianceFinal = Covariance;
                RBudgetsFinal = RBudgets;
                
                if NofZeroA > 0
                    Covariance(:,zeroRB_Assets) = [];
                    Covariance(zeroRB_Assets,:) = [];
                    RBudgets(zeroRB_Assets) = [];
                    RBudgets = RBudgets/sum(RBudgets);
                    NofAssets = NofNonZeroA;
                    LowerBound(zeroRB_Assets) = [];
                    UpperBound(zeroRB_Assets) = [];
                end
                % end of check
                
                % optimization function
                fun = @(x)RB_optimum(x,Covariance,RBudgets);
                
                % starting points
                x0 = 1/NofAssets*ones(NofAssets,1);
                
                % constraints (disequalities)
                if ~isempty(MaxLongShortExposure)
                    A = [ones(1,NofAssets); -ones(1,NofAssets)];
                    b = [MaxLongShortExposure(1);-MaxLongShortExposure(2)];
                else
                    A = [];
                    b = [];
                end
                if ~isempty(MinNetExposure)
                    A = [A; -ones(1,NofAssets)];
                    b = [b; -MinNetExposure];
                end
                
                % constraints (equalities)
                if ~isempty(Exposure)
                    Aeq = ones(1,NofAssets);
                    beq = Exposure;
                else
                    Aeq = [];
                    beq = [];
                end
                
                % linear equality constraints that might be triggered by
                % quant strategies
                if ~isempty(RB.params.beqFromQviews)
                    Aeq = [Aeq;RB.params.AeqFromQviews];
                    beq = [beq;RB.params.beqFromQviews];
                end
                % option for fmincon: 
                % 1) displays no outputs
                % 2) sqp algorithm (seems faster in this case)
                
                options = optimoptions('fmincon');
                options.ConstraintTolerance = 1.000e-03;
                options.Algorithm = 'sqp';
                options.Display = 'off';
                % options.Display = 'iter'; % for debug purpose

                
                exitcheck = 0;
                counter = 0;
                normFlag = 0;
                
                while exitcheck == 0
                    
                    [AssetWeights,fval,exitflag,output] = fmincon(fun,x0,A,b,Aeq,beq,LowerBound,UpperBound,[],options);
                    
                    if exitflag == 0
                        % not enogh iteractions or function evaluations ->
                        % increases iterations & evaluation
                        options.MaxFunctionEvaluations = NofAssets*10000;
                        options.MaxIterations = 40000;
                        counter = counter + 1;
                        
                    elseif exitflag == -2
                        % no feasible point ->
                        % relax the bounds
                        UpperBound = UpperBound * 2;
                        LowerBound = LowerBound * 2;
                        A = [];
                        b = [];
                        Aeq = [];
                        beq = [];
                        counter = counter + 1;
                        normFlag = 1;
                        
                    else
                        exitcheck = 1;
                        disp("RB_Optimization found a solution")
                    end
                    if counter > 3
                        exitcheck = 1;
                        if exitflag == 0
                            ErrorMsg = strcat("RB_Optimisation could not find a solution even after ",string(options.MaxIterations), ...
                                " iterations and ", string( options.MaxFunctionEvaluations), ...
                                " function evaluations - not enogh iteractions or function evaluations")
                            
                        elseif exitflag == -2
                            ErrorMsg = "RB_Optimisation could not find a solution even relaxing the bounds - no feasible point"
                            
                        end
                    end
                end %while
                
                if normFlag == 1
                    %%%% in case a solution was found without bounds (exitflag = -2) %%%%
                    
                    % Normalization of the allocations
                    % check on the sign of the total exposure found and the target
                    % total exposure of the portfolio (eg. if the target ptf is net
                    % short, the total exposure of the Risk Budget portfolio can't
                    % be net long)
                    
                    % this procedure is to mnormalize the solutions in a way the could
                    % fit the upper and lower bound and the target global exposure
                    % of the portfolio: cfr note 12 page 9 of B.Bruder, T.Roncalli
                    % "Managing Risk Exposures using the Risk Budgeting
                    % Approach"
                    
                    ErrorMsg = strcat(ErrorMsg," RB_Optimisation found a solution without constraints, then normalize it to fit the constraints")
                    if ~isempty(MaxLongShortExposure)
                        LongShortBound = min(abs(MaxLongShortExposure));
                    elseif ~isempty(MinNetExposure)
                        LongShortBound = MinNetExposure;
                    end
                    TotalExp = sum(AssetWeights);
                    if isempty(Exposure)
                        Exposure = sign(TotalExp); % needed to normalize the vector of the allocations
                    end
                    if sign(TotalExp) == sign(Exposure)
                        AssetWeights = AssetWeights / TotalExp * sign(Exposure)*min([abs(Exposure),LongShortBound]);
                    else
                        AssetWeights = AssetWeights / TotalExp * sign(TotalExp)*min([abs(Exposure),LongShortBound]);
                        ErrorMsg = strcat(ErrorMsg, " - WARNING: THE SIGN OF THE TOTAL EXPOSURE IS DIFFERENT FROM THE SIGN OF THE REQUIRED EXPOSURE")
                    end
                    
                end %if normflag
                
                % output section
                if NofZeroA > 0 % in case there is some zero risk budget asset
                    AssetWeightsFinal = zeros(NofNonZeroA+NofZeroA,1);
                    AssetWeightsFinal(nonzeroRB_Assets) = AssetWeights;
                else
                    AssetWeightsFinal = AssetWeights;
                end
                
                %%% OUTPUTS
                                
                RB.Errors = ErrorMsg;
                RB.OtherOutputs.fval = [RB_optimum(AssetWeightsFinal,CovarianceFinal,RBudgetsFinal),fval];
                RB.OtherOutputs.OptOut = output;
                RB.OtherOutputs.RiskTarget = [margRiskContributions(AssetWeightsFinal,CovarianceFinal)/ ...
                                            sum(margRiskContributions(AssetWeightsFinal,CovarianceFinal)), RBudgetsFinal];
                RB.MarginalRisks = margRiskContributions(AssetWeightsFinal,CovarianceFinal);
                
                RB.RB_Return = AssetWeightsFinal' * ExpectedValues;
                RB.RB_Risk = sqrt(AssetWeightsFinal' * CovarianceFinal * AssetWeightsFinal);
                RB.RB_Composition = AssetWeightsFinal';
                RB.Exitflag = exitflag;
                
                %%% END OUTPUTS
                
                
            elseif equalWeightsFlag
                % optimization has not run since the vector of weights was
                % given. Riks and Return figures are claulated based on this
                % fixed vector of weights
                RB.Errors = ('error with Risk Budget constraints: upper and lower bound are the same');
                RB.OtherOutputs.fval = [];
                RB.OtherOutputs.OptOut = [];
                RB.OtherOutputs.RiskTarget = [];
                RB.MarginalRisks = margRiskContributions(CurrentWgts',Covariance);
                
                RB.RB_Return = CurrentWgts*ExpectedValues;
                RB.RB_Risk = sqrt(CurrentWgts*Covariance*CurrentWgts');
                RB.RB_Composition = CurrentWgts;
                RB.Exitflag = 999; % used when no optimization occurred because of fixed weights for all of the assets
            end
            
            % target function
            % see formula 8) at page 9 of the paper
            function target = RB_optimum(x,Covariance,RBudgets)
                marginalRisks = margRiskContributions(x,Covariance);
                target = sum((marginalRisks/sum(marginalRisks)-RBudgets).^2);        
            end
            function mrc = margRiskContributions(x,Covariance)
                denominator = (x'*Covariance*x)^0.5;
                numerator = x.*Covariance*x;
                mrc = numerator/denominator;
            end
        end % PtfBuilding
        
    end
end