function [d,sec] = getdata(b,s,f,o,ov,varargin)
%GETDATA Current Bloomberg V3 data.
%   [D,SEC] = GETDATA(B,S,F) returns the data for the fields F for the 
%   security list S.  SEC is the security list that maps the order of the 
%   return data.   The return data, D and SEC, is sorted to match the
%   input order of S.
%
%   [D,SEC] = GETDATA(B,S,F,O,OV) returns the data for the fields F for the 
%   security list S using the override fields O with corresponding override
%   values.
%
%   [D,SEC] = GETDATA(B,S,F,O,OV,NAME,VALUE,...) returns the data for the fields F for the 
%   security list S using the override fields O with corresponding override
%   values.  NAME/VALUE pairs are used for additional Bloomberg request settings.
%
%   Examples:
%
%   [D,SEC] = GETDATA(C,'ABC US Equity',{'LAST_PRICE';'OPEN'}) returns
%   today's current and open price of the given security.
%
%   [D,SEC] = GETDATA(C,'3358ABCD4 Corp',...
%   {'YLD_YTM_ASK','ASK','OAS_SPREAD_ASK','OAS_VOL_ASK'},...
%   {'ASK','OAS_VOL_ASK'},{'99.125000','14.000000'})
%   returns the requested fields given override fields and values.
%
%   See also BLP, HISTORY, REALTIME, TIMESERIES.

%   Copyright 1999-2010 The MathWorks, Inc.

%imports
import com.bloomberglp.blpapi.*;

%Validate security list.  Security list should be cell array string
if ischar(s) || isstring(s)
  s = cellstr(s);
end
if ~iscell(s) || ~ischar(s{1})
  error(message('datafeed:blpGetData:securityInputError'))
end

%Convert field list to cell array
if ischar(f) || isstring(f)
  f = cellstr(f);
end
if ~iscell(f) || ~ischar(f{1})
  error(message('datafeed:blpGetData:fieldInputError'))
end

%Convert overrides and values to cell array
if exist('o','var') && ~isempty(o)
  if ischar(o) || isstring(o)
    o = cellstr(o);
  elseif ~iscell(o) || ~ischar(o{1})
    error(message('datafeed:blpGetData:overrideFieldInputError'))
  end
end

if exist('ov','var') && ~isempty(ov)
  if ischar(ov) || isstring(ov)
    ov = cellstr(ov);
  elseif ~iscell(ov) || ~ischar(ov{1})
    error(message('datafeed:blpGetData:overrideValueInputError'))
  end
end

%get bloomberg service, set request type
refDataService = b.session.getService('//blp/refdata');
request = refDataService.createRequest('ReferenceDataRequest');

%add securities to request
securities = request.getElement('securities');
for i = 1:length(s)
  securities.appendValue(s{i});
end

%add fields to request, max fields is 400
fields = request.getElement('fields');
for i = 1:length(f)
  fields.appendValue(f{i});
end

%add overrides to request if given
if nargin > 3 
  
  if ~exist('ov','var') || (length(o) ~= length(ov))
    error(message('datafeed:blp:overrideMismatch'));
  end
  
  overrides = request.getElement('overrides');

  for i = 1:length(o)
    override = overrides.appendElement;
    override.setElement('fieldId', o{i});
    override.setElement('value', ov{i});
  end
  
end

%set other parameters, reference BLP API doc for names and settings
if nargin > 5
  numin = length(varargin);
  if mod(numin,2)
    error(message('datafeed:blpGetData:parameterMismatch'))
  end
  for i = 1:2:length(varargin)
    request.set(char(varargin{i}),varargin{i+1})
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
    d_cid = b.session.sendRequest(request,b.user,[]);
  case 'blpsrv'
    b.authorize;
    d_cid = b.session.sendRequest(request,b.user,CorrelationID(b.uuid));
  case 'blp'
    d_cid = b.session.sendRequest(request,[]);
end

