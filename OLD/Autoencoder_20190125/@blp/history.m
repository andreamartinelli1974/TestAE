function [d,sec] = history(b,s,f,sd,ed,per,cur,varargin)
%HISTORY Bloomberg V3 historical data.
%   [D, SEC] = HISTORY(C,S,F,FROMDATE,TODATE) returns the historical data for 
%   the security list S for the fields F for the dates FROMDATE to TODATE.
%   Date strings can be input in any format recognized by MATLAB.
%   SEC is the security list that maps the order of the return data.   The 
%   return data, D and SEC, is sorted to match the input order of S.
%   For better performance, add the Bloomberg file blpapi3.jar to the
%   MATLAB static java classpath by modifying the file
%   $MATLAB/toolbox/local/classpath.txt.
%
%   [D, SEC] = HISTORY(C,S,F,FROMDATE,TODATE,PER) returns the historical data for 
%   the field, F, for the dates FROMDATE to TODATE.  PER specifies the period of the data,
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
%   'none' - anchor date specification
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
%   [D, SEC] = HISTORY(C,S,F,FROMDATE,TODATE,PER,CUR) returns the historical data for 
%   the security list S for the fields F for the dates FROMDATE to TODATE 
%   based on the given currency, CUR.  
%
%   [D, SEC] = HISTORY(C,S,F,FROMDATE,TODATE,PER,CUR,NAME,VALUE,...) returns the historical data for 
%   the security list S for the fields F for the dates FROMDATE to TODATE 
%   based on the given currency, CUR.  NAME/VALUE pairs are used for
%   additional Bloomberg request settings.
%
%   Note that historical requests that include the current date as the end 
%   date made before the market opens on the current date may have missing
%   or skewed data.   For example, if the LAST_PRICE and VOLUME are requested,
%   the LAST_PRICE may not be returned and the VOLUME data for the last,
%   current date may be shifted into the LAST_PRICE column.  
%  
%   Examples:
%
%   [D, SEC] = HISTORY(C,'ABC US Equity','LAST_PRICE','8/01/99','8/10/99')
%   returns the closing price for the given dates for the given security using
%   the default period of the data.
%
%   [D, SEC] = HISTORY(C,'ABC US Equity','LAST_PRICE','8/01/99','8/10/99','monthly')
%   returns the monthly closing price for the given dates for the given security.
%
%   [D, SEC] = HISTORY(C,'ABC US Equity','LAST_PRICE','8/01/99','8/10/99','monthly','USD')
%   returns the monthly closing price converted to US dollars for the given dates 
%   for the given security .
%
%   [D, SEC] = HISTORY(C,'ABC US Equity','LAST_PRICE','8/01/99','8/10/99',{'daily','actual','all_calendar_days','nil_value'},'USD')
%   returns the daily closing price converted to US dollars for the given dates 
%   for the given security .
%
%   [D, SEC] = HISTORY(C,'ABC US Equity','LAST_PRICE','12/01/99','12/23/99',{'weekly'},'USD')
%   returns the weekly closing price converted to US dollars for the given dates 
%   for the given security.  Note that the anchor date is dependent on the
%   date 12/23/1999 in this case.   Because this date is a Thursday, each
%   previous value will be reported for the Thursday of the week in
%   question.
%
%   [D, SEC] = HISTORY(C,'ABC US Equity','LAST_PRICE','8/01/99','8/10/99',[],'USD')
%   returns the closing price converted to US dollars for the given dates 
%   for the given security using the default period of the data.    The
%   default period of a security is dependent on the security itself and
%   not set in this function.
%
%   [D, SEC] = HISTORY(C,'ABC US Equity','LAST_PRICE','8/01/99','8/10/99','daily','USD','adjustmentNormal',true,'adjustmentSplit',true)
%   returns the closing price converted to US dollars for the given dates 
%   for the given security using the default period of the data. The prices
%   are adjusted for normal cash and splits.
%   
%   See also BLP, GETDATA, TIMESERIES, REALTIME.

%   Copyright 1999-2016 The MathWorks, Inc.
%   $Revision: 1.1.8.7 $   $Date: 2014/04/10 21:31:09 $

%imports
import com.bloomberglp.blpapi.*;
import com.mathworks.toolbox.datafeed.*;

%Validate security list.  Security list should be cell array string
if ischar(s) || isstring(s)  
  s = cellstr(s);
end
if ~iscell(s) || ~ischar(s{1})
  error(message('datafeed:blpHistory:securityInputError'))
end

%Convert field list to cell array
if ischar(f) || isstring(f)  
  f = cellstr(f);
