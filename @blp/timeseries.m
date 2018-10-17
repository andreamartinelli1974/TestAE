function d = timeseries(b,s,daterange,intv,fld,varargin)
%TIMESERIES Bloomberg V3 intraday tick data.
%   D = TIMESERIES(C,S,T) returns the raw tick data for the security S for
%   the date T. 
%
%   For better performance, add the Bloomberg file blpapi3.jar to the
%   MATLAB static java classpath by modifying the file
%   $MATLAB/toolbox/local/classpath.txt.
%
%   D = TIMESERIES(C,S,{STARTDATE,ENDDATE}) returns the raw tick data
%   for the security S for the date range defined by STARTDATE and ENDDATE.
%
%   D = TIMESERIES(C,S,T,B,F) returns the tick data for the security S for
%   the date T in intervals of B minutes for the field, F.  Intraday tick 
%   data requested with the interval, B, is returned with the columns 
%   representing Time, Open, High, Low, Last Price, Volume of the ticks,   
%   number of ticks and total value of the ticks in the bar.  
%
%   D = TIMESERIES(C,S,{STARTDATE:ENDDATE,STARTTIME,ENDTIME},B,F) returns
%   the tick data for the security S for the date range defined by
%   STARTDATE to ENDDATE for the time range defined by STARTTIME and
%   ENDTIME for each day in the range.   Intraday tick 
%   data requested with the interval, B, is returned with the columns 
%   representing Time, Open, High, Low, Last Price, Volume of the ticks,   
%   number of ticks and total value of the ticks in the bar.  F is the tick
%   type with a default value of 'TRADE'.
%
%   D = TIMESERIES(C,S,{STARTDATE:INC:ENDDATE,STARTTIME,ENDTIME},B,F) returns
%   the tick data for the security S for the date range defined by
%   STARTDATE to ENDDATE for the time range defined by STARTTIME and
%   ENDTIME for each day in the range.   INC denotes the whole day increment 
%   value to use between STARTDATE and ENDDATE.  The default value is 1 day.
%   Intraday tick data requested with the interval, B, is returned with the 
%   columns representing Time, Open, High, Low, Last Price, Volume of the ticks,   
%   number of ticks and total value of the ticks in the bar.  F is the tick
%   type with a default value of 'TRADE'.
%
%   Examples:
%
%   D = TIMESERIES(C,'ABC US Equity',FLOOR(NOW)) returns today's time series
%   for the given security.  The timestamp and tick value are returned.
%
%   D = TIMESERIES(C,'ABC US Equity',FLOOR(NOW),5,'Trade') returns today's Trade tick series
%   for the given security aggregated into 5 minute intervals.  
%
%   D = TIMESERIES(C,'ABC US Equity',{'12/08/2008 00:00:00','12/10/2008 23:59:59.99'},5,'Trade') 
%   returns the Trade tick series for 12/08/2008 to 12/10/2008 for the given 
%   security aggregated into 5 minute intervals.  
%
%   D = TIMESERIES(b,'ABC US Equity',{datetime('12/07/2016'):datetime('12/21/2016'),'09:30:00','10:30:00'},5)
%   returns the Trade tick series for 12/07/2016 to 12/21/2016 for the given 
%   security aggregated into 5 minute intervals.  Only the data for the time
%   range 09:30:00 to 10:30:00 is returned for each day in the range.
%
%   D = TIMESERIES(b,'ABC US Equity',{datetime('12/07/2016'):7:datetime('12/21/2016'),'09:30:00','10:30:00'},5)
%   returns the Trade tick series for 12/07/2016, 12/14/2016, and 12/21/2016 for the given 
%   security aggregated into 5 minute intervals.  Only the data for the time
%   range 09:30:00 to 10:30:00 is returned for each day in the range.
%
%   See also BLP, GETDATA, HISTORY, REALTIME.

%   Copyright 1999-2017 The MathWorks, Inc.

%imports
import com.bloomberglp.blpapi.*;
import java.util.Calendar;
import com.mathworks.toolbox.datafeed.*;

% Convert daterange to cell array
if ~iscell(daterange)
  daterange = {daterange};
end
if isstring(daterange)
  daterange = cellstr(daterange);
end

% Get length of date range input
dateRangeLength = length(daterange);
  
%get bloomberg service, set request type
refDataService = b.session.getService('//blp/refdata');
if nargin > 3 && ~isempty(intv)
  if dateRangeLength == 3
    request = refDataService.createRequest('IntradayBarDateTimeChoiceRequest');
  else
    request = refDataService.createRequest('IntradayBarRequest');
  end
