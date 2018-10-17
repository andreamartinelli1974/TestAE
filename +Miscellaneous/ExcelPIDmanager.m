classdef ExcelPIDmanager < handle
    % the purpose of this class is to track all the PIDs of the Excel
    % processes called by the matlab code when runned, to be able to close
    % all and only the relevant processes without affecting the Excel
    % instances called by other users
    
    properties
        ActivePID;
        CalledPID;
    end
    
    properties(SetObservable = true)
        GetPID = false(1);
        ClosePID = false(1);
    end
    
    properties (SetAccess = protected)
        EventListener;
    end
    
    methods 
        function EPM = ExcelPIDmanager() % constructor
            EPM.ActivePID = [];
            EPM.CalledPID = [];
            
            % add listener
            L1 = addlistener(EPM,'GetPID','PostSet',@EPM.handleGetPID); 
            EPM.EventListener = L1;
            L2 = addlistener(EPM,'ClosePID','PostSet',@EPM.handleClosePID); 
            EPM.EventListener = L2;
        end
        
        function handleGetPID(EPM,src,evnt)
            if strcmp(src.Name,'GetPID')
                EPM.ActivePID = getpidof('EXCEL.EXE');
            end
        end
        
        function handleClosePID(EPM,src,evnt)
            if strcmp(src.Name,'ClosePID')
                currentPID = getpidof('EXCEL.EXE');
                EPM.CalledPID = setdiff(currentPID,EPM.ActivePID);
            end
        end
        
        function mypid = GetPIDtoClose(EPM)
            mypid = EPM.CalledPID;
        end
        
    end % methods
end %classdef