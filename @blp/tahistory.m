function d = tahistory(b,s,sd,ed,studychoice,per,varargin)
%TAHISTORY Bloomberg V3 historical technical analysis.
%   D = TAHISTORY(C) returns the Bloomberg technical analysis data study and 
%   element definitions. 
%
%   D = TAHISTORY(C,S,FROMDATE,TODATE,STUDYCHOICE,PER,NAME,VALUE,...) returns 
%   the technical analysis data for the security S and study STUDYCHOICE for 
%   the dates FROMDATE to TODATE. NAME/VALUE pairs are used for additional 
%   Bloomberg request settings.
%
%   'daily' - daily
%   'weekly' - weekly
%   'monthly' - monthly
%   'quarterly' - quarterly
%   'semi_annually' - semi annually
%   'yearly' - yearly
%   'actual' - anchor date specification
%   'calendar' - anchor date specification 
%   'fiscal' - anchor date specification
%   'non_trading_weekdays' - non trading weekdays
%   'all_calendar_days' - return all calendar days
%   'active_days_only' - active trading days only
%   'previous_value' - fill missing values with previous values
%   'nil_value' - fill missing values with NaN
%
%   For example, PER = {'daily','calendar'} returns daily data for all calendar days
%   reporting missing data as NaN's. PER = {'actual'} returns the data using
%   the default periodicity and default calendar reporting missing data as
%   NaN's.  Note that the anchor date is dependent on the TODATE input
%   argument.  
%
%   For information on available options, see the Bloomberg tool 
%   C:\blp\API\APIv3\bin\BBAPIDemo.exe.
%
%   Examples:
%
%   b = blp;
%   d = tahistory(b,'IBM US Equity',floor(now)-30,floor(now),'dmi','all_calendar_days','period',14,'priceSourceHigh','PX_HIGH','priceSourceLow','PX_LOW','priceSourceClose','PX_LAST')
%
%   d = tahistory(b,'IBM US Equity',floor(now)-30,floor(now),'dmi',{'all_calendar_days','previous_value','weekly'},'period',14,'priceSourceHigh','PX_HIGH','priceSourceLow','PX_LOW','priceSourceClose','PX_LAST')
%
%   d = tahistory(b,'IBM US Equity',floor(now)-30,floor(now),'smavg',[],'period',14,'priceSourceClose','PX_LAST')
%
%   d = tahistory(b,'IBM US Equity',floor(now)-30,floor(now),'smavg',[],'period',14,'priceSourceClose','PX_LAST','adjustmentNormal',true,'adjustmentSplit',true)
%   
%   r = tahistory(b);
%
%   r.dmiStudyAttributes
%   
%   ans = 
%   
%                 period: [1x130 char]
%        priceSourceHigh: [1x149 char]
%         priceSourceLow: [1x147 char]
%       priceSourceClose: [1x151 char]
%   
%   r.dmiStudyAttributes.period
%   
%   ans =
%   
%   DEFINITION period {
%   
%       Alternate names = {}
%   
%       Min Value = 1
%   
%       Max Value = 1
%   
%       TYPE Int64
%   
%   } // End Definition: period
%
%   See also BLP, GETDATA, HISTORY, TIMESERIES, REALTIME.

%   Copyright 1999-2016 The MathWorks, Inc.

%imports
import com.bloomberglp.blpapi.*;
import com.mathworks.toolbox.datafeed.*;

%find reference data to start service
if ~b.session.openService('//blp/tasvc')
  b.session.stop
  error(message('datafeed:blpRealTime:openServiceError'));
end

%get bloomberg service, set request type
tasvcService = b.session.getService('//blp/tasvc');
request = tasvcService.createRequest('studyRequest');

%information request
if nargin == 1
  %create request and get study attributes element
  request = tasvcService.createRequest('studyRequest');
  studyAttributes = request.getElement('studyAttributes');

  %get study attributes definitions and elements of each
  typeDefinition = studyAttributes.typeDefinition;
  numStudyDefinitions = typeDefinition.numElementDefinitions;
  for i = 1:numStudyDefinitions
    studyDef = typeDefinition.getElementDefinition(i-1);
    subTypeDef = studyDef.typeDefinition;
    numSubStudyDefinitions = subTypeDef.numElementDefinitions;
    for k = 1:numSubStudyDefinitions
      subStudyDef = subTypeDef.getElementDefinition(k-1);
      d.(char(studyDef.name)).(char(subStudyDef.name)) = char(subStudyDef);
    end
  end
  return
end

%Validate security list.  Security list should be cell array string
if ischar(s) || isstring(s)  
  s = cellstr(s);
end
if ~iscell(s) || ~ischar(s{1})
  error(message('datafeed:blpHistory:securityInputError'))
end

%add securities to request
priceSource = request.getElement('priceSource');
priceSource.setElement('securityName',s{1});
dataRange = priceSource.getElement('dataRange');
dataRange.setChoice('historical');

%set date range
historical = dataRange.getElement('historical');
startDate = datestr(sd,'YYYYmmDD');
historical.setElement('startDate', startDate);
endDate = datestr(ed,'YYYYmmDD');
historical.setElement('endDate', endDate);

% Set study attributes
studyAttributes = request.getElement('studyAttributes');
sStudyAttributes = [char(studychoice) 'StudyAttributes'];
studyAttributes.setChoice(sStudyAttributes);
requestStudy = studyAttributes.getElement(sStudyAttributes);

%Convert periodicity to cell array
if nargin < 6 || isempty(per)
  per = {'ACTUAL','DAILY','ACTIVE_DAYS_ONLY','NIL_VALUE'};
