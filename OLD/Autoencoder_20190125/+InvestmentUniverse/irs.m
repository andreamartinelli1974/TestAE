classdef irs < InvestmentUniverse.asset
    % subclass modeling IRS swaps (including cross currency swaps)
    
    % TODO: 04.11.2016: IMPORTANT: for now cross currency swaps cannot be
    % modeled through this class. The Cleg class is ready, but this 'irs' class, using Cleg
    % as a pricer is not and need to be further enhanced.
    
    properties
        % specific public properties
        pricerObj; % obj of class Cleg that I want to be able to change based on pricing needs (used within the 'Reprice' method)
        tenors_choice = 'tenors_yf'% % TODO: parametrize this choice
        
    end
    
    properties (SetAccess = immutable) % specific 'immutable' properties
        
        % struct array containing 1 sub-field for each curve needed for pricing
        % each sub-field contains an obj of class IR_Curve. The names of the
        % sub-fields will also be used as the names of the risk factors (used to identify the appropriate invariants
        % in the AA process when repricing). The last sub-field, when not
        % empty contains an FX curve. Not used for know, but if needed the
        % IR_Curve class can be adapted to contain an FX curve for now.
        % *** TODO ***: when
        % there is time create an abstract class, e.g. Curves, whose
        % implementations will be sub-classes like IR_Curve, CDS_Curve and
        % in this context create a new FX curve subclass.
        CurvesHistory;
        ConstantTenor = []; % will get a value only for swaps with constant time to maturity (this tenor will bhe held cobstant across time)
        FixedTenor = [] % will get a value only for swaps with a fixed, given tenor date
        StartDate = [];
        FixedMaturity = [];
        Specific_Attributes = []; % will hold specific attributes (derived from the instance of class Cleg used to instantiate this object
        isproxy  = []; % not used
        isRate = [];   % not used
        Notional; % this is the sum of all constituents' Notionals
      
    end
    
    methods
        
        function IRS = irs(asset_params,params)
            IRS = IRS@InvestmentUniverse.asset(asset_params);
            % input specific to the 'irs' subclass (under params. struct
            % array root):
            % .ZeroCurves: there must be one zero curve for each floating
            % leg (checks on this have been performed when inputting data)
            % .Tenor and  .StartDate are used (see comments below) to
            % define a swap with a constant time to maturity OR with a
            % given fixed expiry
            % .Notional, .ExchangeNotional, .LegType, .LegSide,
            % .LegRateSpread, .LegCurType, .LegFrequency, .LegAccrual,
            % .DiscountCurve MUST ALL HAVE a number of constituents equal
            % to the no of legs of the modeled swap
            
            % defining time to maturity features of the IRS: 2 options
            if ~isempty(params.Tenor) &  isempty(params.StartDate)
                % 1)the Tenor is given while the StartDate is empty: this is an
                % IRS with a constant time to maturity, that will be held
                % constant over time
                IRS.ConstantTenor = params.Tenor;
                IRS.StartDate = [];
            elseif ~isempty(params.Tenor) &  ~isempty(params.StartDate)
                % 2)the Tenor and the StartDate are both given: this is an IRS with
                % a given maturity date. So it's time to maturity will go down
                % with time
                IRS.FixedTenor = params.Tenor;
                IRS.StartDate = params.StartDate;
                % in this case a fixed maturity can be calculated
                IRS.FixedMaturity = params.StartDate + params.Tenor.*365;
            else
                disp('Combination of Tenor/StartDate not acceptable - execution terminated');
                return;
            end
            
            % assigning main properties needed by the pricer:
            
            IRS.CurvesHistory = params.Curves4ccySwap;
            IRS.Specific_Attributes.LegFreq = params.LegFrequency;
            % **** the following 4 fields define the
            IRS.Specific_Attributes.LegSide = params.LegSide;
            IRS.Specific_Attributes.LegType = params.LegType;
            % ****
            IRS.Specific_Attributes.DealtFx = params.DealtFx;
            IRS.Specific_Attributes.Notional = params.Notional;
            IRS.Specific_Attributes.LegRateSpread = params.LegRateSpread;
            %             IRS.Specific_Attributes.LegMonthLag = params.LegMonthLag;
            IRS.Specific_Attributes.DiscountCurves = params.DiscountCurve;
            IRS.Specific_Attributes.ForwardCurves = params.ForwardCurve;
            IRS.Specific_Attributes.LegCurType = params.LegCurType;
            IRS.Specific_Attributes.FixingCurves = params.FixingCurve;
            
            % 'generic' assets' info that it was not possible to assign
            % within mother class 'asset'
            IRS.Reference_Info.name{1} = asset_params.ticker_BBG;
            IRS.Reference_Info.currency = params.DomesticCurrency;
            
            notionals = cell2mat(params.Notional');     % put the ‘ after Notional it was not there. 
            if ~isnumeric(notionals)
                notionals = str2num(notionals);
            end

            IRS.Notional = sum(notionals);
            
            % names and nature (as the field name, e.g. 'YTM' or 'ZeroRate') of the
            % underlying risk factors used for pricing. This names will be
            % used to identify the appropriate invariants when repricing at
            % the investment horizon in the AA process
            nc = numel(params.Curves4ccySwap.ZeroCurves);
            for k=1:nc
                if iscell((params.Curves4ccySwap.ZeroCurves{k}.Name))    
                    curveName = params.Curves4ccySwap.ZeroCurves{k}.Name{1};
                else
                    curveName = params.Curves4ccySwap.ZeroCurves{k}.Name;
                end
                IRS.Risk_Factors_Names.ZeroRate.(curveName) = curveName ;
               
            end
            
            
            % building an instance of class Cleg that will be used for
            % repricing over the historical window and/or at the investment
            % horizons (after changing the fields relevant to each specific pricing)
            % All curves data parameters are set to [] to create the initial
            % instance. The same for TradeDate parameter
            FX_CURVE = [];
            ZERO_CURVE_DOM = [];
            DC_CURVE_DOM = [];
            ZERO_CURVE_FOR = [];
            DC_CURVE_FOR = [];
            TRADE_DATE = [];
            ACCRUAL_CURVE = [];
            % params.StartDate and params.Tenor are correctly assigned based on input params
            
            numswapinstr = length(params.Notional); %Count how many times we will call the Cleg Vec depending on how many notionals we entered.
            
            for i = 1:numswapinstr
                
                IRS.pricerObj{i} = Cleg_Vec_Scenarios(params.LegFrequency{2*i-1},params.LegFrequency{2*i},params.Tenor,params.LegType{2*i-1}, ...
                    params.LegSide{2*i-1},params.LegSide{2*i},params.LegType{2*i},FX_CURVE, ...
                    ZERO_CURVE_DOM,DC_CURVE_DOM,ZERO_CURVE_FOR,DC_CURVE_FOR,params.DealtFx,str2double(params.Notional{i}), ...
                    str2double(params.LegRateSpread{2*i-1}),str2double(params.LegRateSpread{2*i}),params.StartDate,TRADE_DATE, ...
                    params.LegCurType{2*i-1},params.LegCurType{2*i-1},params.LegCurType{2*i},params.LegAccrual{2*i-1},params.LegAccrual{2*i}, ...
                    params.ExchangeNotional{2*i-1},params.ExchangeNotional{2*i},ACCRUAL_CURVE);
                
            end
            
            
        end % constructor
        
        function Price2Invariants(IRS) % calculating invariants
            % for irs invariants are always external, so this methhod makes
            % no sense here
        end % Price2Invariants
        
        function output = Reprice(IRS,params)
            % this method will reprice the 'current instance' of the IRS
            % INPUTS (fields of struct array params):
            % .repricing_dt: date of repricing
            % .tradeDate: date as of which the IRS must be repriced: when
            % repricing using typeOfRepricing='Historical', repricing_dt and
            % tradeDate will be the same. When repricing using
            % typeOfRepricing='AtHorizon', instead, repricing_dt will be the
            % date of the optimization, while tradeDate will be the Horizon
            % date
            % .horizon_days: (when typeOfRepricing='AtHorizon')
            % investment horizon in days from the repricing_dt
            % .typeOfRepricing: = 'Historical' or 'AtHorizon': the former
            % is used to reprice the swap on one of the historical dates
            % for which we have a curve. The latter is used to reprice at a
            % future date based on a simulated curve
            % .numsim: no of simulated paths to the investment horizon
            % .er: struct array containing, for each curve, the simulated
            % projected zeros rates changes (for each pillar) at the
            % investment horizon
            % .zero0: struct array containing, for each curve, the initial
            % lavele (as of the optimization date) of the rates. Adding
            % this initial level to the simulated cumulated change over the
            % investment horizon (in .er) we get the projected distrib of
            % rates at the investment horizon
            % .p0: initial price (as of the optimization date) of the swap
            % NOTE on tradeDate: date as of which the IRS must be repriced: when
            % repricing using typeOfRepricing='Historical', repricing_dt and
            % tradeDate will be the same. When repricing using
            % typeOfRepricing='AtHorizon', instead, repricing_dt will be the
            % date of the optimization, while tradeDate will be the Horizon
            % date
            
            % OUTPUTS:
            % struct array output with sybfields:
            % .price: present value
            % .accrualsTot: tot accruals, both realized and unrealized
            
            NoOfSwaps = length(IRS.pricerObj); % Count how many objects are for pricing
            
            switch params.typeOfRepricing
                
                case 'Historical'
                    repricing_dt = params.repricing_dt;
                    tradeDate = repricing_dt;
                    nLegs = length(IRS.Specific_Attributes.LegType);
                    
                    % TODO: 'double loops below are probably not strictly
                    % necessary, but it would be necessary to re-write the
                    % input structure to remove the 'ZeroCurves' field and
                    % determine the intersection between Fwd curves and
                    % Disc Curves programatically (email sent to Panos on
                    % this)
                    
                    % processing IRS.CurvesHistory
                    % here I need to do 2 things:
                    % 1) getting the curves in the format required from
                    % class Cleg_Vec
                    % 2) derive a 'fictious' (all ones) FX curve when it is not
                    % provided (for swaps that are not cross currency)
                    Ld = length(IRS.Specific_Attributes.DiscountCurves);
                    Lf = length(IRS.Specific_Attributes.ForwardCurves);
                    
                    % preallocation
                    temp(max([Ld,Lf,nLegs])).ZeroCurves = [];
                    temp(max([Ld,Lf,nLegs])).ZeroCurveFor = [];
                    
                    for discrefi = 1: length(IRS.CurvesHistory.ZeroCurves)
                        % Assigning Discounting Curves
                        for discrefj = 1 : Ld
                            if strcmp(IRS.CurvesHistory.ZeroCurves{discrefi}.CurveID, IRS.Specific_Attributes.DiscountCurves{discrefj} ) ==  1
                                temp(discrefj).ZeroCurves = IRS.CurvesHistory.ZeroCurves{discrefi}; % Discounting curves
                            else
                                
                            end
                        end
                        
                        % Assigning Forwarding Curves
                        for discrefj = 1 : Lf
                            if strcmp(IRS.CurvesHistory.ZeroCurves{discrefi}.CurveID, IRS.Specific_Attributes.ForwardCurves{discrefj} ) ==  1
                                for countlegs = 1: nLegs   % Check which of the two legs is floating so that i assign only one curve. pb 22/12/2016.
                                    if strcmp(IRS.Specific_Attributes.LegType(countlegs) , 'Float') == 1
                                        temp(countlegs).ZeroCurveFor = IRS.CurvesHistory.ZeroCurves{discrefi}; % Discounting curves
                                    else
                                        temp(countlegs).ZeroCurveFor = [];
                                    end
                                end
                            else
                                
                            end
                        end
                    end % FOR discrefi
                    
                    temp(1).FxCurve = IRS.CurvesHistory.FxCurve; % temp, waiting to implement ccy swaps
                    
                    %% For every object in the deal
                    % remember that by construction a multiple leg swaps
                    % (more than 2 legs) is broken down into a series of
                    % swaps each one having 2 legs
                    
                    
                    IRS_PV_temp = zeros(NoOfSwaps,3);
                    IRS_Accruals_temp = zeros(NoOfSwaps,3);
                    
                    firstleg = 0;
                    for subswapnum =1 : NoOfSwaps
                        
                        %Choose the curves to work with
                        curves4Cleg1 = IRS.GetCurveAsOfDate(temp(subswapnum*2-1),repricing_dt); % Leg1 at date Curves for swap in counter subswapnum!
                        curves4Cleg2 = IRS.GetCurveAsOfDate(temp(subswapnum*2),repricing_dt); % Leg2 at date Curves for swap in counter subswapnum!
                        
                        if isempty(curves4Cleg1) | isempty(curves4Cleg2)
                            % if curves4Cleg1 or curves4Cleg2 is empty it
                            % means that there are no curve's data for the
                            % current date. Pricing cannot be performed
                            output.PV = [];
                            return;
                        end
                        
                        DcCurveDom = curves4Cleg1.ZeroCurves.curveAtDate;
                        DcCurveFor = curves4Cleg2.ZeroCurves.curveAtDate;
                        % changing the properties of the 'IRS pricer'
                        % object to price 'this' instance of irs class
                        % IRS.pricerObj.pTradeDate = tradeDate;
                        IRS.pricerObj{subswapnum}.pFxCurve = curves4Cleg1.FxCurve.curveAtDate;
                        
                        % Try to assign a curveAtDate if exists otherwise
                        % it does not exist because it is a fixed leg. ALso
                        % assign fixing Curve.
                        
                        % First leg
                        try
                            % Assign forwarding Curve.
                            IRS.pricerObj{subswapnum}.pFwdCurveDom = curves4Cleg1.ZeroCurveFor.curveAtDate;
                            
                        catch
                            % If it does not exist assign the discounting
                            % curve for reference.
                            IRS.pricerObj{subswapnum}.pFwdCurveDom = curves4Cleg1.ZeroCurves.curveAtDate;
                        end
                        
                        % Second leg
                        try
                            % Assign forwarding Curve.
                            IRS.pricerObj{subswapnum}.pFwdCurveFor = curves4Cleg2.ZeroCurveFor.curveAtDate;
                            
                        catch
                            % If it does not exist assign the discounting
                            % curve for reference.
                            IRS.pricerObj{subswapnum}.pFwdCurveFor = curves4Cleg2.ZeroCurves.curveAtDate;
                        end
                        
                        % TODO:
                        % Do the logical test my dear friend Gianpiero
                        % wants. 8-)
                        %                         if ~isempty((curves4Cleg1.ZeroCurveFor)) % it is a cross currency swap
                        %                             IRS.pricerObj{subswapnum}.pFwdCurveFor = curves4Cleg.ZeroCurveFor.curveAtDate;
                        %                             DcCurveFor = curves4Cleg.ZeroCurveFor.curveAtDate;
                        %                         else % it is not a cross currency swap
                        % %                             IRS.pricerObj{subswapnum}.pFwdCurveFor = curves4Cleg.ZeroCurves.curveAtDate;
                        % %                             DcCurveFor = DcCurveDom;
                        %                         end
                        IRS.pricerObj{subswapnum}.pDcCurveDom = DcCurveDom;
                        IRS.pricerObj{subswapnum}.pDcCurveFor = DcCurveFor;
                        
                        % changing the properties of the 'IRS pricer'
                        % object to price 'this' instance of irs class
                        IRS.pricerObj{subswapnum}.pTradeDate = tradeDate;
                        
                        %------ Accruals Index Assignment ---------23/12/2016
                        if strcmp(IRS.pricerObj{subswapnum}.pLeg1Type , 'Float' ) == 1
                            fixindex1 = IRS.Specific_Attributes.FixingCurves{subswapnum};
                            IRS.pricerObj{subswapnum}.pIndices.Leg1 =[IRS.External_RF.RF(find(strcmp({IRS.External_RF.RF.ObjName}, fixindex1)==1)).Invariants.Dates, ...
                                100* IRS.External_RF.RF(find(strcmp({IRS.External_RF.RF.ObjName}, fixindex1)==1)).Invariants.Prices]; % For first leg Accruals
                            firstleg = firstleg+1; %Flag to be used for second leg.
                            lengthofdates = length(IRS.External_RF.RF(find(strcmp({IRS.External_RF.RF.ObjName}, fixindex1)==1)).Invariants.Dates);
                            IRS.pricerObj{subswapnum}.pIndices.FX =[IRS.External_RF.RF(find(strcmp({IRS.External_RF.RF.ObjName}, fixindex1)==1)).Invariants.Dates, ...
                                ones(lengthofdates,1)];
                        else
                            IRS.pricerObj{subswapnum}.pIndices.Leg1 = [];
                        end
                        if strcmp(IRS.pricerObj{subswapnum}.pLeg2Type , 'Float' ) ==1
                            
                            fixindex2 = IRS.Specific_Attributes.FixingCurves{subswapnum + firstleg};
                            IRS.pricerObj{subswapnum}.pIndices.Leg2 = [IRS.External_RF.RF(find(strcmp({IRS.External_RF.RF.ObjName}, fixindex2)==1)).Invariants.Dates, ...
                                100* IRS.External_RF.RF(find(strcmp({IRS.External_RF.RF.ObjName}, fixindex2)==1)).Invariants.Prices]; % For first leg Accruals
                            lengthofdates = length(IRS.External_RF.RF(find(strcmp({IRS.External_RF.RF.ObjName}, fixindex2)==1)).Invariants.Dates);
                            IRS.pricerObj{subswapnum}.pIndices.FX =[IRS.External_RF.RF(find(strcmp({IRS.External_RF.RF.ObjName}, fixindex2)==1)).Invariants.Dates, ...
                                ones(lengthofdates,1)];
                        else
                            IRS.pricerObj{subswapnum}.pIndices.Leg2 = [];
                        end
                        
                        
                        %------ Accruals Index Assignment ---------.
                        
                        if ~isempty(IRS.ConstantTenor) & isempty(IRS.FixedTenor) % if this is a constant tenor IRS
                            % if the ConstantTenor has been set it means
                            % that this is an IRS with a constant time
                            % to maturity: the start date has to be
                            % determined based on the trade date (=
                            % date of pricing) and the constant Tenor
                            % It is set adding 'pLeg1MonthLag' months
                            % to the trade date
                            % TODO: using 30 days per month now: see if
                            % it is appropriate to improve this:
                            % probably gains in precision would not be
                            % relevant in this context
                            IRS.pricerObj{subswapnum}.pStartDate = tradeDate + 2;
                            
                        elseif ~isempty(IRS.FixedTenor) & isempty(IRS.ConstantTenor) % if this is a fixed maturity IRS
                            % in this case it will suffice to reprice
                            % the IRS based on a new trade date (the
                            % current pricing date), since both start
                            % date and tenor have been assigned when
                            % the object was built and will never
                            % change
                            
                            % TODO: CHECK THIS
                        end
                        
                        
                        % Cashflows Calculation
                        % PV with repricing
                        IRS.pricerObj{subswapnum}.CrossCurrencyPV;
                        % Accruals Calculations
                        IRS.pricerObj{subswapnum}.Accruals;
                        
                        % below I am assuming that
                        % IRS.pricerObj{subswapnum}.pCrossCurrencyValue is
                        % a 'dirty' PV, incorporating unrealized accruals
                        
                        % keep track of the PV for each IRS's constituent
                        IRS_PV_temp(subswapnum,:) = IRS.pricerObj{subswapnum}.pCrossCurrencyValue;
                                               
                       %   IRS_Accruals_temp(subswapnum,:) = IRS.pricerObj{subswapnum}.pCrossCurrencyRealizedAndUnrealizedAccrualsValue;
                       IRS_Accruals_temp(subswapnum,:) = IRS.pricerObj{subswapnum}.pCrossCurrencyAccrualsValue; % 
                        
                    end % for every irs constituent
                    
                    clear temp;
                    
                    % tot PV and accruals from all IRS constituents (not
                    % used for now - 19012017)
                    PV = sum(IRS_PV_temp(:,1)); 
                    accrualsTot = sum(IRS_Accruals_temp(:,1)); 
