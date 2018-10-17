classdef MES_EFrontier < Optimizations.EfficientFrontier
    % implementation of the EfficientFrontier abstract class in the Mean
    % Expected Shortfall framework
    
    properties
        EF_Return;linprog
        EF_Risk;
        EF_Composition;
        Exitflag;
        OtherOutputs;
    end
    
    methods
        function MES = MES_EFrontier(params)
            MES = MES@Optimizations.EfficientFrontier(params);
        end % constructor
        
        function Optimization(MES,varargin)
            % Efficient frontier optimization algorithm in the
            % Mean-Variance space
            % invertFlag: (optional): if set to True(1) the optimization is
            % 'inverted': a minimization becomes a maximization. THIS
            % PARAMETERS IS USED WITH 'LINEARIZED' OPTIMIZATIONS ONLY.
            % prevReturn: this is optiona. When it is not empty then one
            % more inequality will be added to the constraints matrix in
            % the 'ESopt.SingleES' case (see comments to the code below)
            
            import Optimizations.*;
            
            if numel(varargin)==1
                invertFlag = varargin{1};
                prevReturn = [];
            elseif numel(varargin)==2
                invertFlag = varargin{1};
                prevReturn = varargin{2};
            end
            
            if invertFlag
               ogjFunSign = -1; 
            else
               ogjFunSign = 1;
            end
            warning off;
            
            % Optimization options
            options = optimoptions(@fmincon,'Algorithm','interior-point','TolFun',1e-6,'TolCon',1e-6, ...
                'MaxFunEvals',100000,'Display','off');
            
            MaxLongShortExposure = MES.params.MaxLongShortExposure; % 2 elements vector: e.g. [2 -3] means that max long and short exposures limits are 200% and 300% respecitvely
            equalWeightsFlag = MES.params.equalWeightsFlag; % if this flag is true no optimization takes place and the output weights are the same as the constrained weights
            NumAssets=size(MES.params.Covariance,2);    % number of active assets in the investment universe
            Covariance = MES.params.Covariance;         % covariance matrix for the active assets in the investment universe
            ExpectedValues = MES.params.ExpectedValues; % these are the expected returns for the active assets in the investment universe
            FirstDegree = zeros(NumAssets,1);
            SecondDegree = Covariance;
            NumPortf = MES.params.NumPortf;
            ESopt = MES.params.ExpectedShortfall_EF_options;
            ConstrainedTotWgts = MES.params.ConstrainedTotWgts;
            MinNetExposure = MES.params.MinNetExposure;
            RSim = MES.params.RSim; % simulated returns at the inv horizon
            prob = MES.params.probabilities; % scenario's posterior probabilities to compute optimal AA 
            RSimFullHist = MES.params.R_sim_hist; % .. on whole dataset (past and future) to compute full dataset ES for the optimal portfolio
            % below the scenarios' probabilities that refers to the whole
            % hist dataset (always equiprobabilities)
            if ~isempty(RSimFullHist) % see DAA_params.ExpectedShortfall_EF_options.onFullHistDataSet in 'initial parameters'
                probFullHist = 1./size(RSimFullHist,1).*ones(size(RSimFullHist,1),1);
            end
            
            % *************************************************************
            % ************ Constraints and intiail values  ****************
            % TODO: implement solutions to manage different solutions for
            % the constraint set in an automated way (e.g. with constraints
            % setup in the params property and managed here)
            % *************************************************************
            % sum of weights constraint (if ConstrainedTotWgts is not
            % empty)
            % *************************************************************
            
            % Adding equality constraints
            if isempty(ConstrainedTotWgts)
                Aeq = [];
                beq = [];
            else
                Aeq=ones(1,NumAssets);
                beq = ConstrainedTotWgts;
            end
            
            % linear equality constraints that might be triggered by
            % quant strategies
            if ~isempty(MES.params.beqFromQviews)
                Aeq = [Aeq;MES.params.AeqFromQviews];
                beq = [beq;MES.params.beqFromQviews];
            end
                
            % Adding inequality constraints
            % ***************************
            %%%% no-short constraint
            %%%%  A=-eye(NumAssets);
            %%%%  b=zeros(NumAssets,1);
            % ***************************
            % constraints to max long or short exposures
            if ~isempty(MaxLongShortExposure)
                A = ones(1,NumAssets).*(-1);
                b = -MaxLongShortExposure(2);
                A = [A; ...
                    ones(1,NumAssets)];
                b = [b;MaxLongShortExposure(1)];
            else
                A = [];
                b = [];
            end
            % constraint to tot net exposure
            if ~isempty(MinNetExposure)
                A = [A;ones(1,NumAssets).*(-1)];
                b = [b;-MinNetExposure];
            end
            
            x0=1/NumAssets*ones(NumAssets,1);
            lb = MES.params.AA_constraints.lb;
            ub = MES.params.AA_constraints.ub;
            
            
            [J,N] = size(RSim); % #scenarios x #assets
            % * dP = (1./J).*ones(J,1);
            % * [RSim_adj] = MES.RN_ChangeOfMeasure(RSim,dP,prob); 
            
            % ***************** End of constraints setup  *****************
            % *************************************************************
            
            % *************************************************************
            % ************** Type of desired Mean-ES requested ************
            % *************************************************************
            single_calc = false(1);
            MES.Exitflag = [NaN];
            % when the choice has been to get to Full Efficient Frontier
            % the block of code within the following IF statement is fully
            % skipped
            if ~(isempty(ESopt.SingleRet) & isempty(ESopt.SingleES) & isempty(ESopt.GMES))
                % a single value only has to be calculated, not the whole
                % frontier
                single_calc = true(1);
                
                % IMPORTANT: at most one of these 3 can be non empty (TODO:
                % enforce checks)
                
                if ~isempty(ESopt.SingleES) % ES given: optimize return
                     % constraints definition
                    x0 = [1/NumAssets*ones(NumAssets,1)];
                    Aeq_flinES = [];
                    beq_flinES = [];
                    A_flinES = [];
                    b_flinES = [];
                    
                                        
                    if ~equalWeightsFlag
                        if ESopt.LinearizedOptimizer % using linearized optimizer: only available for GMES and max ret for a given ES level
                            
                                                        
                            % CONSTRAINTS SETUP (see notes)
                            % compared to the GMES case (the inequalities setup
                            % following this piece of code  is almost identical) I
                            % need to add 1 row to the full matrix A_flinES and
                            % the vector b_flinES that will be created by
                            % assembling all sub-matrices
                            
                            % ************************************************
                            % defining the row to be added compared to the GMES
                            % case
                            % ************************************************
                            Wc_addedRow = zeros(1,N);
                            Uc_addedRow = (prob)'.*(1./(1 - ESopt.ConfLevel));
                            alpha_Uc_addedRow = 1;
                            b_flinES_addedRow = ESopt.SingleES;
                            
                            
                            % *********************************************
                            % Aeq may not be empty due to the flag
                            % ConstrainedTotWgts: in this case it must be
                            % incroporated within the linearized approach
                            % system of equality constraints
                            eqConstraints2beAdded_A = [];
                            eqConstraints2beAdded_b = [];
                            if ~isempty(Aeq)
                                naeq = size(Aeq,1);
                                tmpEq = zeros(naeq,N+J+1);
                                tmpEq(:,1:N) = Aeq;
                                eqConstraints2beAdded_A = tmpEq;
                                eqConstraints2beAdded_b = beq;
                            end
                            
                            % A is not empty due to a constraint (see above)
                            % on the total  exposure
                            % A must be included within the linearized approach
                            % system of inequality constraints
                            ineqConstraints2beAdded_A = [];
                            ineqConstraints2beAdded_b = [];
                            if ~isempty(A)
                                naIneq = size(A,1);
                                tmpInEq = zeros(naIneq,N+J+1);
                                tmpInEq(:,1:N) = A;
                                ineqConstraints2beAdded_A = tmpInEq;
                                ineqConstraints2beAdded_b = b;
                            end
                            % *********************************************
                            
                            
                            % ************************************************
                            % .... from here it is almost the same as in GMES case
                            % but with e different obj function (see
                            % tech doc)
                            % coded ahead
                            % sub-matrices
                            % ATTENTION: below Wc_2, Uc_2 and alpha_c2 are
                            % rescaled by prob compared to the GMES case.
                            % This will not alter the inequality
                            % constraints (simply rescale them), but will
                            % likely defined a more well scaled problem,
                            % since the 'added row' defined above uses u's
                            % weighted by prob.
                            
