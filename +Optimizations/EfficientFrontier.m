classdef (Abstract) EfficientFrontier < handle
% abstract class used to implement several types of efficienty frontiers
% (MV and Expected shortfall based at the moment)
    
    properties
    end
    
    properties (Constant)
    end
    
    properties (Abstract)
        % main outputs: coordinates of the efficient frontier in a risk
        % return space
        EF_Return;
        EF_Risk;
        EF_Composition;
        Exitflag;
    end
    
    properties (SetAccess = immutable) 
        params = [];
    end
    
    methods
        function EF = EfficientFrontier(params) % constructor
            % params is a struct array having the following fields:
            % .NumPortf: no of portfolios on the efficient frontier
            % .Covariance: estimated (at the investment horizon) covariance matrix
            % .ExpectedValues: vector of expected returns at the inv
            % horizon
            % .MaxTargetRet: NOT USED
            % .AA_constraints: upper and lower bounds constraints on assets
            % weights
            % resampling: bool field = true if portfolio resampling (as in
            % Michaud) has to be performed. False otherwise. This field is
            % meaningful only for implementation of the class in the
            % MeanVariance framework (it has no impact foir implementations
            % in the MeanES framework)
            % resampling_params: params to be used for resampling when
            % resampling is true
            % RSim: matrix of simulated returns at the investment horizon.
            % This is the distributions of assets returns at the investment
            % horizon
            % ESopt
            
            EF.params = params;
            
        end % constructor
    end % methods
    
    methods (Abstract)
        Optimization;
    end % abstract methods
    
    methods (Static)
        
    end % static methods
end