end
if ~iscell(f) || ~ischar(f{1})
  error(message('datafeed:blpHistory:fieldInputError'))
end

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
  
%get bloomberg service, set request type
refDataService = b.session.getService('//blp/refdata');
request = refDataService.createRequest('HistoricalDataRequest');

%add securities to request
securities = request.getElement('securities');
for i = 1:length(s)
  securities.appendValue(s{i});
end

%add fields to request
fields = request.getElement('fields');
f = upper(f);
for i = 1:length(f)
  fields.appendValue(f{i});
end

%set periodicity and data fill parameters
perParams = {'DAILY','WEEKLY','MONTHLY','QUARTERLY','SEMI_ANNUALLY','YEARLY'};
calParams = {'ACTUAL','CALENDAR','FISCAL','NONE'};
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
if ~any(strcmpi(per,'NONE'))
  i = strcmpi(per{1},calParams) | strcmpi(per{2},calParams) | ...
    strcmpi(per{3},calParams) | strcmpi(per{4},calParams);
  if ~any(i)
    cal = 'ACTUAL';
  else
    cal = calParams{i};
  end
  request.set('periodicityAdjustment', cal);
end


%Set periodicity
i = strcmpi(per{1},perParams) | strcmpi(per{2},perParams) | ...
    strcmpi(per{3},perParams) | strcmpi(per{4},perParams);
if ~any(i)
  prd = 'DAILY';
else
  prd = perParams{i};
end
request.set('periodicitySelection', prd);

%Set data schedule parameters
i = strcmpi(per{1},dayParams) | strcmpi(per{2},dayParams) | ...
    strcmpi(per{3},dayParams) | strcmpi(per{4},dayParams);
if ~any(i)
  dyp = 'ACTIVE_DAYS_ONLY';
else
  dyp = dayParams{i};
end
request.set('nonTradingDayFillOption',dyp);

%Set data fill method
i = strcmpi(per{1},filParams) | strcmpi(per{2},filParams) | ...
    strcmpi(per{3},filParams) | strcmpi(per{4},filParams);
if ~any(i)
  fil = 'NIL_VALUE';
else
  fil = filParams{i};
end
request.set('nonTradingDayFillMethod',fil);

%set the currency if given
if exist('cur','var') && ~isempty(cur)
  request.set('currency',cur)
end

%set date range
startDate = datestr(sd,'YYYYmmDD');
request.set('startDate', startDate);
endDate = datestr(ed,'YYYYmmDD');
request.set('endDate', endDate);

%set maximum number of data point returned
request.set('maxDataPoints', int32(100000));
request.set('returnEids', true);

%set other parameters, reference BLP API doc for names and settings
if nargin > 7
  numin = length(varargin);
  if mod(numin,2)
    error(message('datafeed:blpHistory:parameterMismatch'))
  end
  for i = 1:2:length(varargin)
    if strcmpi(varargin{i},'overrideFields')
      %Set overrides, override values must be input as a Nx2 cell array
      overrides = request.getElement('overrides');
      for j = 1:size(varargin{i+1},1)
         override = overrides.appendElement;
         override.setElement('fieldId',varargin{i+1}{j,1});
         override.setElement('value',varargin{i+1}{j,2});
      end
    else
      request.set(varargin{i},varargin{i+1})
    end
  end
end

% If SAPI, check for EID
if isprop(b,'returnEids')
 request.set('returnEids',true)
end

% Send request, with identity object needed
switch class(b)
  case 'bpipe'
    b.authorize;
    b.session.sendRequest(request,b.user,[]);
  case 'blpsrv'
    b.authorize;
    b.session.sendRequest(request,b.user,CorrelationID(b.uuid));
  case 'blp'
    b.session.sendRequest(request,[]);
end

% Handle messages that require authentication
if isprop(b,'returnEids')
  [d,sec] = eventHandler(b,s,f);
  return
end

%process request message
try
  tmp = blpHistory();
  flds = java.util.Vector;
  for i = 1:length(f)
    flds.addElement(f{i});
  end
  vData = tmp.processEvents(b.session,length(f),flds);
catch 
  %Process events when blpapi3.jar is not on static classpath
  [d,sec] = eventHandler(b,s,f);
  return
end

%Convert data from vectors to cell arrays
tmpData = system_dependent(44,vData,1);
sec = system_dependent(44,tmp.returnSecList,1);
numsec = length(s);
numflds = length(f) + 1;
d = cell(1,numsec);
dCounter = 1;