% %                             Wc_2 = -RSim.*repmat(prob,1,N);
% %                             sprob = size(prob,1);
% %                             % using sparse matrix here because when DAA_params.ProjectionResampling_numsim
% %                             % is large (e.g. 50k or 100k) the Uc_2 would be
% %                             % too big
% %                             Uc_2 = spdiags(-prob.*ones(size(prob,1),1),0,sprob,sprob);
% %                             
% %                             alpha_c2 =  -ones(J,1).*prob; 
                           
                            % **************************
                             Wc_2 =  -RSim; % 
                            sprob = size(prob,1);
                            % using sparse matrix here because when DAA_params.ProjectionResampling_numsim
                            % is large (e.g. 50k or 100k) the Uc_2 would be
                            % too big
                            Uc_2 = spdiags(-1.*ones(size(prob,1),1),0,sprob,sprob);
                            alpha_c2 = -ones(J,1); % -ones(J,1).*prob; % 
                            % **************************
                            
                            
                            % excluding the constraint on the U's (= u's*p's) since
                            % it is implied by the lower bound condition
                            A_flinES = [Wc_2 Uc_2 alpha_c2];
                            b_flinES = zeros(1*J,1);
                            
                            % adding to the constraints matrix the row specific
                            % to this case (compared to the GMES case)
                            % and incorporating (1st element) the
                            % constraints related to the max abs exposure)
                            A_flinES = [ineqConstraints2beAdded_A; A_flinES; [Wc_addedRow Uc_addedRow alpha_Uc_addedRow]];
                            b_flinES = [ineqConstraints2beAdded_b; b_flinES; b_flinES_addedRow];
                            
                            % testing it ....
                            if ~isempty(prevReturn)
                                % logic: here, if 'prevReturn'  is not
                                % empty a new constraint is added. It
                                % imposes that the optimal solution must
                                % have a return above the return
                                % 'prevReturn', that should be a return
                                % corresponding to the previous point (less
                                % risk) on the efficient frontier. This is
                                % a way to force convexity of the efficient
                                % frontier, but its main reason is to try
                                % to reduce (a little bit) the optimization time by
                                % shrinking the feasible region
                                newrow = zeros(1,size(A_flinES,2));
                                newrow(1:N) = -1; % corresponding to the 'weights'
                                A_flinES = [A_flinES;newrow];
                                b_flinES = [b_flinES-10e-8;-prevReturn];
                            end
                            
                            % to include constraints related to the
                            % ConstrainedTotWgts flag 
                            Aeq_flinES = [eqConstraints2beAdded_A];
                            beq_flinES = [eqConstraints2beAdded_b];
                            
                            % the first N items must contain limits to
                            % portfolio's weights, the next J items are limits to the u's,
                            % while the last item is the limit
                            % to 'alpha' (max LOSS)
                            
                            % ATTENTION: enforcing the lb=0 constraint on
                            % alpha depends on the definition of ES that
                            % one wants to implement. e.g. enforcing this
                            % constraint is like using the 'if on prc'
                            % statement in function ES4opt /basically when
                            % VaR is positive, by definition it is set to
                            % zero and the expected shortfall is computed
                            % as the average of values < 0)
                            
                            % lb_flinES = [lb,zeros(1,J),0];
                            % ub_flinES = [ub,ones(1,J).*Inf,Inf];
                            
                            % no constraint on alpha in this version
                            % when  the desired percentile defining VaR is
                            % above zero the ES is computed as the average
                            % of values to the 'left' of this value
                            lb_flinES = [lb,zeros(1,J)];
                            ub_flinES = [ub,ones(1,J).*Inf];
                            
                            % definitions used within the objective function
                            % ***************************
                            u = zeros(1,J);
                            alpha = 0;
                            ExpectedReturn = ExpectedValues'; 
                            % ***************************
                            % here I reduce the function Tolerance to 0.1%,
                            % that is acceptab
                            switch ESopt.LinProgAlgo
                                case 'interior-point'
                                    optionsLinProg = optimoptions(@linprog,'Algorithm','interior-point'); %'ConstraintTolerance',1e-3,'OptimalityTolerance',1e-5,'MaxTime',Inf
                                case 'dual-simplex'
                                    optionsLinProg = optimoptions(@linprog,'Algorithm','dual-simplex','ConstraintTolerance',1e-7,'OptimalityTolerance',1e-6,'MaxTime',Inf);
                            end
                            [optimal_X,fval,exitflag,output,lambda] =  ...
                                linprog(flinES_maxRgiveES,A_flinES,b_flinES,Aeq_flinES,beq_flinES,lb_flinES,ub_flinES,[],optionsLinProg);
                           
                            % to be used  after installing CPLEX
