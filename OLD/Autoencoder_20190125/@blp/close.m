function close(c) 
%CLOSE Close connection to Bloomberg V3.
%   CLOSE(C) closes the connection, C, to the Bloomberg.
%
%   See also BLP.

%   Copyright 1999-2009 The MathWorks, Inc.
if ~isempty(c.session)
    c.session.stop;
end