else
  request = refDataService.createRequest('IntradayTickRequest');
end

%set security
request.set('security', s);

%parse interval value, set default tick type to TRADE
if nargin > 3 && ~isempty(intv)
    request.set('interval', int32(intv));
    request.set('gapFillInitialBar', false);
    bBarRequest = true;
else
  eventTypes = request.getElement('eventTypes');
  bBarRequest = false;
end

%parse field input
if nargin > 4
  %Convert field list to cell array
  if ischar(fld) || isstring(fld)
    fld = cellstr(fld);
  end
  if ~iscell(fld) || ~ischar(fld{1})
    error(message('datafeed:blpTimeSeries:fieldInputError'))
  end
elseif nargin == 4
  request.set('eventType','TRADE');
else
  eventTypes.appendValue('TRADE');
end

%set field request
if nargin > 4 && ~isempty(intv)
  request.set('eventType', upper(fld{1}));
elseif nargin > 4
  for i = 1:length(fld)
    eventTypes.appendValue(upper(fld{i}));
  end
end

%parse date range and account for timezone
if dateRangeLength > 1
  
  switch dateRangeLength
    
    case 2
      
      %Convert times into milliseconds based on base date of 1/1/1970
      tzStartDate = java.util.Calendar.getInstance;
      startInMillis = (datenum(daterange{1})-719529)*86400000;
      tzStartDate.setTimeInMillis(startInMillis)
      startdt = java.util.Date(startInMillis);
      if tzStartDate.getTimeZone.inDaylightTime(startdt)
        tzStartOffset = tzStartDate.getTimeZone.getRawOffset + tzStartDate.getTimeZone.getDSTSavings;
      else
        tzStartOffset = tzStartDate.getTimeZone.getRawOffset;
      end
      sd = datevec(startInMillis/86400000+719529 - tzStartOffset/3600000/24);
  
      tzEndDate = java.util.Calendar.getInstance;
      endInMillis = (datenum(daterange{2})-719529)*86400000;
      tzEndDate.setTimeInMillis(endInMillis)
      enddt = java.util.Date(endInMillis);
      if tzEndDate.getTimeZone.inDaylightTime(enddt)
        tzEndOffset = tzEndDate.getTimeZone.getRawOffset + tzEndDate.getTimeZone.getDSTSavings;
      else
        tzEndOffset = tzEndDate.getTimeZone.getRawOffset;
      end
      ed = datevec(endInMillis/86400000+719529 - tzEndOffset/3600000/24);

    case 3
  
      %Convert times into milliseconds based on base date of 1/1/1970
      tzStartDate = java.util.Calendar.getInstance;
  
      % First element of daterange is vector of dates
      targetDate = datenum(daterange{1});
      numDates = length(targetDate);
      sd = zeros(numDates,6);
      
      % Convert dates to date vector components
      for i = 1:numDates
  
        dateInMillis = (targetDate(i)-719529)*86400000;
        tzStartDate.setTimeInMillis(dateInMillis)
        startdt = java.util.Date(dateInMillis);
        if tzStartDate.getTimeZone.inDaylightTime(startdt)
          tzStartOffset = tzStartDate.getTimeZone.getRawOffset + tzStartDate.getTimeZone.getDSTSavings;
        else
          tzStartOffset = tzStartDate.getTimeZone.getRawOffset;
        end
        sd(i,:) = datevec(dateInMillis/86400000+719529 - tzStartOffset/3600000/24);
  
      end
      
  end
  
else
  %If single date input given, make end of range end of that date
  %Convert times into milliseconds based on base date of 1/1/1970
  tzStartDate = java.util.Calendar.getInstance;
  startInMillis = (datenum(daterange{1})-719529)*86400000;
  tzStartDate.setTimeInMillis(startInMillis)
  startdt = java.util.Date(startInMillis);
  if tzStartDate.getTimeZone.inDaylightTime(startdt)
    tzStartOffset = tzStartDate.getTimeZone.getRawOffset + tzStartDate.getTimeZone.getDSTSavings;
  else
    tzStartOffset = tzStartDate.getTimeZone.getRawOffset;
  end
  sd = datevec(startInMillis/86400000+719529 - tzStartOffset/3600000/24);
  
  tzEndDate = java.util.Calendar.getInstance;
  endInMillis = (datenum(daterange{1})+1-719529)*86400000;
  tzEndDate.setTimeInMillis(endInMillis)
  enddt = java.util.Date(endInMillis);
  if tzEndDate.getTimeZone.inDaylightTime(enddt)
    tzEndOffset = tzEndDate.getTimeZone.getRawOffset + tzEndDate.getTimeZone.getDSTSavings;
  else
    tzEndOffset = tzEndDate.getTimeZone.getRawOffset;
  end
  ed = datevec(endInMillis/86400000+719529 - tzEndOffset/3600000/24);