%                             tic
%                             [optimal_X,fval,exitflag,output,lambda] =  ...
%                                 cplexlp(flinES_maxRgiveES,A_flinES,b_flinES,Aeq_flinES,beq_flinES,lb_flinES,ub_flinES,x0);
%                             toc
                            MES.Exitflag = exitflag;
                            if isempty(optimal_X) % it means that the dual-simplex didn't converge to a solution
                                % then return to the invoking code that
                                % manages the exitflag
                                return
                            end
                            
                            SingleESMaxRet_Weights = optimal_X(1:NumAssets);
                            SingleESMaxRet_Returns = SingleESMaxRet_Weights'*ExpectedValues;
                            VaR = optimal_X(end);
                            % to check that the VaR computed within this
                            % function matches 'VaR'
                            % ES4opt(SingleESMaxRet_Weights).*ogjFunSign;
                            
                            % *****************************************************
                        else  % using non linear optimizer
                            % *****************************************************
                            TargetES = ESopt.SingleES;
                            rfun = @(wgts) -(wgts'*ExpectedValues); % obj function (maximize portfolio expected return)
                            SingleESMaxRet_Weights = fmincon(rfun,x0,A,b,Aeq,beq,lb,ub,@ES_constraint,options);
                            SingleESMaxRet_Returns = SingleESMaxRet_Weights'*ExpectedValues;
                        end
                        
                        
                        MES.EF_Composition = SingleESMaxRet_Weights';
                        MES.EF_Risk = ESopt.SingleES; % for check ES4opt(SingleESMaxRet_Weights).*ogjFunSign;
                        MES.EF_Return = SingleESMaxRet_Returns;
                    elseif equalWeightsFlag
                        m = msgbox(['MES_EFrontier: the vector of weighs is given: NOT POSSIBLE TO OPTIMIZE FOR A GIVEN LEVEL OF RISK. Review settings and re-launch'] ...
                            ,'Icon','warn','modal');
                        pause(1.5);
                        close(m);
                        return;
                    end
                    % to calc ES and variance for the optimal portfolio using
                    % the full hist dataset (both past and future at any
                    % given date). Here I use a cycle over the numbher of
                    % subfields of MES.params.FullHistES_AssetsToInlcude
                    % since for now it is possible to define more
                    % subportfolio (MANUALLY in universe.m class)
                    if ~isempty(RSimFullHist)
                        flnames = fieldnames(MES.params.FullHistES_AssetsToInlcude);
                        nf = numel(flnames);
                        for sub=1:nf
                            MES.OtherOutputs.ESonFullHistDataSet.(flnames{nf}) = ...
                                ES4opt_FullHist(SingleESMaxRet_Weights.*MES.params.FullHistES_AssetsToInlcude.(flnames{nf}));
                            MES.OtherOutputs.VarianceonFullHistDataSet.(flnames{nf}) = ...
                                Variance_FullHist(SingleESMaxRet_Weights.*MES.params.FullHistES_AssetsToInlcude.(flnames{nf}));
                        end
                    end
                    
                    return % output is complete: go back to the invoking program
                    
                elseif ~isempty(ESopt.SingleRet) % return given: optimize ES (LINEARIZED APPROACH NOT POSSIBLE HERE)
                    if ~equalWeightsFlag
                        A = [A; ...
                            -ones(1,NumAssets)];
                        b = [b; -ESopt.SingleRet];    % add inequality constraint on target expected return (>= at horizon)
                        SingleRetMinES_Weights = fmincon(@ES4opt,x0,A,b,Aeq,beq,lb,ub,[],options);
                        SingleRetMinES_Returns = SingleRetMinES_Weights'*ExpectedValues;
                        
                        MES.EF_Composition = SingleRetMinES_Weights';
                        MES.EF_Risk = ES4opt(SingleRetMinES_Weights).*ogjFunSign;
                        MES.EF_Return = SingleRetMinES_Returns;
                    elseif equalWeightsFlag
                        m = msgbox(['MES_EFrontier: the vector of weighs is given: NOT POSSIBLE TO OPTIMIZE FOR A GIVEN LEVEL OF RETURN. Review settings and re-launch'] ...
                            ,'Icon','warn','modal');
                        pause(1.5);
                        close(m);
                        return;
                    end
                    return % output is complete: go back to the invoking program
                    
                elseif ~isempty(ESopt.GMES) % *** global min ES portfolio ***
                    
                    [J,N] = size(RSim);
                    % constraints definition
                    x0 = [1/NumAssets*ones(NumAssets,1)];
                    Aeq_flinES = [];
                    beq_flinES = [];
                    A_flinES = [];
                    b_flinES = [];
                    
                    % **  dP = (1./J).*ones(J,1);
                    % **  [RSim_adj] = MES.RN_ChangeOfMeasure(RSim,dP,prob);
                    
                    if ~equalWeightsFlag
                        if ESopt.LinearizedOptimizer % using linearized optimizer: only available for GMES and lowest ES for a given return optimizations
                    
                            
                            % *********************************************
                            % Aeq may not be empty due to the flag
                            % ConstrainedTotWgts: in this case it must be
                            % incroporated within the linearized approach
                            % system of equality constraints
                            eqConstraints2beAdded_A = [];
                            eqConstraints2beAdded_b = [];
                            if ~isempty(Aeq)
                                naeq = size(Aeq,1);
                                tmpEq = zeros(naeq,N+J+1);
                                tmpEq(:,1:N) = Aeq;
                                eqConstraints2beAdded_A = tmpEq;
                                eqConstraints2beAdded_b = beq;
                            end
                            
                            % A is not empty due to a constraint (see above)
                            % on the total absolute exposure
                            % A must be included within the linearized approach
                            % system of inequality constraints
                            ineqConstraints2beAdded_A = [];
                            ineqConstraints2beAdded_b = [];
                            if ~isempty(A)
                                naIneq = size(A,1);
                                tmpInEq = zeros(naIneq,N+J+1);
                                tmpInEq(:,1:N) = A;
                                ineqConstraints2beAdded_A = tmpInEq;
                                ineqConstraints2beAdded_b = b;
                            end
                            % *********************************************
                            
                            % CONSTRAINTS SETUP (see notes)
                            % sub-matrices
                            Wc_2 =  -RSim; % 
                            sprob = size(prob,1);
                            % using sparse matrix here because when DAA_params.ProjectionResampling_numsim
                            % is large (e.g. 50k or 100k) the Uc_2 would be
                            % too big
                            Uc_2 = spdiags(-1.*ones(size(prob,1),1),0,sprob,sprob);
                            alpha_c2 = -ones(J,1); % -ones(J,1).*prob; % 
                            % full constraints matrix
                            % excluding the constraint on the U's (= u's*p's) since
                            % it is implied by the lower bound condition
                            A_flinES = [Wc_2 Uc_2 alpha_c2];
                            b_flinES = zeros(1*J,1)-10e-8;
                            
                            % to include constraints related to the
                            % ConstrainedTotWgts flag and to the total
                            % exposure (see above)
                            A_flinES = [ineqConstraints2beAdded_A;A_flinES];
                            b_flinES = [ineqConstraints2beAdded_b;b_flinES];
                            Aeq_flinES = [eqConstraints2beAdded_A];
                            beq_flinES = [eqConstraints2beAdded_b];
                            
                            % the first N items must contain limits to
                            % portfolio's weights, the next J items are limits to the u's,
                            % while the last item is the limit
                            % to 'alpha' (max LOSS)
                            
                              % ATTENTION: enforcing the lb=0 constraint on
                            % alpha depends on the definition of ES that
                            % one wants to implement. e.g. enforcing this
                            % constraint is like using the 'if on prc'
                            % statement in function ES4opt /basically when
                            % VaR is positive, by definition it is set to
                            % zero and the expected shortfall is computed
                            % as the average of values < 0)
                            
                            % lb_flinES = [lb,zeros(1,J),0];
                            % ub_flinES = [ub,ones(1,J).*Inf,Inf];
                            
                            % no constraint on alpha in this version
                            % when  the desired percentile defining VaR is
                            % above zero the ES is computed as the average
                            % of values to the 'left' of this value
                            lb_flinES = [lb,zeros(1,J)];
                            ub_flinES = [ub,ones(1,J).*Inf];
                            
                            % definitions used within the objective function
                            % ***************************
                            u = ones(1,J); 
                            w = zeros(1,N);
                            alpha = 1;
                            % ***************************
                            switch ESopt.LinProgAlgo
                                case 'interior-point'
                                    optionsLinProg = optimoptions(@linprog,'Algorithm','interior-point'); %'ConstraintTolerance',1e-3,'OptimalityTolerance',1e-5,'MaxTime',Inf
                                case 'dual-simplex'
                                    optionsLinProg = optimoptions(@linprog,'Algorithm','dual-simplex','ConstraintTolerance',1e-5,'OptimalityTolerance',1e-4,'MaxTime',Inf);
                            end
                            
                            tic
                            
                            [optimal_X,fval,exitflag,output,lambda] =  ...
                                linprog(flinES,A_flinES,b_flinES,Aeq_flinES,beq_flinES,lb_flinES,ub_flinES,[],optionsLinProg);
                           
                            % to be used  after installing CPLEX
