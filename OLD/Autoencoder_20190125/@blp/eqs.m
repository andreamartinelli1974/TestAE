function d = eqs(b,screenName,screenType,languageId,Group,varargin)
%EQS Bloomberg V3 equity screening.
%   D = EQS(B,SNAME) returns equity screening data given the Bloomberg screen name,
%   SNAME.
%
%   D = EQS(B,SNAME,STYPE) returns equity screening data given the screen name,
%   SNAME, and screen type, STYPE.   
%
%   D = EQS(B,SNAME,STYPE,LANGUAGEID,GROUP) returns equity screening data 
%   given the screen name, SNAME, screen type, STYPE, language, LANGUAGEID, 
%   and GROUP.
%
%   Examples:
%
%   d = eqs(b,'Core Capital Ratios'); 
%   d = eqs(b,'F score - Piotroski'); 
%   d = eqs(b,'Fair Value (Level III Assets)'); 
%   d = eqs(b,'Frontier Market Stocks with 1 billion USD Market Caps'); 
%   d = eqs(b,'Global Bank Capital'); 
%   d = eqs(b,'Global Oil Companies YTD Return'); 
%   d = eqs(b,'Investment Grade Credit Rating'); 
%   d = eqs(b,'Top 500 Global Islamic/Sharia Compliant Companies'); 
%   d = eqs(b,'Vehicle-Engine-Parts'); 
%
%   See also BLP, GETDATA, TAHISTORY.

%   Copyright 1999-2012 The MathWorks, Inc.
%   $Revision: 1.1.8.4 $   $Date: 2014/04/10 21:31:03 $

%imports
import com.bloomberglp.blpapi.*;

%get bloomberg service, set request type
refDataService = b.session.getService('//blp/refdata');
request = refDataService.createRequest('BeqsRequest');

%set properties
request.getElement('screenName').setValue(screenName)
if exist('screenType','var') && ~isempty(screenType)
  request.getElement('screenType').setValue(screenType)
end
if exist('languageId','var') && ~isempty(languageId)
  request.getElement('languageId').setValue(languageId)
end
if exist('Group','var') && ~isempty(Group)
  request.getElement('Group').setValue(Group)
end

%set other parameters, reference BLP API doc for names and settings
if nargin > 5
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
    if msg.hasElement(Name('responseError'));
      error(message('datafeed:blp:eventError',char(msg.getElement('responseError').getElementAsString('message'))))
    end
    
    if (msg.correlationID() == d_cid)
      
      if strcmp(msg.messageType.toString,'BeqsResponse')
        if msg.hasElement('data')
          sdElement = msg.getElement('data');
          for j = 0:sdElement.numElements-1
            subElement = sdElement.getElement(j);
            switch char(subElement.name)
              case 'fieldDisplayUnits'
                numFields = subElement.numElements;
                d = cell(1,numFields);
                for k = 0:numFields-1
                  d{1,k+1} = char(subElement.getElement(k).name);
                end
              case 'securityData'
                numValues = subElement.numValues;
                d(2:numValues+1,1:numFields) = cell(numValues,numFields);
                for k = 0:numValues-1
                  subValueElement = subElement.getValueAsElement(k);
                  subElementElement = subValueElement.getElement(2);
                  for m = 1:numFields
                    tmpElement = subElementElement.getElement(d{1,m});
                    switch char(tmpElement.datatype)
                      case 'FLOAT64'
                        if tmpElement.isNull
                          d{k+2,m} = NaN;
                        else
                          d{k+2,m} = tmpElement.getValueAsFloat64;
                        end
                      case 'INT32'
                        if tmpElement.isNull
                          d{k+2,m} = NaN;
                        else
                          d{k+2,m} = tmpElement.getValueAsInt32;
                        end
                      otherwise
                        if tmpElement.isNull
                          d{k+2,m} = [];
                        else
                          d{k+2,m} = char(tmpElement.getValueAsString);
                        end
                    end
                  end
               
                end
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
    