%                         disp(accrualsTot)              
                    % final output
                    output.PV =  PV;
                    output.accrualsTot =  accrualsTot;
                    % -->>  computing the price of the IRS as a whole
                    %       (including all of its constituents 
                    output.PriceTotReturn = (IRS.Notional + PV + accrualsTot)./IRS.Notional;
                    
                case 'AtHorizon'
                    disp('Repricing IRS at Horizon');
                    price = zeros(1,params.numsim); % preallocating output
                    repricing_dt = params.repricing_dt;
                    tradeDate = repricing_dt + params.horizon_days;
                    
                    % here I need to 'mimic' what's done above for
                    % pricing over history w.r.t. retrieving a curve as of
                    % the tradeDate (that in this case is the Horizon date)
                    % to this purpose I need to 'manipulate' a little the
                    % information that I have in params.zero0 and params.er
                    % (that ideally  is the same info that I have in IRS.CurvesHistory
                    % above when using 'Reprice' for historical pricing) so
                    % that it can be given to IRS.GetCurveAsOfDate as an
                    % input
                    
                    % ****************************************************
                    fnames = fieldnames(params.zero0);
                    nf = numel(fnames); % number of curves for which 'current date' (optim date) prices are held in params.zero0
                    Ld = length(IRS.Specific_Attributes.DiscountCurves);
                    Lf = length(IRS.Specific_Attributes.ForwardCurves);
                    
                    tic
                    clear temp;
                    % preallocation
                    % temp(max(Ld,Lf)).ZeroCurves = [];
                    % temp(max(Ld,Lf)).ZeroCurveFor = [];
                    
% PANOS START NEW  
                
                for subswapnum =1 : NoOfSwaps % for each one of the IRS constituents
                        IRS_PV_temp = zeros(params.numsim,NoOfSwaps);
                        IRS_Accruals_temp = zeros(params.numsim,NoOfSwaps);
                        firstleg = 0;
                        DcCurveDom = 0; % Cleaning the Discounting curves
                        DcCurveFor = 0;
                 
                    %--------------------------------
                        
                        simNo=1:params.numsim ;
%                                ***** ASSIGNING CURVES *****
                        for discrefi = 1: nf
%                             Assigning Discounting Curves
                            for discrefj = 1 : Ld
%                                 NOTE: here I need to reproduce the same
%                                 structure  of an obj with fields .rates,
%                                 .dates and .tenors_yf that is thypical of
%                                 the field Curve of objects of class
%                                 IR_Curve
                                if strcmp(fnames{discrefi}, IRS.Specific_Attributes.DiscountCurves{discrefj} ) ==  1
                                    temp(discrefj).ZeroCurves.Curve.dates = tradeDate;
                                    temp(discrefj).ZeroCurves.Curve.rates = repmat(params.zero0.(fnames{discrefi}).rates,params.numsim,1)  ...
                                        +  params.er.(fnames{discrefi}).rates(simNo,:); % simulated rates at horizon for simulated path simNo
                                    temp(discrefj).ZeroCurves.Curve.tenors_yf = params.zero0.(fnames{discrefi}).maturity_yf;
                                else
                                    
                                end
                            end
                            
%                             Assigning Forwarding Curves
                            for discrefj = 1 : Lf
                                if strcmp(fnames{discrefi}, IRS.Specific_Attributes.ForwardCurves{discrefj} ) ==  1
                                    for countlegs = 1: length(IRS.Specific_Attributes.LegType)    % Check which of the two legs is floating so that i assign only one curve. pb 22/12/2016.
 
                                        switch lower(IRS.Specific_Attributes.LegType{countlegs})
                                            case 'float'
                                            temp(countlegs).ZeroCurveFor.Curve.dates = tradeDate;
                                            temp(countlegs).ZeroCurveFor.Curve.rates = repmat(params.zero0.(fnames{discrefi}).rates,params.numsim,1)  ...
                                                +  params.er.(fnames{discrefi}).rates(simNo,:); % simulated rates at horizon for simulated path simNo
                                            temp(countlegs).ZeroCurveFor.Curve.tenors_yf = params.zero0.(fnames{discrefi}).maturity_yf;
                                            otherwise 
                                            temp(countlegs).ZeroCurveFor = [];
                                        end
                                    end
                                else
                                    
                                end
                            end
                            
                        end % FOR discrefi
                        
                        temp(1).FxCurve = IRS.CurvesHistory.FxCurve; % temp, waiting to implement ccy swaps                       
                        
%                         ****************************
%                         Choose the curves to work with
                            curves4Cleg1 = IRS.GetCurveAsOfDateExtended(temp(subswapnum*2-1),tradeDate); % Leg1 at date Curves for swap in counter subswapnum!
                            curves4Cleg2 = IRS.GetCurveAsOfDateExtended(temp(subswapnum*2),tradeDate); % Leg2 at date Curves for swap in counter subswapnum!
                             
                                DcCurveDom  = curves4Cleg1.ZeroCurves.curveAtDate(:,1:end);
                                DcCurveFor  = curves4Cleg2.ZeroCurves.curveAtDate(:,1:end);
                            
%                             changing the properties of the 'IRS pricer'
%                             object to price 'this' instance of irs class
%                             IRS.pricerObj.pTradeDate = tradeDate;
                            IRS.pricerObj{subswapnum}.pFxCurve = curves4Cleg1.FxCurve.curveAtDate;
                            
%                             Try to assign a curveAtDate if exists otherwise
%                             it does not exist because it is a fixed leg. ALso
%                             assign fixing Curve.
%                             Preallocate space.
 
                             if isempty(curves4Cleg1.ZeroCurveFor) ~= 1 
%                                 Assign forwarding Curve.
                                IRS.pricerObj{subswapnum}.pFwdCurveDom = curves4Cleg1.ZeroCurveFor.curveAtDate(:,1:end);
                                
                             else
%                                 If it does not exist assign the discounting
%                                 curve for reference.
                                IRS.pricerObj{subswapnum}.pFwdCurveDom = curves4Cleg1.ZeroCurves.curveAtDate(:,1:end);
                              end
%                             Second leg
                             try
%                                 Assign forwarding Curve.
                                IRS.pricerObj{subswapnum}.pFwdCurveFor = curves4Cleg2.ZeroCurveFor.curveAtDate(:,1:end);
                                
                             catch
%                                 If it does not exist assign the discounting
%                                 curve for reference.
                                IRS.pricerObj{subswapnum}.pFwdCurveFor = curves4Cleg2.ZeroCurves.curveAtDate(:,1:end);
                             end
                                
% %                   end
                            
                            
%                             changing the properties of the 'IRS pricer'
%                             object to price 'this' instance of irs class
                            IRS.pricerObj{subswapnum}.pTradeDate = tradeDate;
                            
                        %--------------------------------
                          
                        % After all scenarios are gathered we can assign Discounting
                        % Curves
                        IRS.pricerObj{subswapnum}.pDcCurveDom = DcCurveDom;
                        IRS.pricerObj{subswapnum}.pDcCurveFor = DcCurveFor;
                        
                        %------Accruals Index Assignment 12/01/2017
                            if strcmp(IRS.pricerObj{subswapnum}.pLeg1Type , 'Float' ) == 1
                                fixindex1 = IRS.Specific_Attributes.FixingCurves{subswapnum};
                                % x Panos: I have removed the switch as it
                                % should be maintained by adding curves.
                                % Moreover it is not absolutely guaranteed
                                % that a single index corresponds to one
                                % curve only (we might decide to build a
                                % custom IRS).
                                % However the solution is very easy: we
                                % have the name of the index used for
                                % fixing corresponding to each curve that
                                % we use to derive the forward rates. It is
                                % in the "ForwardCurves" input field,
                                % where there should be a 1 to 1
                                % correspondence between the zero
                                % curves put in that fields and the fixing
                                % indices put in "FixingCurves" (see
                                % Investment_Universe.xls, .. I have added
                                % a comment there)
                                correspondingCurveName = IRS.Specific_Attributes.ForwardCurves{subswapnum};
                                
                                IRS.pricerObj{subswapnum}.pIndices.Leg1 =[IRS.External_RF.RF(find(strcmp({IRS.External_RF.RF.ObjName}, fixindex1)==1)).Invariants.Dates, ...
                                    100* IRS.External_RF.RF(find(strcmp({IRS.External_RF.RF.ObjName}, fixindex1)==1)).Invariants.Prices]; % For first leg Accruals

                                Correction_vec = [(repricing_dt+1:repricing_dt + params.horizon_days)', params.zero0.(correspondingCurveName).fixing_projections'];
                                
                                % Add it to the
                                % {IRS.pricerObj{subswapnum}.pIndices.Leg2} on the
                                % correct dates
                                
                                for y = 1:length(Correction_vec)
                                    % if the date in Correction_vec is
                                    % within the range of date for the
                                    % fixings rates being used
                                    if Correction_vec(y,1) < IRS.pricerObj{subswapnum}.pIndices.Leg1(end,1)
                                        INDX = find(IRS.pricerObj{subswapnum}.pIndices.Leg1(:,1) == Correction_vec(y,1));
                                        IRS.pricerObj{subswapnum}.pIndices.Leg1(INDX,2) = 100*Correction_vec(y,2);
                                    else
                                        % adding 'future' rates
                                        IRS.pricerObj{subswapnum}.pIndices.Leg1 = [IRS.pricerObj{subswapnum}.pIndices.Leg1;[Correction_vec(y,1) 100*Correction_vec(y,2)]];
                                    end
                                end
             
                                firstleg = firstleg+1; % Flag to be used for second leg.
                                lengthofdates = length(IRS.External_RF.RF(find(strcmp({IRS.External_RF.RF.ObjName}, fixindex1)==1)).Invariants.Dates);
                                IRS.pricerObj{subswapnum}.pIndices.FX =[IRS.External_RF.RF(find(strcmp({IRS.External_RF.RF.ObjName}, fixindex1)==1)).Invariants.Dates, ...
                                    ones(lengthofdates,1)];
                            else
                                IRS.pricerObj{subswapnum}.pIndices.Leg1 = [];
                            end
                            if strcmp(IRS.pricerObj{subswapnum}.pLeg2Type , 'Float' ) ==1
                                
                                fixindex2 = IRS.Specific_Attributes.FixingCurves{subswapnum + firstleg};
                                correspondingCurveName = IRS.Specific_Attributes.ForwardCurves{subswapnum + firstleg};
                                
                                IRS.pricerObj{subswapnum}.pIndices.Leg2 = [IRS.External_RF.RF(find(strcmp({IRS.External_RF.RF.ObjName}, fixindex2)==1)).Invariants.Dates, ...
                                    100* IRS.External_RF.RF(find(strcmp({IRS.External_RF.RF.ObjName}, fixindex2)==1)).Invariants.Prices]; % For first leg Accruals

                                Correction_vec = [(repricing_dt+1:repricing_dt+ params.horizon_days)', params.zero0.(correspondingCurveName).fixing_projections'];
                                
                                % Add it to the
                                % {IRS.pricerObj{subswapnum}.pIndices.Leg2} on the
                                % correct dates
                                % *** XPanos. THIS MUST BE REVIEWED: SEE MY
                                % EMAIL (17012017). Its good -- Panos
                                for y = 1:size(Correction_vec,1)
                                    % if the date in Correction_vec is
                                    % within the range of date for the
                                    % fixings rates being used
                                    if Correction_vec(y,1) < IRS.pricerObj{subswapnum}.pIndices.Leg2(end,1)
                                        INDX = find(IRS.pricerObj{subswapnum}.pIndices.Leg2(:,1) == Correction_vec(y,1));
                                        IRS.pricerObj{subswapnum}.pIndices.Leg2(INDX,2) = 100*Correction_vec(y,2);
                                    else
                                        % adding 'future' rates
                                        IRS.pricerObj{subswapnum}.pIndices.Leg2 = [IRS.pricerObj{subswapnum}.pIndices.Leg2;[Correction_vec(y,1) 100*Correction_vec(y,2)]];
                                    end

                                end
                                
                                %-----------------------------
                                lengthofdates = length(IRS.External_RF.RF(find(strcmp({IRS.External_RF.RF.ObjName}, fixindex2)==1)).Invariants.Dates);
                                IRS.pricerObj{subswapnum}.pIndices.FX =[IRS.External_RF.RF(find(strcmp({IRS.External_RF.RF.ObjName}, fixindex2)==1)).Invariants.Dates, ...
                                    ones(lengthofdates,1)];
                            else
                                IRS.pricerObj{subswapnum}.pIndices.Leg2 = [];
                            end
                            
                            %------ Accruals Index Assignment ---------.
                            if ~isempty(IRS.ConstantTenor) & isempty(IRS.FixedTenor) % if this is a constant tenor IRS
                                % if the ConstantTenor has been set it means
                                % that this is an IRS with a constant time
                                % to maturity: the start date has to be
                                % determined based on the trade date (=
                                % date of pricing) and the constant Tenor
                                % It is set adding 'pLeg1MonthLag' months
                                % to the trade date
                                % TODO: using 30 days per month now: see if
                                % it is appropriate to improve this:
                                % probably gains in precision would not be
                                % relevant in this context
                                IRS.pricerObj{subswapnum}.pStartDate = tradeDate + 2;
                                
                            elseif ~isempty(IRS.FixedTenor) & isempty(IRS.ConstantTenor) % if this is a fixed maturity IRS
                                % in this case it will suffice to reprice
                                % the IRS based on a new trade date (the
                                % current pricing date), since both start
                                % date and tenor have been assigned when
                                % the object was built and will never
                                % change
                                
                                % TODO: CHECK THIS
                            end
                            
                            % Cashflows Calculation
                            % PV with repricing
                            
                            IRS.pricerObj{subswapnum}.CrossCurrencyPV;
                            
                            IRS.pricerObj{subswapnum}.Accruals;
                            % Accruals Calculations
                       
                            % keep track of the PV for each IRS's constituent
                            IRS_PV_temp(:,subswapnum) = IRS.pricerObj{subswapnum}.pCrossCurrencyValue(:,1);
                                               
                          %   IRS_Accruals_temp(subswapnum,:) = IRS.pricerObj{subswapnum}.pCrossCurrencyRealizedAndUnrealizedAccrualsValue;
                            IRS_Accruals_temp(:,subswapnum) = IRS.pricerObj{subswapnum}.pCrossCurrencyAccrualsValue(:,1); % 
                          end  
                        % tot PV and accruals from all IRS constituents (not
                        % used for now - 19012017)
                        PV = sum(IRS_PV_temp,2);
                        accrualsTot = sum(IRS_Accruals_temp,2);
%                         disp(accrualsTot) 
                        % final output
                        output.PV(1,:) =  PV;
                        output.accrualsTot(1,:) =  accrualsTot;
                        output.PriceTotReturn(1,:) = (IRS.Notional + PV + accrualsTot)./IRS.Notional;
                    
 % PANOS END NEW                   
 
            end % switch on repricing type
            
        end % Reprice
        
    end % methods
    
    methods (Static)
        function currentCurves = GetCurveAsOfDate(CurvesTimeSeries,current_dt)
            % getting hist curve infos in the form required by class CLeg
            % (that is a Tx2 matrix of fwd dates and % rates) as of date 'current_dt'
            % INPUTS:
            % -> CurvesTimeSeries: a struct array whose subfields are obj having the
            % structure of objects of class IR_Curve, or having at least
            % the fields used below: .dates, .tenors_yf, .rates
            % -> current_dt: 'the current date' (in Matlab date no format)
            
            % UPDATE: 24.11.16: this method will be called not only for
            % pricing over history, but also to price at investment Horizon
            % (method Reprice). In the latter case the TimeSeries will
            % contain only one date (the horizon date)
            
            crvtypes = fieldnames(CurvesTimeSeries); % curves types (fwd domestic, fx, ..)
            ntypes = numel(crvtypes);
            for c=1:ntypes
                if ~isempty(CurvesTimeSeries.(crvtypes{c}))
                    dates = CurvesTimeSeries.(crvtypes{c}).Curve.dates;
                    tenors_yf = CurvesTimeSeries.(crvtypes{c}).Curve.tenors_yf;
                    % looking for curve's quotes for the
                    % date 'current_dt'
                    fd = find(dates == current_dt);
                    
                    if isempty(fd)
                        % if there are no curve data for the current date
                        % then control must be given back to the program
                        % calling the Reprice function and the absence of
                        % price must be managed there 
                        currentCurves = [];
                        return;
                    end
                    
                    % here I need to convert maturities
                    % expressed as year fractions into
                    % dates, starting from the 'current
                    % date'. TODO: see if appropriate
                    % to model different yf
                    % conventions. Currently using
                    % tenors_tf, based on a 365 days
                    % year
                    yf2noOfdays = tenors_yf*365; % year fraction into days
                    currentCurves.(crvtypes{c}).curveAtDate(:,1) = current_dt + yf2noOfdays; % maturities as dates
                    currentCurves.(crvtypes{c}).curveAtDate(:,2) = CurvesTimeSeries.(crvtypes{c}).Curve.rates(fd,:)'*100; % TODO: parametrize this '*100' by attaching a new field to all IR/CDS curves obj that specifies the format of the data (e.g. 'fraction', 'percent', 'bps')
                else
                    if strcmp(crvtypes{c},'FxCurve')
                        % if the FX curve field is
                        % empty then an artificial
                        % curve with all '1s' is used.
                        % This implies that we are not
                        % working on a cross currency
                        % swap. The no of points to be
                        % used is derived from the
                        % 'ZeroCurves' field (that
                        % must always be assigned and
                        % must precede the 'FxCurve' in
                        % the input struct array
                        % containing curves hist data
                        % (in params.Curves4ccySwap)
                        currentCurves.FxCurve.curveAtDate(:,1) = currentCurves.ZeroCurves.curveAtDate(:,1);
                        currentCurves.FxCurve.curveAtDate(:,2) = ones(size(currentCurves.ZeroCurves.curveAtDate(:,2),1),1);
                    else
                        currentCurves.ZeroCurveFor = [];
                    end
                end
            end % for loop on 'c'
            
        end % InputCurves2ClegFormat
        
        function currentCurves = GetCurveAsOfDateExtended(CurvesTimeSeries,current_dt)
            % getting hist curve infos in the form required by class CLeg
            % (that is a Tx2 matrix of fwd dates and % rates) as of date 'current_dt'
            % INPUTS:
            % -> CurvesTimeSeries: a struct array whose subfields are obj having the
            % structure of objects of class IR_Curve, or having at least
            % the fields used below: .dates, .tenors_yf, .rates
            % -> current_dt: 'the current date' (in Matlab date no format)
            
            % UPDATE: 24.11.16: this method will be called not only for
            % pricing over history, but also to price at investment Horizon
            % (method Reprice). In the latter case the TimeSeries will
            % contain only one date (the horizon date)
            
            crvtypes = fieldnames(CurvesTimeSeries); % curves types (fwd domestic, fx, ..)
            ntypes = numel(crvtypes);
            for c=1:ntypes
                if ~isempty(CurvesTimeSeries.(crvtypes{c}))
                    dates = CurvesTimeSeries.(crvtypes{c}).Curve.dates;
                    tenors_yf = CurvesTimeSeries.(crvtypes{c}).Curve.tenors_yf;
                    % looking for curve's quotes for the
                    % date 'current_dt'
                    fd = find(dates == current_dt);
                    
                    if isempty(fd)
                        % if there are no curve data for the current date
                        % then control must be given back to the program
                        % calling the Reprice function and the absence of
                        % price must be managed there 
                        currentCurves = [];
                        return;
                    end
                    
                    % here I need to convert maturities
                    % expressed as year fractions into
                    % dates, starting from the 'current
                    % date'. TODO: see if appropriate
                    % to model different yf
                    % conventions. Currently using
                    % tenors_tf, based on a 365 days
                    % year
                    yf2noOfdays = tenors_yf*365; % year fraction into days
                    currentCurves.(crvtypes{c}).curveAtDate(:,1) = current_dt + yf2noOfdays; % maturities as dates
                    currentCurves.(crvtypes{c}).curveAtDate(:,2:size(CurvesTimeSeries.(crvtypes{c}).Curve.rates(:,:)',2)+1) = CurvesTimeSeries.(crvtypes{c}).Curve.rates(:,:)'*100; % TODO: parametrize this '*100' by attaching a new field to all IR/CDS curves obj that specifies the format of the data (e.g. 'fraction', 'percent', 'bps')
                else
                    if strcmp(crvtypes{c},'FxCurve')
                        % if the FX curve field is
                        % empty then an artificial
                        % curve with all '1s' is used.
                        % This implies that we are not
                        % working on a cross currency
                        % swap. The no of points to be
                        % used is derived from the
                        % 'ZeroCurves' field (that
                        % must always be assigned and
                        % must precede the 'FxCurve' in
                        % the input struct array
                        % containing curves hist data
                        % (in params.Curves4ccySwap)
                        currentCurves.FxCurve.curveAtDate(:,1) = currentCurves.ZeroCurves.curveAtDate(:,1);
                        currentCurves.FxCurve.curveAtDate(:,2) = ones(size(currentCurves.ZeroCurves.curveAtDate(:,2),1),1);
                    else
                        currentCurves.ZeroCurveFor = [];
                    end
                end
            end % for loop on 'c'
            
        end % InputCurves2ClegFormat
    end % static methods
end

