classdef (Abstract) DataValidation < handle
    % the purpose of this abstract class is to manage data validation. In
    % this context 'data' may refer to:
    % input parameters;
    % Bloomberg data;
    % data from several external sources;
    % etc.
    % The mgmt of data vaidation and related exception will be implemented
    % through specific 'real' classes. e.g. one for input parameters, one
    % for BBG data, etc. All of them will be specific implementations of
    % the abstract method 'Validate' (see Abstract methods below)
    % This class will be expanded over time to manage all possible
    % conflicts, inconsistencies, issues, etc., between differenct sets of data
    
    properties
    end
    
    properties (Constant)
    end
   
    properties (SetAccess = immutable) 
       data2Validate;
    end
    
    properties (SetObservable = true)
        ErrorsTriggers = false(1);
        WarningsTriggers = false(1); % NOT USED
    end
    
    properties (Abstract, SetAccess = protected)
        % will be implemented through the specific class designed to manage
        % the specific set of data
        dataValidated;  % can be the same as data2Validate or a modified version of it
    end
    
    properties (SetAccess = protected)
        EventListener;
    end
    
    methods
        function DV = DataValidation(data2Validate) % constructor
            DV.data2Validate = data2Validate;
            
            % add listeners
            L1 = addlistener(DV,'ErrorsTriggers','PostSet',@DV.handleErrorEvents); 
            DV.EventListener = L1;
            L2 = addlistener(DV,'WarningsTriggers','PostSet',@DV.handleWarningEvents); 
            DV.EventListener = L2;
        end
        
        function handleErrorEvents(DV,src,evnt) 
            if strcmp(src.Name,'ErrorsTriggers')
                DV.dataValidated.Valid = false(1);
                m = msgbox(['Validation Error (',DV.dataValidated.ErrorStruct.message,')'] ...
                        ,'Icon','warn');
                waitfor(m);
                delete(m);
                error(DV.dataValidated.ErrorStruct);
            end
        end
        
        function handleWarningEvents(DV,src,evnt) % *** NOT USED FOR NOW ***
            if strcmp(src.Name,'WarningsTriggers')
                m = msgbox(['Validation Warning (',DV.dataValidated.Warning.message,')'] ...
                        ,'Icon','warn');
                waitfor(m);
                delete(m);
            end
        end
    end
    
    methods (Abstract)
        % will be implemented through the specific class designed to manage
        % the specific set of data
        Validate;
    end % abstract methods
    
    methods (Static)
        
        
    end
end % classdef

