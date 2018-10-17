classdef MV_EFrontier < Optimizations.EfficientFrontier
    % implementation of the EfficientFrontier abstract class in the MV
    % framework
    
    properties
        EF_Return;
        EF_Risk;
        EF_Composition;
        Exitflag;
    end
    
    methods
        function MV = MV_EFrontier(params)
            MV = MV@Optimizations.EfficientFrontier(params);
        end % constructor
        
        function Optimization(MV)
            % Efficient frontier optimization algorithm in the
            % Mean-Variance space
            warning off;
            
            equalWeightsFlag = MV.params.equalWeightsFlag; % if this flag is true no optimization takes place and the output weights are the same as the constrained weights
            MaxLongShortExposure = MV.params.MaxLongShortExposure; % 2 elements vector: e.g. [2 -3] means that max long and short exposures limits are 200% and 300% respecitvely
            MinNetExposure = MV.params.MinNetExposure;
            
            lb = MV.params.AA_constraints.lb;
            ub = MV.params.AA_constraints.ub;
            Covariance = MV.params.Covariance;
            ExpectedValues = MV.params.ExpectedValues;
            
            if ~equalWeightsFlag
                
                if MV.params.resampling % if Michaud type resampling is required
                    NumPort4Resampling = MV.params.resampling_params.NumPort4Resampling;
                    % target returns vector to be used for
                    % resampling
                    ER4Resampling = MV.params.resampling_params.ER4Resampling;
                end
                
                % Optimization options
                options = optimoptions(@quadprog,'Algorithm','interior-point-convex','Display','off');
                
                NumAssets=size(MV.params.Covariance,2);
                
                FirstDegree = zeros(NumAssets,1);
                SecondDegree = Covariance;
                NumPortf = MV.params.NumPortf;
                ConstrainedTotWgts = MV.params.ConstrainedTotWgts;
                % *************************************************************
                % ************ Constraints and intiail values  ****************
               
                % Adding equality constraints
                % sum of weights constraint (if ConstrainedTotWgts is not
                % empty)
                % ***************************
                if isempty(ConstrainedTotWgts)
                    AEq_fromSettings = [];
                    bEq_fromSettings = [];
                else
                    AEq_fromSettings=ones(1,NumAssets);
                    bEq_fromSettings = ConstrainedTotWgts;
                end
                
                % linear equality constraints that might be triggered by
                % quant strategies
                if ~isempty(MV.params.beqFromQviews)
                    AEq_fromSettings = [AEq_fromSettings;MV.params.AeqFromQviews];
                    bEq_fromSettings = [bEq_fromSettings;MV.params.beqFromQviews];
                end
                % ***************************
                % no-short constraint
                %  A=-eye(NumAssets);
                %  b=zeros(NumAssets,1);
                % ***************************
                % Adding inequality constraints
                A = [];
                b = [];
                % ***************************
                if ~isempty(MaxLongShortExposure)
                    A = ones(1,NumAssets).*(-1);
                    b = -MaxLongShortExposure(2);
                    A = [A; ...
                        ones(1,NumAssets)];
                    b = [b;MaxLongShortExposure(1)];
                end
                
                if ~isempty(MinNetExposure)
                    A = [A;ones(1,NumAssets).*(-1)];
                    b = [b;-MinNetExposure];
                end
                
                x0 = (ub+lb)./2; %1/NumAssets*ones(NumAssets,1);
                
                % ***************** End of constraints setup  *****************
                % *************************************************************
                
                % Get min volatility and max return portfolios
                [MinVol_Weights,minRisk,exitflag,~] = quadprog(SecondDegree,FirstDegree,A,b,AEq_fromSettings,bEq_fromSettings,lb,ub,x0,options);
                EF_exitflags = exitflag;
                MinVol_Return = MinVol_Weights'*ExpectedValues;
                
                if ~MV.params.resampling
                    
                    % I
                    % *****************************************************
                    % max risk on the efficient frontier set by the user
                    mxrFromUser = MV.params.MaxReturn4FullFrontier_MV;
                    
                    % II
                    % max achievable return 
                    % *****************************************************
                    % Getting max return portfolio
                    [MaxRet_Weights,~,exitflag] = linprog(-ExpectedValues,A,b,AEq_fromSettings,bEq_fromSettings,lb,ub);
                    % TODO: check better the logic in the IF below
                    if exitflag~=1 & exitflag~=-3  & MaxESpoint.Exitflag~=-5
                        m = msgbox('MV optimization for the highest point of the EF is not feasible (or Primal and Dual problems undeasible) - Execution terminated' ...
                            ,'Icon','warn','replace');
                        pause(1.5);
                        close(m);
                        return
                    elseif exitflag==-3 | exitflag==-5 % sometimes infeasibility of primal and dual seems to arise when the problem is unbounded (look at this in more depth TODO)
                        % the problem is unbounded (very likely outcome)
                        % the highest risk on the EF is set to .MaxRisk4FullFrontier_MV
                        
                        m = msgbox(['Optimization for the highest point of the EF is UNBOUNDED (or Primal and Dual problems undeasible - Max Risk set to ', num2str(MV.params.MaxRisk4FullFrontier_MV*100),'%'] ...
                            ,'Icon','warn','replace');
                        pause(1.5);
                        close(m);
                        mxr_calculated = MV.params.MaxRisk4FullFrontier_MV;
                    else
                        mxr_calculated = MaxRet_Weights'*ExpectedValues - 5e-10; % to avoid non convergence in the eff frontier cycle below due to rounding errors of the highest possible return
                    end
                    
                    % select the min between the calculated max target
                    % and the max target set by the user
                    if mxrFromUser > MinVol_Return
                        % I can set the higher level equal to the
                        % user's desired level (see initial parameters)
                        % only if this level is above the min computed level  ptf
                        mxr = min(mxrFromUser,mxr_calculated);
                    else
                        mxr = mxr_calculated;
                        msg = ['The max target return that has been provided (', num2str(mxrFromUser) ...
                            ,') is less than the min return portfolio (',num2str(MinVol_Return),') - The max risk on the EF is reset to the highest computed value (' ...
                            ,num2str(mxr_calculated),')'];
                        m = msgbox(msg,'Icon','warn');
                        pause(1.5);
                    end
                    
                    % if, after the step above, MaxES_Risk is still <
                    % MinES_Risk, there must be  something wrong
                    if mxr <= MinVol_Return
                        msg = ['The max target return used  is less than the Min Return Ptf (',num2str(MinVol_Return),') - There is somethin not working properly'];
                        m = msgbox(msg,'Icon','warn');
                        pause(1.5);
                        close(m);
                        MV.Exitflag = 888.*ones(1,NumPortf); % used when the no optim occurred since max target ret was less then min risk return
                        return
                    end
                    
                    % slice efficient frontier in NumPortf equally thick horizontal
                    % sectors in the upper branch only
                    Step=(mxr-MinVol_Return)/(NumPortf-1);
                    TargetReturns=[MinVol_Return : Step : mxr];
                    NumTotPortfolios = size(TargetReturns,2);
                    
                elseif MV.params.resampling % **** NO MORE USED
                    % when this method is called for resampling, the vector of
                    % target returns is given, as well as the no of portfolios
                    NumPortf = NumPort4Resampling;
                    TargetReturns = ER4Resampling;
                end % ~resampling
                
                % *************************************************************
                % ********  MV Efficient Frontier quadratic optimization ******
                % *************************************************************
                
                disp(['Slicing the Efficient Frontier into ',num2str(NumPortf),' portfolios']);
                NumPortf_completed = false(1);
                
                while ~NumPortf_completed
                    PortfolioComposition = MinVol_Weights';
                    PortfolioVolatility = sqrt(MinVol_Weights'*Covariance*MinVol_Weights);
                    PortfolioExpectedValue = MinVol_Weights'*ExpectedValues;
                    
                    for i=2:NumPortf %-1
                        % disp(['Point on the eff frontier no ',num2str(i)]);
                        % to constrain sum of weights to be 1
                        % determine least risky portfolio for given expected return
                        % sum of weights must be  1
                        
                        AEQ=[AEq_fromSettings;
                            ExpectedValues'];
                        BEQ=[bEq_fromSettings
                            TargetReturns(i)]; 
                       
                        tic
                        [Weights,~,exitflag,~] = quadprog(SecondDegree,FirstDegree,A,b,AEQ,BEQ,lb,ub,x0,options);
                        toc
                        
                        EF_exitflags = [EF_exitflags,exitflag];
                        if exitflag  < 0 % no convergence
                            % m = msgbox('A single optimization on a point of the EF is not feasible: point removed NaN' ...
                            %    ,'Icon','warn','replace');
                            disp('A single optimization on a point of the EF is not feasible: point removed NaN');
                            PortfolioComposition = [PortfolioComposition;NaN*ones(1,size(PortfolioComposition,2))];
                            PortfolioVolatility = [PortfolioVolatility,NaN];
                            PortfolioExpectedValue = [PortfolioExpectedValue,NaN];
                            continue;
                        end
                        
                        Weights = Weights';
                        risk = sqrt(Weights*Covariance*Weights');
                        % TODO: (temp) IMPORTANT: investigate in more depth these occurrences
                        if risk < PortfolioVolatility(i-1)
                            % the optimal solution must
                            % have a risk above the risk
                            % corresponding to the previous point (less
                            % risk and lower return) on the efficient frontier,
                            % other wise the combination is not recorded
                            disp('Optimal combination woudl yield a non convex frontier: skipped (NaN)');
                            EF_exitflags(end) = 888; % conventionally set to 888 when the optimal sol would result in a non convex eff front
                            PortfolioComposition = [PortfolioComposition;NaN*ones(1,size(PortfolioComposition,2))];
                            PortfolioVolatility = [PortfolioVolatility,NaN];
                            PortfolioExpectedValue = [PortfolioExpectedValue,NaN];
                            continue
                        end
                        
                        PortfolioComposition = [PortfolioComposition; Weights];
                        PortfolioVolatility = [PortfolioVolatility ...
                            risk];
                        PortfolioExpectedValue = [PortfolioExpectedValue ...
                            Weights*ExpectedValues];
                        NumPortf_completed = true(1);
                        
                    end % loop on no of portfolios along the EF
                    
                end % NumPortf_completed flag
                
                % *************************************************************
                warning on;
            elseif equalWeightsFlag
                % optimization has not run since the vector of weights was
                % given. Riks and Return figures are claulated based on this
                % fixed vector of weights
                PortfolioExpectedValue = lb*ExpectedValues;
                PortfolioVolatility = sqrt(lb*Covariance*lb');
                PortfolioComposition = lb;
                EF_exitflags = 999; % used when no optimization occurred because of fixed weights for all of the assets
            end
            MV.EF_Return = PortfolioExpectedValue;
            MV.EF_Risk = PortfolioVolatility;
            MV.EF_Composition = PortfolioComposition;
            MV.Exitflag = EF_exitflags;
            
        end % Optimization
        
    end % Public methods
    
end

