classdef seasonality < handle
    
    % CLASS seasonality: versione modificata di seasonality che da la
    % possibilità )sew flag w_week_cyc == 1) di stimare anche la componente
    % ciclica settimanale
    % le istanze di questo oggetto restituiscono i parametri, la curva ciclica,
    % etc, relativi alla componente stagionale della serie in INPUT [vettore
    % date, prezzi], mediante fitting di un polinomio trigonometrico di cui si
    % individuano i parametri (assumento due picchi x anno)
    
    properties (SetAccess = immutable) % solo in constructor può modificare queste proprietà
        seasnorm = []; % componente ciclica relativa a tutta la serie fornita in INPUT + eventuali giorni fed (nr_days_fwd in input)
        price_daily = []; % serie daily in INPUT
        price_daily_w_forward = []; % aggiunge a price_daily una serie con prezzi uguali all'ultimo pubblicato per il pezzo forward
        price_daily_destag = []; % serie daily / componente ciclica
        tvectf = []; % year fraction riferita alla serie in input
        tvectf_output = []; % year fraction che include il periodo forward specificato da nr_days_fwd in input
        dates_vector_w_forward = []; % vettore date inclusivo della componente forward (in pratica serie(:,1) + gg forward pecificati in nr_days_fwd)
        x = []; % parametri componente ciclica da ottimizzazione
    end
    
    methods
        function SEASONALITY_constructor = seasonality(serie, nr_days_fwd,seas_f,n_unknowns)
            
            import ViewsGen.*;
            
            % serie = [date vector, prices];
            % flag w_week_cyc: se 1 considera anche componente ciclica
            % nr_days_fwd: numero giorni forward oltre il termine delle
            % date in serie da coprire nella stima della componente ciclica
            % settimanale
            % spostamento in avanti date per renderle coincidenti con delivery dates
            % (solo quando serve sulla base del vettore date di serie)
            % seas_f; chosen seasonality function
            serie(:,1) = serie(:,1);
            
            X = serie(:,2); % serie prezzi
            % giorni trascorsi da inizio anno (rispetto al primo dato della serie): mi
            % serve per determinare il vettore dei tempi in termini di year fraction
            % ggdelay = serie(1,1)-datenum([year(serie(1,1)) 1 1]);
            % tvectf = ([ggdelay:1:size(serie,1)+ggdelay-1]./365)';
            
            dates_fwd = [serie(end,1)+1:1:serie(end,1)+nr_days_fwd]';
            dates_vector_w_forward = [serie(:,1);dates_fwd];
            
            % aggiungo prezzi relativi al 'pezzo' forward di componente
            % ciclica che vado a stimare (utilizzo l'ultimo prezzo
            % pubblicato: non serve a nessuno scopo, solo ad avere una
            % serie dei prezi spot della stessa lunghezza della serie
            % seasnorm che andrò a stimare)
            prices2add = (serie(end,2).*ones(size(dates_fwd,1),1));
            price_daily_w_forward = [dates_vector_w_forward,[serie(:,2);prices2add]];
            
            tvectf =(serie(:,1)-datenum([year(serie(1,1)) 1 1]))./365;
            tvectf_output =(dates_vector_w_forward(:,1)-datenum([year(dates_vector_w_forward(1,1)) 1 1]))./365;
            
            % derivo serie prezzi e serie year fraction senza week ends
            nowends = find(~(weekday(serie(:,1)) == 7 | weekday(serie(:,1)) == 1));
            serie_nowends(:,1) = serie(nowends,1);
            serie_nowends(:,2) = serie(nowends,2);
            tvectf_nowends =(serie_nowends(:,1)-datenum([year(serie_nowends(1,1)) 1 1]))./365;
            
            deltat = [0;diff(tvectf)]; deltat(1)=deltat(2);
            deltat_nowends = [0;diff(tvectf_nowends)]; deltat_nowends(1)=deltat_nowends(2);
            
            options = optimoptions(@fminunc,'Diagnostics','off','Display','none');
            
            % *********************  DESTAGIONALIZZAZIONE  ***************************
            % ************************************************************************
            %   destagionalizzazione serie prezzi X(t)
            
            % *****************************************
            % salvo queste serie per utilizzo in f_destag_2
            %             save   tvectf tvectf
            X = filloutliers(X,'linear');
            
            % ottimizzazione nei parametri di f(t) della funzione obiettivo [X-f(t)].^2
            x0 = zeros(1,n_unknowns);
            [x,funval] = fminunc(@(x)f_destag(x,X,tvectf,seas_f),x0,options);
            
            SEASONALITY_constructor.seasnorm = seas_f(x,tvectf);
            SEASONALITY_constructor.price_daily = serie; % serie daily (vettore date + prezzo)
            SEASONALITY_constructor.price_daily_w_forward = price_daily_w_forward; % include anche 'pezzo' fwd con prezzi uguali all'ultimo pubblicato
            SEASONALITY_constructor.tvectf = tvectf_output; % year fraction
            SEASONALITY_constructor.x = x; % parametri ciclicità
            SEASONALITY_constructor.price_daily_destag = X./(SEASONALITY_constructor.seasnorm(1:size(tvectf,1)));
            SEASONALITY_constructor.dates_vector_w_forward = dates_vector_w_forward;
            SEASONALITY_constructor.tvectf_output = tvectf_output;
        end
        
        function chart_seasnorm(SEASONALITY_constructor)
            % metodo per il plot della serie dei daily spread e della
            % componente di trend/ciclica stimata
            figure
            hold on
            grid on
            plot(SEASONALITY_constructor.price_daily(:,2),'r') % serie prezzi fornita in input
            plot(SEASONALITY_constructor.seasnorm,'Linewidth',3) % norma stagionale che include anche eventuali giorni forward
            legend('prezzo','componente ciclica');
            figure
            % serie prezzi fornita in input destagionalizzata
            plot(SEASONALITY_constructor.price_daily_destag); hold on; grid on;
            title('SERIE DESTAGIONALIZZATA','FontSize',12);
        end
        
        %         function settype = set.type(settype,type)
        %             if ~(strcmpi(type,'bond') || strcmpi(type,'stock') || strcmpi(type,'derivative'))
        %                 error('Type must be either bond, stock, or derivative')
        %             else
        %                 settype.type = type; % per assegnare il valore passato in input una volta superato il check
        %             end
        %         end
        
    end
end



