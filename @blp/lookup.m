function d = lookup(b,s,reqType,varargin)
%LOOKUP Bloomberg V3 security look up.
%   L = LOOKUP(B,S,REQTYPE,'NAME1','VALUE1','NAME2','VALUE2',...) finds
%   information given additional inputs as name/value pairs.
%
%   Examples:
%
%   insts = lookup(b,'IBM','instrumentListRequest','maxResults',20,'yellowKeyFilter','YK_FILTER_CORP',...
%                'languageOverride','LANG_OVERRIDE_NONE')
%
%   returns
%
%   insts = 
% 
%        security: {20x1 cell}
%     description: {20x1 cell}
%
%   curves = lookup(b,'GOLD','curveListRequest','maxResults',10,...
%                'countryCode','US','currencyCode','USD',...
%                'curveid','CD1016','type','CORP','subtype','CDS')
%
%   return
%
%    curves = 
% 
%           curve: {'YCCD1016 Index'}
%     description: {'Goldman Sachs Group Inc/The'}
%         country: {'US'}
%        currency: {'USD'}
%         curveid: {'CD1016'}
%            type: {'CORP'}
%         subtype: {'CDS'}
%       publisher: {'Bloomberg'}
%           bbgid: {''}
%
%   govts = lookup(b,'T','govtListRequest','maxResults',10,'partialMatch',false)   
%
%   returns
%
%   govts = 
% 
%     parseky: {10x1 cell}
%        name: {10x1 cell}
%      ticker: {10x1 cell}
%
%   See also BLP, GETDATA, HISTORY, REALTIME, TIMESERIES.

%   Copyright 1999-2013 The MathWorks, Inc.

%imports
import com.bloomberglp.blpapi.*;

%Validate security list.  Security list should be cell array string
if ischar(s) || isstring(s)
  s = cellstr(s);
end
if ~iscell(s) || ~ischar(s{1})
  error(message('datafeed:blpGetData:securityInputError'))
end

%ope instruments service
if ~b.session.openService('//blp/instruments')
  error(message('datafeed:blp:noService'));
end

%get bloomberg service, set request type
instDataService = b.session.getService('//blp/instruments');
request = instDataService.createRequest(reqType);

%add securities to request
request.set('query',s);
for i = 1:2:length(varargin)
  switch varargin{i}
    case 'maxResults'
      request.set('maxResults',int32(varargin{i+1}));
    otherwise
      request.set(varargin{i},varargin{i+1});
  end
end

%send request
d_cid = b.session.sendRequest(request,[]);

%process event messages and types
done = false;
k = 1;
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
      
      msgResults = msg.getElement('results');
      
      switch char(msg.messageType)
        
        case 'InstrumentListResponse'
          
          for i = 1:msgResults.numValues
            d.security{k,1} = msgResults.getValueAsElement(i-1).getElementAsString('security');
            d.description{k,1} = msgResults.getValueAsElement(i-1).getElementAsString('description');
            k = k + 1;
          end
          
          if ~exist('d','var')
            d = [];
            return
          end
          
          d.security = cellstr(char(cell2mat(d.security)));
          d.description = cellstr(char(cell2mat(d.description)));
          
        case 'CurveListResponse'
          
          for i = 1:msgResults.numValues
            d.curve{k,1} = msgResults.getValueAsElement(i-1).getElementAsString('curve');
            d.description{k,1} = msgResults.getValueAsElement(i-1).getElementAsString('description');
            d.country{k,1} = msgResults.getValueAsElement(i-1).getElementAsString('country');
            d.currency{k,1} = msgResults.getValueAsElement(i-1).getElementAsString('currency');
            d.curveid{k,1} = msgResults.getValueAsElement(i-1).getElementAsString('curveid');
            d.type{k,1} = msgResults.getValueAsElement(i-1).getElementAsString('type');
            d.subtype{k,1} = msgResults.getValueAsElement(i-1).getElementAsString('subtype');
            d.publisher{k,1} = msgResults.getValueAsElement(i-1).getElementAsString('publisher');
            d.bbgid{k,1} = msgResults.getValueAsElement(i-1).getElementAsString('bbgid');
            k = k + 1;
          end
          
          if ~exist('d','var')
            d = [];
            return
          end
          
          d.curve = cellstr(char(cell2mat(d.curve)));
          d.description = cellstr(char(cell2mat(d.description)));
          d.country = cellstr(char(cell2mat(d.country)));
          d.currency = cellstr(char(cell2mat(d.currency)));
          d.curveid = cellstr(char(cell2mat(d.curveid)));
          d.type = cellstr(char(cell2mat(d.type)));
          d.subtype = cellstr(char(cell2mat(d.subtype)));
          d.publisher = cellstr(char(cell2mat(d.publisher)));
          d.bbgid = cellstr(char(cell2mat(d.bbgid)));
          
        case 'GovtListResponse'
           
          for i = 1:msgResults.numValues
            d.parseky{k,1} = msgResults.getValueAsElement(i-1).getElementAsString('parseky');
            d.name{k,1} = msgResults.getValueAsElement(i-1).getElementAsString('name');
            d.ticker{k,1} = msgResults.getValueAsElement(i-1).getElementAsString('ticker');
            k = k + 1;
          end
          
          if ~exist('d','var')
            d = [];
            return
          end
          
          d.parseky = cellstr(char(cell2mat(d.parseky)));
          d.name = cellstr(char(cell2mat(d.name)));
          d.ticker = cellstr(char(cell2mat(d.ticker)));
           
      end
    end
            
    if (event.eventType().toString == java.lang.String('RESPONSE')) 
      done = true;
    end
  end
end