end
if ischar(per) || isstring(per)
  per = cellstr(per);
end
if ~iscell(per) || ~ischar(per{1})
  error(message('datafeed:blpHistory:perInputError'))
end
if length(per) < 4
  per = [per,cell(1,4-length(per))];
end

%Set additional attribute parameters
numin = length(varargin);
for i = 1:2:numin
  switch lower(varargin{i})
    case {'period','maperiod1','maperiod2','sigperiod'}  
      requestStudy.setElement(varargin{i},int64(varargin{i+1}));
      otherwise
        try
          %Assume element applies to requestStudy  
          requestStudy.setElement(varargin{i},varargin{i+1});
        catch
          %setElement failed on requestStudy, try on general historical object
          historical.setElement(varargin{i},varargin{i+1});
        end
  end
end

%set periodicity and data fill parameters
perParams = {'DAILY','WEEKLY','MONTHLY','QUARTERLY','SEMI_ANNUALLY','YEARLY'};
calParams = {'ACTUAL','CALENDAR','FISCAL'};
dayParams = {'NON_TRADING_WEEKDAYS','ALL_CALENDAR_DAYS','ACTIVE_DAYS_ONLY'};
filParams = {'PREVIOUS_VALUE','NIL_VALUE'};

%First check for any invalid entries
allParams = [perParams calParams dayParams filParams];
for i = 1:length(per)
   if ~isempty(per{i}) && ~any(strcmpi(per{i},allParams))
     error(message('datafeed:blpHistory:invalidPeriodicityFlag',per{i}))
   end
end

%Set calendar parameters
i = strcmpi(per{1},calParams) | strcmpi(per{2},calParams) | ...
    strcmpi(per{3},calParams) | strcmpi(per{4},calParams);
if ~any(i)
  cal = 'ACTUAL';
else
  cal = calParams{i};
end
historical.setElement('periodicityAdjustment', cal);

%Set periodicity
i = strcmpi(per{1},perParams) | strcmpi(per{2},perParams) | ...
    strcmpi(per{3},perParams) | strcmpi(per{4},perParams);
if ~any(i)
  prd = 'DAILY';
else
  prd = perParams{i};
end
historical.setElement('periodicitySelection', prd);

%Set data schedule parameters
i = strcmpi(per{1},dayParams) | strcmpi(per{2},dayParams) | ...
    strcmpi(per{3},dayParams) | strcmpi(per{4},dayParams);
if ~any(i)
  dyp = 'ACTIVE_DAYS_ONLY';
else
  dyp = dayParams{i};
end
historical.setElement('nonTradingDayFillOption',dyp);

%Set data fill method
i = strcmpi(per{1},filParams) | strcmpi(per{2},filParams) | ...
    strcmpi(per{3},filParams) | strcmpi(per{4},filParams);
if ~any(i)
  fil = 'NIL_VALUE';
else
  fil = filParams{i};
end
historical.setElement('nonTradingDayFillMethod',fil);

% Send request, with identity object needed
switch class(b)
  case 'bpipe'
    b.authorize;
    d_cid = b.session.sendRequest(request,b.user,[]);
  case 'blpsrv'
    b.authorize;
    d_cid = b.session.sendRequest(request,b.user,CorrelationID(b.uuid));
  case 'blp'
    d_cid = b.session.sendRequest(request,[]);
end

%process request message
d = eventHandler(b,d_cid);


function d = eventHandler(b,d_cid)
%EVENTHANDLER Process events

import com.bloomberglp.blpapi.*;

%process event messages and types
done = false;
i = 1;
while ~done
     
  %get next event
  if b.timeout
    event = b.session.nextEvent(b.timeout);
    
    %Check if event is TIMEOUT
    if strcmp(char(event.eventType().toString),'TIMEOUT')
      error(message('datafeed:blp:noService'));
    end
  else
    event = b.session.nextEvent();
  end
  msgIter = event.messageIterator();
  
  while (msgIter.hasNext)
    
    %valid event
    msg = msgIter.next();
    
    %trap event error
    if msg.hasElement(Name('responseError'))
      error(message('datafeed:blpHistory:eventError',char(msg.getElement('responseError').getElementAsString('message'))))
    end
    
    if (msg.correlationID() == d_cid)
      
      if strcmp(msg.messageType.toString,'studyResponse')
        if msg.hasElement('studyData')
          sdElement = msg.getElement('studyData');
          for j = 0:sdElement.numValues-1
            sdValue = sdElement.getValueAsElement(j);
            for k = 0:sdValue.numElements-1
              tmp = sdValue.getElement(k);
              fName = char(tmp.name.toString);
              switch fName
                case 'date'
                  d.(fName){j+1,1} = char(tmp.getValueAsString);
                  otherwise
                    if (j > 0) && ~isfield(d,fName)
                      d.(fName)(1:j+1,1) = NaN;
                    elseif ~isfield(d,fName)
                      %trap this case 
                    elseif ( (j+1) - length(d.(fName)) > 1)
                      d.(fName)(length(d.(fName))+1:j) = NaN;
                    end
                    d.(fName)(j+1,1) = tmp.getValueAsFloat64;
              end
              i = i + 1; 
            end
          end
        end
      end
      
    end
         
    %RESPONSE event indicates end of events
    if (event.eventType().toString == java.lang.String('RESPONSE')) 
      done = true;
    end
      
  end
end


if ~exist('d','var')
  d = msg;
elseif isfield(d,'date')
  d.date = datenum(d.date,'YYYY-mm-DDTHH:MM:SS.FFF');
end
    