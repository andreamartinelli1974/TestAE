function stop(b,subs,t,s)
%STOP Unsubscribe real time requests for Bloomberg V3.
%   STOP(B,SUBS,T) unsubscribes all real time requests associated with the 
%   Bloomberg connection, B, and subscription list, SUBS.   T is the timer
%   associated with the real time callback for the subscription list.
%
%   STOP(B,SUBS,[],S) unsubscribes real time requests for each security, S, 
%   on the subscription list, SUBS.   The timer input, T, is empty.
%
%   See also BLP, HISTORY, GETDATA, REALTIME, TIMESERIES, V3STOCKTICKER, V3SHOWTRADES, V3PRICEVOL.

%   Copyright 1999-2009 The MathWorks, Inc.

%Imports
import com.bloomberglp.blpapi.*;

%Stop timer
if ~isempty(t)
  stop(t)
end

%Unsubscribe from all securities if none explicitly given
if nargin < 4
  b.session.unsubscribe(subs)
  return
end

%Convert security list to cell array
if ischar(s) || isstring(s)   
  s = cellstr(s);
end
if ~iscell(s) || ~ischar(s{1})
  error(message('datafeed:blpapi3RealTime:securityInputError'))
end
  
%Unsubscribe from specified securities only
for i = 1:length(s)
  b.session.unsubscribe(CorrelationID(s{i}))
end