end

if dateRangeLength <= 2
  
  % Convert input dates to Datetime object and set request parameters for
  % IntradayBarRequest or IntradayTickRequest
  startDateTime = Datetime(sd(1),sd(2),sd(3),sd(4),sd(5),sd(6),0);
  endDateTime = Datetime(ed(1),ed(2),ed(3),ed(4),ed(5),ed(6),0);
  request.set('startDateTime', startDateTime);
  request.set('endDateTime', endDateTime);

else
  
  % Set date time info  and time range parameters of IntradayBarDateTimeChoiceRequest
  dateTimeInfo = request.getElement('dateTimeInfo');
  startDateDuration = dateTimeInfo.getElement('startDateDuration');
  startDuration = mod(datenum(daterange{2}),1);
  startVec = datevec(startDuration);
  endDuration = mod(datenum(daterange{3}),1);
  timeList = startDateDuration.getElement('rangeStartDateTimeList');
  for i = 1:size(sd,1)
    dateTime = Datetime(sd(i,1),sd(i,2),sd(i,3),startVec(1,4)+sd(i,4),startVec(1,5),startVec(1,6),0);
    timeList.appendValue(dateTime);
  end
  
  % Time range duration for each day converted to seconds
  timeDuration = (endDuration - startDuration) * (60 * 60 * 24);
  startDateDuration.setElement('duration',int32(timeDuration));
  
end

%set other parameters, reference BLP API doc for names and settings
if nargin > 5
  numin = length(varargin);
  if mod(numin,2)
    error(message('datafeed:blpTimeSeries:parameterMismatch'))
  end
  if iscell(varargin{1})
    for i = 1:length(varargin{1})
      request.set(varargin{1}{i},varargin{2}{i})
    end
  else
    request.set(varargin{1},varargin{2})
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

if ~bBarRequest %raw tick request
  
  % Handle messages that require authentication
  if isprop(b,'returnEids')
    d = eventHandler(b);
    return
  end
    
  %process request raw tick request
  try
    bTsObj = blpTimeseries();
  catch
    %Use old event handler when blpapi3.jar is not on static classpath
    d = eventHandler(b);
    return
  end
  
  v = bTsObj.processEvents(b.session);

  %Process return vectors
  numVects = v.size;

  %Preallocate output, get number of elements for each message vector
  vNumElements = bTsObj.getNumElements;
  nEls = 0;
  subEls = [0;ones(numVects,1)];
  nCols = 8;
  for i = 1:numVects
    subEls(i+1) = vNumElements.elementAt(i-1);
    nEls = nEls + subEls(i+1);
  end
  d = cell(nEls,nCols);

  %Fill cell array with tick data, v is a vector of vectors
  rCounter = 0;
  for i = 1:numVects
    tmpV = v.elementAt(i-1);
    if ~tmpV.isEmpty
      d(rCounter+1:rCounter+subEls(i+1),:) = system_dependent(44,tmpV,tmpV.size/nCols)';
    end
    rCounter = rCounter + subEls(i+1);
  end
  
  %Strip out broker buy, broker sell, condition and exchange code columns if not requested
  if ~bTsObj.includesBrokerSellCode
    d(:,8) = [];
  end
  if ~bTsObj.includesBrokerBuyCode
    d(:,7) = [];
  end
  if ~bTsObj.includesExchCode
    d(:,6) = [];
  end
  if ~bTsObj.includesCondCode
    d(:,5) = [];
  end

  %Convert dates into MATLAB date numbers with correct timezone offset
  numTicks = size(d,1);
  for i = 1:numTicks
    d{i,2} = d{i,2}';
  end

  %convert dates
  if ~isempty(d)
    tmp = (datenum(d(:,2),'yyyy-mm-ddTHH:MM:SS')-719529)*86400000;
    d(:,2) = num2cell(convertdates(tmp));
  end
  