%Returned output has data for all requested securities, need to parse

%Create list of possible dates to eliminate datenum calls in loop
dateRange(1,1) = datenum(sd);
dateRange(2,1) = datenum(ed)+31; %for monthly or yearly non_trading_weekdays, Bloomberg may give one extra month's data
dateNums = dateRange(1):dateRange(2);
dateStrs = datestr(dateNums,'yyyy-mm-dd');
dateNums = num2cell(dateNums);

for i = 1:numsec
  numPts = tmpData{dCounter};
  if isnumeric(numPts)
    d{i} = reshape(tmpData(dCounter+1:dCounter+numPts*numflds),numflds,numPts)';
    if ~isempty(d{i})
      [dateFnd,dateIndx] = ismember(d{i}(:,1),dateStrs);
      if any(dateFnd)
         d{i}(dateFnd,1) = dateNums(dateIndx(dateFnd));
      end
    end
    try
      d{i} = cell2mat(d{i});
    catch exception %#ok
    end
    dCounter = dCounter+numPts*numflds+1;
  else
    d{i} = tmpData{dCounter};
    dCounter = dCounter + 1;
  end
end

%Single security output 
if length(d) == 1
  d = d{1};
else
  %Sort output based on input list
  numsec = length(s);
  outInd = zeros(length(s),1);
  for i = 1:numsec
    outInd(i) = find(strcmp(s(i),sec),1);
  end
  d = d(outInd)';
  sec = sec(outInd);
end

function [d,sec] = eventHandler(b,s,f)
%EVENTHANDLER Process events when blpapi3.jar is not on static classpath

import com.bloomberglp.blpapi.*;

%process event messages and types
done = false;
i = 1;
d = cell(1,length(s));
sec = d;
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
    
    b.entitlements(msg);
    
    %trap event error
    if msg.hasElement(Name('responseError'))
      error(message('datafeed:blpHistory:eventError',char(msg.getElement('responseError').getElementAsString('message'))))
    end
    
    %parse security and field data
    if msg.hasElement('securityData')
      
      dElement = msg.getElement('securityData');
      
      if dElement.hasElement('fieldData')
        
        fElement = dElement.getElement('fieldData');
        sec{i} = char(dElement.getElementAsString('security'));
        
        if fElement.isNull
          
          %If no data, trap error
          try
            d{i} = char(dElement.getElement('securityError').getElementAsString('message'));
          catch exception %#ok
            d{i} = [];
          end
        else
          
          %Preallocate output as NaN's
          numPts = fElement.numValues;
          d{i} = num2cell(nan(numPts,length(f)+1));
        
          %loop through number of points in data
          for j = 0:numPts-1
            fData = fElement.getValueAsElement(j);
            %d{i}{j+1,1} = datenum(char(fData.getElementAsDate('date')));
            tmpDate = fData.getElementAsDate('date');
            d{i}{j+1,1} = tmpDate.year*10000 + tmpDate.month*100 + tmpDate.dayOfMonth;
            %loop through fields
            for k = 1:length(f)
            
              try
              
                %get each element of data
                eData = fData.getElement(k);
              
                %get name to make sure data is in correct column
                eName = eData.name;
                indx = find(strcmpi(eName,f));
                
                %convert data
                switch eData.datatype.intValue
                  case 9
                    d{i}{j+1,indx+1} = char(fData.getElementAsString(f{indx}));
                  case {5,6,7,8}
                    d{i}{j+1,indx+1} = fData.getElementAsFloat64(f{indx});
                end
              
              catch exception %#ok
              
                %array element remains NaN
              
              end  
            end
          end
        end  
      end
      
      %event counter
      i = i + 1;
      
      %RESPONSE event indicates end of events
      if (event.eventType().toString == java.lang.String('RESPONSE')) 
        done = true;
      end
      
    end
  end
end

%Convert YYYYMMDD date column to date number  
%Convert output array to matrix if possible
for i = 1:length(d)
  try
    d{i}(:,1) = num2cell(datenum(floor([d{i}{:,1}]'/10000),floor(mod([d{i}{:,1}]',10000)/100),mod([d{i}{:,1}]',100)));
    d{i} = cell2mat(d{i});
  catch
    %strings in output cell array
  end
end

%Single security output 
if length(d) == 1
  d = d{1};
else
  %Sort output based on input list
  numsec = length(s);
  outInd = zeros(length(s),1);
  for i = 1:numsec
    j = find(strcmp(s(i),sec));
    outInd(i) = j(1);
  end
  d = d(outInd)';
  sec = sec(outInd)';
end