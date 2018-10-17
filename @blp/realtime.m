function [subscriptions,t] = realtime(b,s,f,cb)
%REALTIME Bloomberg V3 realtime data retrieval.
%   [SUBS,T] = REALTIME(C,S,F,API) subscribes to a given security or list of
%   securities S requesting the fields F and runs the specified function by 
%   API.  SUBS is the subscription list and T is the timer associated with 
%   the real time callback for the subscription list. See the function 
%   V3SHOWTRADES for information on the data returned by asynchronous Bloomberg 
%   events.
%
%   Example:
%
%   [SUBS,T] = REALTIME(C,'ABC US Equity',{'Last_Trade','Volume'},'v3stockticker')
%   subscribes to the security ABC US Equity requesting the fields Last_Trade
%   and Volume to update in realtime running the function STOCKTICKER. 
%
%   See also BLP, HISTORY, GETDATA, STOP, TIMESERIES, V3STOCKTICKER, V3SHOWTRADES, V3PRICEVOL.

%   Copyright 1999-2016 The MathWorks, Inc.

%Imports
import com.bloomberglp.blpapi.*;

%Validate security list.  Security list should be cell array string
if ischar(s) || isstring(s)
  s = cellstr(s);
end
if ~iscell(s) || ~ischar(s{1})
  error(message('datafeed:blpRealTime:securityInputError'))
end

%Convert field list to cell array
if ischar(f) || isstring(f)   
  f = cellstr(f);
end
if ~iscell(f) || ~ischar(f{1})
  error(message('datafeed:blpRealTime:fieldInputError'))
end

%find reference data to start service
if ~b.session.openService('//blp/mktdata')
  b.session.stop
  error(message('datafeed:blpRealTime:openServiceError'));
end

%create subscription object
subscriptions = SubscriptionList;
  
%create fields string
fldlst = [];
for i = 1:length(f)
  fldlst = [fldlst upper(f{i}) ','];   %#ok
end
fldlst(end) = [];

%add fields and securities to subscription object
for i = 1:length(s)
  subscriptions.add(Subscription(s{i},fldlst,'',CorrelationID(s{i})));
end

%subscribe
if isprop(b,'user')
  b.authorize;
  b.session.subscribe(subscriptions,b.user);
else
  b.session.subscribe(subscriptions);
end

%If callback given, "listen" for data, otherwise get current values

if nargin == 4
  
  %create object to process realtime events
  t = timer('TimerFcn',{@processevents,b,upper(f),cb},'Period',.05,'ExecutionMode','fixedRate');
  start(t)

else
  
  subscriptions = snapshot(b,upper(f),subscriptions);
  t = [];
  
end


function processevents(obj,event,b,f,cb)   %#ok
%PROCESSEVENTS

try
  
  %set loop flag
  iter = true;
  
  %process events
  while iter 
    
    %listen for event
    event = b.session.nextEvent(10);
    eventStr = char(event.eventType);
    if strcmp(eventStr,'TIMEOUT')
      iter = false;
    end
    msgIter = event.messageIterator;
    
    while (msgIter.hasNext) 
    
      %get event
      msg = msgIter.next;
      b.entitlements(msg);
      
      %handle event
      switch eventStr
        
        case 'SUBSCRIPTION_STATUS'
          imp = msg.asElement;
          if imp.hasElement('reason')
            if imp.hasElement('failureDetails') && ~isempty(char(imp.getElement('failureDetails')))
              error(message('datafeed:blpRealTime:subscriptionError',char(imp.getElement('failureDetails'))))
            else
              % warning(char(imp.getElement('reason')))
            end
          end
          
        case 'SUBSCRIPTION_DATA'
          topic = char(msg.correlationID.object);
          d = [];
          for j = 1:length(f)
            try
              d.(f{j}) = char(msg.getElementAsString(f{j}));
            catch 
              % field not found in event
            end
          end

          %run callback
          feval(cb,d,topic)

        otherwise
         
          %place holder for additional event type
        
      end
      
    end
    
  end

catch 
  disp(char(msg))
end


function d = snapshot(b,f,s)

d = [];

try
  
  %set loop flag
  iter = true;
  
  %process events
  while iter 
    
    %listen for event
    event = b.session.nextEvent(10);
    msgIter = event.messageIterator;
    
    while (msgIter.hasNext) 
    
      %get event
      msg = msgIter.next;
      b.entitlements(msg);
      eventStr = char(event.eventType);
      
      %handle event
      switch eventStr
        
        case 'SUBSCRIPTION_STATUS'
          imp = msg.asElement;
          if imp.hasElement('reason')
            if imp.hasElement('failureDetails') && ~isempty(char(imp.getElement('failureDetails')))
              error(message('datafeed:blpRealTime:subscriptionError',char(imp.getElement('failureDetails'))))
            else
              %warning(char(imp.getElement('reason')))
              iter = false;
            end
          end
          
        case 'SUBSCRIPTION_DATA'
          d = [];
          for j = 1:length(f)
            try
              d.(f{j}) = char(msg.getElementAsString(f{j}));
            catch 
              % field not found in event
            end
          end

          b.session.unsubscribe(s)
          
        otherwise
         
          %place holder for additional event type
        
      end
      
    end
    
    %done, break event handling loop
    
  
  end
  
catch
  disp(char(msg))
end
