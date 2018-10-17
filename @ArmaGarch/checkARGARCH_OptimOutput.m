function result = checkARGARCH_OptimOutput(U,currentModel,optimExitFlag)
% ***** basically here I want to check whether the Variance
% model parameters are within the unit circle and that the
% optimization exit flag is acceptable

result = true(1);
egarchFlag = false(1);
r = 10e3;

mc_currentModel = metaclass(currentModel);
mc_currentModelName = mc_currentModel.Name;

% ***** RETRIEVE VARIANCE PARAMETERS  *****

if strcmp(mc_currentModelName,'arima') % if it iss arima check whether there is a gjr or garch model for variance
    if isobject(currentModel.Variance)
        currentVarModel = currentModel.Variance;
        mc_currentVarModel = metaclass(currentModel.Variance);
        mc_currentVarModelName = mc_currentVarModel.Name;
        if  strcmp(mc_currentVarModelName,'garch')
            alpha = getalpha(currentVarModel);
            beta = getbeta(currentVarModel);
            leverage = 0;
        elseif strcmp(mc_currentVarModelName,'gjr')
            alpha = getalpha(currentVarModel);
            beta = getbeta(currentVarModel);
            leverage = getleverage(currentVarModel);
            
            %         elseif strcmp(mc_currentVarModelName,'egarch') % *** NOT USED FOR NOW
            %             alpha = getalpha(currentVarModel);
            %             beta = getbeta(currentVarModel);
            %             egarchFlag = true(1);
            %             leverage = currentVarModel.Leverage{1};
            %             if isempty(leverage)
            %                 leverage = 0
            %             end
            %             pol = [-alpha 1];
            %             r = roots(pol);
            
        end
        
    else
        alpha = 0;
        beta = 0;
        leverage = 0;
    end
end

if  strcmp(mc_currentModelName,'garch')
    alpha = sum(cell2mat(currentModel.GARCH));
    beta = sum(cell2mat(currentModel.ARCH));
    leverage = 0;
elseif strcmp(mc_currentModelName,'gjr')
    alpha = sum(cell2mat(currentModel.GARCH));
    beta = sum(cell2mat(currentModel.ARCH));
    leverage = getleverage(currentVarModel);
   
    % elseif strcmp(mc_currentModelName,'egarch') % *** NOT USED FOR NOW
    %     egarchFlag = true(1);
    %     alpha = currentModel.GARCH{1};
    %     beta = currentModel.ARCH{1};
    %     leverage = currentModel.Leverage{1};
    %     if isempty(leverage)
    %         leverage = 0
    %     end
    %     pol = [-alpha 1];
    %     r = roots(pol);
end

% UNIT CIRCLE CONDITION
if ~egarchFlag
    sum2check = alpha + beta + 0.5*leverage; % required condition for non-exploding variance (TODO: check the opportunity to use integrated GARCH)
    
    % limit set to 0.995 to avoid 'almost integrated' GARCH. PARAMETRIZE IT
    % Later also try to model as EWMA processes those that are almost
    % integrated
    if sum2check>=0.995 | (optimExitFlag~=1) % & optimExitFlag~=2) % specify conditions for not accepting the model
        result = false(1);
    end
else
    if any(r<1)<1
        result = false(1);
    end
end

    function out = getalpha(currentVarModel)
        if numel(currentVarModel.GARCH)>0
            out = currentVarModel.GARCH{1};
        else
            out = 0;
        end
    end

    function out = getbeta(currentVarModel)
        if numel(currentVarModel.ARCH)>0
            out = currentVarModel.ARCH{1};
        else
            out = 0;
        end
    end

    function out = getleverage(currentVarModel)
        if numel(currentVarModel.Leverage)>0
            out = currentVarModel.Leverage{1};
        else
            out = 0;
        end
    end

end %  function checkARGARCH_OptimOutput