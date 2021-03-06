function d = fieldinfo(b,f)
%FIELDINFO Bloomberg V3 field information.
%   D = FIELDINFO(B,F) returns field information given a field mnemonic,
%   F.  The data returned is a Mx5 cell array containing the field help, 
%   field id, field mnemonic, field name, and field data type.
%
%   See also BLP, CATEGORY, FIELDSEARCH, GETDATA, HISTORY, REALTIME, TIMESERIES.

%   Copyright 1999-2010 The MathWorks, Inc.

%imports
import com.bloomberglp.blpapi.*;

%get bloomberg service, set request type
b.session.openService('//blp/apiflds');
fldInfoService = b.session.getService('//blp/apiflds');
request = fldInfoService.createRequest('FieldInfoRequest');

%Convert field list to cell array
if ischar(f) || isstring(f)
  f = cellstr(f);
end
if ~iscell(f) || ~ischar(f{1})
  error(message('datafeed:blpFieldInfo:fieldInputError'))
end

%add fields to request
for i = 1:length(f)
  request.append('id',f{i});
end

%set flags
request.set('returnFieldDocumentation',true);
request.append('properties','fieldoverridable');

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
tmp = [];
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
    if (msg.correlationID() == d_cid) 
      tmp = [tmp;processMessage(msg)];   %#ok
    end
            
    if (event.eventType().toString == java.lang.String('RESPONSE')) 
      done = true;
    end
  end
end

d = tmp;


function d = processMessage(msg)
%PROCESSRESPONSEEVENT Process events

%imports
import com.bloomberglp.blpapi.*;

%create data type flags
FIELD_DATA = Name('fieldData');

%get data from message
fieldDataArray = msg.getElement(FIELD_DATA);
numFields = fieldDataArray.numValues();

%parse return data into structure
k = 1;
for j = 0:numFields-1
  
  fieldData = fieldDataArray.getValueAsElement(j);
  
  if (fieldData.isNull())
      %No data
      d = [];
  else
      
    try
      fieldInfo = fieldData.getElement('fieldInfo');
      d{k,1} = char(fieldInfo.getElementAsString('documentation')); %#ok
      d{k,2} = char(fieldData.getElementAsString('id')); %#ok
      d{k,3} = char(fieldInfo.getElementAsString('mnemonic')); %#ok
      d{k,4} = char(fieldInfo.getElementAsString('description')); %#ok
      d{k,5} = char(fieldInfo.getElementAsString('datatype')); %#ok
      k = k + 1;
    catch %#ok
      fieldError = fieldData.getElement('fieldError');
      d{k,1} = char(fieldData.getElementAsString('id')); %#ok
      d{k,2} = char(fieldError.getElementAsString('category')); %#ok
      d{k,3} = char(fieldError.getElementAsString('source')); %#ok
      d{k,4} = char(fieldError.getElementAsString('category')); %#ok
      d{k,5} = char(fieldError.getElementAsString('message')); %#ok
      
      k = k + 1;
    end
  end
    
end
