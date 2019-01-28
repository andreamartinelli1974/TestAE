classdef QuantSignals < handle
    % This class implements quant based strategies and creates a vector of
    % signals (or a structure containing several vectors) as a property of
    % the class that can be used in different  applications.
    % For now only the SignalGen_1 algo is implemented.
    
    properties (SetAccess = immutable)
    end
    
    properties
        prices = [];
        params = [];
        Signal = [];
        ViewsNames = [];
        ConfidenceInSignal = []; % will remain empty if there is not an endogenous method to generate the confidence (in this case the conf in quant views as defined in the initial settings will be used)
        TradingSystem;
    end
    
    
    methods
        function Q = QuantSignals(params) % CONSTRUCTOR
            % prices: a timeseries (2 column vectors: prices, dates)
            % params: struct array containing  parameters and other inputs
            % necessary to the algorithms.
            Q.prices = params.prices;
            Q.params = params;
        end
        
        function SignalGen_1(Q) % algo 1: produces quant signals based on a simple model designed by me
            % TODO: clean and optimize the function below
%             if params.generator_choice == 1
%                 % this choice corresponds to the multiple signal generator
%                 % based on SignalGen_1 algorithm
%             
%             elseif params.generator_choice == 2
%                 % to allow further choices
%                 
%             end
            % % ************************************************
            serie(:,1) = Q.prices(:,2); % ****************
            % % ************************************************
            
            item{1,1}=['P'];
            item{2,1}=['T as divisor'];
            item{3,1}=['P as divisor'];
            item{4,1}=['S-Quadratic'];
            item{5,1}=['Quadratic'];
            item{6,1}=['Iper Quadratic'];
            item{7,1}=['Quad Squared'];
            item{8,1}=['Time Driven'];
            item{9,1}=['Simple Relative'];
            item{10,1}=['Mod Relative'];
            item{11,1}=['Normalized'];
            item{12,1}=['Q-Normalized'];
            
            %sol=input('dvd T (0),dvd p(t)(1), S-QUAD (2), D-QUAD (3), Q-SQ (4), REL (5), QUAD (6) ...: ');
            % sol=menu('Analysis type',item)
            sol = 1;
            moltip=1;
            
            % if sol==0
            %     moltip=input('Moltiplicatore....:');
            % else
            %     moltip=1;
            % end
            
            serie(:,1)=serie(:,1).*moltip;
            upd = 'N';
            filetoload{1,1}=['xx+xx'];
            %[p,lp,mn,mng,mng2,x,y,errcode]=mnmngdouble_calc(serie,upd,filetoload);
            
            T_coord(1,1) = 1; %T_COORD(1,1);
            T_coord(1,2) = 0; %T_COORD(1,2);
            
            %**************************************************************************
            [orig_p,vtime,p,lp,mn,mng,mng2,mng3,mng4,mng5,x,errcode] = Q.mnmngmultiple_calc_v3(serie,upd,filetoload,sol,T_coord);
            %**************************************************************************
            
            col='rmygbk';
            figure
            plot(p)
            grid on
            hold on
            % [xx,yy] = ginput;
            % xx=floor(xx); yy=floor(yy);
            xx = T_coord(1,1);
            
            ic=0;
            for k=1:size(xx,1)
                
                fxx=xx(k);
                if ic<7; ic=ic+1; else ic=1; end
                plot([xx(k):lp],mn(xx(k):lp,xx(k)),'-','Linewidth',1,'Color',col(ic));
                plot([xx(k):lp],mng(xx(k):lp,xx(k)),'-.','Linewidth',2,'Color',col(ic));
                if sol~=11
                    plot([xx(k):lp],mng2(xx(k):lp,xx(k)),'-','Linewidth',2,'Color',col(ic));
                    plot([xx(k):lp],mng3(xx(k):lp,xx(k)),'-','Linewidth',3,'Color',col(ic));
                    %
                    plot([xx(k):lp],mng4(xx(k):lp,xx(k)),'-','Linewidth',1,'Color',col(ic));
                    plot([xx(k):lp],mng5(xx(k):lp,xx(k)),'-','Linewidth',1,'Color',col(ic+1));
                end
                xm=(mn(xx(k):lp,xx(k))+mng(xx(k):lp,xx(k))+mng2(xx(k):lp,xx(k))+mng3(xx(k):lp,xx(k))+...
                    mng4(xx(k):lp,xx(k)))./5;
                if sol~=11
                    plot([xx(k):lp],xm,'-','Linewidth',3,'Color',col(ic+1));
                end
                % *******************************************
                % *********  dynamic weighting I ************
                pvect=p(xx(k):lp)';
                clear CMATRIX
                CMATRIX(1,:)=mn(xx(k):lp,xx(k))';   CMATRIX(2,:)=mng(xx(k):lp,xx(k))';
                CMATRIX(3,:)=mng2(xx(k):lp,xx(k))'; CMATRIX(4,:)=mng3(xx(k):lp,xx(k))';
                CMATRIX(5,:)=mng4(xx(k):lp,xx(k))';  CMATRIX(6,:)=mng5(xx(k):lp,xx(k))';
                CMATRIX(7,:)=pvect;
                
                dmatrix=CMATRIX(2:6,:);
                
                ddim=size(dmatrix,1); mdim=lp-xx(k)+1;
                [dmatrix,ORD]=sort(dmatrix,1,'descend');
                %divisor=abs(mn(xx(k):lp,xx(k))'-pvect);
                divisor=abs(max(dmatrix)-min(dmatrix));
                Wmatrix=abs(diff(dmatrix))./repmat(divisor,ddim-1,1);
                
                %Wmatrix(ORD(1:ddim-1,:)==ddim)=0;
                
                Wmng = sum(dmatrix(1:ddim-1,:).*Wmatrix);
                %plot([xx(k):lp],Wmng,'-','Linewidth',3,'Color','c');
                
                
                % *********  dynamic weighting II ************
                d2matrix=zeros(size(dmatrix));
                MN=mn(xx(k):lp,xx(k));
                for z=1:mdim
                    if pvect(z)>MN(z)
                        d2matrix(:,z)=sort(dmatrix(:,z),1,'ascend');
                    else
                        d2matrix(:,z)=sort(dmatrix(:,z),1,'descend');
                    end
                end
                divisor2=(max(d2matrix)-min(d2matrix));
                W2matrix=(diff(d2matrix))./repmat(divisor2,ddim-1,1);
                Wmng2 = abs(sum(d2matrix(1:ddim-1,:).*W2matrix));
                plot([xx(k):lp],Wmng2,'-','Linewidth',3,'Color','k');
                %*******************************************
                Wmatrix_inv=((1./W2matrix))./100;
                Wmatrix_c=Wmatrix_inv./repmat(sum(Wmatrix_inv),size(Wmatrix_inv,1),1);
                Wmng_c = abs(sum(flipud(d2matrix(1:ddim-1,:)).*W2matrix)); %oppure moltip. per Wmatrix_c (ma diverso)
                plot([xx(k):lp],Wmng_c,'-','Linewidth',3,'Color','g');
                %*******************************************
                %*******************************************
                Wmng2_2=Wmng2;
                %*******************************************
                %*******************************************
                %*******************************************
                %*******************************************
                %*******************************************
                pvect=p(xx(k):lp)';
                clear CMATRIX
                CMATRIX(1,:)=mn(xx(k):lp,xx(k))';   CMATRIX(2,:)=mng(xx(k):lp,xx(k))';
                CMATRIX(3,:)=mng2(xx(k):lp,xx(k))'; CMATRIX(4,:)=mng3(xx(k):lp,xx(k))';
                CMATRIX(5,:)=mng4(xx(k):lp,xx(k))';  CMATRIX(6,:)=mng5(xx(k):lp,xx(k))';
                CMATRIX(7,:)=pvect;
                
                dmatrix=CMATRIX(1:6,:);
                
                ddim=size(dmatrix,1); mdim=lp-xx(k)+1;
                [dmatrix,ORD]=sort(dmatrix,1,'descend');
                %divisor=abs(mn(xx(k):lp,xx(k))'-pvect);
                divisor=abs(max(dmatrix)-min(dmatrix));
                Wmatrix=abs(diff(dmatrix))./repmat(divisor,ddim-1,1);
                
                %Wmatrix(ORD(1:ddim-1,:)==ddim)=0;
                
                Wmng = sum(dmatrix(1:ddim-1,:).*Wmatrix);
                %plot([xx(k):lp],Wmng,'-','Linewidth',3,'Color','c');
                %*******************************************
                %*******************************************
                
                % *********  dynamic weighting II ************
                d2matrix=zeros(size(dmatrix));
                MN=mn(xx(k):lp,xx(k));
                for z=1:mdim
                    if pvect(z)>MN(z)
                        d2matrix(:,z)=sort(dmatrix(:,z),1,'ascend');
                    else
                        d2matrix(:,z)=sort(dmatrix(:,z),1,'descend');
                    end
                end
                divisor2=abs(max(d2matrix)-min(d2matrix));
                W2matrix=abs(diff(d2matrix))./repmat(divisor2,ddim-1,1);
                Wmng2 = sum(d2matrix(1:ddim-1,:).*W2matrix);
                plot([xx(k):lp],Wmng2,'-','Linewidth',3,'Color','c');
                
                %***********************************************************
                
                Q.Signal.Wmng2 = Wmng2;
                Q.Signal.mn = mn;
                Q.Signal.mng = mng;
                Q.Signal.mng2 = mng2;
                Q.Signal.mng3 = mng3;
                Q.Signal.mng4 = mng4;
                Q.Signal.mng5 = mng5;
                
            end % k-for
        end % SignalGen_1
        
        % *****************************************************************
        
        function EG_Coint(Q) % algo 2: produces quant signals based on cointegration
            
            rollw = Q.params.egRollWin;
            rebalf = Q.params.egRebalFreq;
            stdno = Q.params.egNoOfStd;
            alpha = Q.params.egConfLevel;
            DataFromBBG = Q.params.DataFromBBG;
            tickers = Q.params.egTickers;
            Prices = Q.params.prices;
            
            StartDt = Q.params.StartDt;
            EndDt = Q.params.EndDt;
            
            for k=1:size(tickers,1)
                tickers{k,2} = strrep(tickers{k,1},' ','_');
            end
            
            clear C;
            tickersIDvect = [1:1:size(tickers,1)]; % used to generate all possible combinations
            Combinations = combnk(tickersIDvect,2);
            exludedCombs = ismember(Combinations,Q.params.ExcludedCombinations,'rows');
            Combinations(exludedCombs,:) = [];
            spec_struct.driver_no = ['ratio']; %1;
            spec_struct.budget = 1000000; % NOT USED FOR NOW
            spec_struct.alpha = alpha;
            annualScaling = sqrt(252);
            cost = 0;
            
            tic
            for c=1:size(Combinations,1) % for each combination
                a1_id = Combinations(c,1);
                a2_id = Combinations(c,2);
                
                % create the input data structure *************************************
                clear newPriceStruct;
                newPriceStruct.DataFromBBG = DataFromBBG;
                newPriceStruct.allprices = Prices.prices(:,[a1_id,a2_id]); %Prices.Prices.allprices(:,[a1_id,a2_id]);
                newPriceStruct.dates = Prices.dates;
                newPriceStruct.Tickers = tickers([a1_id a2_id],:);
                spec_struct.input_data = newPriceStruct; % 'BBG' to get prices from Bloomberg or a struct array like 'Prices' above to provide data
                % *********************************************************************
                
                msgbox(['Running combination (',num2str(c),'/',num2str(size(Combinations,1)),': ',newPriceStruct.Tickers{1,1},' ',newPriceStruct.Tickers{2,1}], ...
                    'Testing all pairs combinations','CreateMode','replace');
                
                C(c,1) = CointegratedTradingEG(DataFromBBG,StartDt,EndDt,newPriceStruct.Tickers,'Daily',spec_struct);
                C(c,1).PairsTrading(rollw, rebalf, stdno, annualScaling, cost);
                % used to name quant views within class QuantViews since
                % there will be one possible quant view for each
                % contegrated pair
                Q.ViewsNames{c,1} = ['Cointegration_',tickers{a1_id,2},'__',tickers{a2_id,2}];
            end
            toc
            Q.Signal = C;
            
        end % EG_Coint method
        
        function CointPower(Q) % algo 3: produces quant signals based on cointegration betwwen power weekahead forwards and the underlying spot seasonality
            
            % ********  GET SPOT TIMESERIES HIST QUOTES *******
            import ViewsGen.*;
            
            
            n_cointPairs = numel(Q.params); % this depends on the settings in AA_DashBoard where 'CointPower' strategies are setup
            
            for c=1:n_cointPairs
                Q.ViewsNames{c,1} = ['SpreadCointegration_',Q.params(c).forward_tickers{1},'__',Q.params(c).forward_tickers{2}];
                Q.ViewsNames{c,1} = strrep(Q.ViewsNames{c,1},' ','_');
                fwdForcingDates = Q.params(c).forcingTimeVector;
                
                uparams.DataFromBBG = Q.params(c).DataFromBBG;
                uparams.ticker = Q.params(c).underlying_tickers;
                uparams.fields = 'LAST_PRICE';
                uparams.history_start_date = Q.params(c).start_dt;
                uparams.history_end_date = Q.params(c).end_dt;
                uparams.granularity = 'DAILY';
                U = Utilities(uparams);
                U.GetHistPrices;
                
                % for backward compatibility
                DA.LPXBHRBS_Index.ts = U.Output.HistInfo{1};
                DA.PWNXFRAV_Index.ts =  U.Output.HistInfo{2};
                
                % **********  GET WEEK AHEAD MARKET DATA *********
                
                uparams.DataFromBBG = Q.params(c).DataFromBBG;
                uparams.ticker = Q.params(c).forward_tickers;
                uparams.fields = 'PX_MID';
                uparams.history_start_date = Q.params(c).start_dt;
                uparams.history_end_date = Q.params(c).end_dt;
                uparams.granularity = 'DAILY';
                Ufwd = Utilities(uparams);
                Ufwd.GetHistPrices;
                
                C_v_f = Q.params(c).confidenceF;
                % *******  ESTIMATE SPOT SPREAD SEASONALITY *******
                              
                dates = datetime(DA.LPXBHRBS_Index.ts(:,1),'ConvertFrom','datenum'); % dates GE
                Spot.Daily.GE = timetable(dates,DA.LPXBHRBS_Index.ts(:,2));          % GE spot timetable
                dates = datetime(DA.PWNXFRAV_Index.ts(:,1),'ConvertFrom','datenum'); % dates FR
                Spot.Daily.FR = timetable(dates,DA.PWNXFRAV_Index.ts(:,2));          % FR spot timetable
                % remove outliers
                Spot.Daily.GE = filloutliers(Spot.Daily.GE,'previous','movmedian',[days(250) days(0)],'ThresholdFactor',5)
                Spot.Daily.FR = filloutliers(Spot.Daily.FR,'previous','movmedian',[days(250) days(0)],'ThresholdFactor',5)
                
                % merge the 2 spot series on the intersection of the dates vectors
                Spot.Daily.GEFR = synchronize(Spot.Daily.GE,Spot.Daily.FR,'intersection');
                Spot.Daily.GEFR.Properties.VariableNames{1} = 'GE';
                Spot.Daily.GEFR.Properties.VariableNames{2} = 'FR';
                
                Spot.Daily.Spread = timetable(Spot.Daily.GEFR.dates, Spot.Daily.GEFR.GE, Spot.Daily.GEFR.FR, Spot.Daily.GEFR.GE - Spot.Daily.GEFR.FR,'VariableNames',{'GE','FR','spotDailySpread'});
                
                seasonalityFunction = Q.params(c).seasParams.seasonalityFunction;
                initWin4SeasNorm = Q.params(c).seasParams.initWin4SeasNorm;
                seasEstChunkLength = Q.params(c).seasParams.seasEstChunkLength;
                seasRollWin = Q.params(c).seasParams.seasRollWin; % 0 to use an expanding widnow; no of day making up the rolling window otherwise. MUST BE > initWin4SeasNorm
                Tspot = size(Spot.Daily.Spread,1);
                
                % trig poly used within class seasonality
                switch  seasonalityFunction
                    case 0
                        seas_f = @(x,yf) x(1) + x(2).*yf + x(3).*sin(2.*pi.*yf + x(4)) + x(5).*cos(2.*pi.*yf + x(6)) ...
                            + x(7).*sin(4.*pi.*yf + x(8)) + x(9).*cos(4.*pi.*yf + x(10));
                        n_unknowns = 10;
                    case 1
                        
                        seas_f = @(x,yf) x(1) + x(2).*yf ...
                            +  x(3).*sin(2.*pi.*yf + x(4)) + x(5).*cos(2.*pi.*yf + x(6)) ...
                            + x(7).*sin(4.*pi.*yf + x(8)) + x(9).*cos(4.*pi.*yf + x(10)) ...
                            + x(11).*sin(108.*pi.*yf + x(12)) + x(13).*cos(108.*pi.*yf + x(14));
                        n_unknowns = 14;
                    case 2
                        seas_f = @(x,yf) x(1).*yf ...
                            +  x(2).*sin(2.*pi.*yf + x(3)) + x(4).*cos(2.*pi.*yf + x(5)) ...
                            + x(6).*sin(4.*pi.*yf + x(7)) + x(8).*cos(4.*pi.*yf + x(9)) ...
                            + x(10).*sin(108.*pi.*yf + x(11)) + x(12).*cos(108.*pi.*yf + x(13));
                        n_unknowns = 13;
                end
                
                tmpSpread = [datenum(Spot.Daily.Spread.Time),Spot.Daily.Spread.spotDailySpread]; % used to estimate seasonality
                seasEst = zeros(Tspot,3);
                for t=initWin4SeasNorm:seasEstChunkLength:Tspot
                    
                    final_t = min(t+seasEstChunkLength,Tspot); % latest point in time considered as of each iteration
                    t_yf = (tmpSpread(t:final_t,1) - datenum([year(tmpSpread(t,1)) 1 1]))./365;
                    
                    if seasRollWin==0
                        start_t = 1;
                    elseif seasRollWin>0
                        start_t = t - seasRollWin;
                    end
                    S = seasonality(tmpSpread(start_t:t-1,:),7,seas_f,n_unknowns);
                    seasEst(t:final_t,1) = tmpSpread(t:final_t,1); % dates
                    seasEst(t:final_t,2) = tmpSpread(t:final_t,2); % spread (no outliers)
                    seasEst(t:final_t,3) = seas_f(S.x,t_yf);       % spread seasonal norm
                    
                    if t+seasEstChunkLength > Tspot
                        break
                    end
                end
                
                % seasEst = seasEst(initWin4SeasNorm+1:end,:);
                
                Spot.Daily.Spread.SeasonalNorm = seasEst(:,3);
                Spot.Daily.Spread(1:initWin4SeasNorm-1,:) = []; % remove the initial initWin4SeasNorm rows
                Spot.Daily.Spread.Properties.VariableNames = {'GE','FR','spotDailySpread'  'dailySeasonalNorm'};
                
                % ***************  AGGREGATE INTO WEEKLY DATA  ***************
                % vector of dates that are 'Sundays': these dates will be the right edges
                % of the buckets used to aggregate data through the mean computation, so
                % that each time will be a Sunday and the corresponding price will be the
                % average price for the week ended that Sunday
                newWeeklyTimeVector = Spot.Daily.Spread.Time(weekday(Spot.Daily.Spread.Time)==1);
                Spot.Weekly.Spread = retime(Spot.Daily.Spread,newWeeklyTimeVector,'mean','IncludedEdge','right');
                Spot.Weekly.Spread.Properties.VariableNames = {'GEwkAvg','FRwkAvg','spotWeeklySpread'  'weeklySeasonalNorm'};
                Spot.Weekly.Spread.Week = week (Spot.Weekly.Spread.Time);
                Spot.Weekly.Spread.Year = year (Spot.Weekly.Spread.Time);
                % subtracting one since for Matlab weeks start on Sundays. This dates
                % vector contains Sundays only. In this way consistency between these week
                % indicaros and the one used later for daily timeseries is guaranteed
                Spot.Weekly.Spread.Week = Spot.Weekly.Spread.Week - 1;
                
                % for debugging purposes (plot estimated seasonality)
                figure
                plot(Spot.Weekly.Spread.Time,Spot.Weekly.Spread.spotWeeklySpread,'DisplayName','Spot.Weekly.Spread.spotWeeklySpread');
                grid on;
                hold on;
                plot(Spot.Weekly.Spread.Time,Spot.Weekly.Spread.weeklySeasonalNorm,'DisplayName','Spot.Weekly.Spread.weeklySeasonalNorm','LineWidth',2);
                legend({'GE-FR Spot spread','Seasonal norm spread'})
                ylabel('eur/MWh')
                xlabel('Time');
                title('Weekly spread and weekly spread seasonal norm');
                
                % ******  DYNAMIC COINTEGRATING RELATIONSHIP ESTIMATION  ******
                data = [Spot.Weekly.Spread.spotWeeklySpread Spot.Weekly.Spread.weeklySeasonalNorm];
                
                % test the cointegration hypothesys at each point in time and compute the
                % cointegrating vector
                Cointegration.burnIn = Q.params(c).cointParams.burnIn;  % initial min windows (in weeks) used to estimate the relationship
                Cointegration.movWIn = Q.params(c).cointParams.movWIn;  % 0 to use an expanding window from t0; otherwise the width (in weeks here) of the rolling windows to be used
                Cointegration.stdMovWIn = Q.params(c).cointParams.stdMovWIn; % 0 to compute the STD from the first meaningful 'relationship piece of data'; otherwise the width (in weeks here) of the rolling windows to be used
                
                Cointegration.Data = Spot.Weekly.Spread;
                Cointegration.T = size(data,1);
                Cointegration.Data.hTest(1:Cointegration.T) = 0;
                Cointegration.Data.pval(1:Cointegration.T) = NaN;
                Cointegration.Data.cointVector(1:Cointegration.T) = cell(Cointegration.T,1);
                
                tic % ****************************************************
                first = 0;
                for t=1:Cointegration.T
                    Cointegration.Data.cointVector{t} = [0 0];
                    
                    if Cointegration.movWIn==0
                        if t<=Cointegration.burnIn % burn-in window: no signals will be generated here
                            continue
                        end
                        start_t = 1;
                    end
                    
                    if Cointegration.movWIn>0
                        start_t = t - Cointegration.movWIn;
                        
                    end
                    
                    if start_t>0
                        first = first + 1;
                        final_t = t - 1;
                        dataSubset = data(start_t:final_t,:);
                        [h,pValue,stat,cValue,reg1,reg2] = egcitest(dataSubset);
                        Cointegration.Data.hTest(t) = h;
                        Cointegration.Data.pval(t) = pValue;
                        Cointegration.Data.cointVector{t} = [reg1.coeff(1),reg1.coeff(2)];
                        relationship = dataSubset*[1,-reg1.coeff(2)]' - reg1.coeff(1);
                        Cointegration.Data.Relationship(t) = relationship(end);
                        
                        % **** Moving measure of dispersion for the cointegration relationship ****
                        if first==1 % first meaningful piece of data for the cointegration relationship (cir)
                            Cointegration.relationshipFirstMeaningfulTime = Cointegration.Data.Time(t); % ** date of the first meaningful value
                            first_t = t;
                        elseif first>1
                            % compute the measure of dispersion for the cir
                            if Cointegration.stdMovWIn==0
                                % uding an expanding windows from the first time
                                Cointegration.Data.cirMean(t) = mean(Cointegration.Data.Relationship(first_t:t));
                                Cointegration.Data.cirDispersion(t) = std(Cointegration.Data.Relationship(first_t:t));
                            elseif Cointegration.stdMovWIn>0
                                % using an expanding window for the initial 'stdMovWIn'
                                % weeks of meaningful data end then the moving window set
                                % forth in 'stdMovWIn'
                                if t-first_t > Cointegration.stdMovWIn
                                    Cointegration.Data.cirMean(t) = mean(Cointegration.Data.Relationship(t-Cointegration.stdMovWIn:t));
                                    Cointegration.Data.cirDispersion(t) = std(Cointegration.Data.Relationship(t-Cointegration.stdMovWIn:t));
                                else
                                    Cointegration.Data.cirMean(t) = mean(Cointegration.Data.Relationship(first_t:t));
                                    Cointegration.Data.cirDispersion(t) = std(Cointegration.Data.Relationship(first_t:t));
                                end
                                
                            end % if about using Cointegration.stdMovWIn
                        end % if on the first meaningful cir piece of data
                        % *************************************************************************
                        
                    end % if on start_t>0
                end % main t loop
                toc
                
                Cointegration.firstTime4Signal = first_t; % index of 1-st time that can be used for the trading system
                % for debugging purposes (plot estimated seasonality): to plot
                % the cointegration relationship
                figure;
                plot(Cointegration.Data.Time(first_t:end),Cointegration.Data.Relationship(first_t:end) );
                grid on; hold on;
                plot(Cointegration.Data.Time(first_t:end),Cointegration.Data.cirMean(first_t:end) + Cointegration.Data.cirDispersion(first_t:end),'g');
                plot(Cointegration.Data.Time(first_t:end),Cointegration.Data.cirMean(first_t:end) - Cointegration.Data.cirDispersion(first_t:end),'g');
                plot(Cointegration.Data.Time(first_t:end),Cointegration.Data.cirMean(first_t:end) + 2.*Cointegration.Data.cirDispersion(first_t:end),'r');
                plot(Cointegration.Data.Time(first_t:end),Cointegration.Data.cirMean(first_t:end) - 2.*Cointegration.Data.cirDispersion(first_t:end),'r');
                plot(Cointegration.Data.Time(first_t:end),Cointegration.Data.cirMean(first_t:end) - 3.*Cointegration.Data.cirDispersion(first_t:end),'c');
                title('Cointegration relationship');
                
                figure; grid on; hold on;
                plot(Cointegration.Data.Time(first_t:end),Cointegration.Data.pval(first_t:end) );
                plot(Cointegration.Data.Time(first_t:end),0.05.*ones(1,Cointegration.T-first_t+1),'-.r');
                legend({'pvalues','rejection threshold'});
                title('Cointegration relationship significance (pvalues)');
                
                % ************  CREATE A TRADED SPREAD TIMESERIES  ************
             
                dates = datetime(datestr(Ufwd.Output.HistInfo{1}(:,1)),'ConvertFrom','datenum');
                wkaGE_fts = timetable(dates,Ufwd.Output.HistInfo{1}(:,2));
                wkaGE_fts.Properties.VariableNames = {'Price'}; % Germany week ahead timeaseries
                dates = datetime(datestr(Ufwd.Output.HistInfo{2}(:,1)),'ConvertFrom','datenum');
                wkaFR_fts = timetable(dates,Ufwd.Output.HistInfo{2}(:,2));
                wkaFR_fts.Properties.VariableNames = {'Price'}; % France week ahead timeaseries
                
                Forward.Daily.GE = wkaGE_fts;
                Forward.Daily.FR = wkaFR_fts;
                Forward.Daily.GEFR = synchronize(Forward.Daily.GE,Forward.Daily.FR,'intersection');
                Forward.Daily.GEFR.Properties.VariableNames{1} = 'GE';
                Forward.Daily.GEFR.Properties.VariableNames{2} = 'FR';
                
                Forward.Daily.Spread = timetable(Forward.Daily.GEFR.dates,Forward.Daily.GEFR.GE ...
                    - Forward.Daily.GEFR.FR,'VariableNames',{'fwdDailySpread'});
                
                % ************************ TRADING SIGNALS ********************
                % Note: 2 trading strategies based on the same 'enter trade' trigger  signal
                % are implemented below. The difference between the 2s is in the closing
                % date.
                
                % 1) in strategy 1 the trade is always closed on the Friday of the same
                % trading week
                % 2) in strategy 2 the trade is closed thorugh delivery on the fololowing
                % week
                
                % Matlab's day of week numbering convention:
                % Sun:1 Mon:2 Tue:3 Wed:4 Thu:5 Fri:6 Sat_7
                
                % get the traded week ahead spreads
                TradingSystem.noOfStd_up = 1;
                TradingSystem.noOfStd_down = 3;
                TradingSystem.tradesSize = 10; % in MW
                % in the prototype the 2 parameters below were set to 4 and 5. 
                TradingSystem.minWkEnterDay = 4; % min weekday to enter a trade (e.g. when 3 it means that a trade can be entered not earlier than Tuesday)
                TradingSystem.maxWkEnterDay = 5; % max weekday to enter a trade (e.g. when 5 it means that a trade can be entered no later than Thursday) - applies to strategy 1 only
                TradingSystem.closingWkDay = 6;  % APPLIES TO STRATEGY 1 ONLY: the day when the trade is closed
                TradingSystem.Data.Daily = [Forward.Daily.GEFR,Forward.Daily.Spread];
                TradingSystem.Data.Daily.Properties.DimensionNames{1} = 'Time';
                TradingSystem.Data.Daily.fwdDelivery = TradingSystem.Data.Daily.Time+days(7); % 1 week shift to get to the corresponding day in the delivery week
                TradingSystem.Data.Daily.fwdDeliveryWeek =  week(TradingSystem.Data.Daily.fwdDelivery); % week of delivery for the fwd
                TradingSystem.Data.Daily.fwdDeliveryYear =  year(TradingSystem.Data.Daily.fwdDelivery); % year of delivery for the fwd
                TradingSystem.Data.Daily.fwdDeliveryWeek = TradingSystem.Data.Daily.fwdDeliveryWeek  - 1;
                
                f3 = figure; % for the 1st trading strategy
                plot(TradingSystem.Data.Daily.Time,TradingSystem.Data.Daily.fwdDailySpread);
                hold on; grid on;
                title('Strategy 1 entry signals (no delivery)');
                
                f4 = figure; % for the 2nd trading strategy
                plot(TradingSystem.Data.Daily.Time,TradingSystem.Data.Daily.fwdDailySpread);
                hold on; grid on;
                title('Strategy 2 entry signals (with delivery)');
                
                % add the columns containing the upper and lower thresholds: at the moment
                % I use the measure of dispersion computed above on weekly data, but it
                % could also be a function of this dispersion measure
                T = size(TradingSystem.Data.Daily,1);
                TradingSystem.Data.Daily.upperThreshold = zeros(T,1);
                TradingSystem.Data.Daily.lowerThreshold = zeros(T,1);
                TradingSystem.Data.Daily.Distance = zeros(T,1);    % distance of the spread from its seasonl norm
                TradingSystem.Data.Daily.stdDistance = zeros(T,1); % ... same thing in std units
                TradingSystem.Data.Daily.strat1_closingPrice = zeros(T,1); % needed to close strategy 1 trades
                TradingSystem.Data.Daily.avgDeliveryPrice = zeros(T,1); % avg delivery price for the spread needed to close strategy 2 trades
                TradingSystem.Data.Daily.GEwkAvg = zeros(T,1); % avg delivery price GE
                TradingSystem.Data.Daily.FRwkAvg = zeros(T,1); % avg delivery price FR
                
                TradingSystem.Data.Daily.SignalsStrat_1 = zeros(T,1);
                TradingSystem.Data.Daily.SignalsStrat_2 = zeros(T,1);
                TradingSystem.Data.Daily.PL_strat_1 = zeros(T,1);
                TradingSystem.Data.Daily.PLtot_strat_1 = zeros(T,1);
                TradingSystem.Data.Daily.PL_strat_2 = zeros(T,1);
                TradingSystem.Data.Daily.PLtot_strat_2 = zeros(T,1);
                TradingSystem.Data.Daily.ConfidenceInSignal = zeros(T,1);
                TradingSystem.Data.Daily.HorizonDays = ones(T,1).*Q.params(c).HorizonDays;
                TradingSystem.persist = Q.params(c).persist;
                
                % note: here I have daily data. The weekly threshold will be used for all
                % of the corresponding days in the delivery week
                strategyActive = false(1);
                sameWeekSignals = 0;
                
                for t=1:T % ***********************************************
                    
                    current_dt = datenum(TradingSystem.Data.Daily.Time(t));
                    
                    % looking for the delivery week data in the weekly dataset
                    fd = find(Cointegration.Data.Week==TradingSystem.Data.Daily.fwdDeliveryWeek(t) ...
                        & Cointegration.Data.Year==TradingSystem.Data.Daily.fwdDeliveryYear(t));
                    
                    % check the most recent (as of time t) hypothesis test available
                    fcointHyp = find(Cointegration.Data.Time < TradingSystem.Data.Daily.Time(t),1,'last');
                    
                    if Cointegration.Data.hTest(fcointHyp)==0
                        fd = []; % no signal can be triggered
                    end
    
                    % *********************************************************************
                    % closing pre-requisites for the 2 strategies: in the backtests below
                    % signal triggers are conditioned upon the existence (in the dataset)
                    % of the information needed to close the position, given the trade
                    % close triggers implemented in the 2 strategies
                    
                    % for strategy 1: the mkt price of the spread for the subsequent TradingSystem.closingWkDay
                    % day of the week (normally a Friday) in needed
                    % look for the index of the first subsequent 'TradingSystem.closingWkDay' weekday
                    
                    candidateFriday = find(weekday(TradingSystem.Data.Daily.Time(t:end)) == TradingSystem.closingWkDay,1,'first') + t - 1;
                   
                    
                    if ~isempty(candidateFriday)
                        if TradingSystem.Data.Daily.Time(candidateFriday) < TradingSystem.Data.Daily.Time(t) + 7 % must be in the same week
                            % pass
                            TradingSystem.Data.Daily.strat1_closingPrice(t) = TradingSystem.Data.Daily.fwdDailySpread(candidateFriday);
                        else
                            candidateFriday = [];
                            TradingSystem.Data.Daily.strat1_closingPrice(t) = NaN;
                        end
                    end
                    
                    % for strategy 2: need to have the average spot price for the delivery week
                    % --> this is implied by the existence of 'fd' below
                    
                    % *********************************************************************
                    days2NextFriday = 6 - weekday(current_dt);
                    nextFriday = current_dt + days2NextFriday;
                    if ~isempty(fwdForcingDates) & ~ismember(nextFriday,fwdForcingDates)    
                        % no signal when the 'nextFriday' date is not
                        % included in the set 'fwdForcingDates'
                        candidateFriday = [];
                    end
                                
                    if ~isempty(fd)
                        TradingSystem.Data.Daily.upperThreshold(t) = Cointegration.Data.cirMean(fd) + TradingSystem.noOfStd_up.*Cointegration.Data.cirDispersion(fd);
                        TradingSystem.Data.Daily.lowerThreshold(t) = Cointegration.Data.cirMean(fd) - TradingSystem.noOfStd_down.*Cointegration.Data.cirDispersion(fd);
                        TradingSystem.Data.Daily.avgDeliveryPrice(t) = Cointegration.Data.spotWeeklySpread(fd);
                        TradingSystem.Data.Daily.GEwkAvg(t) = Cointegration.Data.GEwkAvg(fd);
                        TradingSystem.Data.Daily.FRwkAvg(t) = Cointegration.Data.FRwkAvg(fd);
                        
                        % standardized distante (used as signal's intensity)
                        TradingSystem.Data.Daily.Distance(t) = TradingSystem.Data.Daily.fwdDailySpread(t) - Cointegration.Data.weeklySeasonalNorm(fd);
                        TradingSystem.Data.Daily.stdDistance(t) = abs(TradingSystem.Data.Daily.Distance(t))./Cointegration.Data.cirDispersion(fd);
                        TradingSystem.Data.Daily.ConfidenceInSignal(t) = C_v_f(TradingSystem.Data.Daily.stdDistance(t)); % intensity of the signal (if any)
                        
                        % *** trading signals ***
                        
                        % *** STRATEGY 1 ***
                        if weekday(TradingSystem.Data.Daily.Time(t))>=TradingSystem.minWkEnterDay ... % condition on the min week day to enter a trade
                                & weekday(TradingSystem.Data.Daily.Time(t))<=TradingSystem.maxWkEnterDay ... % condition on the max week day to enter a trade
                                & ~isempty(candidateFriday) ... % condition on the existence of the price on the closing day (otherwise I ignore the signal)
                                & sameWeekSignals <=3  % no more than 3 signals within the same week
                            
                            signalCurrentTime = false(1);
                            if TradingSystem.Data.Daily.fwdDailySpread(t) > TradingSystem.Data.Daily.upperThreshold(t)
                                signalCurrentTime = true(1);
                                % when a signal from cointegration occur my horizon changes to
                                % the no of days until the next Friday (when, by definition,
                                % the strategy is closed;
                                TradingSystem.Data.Daily.HorizonDays(t) = 6 - weekday(current_dt);
                                
                                TradingSystem.Data.Daily.SignalsStrat_1(t) = -1; % SELL the spread
                                TradingSystem.Data.Daily.PL_strat_1(t) = TradingSystem.Data.Daily.fwdDailySpread(t) - TradingSystem.Data.Daily.strat1_closingPrice(t);
                                TradingSystem.Data.Daily.PLtot_strat_1(t) = TradingSystem.Data.Daily.PL_strat_1(t).*TradingSystem.tradesSize.*24.*7;
                                figure(f3);
                                plot(TradingSystem.Data.Daily.Time(t),TradingSystem.Data.Daily.fwdDailySpread(t),'or','Linewidth',3)
                                
                            elseif TradingSystem.Data.Daily.fwdDailySpread(t) < TradingSystem.Data.Daily.lowerThreshold(t)
                                signalCurrentTime = true(1);
                                % when a signal from cointegration occur my horizon changes to
                                % the no of days until the next Friday (when, by definition,
                                % the strategy is closed;
                                TradingSystem.Data.Daily.HorizonDays(t) = 6 - weekday(current_dt);
                                
                                TradingSystem.Data.Daily.SignalsStrat_1(t) = +1; % BUY the spread
                                TradingSystem.Data.Daily.PL_strat_1(t) = -TradingSystem.Data.Daily.fwdDailySpread(t) + TradingSystem.Data.Daily.strat1_closingPrice(t);
                                TradingSystem.Data.Daily.PLtot_strat_1(t) = TradingSystem.Data.Daily.PL_strat_1(t).*TradingSystem.tradesSize.*24.*7;
                                figure(f3);
                                plot(TradingSystem.Data.Daily.Time(t),TradingSystem.Data.Daily.fwdDailySpread(t),'og','Linewidth',3)
                            end
                            
                            if signalCurrentTime % on the day of the signal
                                sameWeekSignals = sameWeekSignals + 1;
                                strategyActive = true(1);
                                latestSignalDate = current_dt;
                                % here I assume there can be at most 2
                                % signals per week (e.g. Wed and Thru): the
                                % first one is given a weight 0.5 times the
                                % highest possible allocation, while the
                                % second one is given the whole allocation
                                % limit
                                TradingSystem.Data.Daily.Strat_1_sameWkSignal(t) = sameWeekSignals./2; 
                            end
                        end
                        
                        % *** STRATEGY 2 *** (closed into delivery --- NOT USED HERE FOR NOW ---)
                        if TradingSystem.Data.Daily.fwdDailySpread(t) > TradingSystem.Data.Daily.upperThreshold(t)
                            
                            TradingSystem.Data.Daily.SignalsStrat_2(t) = -1; % SELL the spread
                            TradingSystem.Data.Daily.PL_strat_2(t) = TradingSystem.Data.Daily.fwdDailySpread(t) - TradingSystem.Data.Daily.avgDeliveryPrice(t);
                            TradingSystem.Data.Daily.PLtot_strat_2(t) = TradingSystem.Data.Daily.PL_strat_2(t).*TradingSystem.tradesSize.*24.*7;
                            figure(f4);
                            plot(TradingSystem.Data.Daily.Time(t),TradingSystem.Data.Daily.fwdDailySpread(t),'or','Linewidth',3)
                            
                        elseif TradingSystem.Data.Daily.fwdDailySpread(t) < TradingSystem.Data.Daily.lowerThreshold(t)
                           
                            TradingSystem.Data.Daily.SignalsStrat_2(t) = +1; % BUY the spread
                            TradingSystem.Data.Daily.PL_strat_2(t) = -TradingSystem.Data.Daily.fwdDailySpread(t) + TradingSystem.Data.Daily.avgDeliveryPrice(t);
                            TradingSystem.Data.Daily.PLtot_strat_2(t) = TradingSystem.Data.Daily.PL_strat_2(t).*TradingSystem.tradesSize.*24.*7;
                            figure(f4);
                            plot(TradingSystem.Data.Daily.Time(t),TradingSystem.Data.Daily.fwdDailySpread(t),'og','Linewidth',3)
                        end
                        
                       % to account for strategy 1 close at the end of
                       % the week (Friday) when the signal occurred
                        if strategyActive && current_dt>=nextFriday  % <<=== IMPORTANT: IN CASE i put a '-1' HERE:  ADDED here compared to the prototype because in AA new positions are enforced one day after the signal (TODO: make this an option)
                            strategyActive = false(1);
                            sameWeekSignals = 0;
                            TradingSystem.Data.Daily.CloseStrat_1(t) = 1;
                        end
                    else
                        TradingSystem.Data.Daily.upperThreshold(t) = NaN;
                        TradingSystem.Data.Daily.lowerThreshold(t) = NaN;
                        
                    end % if on existence of 'fd'
                    
                end % loop over [1:T]
                
                Q.Signal{c} = TradingSystem; % put in Q.Signal the table where I have all that I need to manage signals
                % when not empty the info in Q.ConfidenceInSignal will prevail (in
                % universe.Dynamic_AA_1) over the constant setting provided via
                % the initial settings
                Q.ConfidenceInSignal{c} = [datenum(TradingSystem.Data.Daily.Time),TradingSystem.Data.Daily.ConfidenceInSignal];
                Q.TradingSystem{c} = TradingSystem;
            end % c-loop (on the no of coint pairs)
            
        end % method CointPower
        
        % *****************************************************************
        % Method PairCointegration
        % *****************************************************************
        function PairCointegration(Q) % algo 3: produces quant signals based on cointegration betwwen power weekahead forwards and the underlying spot seasonality
            
            % ********  GET SPOT TIMESERIES HIST QUOTES *******
            import ViewsGen.*;
            
            
            n_cointPairs = numel(Q.params); % this depends on the settings in AA_DashBoard where 'CointPower' strategies are setup
            
            for c=1:n_cointPairs
                fwdForcingDates = Q.params(c).forcingTimeVector;
                Q.ViewsNames{c,1} = ['PairCointegration_',Q.params(c).tickers{1},'__',Q.params(c).tickers{2}];
                Q.ViewsNames{c,1} = strrep(Q.ViewsNames{c,1},' ','_');
                
                
                % **********  GET WEEK AHEAD MARKET DATA *********
                
                uparams.DataFromBBG = Q.params(c).DataFromBBG;
                uparams.ticker = Q.params(c).tickers;
                uparams.fields = 'LAST_PRICE';
                uparams.history_start_date = Q.params(c).start_dt;
                uparams.history_end_date = Q.params(c).end_dt;
                uparams.granularity = 'DAILY';
                CointPairRawData = Utilities(uparams);
                CointPairRawData.GetHistPrices;
                
                dates = datetime(datestr(CointPairRawData.Output.HistInfo{1}(:,1)),'ConvertFrom','datenum');
                series1_fts = timetable(dates,CointPairRawData.Output.HistInfo{1}(:,2));
                series1_fts.Properties.VariableNames = {'Price'}; % Germany week ahead timeaseries
                dates = datetime(datestr(CointPairRawData.Output.HistInfo{2}(:,1)),'ConvertFrom','datenum');
                series2_fts = timetable(dates,CointPairRawData.Output.HistInfo{2}(:,2));
                series2_fts.Properties.VariableNames = {'Price'}; % France week ahead timeaseries
                % get the (assumed) cointegrated series on a common set of
                % dates
                CointPair = synchronize(series1_fts,series2_fts,'intersection');
                
                
                C_v_f = Q.params(c).confidenceF;
                % *******  ESTIMATE SPOT SPREAD SEASONALITY *******
                              
                
                % ******  DYNAMIC COINTEGRATING RELATIONSHIP ESTIMATION  ******
                data = [CointPair.Price_series1_fts CointPair.Price_series2_fts];
                % convert to 'base 1' prices
                base1_price = ret2price(price2ret(data(:,1)),1);
                base2_price = ret2price(price2ret(data(:,2)),1);
                CointPair.Price_series1_fts = base1_price;
                CointPair.Price_series2_fts = base2_price;
                
                % test the cointegration hypothesys at each point in time and compute the
                % cointegrating vector
                Cointegration.burnIn = Q.params(c).cointParams.burnIn;  % initial min windows (in weeks) used to estimate the relationship
                Cointegration.movWIn = Q.params(c).cointParams.movWIn;  % 0 to use an expanding window from t0; otherwise the width (in weeks here) of the rolling windows to be used
                Cointegration.stdMovWIn = Q.params(c).cointParams.stdMovWIn; % 0 to compute the STD from the first meaningful 'relationship piece of data'; otherwise the width (in weeks here) of the rolling windows to be used
                Cointegration.confLevel = Q.params(c).cointParams.cointConfLevel;
                
                Cointegration.Data = CointPair;
                Cointegration.T = size(data,1);
                Cointegration.Data.hTest(1:Cointegration.T) = 0;
                Cointegration.Data.pval(1:Cointegration.T) = NaN;
                Cointegration.Data.cointVector(1:Cointegration.T) = cell(Cointegration.T,1);
                
                tic % ****************************************************
                first = 0;
                for t=1:Cointegration.T
                    Cointegration.Data.cointVector{t} = [0 0];
                    
                    if Cointegration.movWIn==0
                        if t<=Cointegration.burnIn % burn-in window: no signals will be generated here
                            continue
                        end
                        start_t = 1;
                    end
                    
                    if Cointegration.movWIn>0
                        start_t = t - Cointegration.movWIn;
                        
                    end
                    
                    if start_t>0
                        first = first + 1;
                        final_t = t - 1;
                        dataSubset = data(start_t:final_t,:);
                        [h,pValue,stat,cValue,reg1,reg2] = egcitest(dataSubset,'alpha',Cointegration.confLevel);
                        Cointegration.Data.hTest(t) = h;
                        Cointegration.Data.pval(t) = pValue;
                        Cointegration.Data.cointVector{t} = [reg1.coeff(1),reg1.coeff(2)];
                        relationship = dataSubset*[1,-reg1.coeff(2)]' - reg1.coeff(1);
                        Cointegration.Data.Relationship(t) = relationship(end);
                        
                        % **** Moving measure of dispersion for the cointegration relationship ****
                        if first==1 % first meaningful piece of data for the cointegration relationship (cir)
                            Cointegration.relationshipFirstMeaningfulTime = Cointegration.Data.dates(t); % ** date of the first meaningful value
                            first_t = t;
                        elseif first>1
                            % compute the measure of dispersion for the cir
                            if Cointegration.stdMovWIn==0
                                % uding an expanding windows from the first time
                                Cointegration.Data.cirMean(t) = mean(Cointegration.Data.Relationship(first_t:t));
                                Cointegration.Data.cirDispersion(t) = std(Cointegration.Data.Relationship(first_t:t));
                            elseif Cointegration.stdMovWIn>0
                                % using an expanding window for the initial 'stdMovWIn'
                                % weeks of meaningful data end then the moving window set
                                % forth in 'stdMovWIn'
                                if t-first_t > Cointegration.stdMovWIn
                                    Cointegration.Data.cirMean(t) = mean(Cointegration.Data.Relationship(t-Cointegration.stdMovWIn:t));
                                    Cointegration.Data.cirDispersion(t) = std(Cointegration.Data.Relationship(t-Cointegration.stdMovWIn:t));
                                else
                                    Cointegration.Data.cirMean(t) = mean(Cointegration.Data.Relationship(first_t:t));
                                    Cointegration.Data.cirDispersion(t) = std(Cointegration.Data.Relationship(first_t:t));
                                end
                                
                            end % if about using Cointegration.stdMovWIn
                        end % if on the first meaningful cir piece of data
                        % *************************************************************************
                        
                    end % if on start_t>0
                end % main t loop
                toc
                
                Cointegration.firstTime4Signal = first_t; % index of 1-st time that can be used for the trading system
                % for debugging purposes (plot estimated seasonality): to plot
                % the cointegration relationship
                figure;
                plot(Cointegration.Data.dates(first_t:end),Cointegration.Data.Relationship(first_t:end) );
                grid on; hold on;
                plot(Cointegration.Data.dates(first_t:end),Cointegration.Data.cirMean(first_t:end) + Cointegration.Data.cirDispersion(first_t:end),'g');
                plot(Cointegration.Data.dates(first_t:end),Cointegration.Data.cirMean(first_t:end) - Cointegration.Data.cirDispersion(first_t:end),'g');
                plot(Cointegration.Data.dates(first_t:end),Cointegration.Data.cirMean(first_t:end) + 2.*Cointegration.Data.cirDispersion(first_t:end),'r');
                plot(Cointegration.Data.dates(first_t:end),Cointegration.Data.cirMean(first_t:end) - 2.*Cointegration.Data.cirDispersion(first_t:end),'r');
                plot(Cointegration.Data.dates(first_t:end),Cointegration.Data.cirMean(first_t:end) - 3.*Cointegration.Data.cirDispersion(first_t:end),'c');
                title('Cointegration relationship');
                
                figure; grid on; hold on;
                plot(Cointegration.Data.dates(first_t:end),Cointegration.Data.pval(first_t:end) );
                plot(Cointegration.Data.dates(first_t:end),Cointegration.confLevel.*ones(1,Cointegration.T-first_t+1),'-.r');
                legend({'pvalues','rejection threshold'});
                title('Cointegration relationship significance (pvalues)');
                
                
                % ************************ TRADING SIGNALS ********************
                % Note: 2 trading strategies based on the same 'enter trade' trigger  signal
                % are implemented below. The difference between the 2s is in the closing
                % date.
                
                % 1) in strategy 1 the trade is always closed on the Friday of the same
                % trading week
                % 2) in strategy 2 the trade is closed thorugh delivery on the fololowing
                % week
                
                % Matlab's day of week numbering convention:
                % Sun:1 Mon:2 Tue:3 Wed:4 Thu:5 Fri:6 Sat_7
                
                TradingSystem.noOfStd_up = Q.params(c).tsParams.noOfStd_up;
                TradingSystem.noOfStd_down = Q.params(c).tsParams.noOfStd_down;
                TradingSystem.persist = Q.params(c).persist;
                
                % in the prototype the 2 parameters below were set to 4 and 5. 
                TradingSystem.Data = timetable(Cointegration.Data.dates,Cointegration.Data.Relationship);
                TradingSystem.Data.Properties.DimensionNames{1} = 'dates';
                TradingSystem.Data.Properties.VariableNames{1} = 'Spread';
                % add the columns containing the upper and lower thresholds: at the moment
                % I use the measure of dispersion computed above on weekly data, but it
                % could also be a function of this dispersion measure
                T = size(TradingSystem.Data,1);
                TradingSystem.Data.hTest = Cointegration.Data.hTest;
                TradingSystem.Data.upperThreshold = Cointegration.Data.cirMean + TradingSystem.noOfStd_up.*Cointegration.Data.cirDispersion;
                TradingSystem.Data.lowerThreshold = Cointegration.Data.cirMean - TradingSystem.noOfStd_down.*Cointegration.Data.cirDispersion;
                TradingSystem.Data.stdDistance = (Cointegration.Data.Relationship - Cointegration.Data.cirMean)./Cointegration.Data.cirDispersion; % ... std distance from the mean
                
                TradingSystem.Data.SignalsStrat_1 = zeros(T,1);
                TradingSystem.Data.PL_strat_1 = zeros(T,1);
                TradingSystem.Data.PLtot_strat_1 = zeros(T,1);
                TradingSystem.Data.ConfidenceInSignal = zeros(T,1);
                TradingSystem.Data.HorizonDays = ones(T,1).*Q.params(c).HorizonDays;
                
                f3 = figure; 
                plot(TradingSystem.Data.dates,TradingSystem.Data.Spread);
                hold on; grid on;
                title('Strategy 1 entry signals (no delivery)');
                
                strategyActive = false(1);
                
                for t=1:T % ***********************************************
                    
                    current_dt = datenum(TradingSystem.Data.dates(t));
                                
                    if TradingSystem.Data.hTest(t) == 1
                                                
                        TradingSystem.Data.ConfidenceInSignal(t) = C_v_f(TradingSystem.Data.stdDistance(t)); % intensity of the signal (if any)
                        
                        % *** trading signals ***
                        
                        % *** STRATEGY 1 ***
                            
                            signalCurrentTime = false(1);
                            if TradingSystem.Data.Spread(t) > TradingSystem.Data.upperThreshold(t) % SELL ASSET 1 / BUY ASSET 2
                                signalCurrentTime = true(1);
                               
                                TradingSystem.Data.SignalsStrat_1(t) = -1; % SELL the spread
                                figure(f3);
                                plot(TradingSystem.Data.dates(t),TradingSystem.Data.Spread(t),'or','Linewidth',3)
                                
                            elseif TradingSystem.Data.Spread(t) < TradingSystem.Data.lowerThreshold(t) % BUY ASSET 1 / SELL ASSET 2
                                signalCurrentTime = true(1);
                                
                                TradingSystem.Data.SignalsStrat_1(t) = +1; % BUY the spread
                                figure(f3);
                                plot(TradingSystem.Data.dates(t),TradingSystem.Data.Spread(t),'og','Linewidth',3)
                            end
                        
                       % to account for strategy 1 close at the end of
                       % the week (Friday) when the signal occurred
%                         if strategyActive && current_dt>=nextFriday  % <<=== IMPORTANT: IN CASE i put a '-1' HERE:  ADDED here compared to the prototype because in AA new positions are enforced one day after the signal (TODO: make this an option)
%                             strategyActive = false(1);
%                             sameWeekSignals = 0;
%                             TradingSystem.Data.Daily.CloseStrat_1(t) = 1;
%                         end
                        
                    end % if on coint relationship significance
                    
                end % loop over [1:T]
                
                Q.Signal{c} = TradingSystem; % put in Q.Signal the table where I have all that I need to manage signals
                % when not empty the info in Q.ConfidenceInSignal will prevail (in
                % universe.Dynamic_AA_1) over the constant setting provided via
                % the initial settings
                Q.ConfidenceInSignal{c} = [datenum(TradingSystem.Data.dates),TradingSystem.Data.ConfidenceInSignal];
                Q.TradingSystem{c} = TradingSystem;
            end % c-loop (on the no of coint pairs)
            
        end % method PairsCointegration
        
        % *****************************************************************
        % End of method PairCointegration
        % *****************************************************************
        
    end % methods (public)
    
    methods (Static)
        function [orig_p,vtime,p,lp,mn,mng,mng2,mng3,mng4,mng5,x,errcode]=mnmngmultiple_calc_v3(newserie,upd,filetoload,sol,T_coord)
            %crea le matrici mn,dev,mng+mng2 e dmng ex novo oppure aggiornando quelle salvate
            %alla precedente esecuzione del programma che invoca la presente funzione
            vtime=0;
            errcode=99;
            if upd=='S'
                
            elseif upd=='N'
                
                %consente all'utente di selezionare dal grafico la parte della serie
                %dei prezzi da utilizzare e calcola mn ed mng+mng2
                %     clf
                %     close all
                figure
                plot(newserie(:,1));
                
                %     [x,y]=ginput(2);
                %     x=floor(x);
                %     y=floor(y);
                
                x(1) = T_coord(1,1);
                x(2) = T_coord(1,2);
                if x(2)==0; x(2)=size(newserie,1); end
                p=newserie(x(1):x(2),1);
                
                orig_p=p;
                lp=size(p,1); mn=zeros(lp,lp); mng=zeros(lp,lp); mng2=zeros(lp,lp);
                mng3=zeros(lp,lp); mng4=zeros(lp,lp); mng5=zeros(lp,lp);
                
                if sol==1
                    % p remain itself
                    
                elseif sol==11
                    % p remain itself
                    
                elseif sol==12
                    spc(1)=1;
                    for jj=2:length(p(:,1))
                        spc(jj)=(p(jj).^2)./(abs(p(jj)-p(1)).^2); %*****
                        %spc(jj)=(p(jj).^2)-(abs(p(jj)-p(1)).^2);
                        %spc(jj)=(p(jj).^2)./(abs(p(jj)-p(1))./jj).^2;
                    end
                    spc(1)=spc(2);
                    
                    p(:,1)=((((p(:,1)-p(1)).^2)./(spc')).*sign(((p(:,1)-p(1))./spc')))./p(:,1).^2; %****
                    
                elseif sol==2
                    sca=p(1);
                    spc(1)=(1+sca)./(p(2).*0.005);
                    for jj=2:length(p(:,1))
                        spc(jj)=(jj+sca)./(abs(p(jj)-p(1)));
                    end
                    p(:,1)=((p(:,1)-p(1))./spc');
                elseif sol==3
                    sca=p(1);
                    spc(1)=(1+sca)./(p(2).*0.005);
                    for jj=2:length(p(:,1))
                        spc(jj)=p(jj)./(abs(p(jj)-p(1)));
                    end
                    p(:,1)=((p(:,1)-p(1))./spc');
                elseif sol==4
                    spc(1)=1;
                    for jj=2:length(p(:,1))
                        spc(jj)=(p(jj))./(abs(p(jj)-p(1))).^2;
                    end
                    p(:,1)=((p(:,1)-p(1))./spc');
                    %p(:,1)=((p(:,1)-p(1)).^2./spc').*sign(((p(:,1)-p(1))./spc'));
                elseif sol==6
                    spc(1)=1;
                    for jj=2:length(p(:,1))
                        spc(jj)=(p(jj))./(abs(p(jj)-p(1))).^2;
                    end
                    p(:,1)=(((p(:,1)-p(1))./spc').^2).*sign(((p(:,1)-p(1))./spc'));
                elseif sol==7
                    spc(1)=1;
                    for jj=2:length(p(:,1))
                        spc(jj)=(p(jj))./(abs(p(jj)-p(1))).^2;
                    end
                    p(:,1)=(abs((p(:,1)-p(1))./spc').^0.5).*sign(((p(:,1)-p(1))./spc'));
                elseif sol==8
                    spc(1)=1;
                    for jj=2:length(p(:,1))
                        spc(jj)=(p(jj).^2)./(abs(p(jj)-p(1)).^2); %*****
                        %spc(jj)=(p(jj).^2)-(abs(p(jj)-p(1)).^2);
                        %spc(jj)=(p(jj).^2)./(abs(p(jj)-p(1))./jj).^2;
                    end
                    spc(1)=spc(2);
                    ptime=cumprod([1;1+abs((p(2:end)-p(1:end-1)))./p(1:end-1)]).*[1:1:lp]'; %*****
                    
                    %ptime=[1:1:lp]';
                    %ptime=[1:1:lp]'./cumprod([1;1+((p(2:end)-p(1:end-1)))./p(1:end-1)]);
                    vtime=((ptime))./spc'.*(sign(((p(:,1)-p(1))./spc'))); %*****
                    %vtime=(((ptime))./spc')./((p(:,1)-p(1))).*(sign(((p(:,1)-p(1))./spc')));
                    %vtime=(([1:1:lp]').^0.5)./spc'.*(sign(((p(:,1)-p(1))./spc')));
                    p(:,1)=vtime;%.*sign(((p(:,1)-p(1))));
                    
                elseif sol==5
                    spc(1)=1;
                    for jj=2:length(p(:,1))
                        spc(jj)=(p(jj).^2)./(abs(p(jj)-p(1)).^2); %*****
                        %spc(jj)=(p(jj).^2)-(abs(p(jj)-p(1)).^2);
                        %spc(jj)=(p(jj).^2)./(abs(p(jj)-p(1))./jj).^2;
                    end
                    spc(1)=spc(2);
                    
                    p(:,1)=((((p(:,1)-p(1)).^2)./(spc')).*sign(((p(:,1)-p(1))./spc'))); %****
                    
                    
                elseif sol==9 | sol==10
                    spc(1)=1;
                    for jj=2:length(p(:,1))
                        spc1(jj)=((p(jj)).^2)-((abs((p(jj)-p(1)))).^2); %*****
                        spc(jj)=((p(jj)).^2)./spc1(jj);
                    end
                    spc(1)=spc(2);
                    
                    p(:,1)=(((p(:,1)).^2)./spc');
                    
                end % if on sol
                
                if sol>1; p(:,1)=p(:,1)+abs(min(p(:,1)))+1; end
                
                for i=1:lp
                    i-lp
                    mn(i:end,i)=cumsum(p(i:end))./[1:1:lp-i+1]';
                end
                
                conta=[1:1:lp]';
                gm=sum(mn,2)./conta;
                figure
                plot(orig_p)
                %plot(p,spc,'r')
                grid on
                
                
                for j=1:lp
                    j-lp
                    K=numel(find(mn(j,:)>0));
                    conta=[K:-1:1];
                    mng(j,1:K)=fliplr(cumsum(fliplr(mn(j,1:K))))./conta;
                    
                    K2=numel(find(mng(j,:)>0));
                    conta=[K2:-1:1];
                    mng2(j,1:K2)=fliplr(cumsum(fliplr(mng(j,1:K2))))./conta;
                    
                    K3=numel(find(mng2(j,:)>0));
                    conta=[K3:-1:1];
                    mng3(j,1:K3)=fliplr(cumsum(fliplr(mng2(j,1:K3))))./conta;
                    
                    K4=numel(find(mng3(j,:)>0));
                    conta=[K4:-1:1];
                    mng4(j,1:K4)=fliplr(cumsum(fliplr(mng3(j,1:K4))))./conta;
                    
                    K5=numel(find(mng4(j,:)>0));
                    conta=[K5:-1:1];
                    mng5(j,1:K5)=fliplr(cumsum(fliplr(mng4(j,1:K5))))./conta;
                    
                end
                
                % cycle II of mean calculations
                if sol==99 | sol==100 | sol==11  | sol==12 %only for relative and modified relative
                    %***************************
                    %***************************
                    %***************************
                    pvect=p(1:lp)';
                    clear CMATRIX
                    CMATRIX(1,:)=mn(1:lp,1)';   CMATRIX(2,:)=mng(1:lp,1)';
                    CMATRIX(3,:)=mng2(1:lp,1)'; CMATRIX(4,:)=mng3(1:lp,1)';
                    CMATRIX(5,:)=mng4(1:lp,1)';  CMATRIX(6,:)=mng5(1:lp,1)';
                    CMATRIX(7,:)=pvect;
                    
                    dmatrix=CMATRIX(2:6,:);
                    ddim=size(dmatrix,1); mdim=lp;
                    % *********  dynamic weighting II ************
                    d2matrix=zeros(size(dmatrix));
                    MN=mn(1:lp,1);
                    for z=1:mdim
                        if pvect(z)>MN(z)
                            d2matrix(:,z)=sort(dmatrix(:,z),1,'ascend');
                        else
                            d2matrix(:,z)=sort(dmatrix(:,z),1,'descend');
                        end
                    end
                    divisor2=abs(max(d2matrix)-min(d2matrix));
                    W2matrix=abs(diff(d2matrix))./repmat(divisor2,ddim-1,1);
                    Wmng2 = sum(d2matrix(1:ddim-1,:).*W2matrix);
                    
                    Wmatrix_inv=((1./W2matrix))./100;
                    Wmatrix_c=Wmatrix_inv./repmat(sum(Wmatrix_inv),size(Wmatrix_inv,1),1);
                    Wmng_c = abs(sum(flipud(d2matrix(1:ddim-1,:)).*W2matrix)); %oppure moltip. per Wmatrix_c (ma diverso)
                    %***********************************************************
                    if sol==10
                        rect=(max(mng(:,1),Wmng2')-min(mng(:,1),Wmng2'))./min(mng(:,1),Wmng2');
                        p=p.*rect;
                    elseif sol==9 %| sol==1
                        rect=((max(mng(:,1),Wmng2')-min(mng(:,1),Wmng2'))./min(mng(:,1),Wmng2'))+1;
                        p=p./rect;
                    elseif sol==11 | sol==12
                        rect=((max(mng(:,1),Wmng2')-min(mng(:,1),Wmng2'))./min(mng(:,1),Wmng2'))+1;
                        
                        if isnan(Wmng2(1)); Wmng2(1)=Wmng2(2); end
                        if isnan(Wmng_c(1)); Wmng_c(1)=Wmng_c(2); end
                        
                        p=(p-Wmng2'); p(1:4,1)=p(5,1); %*******
                        p(:,1)=p(:,1)+abs(min(p(:,1)))+1;
                    end
                    %**************************************
                    %**************************************
                    
                    for i=1:lp
                        i-lp
                        mn(i:end,i)=cumsum(p(i:end))./[1:1:lp-i+1]';
                    end
                    
                    for j=1:lp
                        j-lp
                        K=numel(find(mn(j,:)>0));
                        conta=[K:-1:1];
                        mng(j,1:K)=fliplr(cumsum(fliplr(mn(j,1:K))))./conta;
                        
                        K2=numel(find(mng(j,:)>0));
                        conta=[K2:-1:1];
                        mng2(j,1:K2)=fliplr(cumsum(fliplr(mng(j,1:K2))))./conta;
                        
                        K3=numel(find(mng2(j,:)>0));
                        conta=[K3:-1:1];
                        mng3(j,1:K3)=fliplr(cumsum(fliplr(mng2(j,1:K3))))./conta;
                        
                        K4=numel(find(mng3(j,:)>0));
                        conta=[K4:-1:1];
                        mng4(j,1:K4)=fliplr(cumsum(fliplr(mng3(j,1:K4))))./conta;
                        
                        K5=numel(find(mng4(j,:)>0));
                        conta=[K5:-1:1];
                        mng5(j,1:K5)=fliplr(cumsum(fliplr(mng4(j,1:K5))))./conta;
                        
                        
                    end %% end of cycle II of mean calculations
                    
                end % if on sol
                %***************************
                %***************************
                %***************************
            end % if on upd
            
        end
        
    end % static methods
    
end % classdef


