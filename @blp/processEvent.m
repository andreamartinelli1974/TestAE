function processEvent(b,~,~)
%PROCESSEVENT Sample Bloomberg event handler.
%   PROCESSEVENT(B) processes the event queue associated with 
%   Bloomberg connection handle, B. 

%   Copyright 2012 The MathWorks, Inc.

iter = true;

%process events and display messages
while iter
  evt = b.session.nextEvent(10);
  evtType = char(evt.eventType);
  %msgIter = evt.messageIterator;
  switch evtType
    case 'TIMEOUT'
      iter = false;
    otherwise
      %disp(char(msgIter.next));
  end
end