else %bar request
  
  % Handle messages that require authentication
  if isprop(b,'returnEids')
    d = eventHandler(b);
    return
  end
  
  %process event messages and types
  try
    bBarTsObj = blpBarTimeseries();
  catch
    %Use old event handler when blpapi3.jar is not on static classpath  
    d = eventHandler(b);
    return
  end
  
  v = bBarTsObj.processBarEvents(b.session);
  
  %Process return vectors
  numVects = v.size;
  
  %Preallocate output, get number of elements for each message vector
  vNumElements = bBarTsObj.getNumElements;
  nEls = 0;
  subEls = [0;ones(numVects,1)];
  nCols = 8;
  for i = 1:numVects
    subEls(i+1) = vNumElements.elementAt(i-1);
    nEls = nEls + subEls(i+1);
  end
  d = cell(nEls,nCols);

  %Fill cell array with tick data, v is a vector of vectors
  rCounter = 0;
  for i = 1:numVects
    tmpV = v.elementAt(i-1);
    if ~tmpV.isEmpty
      d(rCounter+1:rCounter+subEls(i+1),:) = system_dependent(44,tmpV,tmpV.size/nCols)';
    end
    rCounter = rCounter + subEls(i+1);
  end
  
  %Convert dates into MATLAB date numbers with correct timezone offset
  numTicks = size(d,1);
  for i = 1:numTicks
    d{i,1} = d{i,1}';
  end

  %Need to convert dates based on timezone
  %719529 == 01/01/1970
  if isempty(d)
    d = zeros([],8); %convert to 0x8 for backward compatibility
    return
  end
  tmp = (datenum(d(:,1),'yyyy-mm-ddTHH:MM:SS')-719529)*86400000;
  d(:,1) = {0};
  d = cell2mat(d);
  d(:,1) = convertdates(tmp);
end

function d = eventHandler(b)
%EVENTHANDLER Event handler for cases where blpapi3.jar is not on static
%classpath

%initialize variables
done = false;
d = [];

%process event messages and types
while ~done
            
  if b.timeout
    event = b.session.nextEvent(b.timeout);
    
    %Check if event is TIMEOUT
    if strcmp(char(event.eventType().toString),'TIMEOUT')
      error(message('datafeed:blp:noService'));
    end
  else
    event = b.session.nextEvent();
  end
  
  if (strcmp(char(event.eventType),'PARTIAL_RESPONSE'))
    d = [d;processResponseEvent(b,event)];   %#ok
  elseif (strcmp(char(event.eventType),'RESPONSE')) 
    d = [d;processResponseEvent(b,event)];   %#ok
    done = true;
  else
    msgIter = event.messageIterator();
    while (msgIter.hasNext()) 
      msg = msgIter.next();
      if (strcmp(char(event.eventType),'SESSION_STATUS'))
        if (msg.messageType().equals('SessionTerminated')) 							
          done = true;
        end
      end
    end
  end
end


function d = processResponseEvent(b,event)
%PROCESSRESPONSEEVENT Process events

%imports
import com.bloomberglp.blpapi.*;
import java.util.Calendar;

%initialize response error
RESPONSE_ERROR = Name('responseError');

%Process messages
msgIter = event.messageIterator();
while (msgIter.hasNext()) 
  msg = msgIter.next();
  b.entitlements(msg);
  if (msg.hasElement(RESPONSE_ERROR)) 
    error(message('datafeed:blp:timeseriesFailure',char(msg.getElement(RESPONSE_ERROR))));
  end
  d = processMessage(msg);
end

function d = processMessage(msg)
%PROCESSMESSAGE Process event messages and data

%imports
import com.bloomberglp.blpapi.*;
import java.util.Calendar;
import java.text.DecimalFormat;
import java.text.SimpleDateFormat;

%initialize date formatting
d_dateFormat = SimpleDateFormat();
d_dateFormat.applyPattern('MM/dd/yyyy k:mm');
d_decimalFormat = DecimalFormat();
d_decimalFormat.setMaximumFractionDigits(3);
  
%get message type
sMessageType = char(msg.messageType);

%base date used in date conversions
baseDate = datenum('01/01/1970');
  