%process event messages and types
done = false;
k = 1;
sec = [];
tmpData = {NaN};
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
  
  msgIter = event.messageIterator();
  while (msgIter.hasNext)
    
    msg = msgIter.next();
    
    %trap event error
    if msg.hasElement(Name('responseError'))
      error(message('datafeed:blpGetData:eventError', char( msg.getElement( 'responseError' ).getElementAsString( 'message' ) )))
    end
    
    if (msg.correlationID() == d_cid)
      
      b.entitlements(msg);
      
      [tmp{k},newflds,tmpsec] = processMessage(msg,f);   %#ok
      if isempty(tmp{k})
        for i = 1:length(f)
          try
            tmp{k}.(f{i}) = tmpData(ones(length(tmpsec),1));   
          catch exception %#ok
            tmp{k}.(['n' char(scrubfields(f(i)))]) = tmpData(ones(length(tmpsec),1));   
          end
        end
      end
      sec = [sec;tmpsec];                              %#ok
      k = k + 1;
    end
            
    if (event.eventType().toString == java.lang.String('RESPONSE')) 
      done = true;
    end
  end
end

% Build output structure
if ~exist('tmp','var')
  d = [];
  return
end

%if multiple messages, need to concatenate structures
nummessages = length(tmp);

if nummessages == 1

  %single message
  d = tmp{1};   

else
  %multiple messages
  
  flds = {};
  %get union of fields from messages
  for i = 1:nummessages
    if ~isempty(tmp{i})
      flds = union(flds,fieldnames(tmp{i}));
    end
  end
  
  %fill empty elements with empty structures
  for i = 1:length(tmp)
    if isempty(tmp{i})
      for j = 1:length(flds)
        tmp{i}.(flds{j}) = {NaN};  
      end
    end
  end
  
  %concatenate structures, trapping unique fields in messages
  %Need to trap all return types and compare to any structure elements to
  %make rest of structure is populated correctly
  for i = 1:nummessages
    for j = 1:length(flds)
      if isfield(tmp{i},flds{j})
        if exist('d','var') && isfield(d,flds{j})
          if iscell(d.(flds{j})) && isa(tmp{i}.(flds{j}),'double')
            d.(flds{j}) = nan(size(d.(flds{j})));
            d.(flds{j})(end+1:end+length(tmp{i}.(flds{j})),1) = tmp{i}.(flds{j});
          elseif isa(d.(flds{j}),'double') && iscell(tmp{i}.(flds{j}))
            d.(flds{j})(end+1:end+length(tmp{i}.(flds{j})),1) = nan(length(tmp{i}.(flds{j})),1);
          else
            d.(flds{j})(end+1:end+length(tmp{i}.(flds{j})),1) = tmp{i}.(flds{j});
          end
        else
          d.(flds{j}) = tmp{i}.(flds{j})(:);
        end
      end
    end
  end
end

%Fill in valid fields that returned events
if ~exist('d','var')
  d = [];
  return
end
if isempty(d)
  mFields = f;
else
  retFields = fieldnames(d);
  for i = 1:length(f)
    if ~isnan(str2double(f{i}(1))) && ~any(strcmp(f{i}(1),{'i','j'}))
      f{i} = ['n' f{i}];
    end
  end
  mFields = setdiff(scrubfields(f),retFields);
end

%Create empty return value for each requested security for fields with no
%events
numRecords = length(s);
tmpString = {[]};
emptyRecords = tmpString(ones(numRecords,1),:);
emptyNumbers = nan(numRecords,1);
sdArray = msg.getElement('securityData');
sd = sdArray.getValueAsElement(0);
fd = sd.getElement('fieldData');
for i = 1:length(mFields)
  switch char(fd.getElement(mFields{i}).datatype)
    case {'DATE','FLOAT32','FLOAT64','INT32'}
      try
        d.(mFields{i}) = emptyNumbers;
      catch
        d.(['n' char(scrubfields(mFields(i)))]) = emptyNumbers;
      end
    otherwise
      try
        d.(mFields{i}) = emptyRecords;
      catch
        d.(['n' char(scrubfields(mFields(i)))]) = emptyRecords;
      end
  end
end

%Pad fields with no data at end of fields
allFields = fieldnames(d);
for i = 1:length(allFields)
  if length(d.(allFields{i})) < numRecords
    if iscell(d.(allFields{i}))
      d.(allFields{i}){numRecords} = [];
    else
      numPts = length(d.(allFields{i}));
      d.(allFields{i})(numPts+1:numRecords,1) = NaN;
    end
  end
