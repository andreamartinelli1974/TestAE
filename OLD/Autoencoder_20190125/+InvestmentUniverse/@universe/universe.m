classdef universe < handle
    % This class represents a set of investibale assets and has methods
    % necessary to define the Asset Allocation based on several
    % methodologies
    
    properties
        %this is a structured array whose fields are signals generated
        % through quant or other algos to drive the dynamic AA process
        Drivers = [];
        Assets = []; % vector of objects of any subclass of class 'asset' see method AddAsset
        % information on and set of all invariants: IMPORTANT
        % from method GetInvariants_EmpiricalDistribution
        % MAIN FIELDS:
        % 1) NamesSet: cell array containing the name of all invariants, in
        % the same order as they are stored in the matrix X (these are the
        % same names used within the .Invariants.Name field of each asset
        % and will be useful to rebuild the correspondence from invariant
        % ans assets for repricing). By construction single invariant are
        % not repeated
        % 2) X: this is a [JxK] matrix containing all the invariants,
        % where J is the the no of joint scenarios and K is the no of
        % invariants
        % 3) dates: the date vector corresponding to X
        AllInvariants = [];
        Horizon = []; % Investment Horizon (in years)
        Assets_Legend = [];
        Assets_Tickers;
        Strategies = [];
        Currencies = []; % vector of denomination currencies for each asset
        Debug = {};
        InternalInvariantsLastDate = {}; % property containing the latest date available for invariants (and hence for pricing) before merging them of a common set of dates (intersection)
        CountryStrategyInfo = {}; % containing the country & industry of the assets in the ptf
        AssetType = {}; % asset type (as specified in the input Investment_Universe.xls file
        IU; % struct array from ReadFromIU_inputFile (now used for reporting purposes only). It is used externally when invoking AddAsset. TODO: move AddAsset inside class universe.m
        ARMA_GARCH_filtering = [];
    end
    
    properties (Abstract = true)
    end
    
    properties (SetAccess = immutable) % solo il constructor può modificare queste proprietà
        ExternalRF = []; % this is an object of class External_Risk_Factors (see notes to the class)
        DataFromBBG = [];
        % dt = []; % time granularity in year fraction (eg 1/252 for a daily setting
        % containing all external risk factors that must be blended into
        % AllInvariants for risk estim and pricing purposes
        % Ndt = []; % no of time steps in one year
        Exceptions; % all excluded 'entities' (curves, assets, etc.) - see comments to Exceptions in the 'Main' code
    end
    
    properties (SetAccess = protected)
        ExchangeRates = []; % obj containing fts obj for all currencies in the set of currencies of denomination of the assets
        Errors; % used to track managed and unmanaged exceptions
    end
    
    methods
        function U = universe(name,DataFromBBG,extrf,IU,Exceptions) % constructor
            % name: name of the instance (a specific investable universe)
            % DataFromBBG: struct to get BBG data
            % extrf: obj of class Esternal_Risk_Factors
            % tmap: tenors map to reflect the constant tenors map
            % structure defined in class IR_Curve
            % IU: see comment above
            
            U.ExternalRF = extrf;
            U.Assets = [];
            U.DataFromBBG = DataFromBBG;
            U.IU = IU;
            U.Exceptions = Exceptions;
            
        end
        
        % declaring  public methods defined within @universe
        Dynamic_AA_1(obj,DAA_params,SubjectiveViews);
        AA_BackTest(obj,strategy,params);
            
        function AddAsset(U,NewAsset)
            % this method adds an asset (or a vector of assets) to the  investable universe
            % NewAsset: this must be an object of any subclass of class 'asset'
            
            % if the input is a vector or a matrix of assets, it is
            % 'linearized' into a column array of objects and then each
            % object is appended to the universe (Asset.value property)
            sz = size(NewAsset);
            total_size = prod(sz);
            NewAsset = reshape(NewAsset,total_size,1);
            
            for k=1:total_size
                asset_name = strrep(NewAsset(k,1).Reference_Info.name{1},' ','_');
                asset_ticker = NewAsset(k,1).Reference_Info.ticker_BBG;
                disp(['Adding to Universe asset: ',asset_name]);
                if isempty(U.Assets)
                    n = 0;
                else
                    n = size(U.Assets,1);
                end
                U.Assets(n+1,1).value = NewAsset(k,1);
                % only descriptions (for charting/informative purposes)
                U.Assets_Legend{n+1,1} = asset_name;
                U.Assets_Tickers{n+1,1} = asset_ticker;
                if isfield(NewAsset(k,1).AA_limits,'lb') & isfield(NewAsset(k,1).AA_limits,'ub') % check as there could be no weights
                    U.Assets_Legend{n+1,2} = NewAsset(k,1).AA_limits.lb;
                    U.Assets_Legend{n+1,3} = NewAsset(k,1).AA_limits.ub
                end
                U.Currencies{n+1,1} = (cell2mat(U.Assets(n+1).value.Reference_Info.currency));
            end
        end
        
        function GetInvariants_EmpiricalDistribution(U)
            % TODO: in general the following code tries to avoid
            % duplication of invariants within the final Invariant matrix.
            % However sometimes a given invariant may be repeated as it
            % comes from both internal and external invariants. This
            % shouldn'ìt be an issue. However, REVIEW the procedures used
            % to attribute names to invariants in the CDS curve builder (for external invariants)
            % and in the cds class (for internal invariants)
            
            U.AllInvariants.NamesSet={};
            InvariantsAndPricesCollections = [];
            
            cnt = 0;
            
            % *************************************************************
            % 'INTERNAL' Invariants: those provided directly when setting
            % up assets
            % *************************************************************
            for k=1:size(U.Assets,1) % cycling over all assets
                
                for j=1:size(U.Assets(k).value.Invariants,2) % cycling over invariants per each asset (an asset could have more invariants
                    
                    if ~U.Assets(k).value.Invariants(j).External4AtHorizonModeling % if the internal invariant has to be used
                        
                        
                        disp(['Setup of Internal Invariants: ',U.Assets(k).value.Invariants(j).Name]);
                        iA = ismember(U.AllInvariants.NamesSet,U.Assets(k).value.Invariants(j).Name);
                        if isempty(U.AllInvariants.NamesSet) | sum(iA)==0 % the invariant has not been considered yet
                            cnt = cnt + 1;
                            type = U.Assets(k).value.Invariants(j).Type;
                            name = U.Assets(k).value.Invariants(j).Name;
                            U.AllInvariants.NamesSet{cnt,1} = name;
                            U.AllInvariants.InvariantType{cnt,1} = type;
                            
                            % the 'equityAssetFlag' is essentially used to
                            % recognize invariants underlying 'equities'
                            % (e.g. stocks, stock indices, etc) that will
                            % be modeled through an asymmetric GARCH if the
                            % AR-GARCH option is used. 'equityAssetFlag' is
                            % given as an input by the user via the
                            % Investment_Universe file (column
                            % Asset_asset_type) and is used with
                            % internal invariants only (at least for
                            % now). For External invariants it is  always set
                            % to False
                            %                             if strcmp(U.Assets(k).value.AssetType,'equity') & strcmp(U.Assets(k).value.Invariants(j).Type,'Returns')
                            %                                 U.AllInvariants.equityAssetFlag{cnt,1} = true(1);
                            %                             else
                            %                                 U.AllInvariants.equityAssetFlag{cnt,1} = false(1);
                            %                             end
                            
                            % adding Invariants' prices: these are not
                            % necessarily the prices of the tradable assets in
                            % the Universe
                            
                            %                             % for CDS internal invariants need to take the 3rd
                            %                             % column of prices (based on roll adj cds history)
                            %                             % (for external invariants the choice is made when building the CDS curve obj)
                            %                             if strcmp(type,'CDS_changes')
                            %                                 colno = 2;
                            %                             else
                            %                                 colno = 2;
                            %                             end
                            colno = 2;
                            
                            % feeding InvariantsAndPricesCollections
                            % collections (vectors of cell array that will be used later to get
                            % datasets on a common set of dates)
                            % This is done for both returns and prices. The
                            % latter are not strictly necessary and are
                            % mainly used for debugging purposes
                            
                            InvariantsAndPricesCollections.Returns{cnt,1} = [U.Assets(k).value.Invariants(j).(type)(:,1),U.Assets(k).value.Invariants(j).(type)(:,2)];
                            InvariantsAndPricesCollections.Prices{cnt,1} = [U.Assets(k).value.Invariants(j).Prices(:,1),U.Assets(k).value.Invariants(j).Prices(:,colno)];
                            if isnan (InvariantsAndPricesCollections.Returns{1,1})
                                pause
                            end
                        end
                    end
                end % j-for (loop over invariants within asset)
            end % k-for (loop over assets)
            
            % ************************************************************
            % 'EXTERNAL' Invariants: those provided through an object of
            % *************************************************************
            % class External_Risk_Factors
            if  ~isempty(U.ExternalRF)
                
                nRF = size(U.ExternalRF.RF,1);
                for k=1:nRF % external factors datasets
                    
                    name_root = U.ExternalRF.RF(k).Name;
                    if iscell(name_root) == 1
                        name_root = name_root{1};
                    else
                    end
                    disp(['Setup of External Invariants: ',name_root, ' ',U.ExternalRF.RF(k).Invariants.Category]);
                    names = [];
                    
                    
                    if strcmp(U.ExternalRF.RF(k).Invariants.Category,'IR_Curve') ...
                            || strcmp(U.ExternalRF.RF(k).Invariants.Category,'CDS_Curve') ...
                            & U.ExternalRF.RF(k).ToBeIncludedInInvariants == 1
                        % IMPORTANT: the name convention used here is the
                        % same that must be used when locating invariants
                        % (e.g. for pricing purposes)
                        % for 'IR_Curve' object the name built from BBG
                        % ticker is used as a root. To this root a string
                        % representing the tenor is added for each tenor's
                        % timeseries
                        
                        % below I will use '.Tenors_yf' to label the
                        % timeseries corresponding to the various indices
                        
                        % this parameter is needed to locate the starting
                        % index to be used to define the limits of the
                        % dates vector for returns, since for some
                        % invariants (e.g. IR_Curves) returns vector has
                        % the same size as the price vector, while for
                        % other invariants (e.g. Single_Index type) the
                        % returns'timeseries is shorter
                        % TODO: adjthis and make the behaviour uniform
                        
                        startDateIdx4Returns = 1; % TODO: REMOVE (NJO MORE USED)
                        
                        for n=1:size(U.ExternalRF.RF(k).Tenors_yf,2) % single timeseries within the k-th dataset
                            
                            yf_label_numeric = U.ExternalRF.RF(k).Tenors_yf(n);
                            names{1,n} = [name_root,'_',U.yearFract2Label(yf_label_numeric)]; % '.' replaced to prevent problems when isung this name as a field name
                            
                            iA = ismember(U.AllInvariants.NamesSet,names{1,n});
                            if isempty(U.AllInvariants.NamesSet) | sum(iA)==0 % check that the invariant has not yet been picked up
                                cnt = cnt + 1; % continue counting after 'Internal Invariants' processing
                                type = U.ExternalRF.RF(k).Invariants.Type;
                                name = names{1,n};
                                U.AllInvariants.NamesSet{cnt,1} = name;
                                U.AllInvariants.InvariantType{cnt,1} = type;
                                
                                % the 'equityAssetFlag' is essentially used to
                                % recognize invariants underlying 'equities'
                                % (e.g. stocks, stock indices, etc) that will
                                % be modeled through an asymmetric GARCH if the
                                % AR-GARCH option is used. 'equityAssetFlag' is
                                % given as an input by the user via the
                                % Investment_Universe file (column
                                % Asset_asset_type) and is used with
                                % internal invariants only (at least for
                                % now). For External invariants it is  always set
                                % to False
                                %                                 U.AllInvariants.equityAssetFlag{cnt,1} = false(1);
                                
                                
                                dates = U.ExternalRF.RF(k).Invariants.Dates;
                                returns = U.ExternalRF.RF(k).Invariants.(type)(:,n);
                                prices = U.ExternalRF.RF(k).Invariants.Prices(:,n);
                                % removing NaNs
                                % TODO: IMPORTANT: REVIEW THIS AND
                                % CENTRALIZE ALL INTERPOLATIONS & DATA
                                % MANIPULATIONS LIKE THIS ONE
                                fn = find(isnan(returns));
                                if ~isempty(fn)
                                    returns(fn) = [];
                                    dates(fn) = [];
                                    prices(fn) = [];
                                end
                                
                                % feeding InvariantsAndPricesCollections collection
                                % (vectors of cell array that will be used later to get
                                % datasets on a common set of dates)
                                % This is done for both returns and prices. The
                                % latter are not strictly necessary and are
                                % mainly used for debugging purposes
                                InvariantsAndPricesCollections.Returns{cnt,1} = [dates(startDateIdx4Returns:end),returns];
                                InvariantsAndPricesCollections.Prices{cnt,1} = [dates,prices];
                                
                            end
                        end % no of single timeseries within the k-th dataset
                        
                    elseif strcmp(U.ExternalRF.RF(k).Invariants.Category,'Single_Index') ...
                            & U.ExternalRF.RF(k).ToBeIncludedInInvariants == 1
                        
                        startDateIdx4Returns = 1;
                        
                        names{1,1} = name_root;
                        iA = ismember(U.AllInvariants.NamesSet,names{1,1});
                        if isempty(U.AllInvariants.NamesSet) | sum(iA)==0
                            cnt = cnt + 1; % continue counting after 'Internal Invariants' processing
                            type = U.ExternalRF.RF(k).Invariants.Type;
                            name = names{1,1};
                            U.AllInvariants.NamesSet{cnt,1} = name;
                            U.AllInvariants.InvariantType{cnt,1} = type;
                            
                            % the 'equityAssetFlag' is essentially used to
                            % recognize invariants underlying 'equities'
                            % (e.g. stocks, stock indices, etc) that will
                            % be modeled through an asymmetric GARCH if the
                            % AR-GARCH option is used. 'equityAssetFlag' is
                            % given as an input by the user via the
                            % Investment_Universe file (column
                            % Asset_asset_type) and is used with
                            % internal invariants only (at least for
                            % now). For External invariants it is  always set
                            % to False
                            %                             U.AllInvariants.equityAssetFlag{cnt,1} = false(1);
                            
                            dates = U.ExternalRF.RF(k).Invariants.Dates;
                            returns = U.ExternalRF.RF(k).Invariants.(type)(:,1);
                            prices = U.ExternalRF.RF(k).Invariants.Prices(:,1);
                            % removing NaNs
                            % TODO: IMPORTANT: REVIEW THIS AND
                            % CENTRALIZE ALL INTERPOLATIONS & DATA
                            % MANIPULATIONS LIKE THIS ONE
                            fn = find(isnan(returns));
                            if ~isempty(fn)
                                returns(fn) = [];
                                dates(fn) = [];
                                prices(fn) = [];
                            end
                            
                            % feeding InvariantsAndPricesCollections collection (see
                            % comments above)
                            InvariantsAndPricesCollections.Returns{cnt,1} = [dates(startDateIdx4Returns:end),returns];
                            InvariantsAndPricesCollections.Prices{cnt,1} = [dates,prices];
                            
                        end
                        
                    elseif strcmp(U.ExternalRF.RF(k).Invariants.Category,'Vol_Curve') ...
                            & U.ExternalRF.RF(k).ToBeIncludedInInvariants == 1
                        
                        [x1, y1, z1] = size(U.ExternalRF.RF(k).Invariants.Tenor);
                        yf_term = reshape(U.ExternalRF.RF(k).Invariants.Tenor(:,:,1),1,x1*y1);
                        [x2, y2, z2] = size(U.ExternalRF.RF(k).Invariants.Moneyness);
                        moneyness_term = reshape(U.ExternalRF.RF(k).Invariants.Moneyness(:,:,1),1,x2*y2);
                        names = {};
                        names_cube = reshape([1:x1*y1] ,x1,y1); % Create coordinates for later reshape
                        % X Panos: this ensures that the same name used to
                        % identify the risk factor within the
                        % Option_Vanilla class instance is used here
                        for n = 1 : length(yf_term)
                            
                            name_root = regexprep(name_root,'[^\w'']','');
                            yf_term_tmp  = strrep(num2str(yf_term(1,n)),'.','dot');
                            moneyness_term_tmp  = strrep(num2str(moneyness_term(1,n)),'-','m'); % Replace Minus
                            moneyness_term_tmp  = strrep(moneyness_term_tmp,'.','dot'); % Replace Dot
                            
                            names(n) = {[name_root,'_',yf_term_tmp,'Y', '_', moneyness_term_tmp,'D']};
                            
                            iA = ismember(U.AllInvariants.NamesSet,names{1,n});
                            if isempty(U.AllInvariants.NamesSet) | sum(iA)==0 % check that the invariant has not yet been picked up
                                cnt = cnt + 1; % continue counting after 'Internal Invariants' processing
                                type = U.ExternalRF.RF(k).Invariants.Type;
                                name = names{1,n};
                                U.AllInvariants.NamesSet{cnt,1} = name;
                                U.AllInvariants.InvariantType{cnt,1} = type;
                                
                                % the 'equityAssetFlag' is essentially used to
                                % recognize invariants underlying 'equities'
                                % (e.g. stocks, stock indices, etc) that will
                                % be modeled through an asymmetric GARCH if the
                                % AR-GARCH option is used. 'equityAssetFlag' is
                                % given as an input by the user via the
                                % Investment_Universe file (column
                                % Asset_asset_type) and is used with
                                % internal invariants only (at least for
                                % now). For External invariants it is  always set
                                % to False
                                %                                 U.AllInvariants.equityAssetFlag{cnt,1} = false(1);
                                
                                dates = U.ExternalRF.RF(k).Invariants.Dates;
                                
                                % Find coordinates to reshape.
                                [x1n,y1n] = find(names_cube == n);
                                
                                returns = reshape(U.ExternalRF.RF(k).Invariants.(type)(x1n,y1n,:),1,z1);
                                prices = reshape(U.ExternalRF.RF(k).Invariants.Prices(x1n,y1n,:),1,z1);
                                % removing NaNs
                                % TODO: IMPORTANT: REVIEW THIS AND
                                % CENTRALIZE ALL INTERPOLATIONS & DATA
                                % MANIPULATIONS LIKE THIS ONE
                                fn = find(isnan(returns));
                                if ~isempty(fn)
                                    returns(fn) = [];
                                    dates(fn) = [];
                                    prices(fn) = [];
                                end
                                
                                % feeding ExternalInvariants collection (see
                                % comments above)
                                InvariantsAndPricesCollections.Returns{cnt,1} = [dates ,returns'];
                                InvariantsAndPricesCollections.Prices{cnt,1} = [dates,prices'];
                                
                            end
                            %-----------
                        end
                        
                    elseif strcmp(U.ExternalRF.RF(k).Invariants.Category,'ATM_Vol_Curve') ...
                            & U.ExternalRF.RF(k).ToBeIncludedInInvariants == 1
                        name_root = regexprep(name_root,'[^\w'']','');
                        
                        startDateIdx4Returns = 1;
                        
                        nMaturities = size(U.ExternalRF.RF(k).Invariants.Tenor,1);
                        for n=1:nMaturities
                            yf_term_tmp  = strrep(num2str(U.ExternalRF.RF(k).Invariants.Tenor(n)),'.','dot');
                            name = [name_root,'_',yf_term_tmp,'Y'];
                            
                            iA = ismember(U.AllInvariants.NamesSet,name);
                            if isempty(U.AllInvariants.NamesSet) | sum(iA)==0 % check that the invariant has not yet been picked up
                                cnt = cnt + 1; % continue counting after 'Internal Invariants' processing
                                type = U.ExternalRF.RF(k).Invariants.Type;
                                U.AllInvariants.NamesSet{cnt,1} = name;
                                U.AllInvariants.InvariantType{cnt,1} = type;
                                U.AllInvariants.equityAssetFlag{cnt,1} = false(1);
                                
                                dates = U.ExternalRF.RF(k).Invariants.Dates;
                                returns = U.ExternalRF.RF(k).Invariants.(type)(:,n);
                                prices = U.ExternalRF.RF(k).Invariants.Prices(:,n);
                                % removing NaNs
                                % TODO: IMPORTANT: REVIEW THIS AND
                                % CENTRALIZE ALL INTERPOLATIONS & DATA
                                % MANIPULATIONS LIKE THIS ONE
                                fn = find(isnan(returns));
                                if ~isempty(fn)
                                    returns(fn) = [];
                                    dates(fn) = [];
                                    prices(fn) = [];
                                end
                                
                                % feeding InvariantsAndPricesCollections collection (see
                                % comments above)
                                InvariantsAndPricesCollections.Returns{cnt,1} = [dates(startDateIdx4Returns:end),returns];
                                InvariantsAndPricesCollections.Prices{cnt,1} = [dates,prices];
                                
                            end
                        end
                    end % if on Invariant's category
                end % no of external factors datasets
            end
            
            % merging all fts obj on a common set of dates (intersection of
            % dates)
            % IMPORTANT: THE ORDER OF THE VARIOUS INVARIANTS IN allfts IS
            % THE SAME AS THE ORDER IN U.AllInvariants.NamesSet, WHERE
            % INVARIANTS' NAMES ARE STORED: this will be useful to rebuild
            % a one to one correspondence between the names of the
            % invariants and the final matrix that will contain them
            % U.AllInvariants.X
            if cnt > 0 % if there is at least 1 invariant
                
                % ********************************************************
                U.AllInvariants.InvariantsAndPricesCollectionsRawData = InvariantsAndPricesCollections;
                
                % Using Utilities.GetCommonDataSet to merge the single
                % timeseries (method: dates intersection)
                
                % for Returns
                uparams.op_type = 'intersect';
                uparams.inputTS = InvariantsAndPricesCollections.Returns;
                Util = Utilities(uparams);
                Util.GetCommonDataSet;
                U.AllInvariants.Dates = Util.Output.DataSet.dates;
                U.AllInvariants.X = Util.Output.DataSet.data;
                
                % for Prices
                uparams.op_type = 'intersect';
                uparams.inputTS = InvariantsAndPricesCollections.Prices;
                Util = Utilities(uparams);
                Util.GetCommonDataSet;
                U.AllInvariants.Dates_prices = Util.Output.DataSet.dates;
                U.AllInvariants.X_prices = Util.Output.DataSet.data;
                
                % mapping invariants names to the corresponding
                % columns'numbers in X
                keySet = U.AllInvariants.NamesSet;
                valueSet = [1:1:size(U.AllInvariants.X,2)]';
                U.AllInvariants.Names2ColNoMap = containers.Map(keySet,valueSet);
                
                % ********************************************************
            end
            
            % figure; plotmatrix(U.AllInvariants.X); grid on;
            
        end % GetInvariants_EmpiricalDistribution
        
        function ARMAGARCH_filtering(U,ARGARCH)
            U.ARMA_GARCH_filtering = ARGARCH.ARMA_GARCH_filtering;
        end % end of method ARMAGARCH_filtering
        
        % ************************************************************
        
        
        %             else % ***** FOR PANOS: Panos, this is never used, right ???
        %                 disp('Creating the memory map from scratch. This will take a while...')
        %                 % ELSE CREATE EVERYTHING FROM SCRATCH (TAKES TIME)
        %                 RFnum = length(U.AllInvariants.NamesSet);
        %                 returns = U.AllInvariants.X;
        %                 T = size(returns,1);
        %
        %                 nIndices  = RFnum;        % # of indices
        %                 residuals = NaN(T, nIndices);    % preallocate storage
        %                 variances = NaN(T, nIndices);
        %                 fit       = cell(nIndices,1);
        %
        %                 returns = 100*returns;
        %                 for i = 1:nIndices
        %                     i
        %                     fit{i} = estimate(model,  returns(:,i), 'print', false, 'options', options);
        %                     [residuals(:,i), variances(:,i)] = infer(fit{i}, returns(:,i));
        %                 end
        %
        %                 % Put all in a container map.
        %                 fit_mem_obj = containers.Map(U.AllInvariants.NamesSet,fit);
        %
        %                 save(['ARMAGARCH_obj_' num2str(U.AllInvariants.Dates(1)) '.mat'],'fit_mem_obj');
        %                 %keys(fit_mem_obj) % All keys
        %                 %fit_mem_obj('ImpliedVola_UKX_5Y_0dot3D') % Example.
        %                 %isKey(fit_mem_obj,'ImpliedVola_UKX_5Y_0dot3D')
        %
        %
        %                 for index  = 1 : RFnum
        %                     figure(index)
        %                     subplot(1,3,1);
        %                     plot(returns(:,index))
        %                     subplot(1,3,2);
        %                     autocorr(returns(:,index))
        %                     title(['Sample ACF of Returns ' U.AllInvariants.NamesSet(index)])
        %                     subplot(1,3,3);
        %                     autocorr(returns(:,index).^2)
        %                     title(['Sample ACF of Squared Returns ' U.AllInvariants.NamesSet(index)])
        %                     set(index,'WindowStyle','docked')
        %                     export_fig temp1.pdf
        %                     append_pdfs Output.pdf temp1.pdf % Append all figs to pdf file.
        %                     close all
        %                 end
        %                 close all
        %
        %                 % Assess the residual conditioning
        %                 for index = 1:RFnum
        %                     figure(index)
        %                     subplot(2,1,1)
        %                     plot(residuals(:,index))
        %                     datetick('x')
        %                     xlabel('Date')
        %                     ylabel('Residual')
        %                     title (['Filtered Residuals'  U.AllInvariants.NamesSet(index)])
        %                     subplot(2,1,2)
        %                     plot(sqrt(variances(:,index)))
        %                     datetick('x')
        %                     xlabel('Date')
        %                     ylabel('Volatility')
        %                     title (['Filtered Conditional Standard Deviations'  U.AllInvariants.NamesSet(index)])
        %                     export_fig temp1.pdf
        %                     append_pdfs Output2.pdf temp1.pdf % Append all figs to pdf file.
        %                     close all
        %                 end
        %
        %                 %Zero mean unit variance.
        %                 std_residuals = residuals ./ sqrt(variances);
        %
        %                 Q = input('Do you want to export graphs from scratch ? [y/n]', 's');
        %                 if strcmp(Q,'y') == 1
        %                     for index = 1:RFnum
        %                         figure(index)
        %                         subplot(2,1,1)
        %                         autocorr(std_residuals(:,index))
        %                         title(['Sample ACF of Standardized Residuals ' U.AllInvariants.NamesSet(index)])
        %                         subplot(2,1,2)
        %                         autocorr(std_residuals(:,index).^2)
        %                         title(['Sample ACF of Squared Standardized Residuals ' U.AllInvariants.NamesSet(index)])
        %                         export_fig temp1.pdf
        %                         append_pdfs Output3.pdf temp1.pdf % Append all figs to pdf file.
        %                         close all
        %                     end
        %                 else
        %                 end
        %
        %             end

        
        
        function [P,P4BackTest] = Asset_HPrices(U,dt)
            % this method retrieves historical prices for all of the assets
            % as of date dt.
            % INPUT:
            % dt: date as of which I want to retrieve hist prices
            % OUTPUT:
            % P: vector of assets' prices as of date ft
            % P4BackTest: price used for backtest (normally it is P)
            
            for na=1:size(U.Assets,1)
                % only if dt after the date when the asset enters the
                % investable universe (if empty assumes that the asset is always in the Universe)
                if (~isempty(U.Assets(na).value.Enter_Universe_date) && dt>=datenum(U.Assets(na).value.Enter_Universe_date)) ...
                        | isempty(U.Assets(na).value.Enter_Universe_date)
                    fd = find(U.Assets(na).value.History.Price.TimeSeries(:,1) == dt);
                    P(1,na) = U.Assets(na).value.History.Price.TimeSeries(fd,2);
                    P4BackTest(1,na) = P(1,na);
                else
                    P(1,na) = NaN; % TODO: check this
                    P4BackTest(1,na) = NaN;
                end
            end
        end
        
        function AnimatedFrontiers(U,strategy,lastPincluded,pause_time)
            % this method plots an 'animated efficient frontier', starting
            % with the EF at the time of the 1st investment decision and
            % updating it every time that an AA update occurs
            % INPUTS:
            % lastPincluded = 0 if the last point on the frontier m,ust
            % not be included in the PLOT (this can be useful when there is an 'imposed'
            % MaxReturn in the EF construction (see Efficient Frontier method)
            % pause_time: to regulate the animation's speed (e.g. 0.05)
            
            figure; hold on; grid on;
            starting_t = U.Strategies.(strategy).StartingTime;
            dates = U.Strategies.(strategy).H_dates_vector;
            aa_changes = U.Strategies.(strategy).Allocation_changes_EP;
            
            T = size(U.Strategies.(strategy).Dynamic_Frontier_EP.Risk,2);
            NofPortfolios = size(U.Strategies.(strategy).Dynamic_Frontier_EP.Risk,1);
            if lastPincluded == 0
                NofPortfolios = NofPortfolios - 1;
            end
            X = U.Strategies.(strategy).Dynamic_Frontier_EP.Risk(1:NofPortfolios,starting_t);
            Y = U.Strategies.(strategy).Dynamic_Frontier_EP.ExpectedReturn(1:NofPortfolios,starting_t);
            h = plot(X*100,Y*100,'Color','r','LineWidth',3); % plot 1st Eff Frontier
            xlabel('Expected Risk at Investment Horizon (%)');
            ylabel('Expected Return at Investment Horizon (%)');
            for t=starting_t+1:T
                if aa_changes(t)==1
                    X = U.Strategies.(strategy).Dynamic_Frontier_EP.Risk(1:NofPortfolios,t)*100;
                    Y = U.Strategies.(strategy).Dynamic_Frontier_EP.ExpectedReturn(1:NofPortfolios,t)*100;
                    h.XData = X;
                    h.YData = Y;
                    pause(pause_time)
                    tit = ['Time: ',num2str(t),' - Date: ', datestr(dates(t))];
                    title(tit,'FontSize',12);
                end
            end
            
        end
        
        function GetPosterior(U)
            % to be implemented: to get the posterior dsistribution through
            % Entropy Pooling or Bayes Posterior (or other static methods)
        end
        
        function AlgoViews(U,algo_choice,Prices, params)
            % this  function implements algo based signal generations
            % (that can be used to define automated views)
            % INPUT:
            % algo_choice: choice of the Algorithm (only Signal_Gen_1 for
            % now)
            % timeseries: input timeseries. This must be a struct arrays
            % with fields:
            % 1) .dates: common vector of dates
            % 2) .prices: prices
            % If there is more
            % than one timeseries the output 'Signal' will be a structured
            % array containing signals vectors for all the input timeseries
            % params: a structured array containing parameters necessary to
            % call the algo
            % OUTPUT:
            % Drivers.(name of the strategy): this struct will become a
            % field of the instance of class universe that invoked this
            % method and will contain the information needed to convert the
            % signals from the algo into views (that is constarints to the
            % Entropy Pooling optimization process)
            % This is the main output: this field will contain the
            % details of the signals generated by a specific instance of
            % class Quantsignals and its structure will vary based on the
            
            % *********************************************************************
            % *********************************************************************
            % NOTE:
            % QUICK SIMPLIFIED ALGO USED HERE TO TEST THE CODE
            % *********************************************************************
            % *********************************************************************
            
            import ViewsGen.*;
            
            switch algo_choice
                
                % *********************************************************
                case 'Signal_Gen_1'
                    nfld = size(Prices.prices,2);
                    for k=1:nfld
                        Driver(k).prices = Prices.prices(:,k);
                        Driver(k).dates = Prices.dates(:,1);
                        
                        params.prices = [Driver(k).dates,Driver(k).prices];
                        QS1 = QuantSignals(params);
                        QS1.SignalGen_1;
                        Signals.(['signal_',num2str(k)]) = QS1.Signal;
                        
                        Driver(k).Signal = Signals.(['signal_',num2str(k)]).(params.indicator)(:,1);
                        
                        [Driver(k).SignalHistory,Driver(k).SignalStructure,Driver(k).DriverS_changes,Driver(k).Prior_Changes] = ...
                            U.MultipleSignals(Driver(k),params.StartingTime);
                        Driver(k).Name = params.D_Names{k,1};
                        Driver(k).UndName = params.D_Names{k,2};
                    end
                    
                    U.Drivers.Signal_Gen_1 = Driver; % obj needed in universe.Dynamic_AA_1 to implement algo views
                    % *********************************************************
               
                case 'CointPower'
                    % *********************************************************
                    QS1 = QuantSignals(params);
                    QS1.CointPower;
                    U.Drivers.CointPower = QS1;  % obj needed in universe.Dynamic_AA_1 to implement algo views
                    % *********************************************************
                case 'PairCointegration'
                    % *********************************************************
                    QS1 = QuantSignals(params);
                    QS1.PairCointegration;
                    U.Drivers.PairCointegration = QS1;  % obj needed in universe.Dynamic_AA_1 to implement algo views    
                    % *********************************************************
            end
        end % Signals
        
        
        function [P_sim] = HRepricing(U,X_Resampled,nassets,cur_dt,initial_price,HorizonDays,HorizonDate)
            % this method performs the repricing at horizon for all the assets
            
            numsim = size(X_Resampled,1); % no of simulated paths
            % used to keep track of the assets of subclass equity that have
            % been repriced already. It is meant to avoid repricing the
            % same equity many times if it is the underlying for many
            % options or if the same equity is repeated in multiple
            % portfolios
            repricedEquitiesMap = containers.Map;
            % ... same thing for options
            repricedOptionsMap = containers.Map;
            
            P_sim = zeros(size(X_Resampled,1),nassets);
            clear CDS_spread0 ZERO0 YTM0 U0;
            for na=1:size(U.Assets,1)
                
                clear params yf_numeric col_idx;
                col_idx = []; % will identify columns indices in AllInvariants.X or AllInvariants.X_Prices
                
                mc = metaclass(U.Assets(na).value);
                
                % for equity subclass (used for FX and commodities as well)
                if strcmp(mc.Name,'InvestmentUniverse.equity') | strcmp(mc.Name,'InvestmentUniverse.fx')
                    % name of the risk factor
                    name = U.Assets(na).value.Risk_Factors_Names.Price;
                    
                    try % if priced already
                        P_sim(:,na) = repricedEquitiesMap(name);
                    catch MM
                        if strcmp(MM.identifier,'MATLAB:Containers:Map:NoKey')
                            % if not in the map (not yet repriced)
                            
                            % locating it in U.AllInvariants.NamesSet
                            fn = ismember(U.AllInvariants.NamesSet,name);
                            col_idx = find(fn); % column index in U.AllInvariants.X_prices
                            ts = [U.AllInvariants.Dates,U.AllInvariants.X_prices(:,col_idx)]; % timeseries of interest
                            
                            fd = find(ts(:,1) == cur_dt);
                            if isempty(fd)
                                clc; disp('Initial Price unavailable'); % TODO: refine this by providing corrective options
                                pause;
                            end
                            U0(na,1) = ts(fd,2);
                            
                            % REPRICING ***********************************
                            params.p0 = U0(na);
                            
                            EquityMaturityinDays = inf;
                            TrueHorizonDays = max(min(HorizonDays,EquityMaturityinDays),1);   % Added TrueHorizonDays
                            Mu_return_H_all = sum(X_Resampled(:,:,1:TrueHorizonDays),3);
                            
                            params.er = Mu_return_H_all(:,col_idx); % vectorial repricing
                            P_sim(:,na) = U.Assets(na,1).value.Reprice(params);
                            repricedEquitiesMap(name) = P_sim(:,na);
                        else
                            rethrow(MM);
                        end
                    end % try repricing through map
                    
                end % 'if equity' or 'fx' asset subclasses
                
                % for 'bond_ZCB' assets  only
                if strcmp(mc.Name,'InvestmentUniverse.bond_ZCB')
                    % setting the time 2 maturity for pricing
                    % time2maturityFromCurrentDt_days (in days) is the time from 'today'
                    % (cur_dt) to the expiry and is used to build
                    % TrueHorizonDays (see below)
                    if ~isempty(U.Assets(na).value.MaturityDate)
                        matdate = datenum(U.Assets(na).value.MaturityDate);
                        time2mat = (matdate - HorizonDate); % the repricing date must be the investment horizon date
                        time2mat_y = time2mat./365;
                        time2maturityFromCurrentDt_days = matdate - HorizonDate; %cur_dt;  Gianpiero point.
                    else % if there is no maturity date it must be a bond with constant time to expiry
                        time2mat_y = U.Assets(na).value.FixedTtm;
                        time2maturityFromCurrentDt_days = Inf;
                    end
                    
                    if isempty(U.Assets(na).value.ReferenceCurve) % WHEN NOT PRICING WITH CURVE
                        % name of the risk factor
                        name = U.Assets(na).value.Risk_Factors_Names.YTM;
                        % locating it in U.AllInvariants.NamesSet
                        fn = ismember(U.AllInvariants.NamesSet,name);
                        col_idx = find(fn); % column index in U.AllInvariants.X_prices
                        ts = [U.AllInvariants.Dates,U.AllInvariants.X_prices(:,col_idx)]; % timeseries of interest
                        
                        fd = find(ts(:,1) == cur_dt);
                        if isempty(fd)
                            clc; disp('Initial Price unavailable'); % TODO: refine this by providing corrective options
                            pause;
                        end
                        YTM0(na,1) = ts(fd,2);
                        
                    else
                        disp('Selection of the curve for bond pricing');
                        rc = U.Assets(na).value.ReferenceCurve;
                        % looking for the YC ticker's root
                        srcs = strfind(U.AllInvariants.NamesSet,rc.Name);
                        s_srcs = size(srcs,1);
                        % iterating over srcs to locate the
                        % appropriate points on the curve
                        % TODO: improve the design of AllInvariants
                        % (e.g. system of pointers easier and faster to use)
                        crv = [];
                        cnt = 0;
                        fn = [];
                        for n=1:s_srcs
                            if srcs{n,1} == 1
                                cnt = cnt + 1;
                                col_idx = [col_idx,n]; % columns indices in AllInvariants.X_Prices
                                disp([num2str(n),'-th col of AllInvariants.X_Prices']);
                                
                                ts = [U.AllInvariants.Dates,U.AllInvariants.X_prices(:,n)]; % timeseries of interest
                                fd = find(ts(:,1) == cur_dt);
                                % identifying the maturity label in the
                                % ticker and translating it into
                                % years to maturity as a number
                                [yf_numeric] = U.Label2yearFract(U.AllInvariants.NamesSet{n});
                                % then look for the column of invariants
                                % corresponding to this year fraction in
                                % the object
                                fy = find(rc.Curve.tenors_yf == yf_numeric);
                                curve_pt_ttm = yf_numeric;
                                
                                % curve at the current date
                                % [time to maturity, price] x no of pts on the curve
                                crv(cnt,:) = [curve_pt_ttm,ts(fd,2)];
                            end
                        end % n
                        % in crv I have the YTMs on the curve as of
                        % the current date: using it to interpolate
                        % for the actual time to maturity of the
                        % bonds in years (time2mat_y)
                        YTM0(na,1) = interp1(crv(:,1),crv(:,2),time2mat_y,'linear','extrap');
                    end
                    
                    % REPRICING *******************************************
                    params.ytm0 = YTM0(na);
                    params.p0 =  initial_price(na);
                    % time to maturity parameter
                    params.ttm = time2mat_y;
                    
                    BondMaturityinDays = round(params.ttm * 365,0); % in Days.
                    TrueHorizonDays = max(min(HorizonDays,BondMaturityinDays),1);   % Added TrueHorizonDays
                    Mu_return_H_all = sum(X_Resampled(:,:,1:TrueHorizonDays),3);
                    
                    if length(col_idx)>1
                        % using a curve for pricing: necessary to
                        % interpolate like done above for current
                        % price
                        params.er = interp1(crv(:,1),Mu_return_H_all(:,col_idx)',time2mat_y,'linear','extrap');
                    else
                        params.er = Mu_return_H_all(:,col_idx);
                        params.er = params.er';
                    end
                    params.horizon_days = HorizonDays;
                    params.repricing_dt = cur_dt;
                    P_sim(:,na) = U.Assets(na,1).value.Reprice(params);
                end % if bond
                
                % *************************************************
                % *************************************************
                % for 'CDS' assets  only
                if strcmp(mc.Name,'InvestmentUniverse.cds')
                    if 1==1
                        % THE ONLY OPTION FOR NOW: REPRICING BASED ON
                        % 1ST ORDER CSDV01 APPROX (FULL CURVE NOT
                        % NEEDED)
                        name = U.Assets(na).value.Risk_Factors_Names.CDS;
                        % locating it in U.AllInvariants.NamesSet
                        fn = ismember(U.AllInvariants.NamesSet,name);
                        col_idx = find(fn); % column index in U.AllInvariants.X_prices
                        ts = [U.AllInvariants.Dates,U.AllInvariants.X_prices(:,col_idx)]; % timeseries of interest
                        
                        fd = find(ts(:,1) == cur_dt);
                        if isempty(fd)
                            clc; disp('Initial Price unavailable'); % TODO: refine this by providing corrective options
                            pause;
                        end
                        
                        CDS_spread0(na,1) = ts(fd,2);
                        
                    else % ****************************************
                        % NOT USED FOR NOW (TOO SLOW): TO BE IMPLEMENTED: THE FULL
                        % CURVE IS NEEDED ONLY FOR FULL REPRICING
                        
                        %                         disp('Selection of the curve for CDS pricing');
                        %                         rc = U.Assets(na).value.ReferenceCurve;
                        %                         % looking for the YC ticker's root
                        %                         srcs = strfind(U.AllInvariants.NamesSet,rc);
                        %                         s_srcs = size(srcs,1);
                        %
                        %                         % iterating over srcs to locate the
                        %                         % appropriate points on the curve
                        %                         % TODO: improve the design of AllInvariants
                        %                         % (e.g. system of pointers easier and faster to use)
                        %                         cnt = 0;
                        %                         fn = [];
                        %                         crv = [];
                        %                         for n=1:s_srcs
                        %                             if srcs{n,1} == 1
                        %                                 cnt = cnt + 1;
                        %                                 col_idx = [col_idx,n]; % columns indices in AllInvariants.X_Prices
                        %                                 disp([num2str(n),'-th col of AllInvariants.X_Prices']);
                        %
                        %                                 ts = [U.AllInvariants.Dates,U.AllInvariants.X_prices(:,n)]; % timeseries of interest
                        %                                 fd = find(ts(:,1) == cur_dt);
                        %
                        %                                 % identifying the maturity label in the
                        %                                 % ticker and translating it into
                        %                                 % years to maturity as a number
                        %                                 [yf_numeric] = U.Label2yearFract(U.AllInvariants.NamesSet{n});
                        %                                 % then look for the column of invariants
                        %                                 % corresponding to this year fraction in
                        %                                 % the object
                        %                                 fy = find(rc.Curve.tenors_yf == yf_numeric);
                        %                                 curve_pt_ttm = yf_numeric;
                        %
                        %                                 % curve at the current date
                        %                                 % [time to maturity, price] x no of pts on the curve
                        %                                 crv(cnt,:) = [curve_pt_ttm,ts(fd,2)];
                        %
                        %                             end
                        %                         end % n
                    end
                    
                    % REPRICING ***********************************
                    params.type = 'approx';
                    params.CDS_spread0 = CDS_spread0(na); % spread as of time t
                    params.p0 =  initial_price(na); % price of the CDS as of time t
                    % INCORPORATING ACCRUALS: when
                    % A.AccrueCDS_coupon is True I need to
                    % continuously account for accruals, based on
                    % the fixed coupon A.FixedCoupon. In this case prices
                    % in params.p0 are 'dirty prices' (see
                    % asset.Bloomberg_GetHistory for CDS 'history' pricing)
                    if U.Assets(na).value.AccrueCDS_coupon
                        continuousAccruals = HorizonDays .* ...
                            ((U.Assets(na).value.Notional.*U.Assets(na).value.FixedCoupon/(365*10000)) .* -sign(U.Assets(na).value.Notional));
                    else
                        continuousAccruals = 0;
                    end
                    
                    % 1st order sensitivity measure
                    SPV01 = U.Assets(na).value.History.SPV01.TimeSeries;
                    fd = find(SPV01(:,1) == cur_dt);
                    params.SPV01 = SPV01(fd,2);
                    
                    CDSMaturityinDays = round(U.Assets(na).value.FixedTtm  * 365,0); % in Days (only CDS with constant maturity are modeled at the moment)
                    TrueHorizonDays = max(min(HorizonDays,CDSMaturityinDays),1);   % Added TrueHorizonDays
                    Mu_return_H_all = sum(X_Resampled(:,:,1:TrueHorizonDays),3);
                    
                    % distribution of invariant (spread) at horizon
                    params.er = Mu_return_H_all(:,col_idx)
                    params.settle = cur_dt; % repricing's date
                    P_sim(:,na) = U.Assets(na,1).value.Reprice(params);
                    % incroporating accruals that are based on a known rate
                    P_sim(:,na) = P_sim(:,na) + continuousAccruals;
                    
                end % if cds
                % *************************************************
                % *************************************************
                
                % for 'irs' assets  only
                if strcmp(mc.Name,'InvestmentUniverse.irs')
                    clear RC rc;
                    disp('Selection of the curve for IRS pricing');
                    
                    rc = U.Assets(na).value.Risk_Factors_Names.ZeroRate; % identify curves needed for repricing
                    
                    fnames = fieldnames(rc);
                    nf = numel(fnames);
                    
                    % SwapsMaturityinDays is the ttm as of pricing date of the swap, that is the
                    % date of the investment horizon
                    % time2maturityFromCurrentDt_days (in days) is the time from 'today'
                    % (cur_dt) to the expiry and is used to build
                    % TrueHorizonDays (see below)
                    SwapsMaturityinDays = round((U.Assets(na).value.FixedMaturity - HorizonDate),0); % time to maturity in Days (as of the repricing date, that is the Horizon Date).
                    time2maturityFromCurrentDt_days = round((U.Assets(na).value.FixedMaturity - cur_dt),0);
                    if isempty(SwapsMaturityinDays) == 1  %Constant Tenor swap.
                        time2maturityFromCurrentDt_days = inf;
                    else
                    end
                    TrueHorizonDays = max(min(HorizonDays,time2maturityFromCurrentDt_days),1);   % Added TrueHorizonDays
                    
                    Mu_return_H_all = sum(X_Resampled(:,:,1:TrueHorizonDays),3);
                    
                    for k=1:nf
                        % looking for the curve
                        % rc = U.Assets(na).value.CurvesHistory.(fnames{k}); % this is the obj representing the curve I am working on
                        srcs = strfind(U.AllInvariants.NamesSet,fnames{k}); % this vector contains 'ones' in positions corresponding to the single pillars of the curve identified by  fnames{k}
                        f = cellfun(@isempty, srcs,'UniformOutput',false(1));
                        f = cell2mat(f);
                        f = ~logical(f); % inverting since I want not empty cells that identufy the element  in U.AllInvariants.NamesSet that I want to select
                        col_idx = find(f); % to get col indices needed to retrieve simulated invariants at horizon in Mu_return_H_all
                        
                        % the loop below is needed to get the historical
                        % rates corresponding to the current curve (fnames{k})
                        % TODO: for different assets subclasses I
                        % usually put the name of the curve itself in
                        % the field name structure (so below I would
                        % have something like
                        % U.Assets(na).value.CurvesHistory.ZeroCurves.<Name of the Curve>
                        % to avoid the need for these loops. NOT
                        % ESSENTIAL, but when there is time try to make
                        % IRS consistent with other asset subclasses
                        % using curves
                        for ncurve=1:numel(U.Assets(na).value.CurvesHistory.ZeroCurves)
                            if strcmp(U.Assets(na).value.CurvesHistory.ZeroCurves{ncurve}.CurveID,fnames{k})
                                fd = find(U.Assets(na).value.CurvesHistory.ZeroCurves{ncurve}.Curve.dates   == cur_dt); % locating the current date
                                % zero rates as of the current date for the
                                % curves needed for repricing: they are needed
                                % since they represent the 'starting point' of
                                % the simulations
                                ZERO0.(fnames{k}).rates{na,1} = U.Assets(na).value.CurvesHistory.ZeroCurves{ncurve}.Curve.rates(fd,:)'; %
                                ZERO0.(fnames{k}).maturity_yf{na,1} = cellfun(@U.Label2yearFract,U.AllInvariants.NamesSet(col_idx)); % getting the maturities from the labels
                                
                                start_fixtenor = strfind(fnames{k},'_');
                                end_fixtenor = strfind(fnames{k},'M');
                                ZERO0.(fnames{k}).frequency{na,1} = str2num(fnames{k}(start_fixtenor+1:end_fixtenor-1)); % Get the Leg frequency for the generation of forward rates from the pricerObject.
                                if isempty( ZERO0.(fnames{k}).frequency{na,1}) ==1
                                    ZERO0.(fnames{k}).frequency{na,1} = 1/365; % If there is no Index on the name then it is an Overnight rate.
                                else
                                end
                                break;
                            end
                        end
                        
                        % parameters needed for repricing at horizon
                        params.zero0.(fnames{k}).rates = ZERO0.(fnames{k}).rates{na,1}';
                        params.zero0.(fnames{k}).maturity_yf = ZERO0.(fnames{k}).maturity_yf{na,1};
                        params.er.(fnames{k}).rates = Mu_return_H_all(:,col_idx);% simulated invariants at investment horizon_days = HorizonDays;
                        
                        % inputs to the Reprice function needed to
                        % compute accruals
                        % Demised  %average_scenarios = mean(params.er.(fnames{k}).rates);  % Find average scenarios to correct for fixings change within the projection period.
                        interpvec = [1:HorizonDays]./365;
                        % These are the 1: Horizon Days extrapolated
                        % (sometimes) values that will be added for each
                        % optimization date.
                        fixingtenor = ZERO0.(fnames{k}).frequency{na,1}  ; % This is the fixing tenor based on the index ie. 1M, 3M, 6M or 12M
                        rate1 = interp1( params.zero0.(fnames{k}).maturity_yf', params.zero0.(fnames{k}).rates, interpvec,'linear','extrap'); % Spot rate interpolations to create the forward rates.
                        rate2 = interp1( params.zero0.(fnames{k}).maturity_yf', params.zero0.(fnames{k}).rates, interpvec + (fixingtenor*30./365),'linear','extrap'); % Spot rate interpolations to create the forward rates.
                        FwdRates = ForwardRate(cur_dt, cur_dt+interpvec*365 ,cur_dt+interpvec*365 + fixingtenor *30,rate1 ,rate2,1);
                        % Demised  % %params.zero0.(fnames{k}).fixing_projections = interp1( params.zero0.(fnames{k}).maturity_yf', average_scenarios, interpvec,'linear','extrap');
                        params.zero0.(fnames{k}).fixing_projections = FwdRates; % Implied Fixings are the forward rates.
                    end % looping over domestic, foreign and FX curves
                    
                    % ***** REPRICING  *****
                    % parameters needed for repricing at horizon
                    % params.zero0 assigned in the FOR loop above
                    % params.er assigned in the FOR loop above
                    params.typeOfRepricing = 'AtHorizon';
                    params.horizon_days = HorizonDays;
                    params.p0 =  initial_price(na); % current price of the swap
                    params.repricing_dt = HorizonDate;% Gianpiero point, cur_dt; % 'current date' (i.e. date of the optimization)
                    params.numsim = numsim; % no of simulated outcomes at the horizon
                    
                    output = U.Assets(na,1).value.Reprice(params);
                    % P_sim(:,na) = output.PV + output.accrualsTot;
                    P_sim(:,na) = output.PriceTotReturn;
                end % if irs
                % *************************************************
                % *************************************************
                
                
                % for 'Option_Vanilla' assets  only
                if strcmp(mc.Name,'InvestmentUniverse.Option_Vanilla')
                    
                    mapKey = U.Assets(na).value.Reference_Info.ticker_BBG;
                    mapKey = strrep(mapKey,' ','_');
                    mapKey = strrep(mapKey,'.','_');
                    mapKey = strrep(mapKey,'/','_');
                    try % if priced already
                        P_sim(:,na) = repricedOptionsMap(mapKey);
                    catch MM
                        if strcmp(MM.identifier,'MATLAB:Containers:Map:NoKey') % price it if not in the map
                            
                            % IDENTIFY THE RISK FACTORS NEEDED FOR PRICING: the
                            % names of the risk factors to be used are, as usual,
                            % in the 'Risk_Factors_Names property' of the asset
                            
                            % *****************************************************
                            % ********* IDENTIFY 'underlying' risk factor *********
                            % *****************************************************
                            % name of the risk factor
                            name = U.Assets(na).value.Risk_Factors_Names.Price;
                            % locating it in U.AllInvariants.NamesSet
                            fn = ismember(U.AllInvariants.NamesSet,name);
                            underlying_col_idx(1) = find(fn); % column index for the underlying  in U.AllInvariants.X_prices
                            
                            
                            % *****************************************************
                            % ****** IDENTIFY implied volatility  risk factor *****
                            % *****************************************************
                            nameUnd = U.Assets(na).value.Risk_Factors_Names.ImpliedVola;
                            srcs = strfind(U.AllInvariants.NamesSet,nameUnd); % this vector contains 'ones' in positions corresponding to the simulated vectors for the surface identified by 'name'
                            f = cellfun(@isempty, srcs,'UniformOutput',false(1));
                            f = cell2mat(f);
                            f = ~logical(f); % inverting since I want not empty cells that identufy the element  in U.AllInvariants.NamesSet that I want to select
                            volatility_col_idx = find(f); % identifies the columns of the invariants corresponding to the vola surface
                            ts = [U.AllInvariants.Dates,U.AllInvariants.X_prices(:,volatility_col_idx)]; % timeseries of interest
                            fd = find(ts(:,1) == cur_dt);
                            if isempty(fd)
                                clc; disp('Initial Price unavailable'); % TODO: refine this by providing corrective options
                                pause;
                            end
                            IV0_table{na} = ts(fd,2:end); % initial volatility price
                            IV0_table_names{na} = U.AllInvariants.NamesSet(volatility_col_idx);
                            
                            % *****************************************************
                            % *********** IDENTIFY zero rate risk factor **********
                            % *****************************************************
                            name = [U.Assets(na).value.Risk_Factors_Names.YTM,'_yfract'];
                            srcs = strfind(U.AllInvariants.NamesSet,name); % this vector contains 'ones' in positions corresponding to the single pillars of the curve identified by  name
                            f = cellfun(@isempty, srcs,'UniformOutput',false(1));
                            f = cell2mat(f);
                            f = ~logical(f); % inverting since I want not empty cells that identufy the element  in U.AllInvariants.NamesSet that I want to select
                            ytm_col_idx = find(f); % to get col indices needed to retrieve simulated invariants at horizon in Mu_return_H_all
                            
                            % Note: here in the vector 'ytm_col_idx' we have the
                            % number of the columns identifying the simulated invariants that
                            % we will be using for projection at horizon purposes
                            % (you can visualize them typing:
                            % U.AllInvariants.NamesSet(ytm_col_idx))
                            
                            % Tau is the ttm as of pricing date of the option, that is the
                            % date of the investment horizon
                            % time2maturityFromCurrentDt_days (in days) is the time from 'today'
                            % (cur_dt) and the expiry and is used to build
                            % TrueHorizonDays (see below)
                            if U.Assets(na).value.FixedExpiryFlag == 1
                                if isempty(U.Assets(na).value.ExpiryDate_OPTIONAL) == 1
                                    Tau = max((U.Assets(na).value.ExpiryDate-HorizonDate)/365 ,0);
                                    time2maturityFromCurrentDt_days = max((U.Assets(na).value.ExpiryDate-cur_dt)/365 ,0)*365;
                                else
                                    Tau = max((U.Assets(na).value.ExpiryDate_OPTIONAL-HorizonDate)/365 ,0);
                                    time2maturityFromCurrentDt_days = max((U.Assets(na).value.ExpiryDate-cur_dt)/365 ,0)*365;
                                end
                            else
                                Tau = U.Assets(na).value.tte_actual;  % I think this needs to be updated@
                                time2maturityFromCurrentDt_days = U.Assets(na).value.tte_actual.*365;
                            end
                            
                            % TODO: centralize all interpolations/extrapolations
                            
                            % Retrieve year fractions for interpolations.
                            yfract_INDEX  = cellfun(@(x) strfind(x,'yfract'), U.AllInvariants.NamesSet(ytm_col_idx),'UniformOutput',false);
                            yfract_INDEX = cellfun(@(x) x + 6,yfract_INDEX,'UniformOutput',false);
                            yfract = cellfun(@(x,y) x(y:end),U.AllInvariants.NamesSet(ytm_col_idx),yfract_INDEX,'UniformOutput',false);
                            yfract = cellfun(@(x) strrep(x,'dot','.'),yfract,'UniformOutput',false);
                            yfract = cellfun(@str2double,yfract);
                            yfract = yfract';
                            
                            T = yfract;
                            V = U.AllInvariants.X_prices(:,ytm_col_idx);
                            TI=Tau;
                            
                            % Interpolate for all dates.
                            VI = arrayfun(@(x)(interp1(T,V(x,:),TI,'linear','extrap')),1:size(V,1),'UniformOutput', false);
                            VI = cell2mat(VI');
                            ts = [U.AllInvariants.Dates,VI];
                            YTM0(na,1) = ts(fd,2); % initial ytm price
                            
                            clear V;
                            
                            % OPTION's REPRICING **************************
                            % ***********************************
                            % ***********************************
                            % ** underlying repricing: must be in the
                            % universe (with zero weight if not to be selected
                            % for AA purposes)
                            % this works only if the option's underlying is
                            % of type equity. For Bond option the repricing
                            % of the underlying should depend on an IF
                            % statement like the 2 above (on mc.Name)
                            p_und = [U.AllInvariants.Dates,U.AllInvariants.X_prices(:,underlying_col_idx(1))];
                            % find the price as of t
                            fd = find(p_und(:,1) == cur_dt);
                            if isempty(fd)
                                clc; disp('Initial Price for the underlying unavailable'); % TODO: refine this by providing corrective options
                                pause;
                            end
                            p_underlying = p_und(fd,2);
                            % repricing of the underlying (equity type
                            % only for now)
                            uparams.p0 = p_underlying;
                            
                            UnderlyingMaturityinDays =  round(time2maturityFromCurrentDt_days,0); % in Days.
                            TrueHorizonDays = max(min(HorizonDays,UnderlyingMaturityinDays),1);   % Added TrueHorizonDays
                            Mu_return_H_all = sum(X_Resampled(:,:,1:TrueHorizonDays),3);
                            
                            uparams.er = Mu_return_H_all(:,underlying_col_idx(1)); % vectorial repricing
                            % use the underlying's method for underlying's repricing
                            try
                                params.underlying = repricedEquitiesMap(nameUnd);
                            catch MM
                                if strcmp(MM.identifier,'MATLAB:Containers:Map:NoKey')
                                    % if not in the map (not yet repriced)
                                    params.underlying = U.Assets(na).value.Underlying_Obj.Reprice(uparams);
                                    repricedEquitiesMap(nameUnd) = params.underlying; % save it into the map
                                else
                                    rethrow(MM);
                                end
                            end
                            
                            % Identify volatility table,
                            % Add Volatility table
                            % Add flag whether fixed expiry or constant maturity.
                            % ** implied volatility repricing
                            params.reprice_vola_flag = 1;
                            params.iv0_table = IV0_table{na};
                            params.iv0_table_names = IV0_table_names{na};
                            params.iv0_table_expret = Mu_return_H_all(:,volatility_col_idx);
                            
                            % ** YTM repricing (for discount factor calculation)
                            ytm0 = YTM0(na,1);
                            
                            V = Mu_return_H_all(:,ytm_col_idx);
                            VI = arrayfun(@(x)(interp1(T,V(x,:),TI,'linear','extrap')),1:size(V,1),'UniformOutput', false);
                            VI = cell2mat(VI');
                            ytm0_er = VI;
                            clear V;
                            
                            ytm_T  = ytm0 + ytm0_er;
                            params.tte = Tau; % must be repeated for each scenario
                            params.df = exp(-ytm_T.*params.tte);
                            params.ytm_T = ytm_T;
                            params.dates = cur_dt; % PANOS Added this for at horizon pricing options.
                            % retreving the dvd yield: dividend yield is not trated
                            % as an invariant for now: so the estimated or declared
                            % dividend as of the current time is used for now
                            % (TODO: assess the benefits of including dvd yield in
                            % the set of invariants and simulating it)
                            % The dvd yield search can be made in the dates vector
                            % of prices, since by construction all the dates vector
                            % under 'History' should match
                            fd = find(U.Assets(na).value.Underlying_Obj.History.Price.TimeSeries(:,1) == cur_dt);
                            % use trhe max between the 2 measures available
                            % (considr that NaNs are replaced with 0s)
                            params.yield = max(U.Assets(na).value.Underlying_Obj.History.DvdYldEst.TimeSeries(fd,2), ...
                                U.Assets(na).value.Underlying_Obj.History.DvdYldInd.TimeSeries(fd,2));
                            P_sim(:,na) = U.Assets(na,1).value.Reprice(params);
                            
                            repricedOptionsMap(mapKey) = P_sim(:,na);
                        else
                            rethrow(MM);
                        end
                    end % try repricing through map
                end % if 'Option_Vanilla'
                
            end % na (n. of assets for pricing as of t)
        end % HRepricing
        
        function FX_Rates(U,history_start_date,history_end_date)
            %% EXCH RATES TIMESERIES
            % creating objects containing the hist timeseries of the exchange rates
            % (against EUR) for all assets not denominated in euros. The name of the
            % obj will reflect the name of the CRNCY property of asset class
            
            % The main purpose of this method is to get FX rates needed to
            % sterilize performances from FX impact when backtesting (see
            % notes in AA_BackTest).
            
            na = size(U.Assets,1);
            ncur = 0;
            ExchangeRates.Names = {};
            bbgFX_Tickers = {};
            allFXtickers = {};
            for k=1:na
                
                % n = size(ExchangeRates.Names,1);
                n = size(allFXtickers,1);
                % upper is used to deal with assets (e.g. some
                % options) denominated in cents of a given
                % currency (e.g. GBp). Here I am assuming that all assets
                % prices denominated in cents of a currency (e.g. USd or
                % GPb) have been previously converted to the corresponding units of
                % currency
                cur = upper(cell2mat(U.Assets(k).value.Reference_Info.currency));
                % ***********
                if ~strcmp(cur,'EUR')
                    mi = ismember(cur,allFXtickers);
                    if sum(mi)==0 % 1st time the currency in 'cur' it is encountered
                        ncur = ncur + 1;
                        allFXtickers{n+1,1} = cur;
                        bbgFX_Tickers{n+1,1} = ['EUR',cur,' Curncy'];
                        
                    end
                end % if not EUR
                % ***********
                
            end % k-loop over all the universe's assets
            
            if ~isempty(allFXtickers) % there are exchange rates
                
                % retrieving historical prices for all of the FX tickers
                % selected above
                uparam.DataFromBBG = U.DataFromBBG;
                uparam.ticker = bbgFX_Tickers;
                uparam.fields = ['LAST_PRICE'];
                uparam.history_start_date = history_start_date;
                uparam.history_end_date = history_end_date;
                uparam.granularity = ['daily'];
                Util = Utilities(uparam);
                Util.GetHistPrices;
                serie = Util.Output.HistInfo;
                
                % merging on a common set of dates: I need that the time vector
                % for these FX timeseries is  aligned with the time vector of
                % all invariants (obtained through the method
                % .GetInvariants_EmpiricalDistribution that must have been
                % executed before the current method is invoked.
                
                % IMPORTANT: this is the only place where I use 'nearest'
                % technique to fill holes. Normally I want to use mkt prices
                % only. However for FX we can expect to have BBG timeseries
                % with no missing values.
                clear uparam;
                uparam.inputTS = serie;
                uparam.op_type = 'fillUsingNearest';
                uparam.referenceDatesVector = U.AllInvariants.Dates;
                Util = Utilities(uparam);
                Util.GetCommonDataSet;
                
                % creating a multiple fts object out of the dataset in Util.Output.DataSet
                
                ExchangeRates.Names = allFXtickers;
%                 ExchangeRates.fts = fints(Util.Output.DataSet.dates,Util.Output.DataSet.data, ...
%                     allFXtickers,'D','multiple FX timeseries corresponding to FX denominated assets');
                tDate = datetime(Util.Output.DataSet.dates, 'ConvertFrom', 'datenum');
                tData = Util.Output.DataSet.data;
                tmpTable = [array2table(tDate),array2table(tData)]; % Table
                tmpTable.Properties.VariableNames(1,1) = {'Time'};
                ftsNew = table2timetable(tmpTable); % Timetable
                ftsNew.Properties.VariableNames = allFXtickers;
                ExchangeRates.fts = ftsNew;
                
            else
                ExchangeRates.fts = [];
            end
            
            U.ExchangeRates = ExchangeRates;
        end
        
        %         function GetLastDate(U) % **********  OLD   *************
        %             % introduced by Andrea (1.2017) to keep track of the latest
        %             % available price for all invariants, before they are merged on
        %             % a common set of dates (intersection). Useful to undertsand
        %             % whicg dates vector drives the intersecion performed by the
        %             % method U.GetInvariants_EmpiricalDistribution
        %             cnt = 0;
        %             for i = 1:size(U.Assets,1)
        %
        %                 noOfInvariants = numel(U.Assets(i).value.Invariants);
        %                 for in=1:noOfInvariants
        %                     if ~isempty(U.Assets(i).value.Invariants(in))
        %                         firstdate = U.Assets(i).value.Invariants(in).Prices(1,1);
        %                         lastdate = U.Assets(i).value.Invariants(in).Prices(end,1);
        %                         name = U.Assets(i).value.Invariants(in).Name;
        %                         cnt = cnt + 1;
        %                         U.InternalInvariantsLastDate(cnt,:) = {name,firstdate,lastdate};
        %                     end
        %                 end
        %             end
        %         end %GetLastDate
        
        function GetLastDateAndSectorCountry(U)
            % introduced by Andrea (1.2017) to keep track of the latest
            % available price for all invariants, before they are merged on
            % a common set of dates (intersection). Useful to undertsand
            % which dates vector drives the intersecion performed by the
            % method U.GetInvariants_EmpiricalDistribution
            
            %%%%% NEW FUNCTIONALITY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % fill the table with the country and industry classification
            % of any asset
            cnt = 0;
            import Miscellaneous.*;
            IndexSector; %load the table IndexSectorTable
            % IndexSectorTable = categorical(IndexSectorTable(:,1));
            IndexSectorTable = table(IndexSectorTable(:,1),IndexSectorTable(:,2),IndexSectorTable(:,3),'VariableNames',{'name','sector','group'});
            IndexSectorTable.name = categorical(IndexSectorTable.name);
            
            for i = 1:size(U.Assets,1)
                
                assetName = U.Assets(i).value.Reference_Info.name;
                assettype = U.Assets(i).value.AssetType;
                
                %%%%%% TO CHANGE %%%%%%%%%%%%%%%%%%%%%%%%%%
                if strcmp(assettype,'DVA')
                    country = {'IT'};
                    industrySector = {'Financial'};
                    industryGroup = {'Banks'};
                else
                    country = U.Assets(i).value.Reference_Info.Country;
                    
                    industrySector = U.Assets(i).value.Reference_Info.IndustrySector;
                    industryGroup = U.Assets(i).value.Reference_Info.IndustryGroup;
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                if isempty(industrySector{1})
                    if isempty(IndexSectorTable.sector(IndexSectorTable.name == assetName))
                        industrySector = {'Not Found'};
                        industryGroup = {'Not Found'};
                    else
                        industrySector = IndexSectorTable.sector(IndexSectorTable.name == assetName);
                    end
                end
                if isempty(industryGroup{1})
                    industryGroup = IndexSectorTable.group(IndexSectorTable.name == assetName);
                end
                
                if isempty(country{1})
                    country = {'Not Found'};
                end
                
                U.CountryStrategyInfo(i,:) = {assetName,country,industrySector,industryGroup};
                U.AssetType(i,:) = {assetName,assettype};
                %%%%%% END OF NEW FUNCTIONALITY %%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                noOfInvariants = numel(U.Assets(i).value.Invariants);
                for in=1:noOfInvariants
                    if ~isempty(U.Assets(i).value.Invariants(in))
                        date = U.Assets(i).value.Invariants(in).(U.Assets(i).value.Invariants(in).Type)(:,1);
                        firstdate = date(1);
                        lastdate = date(end);
                        maxdiff = max(diff(date));
                        name = U.Assets(i).value.Invariants(in).Name;
                        cnt = cnt + 1;
                        U.InternalInvariantsLastDate(cnt,:) = {name,firstdate,lastdate,maxdiff};
                    end
                end
            end
            
            %%%%%%%
            
        end %GetLastDateAndSectorCountry
        
        
        function [ out ] = ARIMA_recursionCaller(U, mdl,arParam, varianceParams, omega, R, Mu, VAR, R0, V0, EPS0)
            
            % ARIMA_recursionCaller: the main task of this function is to 'prepare the
            % ground' for and then launch ARIMA_recursion to infer conditional
            % volatility and standardized residuals from the return process in R
            % ARIMA_recursion.m is at the moment an external function
            
            % INPUTs:
            % -> mdl: model's descriptive field. It is a struct array with 2 subfields:
            % .Model and .varModel that refers to the AR and GARCH/GJR model
            % respectively
            % -> arParam: a scalar containing (if any) the AR(1) parameter
            % -> varianceParams: 1x3 vector containing the 3 parameters of a GARCH(1,1)
            % model(see  alpha, beta, zeta .. described below)
            % -> R: a stationary returns process of dim Tx1
            % -> Mu: vector of unconditional means associuated to R. Each value is the
            % mean of R given the time filtration F{t} with t in {1:T}
            % -> VAR: same as Mu, but w.r.t. uncond variances
            % ** IMPORTANT NOTE ** Mu and VAR are calculated using the
            % whole dataset (from time zero) since the AR-GARCH model are
            % estimated on an expanding dataset that starts from t = 0)
            % -> R0, V0, EPS0: 3 scalars representing pre-sample (t=0) return, variance
            % and innovation, needed to 'spark' the recursion
            % -> RfromT0: this is the vector of returns from t0, the same
            % used to fit AR-GARCH models. It is needed to recalulate c.
            % -> chunkStartTime: index of time where the current chunk
            % starts within the whole dataset. So it basically represents
            % the start of R within RfromT0
            
            % OUTPUTs:
            % see notes to ARIMA_recursion.m
            
            % LOGIC SUMMARY:
            % the data generation process is assumed to be, for each time t in [1:T]:
            % R(t) = Mu(t) + eps(t) = c + delta*R(t-1) + eps(t) (delta is the AR(1) estimated parameter)
            % ... -> R(t) = c + delta*R(t-1) + Z(t)*sqrt(V(t)) ->
            % ->  R(t) = c + delta*R(t-1) + Z(t)*sqrt(omega + alfa*V(t-1) + beta*V(t-1))
            
            % if there is no AR model then Mu(t) is assumed to be equal to the
            % unconditional mean Mu(t)
            % if there is no model for variance then V(t) is assumed to be equal to the
            % unconditional variance VAR(t)
            
            % Basically I am assuming that the AR and GARCH/GJR parameters are 'true'
            % w.r.t. the data in R, whatever the chunk of data they have been estimated
            % upon. However the model created using 'estimate' within the method
            % universe.ARMAGARCH_filtering stores some parameters that imply an
            % expected value for the return process that is the one of the chunk
            % of data used for estimation.
            
            % Here, instead, I want that the bootstrap of standardized residuals is
            % based on unconditional mean of the dataset to which I am
            % APPLYING THE MODEL. Moreover unconditional mean and variance must be
            % reflective, at each point int time, of the information available up to
            % that point (so conditional on filtration F{1:t}. (See inputs Mu and VAR above)
            
            % *************************************************************************
            % *************************************************************************
            
            % R_tm1: for each t in [1:T] it equals the previous day return R(t-1). The
            % first value is the pre-sample datapoint
            R_tm1 = [R0;R(1:end-1)];
            delta = arParam; % AR(1) param (if AR(1) is modeled, otherwise delta = 0)
            
            % conditional variance parameters
            alpha = varianceParams(1);
            beta = varianceParams(2);
            zeta = varianceParams(3);
            
            T = size(R,1); % end time
            t = 0; % starting time minus 1 (time to which pre-sample datapoints refer to)
            
            % 'omega' is the constant term in the GARCH cond variance equation. It can
            % be derived analitically.  Here I define a vector of omega on [1:T] that
            % is consistent with the vector of unconditional variances VAR
            if (strcmp(mdl.varModel,'garch') | strcmp(mdl.varModel,'gjr') | strcmp(mdl.varModel,'egarch'))
                % omega = VAR.*(1 - alpha - beta - 0.5*zeta);
                omega = ones(T,1).*omega;
            elseif strcmp(mdl.varModel,'none')
                omega = VAR;
            end
            
            % defining 'inline' functions that will be used within ARIMA_recursion.m
            fV = @(omega,a,vp,b,e2p,zeta,ind) omega + a*vp + b*e2p + zeta*e2p*ind; % function modeling variance
            fZ = @(e,v) e./sqrt(v); % function modeling the 'realized' random disturbance (= standardized residuals). fV*fZ is the 'innovation' term of the realized process
            fRhat = @(mu,v,z)  mu + sqrt(v)*z;
            % ... putting them in the struct array F
            F.fV = fV;
            F.fZ = fZ;
            F.fRhat = fRhat;
            
            % pre-allocating final outputs
            R_hat = zeros(T,1);
            V = zeros(T,1);
            Z = zeros(T,1);
            Radj = zeros(T,1);
            Const = zeros(T,1);
            EPS = zeros(T,1);
            
            % invoking ARIMA_recursion.m that wil call itself recursively to yield the
            % main outputs over [1:T]
            [ R_hat,V,Z,EPS,Radj,Const,~ ] = ARIMA_recursion(mdl, R, R_tm1, V0, EPS0, t, T, delta, alpha, beta, zeta, omega, R_hat, Radj, V, Z, EPS, Mu, Const, F);
            
            out.R_hat = R_hat;
            out.condVariance = V;
            out.stdResiduals = Z;
            out.Residuals = EPS;
            out.Radj = Radj;
            out.Const = Const;
            
        end % ARIMA_recursionCaller
        
    end % methods
    
    
    methods(Static)
        function [M,S]=Log2LinearRet(Mu,Sigma) % *************************
            % log to simple returns (over long horizon a 2nd order
            % adjustment is required to preserve accuracy)
            M=exp(Mu+(1/2)*diag(Sigma))-1;
            S=exp(Mu+(1/2)*diag(Sigma))*exp(Mu+(1/2)*diag(Sigma))'.*(exp(Sigma)-1);
        end
        
        function [p,PHI] = Joint_Invariants_CharF(X) % ***************************
            % TODO: put checks to be sure that p sums to 1
            % INPUT:
            % X: a matrix containing a multivariate (or even univariate
            % distrib). Rows are scenarios (J). Columns are risk factors (K)
            % OUTPUT:
            % p: empirical probabilities
            % PHI: structure containing the numericalli evaluated char
            % fucntion values and the 'omega vector'
            
            J = size(X,1); % no of joint historical scenarios
            K = size(X,1); % no of joint rvs
            p=ones(J,1)/J; % empirical probability of each joint scenario
            dw = 0.01; % granularity
            % NUMERICALLY DERIVED CHARACTERISTIC FUNCTION THROUGH FOURIER
            % TRANSFORM
            % TODO: USE FFT
            for w=-pi:dw:pi % range di frequenze che prendo in considerazione [-pi pi] va bene per chp PHI(w) è periodica di periodo 2pi
                cnt = cnt+1;
                % utilizzo @Norm_characteristic er determinare l'integrando della
                % funzione caratteristica
                PHI_empirical(cnt,1) = exp(i.*w.*X)'*(p); % integrazione su x per ogni omega
                omega_N(cnt) = w;
            end
            PHI.EmpiricalValues = PHI_empirical;
            PHI.omega = omega_N;
            % plot(omega_N,(PHI_empirical),'r');
            % legend('Analytic','Numerical from characteristic F')
            
        end % end Joint_InvariantsDistrib
        
        function [p_,exitflagU,exitflagC] = EntropyOptim(p,A,b,Aeq,beq,mxiter,algorithm_1,algorithm_2,tfun,tstep,gradobj,hessian) % **********************
            % Entropy Pooling Computation 
            
            % High Level logic; this function (by A. Meucci) implements the
            % entropy pooling optimization, as described in Fully Flexible
            % Views: Theory and Practice1, Meucci 2010. Two cases are
            % trated separately;
            % 1) optimizations that do not include inequality constraints
            % (A and b are empty)
            % 2) optimizations that include inequality constraints 
            % (A and b are non empty)
            % In both cases Meucci chooses to solve the DUAL problem (see
            % my notes in EP_optimCodeExplained.pds in the \DOC folder). 
            % For (1) the dual is defined within the nested function nestedfunU
            % For (2) the dual is defined within the nested function nestedfunC
            
            % Note: , Aeq and Beq should always contain at least the 
            % total probability constraint: sum(p)=1
            
            % INPUTS:
            % [J x 1] vector of prior probabilities (normally they are all
            % equal to 1/J, where J is the no of simulated outcomes)
            % A,b to setup inequality constraints of the form Ax<=b, A is a
            % matrix of dimension [m x J], where m is the no of ineq constraints
            % b is an [m x 1] vecotr
            % Aeq,beq to setup inequality constraints of the form Aeq*x=beq, 
            % Aeq is a matrix of dimension [n x J], where m is the no of eq. constraints
            % beq is an [n x 1] vecotr
            
            % OUTPUTS:
            % p_: posterior probabilities vector
            % exitflagU: exit flag from nestedfunU
            % exitflagC; exit flag from nestedfunC
            
            exitflagC = []; % to evaluate convergence
            exitflagU = []; % to evaluate convergence
            K_= size(A,1);
            K = size(Aeq,1);
            A_=A';
            b_=b';
            Aeq_=Aeq';
            beq_=beq';
            x0 = ones(K_+K,1);
            % setup of inequality constraints used within nestedfunC to
            % constrain the Lagrange multipliers related to the inequality
            % constraints to be positive
            InqMat=-eye(K_+K); InqMat(K_+1:end,:)=[];
            InqVec=zeros(K_,1);
            
%             % options used to optimize nestedfunU with fminunc
%             options_1 = optimoptions(@fminunc,'Algorithm',algorithm_1,'GradObj',gradobj,'Hessian',hessian,'Display','notify-detailed','MaxIter',mxiter,'TolFun',tfun); % iter-detailed
%             % options used to optimize nestedfunC with fmincon
%             options_2 = optimoptions(@fmincon,'Algorithm',algorithm_2,'GradObj',gradobj,'Display','notify-detailed', ...
%                 'MaxIter',mxiter,'TolFun',tfun,'TolCon',tcon); % iter-detailed
            
            % options used to optimize nestedfunU with fminunc
            options_1 = optimoptions(@fminunc,'Algorithm',algorithm_1,'GradObj',gradobj,'Hessian',hessian,'Display','notify-detailed','MaxIter',mxiter,'OptimalityTolerance',tfun); % iter-detailed
            % options used to optimize nestedfunC with fmincon
            options_2 = optimoptions(@fmincon,'Algorithm',algorithm_2,'GradObj',gradobj,'Display','notify-detailed', ...
                'MaxIter',mxiter,'OptimalityTolerance',tfun,'StepTolerance',tstep); % iter-detailed
            
            % ** options_2 = optimoptions(@fmincon,'GradObj',gradobj,'Hessian','user-supplied','HessFcn',@hessianfcn,'Display','notify-detailed', ...
            % ** 'MaxIter',mxiter,'TolFun',tfun,'TolCon',tcon); % iter-detailed
            
            % ****  CALL THE OPTIMIZERS ***********************************
            
            if ~K_% case 1: no inequality constraints case
                [v,fval,exitflagU,outputU]=fminunc(@nestedfunU,x0,options_1);
                p_=exp(log(p)-1-Aeq_*v);
            else % case 2: there are inequality constraints 
                [lv,fval,exitflagC,outputC]=fmincon(@nestedfunC,x0,InqMat,InqVec,[],[],[],[],[],options_2);
                l=lv(1:K_);
                v=lv(K_+1:end);
                p_=exp(log(p)-1-A_*l-Aeq_*v);
            end
            % *************************************************************
            
            % ****  DUAL PROBLEM (MAXIMIZATION) for case 1
            % with no inequality constraints (see notes for the details)
            function [mL g H] = nestedfunU(v) % maximize od the Lagrange multiplier v
                
                x=exp( log(p)-1-Aeq_*v ); % from setting to zero dL/dx and solving for p_ (then use x=p_)
                x=max(x,10^(-32)); % to ensure that log(x) is defined
                L=x'*(log(x)-log(p)+Aeq_*v)-beq_*v; % dual function of v to be maximized
                mL=-L;
                
                % dL/dv and ddl/dv^2 provided analitically
                g = [beq-Aeq*x];
                H = [Aeq*((x*ones(1,K)).*Aeq_)];  % Hessian computed by Chen Qing, Lin Daimin, Meng Yanyan, Wang Weijun
            end
            
            % ****  DUAL PROBLEM (MAXIMIZATION) for case 2
            % with inequality  constraints (see notes for the details)
            function [mL g H] = nestedfunC(lv) % maximize od the Lagrange multipliers l and v
                
                l=lv(1:K_);
                v=lv(K_+1:end);
                x=exp( log(p)-1-A_*l-Aeq_*v );  % from setting to zero dL/dx and solving for p_ (then use x=p_)
                x=max(x,10^(-32)); % to ensure that log(x) is defined
                L=x'*(log(x)-log(p))+l'*(A*x-b)+v'*(Aeq*x-beq);  % dual function of v and l to be maximized
                mL=-L;
                
                % gradient [dL/dv dL/dl] and Hessian provided analitically
                g = [b-A*x; beq-Aeq*x];
                H = [A*((x*ones(1,K_)).*A_)  A*((x*ones(1,K)).*Aeq_) % Hessian computed by Chen Qing, Lin Daimin, Meng Yanyan, Wang Weijun
                    Aeq*((x*ones(1,K_)).*A_)   Aeq*((x*ones(1,K)).*Aeq_)];
            end
            
        end % EntropyOptim
        
        function p_ = Bayes_Posterior() % **********************
            % to implement Bayes Posterior drivation
            % (start with analytic formulatgioon then decide if to go
            % ahhead with e.g. Metropolis-Hastings distrib simulation)
        end
        
        function [SignalHistory,SignalStructure,DriverS_changes,Prior_Changes] = MultipleSignals(Driver,StartingTime)
            % this function is used to create a 'SignalHistory' (to be used for
            % dynamic AA purpose) based on a signal contained in the input
            % Driver.signal, generated by an algorithm (method) of class QuantSignal
            % It is designed to be called iteratively within the AlgoViews method to
            % generate a strucutre of signals each one of whom based on a different
            % timeseries
            
            % INPUT:
            % Driver: a structured array with fields:
            % .prices: (not strictly needed here): this is the timeseries than generated the signal
            % ..Signal: signal that is used to generate SignalHistory and the remaining
            % output data;
            % StartingTime: is the first element of the vector Driver.Signal that must
            % be considered to generate the output
            % OUTPUT:
            % SignalHistory: this is basically the same as Driver.Signal, but starting
            % from time = StartingTime
            % SignalStructure: main output: this field will contain the
            % details of the signals generated by a specific instance of
            % class Quantsignals and its structure will vary based on the
            % specific strategy
            % 1) index of the previous peak or bottom (i.e. preceding the last signal)
            % 2) abs mean return from the previous peak or bottom (not needed: TODO:
            % REVIEW)
            % 3) time (in the same unit used for the input timeseries) from the previous peak or bottom
            
            %   Detailed explanation goes here
            
            n = 4; % no of columns needed in Settings
            L = size(Driver.prices,1);
            LastCross = 1.*ones(L,1);
            PrevMxMn_i = 1;
            SignalStructure = zeros(L,n); % preallocation of the matrix
            
            DriverS_changes = 0;
            Prior_Changes = zeros(L,1);
            MinSignalLag = 0; % TODO: parametrize this and other params
            waitsignal = 1;
            
            for t = 10:L
                
                %   Driver.Signal = Signals.mng(:,PrevMxMn_i); % *****************
                SignalHistory(t,1) = Driver.Signal(t);
                
                if t<=StartingTime
                    SignalStructure(t,1) = 1;
                    SignalStructure(t,2) = mean(price2ret(Driver.Signal(1:t,1)));
                    SignalStructure(t,3) = t;
                    continue;
                end
                if Driver.prices(t,1)>Driver.Signal(t,1) & Driver.prices(t-1,1)<=Driver.Signal(t-1,1)
                    DriverS_changes = DriverS_changes + 1;
                    [PrevMxMn,PrevMxMn_i] = min(Driver.prices(LastCross(t):t,1));
                    PrevMxMn_i = PrevMxMn_i + LastCross(t)  - 1;
                    %LastCross(t:end,1) = t;
                    Prior_Changes(t) = 1;
                    waitsignal = 0;
                    type = 1;
                elseif Driver.prices(t,1)<Driver.Signal(t,1) & Driver.prices(t-1,1)>=Driver.Signal(t-1,1)
                    DriverS_changes = DriverS_changes + 1;
                    [PrevMxMn,PrevMxMn_i]  = max(Driver.prices(LastCross(t):t,1));
                    PrevMxMn_i = PrevMxMn_i + LastCross(t)  - 1;
                    %LastCross(t:end,1) = t;
                    Prior_Changes(t) = 1;
                    waitsignal = 0;
                    type = -1;
                end
                
                if t-PrevMxMn_i > MinSignalLag & waitsignal == 0
                    SignalStructure(t:end,1) = PrevMxMn_i; % index of previous peak or bottom
                    ph = Driver.Signal(PrevMxMn_i:t,1);
                    ph(ph==0) = [];
                    SignalStructure(t:end,2) = mean(ph); % abs return from the previous peak or bottom
                    SignalStructure(t:end,3) = t-PrevMxMn_i; % time from the previous peak or bottom
                    SignalStructure(t:end,4) = type;
                    LastCross(t:end,1) = t;
                    waitsignal = 1;
                else
                    Prior_Changes(t) = 0;
                    SignalStructure(t:end,3) = t-PrevMxMn_i; % time from the previous peak or bottom (must reflect the real length anyway)
                end
            end
            
        end %MultipleSignals
        
        
        % ****************************************************************
        function [PHI] = PDF2CHAR(X,p)
            % this function converts the empirical (or even parametric) joint
            % distribution in X) into the corresponding Characteristic function
            % IMPORTANT: THIS IS A FIRST APPROXIMATE IMPLEMENTATION
            % TODO: IMPLEMENT A MORE PRECISE AND EFFICIENT FFT ALGORITHM
            
            % INPUTS:
            % X: joint scenarios. Dimension is [JxK], when J (time dim) is the no
            % of obs and K is the no of random variables
            % p: empirical probability of each joint scenario
            
            dw = 0.05; % omega granularity
            
            J = size(X,1);
            % p=ones(J,1)/J; % empirical probabilities
            cnt1 = 0;
            
            tic
            
            clear omega_N PHI_empirical_3 COV_N;
            for w1=-pi:dw:pi % range di frequenze che prendo in considerazione [-pi pi] va bene per chp PHI(w) è periodica di periodo 2pi
                cnt1 = cnt1 + 1;
                cnt2 = 0;
                for w2=-pi:dw:pi
                    cnt2 = cnt2 + 1;
                    cnt3 = 0;
                    for w3=-pi:dw:pi
                        cnt3 = cnt3 + 1;
                        % utilizzo @Norm_characteristic per determinare l'integrando della
                        % funzione caratteristica
                        PHI_empirical_3(cnt1,cnt2,cnt3) = exp(i.*(X*[w1 w2 w3]'))'*(p); % integrazione su x per ogni omega
                        omega_N(cnt3) = w3;
                        
                    end
                end
            end
            
            toc
            
            [a,ai] = min(abs(omega_N-0));
            % ****************************************************************
            
            function [w_,cnt] = nestedfor(dw)
                
            end
            
        end % PDF2CHAR
        
        function [Y] = ResampleInvariants(X,Nsim, HorizonDays, method)
            % The purpose of this method is to re-sample from the
            % Nsim simulated scenarios HorizonDays times (one re-sampling
            % for each day in the investment horizon)
            
            % INPUTS:
            % X: [J,N] matrix of N simulated risk factors (J joint scenarios)
            % Nsim: no of samples
            % Horizon: time dimension of resampled scenarios
            % method: 'bootstrap' only for now
            
            % OUTPUT:
            % Y: a [Nsim x no of invariants x HorizonDays] matrix of
            % resampled joint scenarios. Summing along the time dimension
            % will yield the invariants final distribution at the investment
            % horizon
            
            nX = size(X,1);
            
            if strcmp(method,'bootstrap') % only this method for now
                
                extracted_occurrences = unidrnd(nX, HorizonDays, Nsim);
                for t=1:HorizonDays
                    % temp(:,:) = (X(extracted_occurrences,:));
                    Y(:,:,t) = X(extracted_occurrences(t,:)',:);
                end
                
            end
            
        end % ResampleInvariants
        
        function [InterpValues] = CurveInterp(curve,dt,maturity,type,allowed_dtrange)
            % this method is used in various places to interpolate a value
            % on the discount or yield curve
            % INPUT:
            % curve: must be the field 'Curve' of an object of class IR_Curve;
            % dt: the date for which the ytm, rate, discount, spread, etc.. is needed
            % maturity: the maturity or pillar, tenor, etc. on the curve (this can be a vector: in this case
            % the output will be a corresponding set of interpolated values )
            % type: = 'df','rates','CDS_interp',.. etc.
            % allowed_dtrange: if no curve is found as of date dt, then a
            % search is made over a period extending to the next
            % allowed_dtrange days (or the previous allowed_dtrange days if allowed_dtrange < 0)
            
            % TODO: improve interpolation when possible (expand on the commented
            % lines before) and consider a mix of interpolation along time
            % and tenors to avoid jumps
            % *************************
            % [time,tenors] = ndgrid(curve.dates(frange),curve.tenors_yf);
            % F = griddedInterpolant(time,tenors,curve.CDS(frange,:),'nearest','nearest');
            % F(dt.*ones(1,size(maturity,1))',maturity); % interpolated values
            % *************************
            
            fd = [];
            dsearch = dt;
            sa = sign(allowed_dtrange);
            
            abs_allowed_dtrange = abs(allowed_dtrange);
            while isempty(fd)
                fd = find(curve.dates == dsearch);
                dsearch = dsearch + 1.*sa;
                abs_allowed_dtrange = abs_allowed_dtrange - 1;
                if abs_allowed_dtrange == 0
                    break;
                end
            end
            if isempty(fd)
                disp('Refernce date for the curve not found');
                InterpValues = NaN;
                return; % returning a NaN
                % pause; % TODO: manage errors here
            end
            
            X = curve.tenors_yf';
            Y = curve.(type)(fd,:)';
            fm = find(ismember(maturity,X));
            if ~isempty(fm)
                InterpValues = Y(fm);
            else
                InterpValues = interp1(X,Y,maturity,'linear','extrap');
            end
        end % CurveInterp
        
        function cell_row = Write_Output_Check(dt,wording,data,nassets)
            % function used to setup some partial output for checks within
            % the Backtest methods
            cell_row = cell(1,nassets+2);
            cell_row{1,1} = dt;
            cell_row{1,2} = wording;
            for j=1:size(data,2)
                cell_row{1,j+2} = data(j);
            end
        end % Write_Output_Check
        
        function converted = ConvertFX(ForeignCurDenominated,currencies,ExchangeRates,dt,exchdir)
            % this function converts, as of date dt, in EUR the values in
            % 'ForeignCurDenominated', whose currency of denomination are in
            % 'currencies', based on the infos (hist timeseries fts objects having the same names used in currencies)
            % contained in ExchangeRates (see AA_DashBoard where this
            % structure is created): IT MUST HAVE THE SAME NO OF ROWS AS
            % THE COLUMNS IN ForeignCurDenominated AND ITS CURRENCIES MUST
            % BE THE CURRENCIES OF THE ASSETS IN THE COLUMNS OF ForeignCurDenominated
            % INPUT:
            % ForeignCurDenominated: row vector of values (it can be a matrix of such row vectors,
            % in which case the output will be a matrix as well)
            % currencies: row cell array of currency names (e.g. JPY, USD, EUR, ...etc.)
            % ExchangeRates: struct array containing a multiple fts object (whose fields have the names
            % of the various currencies)
            % exchdir = 'FXEUR' to convert from FX denominated to EUR
            %         = 'EURFX' for conversion in the opposite direction
            
            % The basic assumption for this function to work is that the
            % values in ForeignCurDenominated are denominated in the
            % currencies of the corresponding elements of currencies
            if ~(size(ForeignCurDenominated,2) == size(currencies,1))
                disp('The size of the vector of FCY denominated values');
                disp('does not equal the size of the currency vector');
                disp('stop and check before continuing');
                pause;
                return
            end
            
            for k=1:size(ForeignCurDenominated,2)
                if strcmp(currencies{k},'EUR')
                    exch_rate = 1;
                else
                    %ts = extfield(ExchangeRates, currencies{k});
                    %exch_rate = fts2mat(ts(datestr(dt)));
                    exch_rate = ExchangeRates{datestr(dt), currencies{k}};
                end
                if strcmp(exchdir,'FXEUR')
                    converted(:,k) = ForeignCurDenominated(:,k)./exch_rate;
                elseif strcmp(exchdir,'EURFX')
                    converted(:,k) = ForeignCurDenominated(:,k).*exch_rate;
                end
            end
        end % ConvertFX
        
        function [Aeq,beq,A,b] = Views2Constraints(X,views)
            % this function sets up the set of equality and inequality
            % constraints
            % TODO: REVIEW after recent developments: much stuff no more
            % needed here
            
            Mu_View = views.mu;
            
            N = size(X,2);
            J = views.J;
            D_I_matching = views.D_I_matching;
            % id = 1 uses inequalities instead of equalities for implementing the views
            % (not only to restore pre copula simulation covariances)
            % The boundary for the approximated cov values are set through
            % view_covdown and view.covup
            relaxed = views.relaxed;
            
            % Equality Constraints
            Aeq = []; beq = [];
            A = []; b = [];
            Aeq = ones(1,J);  % constrain probabilities to sum to one...
            beq=1;
            % constraining probabilities to be > 0
            %             A = -eye(J);
            %             b = zeros(J,1);
            % expected values
            for k=1:N
                
                if ~isnan(Mu_View(k))
                    % NaNs are skipped since they mean that there is no
                    % view on the corresponding value of the projected
                    % return
                    Aeq = [Aeq; ...
                        X(:,k)'];
                    beq = [beq; Mu_View(k)];
                end
            end
            if isfield(views,'sigma') % views on sigma can be omitted
                Sigma_View = views.sigma;
                mu = repmat(Mu_View,J,1);
                if relaxed==0
                    drivers_indx = find(sum(D_I_matching)>0); % indices of invariants corresponding to drivers
                    
                    % imposing cov constraints on invariants that are
                    % drivers too (too many contrsaints would make infeasible the
                    % Entropy Optimization that follows)
                    
                    if ~isempty(views.D_I_matching)
                        
                        for k=1:N
                            % excluding the if (to the one of j) below means considering all
                            % covariances where at least one of the term is
                            % a driver
                            for j=k:N
                                if ~isnan(Sigma_View(k,j))
                                    if sum(j==drivers_indx)>0 % if j-th inv is a driver
                                        Aeq = [Aeq; ...
                                            ((X(:,k)-mu(:,k)).*(X(:,j)-mu(:,j)))'];
                                        %                                         Aeq = [Aeq; ...
                                        %                                             (X(:,k).*X(:,j))'];
                                        beq = [beq; Sigma_View(k,j)];
                                    end
                                end
                            end
                        end
                        
                    elseif isempty(views.D_I_matching)
                        for k=1:N
                            % excluding the if (to the one of j) below means considering all
                            % covariances where at least one of the term is
                            % a driver
                            for j=k:N
                                % NaNs are skipped since they mean that there is no
                                % view on the corresponding value of the
                                % projected cov matrix
                                if ~isnan(Sigma_View(k,j))
                                    if ~isnan(Sigma_View(k,j))
                                        Aeq = [Aeq; ...
                                            ((X(:,k)-mu(:,k)).*(X(:,j)-mu(:,j)))'];
                                        beq = [beq; Sigma_View(k,j)];
                                    end
                                end
                            end
                        end
                        
                    end % if on flag 'views_copulaSim_reconditioning'
                    
                elseif relaxed==1
                    Sigma_View_up = Sigma_View.*views.covup;
                    Sigma_View_down = Sigma_View.*views.covdown;
                    
                    if ~isempty(views.D_I_matching)
                        drivers_indx = find(sum(D_I_matching)>0); % indices of invariants corresponding to drivers
                        mu = repmat(Mu_View,J,1);
                        
                        % imposing cov constraints on invariants that are
                        % drivers too (too many contrsaints would make infeasible the
                        % Entropy Optimization that follows)
                        for k=1:N
                            % excluding the if (to the one of j) below means considering all
                            % covariances where at least one of the term is
                            % a driver
                            if sum(k==drivers_indx)>0 % if k-th inv is a driver
                                for j=k:N
                                    if ~isnan(Sigma_View(k,j))
                                        if sum(j==drivers_indx)>0 % if j-th inv is a driver
                                            
                                            A = [A; ...
                                                ((X(:,k)-mu(:,k)).*(X(:,j)-mu(:,j)))'];
                                            b = [b; Sigma_View_up(k,j)];
                                            A = [A; ...
                                                -((X(:,k)-mu(:,k)).*(X(:,j)-mu(:,j)))'];
                                            b = [b; - Sigma_View_down(k,j)];
                                        end
                                    end
                                end
                            end
                        end
                    elseif isempty(views.D_I_matching)
                        for k=1:N
                            % excluding the if (to the one of j) below means considering all
                            % covariances where at least one of the term is
                            % a driver
                            for j=k:N
                                if ~isnan(Sigma_View(k,j))
                                    A = [A; ...
                                        ((X(:,k)-mu(:,k)).*(X(:,j)-mu(:,j)))'];
                                    b = [b; Sigma_View_up(k,j)];
                                    A = [A; ...
                                        -((X(:,k)-mu(:,k)).*(X(:,j)-mu(:,j)))'];
                                    b = [b; - Sigma_View_down(k,j)];
                                end
                            end
                        end
                    end
                end % if on 'relaxed' flag
            end % if there are views on sigma
            
        end % Views2Constraints function
        
        function [Aeq,beq,A,b] = SubJViews2Constraints(X,views,Aeq,beq,A,b)
            % this function sets up the set of equality and inequality
            % constraints generated by subjective views. At the moment
            % (060417) only views on proj returns and covariances are managed
            
            % INPUTS:
            % Aeq:  LHS of the system of equalities
            % beq:  RHS of the system of equalities
            % A:    LHS of the system of inequalities
            % b:    RHS of the system of inequalities
            % X:    matrix of risk factors (investment universe's invariants)
            % views: struct array containing subj views (see comments to
            % the SubjectiveViews class for details on the strucutre
            
            % OUTPUTS:
            % updated Aeq,beq,A,b: the idea is to call this method several
            % times to progressively include all subjective views
            
            
            Mu_View = views.mu;
            Mu_ViewSign = views.muSign;
            Sigma_View = views.sigma;
            Sigma_ViewSign = views.sigmaSign;
            
            N = size(X,2);
            J = views.J;
            
            if isempty(Aeq)
                Aeq = ones(1,J);  % constrain probabilities to sum to one (only once !)
                beq=1;
            end
            
            
            % *************************************************************
            % getting equalities / inequalities from views on projected
            % returns *****************************************************
            if numel(find(~isnan(Mu_View)))>0 % there is at least one non NaN
                
                for k=1:N
                    if ~isnan(Mu_View(k)) % if there is a view on the proj return for the k-th risk faactors
                        switch Mu_ViewSign{k}
                            case '='        % view is expresses as an equality
                                Aeq = [Aeq; ...
                                    X(:,k)'];
                                beq = [beq; Mu_View(k)];
                                
                            case '<'        % view is in the form 'lower than'
                                A = [A; ...
                                    X(:,k)'];
                                b = [b; Mu_View(k)];
                                
                            case '>'        % view is in the form 'higher than'
                                A = [A; ...
                                    -X(:,k)'];
                                b = [b; -Mu_View(k)];
                                
                            otherwise
                                m = msgbox([Mu_ViewSign{k}, ' is not a recognized sign for views specs (execution terminated)'] ...
                                    ,'Icon','warn','replace','modal');
                                % quit
                                return;
                        end % switch
                    end
                end % FOR on N = no of risk factors
            end % if there are views on projected returns
            
            % *************************************************************
            % getting equalities / inequalities from views on projected
            % covariances *************************************************
            if numel(find(isnan(Sigma_View)))>0 % there is at least one non NaN
                for k=1:N
                    
                    for j=k:N
                        if ~isnan(Sigma_View(k,j))
                            switch Sigma_ViewSign{k,j}
                                
                                case '='    % view is expresses as an equality
                                    Aeq = [Aeq; ...
                                        ((X(:,k)-mean(X(:,k))).*(X(:,j)-mean(X(:,j))))'];
                                    beq = [beq; Sigma_View(k,j)];
                                    
                                case '<'        % view is in the form 'lower than'
                                    A = [A; ...
                                        ((X(:,k)-mean(X(:,k))).*(X(:,j)-mean(X(:,j))))'];
                                    b = [b; Sigma_View(k,j)];
                                    
                                case '>'        % view is in the form 'higher than'
                                    A = [A; ...
                                        -((X(:,k)-mean(X(:,k))).*(X(:,j)-mean(X(:,j))))'];
                                    b = [b; -Sigma_View(k,j)];
                                    
                                otherwise
                                    m = msgbox([Mu_ViewSign{k}, ' is not a recognized sign for views specs (execution terminated)'] ...
                                        ,'Icon','warn','modal');
                                    % quit
                                    return;
                                    
                            end % switch
                        end
                    end % FOR on N = no of risk factors
                end
            end % if there are views on covariances
            
        end % SubJViews2Constraints function
        
        
        function [yflabel] = yearFract2Label(yf_numeric)
            yflabel = ['yfract',strrep(num2str(yf_numeric),'.','dot')];
        end
        
        function [yf_numeric] = Label2yearFract(yflabel)
            splitted = strsplit(yflabel,'yfract');
            yf_letters = splitted{2};
            yf_numeric = str2num(strrep(yf_letters,'dot','.'));
        end
        
        %
        function [ff,tgtfound] = Search_AA(U,params,strategy,S,timeTOsearch)
            % function invoked within U.AA_BackTest to identify the
            % desired point on the efficient frontier
            % NOTE: normally 'timeTOsearch' equals t-1 since any new
            % allocation (let's assume t is an optimization time) kicks
            % in the 'next day'
            % This has been implemented as a static method since it can
            % be invoked by other classes (see in AA_Output for
            % example)
            
            if strcmp(params.targetType,'quantile')
                % in this case the target must be provided in terms of
                % a quantile (as a pct) : eg 50 to choose the 50º
                % percentile
                d = S.Dynamic_Frontier_EP.(params.targetName)(:,timeTOsearch);
                ff = prctile(d, params.target);
                [mnd,mndi] = min(abs(d-ff)); % choose the point that is closest to the selected percentile
                ff = mndi;
                tgtfound = true(1);
                
            elseif strcmp(params.targetType,'level')
                % in this case the target must be provided in terms of
                % a range (e.g. [0.0050 0.0070]]
                
                T1 = params.target(1); % left limit of the desired range
                T2 = params.target(2); % right limit of the desired range
                tgtfound = false(1);
                
                while ~tgtfound
                    % here we search the desired dimension (ExpectedReturn or
                    % Risk) for the 'target' range (that is an input to
                    % AA_BackTest method (w.r.t. to the day being backtested, identified by 'timeTOsearch')
                    ff = find(S.Dynamic_Frontier_EP.(params.targetName)(:,timeTOsearch) >= T1 ...
                        & S.Dynamic_Frontier_EP.(params.targetName)(:,timeTOsearch) <= T2);
                    
                    if ~isempty(ff)
                        tgtfound = true(1);
                        ff = ff(1); % choose the allocation that is closer to the left limit for the desired metric
                        break
                    end
                    
                    % if there are no points on the efficient frontier that
                    % fall in the desired range, then more attempts are made to
                    % see if it is possible to select the 1st available value
                    % greater than the left bound or lower than the right bound
                    % The user gets a warning
                    % X PANOS: this should also be visible within the output
                    % file summarizing the backtest results.
                    %
                    if isempty(ff)
                        
                        msg = ['Target not found: min max on date ',datestr(S.H_dates_vector(timeTOsearch)),' are ', ...
                            num2str(S.Dynamic_Frontier_EP.(params.targetName)(1,timeTOsearch)*100),'% and ', ...
                            num2str(S.Dynamic_Frontier_EP.(params.targetName)(end,timeTOsearch)*100), ...
                            '%'];
                        m = msgbox(msg,'Icon','warn','replace');
                        
                        if T2>S.Dynamic_Frontier_EP.(params.targetName)(end,timeTOsearch)
                            % if the right target is above the highest point on the
                            % eff frontier then right target is reset to the
                            % highest point on the eff frontier
                            T2 = S.Dynamic_Frontier_EP.(params.targetName)(end,timeTOsearch);
                            % ... and if the new T2 goes below T1 then T1
                            % is reset to the new T2
                            if T2<T1
                                T1 = T2;
                            end
                            
                            msg = ['The right bound of the target range is higher than the highest point on the efficient frotnier,' ...
                                num2str(T2*100), '%: RIGHT BOUND RESET TO THE HIGHEST POINT ON THE EFFICIENT FRONTIER', ...
                                '(if the new right bound is lower than the left bound then the latter is reset equal to the right bound))'];
                            m = msgbox(msg,'Icon','warn','replace');
                            
                        elseif T1<S.Dynamic_Frontier_EP.(params.targetName)(1,timeTOsearch)
                            % if the left target is below the lowest point on the
                            % eff frontier then left target is reset to the
                            % lowest point on the eff frontier
                            T1 = S.Dynamic_Frontier_EP.(params.targetName)(1,timeTOsearch);
                            % ... and if the new T1 goes above T2 then T2
                            % is reset to the new T1
                            if T1>T2
                                T2 = T1;
                            end
                            
                            msg = ['The left bound of the target range is lower than the lowest point on the efficient frotnier,' ...
                                num2str(T1*100), '%: LEFT BOUND RESET TO THE LOWEST POINT ON THE EFFICIENT FRONTIER', ...
                                '(if the new left bound is higher than the right bound then the latter is reset equal to the left bound))'];
                            m = msgbox(msg,'Icon','warn','replace');
                            
                        else % if target still not found look for the value on the eff frontier that is closest to the mid-point of the target range
                            M = (params.target(1)+params.target(2))./2;
                            [mn,mni] = min((S.Dynamic_Frontier_EP.(params.targetName)(:,timeTOsearch) - M).^2);
                            ff = mni(1);
                            tgtfound = true(1);
                            msg = ['No target found: the point on th efficient frontier that is closest to the midpoint of the target range has been selected.' ...
                                ' It is equal to ', num2str(S.Dynamic_Frontier_EP.(params.targetName)(ff,timeTOsearch)*100) '%'];
                            m = msgbox(msg,'Icon','warn','replace');
                        end
                        
                    end % empty(ff)
                end % while
                
            end % if on targetType
            
            
            %                 U.Strategies.(strategy).BackTest.SelectedSigma(t:end,1) = S.Dynamic_Frontier_EP.Risk(ff,timeTOsearch);
            %                 U.Strategies.(strategy).BackTest.SelectedER(t:end,1) =  S.Dynamic_Frontier_EP.ExpectedReturn(ff,timeTOsearch);
            %                 U.Strategies.(strategy).TargetFoundFlag(t:end,1) = tgtfound;
            %
            %                 % Creating matrix [Time x NoAssets] with
            %                 % allocations to each asset (columns) per each
            %                 % time (rows). THEORETICAL WEIGHTS AND NO OF SHARES
            %                 for k=1:S.NAssets
            %                     nma = ['Asset_',num2str(k)];
            %                     % TRACKING ALLOCATION AS OF t
            %                     % ... in relative weights terms
            %                     U.Strategies.(strategy).BackTest.AA(t:end,k) = S.Dynamic_Frontier_EP.Allocation.(nma)(ff,timeTOsearch);
            %                     % ... in no of shares terms:
            %                     % this wouldn't be correct since at the moment
            %                     % S.Dynamic_Frontier_EP.AllocationShares_FX is
            %                     % calculated based on initial Budget and not on the
            %                     % dynamically updated NewBudget as in AA_BackTest
            %                     % U.Strategies.(strategy).BackTest.AA_shares_tplus(t:end,k) = S.Dynamic_Frontier_EP.AllocationShares_FX.(nma)(ff,timeTOsearch);
            %
            %                 end % k assets
            
        end % static function Search_AA
        
    end % static methods
end % classdef
