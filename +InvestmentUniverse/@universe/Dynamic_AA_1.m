function Dynamic_AA_1(U,DAA_params,SubjectiveViews) %******************************
            % this method implements a specific Dynamic AA model.
            % The idea is to create several Dynamic_AA_n methods for
            % different possible dynamic AA processes.
            
            % ************************************************************
            % Dynamic_AA_1: entropy pooling based, with posterior derived
            % thorough Entropy minmization  blending quant/subj  views
            % manmaed by classes QuantViews and SubjectiveViews
            % ************************************************************
            
            % INPUT:
            % DAA_params struct array with many fields driving the dynamic
            % asset allocation process (see comments in Main() AA_DashBoard.m:
            
            % I) LOOP ON t WITHIN THE TIME WINDOW OF INTEREST (ideally
            % this time window should encompass all the backtesting window
            % up to the current time to get current AA)
            
            % TODO: this is a first simple implementation for testing
            % purposes: refine through views on copulas may be using MCA
            % (e.g. implementing CMAseparation_test and
            % CMAcombination_test)
            
            import Optimizations.*;
            import ViewsGen.*;
         
            % **********************  SUBJECTIVE VIEWS ********************
            SUBJECTIVE_VIEW_ACTIVE = DAA_params.SubjectiveViews; % flag for subj views
            SubjViewsLabel = [];       % description of the views
            AllSingleAssetsViews = []; % detailed description of the views
            
            if SUBJECTIVE_VIEW_ACTIVE
               
                SubjViews = SubjectiveViews.SubjViews;
                AllSingleAssetsViews = SubjectiveViews.AllViewsLabel;
                SubjViewsLabel = SubjectiveViews.Label;
                NumberOfSubjects = SubjectiveViews.NumberOfSubjects;
                
                if isempty(SubjectiveViews.SubjectiveViewsWeight)
                    ConfInSubjViews = DAA_params.SubjectiveViewsWeight;
                    % assuming equal confidence levels : if it is not so the
                    % levels associated with the views must be manually
                    % setup in SubjectiveViews.m class
                    ConfInSubjViews = ConfInSubjViews.*ones(1,SubjectiveViews.NumberOfSubjects)./SubjectiveViews.NumberOfSubjects;
                else
                    % only if a set of differentiated weights has been
                    % setup manually in obj SubjectiveViews
                    ConfInSubjViews = SubjectiveViews.SubjectiveViewsWeight;
                end
            else
                ConfInSubjViews = [];
            end
            % ***************************************************************
            
            U.Strategies.Dynamic_AA_1 = [];
            U.Strategies.Dynamic_AA_1.DAA_params = DAA_params; % saving AA's parameters
            U.Strategies.Dynamic_AA_1.Budget = DAA_params.Budget; % this is the total wealth to be allocated (tot abs portfolio Notional when running Scenario Analysis)
            U.Strategies.Dynamic_AA_1.Horizon = DAA_params.Horizon;
            HorizonDays = DAA_params.HorizonDays;
            U.Strategies.Dynamic_AA_1.HorizonDays = HorizonDays;
            % prealloc of some debugging matrices
            U.Debug.HistAndSimProjectionComparison.Dates = [];
            U.Debug.HistAndSimProjectionComparison.Times = [];
            U.Debug.HistAndSimProjectionComparison.Historical.ProjMu = [];
            U.Debug.HistAndSimProjectionComparison.Historical.ProjStd = [];
            U.Debug.HistAndSimProjectionComparison.Historical.ProjKurt = [];
            U.Debug.HistAndSimProjectionComparison.Simulated.ProjMu = [];
            U.Debug.HistAndSimProjectionComparison.Simulated.ProjStd = [];
            U.Debug.HistAndSimProjectionComparison.Simulated.ProjKurt = [];
            
            BackTestOnly = DAA_params.BackTestOnly;
            Horizon = DAA_params.Horizon;
            NumPortf = DAA_params.NumPortf;
            FullHist4TailsEstimation = DAA_params.FullHist4TailsEstimation;
            min_interval_changes = DAA_params.min_interval_changes;
            Budget = DAA_params.Budget;
            NAssets = size(U.Assets,1);
            N = size(U.AllInvariants.X,2); % mkt dimension (or no of risk factors)
            NInvariants = size(U.AllInvariants.X,2); % redundant
            L = size(U.AllInvariants.X,1);
            H_dates_vector = U.AllInvariants.Dates;
            U.Strategies.Dynamic_AA_1.H_dates_vector = H_dates_vector;
            Mu_View = [];
            Sigma_View = [];
            
            % the following IF statement changes the initial 'backtest'
            % date to the latest available historical date when the
            % riskAnalysisFlag flag is set to true: when I am running
            % scenario analsys (e.g. model portfolio or SA) I do not want
            % to backtest over the historical backtest, but simply evaluate
            % the posterior as of the most recent date.
            if DAA_params.riskAnalysisFlag
                
                % if reach a date later than the last available date a
                % warning msg is issued and execution is terminated
                if datenum(DAA_params.StartDay)~=U.AllInvariants.Dates(end,1)
                    m = msgbox(['StartDay (',DAA_params.StartDay,' will be changed to the latest available date for joint invariants (', ...
                        datestr(U.AllInvariants.Dates(end,1)),'), since the Scenario Analysis flag is ON'] ...
                        ,'Icon','warn');
                    % waitfor(m);
                    pause(2);
                    close(m);
                    DAA_params.StartDay = datestr(U.AllInvariants.Dates(end,1));
                end
            end
            
            startday_n = datenum(DAA_params.StartDay);
            
            ProbThreshold4MC = DAA_params.ProbThreshold4MC;
            
            % subset of parameters needed for tails and copula modeling
            if DAA_params.copula_rho == 1
                % if 1 use the corr estimated with
                % copulafit for inversion, otherwise
                % use the original correlation matrix
                corr_X = [];
            end
            evt_params.nsim = DAA_params.copula_NoSim;;
            evt_params.corr_X = corr_X;
            evt_params.ProbThreshold4MC = ProbThreshold4MC;
            evt_params.FullHist4TailsEstimation = FullHist4TailsEstimation;
            evt_params.calibrateTails  = DAA_params.calibrateTails;
            evt_params.ConstantTailsThreshold  = DAA_params.ConstantTailsThreshold;
            evt_params.CentralValuesModel = DAA_params.CentralValuesModel;
            evt_params.MCsimLimSetting = DAA_params.MCsimLimSetting;
            evt_params.MinTailSize = DAA_params.MinTailSize;
            evt_params.useTcopula =DAA_params.useTcopula;
            
            Current_Prices = zeros(L,NAssets);
            Current_Prices4BackTest = zeros(L,NAssets);
            % ***********************  QUANT VIEWS  ***********************
            if DAA_params.QuantSignals
                % parameters needed to obj of class QuantViews to manage algo &
                % quant views
                Qviews_params.StrategyName = DAA_params.QuantStrategyName;
                Qviews_params.HorizonDays = HorizonDays;
                Qviews_params.StrategyName = DAA_params.QuantStrategyName;
                Qviews_params.InvariantsNamesSet = U.AllInvariants.NamesSet;
                
                % switch based on the desired quant strategy
                switch Qviews_params.StrategyName
                    case 'Signal_Gen_1'
                        drivers_no = size(U.Drivers.Signal_Gen_1,2);
                        Qviews_params.Drivers.Signal_Gen_1 = U.Drivers.Signal_Gen_1; % main output field from class ViewsGen.QuantSignals.m (Signal_Gen_1)
                        Qviews_params.drivers_no = drivers_no;
                        
                    case 'EG_Coint'
                        Qviews_params.Drivers.EG_Coint = U.Drivers.EG_Coint; % main output field from class ViewsGen.QuantSignals.m (EG_Coint)
                        
                    case 'CointPower'
                        disp('CointPower case in universe.Dynamic_AA_1.m')
                        Qviews_params.Drivers = U.Drivers.CointPower;  % main output field from class ViewsGen.QuantSignals.m (CointPower)
                        
                    case 'PairCointegration'
                        disp('PairCointegration case in universe.Dynamic_AA_1.m')
                        Qviews_params.Drivers = U.Drivers.PairCointegration;  % main output field from class ViewsGen.QuantSignals.m (CointPower)
                end
                % instantiating QuantViews class to manage quant-based views
                % (algo generated only fr now)
                Qviews_params.confInViews = DAA_params.QViewsWeight;
                Qviews = QuantViews(Qviews_params);
            end
            % *************************************************************
            
            AA_Optim_tracker = [];
            fd = find(U.AllInvariants.Dates(:,1) == startday_n);
            cn = 0;
            
            % precondition: there must be an initial lookback of at least
            % the max between the initial lookback (# days) and the moving window
            % (# days, if used) length
            precondition = (fd - max(DAA_params.Priori_IntialLookback,DAA_params.Priori_MovWin) > 0);
            
            while isempty(fd) | ~precondition
                
                if cn==0
                    disp('Initial window start non existent or the 1st intervaL is too small');
                    disp('Using the first useful date');
                end
                if startday_n<U.AllInvariants.Dates(end,1) % if startday is earlier than the latest available date
                    startday_n = startday_n + 1; % move forward
                else                                       % if startday is past the latest available date
                    startday_n = startday_n - 1; % move backward
                end
                
                fd = find(U.AllInvariants.Dates(:,1) == startday_n);
                if ~isempty(fd)
                    precondition = (fd - max(DAA_params.Priori_IntialLookback,DAA_params.Priori_MovWin) > 0);
                end
                cn = cn + 1;
                if startday_n > U.AllInvariants.Dates(end)
                    % if reach a date later than the last available date a
                    % warning msg is issued and execution is terminated
                    m = msgbox(['Check the date of backtest start and the Min LookBack Window. Probably there is not enough data to have a min backtest of   ', num2str(DAA_params.Priori_IntialLookback), 'days or the start date for the backtest is past the latest available date for invariants'] ...
                        , 'Error','error');
                    waitfor(m);
                    return
                end
            end
            
            DAA_params.StartDay = datestr(startday_n);
            StartingTime = fd;
            
            % for each day in the hist window (from the first investment
            % decision to the most recent date, ideally today)
            % ** preallocations **
            Allocation_changes_EP = zeros(L,1);
            active_assets_change = zeros(L,1);
            hist_scenarios_start = 1;
            ExitFlags = zeros(L,DAA_params.NumPortf);
            OtherOutputs = cell(L,1);
            FullFrontier_flag = true(1);
            ProjectedReturns = cell(L,1); % to store the matrices of simulated projected returns at the investment horizon
            ProbabilityVector_Prior = cell(L,1); % to store the vectors of prior probabilities associated to each simulated proj scenario
            ProbabilityVector_Posterior = cell(L,1); % to store the vectors of posterior probabilities associated to each simulated proj scenario
            HorizonRiskMeasures = cell(L,1);
            
            % This practically means: if I am running
            % a single point optimization (NOT a FULL
            % FRONTIER set of optimizations)
            if (DAA_params.ExpectedShortfall_EF == 1 && ~(isempty(DAA_params.ExpectedShortfall_EF_options.SingleRet) & isempty(DAA_params.ExpectedShortfall_EF_options.SingleES) ...
                    & isempty(DAA_params.ExpectedShortfall_EF_options.GMES))) | DAA_params.RiskBudgeting == 1
                FullFrontier_flag = false(1);
                ExitFlags = zeros(L,1);
                NumPortf = 1;
            end
            % needed for ES calc on full dataset (in future it will be
            % useful for regulatory purposes - not strictly needed now)
            X_fullDataSet = U.AllInvariants.X;
            
            
           
            % ************************************************************
            % ********* cycling over hist horizon for Dynamic AA *********
            % ************************************************************
            
            first = 0; %1; % ALWAYS = 0; can be manually set to 1 if one wants to optimize using the whole hist dataset (both PAST and FUTURE)
            t=0;
            if first == 0
                t = StartingTime-1;
            end
            counterAE = 1; % for debug data storing 
            while t<L
                
                % constraints: these params can be modified during
                % repricing (e.g. because a single asset is no more or has
                % entered the investable universe or because of quantsignals feedbacks through checkSignals - see below -)
                AA_constraints = DAA_params.AA_constraints;
                Horizon = U.Strategies.Dynamic_AA_1.Horizon;
                HorizonDays = U.Strategies.Dynamic_AA_1.HorizonDays;
                % pre-assign linear equality constraints to the AA optim
                % from quant views (if any). These equality
                % constraints could be re-assigned by  a quant view
                % generator
                AeqFromQviews = [];
                beqFromQviews = [];
                
                ConfInQuantViews = []; % conf in quant views reset to empty at each t
                ConfInPrior = DAA_params.PriorWeight; % confidence in prior distrib (basically conf in It (historical info))
                
                % pre-assign linear equality constraints to the AA optim
                % from quant views (if any)
                AeqFromQviews = [];
                beqFromQviews = [];
                
                Mu_View = [];
                Sigma_View = [];
                TypeofView = [];
                
                if first == 1
                    % the first time the eff frontier calc is run over the
                    % whole hist horizon, using prior distrib only. The
                    % purpose is to be able to normalize all subsequent
                    % efficient frontiers based on the dimension of the
                    % whole initial EF (not used for now) - TODO:
                    % parametrize this choice
                    % **  t = L; % no more used
                    
                    % *** DO NOTHING ***
                    
                elseif first ==0
                    t = t + 1;
                end
                
                if DAA_params.Priori_MovWin == 0 % use all available past history
                    startPrior = 1; %StartingTime-DAA_params.Priori_IntialLookback;
                else
                    startPrior = t-DAA_params.Priori_MovWin;
                end
                
                % X_fullHistory is needed because when applying quant
                % signals they might be based on the whole history up to time t
                usingArmagarch = false(1);
                if DAA_params.ARMAGARCH ~= 1 || (DAA_params.ARMAGARCH == 1 & t< DAA_params.chunksLength) % Do not Use ARMA - GARCH
                    X = U.AllInvariants.X(startPrior:t,:);
                    X_hist = U.AllInvariants.X(startPrior:t,:); % the same as X when not using ARIMA modeling (X_hist needed to feed the Debug struct)
                else
                    X = U.ARMA_GARCH_filtering.std_residuals(startPrior:t,:); % ARMA_GARCH Modeling switch
                    X_hist = U.AllInvariants.X(startPrior:t,:);
                    % corresponding original dataset (remember that
                    % in AR-GARCH context returns are expressed as
                    % percentages)
                    X_raw = U.AllInvariants.X(startPrior:t,:); % needed to update drift terms for both AR and GARCH/GJR model
                    usingArmagarch = true(1);
                end
                
                X_fullHistory = U.AllInvariants.X(1:t,:);
                
                % defining X4HVaR used to compute 1-day Historical and
                % Parametric VaR/ES
                if DAA_params.HVaRWindow == 0
                    X4HVaR = U.AllInvariants.X;
                else
                    if DAA_params.HVaRWindow > size(U.AllInvariants.X,1)
                        m = msgbox(['Length of the window used for HVaR and Parametric VaR computations (',DAA_params.HVaRWindow,') changed to max possible size'] ...                   ,'] ...
                            ,'Icon','warn');
                        pause(1.5);
                        close(m);
                        X4HVaR = U.AllInvariants.X;
                    else
                        X4HVaR = U.AllInvariants.X(end-DAA_params.HVaRWindow+1:end,:); % TODO: check for the length of X, given HVaRWindow
                    end
                    
                end
                
                current_t_date = H_dates_vector(t);
                HorizonDate = daysadd(current_t_date,HorizonDays,13);
                
                disp(['Active AA Dynamic_AA_1, date: ',datestr(current_t_date)]);
                
% %                 % constraints: these params can be modified during
% %                 % repricing (e.g. because a single asset is no more or has
% %                 % entered the investable universe)
% %                 AA_constraints = DAA_params.AA_constraints;
                % ************** Assets mkt prices as of t ****************
                % Recovering historical mkt prices for each date (needed
                % below to express AA in terms of prices and quantities and to calc
                % projected returns/cov over the investment horizon)
                % when there are no mkt prices they are implied (e.g. for
                % options they are calculated based on the historical
                % values of the underlying risk factors, while for ZCB they
                % are implied from zero YTMs)
                [Current_Prices(t,:),Current_Prices4BackTest(t,:)] = Asset_HPrices(U,current_t_date);
                P0 = Current_Prices(t,:)';
                
                % updating ActiveAssets matrix, saying which assets (columns) are
                % active (=1) or not (=0) on each date (rows)
                % AND Multipliers matrix (same dimension as ActiveAssets),
                % that at each time t contains the multiplier for the
                % corresponding asset, necessary to transform prices into
                % notional amounts
                
                Active_Assets(t,:) = ones(1,NAssets);
                Multipliers(t,:) = zeros(1,NAssets);
                for na=1:NAssets
                    fldlst = fieldnames(U.Assets(na).value);
                    
                    mc = metaclass(U.Assets(na).value);
                    objtype = mc.Name;
                    
                    if (~isempty(U.Assets(na).value.Enter_Universe_date) && current_t_date<datenum(U.Assets(na).value.Enter_Universe_date)) ... not yet in the Universe
                            | ((~isempty(U.Assets(na).value.AA_limits.lb) &  ~isempty(U.Assets(na).value.AA_limits.ub)) && AA_constraints.lb(na)==0 &  AA_constraints.ub(na)==0 ) ... %U.Assets(na).value.AA_limits.lb == 0 & U.Assets(na).value.AA_limits.ub == 0) ... % has zero weight
                            | (strcmp(objtype,'bond_ZCB') && ~isempty(U.Assets(na).value.MaturityDate) && current_t_date > datenum(U.Assets(na).value.MaturityDate)) ... % it is a bond and it is expired
                            | (strcmp(objtype,'irs') && ~isempty(U.Assets(na).value.FixedMaturity) && current_t_date > datenum(U.Assets(na).value.FixedMaturity)) ... % it is an irs and it is expired
                            | (strcmp(objtype,'Option_Vanilla') && ~isempty(U.Assets(na).value.ExpiryDate) && current_t_date > datenum(U.Assets(na).value.ExpiryDate))
                        Active_Assets(t,na) = 0; % this can be modified later by quant signals
                    end
                    
                    % retrieving the multiplier
                    Multipliers(t,na) =  U.Assets(na).value.Multiplier;
                end
                
                % the notional of a single unit (for bonds it is 1 unit of
                % the currency in which it is denominated)
                UnitNotional_0(t,:) = (P0'.*Multipliers(t,:));
                % converting non EUR denominated unit notionals into euros
                exchdir = 'FXEUR';
                UnitNotional_0_EUR(t,:) = U.ConvertFX(UnitNotional_0(t,:),U.Currencies,U.ExchangeRates.fts,current_t_date,exchdir);
                
                active_assets_change(t,1) = 0;
                if t>1
                    if  ~((Active_Assets(t,:) == Active_Assets(t-1,:)))
                        active_assets_change(t,1) = 1; % to trigger an AA recalc
                    end
                end
                % *********************************************************
                CHANGE = false(1);
                QUANT_VIEW_ACTIVE = false(1);
                % ************************************************
                % calc time from previous AA change
                fp = find(Allocation_changes_EP(1:t-1) == 1);
                
                if isempty(fp);
                    fp = 1;
                else
                    fp = fp(end);
                end
                t_elapsed = t - fp;
                if t_elapsed > DAA_params.MinFreqOfPriorUpdate
                    % to update the prior at least every
                    % DAA_params.MinFreqOfPriorUpdate unit of time (for now
                    % days only)
                    CHANGE = true(1); % flag indicating change due to max elapsed time
                end
                % ************************************************
                
                % ********************************************************
                % ********************************************************
                % CONDITIONING THROUGH VIEWS (SIMPLIFIED APPROACH)
                %             BASED ON QUANT SIGNALS
                % ********************************************************
                % ********************************************************
                
                if DAA_params.QuantSignals & ~BackTestOnly
                    
                    if DAA_params.PriorWeight<1
                        % cycles over all View_Change vectors (one for each driver)
                        % when a view change for any given driver occurs (View(k).View_Change(t) == 1)
                        % then the vector of expected returns and the COV matrix ov
                        % INVARIANTS are updated based on the info in .settings
                        % (generated by the method Algoviews)
                        % If at least one change occurs then the CHANGE flag is set
                        % equal to 1.
                        
                        % Here I need to identify which are the invariants affected
                        % by signals from the drivers. The relation is identified
                        % based on the names of both invariants (in U.AllInvariants.NamesSet)
                        % and drivers (Prior_perturbations(2).Name and Prior_perturbations(2).Und_Name), obtained from
                        % the tickers using a common rule
                        
                                               
                        if first == 0 & t_elapsed > min_interval_changes % t_elapsed > min distance between consecutive views
                            % if this is not the first exec (when the whole
                            % hist only EF is calculated)  and the time
                            % elapsed from the latest optimization is
                            % enough to allow a new optimization
                            optionalParam.upperWgtsLimits = AA_constraints.ub;
                            optionalParam.lowerWgtsLimits = AA_constraints.lb;
                            optionalParam.IU_tickers = U.Assets_Tickers ;
                            optionalParam.nassets = size(U.Assets_Tickers,1);
                            checkSignal = Qviews.CheckSignalAtGivenTime(t,current_t_date,X_fullHistory,HorizonDays,optionalParam);
                            
                            % to feedback the checkSignal struct to
                            % QuantViews at the next iteration: used when
                            % the 'persist' parameter for the specific
                            % strategy (see QuantViews.m) is set to true
                            optionalParam.prevCheckSignal = checkSignal;
                            
                            % assign back the weights limits (some trading
                            % strategy implemented thorugh QuantSignals are
                            % not impacted)
                            
                            AA_constraints.ub = checkSignal.upperWgtsLimits;
                            AA_constraints.lb = checkSignal.lowerWgtsLimits;
                            HorizonDays = checkSignal.HorizonDays;
                            Horizon = checkSignal.HorizonDays./252;
                            HorizonDate = daysadd(current_t_date,HorizonDays,13);
                            disp(['Horizon date modified by dynamic quant signals into: ',datestr(HorizonDate)]);
                            
                            Active_Assets(t,checkSignal.activatedAssets) = 1;
                            % linear equality constraints to the AA optim
                            % from quant views (if any)
                            nqEq = numel(checkSignal.equalityConstraintsFromQuantStratRHS{:});
                            for neq=1:nqEq
                                AeqFromQviews = [AeqFromQviews;checkSignal.equalityConstraintsFromQuantStratLHS{neq}];
                                beqFromQviews = [beqFromQviews;checkSignal.equalityConstraintsFromQuantStratRHS{neq}];
                            end
                            if nqEq>0
                                AeqFromQviews(:,find(~Active_Assets(t,:)))=[];
                            end
                            
                            QUANT_VIEW_ACTIVE_vector = checkSignal.CHANGEQ;
                            % if there is at least one quant signal QUANT_VIEW_ACTIVE
                            % booleans is set to True
                            QUANT_VIEW_ACTIVE = numel(find(QUANT_VIEW_ACTIVE_vector)) > 0;
                            
                            if checkSignal.OPTIM
                                CHANGE = true(1);
                            end

                        end
                    end % if PriorWeight < 1
                    
                    % if at least one signals occurs then the
                    % ConfInQuantViews vector must be created (one element
                    % for each subject). If no specific confidence levels have
                    % been set up in Qviews.ConfInQuantViews then the views
                    % are assigned equal probabilities
                    
                    if QUANT_VIEW_ACTIVE
                        % if views are expressed in terms of expected
                        % invariants characteristics AT HORIZON, then Mu_View
                        % and Sigma_View must be rescaled to the new inv
                        % horizon
                        
                        if isempty(Qviews.ConfInQuantViews)
                            ConfInQuantViews = DAA_params.QViewsWeight;
                            % assuming equal confidence levels : if it is not so the
                            % levels associated with the views must be manually
                            % setup in QuantViews.m class
                            ConfInQuantViews = ConfInQuantViews.*ones(1,Qviews.NumberOfSubjects  )./Qviews.NumberOfSubjects;
                        else
                            % only if a set of differentiated weights has been
                            % setup manually in obj SubjectiveViews
                            ConfInQuantViews = Qviews.ConfInQuantViews;
                        end
                        
                    end % QUANT_VIEW_ACTIVE = True
                    
                end % quantsignals flag
                % ********************************************************
                % ********************************************************
                % END OF CONDITIONING THROUGH VIEWS (SIMPLIFIED APPROACH)
                % ************** BASED ON QUANT SIGNALS ******************
                % ********************************************************
                % ********************************************************
                
                % ****************** MANUAL VIEWS ************************
                %  TO BE IMPLEMENTED BASED ON REAL LIFE 'MODUS OPERANDI'
                % ********************************************************
                
                % when SUBJECTIVE_VIEW_ACTIVE is True (there are subjective views) they
                % are implemented (if below) when the t-elapsed time
                % triggers it or when the quant view triggers it
                if ((QUANT_VIEW_ACTIVE & t_elapsed > min_interval_changes) ... % a Q signal and met condition on min time elapsed
                        | t == StartingTime ...  %  at the time of the first investment decision
                        | active_assets_change(t,1) == 1) | first == 1 | CHANGE % when the inv universe changes or at the first iteration (on full history) or when a CHANGE is triggered by elapsed time
                    
                    % ***** COPULA SIMULATIONS AND TAIL MODELING MGMT *****
                    if DAA_params.copula_sim == 1 & ~BackTestOnly
                        nowAE = tic
                        % Dataset used for multivariate distribution
                        % modeling and simulation / projection purposes
                        if DAA_params.UseAutoEncoder == false
                            DataSet4Modeling = X;
                        else
                            % AEparams.HiddenSize = 60;
                            % AEparams.EncoderTransferFunction = 'logsig';
                            % AEparams.DecoderTransferFunction = 'purelin';
                            % AEparams.L2WeightRegularization = 0.000;
                            % AEparams.SparsityRegularization = 0.5;
                            % AEparams.SparsityProportion = 0.05;
                            % AEparams.MaxEpoch = 2500;
                            % AEparams.ScaleData = true;
                            AEparams = DAA_params.AEparams;
                            
                            TrainigSet = X';
                            
                            AutoEncoder = AE_DimReductor(TrainigSet, AEparams);
                            AutoEncoder.Encode(TrainigSet);
                            DataSet4Modeling = AutoEncoder.CodedSet';
                        end
                            % *********************************************************
                        % modelling invariants based on a semiparametric approach
                        % (Gaussian kernel in the middle and Pareto distrib for the tails)
                        % to draw copula based simulations
                        mu_X = nanmean(DataSet4Modeling);
                        mu_X_fullHistory = nanmean(X_fullHistory);
                        
                        % ** NOT USED
                        if DAA_params.use_rank_corr == 1
                            corr_X = corr(DataSet4Modeling,'type','kendall');
                            cov_X = corr2cov(std(DataSet4Modeling),corr_X);
                        elseif DAA_params.use_rank_corr == 0
                            cov_X = cov(DataSet4Modeling);
                            [~,corr_X] = cov2corr(cov_X);
                        end
                        
                        evt_params.toBeCentered = false(1); % TODO: parametrize (with the remaining evt_params parameters)
                        
%                         if ~usingArmagarch
                            X_centered = bsxfun(@minus, DataSet4Modeling, mu_X);
%                         elseif usingArmagarch
%                             % centered already in this case
%                             X_centered = DataSet4Modeling;
%                         end
                        
                        X_centered_fullHistory = bsxfun(@minus, X_fullHistory, mu_X_fullHistory);
                        
                        % modeling co-dependence structure and marginals
                        % distributions tails cutoffs
                        EVT =  EVT_CopulaSim(X_centered,X_centered_fullHistory,evt_params);
                        EVT.FitCopulaAndSimulate;
                        
                        X_simulated = EVT.Simulated_X;

                        
%                         if ~usingArmagarch
                            X_simulated = bsxfun(@plus, X_simulated, mu_X); % new simulated 'X'
%                         elseif usingArmagarch
%                            % don't need to add back the mean (see IF statement above) 
%                         end
                        % ***************
                        
                        debug_OUT.EVT = EVT.OUT;
                        
                        %                         for corrdim = 1:size(X_centered,2)
                        %                             Y(Y >= DAA_params.simbound *max(X_centered(:,corrdim))) = DAA_params.simbound * max(X_centered(:,corrdim));
                        %                             Y(Y <= DAA_params.simbound *min(X_centered(:,corrdim))) = DAA_params.simbound * min(X_centered(:,corrdim));
                        %                         end
                        
                        % if FullHist4TailsEstimation
                        % X = bsxfun(@plus, Y, mu_X_fullHistory); % new simulated 'X'
                        % else
                        % end
                        
                        % ***** CODE TO MONITORING TAILS CODEPENDENCE *****
                        
                        qt_L = 0.05; % quantile 'left'
                        qt_U = 0.95; % quantile 'right'
                        
                        below = @(DD,q) bsxfun(@lt,DD,prctile(DD,q*100));
                        above = @(DD,q) bsxfun(@gt,DD,prctile(DD,q*100));
                        
                        HistBelow = below(DataSet4Modeling,qt_L);
                        HistAbove = above(DataSet4Modeling,qt_U);
                        
                        p_x1 = @(M,nv1) numel( find(M(:,nv1)==1) ) ./ size(M,1);
                        p_x1x2 = @(M,nv1,nv2) numel( find(M(:,nv1)==1 &  M(:,nv2)==1) ) ./ size(M,1);
                        
                        % p1 = p_x1(eBelow,1);
                        % p12 = p_x1x2(eBelow,1,2);
                        
                        % Tails dependence - Historical data
                        N = size(DataSet4Modeling,2);
                        clear HistLD HistUD;
                        for k=1:N
                            for h=k+1:N
                                lowerDep = p_x1x2(HistBelow,k,h)./p_x1(HistBelow,h);
                                lowerDep(isnan(lowerDep)) = 0;
                                HistLD(k,h) = lowerDep;
                                
                                upperDep = p_x1x2(HistAbove,k,h)./p_x1(HistAbove,h);
                                upperDep(isnan(upperDep)) = 0;
                                HistUD(k,h) = upperDep;
                            end
                        end
                        
                        SimBelow = below(X_simulated,qt_L);
                        SimAbove = above(X_simulated,qt_U);
                        
                        p_x1 = @(M,nv1) numel( find(M(:,nv1)==1) ) ./ size(M,1);
                        p_x1x2 = @(M,nv1,nv2) numel( find(M(:,nv1)==1 &  M(:,nv2)==1) ) ./ size(M,1);
                        
                        % p1 = p_x1(eBelow,1);
                        % p12 = p_x1x2(eBelow,1,2);
                        
                        % Tails dependence - Historical data
                        N = size(X_simulated,2);
                        clear SimLD SimUD;
                        for k=1:N
                            for h=k+1:N
                                lowerDep = p_x1x2(SimBelow,k,h)./p_x1(SimBelow,h);
                                lowerDep(isnan(lowerDep)) = 0;
                                SimLD(k,h) = lowerDep;
                                
                                upperDep = p_x1x2(SimAbove,k,h)./p_x1(SimAbove,h);
                                upperDep(isnan(upperDep)) = 0;
                                SimUD(k,h) = upperDep;
                            end
                        end
                        DiffLD = HistLD-SimLD;
                        DiffUD = HistUD-SimUD;
                        
                        debug_OUT.TAILS = {HistLD HistUD SimLD SimUD DiffLD DiffUD};
                        
                        if DAA_params.UseAutoEncoder == true
                            AutoEncoder.Decode(X_simulated');
                            X_simulated = AutoEncoder.SimulatedSet';
                        end
                        
                        runningtime = toc(nowAE)
                        
                        if DAA_params.UseAutoEncoder == true
                            U.Debug.AE.WITH.X_simulated{counterAE} = X_simulated;
                            U.Debug.AE.WITH.runningtime{counterAE} = runningtime;
                        else
                            U.Debug.AE.WITHOUT.X_simulated{counterAE} = X_simulated;
                            U.Debug.AE.WITHOUT.runningtime{counterAE} = runningtime;
                        end
                        
                        % ***** END OF TAILS CODEPENDENNCE MONITORING *****
                        
                        % -------------------------------------------------
                        % ----------------  ARMA - GARCH  -----------------
                        if ~usingArmagarch
                            
                            % Do not Use ARMA - GARCH *********************
                            
                        elseif usingArmagarch  % Use filtering.
                            
                            disp('Reproducing estimated AR GARCH features');
                            [Tl,nI] = size(X_raw);
                            
                            % *************************************************************
                            % Using moving rolling window to compute unconditional metrics
                            meanUncond = zeros(Tl,nI);
                            varianceUncond = zeros(Tl,nI);
                            winLength = DAA_params.Priori_MovWin; % ARMAGARCH_movWin
                            if winLength+1 > Tl | winLength==0
                                % to deal with the following case: I am
                                % using a rolling window (DAA_params.Priori_MovWin>0 )for AA and this
                                % rolling window is shorter than
                                % DAA_params.Priori_MovWin OR I am using an expanding 
                                % window (from to); in this case MU
                                % and VAR are computed using the whole
                                % rolling window
                                m_tmp = mean(X_raw);
                                v_tmp = var(X_raw);
                                meanUncond = repmat(m_tmp,Tl,1);
                                varianceUncond = repmat(v_tmp,Tl,1);
                            else
                                for tt = winLength+1:Tl
                                    meanUncond(tt,:) = mean(X_raw(tt-winLength:tt,:));
                                    varianceUncond(tt,:) = var(X_raw(tt-winLength:tt,:));
                                end
                            end
                          
                            % *************************************************************
                            % Here is the implementation of the arma-garch
                            % refiltering 
                            [n1,n2] = size(X_simulated);
                            
                            Simulatedreturns = zeros(DAA_params.ProjectionResampling_numsim,n2,HorizonDays);
                            
                            % doing the same job made by
                            % universe.ResampleInvariants
                            % TODO: use ResampleInvariants rather than
                            % repeating the code
                            % ********************************************
                            extracted_occurrences = unidrnd(n1, HorizonDays, DAA_params.ProjectionResampling_numsim);
                            Y_all = zeros(DAA_params.ProjectionResampling_numsim,size(X_simulated,2),HorizonDays);
                            for count_t=1:HorizonDays
                                Y_all(:,:,count_t) = X_simulated(extracted_occurrences(count_t,:)',:);
                            end
                            % ********************************************
                            
                            % Switch parameter models depending on time
                            % ** partition_j =  ( ceil(t / DAA_params.chunksLength)); % select the effective chunk: then the model estimated on chunk-1 will be used to re-construct AR-GARCH features
                            
                            for refilter_i = 1 : n2
                                
                                tmpMap = U.ARMA_GARCH_filtering.MapDatesToChunks{refilter_i};
                                frow = find(tmpMap(:,1)<current_t_date & tmpMap(:,2)>=current_t_date);
                                partition_j = tmpMap(frow,3);
                                
                                % selecting std residuals, returns and cond
                                % variances as of t-1 (seeds for the 'filter' method  used below)
                                Y0 = (U.ARMA_GARCH_filtering.returns(t-2:t-1,refilter_i));
                                Z0 = (U.ARMA_GARCH_filtering.std_residuals(t-2:t-1,refilter_i));
                                V0 = (U.ARMA_GARCH_filtering.variances(t-2:t-1,refilter_i));
                                
                                unconditionalVariance = varianceUncond(t-startPrior+1,refilter_i); % assume that long term uncond variance is this (to calc cond variance drift)
                                unconditionalStd = unconditionalVariance.^0.5;
                                uncondMu = meanUncond(t-startPrior+1,refilter_i);
                                % Constant = U.ARMA_GARCH_filtering.constant(t,refilter_i);
                                
                                if partition_j > 1
                                    
                                    modelObjName = ['Fitting_' U.AllInvariants.NamesSet{refilter_i} '_partition_' num2str(partition_j-1)]; % name of the field of SUMMARY_OUT to be searched
                                    modelObjName = strrep(modelObjName,'/','_'); % to deal with names like BP/_LN_Equity
                                    
                                    objUsed = U.ARMA_GARCH_filtering.SUMMARY_OUT.(modelObjName);
                                    savedModel = objUsed.fit; 
                                    
                                    if strcmp(objUsed.model,'arima')
                                        
                                        mcv = metaclass(savedModel.Variance); % variance model metaclass
                                        if strcmp(mcv.Name,'garch') | strcmp(mcv.Name,'gjr') | strcmp(mcv.Name,'egarch') % EGARCH NOT USED FOR NOW
                                            alpha = ArmaGarch.getalpha(savedModel.Variance);
                                            beta = ArmaGarch.getbeta(savedModel.Variance);
                                        end
                        
                                        if strcmp(mcv.Name,'garch')
                                            varianceModelConstant = unconditionalVariance.*(1-alpha-beta);
                                            savedModel.Variance.Constant = varianceModelConstant; % variance 'drift'
                                        elseif strcmp(mcv.Name,'gjr')
                                            leverage = ArmaGarch.getleverage(savedModel.Variance);
                                            varianceModelConstant = unconditionalVariance.*(1-alpha-beta-0.5.*leverage);
                                            savedModel.Variance.Constant = varianceModelConstant; % variance 'drift'
                                        elseif strcmp(mcv.Name,'egarch') % ** NOT USED FOR NOW
                                            varianceModelConstant = log(unconditionalVariance).*(1-alpha-beta-0.5.*leverage);
                                        else
                                            savedModel.Variance = unconditionalVariance;
                                        end
                                        
                                        savedModel.Constant = uncondMu.*(1-savedModel.AR{1});
                                        
                                        % savedModel.Constant = Constant;
                                        % REFILTER ALONG TIME DIMENSION
                                        [simret,~,~] = savedModel.filter(squeeze(Y_all(:,refilter_i,:))', ...
                                            'Y0',Y0,'Z0',Z0,'V0',V0);
                                        Simulatedreturns(:,refilter_i,:) = simret';
                                        
                                    elseif strcmp(objUsed.model,'garch') ...
                                            | strcmp(objUsed.model,'gjr') | strcmp(objUsed.model,'egarch')
                                        mc = metaclass(savedModel);
                                        alpha = ArmaGarch.getalpha(savedModel);
                                        beta = ArmaGarch.getbeta(savedModel);
                        
                                        if strcmp(mc.Name,'garch')
                                            varianceModelConstant = unconditionalVariance.*(1-alpha-beta);
                                        elseif strcmp(mc.Name,'gjr')
                                            leverage = ArmaGarch.getleverage(savedModel);
                                            varianceModelConstant = unconditionalVariance.*(1-alpha-beta-0.5.*leverage);
                                        elseif strcmp(mc.Name,'egarch') % ** NOT USED FOR NOW
                                            varianceModelConstant = log(unconditionalVariance).*(1-alpha-beta-0.5.*leverage);
                                        end
                                        % change the model properties to
                                        % reflect the features of the
                                        % current time dataset
                                        savedModel.Constant = varianceModelConstant; % variance 'drift'
                                        savedModel.Offset = uncondMu; % ************************************
                                        
                                        % REFILTER ALONG TIME DIMENSION
                                        [~,simret] = savedModel.filter(squeeze(Y_all(:,refilter_i,:))','Z0',Z0,'V0',V0);
                                        Simulatedreturns(:,refilter_i,:) = simret';
                                        
                                    elseif strcmp(objUsed.model,'none')
                                        Simulatedreturns(:,refilter_i,:) = (squeeze(Y_all(:,refilter_i,:)).*unconditionalStd) + uncondMu;
                                    end
                                    
                                else % 1-st chunk only
                                    Simulatedreturns(:,refilter_i,:) =  (Y_all(:,refilter_i,:).*unconditionalStd) + uncondMu;
                                end % if partition_j
                                
                            end % loop on refilter_i
                            
                            Simulatedreturns = Simulatedreturns;
                            
                            X_Resampled = Simulatedreturns;
                            
                            % X_Projected is now the 'final' invariants matrix used for asset allocation optimizations
                            X_Projected = sum(X_Resampled ,3); % Refiltered
                            
                        end
                        %------------------------------------------------
                        
                    end % if on copula_sim flag (COPULA SIMULATIONS AND TAIL MODELING MGMT)
                    
                    
                    if ~BackTestOnly
                        % *****************************************************
                        %  SIMULATION AND PROJECTION TO THE INVESTMENT HORIZON
                        % if DAA_params.ViewsBeforeProjection is false then
                        % simulations and projections to horizon are performed
                        % before running Entropy Pooling, otherwise this step
                        % is ignored and will be performed after EP
                        % NOW ALWAYS FALSE: ViewsBeforeProjection flag removed
                        % basically here I get a new X that represents the
                        % expected distribution of the invariants at the
                        % investment horizon, with the related new
                        % equal-prob vector p. This [X,p] will be used for
                        % Entropy Pooling
                        
                        if usingArmagarch
                            % omit:  WE DO NOT PROJECT AS THE PROJECTION IS DONE EARLIER USING ARMA GARCH.
                        elseif ~usingArmagarch
                            [X_Resampled] = ...
                                U.ResampleInvariants(X_simulated,DAA_params.ProjectionResampling_numsim,HorizonDays,'bootstrap');
                            X_Projected = sum(X_Resampled,3);
                        end
                        
                        J = size(X_Projected,1); % no of joint historical scenarios
                        p = ones(J,1)/J; % probability of each joint scenario
                        % *****************************************************
                        
                        if first == 1
                            p_= p; % only hist info (prior) is used
                        end
                        
                        if first==0
                            Allocation_changes_EP(t) = 1;
                        end
                    end
                    
                    if DAA_params.UseAutoEncoder == true
                        U.Debug.AE.WITH.X_Projected{counterAE} = X_Projected;
                    else
                        U.Debug.AE.WITHOUT.X_Projected{counterAE} = X_Projected;
                    end
                    counterAE = counterAE+1; % for debug storing purposes
                    % *****************************************************
                    % adding information related to historical projected
                    % and simulated projected invariants at the investment
                    % horizon to the Debug structure
                    % (time along columns, invariants on the rows)
                    U.Debug.HistAndSimProjectionComparison.Dates = [U.Debug.HistAndSimProjectionComparison.Dates;current_t_date];
                    U.Debug.HistAndSimProjectionComparison.Times = [U.Debug.HistAndSimProjectionComparison.Times;t];
                    % projected risk/return metrics from historical data
                    U.Debug.HistAndSimProjectionComparison.Historical.ProjMu = [U.Debug.HistAndSimProjectionComparison.Historical.ProjMu,(mean(X_hist).*HorizonDays)'];
                    U.Debug.HistAndSimProjectionComparison.Historical.ProjStd = [U.Debug.HistAndSimProjectionComparison.Historical.ProjStd,(std(X_hist).*HorizonDays.^0.5)'];
                    U.Debug.HistAndSimProjectionComparison.Historical.ProjKurt = [U.Debug.HistAndSimProjectionComparison.Historical.ProjKurt,(kurtosis(X_hist).*HorizonDays.^0.25)'];
                    % projected risk/return metrics from simulated data
                    % (they have been projected already, so there is no
                    % multip by time)
                    U.Debug.HistAndSimProjectionComparison.Simulated.ProjMu = [U.Debug.HistAndSimProjectionComparison.Simulated.ProjMu,(mean(X_Projected))'];
                    U.Debug.HistAndSimProjectionComparison.Simulated.ProjStd = [U.Debug.HistAndSimProjectionComparison.Simulated.ProjStd,(std(X_Projected))'];
                    U.Debug.HistAndSimProjectionComparison.Simulated.ProjKurt = [U.Debug.HistAndSimProjectionComparison.Simulated.ProjKurt,(kurtosis(X_Projected))'];
                    
                    % checking (and warning) about any projected simulated
                    % metric that is more than 2 times the corresponding
                    % proj data from hist data
                    % * U.Debug.HistAndSimProjectionComparison.Simulated.ProjMu(:,end)./U.Debug.HistAndSimProjectionComparison.Historical.ProjMu;
                    
                    % *****************************************************
                    
                    % *****************************************************
                    % ****************** ENTROPY POOLING  *****************
                    % implementing EP to derive the posterior distribution
                    % based on the exp values vector and COV matrix updated
                    % above based on the signal
                    
                    PriorProb = p;
                    p_ = p; % pre-assignment (it won't be changed unless there are views to process)
                    
                    % TODO: IMPORTANT: for now only the 1st 2 moments are
                    % considered. EXTEND THIS TO TAKE INTO ACCOUNT ALL
                    % CROSS MOMENTS
                    % *****************************************************
                    % *****************************************************
                    if ~BackTestOnly & (first == 0 & t >= StartingTime) & ... % must not be the first execution (only made to have the eff frontier on full hist distrib (PRIOR) not used for investment decisions)
                            (CHANGE | SUBJECTIVE_VIEW_ACTIVE | QUANT_VIEW_ACTIVE)
                        
                        
                        % *************************************************
                        %            SUBJ VIEWS IMPLEMENTATION
                        % *************************************************
                        Subj_no = 0;
                        if SUBJECTIVE_VIEW_ACTIVE % if there are subjective views
                            fnames = fieldnames(SubjViews);
                            NumberOfSubjects = numel(fnames);
                            RiskFactors_no = size(U.AllInvariants.NamesSet,1);
                            % preallocating matrix of views on exp returns
                            Mu_View = zeros(NumberOfSubjects,RiskFactors_no).*NaN; % 1 row for each subject expressing any view on Mu
                            Mu_ViewSign = cell(NumberOfSubjects,RiskFactors_no); % corresponding vectors for the sign ('<','>' or '=') of the view
                            
                            % preallocating matrix of views on correlations
                            Corr_View = cell(NumberOfSubjects,1); % where each cell will contain a correlation matrix
                            Sigma_View = cell(NumberOfSubjects,1); % where each cell will contain a covariance matrix
                            Sigma_ViewSign = cell(NumberOfSubjects,1); % ... and corresponding sign ('<','>' or '=') of the view on cov
                            NamesSet = U.AllInvariants.NamesSet;
                            
                            % READING SUBJECTIVE VIEWS ON EXPECTED RETURNS
                            % AND EXPECTED CORRELATIONS
                            for Subj_no=1:NumberOfSubjects % loopung over all subjects
                                if isfield(SubjViews.(fnames{Subj_no}),'Mu') % if the subject expressed a view on Mu
                                    for View_no=1:size(SubjViews.(fnames{Subj_no}).Mu,1)
                                        
                                        ViewRF = strrep(SubjViews.(fnames{Subj_no}).Mu{View_no,1},' ','_'); % ticker
                                        frf = ismember(NamesSet,ViewRF);
                                        fn = find(frf);
                                        if ~isempty(fn)
                                            Mu_View(Subj_no,fn) = SubjViews.(fnames{Subj_no}).Mu{View_no,2};
                                            Mu_ViewSign{Subj_no,fn} = SubjViews.(fnames{Subj_no}).Mu{View_no,3};
                                        else
                                            hh = msgbox('One or more of the invariants (in ViewRF) used to express views cannot be found in the set of invariants: THESE VIEWS WILL HAVE NO EFFECT ', 'Error','error');
                                            waitfor(hh);
                                        end
                                    end % View_no
                                end
                                
                                if isfield(SubjViews.(fnames{Subj_no}),'Corr') % if the subject expressed a view on Corr
                                    % preallocating correlation matrix for the
                                    % specific subject
                                    Corr_View{Subj_no,1} = zeros(RiskFactors_no,RiskFactors_no).*NaN;
                                    Sigma_View{Subj_no,1} = zeros(RiskFactors_no,RiskFactors_no).*NaN;
                                    Sigma_ViewSign{Subj_no,1} = cell(RiskFactors_no,RiskFactors_no);
                                    COVX = cov(U.AllInvariants.X);
                                    
                                    for View_no=1:size(SubjViews.(fnames{Subj_no}).Corr,1)
                                        ViewRF_1 = strrep(SubjViews.(fnames{Subj_no}).Corr{View_no,1},' ','_'); % ticker 1
                                        ViewRF_2 = strrep(SubjViews.(fnames{Subj_no}).Corr{View_no,2},' ','_'); % ticker 2
                                        % look for their positions
                                        % 1st ticker
                                        frf1 = ismember(NamesSet,ViewRF_1);
                                        fn1 = find(frf1);
                                        % 2nd ticker
                                        frf2 = ismember(NamesSet,ViewRF_2);
                                        fn2 = find(frf2);
                                        
                                        if ~isempty(fn1) & ~isempty(fn2)
                                            Corr_View{Subj_no,1}(fn1,fn2) = SubjViews.(fnames{Subj_no}).Corr{View_no,3};
                                            % transform into covariance
                                            ExpSigma(1) = COVX(fn1,fn1); % needed to transform corr into cov
                                            ExpSigma(2) = COVX(fn2,fn2); %    "    "     "       "    "   "
                                            ExpCorrC = eye(2);
                                            ExpCorrC(1,2) = Corr_View{Subj_no,1}(fn1,fn2);
                                            ExpCorrC(2,1) = ExpCorrC(1,2);
                                            ExpCovariance = corr2cov(ExpSigma, ExpCorrC);
                                            Sigma_View{Subj_no,1}(fn1,fn2) = ExpCovariance(1,2);
                                            Sigma_ViewSign{Subj_no,1}{fn1,fn2} = SubjViews.(fnames{Subj_no}).Corr{View_no,4};
                                            % fill up the symmetric
                                            % elements (to avoid problems
                                            % where this is transformed
                                            % into equqlities/inequalities)
                                            Sigma_View{Subj_no,1}(fn2,fn1) = ExpCovariance(1,2);
                                            Sigma_ViewSign{Subj_no,1}{fn2,fn1} = SubjViews.(fnames{Subj_no}).Corr{View_no,4};
                                        else
                                            hh = msgbox('One or more of the invariants (in ViewRF) used to express views cannot be found in the set of invariants: THESE VIEWS WILL HAVE NO EFFECT ', 'Error','error');
                                            waitfor(hh);
                                        end
                                    end
                                end
                                % vector the same length as the no of
                                % subjects expressing views indicating the
                                % type of the view (quant based or
                                % subjective)
                                TypeofView{Subj_no,1} = ['S'];
                                
                            end % Subj_no
                            
                            
                        end % SUBJECTIVE_VIEW_ACTIVE (boolean)
                        % *************************************************
                        %           END OF SUBJ VIEWS IMPLEMENTATION
                        % *************************************************
                        
                        % *************************************************
                        %            QUANT VIEWS IMPLEMENTATION
                        % *************************************************
                        % ... appending quant views (if any)
                        
                        AllViews_no = Subj_no; % tot no of subjects expressing views (both subjective and algo/quant
                        UsedConfInQuantViews = [];
                        
                        if QUANT_VIEW_ACTIVE
                            clear Mu_View Mu_ViewSign Sigma_View Sigma_ViewSign Ranking_Views Ranking_ViewsSign UsedConfInQuantViews;
                            fnames = fieldnames(Qviews.QViews);
                            NumberOfQ_Subjects = numel(fnames); % no of quant views
                            % cycling over quant views
                            qactive_cnt = 0;
                            for Q_no=1:NumberOfQ_Subjects
                                
                                
                                if QUANT_VIEW_ACTIVE_vector(Q_no) % if the specific view is active
                                    AllViews_no = AllViews_no + 1;
                                    qactive_cnt = qactive_cnt + 1;
                                    % here the Mu_View and Sigma_View
                                    % fields due to quant views are
                                    % assigned and a corresponding vector
                                    % UsedConfInQuantViews is created: only
                                    % if the k-th quant view is active
                                    % (that is QUANT_VIEW_ACTIVE_vector(k) ==1) the
                                    % corresponding weight is used,
                                    % otherwise its weight is assigned to
                                    % the prior
                                    TypeofView{AllViews_no,1} = ['Q'];
                                    Mu_View(AllViews_no,:) = Qviews.QViews.(fnames{Q_no,1}).Mu;
                                    Mu_ViewSign(AllViews_no,:) = Qviews.QViews.(fnames{Q_no,1}).MuSign;
                                    Sigma_View{AllViews_no,1} = Qviews.QViews.(fnames{Q_no,1}).Sigma;
                                    Sigma_ViewSign{AllViews_no,1} = Qviews.QViews.(fnames{Q_no,1}).SigmaSign;
                                    
                                    % there are strategies that can express
                                    % views in terms of rankimgs
                                    if ~isempty(Qviews.QViews.(fnames{Q_no,1}).RankingViews)
                                        rankingViewsFlag = true(1);
                                        Ranking_Views(AllViews_no,:) = Qviews.QViews.(fnames{Q_no,1}).RankingViews;
                                        Ranking_ViewsSign{AllViews_no,1} = Qviews.QViews.(fnames{Q_no,1}).RankingViewsSign;
                                    else
                                        rankingViewsFlag = false(1);
                                    end
                                    UsedConfInQuantViews(qactive_cnt) = ConfInQuantViews(Q_no);
                                else
                                    ConfInPrior = ConfInPrior + ConfInQuantViews(Q_no);
                                end
                            end % Q_no
                        else
                            UsedConfInQuantViews = [];
                            % ** UsedConfInQuantViews = 0;
                        end % if on QUANT_VIEW_ACTIVE
                        
                        % *************************************************
                        %        END OF  QUANT VIEWS IMPLEMENTATION
                        % *************************************************
                        
                        % ***** setting up EP's constraints  *****
                        % EP optimization algorithm parameters
                        algorithm_1 = ['trust-region']; % ['trust-region']; % 'quasi-newton'
                        algorithm_2 = ['interior-point']; %['trust-region-reflective']; % 'interior-point'
                        gradobj = ['on'];
                        hessian = ['on'];
                        mxiter = 3000; % 2000;
                        tfun = 10e-6;  %0.00001; % 0.0001;
                        tstep = 10e-6;
                        
                        % *************************************************
                        % *******   CONSTRAINTS SETUP
                        % *************************************************
                        clear p_v;
                        for n=1:AllViews_no
                            % for each view (subjective or quant based)
                            % define the p_ probability vector needed to
                            % 'perturb the prior p
                            views.mu = Mu_View(n,:);
                            views.muSign = Mu_ViewSign(n,:); % signs of the views on projected return
                            views.sigma = Sigma_View{n};
                            views.sigmaSign = Sigma_ViewSign{n}; % signs of the views on projected cov
                            views.J = J;
                            
                            % for each new subject clean up the system of
                            % eq/inequalities
                            A = [];
                            b = [];
                            Aeq = [];
                            beq = [];
                            
                            if strcmp(TypeofView{n,1},'Q')
                                [Aeq,beq,A,b] = U.SubJViews2Constraints(X_Projected,views,Aeq,beq,A,b);
                                % adding views expressed as rankings (on  returns), if any
                                % note: there are 2 ways to implement 'no
                                % ranking views' (it depends on how the
                                % correspndiung field is managed within the
                                % QuantViews class). We can have the
                                % 'Ranking_Views' vector made of zeros only
                                % or we can have an empty 'Ranking_ViewsSign{n}'
                                if rankingViewsFlag % if there are ranking views
                                    if strcmp(Ranking_ViewsSign{n},'<')
                                        RankedViews = (X_Projected*Ranking_Views(n,:)')';
                                    elseif strcmp(Ranking_ViewsSign{n},'>')
                                        RankedViews = (-X_Projected*Ranking_Views(n,:)')';
                                    end
                                    A = [A;RankedViews];
                                    b = [b;0];
                                end
                                
                            elseif strcmp(TypeofView{n,1},'S')
                                [Aeq,beq,A,b] = U.SubJViews2Constraints(X_Projected,views,Aeq,beq,A,b);
                            end
                            
                            disp('Entropy Minimization started');
                            tic
                            p(p==0) = 0.00001;
                            dd = Inf;
                            nz = Inf;
                            
                            % here the no of equality/ineq contstarints is
                            % halved at each step when convergence
                            % is NOT achieved. The no of equalities/ineq cannot be
                            % reduced by more than one half (maxCut_relative).
                            NEqconstraints = size(Aeq,1) + size(A,1);
                            redSteps = 0;
                            maxCut_relative = 0.50; % TODO: PARAMETRIZE
                            cuttingIteration = 0;
                            
                            while abs(dd)>0.10 | nz > size(p_single_subj,1)*0.50 % TODO: parametrize this levels
                                
                                try
                                    [p_single_subj,fU,fC] = U.EntropyOptim(p,A,b,Aeq,beq,mxiter,algorithm_1,algorithm_2,tfun,tstep,gradobj,hessian); % ...compute posterior probabilities
                                catch ME
                                    if strcmp(ME.identifier,'optimlib:trdog:NaNInStep')
                                        disp('Entropy Min not feasible due to NaNs in Trust Region Steps');
                                        p_single_subj = p; % no change
                                        break
                                    else
                                        disp('check ME (Universe.Dynamic_AA_1: EntropyOptim)');
                                        pause;
                                    end
                                end
                                
                                if size(Aeq,1)==1 & isempty(A) % Aeq and A caannot be reduced further
                                    break;
                                end
                                
                                % counting the number of occurrences where
                                % probability does not change between
                                % consecutive scenarios: this may happen
                                % when a very big weight is assigned to a
                                % siungler scenario and a flat probability
                                % is assigned to all or almost all the
                                % remmaining ones. If this is the case I
                                % want to reduce the constraints and rerun
                                % entropy min (see below)
                                d_p_single_subj = diff(p_single_subj);
                                fz = find(d_p_single_subj==0);
                                nz = numel(fz);
                                
                                dd = 1-sum(p_single_subj);
                                relativeCut = 0.20; % relative size of constraints reduction. TODO: PARAMETRIZE
                                
                                % if the sum of tot prob exceeds 1 by more
                                % than 0.10 of the no of flat probabilities
                                % (see above) exceeds 50% of scenarios
                                % number then reduce constraints and rerun
                                
                                % TODO: the checks and actions
                                % implemented here can be moved and managed
                                % within the optimizatioin process: REVIEW
                                % WHEN POSSIBLE
                                
                                if abs(dd)>0.10 | nz > size(p_single_subj,1)*0.50
                                    if cuttingIteration>5 % max 5 attempts (TODO: parametrize)
                                        break
                                    end
                                    
                                    % disp('Entropy Min Not achieved: reducing equality or inequality constraints and retrying ...');
                                    disp('Entropy Min Not achieved: reducing constraints magnitude and retrying ...');
                                    cuttingIteration = cuttingIteration + 1;
                                    
                                    % try to reduce the 'magnitude' of the constraint (i.e. b)
                                    b(1:end) = b(1:end).*(1-relativeCut); % the first one must not be touched: it is the tot probability constraint (sum(p)=1)
                                    
                                end
                                
                            end % while on dd
                            toc
                            disp('Entropy Minimization completed');
                            % **********************************************************************
                            % *******  END OF CONSTRAINTS SETUP
                            % **********************************************************************
                            p_v(:,n) = p_single_subj;
                            dd = 1-sum(p_v(:,n));
                            
                            % TODO: review and improve the if below and
                            % introduce systematic checks to the optim process
                            % above
                            if abs(dd)>0.10 | nz > size(p_single_subj,1)*0.50 % TODO: parametrize this level of approximation
                                % if there are problems in processing a
                                % specific view it is replaced by the prior
                                p_v(:,n) = p; % no change
                                disp('Entropy Min skipped: posterior probabilityies not summing up to 1 or poorly defined');
                                % disp('Sum of conditioned probabilities not converging: NO CHANGE in p');
                                %                                 m = msgbox('A view has been removed and replaced by the prior based view since there is no Entropy Pooling Convergence' ...
                                %                                     ,'Icon','warn','replace');
                                % continue; % not updating AA (even if there would be more history, althought no new prob measure)
                                % pause;
                            else
                                
                                p_v(:,n) = p_v(:,n)./sum(p_v(:,n)); % forcing sum of prob to be 1 when magnitude of dd (error) is acceptable (TODO: parametrize)
                                disp(['Sum of conditioned probabilities: ',num2str(sum(p_v(:,n)))]);
                            end
                            
                        end % n: no of subjects expressing views
                        
                        if SUBJECTIVE_VIEW_ACTIVE | QUANT_VIEW_ACTIVE
                           
                            
                            if AllViews_no == 0
                                % it can happen that AllViews_no==0 and the
                                % SUBJECTIVE_VIEW_ACTIVE is active (e.g.
                                % when the  DAA_params.riskAnalysisFlag
                                % flag is active, but the set of subj views
                                % is empty, to be able to run RiskAnalytics
                                % even when there are no views). In this
                                % case p_v is set to a vector of zeros and
                                % the prior 'equiprobability' only is used
                                p_v = zeros(size(p,1),2);
                                ConfInPrior = 1;
                                ConfInSubjViews = 0;
                                UsedConfInQuantViews = 0;
                            end
                            
                            % WEIGHTING PRIOR AND PERTURBED DISTRIB TO GET THE
                            % POSTERIOR DISTRIBUTION
                            % assign confidence to the views and pool opinions
                            if ~SUBJECTIVE_VIEW_ACTIVE
                                csviews = [];
                            else
                                csviews = sum(ConfInSubjViews);
                            end
                            if ~QUANT_VIEW_ACTIVE
                                cqviews = [];
                            else
                                cqviews = sum(UsedConfInQuantViews);
                            end
                        
                            
                            ConfInPrior = 1;
                            if ~isempty(csviews)
                                ConfInPrior = ConfInPrior - csviews;
                            end
                            if ~isempty(cqviews)
                                ConfInPrior = ConfInPrior - cqviews;
                            end
                            ConfidenceInViews = [ConfInPrior ConfInSubjViews UsedConfInQuantViews];
                            p_ = [p p_v]*ConfidenceInViews';
                            
                            sc = sum(ConfidenceInViews);
                            % the sum might not be 1 because quant signals are
                            % not active. In this case prob are rebalanced
                            if abs(sc-1) > 10e10
                                m = msgbox('Sum of Confidences in all subjects expressing views (including quant views) must sum up to 1 - Prob vectors changed so that they sum up to 1' ...
                                    ,'Icon','warn','replace');
                                pause(1.5);
                                close(m);
                                ConfidenceInViews = ConfidenceInViews./sc;
                            end
                            % save overall confidence levels (used for
                            % checking and output purposes)
                            
                            U.Strategies.Dynamic_AA_1.SubjectiveViewsWeight = ConfInSubjViews;
                            U.Strategies.Dynamic_AA_1.UsedConfInQuantViews = UsedConfInQuantViews;
                            U.Strategies.Dynamic_AA_1.ConfInPrior  = ConfInPrior;
                        else
                            U.Strategies.Dynamic_AA_1.SubjectiveViewsWeight = 0;
                            U.Strategies.Dynamic_AA_1.UsedConfInQuantViews = 0;
                            U.Strategies.Dynamic_AA_1.ConfInPrior  = ConfInPrior;
                        end
                    else
                        p_ = p;
                    end % if t > StartingTime & not BackTestOnly
                    PosteriorProb = p_;
                    
                    % *****************************************************
                    % ************* END OF  ENTROPY POOLING  **************
                    % *****************************************************
                    
                    % in cas the flag is not present in DAA_params,
                    % create flag saying (if == true) that the vector of
                    % weights is given: in this case no optim takes
                    % place and the set of output weights is the same
                    % as the set of constrained weights
                    
                    
                    if (AA_constraints.ub == AA_constraints.lb)
                        equalWeightsFlag = true(1);
                        NumPortf = 1;
                    else
                        equalWeightsFlag = false(1);
                    end
                    
                    % preallocating weights matrices (including assets
                    % excluded from AA because of zero weight)
                    Composition1_Weights = zeros(NumPortf,NAssets);
                    Composition1_Shares = zeros(NumPortf,NAssets);
                    Composition1_Shares_EUR = zeros(NumPortf,NAssets);
                    Composition1_Shares_FX = zeros(NumPortf,NAssets);
                    if DAA_params.riskAnalysisFlag
                        Composition1_Weights4ScenarioAnalysis = zeros(NumPortf,NAssets);
                    end
                    
                    if ~BackTestOnly % run optimization only if not simple backtest is required
                        
                        % *************************************************
                        % Retrieving Invariants' Prices as of time t  *****
                        % Using the AllInvariants matrix (field of Universe)
                        % Repricing takes place in the same cycle immediately
                        % after identifying the current price of the invariants
                        [P_sim] = HRepricing(U,X_Resampled,NAssets,current_t_date,P0,HorizonDays,HorizonDate);
                        
                        % historical repricing for HVaR scenarios
                        HorizonDateHVaR = daysadd(current_t_date,1,13);
                        [P_sim_HVaRScenarios] = HRepricing(U,X4HVaR,NAssets,current_t_date,P0,1,HorizonDateHVaR);
                        
                        if DAA_params.ExpectedShortfall_EF_options.onFullHistDataSet
                            % Needed to calculate ES on the optimal
                            % portfolio using the entire historical dataset
                            % (not used systematically for now). It will be
                            % useful to be able to calculate ES using for
                            % example the same data set used to calc ES for
                            % regulatory purposes, e.g. to impose
                            % constraints based on regulatory ES
                            
                            [P_sim_hist] = HRepricing(U,X_fullDataSet,NAssets,current_t_date,P0,HorizonDays,HorizonDate); % *** NOT STRICTLY NEEDED ***
                        else
                            P_sim_hist = [];
                        end
                        % *************************************************
                        % *************************************************
                        
                        actives = find(Active_Assets(t,:));
                        nonactives = find(~Active_Assets(t,:));
                        AA_constraints_active.lb = AA_constraints.lb(actives);
                        AA_constraints_active.ub = AA_constraints.ub(actives);
                        
                        P0_active = P0(actives);
                        P_sim_active = P_sim(:,actives);
                        Assets_Legend_active = U.Assets_Legend(actives);
                        
                        % Calculate expected returns and COV matrices for ASSETS
                        % at HORIZON
                        % 1) from prices at horizon to returns at horizon
                        rP0 = repmat(P0_active',size(P_sim_active,1),1); % initial prices (as of t)
                        R_sim = P_sim_active./rP0 - 1;
                        
                        % for debug purposes: to get returns for all assets
                        % (including non active ones)
                        rP0_all = repmat(P0',size(P_sim,1),1);
                        R_sim_all = P_sim./rP0_all - 1;
                        
                        % **** HISTVAR
                        % computing 1-period returns from HVaR repricing
                        P_sim_HVaRScenarios_actives = P_sim_HVaRScenarios(:,actives);
                        R_sim_HVaRScenarios = P_sim_HVaRScenarios_actives./repmat(P0_active',size(P_sim_HVaRScenarios_actives,1),1) - 1;
                        
                        % Needed to calculate ES on the optimal
                        % portfolio using the entire historical dataset
                        if DAA_params.ExpectedShortfall_EF_options.onFullHistDataSet
                            P_sim_hist_active =  P_sim_hist(:,actives);
                            rP0_hist = repmat(P0_active',size(P_sim_hist_active,1),1);
                            R_sim_hist = P_sim_hist_active./rP0_hist - 1;
                        else
                            P_sim_hist_active = [];
                            rP0_hist = [];
                            R_sim_hist = [];
                        end
                        
                        % ******************************************
                        
                        if DAA_params.Hcharts == 1
                            for c=1:size(P_sim_active,2)
                                tit1 = ['Asset ',strrep(Assets_Legend_active{c},'_',' '),' simulated price at horizon (= ',num2str(HorizonDays), ...
                                    ' days) as of ',datestr(current_t_date)];
                                tit2 = ['Asset ',strrep(Assets_Legend_active{c},'_',' '),' simulated return at horizon (= ',num2str(HorizonDays), ...
                                    ' days) as of ',datestr(current_t_date)];
                                leg = ['Frequencies based on POSTERIOR DISTRIB'];
                                % plot charts of simulated prices and returns at horizon
                                sp(c) = figure;
                                subplot(2,1,1); grid on;
                                histogram(P_sim_active(:,c));
                                title(tit1);
                                legend(leg);
                                grid on;
                                subplot(2,1,2); grid on;
                                histogram(R_sim(:,c));
                                title(tit2);
                                legend(leg);
                                grid on;
                            end
                            
                            disp('Press a key to close charts and continue ....');
                            pause;
                            close(sp);
                        end
                        
                        
                        Ns = size(R_sim,2);
                        Exps = R_sim'*p_; % = mean(P&L) expected values (all the P&L realizations - for each asset - multiplied by the respective probabilities)
                        % Covs =
                        % cov(R_sim-repmat(Exps',size(R_sim,1),1)); %
                        % should equal the one obtained below for
                        % check
                        
                        % ******************
                        % clear Covs;
                        % for kk=1:Ns
                        %    for jj=1:Ns
                        %        Covs(kk,jj) = sum(((R_sim(:,kk) - mean(R_sim(:,kk)))).*((R_sim(:,jj) - mean(R_sim(:,jj)))).*p_);
                        %    end
                        % end
                        
                        % The mattrix operations below should be
                        % equivalent to the cycle above (check), but much
                        % faster.
                        % Basically I first take the product YY'*diag(p),
                        % that combines the rows of YY' such that the
                        % output rows will be the 1t row of AA multiplied
                        % by p1, the second row af AA muiltiplied by p2 and
                        % so on .... Then this output is multiplied by YY,
                        % that is the same  as the sum of the product done in the FOR loop
                        % above (SUM(k,j) [(R(k)-mu(k))*(R(j)-mu(j))].
                        % NOTE: here I am using a new feature of Matlab
                        % that allows to calculate direcly A-mu, where A is
                        % an n x m matric and mu is a 1 x m vector
                        % diag_p_ = diag(p_);
                        sprob = size(p_,1);
                        % using sparse matrix here because when DAA_params.ProjectionResampling_numsim
                        % is large (e.g. 50k or 100k) the diag_p_ would be
                        % too big
                        diag_p_ = spdiags(p_,0,sprob,sprob);
                        YY  = R_sim - Exps';
                        % YY = bsxfun(@minus, R_sim, Exps'); % for Matlab releases prior to 2016b
                        Covs = (YY'*diag_p_*YY);
                        
                        if DAA_params.riskAnalysisFlag
                            Exps_prior = R_sim'*PriorProb;
                            % diag_p_ = diag(PriorProb);
                            sprob = size(PriorProb,1);
                            diag_p_ = spdiags(PriorProb,0,sprob,sprob);
                            YY  = R_sim - Exps_prior';
                            % YY  = bsxfun(@minus, R_sim, Exps_prior'); % for Matlab releases prior to 2016b
                            Covs_prior = (YY'*diag_p_*YY);
                        end
                        % *****************
                        
                        LinRets_ExpectedValues = Exps';
                        LinRets_Covariance = Covs;
                        
                        disp(['Current t: ',num2str(t)]);
                        
                        MaxTargetRet = 0; %0.40;
                        
%                     end % ~BackTestOnly
%                     
%                     if ~BackTestOnly % run optimization only if not simple backtest is required
                        
                        if first==1
                            Norm_R = norm(LinRets_ExpectedValues);
                            Norm_S = norm(LinRets_Covariance);
                        elseif first==0
                            Norm_R_current = norm(LinRets_ExpectedValues);
                            Norm_S_current = norm(LinRets_Covariance);
                            % normalization by initial norm ( ** NOT USED FOR NOW ** )
                            % LinRets_ExpectedValues = (LinRets_ExpectedValues./Norm_R_current).*Norm_R;
                            % LinRets_Covariance = (LinRets_Covariance./Norm_S_current).*Norm_S;
                        end
                        
                        % efficient frontier parameters setup
                        ef_params.NumPortf = NumPortf;
                        ef_params.Covariance = LinRets_Covariance;
                        ef_params.ExpectedValues = LinRets_ExpectedValues';
                        ef_params.MaxTargetRet = []; % NO MORE USED
                        ef_params.AA_constraints = AA_constraints_active;
                        ef_params.resampling = false(1);  % NO MORE USED
                        ef_params.resampling_params = []; % NO MORE USED
                        ef_params.RSim = [];
                        ef_params.ExpectedShortfall_EF_options = [];
                        ef_params.ConstrainedTotWgts = DAA_params.ConstrainedTotWgts;
                        ef_params.MaxReturn4FullFrontier_MV = DAA_params.MaxReturn4FullFrontier_MV; % this is for MV optim only (a similar parameter is in ExpectedShortfall_EF_options struct array for ES optim)
                        ef_params.equalWeightsFlag = equalWeightsFlag;
                        ef_params.MaxLongShortExposure = DAA_params.MaxLongShortExposure;
                        ef_params.MinNetExposure = DAA_params.MinNetExposure;
                        % linear equality constraints that can be triggered
                        % by quant signals
                        ef_params.AeqFromQviews = AeqFromQviews;
                        ef_params.beqFromQviews = beqFromQviews;
                        
                        if DAA_params.RiskBudgeting == 0
                            try % *************  OPTIMIZATION *****************
                                % used to catch error in the optimization
                                % process not managed in the section of code
                                % starting here
                                
                                if DAA_params.ExpectedShortfall_EF == 1
                                    
                                    % parameters specific to the Mean_ES
                                    % optimization (not used for MV optim)
                                    ef_params.ExpectedShortfall_EF_options = DAA_params.ExpectedShortfall_EF_options;
                                    ef_params.RSim = R_sim;
                                    % Needed to calculate ES on the optimal
                                    % portfolio using the entire historical dataset
                                    ef_params.R_sim_hist = R_sim_hist;
                                    % vector used to select the assets of the
                                    % optimal portfolio used to compute ES on
                                    % the whole hist dataset. This vector is
                                    % not strictly needed, but can be useful if
                                    % one wants to manually change the set of
                                    % assets on which to calc the full hist
                                    % dataset ES
                                    if ~isempty(R_sim_hist) % empty if DAA_params.ExpectedShortfall_EF_options.onFullHistDataSet is FALSE
                                        ef_params.FullHistES_AssetsToInlcude.allAssets = true(1,size(R_sim_hist,2))';
                                    end
                                    % here more subfields can be temporarily
                                    % defined MANUALLY to setup various subsets of
                                    % assets on which to calc Expected Shorfall
                                    % based on the Full Dataset
                                    % ef_params.FullHistES_AssetsToInlcude.sub1 = [true(1,10,false(1,3),true(1,5))];
                                    % *****************************************
                                    InitialTarget = NaN;
                                    if ~isempty(DAA_params.ExpectedShortfall_EF_options.SingleRet)
                                        InitialTarget = DAA_params.ExpectedShortfall_EF_options.SingleRet;
                                    elseif ~isempty(DAA_params.ExpectedShortfall_EF_options.SingleES)
                                        InitialTarget = DAA_params.ExpectedShortfall_EF_options.SingleES;
                                    end
                                    if t==2948
                                       disp('check'); 
                                    end
                                    ef_params.probabilities = p_; % probability vector associated with joint scenarios is RSim
                                    target = NaN;
                                    MES = MES_EFrontier(ef_params);
                                    MES.Optimization(false(1));
                                    ExitFlags(t,:) = MES.Exitflag; % temp: TODO: REVIEW
                                    OtherOutputs{t,1} = MES.OtherOutputs;
                                    U.Debug.CopulaSim.Mean(t,:) = debug_OUT.EVT{1};
                                    U.Debug.CopulaSim.Variance(t,:) = debug_OUT.EVT{2};
                                    U.Debug.CopulaSim.Min(t,:) = debug_OUT.EVT{3};
                                    U.Debug.CopulaSim.Max(t,:) = debug_OUT.EVT{4};
                                    U.Debug.CopulaSim.Tails(t,:) = debug_OUT.TAILS;
                                    
                                    if DAA_params.riskAnalysisFlag
                                        % to get the set of weights related to the
                                        % prior distribution when running AA for
                                        % Scenario Analysis purposes
                                        ef_params4ScenarioAnalysis = ef_params;
                                        ef_params4ScenarioAnalysis.probabilities = PriorProb;
                                        ef_params4ScenarioAnalysis.Covariance = Covs_prior;
                                        ef_params4ScenarioAnalysis.ExpectedValues = Exps_prior;
                                        MES_EFrontier4ScenarioAnalysis = MES_EFrontier(ef_params4ScenarioAnalysis);
                                        MES_EFrontier4ScenarioAnalysis.Optimization(false(1));
                                        CW4ScenarioAnalysis = MES_EFrontier4ScenarioAnalysis.EF_Composition;
                                        CW4ScenarioAnalysis = cast(CW4ScenarioAnalysis,'single');
                                    end
                                    
                                    % This if practically means: if I am running
                                    % a single point optimization (NOT a FULL
                                    % FRONTIER set of optimizations)
                                    if ~FullFrontier_flag
                                        
                                        if ~isempty(MES.Exitflag) && MES.Exitflag > 0 % TODO: can make this more detailed
                                            % when there is no feasible solution (Exitflag ~= -1):
                                            % in this case ExpectedReturn, Risk and CW are kept
                                            % at the previous optimal level
                                            
                                            ExpectedReturn = MES.EF_Return;
                                            Risk = MES.EF_Risk;
                                            CW = MES.EF_Composition;
                                            
                                            CW = cast(CW,'single');
                                            
                                            ExpectedReturn_original = ExpectedReturn;
                                            Risk_original = Risk;
                                            
                                        else % optim did not converge
                                            
                                            %                                 m = msgbox(['MES Optimization Exit Flag is ', num2str(MES.Exitflag), ' (date: ', datestr(current_t_date),')'] ....
                                            %                                     ,'Icon','warn','replace');
                                            
                                            if DAA_params.AA_OptimChangeTarget.flag
                                                %                                     m = msgbox(['MES Optimization Exit Flag is ', num2str(MES.Exitflag), ' (date: ', datestr(current_t_date),') - TRYING TO CHANGE TARGET'] ...
                                                %                                     ,'Icon','warn','replace');
                                                
                                                if ~isempty(DAA_params.ExpectedShortfall_EF_options.SingleES)
                                                    target = DAA_params.ExpectedShortfall_EF_options.SingleES;
                                                    while target < DAA_params.ExpectedShortfall_EF_options.SingleES*DAA_params.AA_OptimChangeTarget.limit
                                                        target = target.*(1+DAA_params.AA_OptimChangeTarget.step )
                                                        ef_params.ExpectedShortfall_EF_options.SingleES = target;
                                                        MES = MES_EFrontier(ef_params)
                                                        MES.Optimization(false(1));
                                                        
                                                        if DAA_params.riskAnalysisFlag
                                                            % to get the set of weights related to the
                                                            % prior distribution when running AA for
                                                            % Scenario Analysis
                                                            % purposes. I want
                                                            % these optimizations
                                                            % to track those run
                                                            % using the prior (with
                                                            % MES)
                                                            ef_params4ScenarioAnalysis = ef_params;
                                                            ef_params4ScenarioAnalysis.probabilities = PriorProb;
                                                            ef_params4ScenarioAnalysis.Covariance = Covs_prior;
                                                            ef_params4ScenarioAnalysis.ExpectedValues = Exps_prior;
                                                            ef_params4ScenarioAnalysis.ExpectedShortfall_EF_options.SingleES = target;
                                                            MES_EFrontier4ScenarioAnalysis = MES_EFrontier(ef_params4ScenarioAnalysis);
                                                            MES_EFrontier4ScenarioAnalysis.Optimization(false(1));
                                                        end
                                                        
                                                        if MES.Exitflag > 0
                                                            %                                                 m = msgbox(['ES Target changed to ', num2str(target), ' - Optimization successfully '] ...
                                                            %                                                 ,'Icon','warn','replace');
                                                            break;
                                                        end
                                                    end
                                                elseif ~isempty(DAA_params.ExpectedShortfall_EF_options.SingleRet)
                                                    limit = 1./DAA_params.AA_OptimChangeTarget.limit;
                                                    target = DAA_params.ExpectedShortfall_EF_options.SingleRet;
                                                    while target > DAA_params.ExpectedShortfall_EF_options.SingleRet*limit
                                                        target = target.*(1-DAA_params.AA_OptimChangeTarget.step )
                                                        ef_params.ExpectedShortfall_EF_options.SingleRet = target;
                                                        MES = MES_EFrontier(ef_params)
                                                        MES.Optimization(false(1));
                                                        
                                                        if DAA_params.riskAnalysisFlag
                                                            % to get the set of weights related to the
                                                            % prior distribution when running AA for
                                                            % Scenario Analysis
                                                            % purposes. I want
                                                            % these optimizations
                                                            % to track those run
                                                            % using the prior (with
                                                            % MES)
                                                            ef_params4ScenarioAnalysis = ef_params;
                                                            ef_params4ScenarioAnalysis.probabilities = PriorProb;
                                                            ef_params4ScenarioAnalysis.Covariance = Covs_prior;
                                                            ef_params4ScenarioAnalysis.ExpectedValues = Exps_prior;
                                                            ef_params4ScenarioAnalysis.ExpectedShortfall_EF_options.SingleES = target;
                                                            MES_EFrontier4ScenarioAnalysis = MES_EFrontier(ef_params4ScenarioAnalysis);
                                                            MES_EFrontier4ScenarioAnalysis.Optimization(false(1));
                                                        end
                                                        
                                                        
                                                        if MES.Exitflag > 0
                                                            %                                                  m = msgbox(['Return Target changed to ', num2str(target), ' - Optimization successfully '] ...
                                                            %                                                 ,'Icon','warn','replace');
                                                            break;
                                                        end
                                                    end
                                                end
                                            end
                                            
                                            if MES.Exitflag <= 0
                                                target = NaN;
                                                %                                      m = msgbox(['MES Optimization failed - ExitFlag = ', num2str(MES.Exitflag), ' (date: ', datestr(current_t_date),') - Most recent optimal weights held'] ...
                                                %                                     ,'Icon','warn','replace');
                                            end
                                        end % if on ExitFlag
                                        
                                    else % I am running FULL FRONTIER optim
                                        if ~isnan(MES.Exitflag)
                                            % if optim didn't converge allocations
                                            % are kept at the previous optimal
                                            % values
                                            ExpectedReturn = MES.EF_Return;
                                            Risk = MES.EF_Risk;
                                           
                                            CW = MES.EF_Composition;
                                            CW = cast(CW,'single');
                                            if DAA_params.riskAnalysisFlag
                                                ExpectedReturn_Prior = MES_EFrontier4ScenarioAnalysis.EF_Return;
                                                Risk_Prior = MES_EFrontier4ScenarioAnalysis.EF_Risk;
                                                CW4ScenarioAnalysis = MES_EFrontier4ScenarioAnalysis.EF_Composition;
                                                CW4ScenarioAnalysis = cast(CW4ScenarioAnalysis,'single');
                                                
                                            end
                                        end
                                    end % if I am running a single point optim (NOT FULL FRONTIER)
                                    
                                    if ~isempty(MES.EF_Return)
                                        % to keep track of the optimization process
                                        AA_Optim_tracker = [AA_Optim_tracker; [t,current_t_date,InitialTarget, ...
                                            target,MES.Exitflag]];
                                    else
                                        % it means that the MES optimization method
                                        % was unable to calculate the min ES point
                                        % of the efficient frontier
                                        % TODO: check what happens if this occurs
                                        % on the first optimization time (when
                                        % there are no previous AA weights)
                                        AA_Optim_tracker = [AA_Optim_tracker; [t,current_t_date,InitialTarget, ...
                                            target,NaN.*ones(1,MES.params.NumPortf)]];
                                    end
                                    
                                    % ***********************************************************************
                                    % ***********************************************************************
                                elseif DAA_params.ExpectedShortfall_EF == 0 % ********  OPTIM in MV SPACE ***
                                    % ***********************************************************************
                                    % ***********************************************************************
                                    
                                    % instantiating MV_EFrontier class to derive
                                    % the Mean-Variance efficient frontier
                                    % TODO: extend better Exit Flag management to
                                    % MV based optimization
                                    
                                    MV = MV_EFrontier(ef_params);
                                    
                                    MV.Optimization;
                                    
                                    ExitFlags(t,:) = MV.Exitflag;
                                    
                                    if DAA_params.riskAnalysisFlag
                                        % to get the set of weights related to the
                                        % prior distribution when running AA for
                                        % Scenario Analysis purposes
                                        ef_params4ScenarioAnalysis = ef_params;
                                        ef_params4ScenarioAnalysis.probabilities = PriorProb;
                                        ef_params4ScenarioAnalysis.Covariance = Covs_prior;
                                        ef_params4ScenarioAnalysis.ExpectedValues = Exps_prior;
                                        MV_EFrontier4ScenarioAnalysis = MV_EFrontier(ef_params4ScenarioAnalysis);
                                        MV_EFrontier4ScenarioAnalysis.Optimization;
                                    end
                                    
                                    if ~isempty(MV.EF_Composition)
                                        ExpectedReturn = MV.EF_Return;
                                        Risk = MV.EF_Risk;
                                        CW = MV.EF_Composition;
                                        if DAA_params.riskAnalysisFlag
                                            CW4ScenarioAnalysis = MV_EFrontier4ScenarioAnalysis.EF_Composition;
                                            ExpectedReturn_Prior = MV_EFrontier4ScenarioAnalysis.EF_Return;
                                            Risk_Prior  = MV_EFrontier4ScenarioAnalysis.EF_Risk;
                                        end
                                        
                                    else
                                        % if the optim didn't succeed then weights
                                        % from previous succeful optim are kept
                                        % TODO: check what happens when there is no
                                        % previous optim (this is the 1st one)
                                        m = msgbox(['MV Optimization failed: MV.EF_Composition is empty: PREVIOUS WEIGHTS HELD'] ...
                                            ,'Icon','warn','replace');
                                        pause(1.5);
                                        close(m);
                                    end
%                                     U.Debug.CopulaSim.Mean(t,:) = debug_OUT.EVT{1};
%                                     U.Debug.CopulaSim.Variance(t,:) = debug_OUT.EVT{2};
%                                     U.Debug.CopulaSim.Min(t,:) = debug_OUT.EVT{3};
%                                     U.Debug.CopulaSim.Max(t,:) = debug_OUT.EVT{4};
%                                     U.Debug.CopulaSim.Tails(t,:) = debug_OUT.TAILS;
                                    
                                    % * ExpectedReturn_original = ExpectedReturn; % no more used (resampling)
                                    % * Risk_original = Risk; % no more used (resampling)
                                    
                                    % to keep track of the optimization process
                                    AA_Optim_tracker = [AA_Optim_tracker; [t,current_t_date,MV.Exitflag]];
                                    
                                end % DAA_params.ExpectedShortfall_EF == 1
                                
                                
                            catch OptimErrors
                                % used to catch error in the optimization
                                % process that have not been managed in the
                                % dedicated section of code
                                
                                % HANDLED EXCEPTIONS
                                % using '1010' to identify this exception
                                % TODO: make a list of the codes used (see in
                                % MES and MV as well)
                                if DAA_params.ExpectedShortfall_EF == 0
                                    AA_Optim_tracker = [AA_Optim_tracker; [t,current_t_date,1010.*ones(1,ef_params.NumPortf)]];
                                elseif DAA_params.ExpectedShortfall_EF == 1
                                    AA_Optim_tracker = [AA_Optim_tracker; [t,current_t_date,InitialTarget,target,1010.*ones(1,ef_params.NumPortf)]];
                                end
                                if strcmp(OptimErrors.identifier,'optim:linprog:CoefficientsTooLarge') ...
                                        | strcmp(OptimErrors.identifier,'optimlib:ipqpcommon:ipConvexQP:InfNaNComplexDetected')
                                    U.Errors.handled.errorCode = OptimErrors;
                                    U.Errors.handled.solution = 'go ahead with the next optimization';
                                    U.Errors.handled.specificFeatures.codeSection = 'optimization';
                                    U.Errors.handled.specificFeatures.optimizationTime = t;
                                    U.Errors.handled.specificFeatures.optimizationDate = current_t_date;
                                    continue% go ahead with the next optimization
                                else
                                    % UNHANDLED EXCEPTIONS
                                    U.Errors.unhandled.errorCode = OptimErrors;
                                    U.Errors.unhandled.specificFeatures.codeSection = 'optimization';
                                    U.Errors.unhandled.specificFeatures.optimizationTime = t;
                                    U.Errors.unhandled.specificFeatures.optimizationDate = current_t_date;
                                    rethrow(OptimErrors);
                                end
                                
                                
                            end % try (OptimErrors)
                            
                            
                            % *********  Efficient Frontier Resampling
                            % ********   (NO MORE USED AND MAINTAINED)
                            if DAA_params.resampling_EffFront.flag & HorizonDays > 1
                                % resampling only makes sense when the horizon
                                % (HorizonDays) is longer then 1 since it is basically
                                % aimed at reducing the estimation error
                                
                                % TODO: PRACTICALLY NOT USED: DONE BEFORE
                                % INTRODUCING BOOTSTRAPPING OVER AT HORIZON,
                                % (THAT IN ITSELF GIVES MORE STABILITY TO MEAN AND RISK ESTIMATES)
                                % REVIEW THE LOGIC
                                
                                % distributional forms for resampling
                                
                                if DAA_params.riskAnalysisFlag
                                    % to get the set of weights related to the
                                    % prior distribution when running AA for
                                    % Scenario Analysis purposes
                                    ef_params4ScenarioAnalysis = ef_params;
                                    ef_params4ScenarioAnalysis.probabilities = PriorProb;
                                    ef_params4ScenarioAnalysis.Covariance = Covs_prior;
                                    ef_params4ScenarioAnalysis.ExpectedValues = Exps_prior;
                                    MV_EFrontier4ScenarioAnalysis = MV_EFrontier(ef_params4ScenarioAnalysis);
                                    MV_EFrontier4ScenarioAnalysis.Optimization;
                                end
                                
                                if ~isempty(MV.EF_Composition)
                                    ExpectedReturn = MV.EF_Return;
                                    Risk = MV.EF_Risk;
                                    CW = MV.EF_Composition;
                                    if DAA_params.riskAnalysisFlag
                                        CW4ScenarioAnalysis = MV_EFrontier4ScenarioAnalysis.EF_Composition;
                                        ExpectedReturn_Prior = MV_EFrontier4ScenarioAnalysis.EF_Return;
                                        Risk_Prior  = MV_EFrontier4ScenarioAnalysis.EF_Risk;
                                    end
                                    
                                    RetSeries_Resampling = mvnrnd(LinRets_ExpectedValues, LinRets_Covariance,HorizonDays);
                                    ERassets_Resampling = mean(RetSeries_Resampling,1); %compute expexted returns
                                    VarCov_Resampling = cov(RetSeries_Resampling); %compute variance covariance matrix
                                    
                                    ef_params.Covariance = VarCov_Resampling;
                                    ef_params.ExpectedValues = ERassets_Resampling';
                                    ef_params.MaxTargetRet = [];
                                    
                                    MV = MV_EFrontier(ef_params);
                                    MV.Optimization;
                                    
                                    Weights_Resampled(:,:,nres) = MV.EF_Composition;
                                    disp(['temp check (resampling no): ',num2str(nres)]);
                                end
                                meanWeights = mean(Weights_Resampled,3); %average (along the 3rd dim = simulations) simualted weights
                                ExpectedReturn = meanWeights * ERassets_Resampling'; %evaluate resampled portfolios expected returns
                                Risk = diag(sqrt(meanWeights * VarCov_Resampling *  meanWeights')); %evaluate resampled portfolios risk
                                
                                figure; grid on; hold on;
                                plot([Risk_original,Risk'], ...
                                    [ExpectedReturn_original,ExpectedReturn']);
                                title('Temp Visual check of resampling');
                                CW = meanWeights; % final weights in case of resampled frontiers
                            end % if resampling flag is true
                            
                            %%%%% RISK BUDGET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        elseif DAA_params.RiskBudgeting == 1
                            % the main params for the Risk Budgeting
                            % portfolio construction are:
                            % - the Covariance Matrix
                            % - the vector of target risk budgets for any
                            % assets
                            % - the lower and upper bound for any asset
                            % weight
                            % - the ExpectedValues for any asset (to built
                            % the same output format as MES_EFrontier.m)

                            % check on RiskBudgetWgts (if empty then set
                            % uniform)
                            if isfield(DAA_params,'RiskBudgetWgts')
                                RiskBudgetWgts_actives = DAA_params.RiskBudgetWgts(:,actives)/sum(DAA_params.RiskBudgetWgts(:,actives));
                            else
                                RiskBudgetWgts_actives = 1/size(Covs,1)*ones(1,size(Covs,1));
                            end
                            
                            if AA_constraints_active.lb == AA_constraints_active.ub
                                disp('error with Risk Budget constraints: upper and lower bound are the same');
                            end
                            
                            
                            rb_params.covs = Covs;
                            rb_params.budgets = RiskBudgetWgts_actives';
                            rb_params.AA_constraints = AA_constraints_active;
                            rb_params.MaxLongShortExposure = DAA_params.MaxLongShortExposure;
                            rb_params.ExpectedValues = Exps;
                            rb_params.ConstrainedTotWgts = DAA_params.ConstrainedTotWgts;
                            if isfield(DAA_params,'CurrentWgts')
                                rb_params.CurrentWgts = DAA_params.CurrentWgts(actives);
                            else
                                rb_params.CurrentWgts = [];
                            end
                            rb_params.MinNetExposure = DAA_params.MinNetExposure;
                            rb_params.AeqFromQviews = AeqFromQviews;
                            rb_params.beqFromQviews = beqFromQviews;
                            
                            rb_params.ActiveAssets = actives; % NOT YET USED
                            rb_params.Assets_Legend_active =  Assets_Legend_active; % NOT YET USED
                            rb_params.equalWeightsFlag = equalWeightsFlag;
                            
                            
                            if current_t_date==732568
                                disp('check');
                            end
                            
                            RB = RiskBudgetPTF(rb_params);
                            RB.PtfBuilding;
                            ExitFlags(t,:) = RB.Exitflag;
                            
                            if DAA_params.riskAnalysisFlag
                                % to get the set of weights related to the
                                % prior distribution when running AA for
                                % Scenario Analysis purposes
                                rb_params4ScenarioAnalysis = rb_params;
                                rb_params4ScenarioAnalysis.probabilities = PriorProb;
                                rb_params4ScenarioAnalysis.covs = Covs_prior;
                                rb_params4ScenarioAnalysis.ExpectedValues = Exps_prior;
                                RB_4ScenarioAnalysis = RiskBudgetPTF(rb_params4ScenarioAnalysis);
                                RB_4ScenarioAnalysis.PtfBuilding;
                            end
                            
                            % HANDLED EXCEPTIONS
                            % TO DO: INCLUDE ERRORS FROM RISK BUDGET
                            
                            if ~isempty(RB.RB_Composition)
                                ExpectedReturn = RB.RB_Return;
                                Risk = RB.RB_Risk;
                                CW = RB.RB_Composition;
                                if DAA_params.riskAnalysisFlag
                                    CW4ScenarioAnalysis = RB_4ScenarioAnalysis.RB_Composition;
                                    ExpectedReturn_Prior = RB_4ScenarioAnalysis.RB_Return;
                                    Risk_Prior  = RB_4ScenarioAnalysis.RB_Risk;
                                end
                                
                            else
                                % if the optim didn't succeed then weights
                                % from previous succeful optim are kept
                                % TODO: check what happens when there is no
                                % previous optim (this is the 1st one)
                                m = msgbox(['RB Optimization failed: RB.RB_Composition is empty: PREVIOUS WEIGHTS HELD'] ...
                                    ,'Icon','warn','replace');
                                pause(1.5);
                                close(m);
                            end
                            
                            AA_Optim_tracker = [AA_Optim_tracker; [t,current_t_date,RB.Exitflag]];
                            %%%%% RISK BUDGET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        end
                        
                        % *************************************************************************************
                        
                        % CS = Budget*CW./(ones(NumPortf,1)*Current_Prices(t,actives));
                        % Composition in terms of shares must be computed after
                        % converting the UnitNotional_0 quantities in EUR since
                        % Budget is EUR denominated
                        % CS = Budget*CW./(ones(NumPortf,1)*UnitNotional_0_EUR(t,actives));
                        
                        % vector of shares (in EUR) of the total budget assigned to the
                        % various available assets
                        
                        
                    else % when only backtest (based on upper bound limits) is required
                        ExpectedReturn = 0;
                        Risk = 0;
                        actives = find(Active_Assets(t,:));
                        CW = AA_constraints.ub(find(actives));
                        
                    end % ~BackTestOnly
                    
                    if ~exist('CW')
                        % when the previous weights are held because the
                        % optim doesn't succed, it it is the 1st
                        % optimization, then CW is not defined, go ahead
                        % assuming that the next optimization is the first
                        % one
                        t = t + 1;
                        first = 1;
                        continue
                        % ** CW = zeros(NumPortf,numel(actives));
                    end
                    BudgetShares_EUR = Budget*CW;
                    
                    % converting this vector in FX denominated amounts
                    exchdir = 'EURFX';
                    
                    % -----> filter U.Currencies BY 'actives'
                    % setup check in ConvertFX
                 
                    crncy_actives = U.Currencies(actives);
                    BudgetShares_FX = U.ConvertFX(BudgetShares_EUR,crncy_actives,U.ExchangeRates.fts,current_t_date,exchdir);
                    
                    CS_FX = BudgetShares_FX./(ones(NumPortf,1)*UnitNotional_0(t,actives));
                    CS_EUR = BudgetShares_EUR./(ones(NumPortf,1)*UnitNotional_0_EUR(t,actives));
                    % *************************************************************************************
                    
                    % remapping of CW and CS to Composition1_Weights and Composition1_Shares
                    Composition1_Weights(:,actives) = CW;
                    Composition1_Shares_EUR(:,actives) = CS_EUR;
                    Composition1_Shares_FX(:,actives) = CS_FX;
                    if DAA_params.riskAnalysisFlag
                        Composition1_Weights4ScenarioAnalysis(:,actives) = CW4ScenarioAnalysis;
                    end
                    % end % if p_v calculation was OK
                end % if an optimization trigger occurs
                
                % EXPECTED RETURNS AND STD AT HORIZON ALONG THE EFFICIENT
                % FRONTIER (OR SINGLE PORTFOLIO OPTIMIZATION)
                if first == 0
                    %                     Norm_R_current = norm(ExpectedReturn);
                    %                     Norm_S_current = norm(Risk);
                    %
                    %                     ExpectedReturn = (ExpectedReturn./Norm_R_current).*Norm_R;
                    %                     Risk = (Risk./Norm_S_current).*Norm_S;
                    %                     IR = ExpectedReturn./Risk;
                    
                    % ... IN TERMS OF RETURNS
                    U.Strategies.Dynamic_AA_1.Dynamic_Frontier_EP.ExpectedReturn(:,t) = ExpectedReturn;
                    U.Strategies.Dynamic_AA_1.Dynamic_Frontier_EP.Risk(:,t) = Risk;
                    
                    %%%%% RISK BUDGET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    if DAA_params.RiskBudgeting == 1
                        U.Strategies.Dynamic_AA_1.RB_ToTest.params(:,t) = rb_params;
                        U.Strategies.Dynamic_AA_1.RB_ToTest.ExpectedReturn(:,t) = RB.RB_Return;
                        U.Strategies.Dynamic_AA_1.RB_ToTest.CW(:,t) = RB.RB_Composition;
                        U.Strategies.Dynamic_AA_1.RB_ToTest.Risk(:,t) = RB.RB_Risk;
                        U.Strategies.Dynamic_AA_1.RB_ToTest.OtherOutputs(:,t) = RB.OtherOutputs;
                        U.Strategies.Dynamic_AA_1.RB_ToTest.MarginalRisks(:,t) = RB.MarginalRisks;
                        U.Strategies.Dynamic_AA_1.RB_ToTest.MarginalRisksPCT(:,t) = RB.MarginalRisks/RB.RB_Risk;
                        U.Strategies.Dynamic_AA_1.RB_ToTest.Errors{:,t} = RB.Errors;
                        U.Strategies.Dynamic_AA_1.RB_ToTest.Exitflags(:,t) = RB.Exitflag;
                    end
                    %%%%% RISK BUDGET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                    % COMPOSITION ALONG THE EFFICIENT FRONTIER
                    % both in terms of weights and no of shares
                    for k=1:NAssets  % actives
                        nm = ['Asset_',num2str(k)];
                        U.Strategies.Dynamic_AA_1.Dynamic_Frontier_EP.Allocation.(nm)(:,t) = Composition1_Weights(:,k);
                        U.Strategies.Dynamic_AA_1.Dynamic_Frontier_EP.AllocationShares_EUR.(nm)(:,t) = Composition1_Shares_EUR(:,k);
                        U.Strategies.Dynamic_AA_1.Dynamic_Frontier_EP.AllocationShares_FX.(nm)(:,t) = Composition1_Shares_FX(:,k);
                        
                        if DAA_params.riskAnalysisFlag
                            
                            U.Strategies.Dynamic_AA_1.Dynamic_Frontier_EP.Allocation4ScenarioAnalysis.(nm)(:,t) = Composition1_Weights4ScenarioAnalysis(:,k);
                        end
                    end
                    U.Strategies.Dynamic_AA_1.Dynamic_Frontier_EP.Active_Assets(t,1:NAssets) = Active_Assets(t,:);
                    U.Strategies.Dynamic_AA_1.Hist_Scenarios_Start(t,1) = hist_scenarios_start;
                    U.Strategies.Dynamic_AA_1.ExitFlags = ExitFlags;
                    U.Strategies.Dynamic_AA_1.OtherOutputs = OtherOutputs;
                    
                    
                elseif first == 1 % ***************************************
                    
                    %                     ** Norm_R = norm(ExpectedReturn);
                    %                     ** Norm_S = norm(Risk);
                end
                
                if first == 1
                    first = 0;
                    t = StartingTime-1;
                end
                
                % ************************************************
                % store the the matrix of simulated projected returns
                % and the prior / posterior probability vectors as
                % of the current optimization time. Need to assign
                % these properties here since they are needed by
                % the class RiskAnalytics
                
                U.Strategies.Dynamic_AA_1.ProjectedReturns{t,1} = R_sim;
                U.Strategies.Dynamic_AA_1.ProbabilityVector_Prior{t,1} = PriorProb;
                U.Strategies.Dynamic_AA_1.ProbabilityVector_Posterior{t,1} = PosteriorProb;
                
                % ************************************************
                
                if DAA_params.riskAnalysisFlag
                    
                    U.Strategies.Dynamic_AA_1.Dynamic_Frontier_EP_Prior.ExpectedReturn(:,t) = ExpectedReturn_Prior;
                    U.Strategies.Dynamic_AA_1.Dynamic_Frontier_EP_Prior.Risk(:,t) = Risk_Prior;
                    for k=1:NAssets  % actives
                        nm = ['Asset_',num2str(k)];
                        U.Strategies.Dynamic_AA_1.Dynamic_Frontier_EP_Prior.Allocation.(nm)(:,t) = ...
                            Composition1_Weights4ScenarioAnalysis(:,k);
                    end
                    % ************************************************
                    % Instantiate RiskAnalytics class
                    % for now the prior / posterior risk metrics are both based
                    % on the vector of weights computed using one probability
                    % measure (that depends on the initial settings). So to
                    % make proper comparison it is necessary to run the
                    % optimizer under 2 different setups)
                    params.ScenarioLabel.universeName = DAA_params.SetUpName;
                    params.ScenarioLabel.posterior = SubjViewsLabel;
                    params.ScenarioLabel.posteriorAllSingleAssetsViews = AllSingleAssetsViews;
                    params.ScenarioLabel.prior = [];
                    params.HVaR.R_sim_HVaRScenarios = R_sim_HVaRScenarios;
                    params.HVaR.Length = size(R_sim_HVaRScenarios,1);
                    RiskAn = RiskAnalytics(U,params);
                    if isdeployed
                        RunMsg = msgbox('Computing Ptf Risk Measures: when working with efficient frontiers this step may take several minutes, depending on the granularity of the frontier', ...
                            'Deployed code execution','CreateMode','Replace');
                    else
                        disp('Computing Ptf Risk Measures: when working with ');
                        disp('efficient frontiers this step may take several minutes');
                    end
                    RiskAn.PortfolioRiskMeasures;
                    % ************************************************
                else
                    RiskAn = [];
                end
                HorizonRiskMeasures{t,1} = RiskAn;
                
            end % loop on t
            % ************************************************************
            % ************************   END OF  *************************
            % ********* cycling over hist horizon for Dynamic AA *********
            % ************************************************************
            
            U.Strategies.Dynamic_AA_1.Allocation_changes_EP = Allocation_changes_EP;
            U.Strategies.Dynamic_AA_1.StartingTime = StartingTime;
            U.Strategies.Dynamic_AA_1.NAssets = NAssets; % TODO: move NAssets under 'U' as this cannot change
            U.Strategies.Dynamic_AA_1.Current_Prices = Current_Prices;
            U.Strategies.Dynamic_AA_1.Current_Prices4BackTest = Current_Prices4BackTest;
            U.Strategies.Dynamic_AA_1.AA_Optim_tracker = AA_Optim_tracker;
            U.Strategies.Dynamic_AA_1.HorizonRiskMeasures = HorizonRiskMeasures;
            
        end % Dynamic_AA_1
