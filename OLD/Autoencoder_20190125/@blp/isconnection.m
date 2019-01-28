function x = isconnection(b) 
%ISCONNECTION True if valid Bloomberg V3 connection.
%   ISCONNECTION is not recommended.  Use BLP instead.
%   X = ISCONNECTION(C) returns 1 if C is a valid Bloomberg V3 connection
%   and 0 otherwise.
%
%   See also BLP, CLOSE, GETDATA.

%   Copyright 1999-2010 The MathWorks, Inc.

%imports
import com.bloomberglp.blpapi.*;

%get bloomberg service, create empty request to test connection
refDataService = b.session.getService('//blp/refdata');
request = refDataService.createRequest('ReferenceDataRequest');

try
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
  x = true;
catch exception %#ok
  x = false;
  return
end

%need to process event messages associated with empty request
done = false;
while ~done
             
  if b.timeout
    event = b.session.nextEvent(b.timeout);
    
    %Check if event is TIMEOUT
    if strcmp(char(event.eventType().toString),'TIMEOUT')
      x = false;
      return
    end
  else
    event = b.session.nextEvent();
  end
  
  msgIter = event.messageIterator();
  
  while (msgIter.hasNext)
    
    msg = msgIter.next();
    
    %trap event error
    if msg.hasElement(Name('responseError'))
      return
    end
       
    if (event.eventType().toString == java.lang.String('RESPONSE')) 
      done = true;
    end
  end
end