end

%Sort output data to match input list
numsec = length(s);
outInd = zeros(length(s),1);
for i = 1:numsec
  secInd = find(strcmp(s(i),sec));
  outInd(i) = secInd(1);
end
for i = 1:length(allFields)
  d.(allFields{i}) = d.(allFields{i})(outInd);
end
sec = sec(outInd);

%Remove the error field if there are no error messages
if isempty([d.ERROR{:}])
  d = rmfield(d,'ERROR');
end


function [d,f,sec] = processMessage(msg,reqFlds)
%PROCESSRESPONSEEVENT Process events

%imports
import com.bloomberglp.blpapi.*;

%%create data type flags
f = [];
SECURITY_DATA = Name('securityData');
FIELD_DATA = Name('fieldData');
FIELD_EXCEPTIONS = Name('fieldExceptions');
ERROR_INFO = Name('errorInfo');
EIDDATA = Name('eidData');

%get data from message
securityDataArray = msg.getElement(SECURITY_DATA);
numSecurities = securityDataArray.numValues();

%parse return data into structure
if numSecurities
  sec = cell(numSecurities,1);
else
  sec = [];
end
d.ERROR = cell(numSecurities,1);
for i = 0:numSecurities-1
  securityData = securityDataArray.getValueAsElement(i);
  eidData = securityData.getElement(EIDDATA);
  for j = 1:eidData.numValues
    d.EID{i+1,1}(j,1) = eidData.getValueAsInt32(j-1);
  end
  sec{i+1} = char(securityData.getElementAsString('security'));

  %Check for security errors
  if securityData.hasElement('securityError')
    d.ERROR{i+1} = char(securityData.getElement('securityError').getElementAsString('subcategory'));
  end
  fieldData = securityData.getElement(FIELD_DATA);
  for j = 0:fieldData.numElements()-1
    field = fieldData.getElement(j);
    if (field.isNull()) && ~exist('d','var')
      %No data
      d = [];
    else
      
      fldname = char(field.name);
      
      %If fldname cannot be used a structure field name, prepend "n"
      try
        fldTest.(fldname) = NaN;
        f{j+1} = fldname; %#ok
      catch
        tmpfld = scrubfields({fldname});
        fldTest.(['n' tmpfld{:}]) = NaN;
        fldname = ['n' tmpfld{:}];
        f{j+1} = fldname;  %#ok
      end
      clear fldTest
      
      %Build output structure based on field datatype
      switch char(field.datatype)
        case {'FLOAT64','FLOAT32','INT32'}
          if exist('d','var') && isfield(d,fldname)
            try
              d.(fldname)(i+1,1) = field.getValueAsFloat64(0);
            catch exception %#ok
              d.(fldname) = nan(length(d.(fldname)),1);
              d.(fldname)(i+1,1) = field.getValueAsFloat64(0);
            end
          else
            d.(fldname) = nan(numSecurities,1);
            d.(fldname)(i+1,1) = field.getValueAsFloat64(0);
          end
        case {'DATE'}
          if exist('d','var') && isfield(d,fldname)
            try
              d.(fldname)(i+1,1) = datenum(char(field.getValueAsString(0)));
            catch exception %#ok
              d.(fldname) = nan(length(d.(fldname)),1);
              d.(fldname)(i+1,1) = datenum(char(field.getValueAsString(0)));
            end
          else
            d.(fldname) = nan(numSecurities,1);
            d.(fldname)(i+1,1) = datenum(char(field.getValueAsString(0)));
          end
        case {'SEQUENCE'}
          %Bulk data creates cell array
          numEls = field.numValues;
          bulkdata = cell(numEls,1);
          for k = 0:numEls - 1
            numSubEls = field.getValueAsElement(k).numElements;
            for m = 0:numSubEls-1
              switch char(field.getValueAsElement(k).getElement(m).datatype)
                case {'DATE'}
                  tmpdate = char(field.getValueAsElement(k).getElement(m).getValueAsString(0));
                  if isempty(tmpdate)
                    bulkdata{k+1,m+1} = NaN;
                  else
                    bulkdata{k+1,m+1} = datenum(tmpdate);
                  end
                case {'FLOAT64','FLOAT32','INT32'}
                  bulkdata{k+1,m+1} = field.getValueAsElement(k).getElement(m).getValueAsFloat64(0);
                otherwise
                  bulkdata{k+1,m+1} = char(field.getValueAsElement(k).getElement(m).getValueAsString(0));
              end
            end
          end
          d.(fldname){i+1,1} = bulkdata;
        otherwise
          if exist('d','var') && isfield(d,fldname)
            d.(fldname){i+1,1} = char(field.getValueAsString(0));
          else
            d.(fldname) = cell(numSecurities,1);
            d.(fldname){i+1,1} = char(field.getValueAsString(0));
          end
      end    
    end
  end
  
  %process field exceptions, errors
  fieldExceptionArray = securityData.getElement(FIELD_EXCEPTIONS);
  for k = 0:fieldExceptionArray.numValues()-1
    fieldException = fieldExceptionArray.getValueAsElement(k);
    try
      d.ERROR{i+1,1} = char(fieldException.getElement(ERROR_INFO).getElementAsString('subcategory'));
    catch exception %#ok
      d.ERROR(i+1,1) = NaN;  
    end
    f = [];
  end
