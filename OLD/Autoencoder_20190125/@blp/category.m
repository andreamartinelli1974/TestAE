function d = category(b,f)
%CATEGORY Bloomberg V3 field category search.
%   D = CATEGORY(B,F) returns category information given a search string,
%   F.  The data returned is a Nx5 cell array containing categories, field
%   id's, field mnemonics, field names, and field data types.
%
%   See also BLP, FIELDINFO, FIELDSEARCH, GETDATA, HISTORY, REALTIME, TIMESERIES.

%   Copyright 1999-2010 The MathWorks, Inc.

%imports
import com.bloomberglp.blpapi.*;

%get bloomberg service, set request type
b.session.openService('//blp/apiflds');
fldInfoService = b.session.getService('//blp/apiflds');
request = fldInfoService.createRequest('CategorizedFieldSearchRequest');

%Convert field list to cell array
if ischar(f) || isstring(f) 
  f = cellstr(f);
end
if ~iscell(f) || ~ischar(f{1})
  error(message('datafeed:blpCategory:fieldInputError'))
end

%add fields to request
for i = 1:length(f)
  request.set('searchSpec',f{i});
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

%%create data type flags
CATEGORY_DATA = Name('category');
FIELD_DATA = Name('fieldData');

%get data from message
if ~msg.hasElement(CATEGORY_DATA)
  msgFailure = msg.getElement('reason');
  error(message('datafeed:blpCategory:noCategoryData',char(msgFailure.getElementAsString('description'))))
end
categoryDataArray = msg.getElement(CATEGORY_DATA);
numCategories = categoryDataArray.numValues();

%parse return data into structure
k = 1;
for i = 0:numCategories-1
  categoryData = categoryDataArray.getValueAsElement(i);
  fieldDataArray = categoryData.getElement(FIELD_DATA);
  categoryName = char(categoryData.getElementAsString('categoryName'));
  for j = 0:fieldDataArray.numValues()-1;
    fieldData = fieldDataArray.getValueAsElement(j);
    if (fieldData.isNull())
      %No data
      d = [];
    else
      
      fieldInfo = fieldData.getElement('fieldInfo');
      d{k,1} = categoryName; %#ok
      d{k,2} = char(fieldData.getElementAsString('id')); %#ok
      d{k,3} = char(fieldInfo.getElementAsString('mnemonic')); %#ok
      d{k,4} = char(fieldInfo.getElementAsString('description')); %#ok
      d{k,5} = char(fieldInfo.getElementAsString('datatype')); %#ok
      k = k + 1;
       
    end
    
  end
  
end

%Check for no return data
if ~exist('d','var')
  error(message('datafeed:blp:noReturnData'))
end
