classdef MBS < InvestmentUniverse.asset
    % subclass designed to model CLOs and RMBSs
    
    properties
       % X PANOS: let's pay attention to build these 2 properties in a way that is consistent
       % with how they are built within other asset sub-classes (e.g.
       % Option_Vanilla), since it is functional to adopting the same logic used so far when
       % doing At Horizon Pricing
       % Risk_Factors_Names;  % defined within the 'asset' superclass
       % Invariants;          % defined within the 'asset' superclass
       
    end
    
    properties (SetAccess = immutable)
        % MBS subclass specific properties
        Specific_Attributes = []; % X PANOS: here you will find Bloomberg static data specific to each tranche
        TranchesList; % list of tranches 'names'
        TranchesNo; % number of tranches
        OurTranche; % infos specific to our tranche (the MBS we are modeling)
        % X PANOS: this property will host the instance of class SABR and
        % the simulated IR paths
        SABR_obj; 
    end
    
    methods
        function M = MBS(asset_params,MBS_params) % constructor
            M = M@InvestmentUniverse.asset(asset_params);
            % asset_params: see notes in asset.m
            % MBS subclass specific inputs: structured array MBS_params
            % with fields:
            % -> tranchesList: must be a cell array containing a list of
            % tranches'names (e.g. {'A1','A2'}). This list will be used to
            % get Bloomberg data for each tranche and to differentiate
            % between tranches for pricing, simulations, etc.
            % ->
            
            M.TranchesList = MBS_params.tranchesList;
            M.TranchesNo = numel(M.TranchesList);
            
            OurTranche.ISIN = MBS_params.ourTrancheISIN;
            OurTranche.trancheID = MBS_params.ourTranche;
            tmp = split(asset_params.ticker_BBG,' Mtge');
            root_ticker = tmp{1};
            OurTranche.ticker = [tmp{1},' ',OurTranche.trancheID,' Mtge'];
            M.OurTranche = OurTranche;
            
            % getting Bloomberg static data through an instance
            % of class Utility for each tranche
            uparam.DataFromBBG = asset_params.DataFromBBG;
            uparam.ticker = asset_params.ticker_BBG;
            uparam.override_fields = [];
            uparam.override_values = [];
            
            for k=1:M.TranchesNo
                uparam.ticker = [root_ticker,' ',M.TranchesList{k},' Mtge'];
                uparam.fields = {'ISSUER','CPN','CPN_TYP','CPN_FREQ','ISSUE_DT','MATURITY','MTG_WAM','MTG_WAL','COLLAT_TYP','CRNCY','MTG_DEAL_TYP', ...
                'SECURITY_TYP','MTG_PAY_DELAY','MTG_DEAL_ORIG_FACE','MTG_ORIG_AMT'};
                U = Utilities(uparam);
                U.GetBBG_StaticData;
                Specific_Attributes.Tranches.(M.TranchesList{k}) = U.Output.BBG_getdata;
                Specific_Attributes.Tranches.(M.TranchesList{k}).ticker = uparam.ticker; % specific ticker for the tranche
                
                % historical cashflows at tranches level
                uparam.fields = 'HIST_CASH_FLOW';
                uparam.override_fields = '';
                uparam.override_values = '';
                U = Utilities(uparam);
                U.GetBBG_StaticData;
                % put cashflows data in a cell array within the sub-struct
                % 'cashflow' for the k-th tranche identified by
                % 'TranchesList{k})'
                % => the columns of this cell array are the following:
                % -------------------------------------------------------------------------------
                % 'Period Number', 'Payment Date', 'Coupon', 'PrincipalPaid', 'Principal Balance'
                % -------------------------------------------------------------------------------
                Specific_Attributes.Tranches.(M.TranchesList{k}).cashflows = U.Output.BBG_getdata.HIST_CASH_FLOW{1, 1};
            end
            
            % assign specific properties from Bloomberg 
            M.Specific_Attributes = Specific_Attributes;
        end
        
        
        function opt_price = Reprice(M,params)
            disp('MBS repricing');
        end
        
    end % (public) methods
    
    methods (Static = true)
        
        
    end % (static) methods
    
end

