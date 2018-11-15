classdef EVT_CopulaSim < handle
    % this class is designed to fit a copula distribution to a multivariate
    % semi-parametric (or parametric) distribution obtained from an
    % empirical multivariate distribution by modelling each marginal
    % empirical distribution as an 'object' whose tails are modeled
    % following a GPD, while the 'center' is modeled through a 'gaussian
    % kernel' (or through and 'ecdf'). Then simulations based on the
    % estimated copula are done and they are transformed back (through inversion of the
    % CDF of the semiparametric distribution mentioned above) from  'copula space'
    % to out original space.
    
    properties (SetAccess = immutable)
        
        inputParams = []; % set of initial parameters;
        X = []; % input multivariate empirical distribution (input 'data')
        X_fullHistory = []; % input 2nd multivariate empirical distribution (input 'data_2')
        
        parametrizedDistributions = [];
    end
    
    properties
        % Main Outputs
        Simulated_X = [];   % main output (simulated realizations based on the model implemented here)
        OUT4Debug = [];     % for debugging purposes
        TailsOpt = []; % tails cutoffs used to define the tails for GPD fit
        CopulaParams = []; % estimated copula parameters
        copulaType = []; % type of fitted copula
        OUT = []; % output for debugging purposes
        ShapeParameters;
        forDebug;
        
        % mean of all the marginals, calculated to center the data if
        % toBeCentered=true(1) (see below). They need to be saved to be
        % able to 'give back' the mean to the simulated data before output
        mu_X;
        mu_X_fullHistory;
    end
    
    methods
        
        function EVT = EVT_CopulaSim(data,data_2,params) % constructor
            % INPUTS:
            % -> data: a [TxN] matrix of T empirical joint empirical observations,
            % so that each column will be a marginal empirical distribution. It
            % is better if this matrix is centered about its mean
            % -> data2: if not empty and when the
            % params.FullHist4TailsEstimation flag is set to true(1) it must be
            % a matrix of dimension [T1xN] that will be used to estimate the
            % tails 'cutoff'. This is used when we want to model tails'cutoffs
            % on different 'history' compared to the history in 'data', that is
            % used to calibrate the GPD parameters
            % -> params: made of the following subfields
            %       -> nsim: number of simulated values from the copula
            %       dsitribution. This is also the number of simulated joint
            %       scenarios for the final output
            %       -> corr_X: if not empty then the co-dependence structure is
            %       not estimated via copula and corr_X is assumed to model this
            %       co-dependence. This is dangerous and must be used carefully
            %       since corr_X is usually different than the correlation
            %       matrix estimated by fittin a copula to the 'grades' of our
            %       original marginal distributions
            %       -> ProbThreshold4MC: IMPORTANT: this is a threshold whose
            %       meaning is: exclude fromn simulated output the simulated
            %       values whgose probability (given the estimated GPD tails)
            %       is less than ProbThreshold4MC. Important to exclude very
            %       unrealistic outcomes (and so to stabilize simulations) when
            %       the partameters modeling a specific tail are so that the
            %       variance can be infinite (there is no convergence of the
            %       integral of the tails to a finite value - like e.g. it is
            %       for a Normal distribution (pi/2) -)
            %       -> calibrateTails: true(1) if the tails cutoffs must be defined based on a calibration algorithm
            %       -> ConstantTailsThreshold: used when calibrateTails =
            %       false(1) to model both the upper and the lower tail based
            %       on a constant threshold whose value is
            %       ConstantTailsThreshold (e.g. 0.07)
            %       -> V CentralValuesModel: 'kernel' or 'ecdf' to define how to
            %       model the central piece of the distribution (between tails)
            %       -> toBeCentered: true(1 )if data must be centered around the mean
            %       before calibration. If data have been centered 'otside'
            %       this class then this step is not necessary
            
            
            EVT.inputParams = params;
            CentralValuesModel = params.CentralValuesModel;
            X = data;
            X_fullHistory = data_2;
            
            if params.toBeCentered
                mu_X = mean(X);
                EVT.mu_X = mu_X;
                X = bsxfun(@minus, X, mu_X);
                
                if params.FullHist4TailsEstimation
                    mu_X_fullHistory = mean(X_fullHistory);
                    X_fullHistory = bsxfun(@minus, X_fullHistory, mu_X_fullHistory);
                    EVT.mu_X_fullHistory = mu_X_fullHistory;
                end
            end
            
            if params.FullHist4TailsEstimation
                Y = X_fullHistory;  % in this case use full history (as of current time t for tails modeling)
            else
                Y = X;
            end
            
            % assigning ssome properties values
            EVT.X = X;
            EVT.X_fullHistory = X_fullHistory;
            
            nrserie = size(Y,2);
            OBJ = cell(nrserie,1);
            warning off;
            
            for i=1:nrserie % for each empirical marginal distribution
                
                if params.calibrateTails
                    EVT.OptimizeTailsCutoffs(i);
                    
                else
                    EVT.TailsOpt(i,1) = params.ConstantTailsThreshold;
                    EVT.TailsOpt(i,2) = 1 - params.ConstantTailsThreshold;
                end
                
                LowerThreshold =  EVT.TailsOpt(i,1);
                UpperThreshold =  EVT.TailsOpt(i,2);
                
                if ~params.FullHist4TailsEstimation
                    %                     try
                    % OBJ{i}=paretotails(Y(:,i),LowerThreshold,UpperThreshold,CentralValuesModel);
                    if strcmp(CentralValuesModel,'ecdf')
                        OBJ{i}=paretotails(Y(:,i),LowerThreshold,UpperThreshold,@EmpiricalCdfhandle);
                    elseif strcmp(CentralValuesModel,'kernel')
                        OBJ{i}=paretotails(Y(:,i),LowerThreshold,UpperThreshold,@KernelDhandle);
                    end
                    
                    %                     catch MM
                    %                         % if the problem was due to the 'ecdf' selection
                    %                         % (to model the 'center' of the distribution, then
                    %                         % try with kernel smoothing
                    %                         if strcmp(MM.identifier,'stats:paretotails:XfromCDFFUNnotDistinct')  ...
                    %                                 & strcmp(CentralValuesModel,'ecdf')
                    %                             % *OBJ{i}=paretotails(Y(:,i),LowerThreshold,UpperThreshold,'kernel');
                    %                             OBJ{i}=paretotails(Y(:,i),LowerThreshold,UpperThreshold,@KernelDhandle);
                    %                         else
                    %                             rethrow(MM);
                    %                         end
                    %                     end
                else
                    % if full history has been used to model the tails, then
                    % the semiparametric OBJ must be rebuilt based on X only
                    if strcmp(CentralValuesModel,'ecdf')
                        OBJ{i}=paretotails(X(:,i),LowerThreshold,UpperThreshold,@EmpiricalCdfhandle);
                    elseif strcmp(CentralValuesModel,'kernel')
                        OBJ{i}=paretotails(X(:,i),LowerThreshold,UpperThreshold,@KernelDhandle);
                    end
                end
                % ********************************************************
                
            end % i loop
            
            EVT.parametrizedDistributions = OBJ;
            
        end % constructor
        
        function OptimizeTailsCutoffs(EVT,currentCol)
            % estimating the best tails' cutoffs **************
            % currentCol identifies the column (marginal distribution) of
            % the main input matrix that I am working on
            
            t_opt.U = 1;
            t_opt.L = 0;
            
            i = currentCol;
            if EVT.inputParams.FullHist4TailsEstimation
                Y = EVT.X_fullHistory;
            else
                Y = EVT.X;
            end
            
            % LOGIC: UNDERSTANT WHEN SHAPE PARAMETER ESTIMATES
            % 'STABILIZES' - NOW TAKING THE CUTOFF CORRESPONDING TO ITS
            % MEAN VALUE
            % the shape parameter is repeatedly
            % estimated for progressively decreasing sizes of
            % the tail (until a NaN i generated).
            
            slag = 5; % (TODO: parametrize) ** no more used for now **
            MinTailSize = EVT.inputParams.MinTailSize;
            
            LU = {'L','U'};
            nT = numel(LU);
            
            for tt=1:nT
                T = LU(tt);
                
                if strcmp(T{1},'L')
                    t = 0.30; % starting value (TODO: parametrize)
                    decreaseRate = -0.01;
                elseif strcmp(T{1},'U')
                    t = 0.70; % starting value (TODO: parametrize)
                    decreaseRate = +0.01; % step size
                end
                
                clear shapeEstimates shapeEstimates_STD mem_t;
                shapeEstimates = [];
                shapeEstimates_STD(1:slag) = 1;
                cnt = 1;
                paramsEstimates = []; % for debug
                logLik4estimates = [];
                
                N_prev = 10e6;
                
                while t>0.05 & t<0.95
                    
                    if strcmp(T{1},'L')
                        p_empirical = prctile(Y(:,i),(t)*100);
                        tail = p_empirical - Y(Y(:,i)<p_empirical,i); % strictly less than
                        noEstimVal = 0; % value of the cutoff (no tail) to be used if no estimate is achieved
                    elseif strcmp(T{1},'U')
                        p_empirical = prctile(Y(:,i),(t)*100);
                        tail = Y(Y(:,i)>p_empirical,i) - p_empirical;
                        noEstimVal = 1;
                    end
                    N = numel(tail);
                    
                    
                    if N > MinTailSize
                        s = gpfit(tail);
                        nlogL = gplike(s,tail);
                        paramsEstimates = [paramsEstimates;s];
                        logLik4estimates = [logLik4estimates;nlogL];
                    else
                        break;
                    end
                    
                    shapeEstimates(cnt) = s(1);
                    
                    
                    mem_t(cnt) = t;
                    cnt = cnt + 1;
                    t = t*(1 + decreaseRate);
                    
                    if N==N_prev
                        % if decreasing the size of the tails has no effect
                        % on its numerosity it makes no sense to
                        % re-estimate the tails parameters. We would get
                        % the same numbers as of the previous iteration and
                        % it would be double counted also for density calc
                        % purposes
                        t = t*(1 + decreaseRate);
                        continue;
                    end
                    N_prev = N; % records the numerosity of the previous iteration tail
                end % while t in ]0 1[
                
                
                if numel(shapeEstimates) < 3 % a min no of estimates in necessary for reliability
                    t_opt.(T{1}) = noEstimVal;
                else
                    
                    % ****************
                    [E1,x] = ecdf(shapeEstimates,'bounds','on');
                    if size(E1) ~= size(x)
                        pause
                    end
                    
                    ff = find(x(2:end)==x(1:end-1));
                    if ~isempty(ff)
                        ff=ff+1;
                        x(ff(end))=[];
                        E1(ff(end))=[];
                        
                    end
                    % ****************
                    pd = makedist('PiecewiseLinear','x',x','Fx',E1');
                    
                    
                    probDensity = pd.pdf(shapeEstimates);
                    [mns,mns_i] = max(probDensity);
                    chosen = mns_i;
                    
                    % should be the same as above
                    % choose the shape parameter value where the
                    % density is highest. The idea is to choose a value
                    % that is within a relatively stable range. Higher prob
                    % density is used as a proxy for stability for now
                    %                     [shapeEstimates_s,si] = sort(shapeEstimates);
                    %                     probCumDensity = pd.cdf(shapeEstimates_s);
                    %                     d_shapeEstimates_s=[0,diff(shapeEstimates_s)];
                    %                     [mns,mns_i] = max([0,diff(probCumDensity)]./d_shapeEstimates_s); % probability mass: ratio between probability and length of corresponding data
                    %                     chosen = si(mns_i);
                    %                     chosen = chosen(1);
                    
                    if shapeEstimates(chosen) > 0  & shapeEstimates(chosen) < 0.50 % > 0 for fat tails (compared to Normal), <0.50 for finite variance
                        t_opt.(T{1}) = mem_t(chosen);
                        EVT.ShapeParameters.(T{1}){i} = shapeEstimates(chosen);
                    else
                        t_opt.(T{1}) = noEstimVal;
                    end
                    
                    
                end
                
                %                                 % plot selected optimal simulated tail (for
                %                                 % DEBUG only) ****************************
                %                                 % MUST BE % COMMENTED % otherwise might
                %                                 % cause stack overflow
                %                                 if strcmp(T{1},'L')
                %                                     p_empirical = prctile(Y(:,i),(t_opt.(T{1}))*100);
                %                                     tail = p_empirical - Y(Y(:,i)<p_empirical,i); % strictly less than
                %                                 elseif strcmp(T{1},'U')
                %                                     p_empirical = prctile(Y(:,i),(t_opt.(T{1}))*100);
                %                                     tail = Y(Y(:,i)>p_empirical,i) - p_empirical;
                %                                 end
                %                                 s = gpfit(tail);
                %                                 r = gprnd(s(1),s(2),t_opt.(T{1}),1000,1);
                %                                 figure;
                %                                 if strcmp(T{1},'L')
                %                                     histogram(t_opt.(T{1})-r,300);
                %                                 elseif strcmp(T{1},'U')
                %                                     histogram(r-t_opt.(T{1}),200);
                %                                 end
                %                                 grid on;
                %                                 title(['Left tail simulated GPD with threshold parameter = ',num2str(t_opt.(T{1})),' and shape parameter = ',num2str(s(1))]);
                % title(['Left tail simulated GPD with threshold parameter = '])
                % *****************************************
                
                %                 else
                %                     TailsOpt(1) = 0;
                %                     TailsOpt(2) = 1;
                %                 end
                
                
                %                 % *****************************************
                %                 % 'uncomment to see results for each
                %                 % optimization'
                %                 figure
                %                 plot(mem_t,shapeEstimates_STD)
                %                 hold on
                %                 grid on
                %                 plot(mem_t(1),shapeEstimates_STD(1),'ok','Linewidth',3)
                %                 plot(mem_t(mns_i),shapeEstimates_STD(mns_i),'or')
                %                 plot(mem_t(chosen),shapeEstimates_STD(chosen),'og','linewidth',3)
                %                 legend({'STD of estimates','STARTS HERE','Min STD','Selected STD Point'});
                %                 title('STD of estimates chart')
                %                 figure
                %                 plot(mem_t,shapeEstimates);
                %                 hold on; grid on;
                %                 plot(mem_t(1),shapeEstimates(1),'ok','Linewidth',3)
                %                 plot(mem_t(mns_i),shapeEstimates(mns_i),'or')
                %                 plot(mem_t(chosen),shapeEstimates(chosen),'og','linewidth',3)
                %                 legend({'S param estimates','STARTS HERE','corresponding to Min STD level','Selected param level'});
                %                 title('Estimates chart')
                %                 % *****************************************
                
                
            end % loop on tails {'L' and 'U'}
            % *************************************************
            % *************************************************
            TailsOpt(1) = t_opt.L;
            TailsOpt(2) = t_opt.U;
            EVT.forDebug.(T{1}).shapeEstimates = shapeEstimates;
            EVT.forDebug.(T{1}).paramsEstimates = paramsEstimates;
            EVT.forDebug.(T{1}).logLik4estimates = logLik4estimates;
            EVT.TailsOpt(i,:) = TailsOpt;
            
            disp(['Optimal lower tail cutoff: ',num2str(TailsOpt(1))]);
            disp(['Optimal upper tail cutoff: ',num2str(TailsOpt(2))]);
            
        end % OptimizeTailsCutoffs
        
        
        function FitCopulaAndSimulate(EVT)
            
            Y = EVT.X;
            ProbThreshold4MC = EVT.inputParams.ProbThreshold4MC;
            OBJ = EVT.parametrizedDistributions; % estimated parametric ot sempiparametric marginals
            corr_X = EVT.inputParams.corr_X;
            nsim = EVT.inputParams.nsim;
            
            U = zeros(size(Y)); % preallocation
            
            % from distributions to their grades (through CFD
            % transformations)
            nrserie = size(U,2);
            for i=1:nrserie
                U(:,i) = OBJ{i}.cdf(Y(:,i));
            end
            
            % remove zeros and ones (if any) from the grades
            f1 = find(U==1); U(f1) = 1-10e-10;
            f0 = find(U==0); U(f0) = 10e-10;
            
            options = statset('Display','final','TolX',1e-4,'UseParallel',true(1));
            
            % estimate copula parameters
            % try t-copula first, otherwise use Gaussian copula
            tcopula = EVT.inputParams.useTcopula;
            done = false(1);
            
            if isempty(corr_X)
                copulaType = ['T-copula'];
                while ~done
                    
                    if tcopula
                        try
                            U(isnan(U)) = 0.50;
                            U(U==1) = 0.99999999;
                            U(U==0) = 0.00000001;
                            disp(['t-Copula fitting started']);
                            tic
                            [rHot, Dof, CI] = ...
                                copulafit('t',U,'Method','ApproximateML','Options',options); % % for t copula
                            toc
                            disp(['Copula fitting done']);
                            u = copularnd('t',rHot,floor(Dof)+1,nsim);
                            EVT.CopulaParams.RHO = rHot;
                            EVT.CopulaParams.Dof = Dof;
                            EVT.CopulaParams.CI = CI;
                        catch ME
                            if tcopula & strcmp(ME.identifier,'stats:copulafit:RhoRankDeficient') ...
                                    | strcmp(ME.identifier,'stats:copulafit:DataOutOfRange')
                                disp('Copula not well defined');
                                disp(['Trying Gaussian instead of T copula']);
                                tcopula = false(1);
                            else
                                rethrow(ME);
                            end
                        end
                    end
                    
                    if ~tcopula
                        disp(['Gaussian Copula fitting started']);
                        tic
                        U(isnan(U)) = 0.50;
                        U(U==1) = 0.99999999;
                        U(U==0) = 0.00000001;
                        % estimate Gaussian copula
                        [rHot] = copulafit('Gaussian',U,'Options',options); % for Normal copula
                        toc
                        disp(['Copula fitting done']);
                        u = copularnd('gaussian',rHot,nsim);
                        copulaType = ['Gaussian-copula'];
                        EVT.CopulaParams.RHO = rHot;
                        EVT.CopulaParams.Dof = [];
                        EVT.CopulaParams.CI = [];
                    end
                    done = true(1);
                end % done
                
                
            else
                u = copularnd('gaussian',corr_X,nsim);
                EVT.CopulaParams.RHO = rHot;
                EVT.CopulaParams.Dof = [];
                EVT.CopulaParams.CI = [];
            end % if isempty(corr_X)
            
            
            for i=1:nrserie
                
                % LIMITING THE VARIABILITY OD SIMULATED OUTCOMES
                % (review and make more efficient the code below)
                tmp = OBJ{i}.icdf(u(:,i));
                
                if strcmp(EVT.inputParams.MCsimLimSetting,'absprob')
                    % eliminating simulated realizations with a probability less
                    % than 1 in 1/ProbThreshold4MC.
                    LimitRight = OBJ{i}.icdf(1-ProbThreshold4MC);
                    LimitLeft = OBJ{i}.icdf(ProbThreshold4MC);
                    tmp(tmp>LimitRight) = LimitRight;
                    tmp(tmp<LimitLeft) = LimitLeft;
                    
                elseif strcmp(EVT.inputParams.MCsimLimSetting,'none')
                    % do not impose limits on simulated outcomes
                end % if on MCsimLimSetting
                
                Simulated_X(:,i) = tmp;
            end
            
            if EVT.inputParams.toBeCentered
                Simulated_X = bsxfun(@plus, Simulated_X, EVT.mu_X); % new simulated 'X'
            end
            
            OUT{1} = mean(Simulated_X);
            OUT{2} = var(Simulated_X);
            OUT{3} = min(Simulated_X);
            OUT{4} = max(Simulated_X);
            
            EVT.Simulated_X = Simulated_X;
            EVT.OUT = OUT;
            EVT.copulaType = copulaType;
            
            
        end % FitCopulaAndSimulate
        
        function  Simulate(EVT)
            % to run a new simulation after all parameters have been
            % estimated (TO BE WRITTEN)
            
        end
        
    end % public methods
    
end % classdef


