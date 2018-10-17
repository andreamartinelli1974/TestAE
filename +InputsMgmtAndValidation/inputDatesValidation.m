classdef inputDatesValidation < InputsMgmtAndValidation.DataValidation
    % this is one of the implementations of the abstract class DataValidation
    % this implementation is designed to validate the set of dates provided
    % through the 'InitialParametersXLS' Excel file Dates validation
    % encompasses validation of relationships between dates and other
    % fields (not necessarily dates) that are affected (or affects) by the
    % dates provided by the user.
    
    properties
        
    end
    
    properties (SetAccess = protected)
        dataValidated;
    end
    
    methods
        function DV = inputDatesValidation(data2Validate)
            DV = DV@InputsMgmtAndValidation.DataValidation(data2Validate);
            DV.dataValidated.Valid = true(1);
            DV.dataValidated = data2Validate;
            DV.Validate;
            
        end % constructor
        
        function Validate(DV)
           disp('Inputs Validation: dates');
           hstart = datenum(DV.data2Validate.history_start_date);
           hend = datenum(DV.data2Validate.history_end_date);
           
           % *** ERRORS:
           
           errorCnt = 0; % not used for now
           warningCnt = 0; % not used for now
           
           % ErrorMsgs = {};
           
           if  ~(hend - hstart > 50) % hard coded for now: TODO: parametrize
               errorCnt = errorCnt + 1;
               ErrorMsg = ['The difference between historical final and start dates must be at least 50 days'];
               DV.dataValidated.ErrorStruct.identifier  = 'inputDatesValidation:inputDatesNotConsistent';
               DV.dataValidated.ErrorStruct.message = ErrorMsg;
               DV.ErrorsTriggers = true(1); % trigger error mgmt
           end
           
           if DV.data2Validate.movwin>0 && DV.data2Validate.movwin > (hend - hstart)
               errorCnt = errorCnt + 1;
               ErrorMsg = ['Input start and end historical dates are not consistent with the desired length of the moving windows'];
               DV.dataValidated.ErrorStruct.identifier = 'inputDatesValidation:inputDatesAndMovWinNotConsistent';
               DV.dataValidated.ErrorStruct.message = ErrorMsg;
               DV.ErrorsTriggers = true(1); % trigger error mgmt
           end
           
           hvstart = datenum(DV.data2Validate.IV_hdate.start);
           hvend = datenum(DV.data2Validate.IV_hdate.end);
           if hvstart > hvend
                errorCnt = errorCnt + 1;
                ErrorMsg = ['Window used for Implied Vola Skew estimation: the start date cannot be higher that the final date'];
                DV.dataValidated.ErrorStruct.identifier = 'inputDatesValidation:inputDatesVolaSkewEstimNotConsistent';
                DV.dataValidated.ErrorStruct.message = ErrorMsg;
                DV.ErrorsTriggers = true(1); % trigger error mgmt
           end
           
           if DV.data2Validate.ARMAGARCH == 1 && DV.data2Validate.chunksLength > hend-hstart+1
               errorCnt = errorCnt + 1;
               ErrorMsg = ['Chunk length used for ARIMA modeling cannot be greater larger than the hitorical window used'];
               DV.dataValidated.ErrorStruct.identifier = 'inputDatesValidation:inputDatesARIMAchunkTooLarge';
               DV.dataValidated.ErrorStruct.message = ErrorMsg;
               DV.ErrorsTriggers = true(1); % trigger error mgmt
           end
           

           
           % ... APPEND MORE ERRORS/WARNINGS MGMT
           
           
           % TODO: manage the lookback as well
          
        end % method Validate
      
    end % methods (Public)
end % classdef