%                             tic
%                             [optimal_X,fval,exitflag,output,lambda] =  ...
%                                 cplexlp(flinES,A_flinES,b_flinES,Aeq_flinES,beq_flinES,lb_flinES,ub_flinES,x0);
%                             toc
                            
                            MES.Exitflag = exitflag;
                            if isempty(optimal_X) % it means that the dual-simplex didn't converge to a solution
                                % then return to the invoking code that
                                % manages the exitflag
                                return
                            end
                            GMES_Weights = optimal_X(1:NumAssets);
                            GMES_Returns = GMES_Weights'*ExpectedValues;
                            VaR = optimal_X(end);
                           
                            % to check that the VaR computed within this
                            % function matches 'VaR'
                            ES4opt(GMES_Weights).*ogjFunSign; % for check
                            % *****************************************************
                        else % using non linear optimizer
                            % *****************************************************
                            % initial non linear optimization approach
                            [GMES_Weights,fval,exitflag] = fmincon(@ES4opt,x0,A,b,Aeq,beq,lb,ub,[],options);
                            GMES_Returns = GMES_Weights'*ExpectedValues;
                            MES.Exitflag = exitflag;
                            fval = fval.*ogjFunSign; % when using -1 I get the negative of the risk measure
                            % *****************************************************
                        end
                        
                    elseif equalWeightsFlag
                        m = msgbox(['MES_EFrontier: the vector of weighs is given: NOT POSSIBLE TO RUN GMES OPTIMIZATION. Review settings and re-launch'] ...
                            ,'Icon','warn','modal');
                        pause(1.5);
                        close(m);
                        return;
                    end
                    MES.EF_Composition = GMES_Weights';
                    MES.EF_Risk = fval; %ES4opt(GMES_Weights); % using non linear obj function
                    MES.EF_Return = GMES_Returns;
                    
                    % to calc ES and variance for the optimal portfolio using
                    % the full hist dataset (both past and future at any
                    % given date). Here I use a cycle over the numbhewr of
                    % subfields of MES.params.FullHistES_AssetsToInlcude
                    % since for now it is possible to define more
                    % subportfolio (MANUALLY in universe.m class)
                    if ~isempty(RSimFullHist)
                        flnames = fieldnames(MES.params.FullHistES_AssetsToInlcude);
                        nf = numel(flnames);
                        for sub=1:nf
                            MES.OtherOutputs.ESonFullHistDataSet.(flnames{nf}) = ...
                                ES4opt_FullHist(GMES_Weights.*MES.params.FullHistES_AssetsToInlcude.(flnames{nf}));
                            MES.OtherOutputs.VarianceonFullHistDataSet.(flnames{nf}) = ...
                                Variance_FullHist(GMES_Weights.*MES.params.FullHistES_AssetsToInlcude.(flnames{nf}));
                        end
                    end
                    
                end
                
                return % output is complete: go back to the invoking program
            end % if on single point optimization
            % *************************************************************
            % ********* End of single point optimization options    *******
            % *************************************************************
            
            
            % *************************************************************
            % ********  FULL ES EFFICIENT FRONTIER CALCULATION ************
            % *************************************************************
            
            if ~equalWeightsFlag
                if ESopt.LinearizedOptimizer
                    % linear optimization: basically here I derive the Exp Ret - ES
                    % using methods and class developed so far
                    
                    parameters = MES.params; % uses this MES objects parameters
                    % changes the GMES field to perform a GMES optimization using
                    % the MES object created below
                    parameters.ExpectedShortfall_EF_options.SingleES = [];
                    parameters.ExpectedShortfall_EF_options.SingleRet = [];
                    parameters.ExpectedShortfall_EF_options.GMES = [1];
                    
                    MinESpoint = MES_EFrontier(parameters);
                    MinESpoint.Optimization(false(1)); % get the GMES portfolio (the lowest point on the EF)
                    if MinESpoint.Exitflag~=1
                        m = msgbox('GMES optimization for the initial point of the EF is not feasible - Execution terminated' ...
                            ,'Icon','warn','replace');
                        pause(1.5);
                        close(m);
                        return
                    end
                    MinES_Weights = MinESpoint.EF_Composition;
                    MinES_Return = MinESpoint.EF_Return;
                    MinES_Risk = MinESpoint.EF_Risk;
                    
                    % 11.05.2017: GP: identification of max return removed. I
                    % prefer that the highest target return is identified based on
                    % a the max level of risk, given as an input through the parameter
                    % MES.params.ExpectedShortfall_EF_options.MaxRisk4FullES_Frontier. Otherwise, when the
                    % granularity of the efficient frontier is not enough we
                    % could end up having many significant levels of
                    % risk/returns comprised between the min risk portfolio (1-st one) and
                    % the following portfolio (2-nd one), excluded from the
                    % analysis
                    
                    % **** IMPORTANT:
                    % NOTE on linearized optimization when maximizin ES:
                    % the linerized version needs to be reviewd to work
                    % well for maximization (** TODO when possible **)
                    % for now it is set it to 0 when maximizing (then is is
                    % reset to the prev value immediately after the
                    % optimization below)
                    parameters.ExpectedShortfall_EF_options.LinearizedOptimizer = 0;
                    % ****************************************************
                    MaxESpoint = MES_EFrontier(parameters);
                    
                    % *************************
                    MaxESpoint.Optimization(true(1));  % get the portfolio with the highest risk on the EF (note the true(1) used to this purpose)
                    
                    % ***** see NOTE on linearized optimization above
                    % here the 'LinearizedOptimizer' is reset to the
                    % value originally set within the MES options
                    % *************************
                    parameters.ExpectedShortfall_EF_options.LinearizedOptimizer = MES.params.ExpectedShortfall_EF_options.LinearizedOptimizer;
                    if MaxESpoint.Exitflag~=1 & MaxESpoint.Exitflag~=-3  & MaxESpoint.Exitflag~=-5
                        m = msgbox('GMES optimization for the highest point of the EF is not feasible - Execution terminated' ...
                            ,'Icon','warn','replace');
                        pause(1.5);
                        close(m);
                        return
                    elseif MaxESpoint.Exitflag==-5 % sometimes infeasibility of primal and dual seems to arise when the problem is unbounded (look at this in more depth TODO)
                        % the problem is unbounded (very likely outcome)
                        % the highest risk on the EF is set to .MaxRisk4FullES_Frontier
                        
                        m = msgbox(['Primal and Dual problems unfeasible - Max Risk set to ', num2str(MES.params.ExpectedShortfall_EF_options.MaxRisk4FullES_Frontier*100),'%'] ...
                            ,'Icon','warn','replace');
                        pause(1.5);
                        close(m);
                        MaxES_Risk = newMaxRisk;
                        % MaxES_Risk = MES.params.ExpectedShortfall_EF_options.MaxRisk4FullES_Frontier; 
                    elseif MaxESpoint.Exitflag==-3 
                        mxr = MES.params.ExpectedShortfall_EF_options.MaxRisk4FullES_Frontier;
                        if mxr <  MinES_Risk
                            mxr = 2.*MinES_Risk;
                            m = msgbox(['Problem is unbounded - Max Risk set to 2 times the min risk, thaat is: ', num2str(mxr*100),'%'] ...
                                ,'Icon','warn','replace');
                            pause(1.5);
                            close(m);
                        else
                            
                            m = msgbox(['Problem is unbounded - Max Risk set to ', num2str(MES.params.ExpectedShortfall_EF_options.MaxRisk4FullES_Frontier*100),'%'] ...
                                ,'Icon','warn','replace');
                            pause(1.5);
                            close(m);
                        end
                        MaxES_Risk = mxr;
                    else
                        MaxES_Risk = MaxESpoint.EF_Risk;
                    end
                    
                
                    % select the min between the calculated max risk target
                    % and the max isk target set by the user
                    if MES.params.ExpectedShortfall_EF_options.MaxRisk4FullES_Frontier > MinES_Risk
                        % I can set the higher risk level equal to the
                        % user's desired level (see initial parameters)
                        % only if this level is above the min risk ptf
                        MaxES_Risk = min(MaxES_Risk,MES.params.ExpectedShortfall_EF_options.MaxRisk4FullES_Frontier);
                    else
                        msg = ['The max target risk that has been provided (', num2str(MES.params.ExpectedShortfall_EF_options.MaxRisk4FullES_Frontier) ...
                            ,') is less than the Min ES portfolio risk (',num2str(MinES_Risk),') - The max risk on the EF is reset to the highest computed value (' ...
                            ,num2str(MaxES_Risk),')'];
                        m = msgbox(msg,'Icon','warn');
                        pause(1.5);
                        close(m);
                    end
                    
                    % if, after the step above, MaxES_Risk is still <
                    % MinES_Risk, there must be  something wrong
                    if MaxES_Risk < MinES_Risk
                        msg = ['The max risk target used is less than the Min ES portfolio risk (',num2str(MaxES_Risk),') - There is something not working properly (Press a key)'];
                        m = msgbox(msg,'Icon','warn');
                        pause(1.5);
                        close(m);
                        MES.Exitflag = 888; % used when the no optim occurred since max target ret was less then min risk return
                        return
                    end
                    
                    % slice efficient frontier in NumPortf equally thick horizontal
                    % sectors in the upper branch only
                    Step = (MaxES_Risk-MinES_Risk)/(NumPortf-1);
                    EF_ES_targets = [MinES_Risk : Step : MaxES_Risk];
                    NumTotPortfolios = size(EF_ES_targets,2);
                    
                    % lowest point of the EF
                    PortfolioComposition = zeros(NumTotPortfolios,size(MinES_Weights,2));
                    PortfolioES = zeros(1,NumTotPortfolios);
                    PortfolioExpectedValue = zeros(1,NumTotPortfolios);
                    
                    PortfolioComposition(1,:) =  MinES_Weights;
                    PortfolioES(1) = MinES_Risk;
                    PortfolioExpectedValue(1) = MinES_Return;
                    EF_exitflags = MinESpoint.Exitflag;
                    
                    tic
                    disp(['Running ',num2str(NumTotPortfolios),' optimizations to get the current Efficient Frontier']);
                    
                    
                    
                    % **parfor k=2:NumTotPortfolios
                    for k=2:NumTotPortfolios   
                        % for each target Risk (ES) level on the EF maximize the
                        % return and get the corresponding weights
                        parameters = MES.params; % uses this MES objects parameters
                        parameters.ExpectedShortfall_EF_options.SingleES = [];
                        parameters.ExpectedShortfall_EF_options.SingleRet = [];
                        parameters.ExpectedShortfall_EF_options.GMES = [];
                        parameters.ExpectedShortfall_EF_options.SingleES = EF_ES_targets(k);
                        MinESpoint = MES_EFrontier(parameters);
                        % MinESpoint.Optimization(false(1),PortfolioExpectedValue(k-1)); % get the portfolio with the highest return given the risk target = EF_ES_targets(k);
                        MinESpoint.Optimization(false(1));
                        % ** MinESpoint.Optimization(false(1),PortfolioExpectedValue(k-1)); % get the portfolio with the highest return given the risk target = EF_ES_targets(k);
                        
                        EF_exitflags = [EF_exitflags,MinESpoint.Exitflag];
                        if MinESpoint.Exitflag~=1
                            % m = msgbox('A single optimization on a point of the EF is not feasible: point removed NaN' ...
                            %    ,'Icon','warn','replace');
                            disp('A single optimization on a point of the EF is not feasible: point removed NaN');
                            PortfolioComposition(k,:) = NaN*ones(1,size(MinES_Weights,2)); %[PortfolioComposition;NaN*ones(1,size(PortfolioComposition,2))];
                            PortfolioES(k) = NaN; % [PortfolioES,NaN];
                            PortfolioExpectedValue(k) = NaN*1; % [PortfolioExpectedValue,NaN];
                            continue
                        end
                        PortfolioComposition(k,:) = MinESpoint.EF_Composition; % [PortfolioComposition;MinESpoint.EF_Composition];
                        PortfolioES(k) = MinESpoint.EF_Risk; % [PortfolioES,MinESpoint.EF_Risk];
                        PortfolioExpectedValue(k) = MinESpoint.EF_Return; % [PortfolioExpectedValue,MinESpoint.EF_Return];
                    end
                    toc
                    
                    % shut down current pool
                    currentPool = gcp;
                    delete(currentPool);

                    % excluding the point on the EF with zero risk (if
                    % any). It rarely happens, but when I have it I want to
                    % exclude it
                    if MinES_Risk == 0 & size(PortfolioComposition,1)>1
                        PortfolioComposition (1,:) = PortfolioComposition(2,:);
                        PortfolioES(1) = PortfolioES(2);
                        PortfolioExpectedValue(1) = PortfolioExpectedValue(2);
                    end

                    
                    % *************************************************************
                else % non linear optim used (practically dismissed)
                    % *************************************************************
                    
                    % Get min ES and max return portfolios
                    [MinES_Weights,fval,exitflag] = fmincon(@ES4opt,x0,A,b,Aeq,beq,lb,ub,[],options);
                    MinES_Return = MinES_Weights'*ExpectedValues;
                    MaxRet_Weights = linprog(-ExpectedValues,A,b,Aeq,beq,lb,ub);
                    MaxTargetRet = MaxRet_Weights'*ExpectedValues;
                    
                    % slice efficient frontier in NumPortf equally thick horizontal
                    % sectors in the upper branch only
                    Step = (MaxTargetRet-MinES_Return)/(NumPortf-1);
                    TargetReturns = [MinES_Return : Step : MaxTargetRet];
                    NumTotPortfolios = size(TargetReturns,2);
                    
                    % *************************************************************
                    % *****  MES Efficient Frontier constrained optimization ******
                    
                    disp(['Slicing the Efficient Frontier into ',num2str(NumPortf),' portfolios']);
                    NumPortf_completed = false(1);
                    
                    while ~NumPortf_completed
                        PortfolioComposition = MinES_Weights';
                        PortfolioES = ES4opt(MinES_Weights);
                        PortfolioExpectedValue = MinES_Weights'*ExpectedValues;
                        EF_exitflags = 1; % check the previous optim to see if it is 1
                        
                        for i=2:NumPortf %-1
                            % disp(['Point on the eff frontier no ',num2str(i)]);
                            % to constrain sum of weights to be 1
                            % determine least risky portfolio for given expected return
                            
                            AEq=[Aeq;
                                ExpectedValues'];
                            bEq=[beq
                                TargetReturns(i)];
                        
                            tic
                            [Weights,~,exitflag] = fmincon(@ES4opt,x0,A,b,AEq,bEq,lb,ub,[],options);
                            toc
                            
                            if exitflag  < 0 % no convergence
                                continue;
                            end
                            
                            Weights = Weights';
                            PortfolioComposition = [PortfolioComposition; Weights];
                            eES = ES4opt(Weights');
                            PortfolioES = [PortfolioES eES];
                            PortfolioExpectedValue = [PortfolioExpectedValue ...
                                Weights*ExpectedValues];
                            EF_exitflags = [EF_exitflags,exitflag];
                            NumPortf_completed = true(1);
                            
                        end % for on no of portfolios along the EF
                        
                    end % NumPortf_completed flag
                    
                end % if on  ESopt.LinearizedOptimizer
                
            elseif equalWeightsFlag
                % optimization has not run since the vector of weights was
                % given. Riks and Return figures are claulated based on this
                % fixed vector of weights
                PortfolioComposition = lb;
                PortfolioExpectedValue = lb*ExpectedValues;
                PortfolioES = ES4opt(lb');
                EF_exitflags = 999; % used when no optimization occurred because of fixed weights for all of the assets
            end
            % *************************************************************
            warning on;
            MES.EF_Return = PortfolioExpectedValue;
            MES.EF_Risk = PortfolioES;
            MES.EF_Composition = PortfolioComposition;
            MES.Exitflag = EF_exitflags;
            % *************************************************************
            % ********  END OF  FULL EFFICIENT FRONTIER CALCULATION *******
            % *************************************************************
            
            % *************************************************************
            % Nested functions used with optimizations above
            function es = ES4opt(w)
                port_ret = RSim*w;
                [port_ret_s,oidx] = sort(port_ret); % sort in asdcending order
                prob_s = prob(oidx); % associate corresponding probabilities
                F = cumsum(prob_s);
                q = find(F<=(1-ESopt.ConfLevel)); % TODO: make this more precise
                q = q(end);
                prc = port_ret_s(q); % this is VaR
                if prc > 0; prc = 0; end % -->> in this way ES will average realizations below zero
                es = - mean(port_ret(port_ret<=prc));
                es = max(es,0).*ogjFunSign;
                
            end
            
            % temp for full hist ES********************
            function es_FullHist = ES4opt_FullHist(w)
                % this is like ES4opt, but computes the optimal portfolio's
                % ES using the whole hist dataset 
                port_ret = RSimFullHist*w;
                [port_ret_s,oidx] = sort(port_ret); % sort in asdcending order
                prob_s = probFullHist(oidx); % associate corresponding probabilities (alway equiprob for full hist)
                F = cumsum(prob_s);
                q = find(F<=(1-ESopt.ConfLevel)); % TODO: make this more precise
                q = q(end);
                prc = port_ret_s(q);
                if prc > 0; prc = 0; end % -->> in this way ES will average realizations below zero
                es_FullHist = - mean(port_ret(port_ret<=prc));
                es_FullHist = max(es_FullHist,0);
            end
            
            function variance_FullHist = Variance_FullHist(w)
                % this is like ES4opt, but computes the optimal portfolio's
                % ES using the whole hist dataset 
                port_ret = RSimFullHist*w;
                variance_FullHist = var(port_ret);
                
            end
            % **********************************************
            
            function [c,ceq] = ES_constraint(w)
                port_ret = RSim*w;
                [port_ret_s,oidx] = sort(port_ret); % sort in asdcending order
                prob_s = prob(oidx); % associate corresponding probabilities
                F = cumsum(prob_s);
                q = find(F<=(1-ESopt.ConfLevel)); % TODO: make more precise
                q = q(end);
                prc = port_ret_s(q);
                if prc > 0; prc = 0; end % -->> in this way ES will average realizations below zero
                es = max(0,-mean(port_ret(port_ret<prc)));
                % +/- 10% allowed range around the target ES level
                c = [es - TargetES.*1.10; ... % TODO: PARAMETRIZE
                    -es + TargetES.*0.90];
                ceq = [];
                % ceq = max(es,0) - TargetES;
            end
            
            % **********************************************************
            
            function VaR = V(w)
                port_ret = RSim*w;
                [port_ret_s,oidx] = sort(port_ret); % sort in asdcending order
                prob_s = prob(oidx); % associate corresponding probabilities
                F = cumsum(prob_s);
                q = find(F<=(1-ESopt.ConfLevel)); % TODO: make more precise
                q = q(end);
                prc = port_ret_s(q);
                VaR = max(0,-prc);
            end
                    
            function f = flinES %(x)
                f = [w prob'.*(1./((1 - ESopt.ConfLevel))).*u alpha].*ogjFunSign;
            end
            
            function f = flinES_maxRgiveES
                f = [-ExpectedReturn u alpha].*ogjFunSign; 
            end
            % **********************************
            
            % *************************************************************
            
        end % Optimization
        
    end % Public methods
    
    methods (Static)
        
        function [OutDistrib] = RN_ChangeOfMeasure(InDistrib,dP,dQ) % ** NOT USED **
            disp('RN change of measure');
            % InDistrib: input distribution(s): dim [JxN]: J scenarios by N
            % assets. The probability vectors dP and dQ must have dim [Jx1]
            % (probabilities associated to each joint scenario)
            % dP: old probability measure
            % dQ: new probability measure
            
            [J,N] = size(InDistrib);
            RN = dQ./dP; % RADON NYKODIN DERIVATIVE
            diag_RN = spdiags(RN,0,J,J); % to get the result below in one shot
            OutDistrib = diag_RN*InDistrib; % to multiply each row (scenario) by the corresponding probability
            
        end
        
    end
    
end