end

if ~exist('d','var') | isempty(d) %#ok
  d = [];
  return
else
  tmpFlds = fieldnames(d);
  numFlds = length(tmpFlds);
  numEls = length(d.(tmpFlds{1}));
  if numEls ~= numSecurities
    szDiff = numSecurities - numEls;
    for j = 1:numFlds
      if iscell(d.(tmpFlds{j}))
        d.(tmpFlds{j}) = [d.(tmpFlds{j});cell(szDiff,1)];
      else
        d.(tmpFlds{j}) = [d.(tmpFlds{j});nan(szDiff,1)];
      end
    end
  end
end

%Fill in fields that had no return data, meaning valid field but no data
%for given security
for i = 1:length(reqFlds)
  if ~isnan(str2double(reqFlds{i}(1))) && ~any(strcmp(reqFlds{i}(1),{'i','j'}))
    reqFlds{i} = ['n' reqFlds{i}];
  end
end
missingfields = setdiff(scrubfields(reqFlds),fieldnames(d));
for i = 1:length(missingfields)
  d.(missingfields{i}) = cell(numSecurities,1);
end
  
%Double check for mismatched field element lengths
structFields = fieldnames(d);
numStructFields = length(structFields);
numEntries = zeros(numStructFields,1);
for i = 1:numStructFields
  numEntries(i) = length(d.(structFields{i}));
end
maxNumEntries = max(numEntries);
for i = 1:numStructFields
  if numEntries(i) ~= maxNumEntries
    if isnumeric(d.(structFields{i}))
      d.(structFields{i})(end+1:maxNumEntries) = NaN;
    else
      d.(structFields{i})(end+1:maxNumEntries) = cell(maxNumEntries-length(d.(structFields{i})),1);
    end
  end
end

function flds = scrubfields(flds)
%SCRUBFIELDS Remove illegal characters from fieldnames.

%Substitution for characters that are not allowed in MATLAB field names
for x = 1:length(flds)
  flds{x}(flds{x} == ' ') = [];
  h = find(flds{x} == ' ' | flds{x} == '''' ...
      | flds{x} == '(' | flds{x} == ')' ...
      | flds{x} == '.' | flds{x} == ':' ...
      | flds{x} == '?' | flds{x} == '$');
  flds{x}(h) = [];   %#ok    
  flds{x}(flds{x} == '/') = 'd';    
  flds{x}(flds{x} == '+') = 'p';
  flds{x}(flds{x} == '%') = 'c';
  flds{x}(flds{x} == '-') = 'm';
  flds{x}(flds{x} == '&') = 'a';
  flds{x}(flds{x} == '<') = 'l';
  flds{x}(flds{x} == '>') = 'g';
  flds{x}(flds{x} == '#') = 'n';
  flds{x}(flds{x} == '*') = 't';
end