if strcmp(sMessageType,'IntradayTickResponse')
  
  %intraday tick responses, raw tick data
  
  %create data type flags
  TICK_DATA = Name('tickData');
  SIZE = Name('size');
  TIME = Name('time');
  TYPE = Name('type');
  VALUE = Name('value');
  CONDITION = Name('conditionCodes');
  EXCHANGE = Name('exchangeCode');
  BROKERBUYCODE = Name('brokerBuyCode');
  BROKERSELLCODE = Name('brokerSellCode');
  RPSCODE = Name('rpsCode');
  RPTPARTY = Name('rptParty');
  RPTCONTRA = Name('rptContra');
  
  %get data object and number of ticks
  data = msg.getElement(TICK_DATA).getElement(TICK_DATA);
  numItems = data.numValues();
  
  %preallocate output
  d = cell(numItems,4);
  
  %parse data
  for i = 0:numItems-1
    item = data.getValueAsElement(i);
    d{i+1,1} = item.getElementAsString(TYPE).toCharArray';
    d{i+1,2} = item.getElementAsDate(TIME).toString.toCharArray';
    d{i+1,3} = item.getElementAsFloat64(VALUE);
    d{i+1,4} = item.getElementAsInt32(SIZE);
    try
      d{i+1,5} = item.getElementAsString(CONDITION).toCharArray';
    catch
      %Every record needs to be checked for a condition code
    end
    try
      d{i+1,6} = item.getElementAsString(EXCHANGE).toCharArray';
    catch
      %Every record needs to be checked for a exchange code
    end
    try
      d{i+1,7} = item.getElementAsString(BROKERBUYCODE).toCharArray';
    catch 
      %Every record needs to be checked for a condition code
    end
    try
      d{i+1,8} = item.getElementAsString(BROKERSELLCODE).toCharArray';
    catch
      %Every record needs to be checked for a exchange code
    end
    try
      d{i+1,9} = item.getElementAsString(RPSCODE).toCharArray';
    catch
      %Every record needs to be checked for a condition code
    end
    try
      d{i+1,10} = item.getElementAsString(RPTPARTY).toCharArray';
    catch
      %Every record needs to be checked for a exchange code
    end
    try
      d{i+1,11} = item.getElementAsString(RPTCONTRA).toCharArray';
    catch 
      %Every record needs to be checked for a condition code
    end
  end

  if isempty(d)
    return
  end
  
  %convert dates to datenumbers and account for timezone
  tmp = datenum(d(:,2),'yyyy-mm-ddTHH:MM:SS');
  for i = 1:numItems
    tzdate = java.util.Date((tmp(i)-baseDate)*86400000);
    tzOffset = tzdate.getTimezoneOffset / (24*60);
    d{i,2} = tmp(i) - tzOffset;
  end
  
elseif strcmp(sMessageType,'IntradayBarResponse')
  
  %intraday tick responses, raw tick data
  BAR_DATA = Name('barData');
  BAR_TICK_DATA = Name('barTickData');
  OPEN = Name('open');
  HIGH = Name('high');
  LOW = Name('low');
  CLOSE = Name('close');
  VOLUME = Name('volume');
  NUM_EVENTS = Name('numEvents');
  TIME = Name('time');
  TVALUE = Name('value');
  
  %get data object from message
  data = msg.getElement(BAR_DATA).getElement(BAR_TICK_DATA);
  numBars = data.numValues();

  %preallocate output
  d = nan(numBars,8);
  tmpDates = cell(numBars,1);

  %parse data
  for i = 0:numBars-1
    bar = data.getValueAsElement(i);
    tmpDates{i+1} = bar.getElementAsDate(TIME).toString.toCharArray';
    d(i+1,2) = bar.getElementAsFloat64(OPEN);
    d(i+1,3) = bar.getElementAsFloat64(HIGH);
    d(i+1,4) = bar.getElementAsFloat64(LOW);
    d(i+1,5) = bar.getElementAsFloat64(CLOSE);
    d(i+1,6) = bar.getElementAsInt64(VOLUME);
    d(i+1,7) = bar.getElementAsInt32(NUM_EVENTS);
    d(i+1,8) = bar.getElementAsFloat64(TVALUE);
  end
  
  %Convert dates
  if ~isempty(d)
    d(:,1) = datenum(tmpDates,'yyyy-mm-ddTHH:MM:SS');
    for i = 1:numBars
      tzdate = java.util.Date((d(i,1)-baseDate)*86400000);
      tzOffset = tzdate.getTimezoneOffset / (24*60);
      d(i,1) = d(i,1) - tzOffset;
    end
  end
end

function x = convertdates(d)
%CONVERTDATES Bloomberg dates to MATLAB date numbers

numDates = size(d,1);
x = zeros(numDates,1);
tzDate = java.util.Calendar.getInstance();
calDate = java.util.Date;
for i = 1:numDates
  tzDate.setTimeInMillis(d(i,1));
  calDate.setTime(d(i,1));
  if (tzDate.getTimeZone().inDaylightTime(calDate))
    tzOffset = tzDate.getTimeZone().getRawOffset() + tzDate.getTimeZone().getDSTSavings();
  else
    tzOffset = tzDate.getTimeZone().getRawOffset();
  end
  x(i) = (d(i)/86400000) + 719529 + tzOffset/3600000/24;
end