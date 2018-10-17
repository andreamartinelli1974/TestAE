function v = get(c,p)
%GET    Get Bloomberg V3 connection properties.
%   V = GET(C,'PropertyName') returns the value of the specified 
%   properties for the Bloomberg V3 connection object.  'PropertyName' is
%   a string or cell array of strings containing property names.
%
%   V = GET(C) returns a structure where each field name is the name
%   of a property of C and each field contains the value of that 
%   property.
%
%   The property names are:
%
%   session
%   ipaddress
%   port   
%
%   See also BLP.

%   Copyright 1999-2009 The MathWorks, Inc.

%Build properties if none are given   
prps = {'session';...
    'ipaddress';...
    'port';...
  };

%Check input properties for invalid entries
if nargin == 1
  
  p = prps;     %Use default property list
  x = (1:3);    %Default index scheme
  
else
  
  if ischar(p) || isstring(p)  %Convert string input to cell array
    p = cellstr(p);
  end
  
  x = zeros(length(p),1);
  for i = 1:length(p)  %Validate each given property
    try
      x(i) = find(strcmpi(p(i),prps));
    catch exception
      error(message('datafeed:blpGet:invalidProperty', class( c ), p{ i }))
    end
  end

  p = prps(x);
  
end

%Make appropriate bb_ api calls to get properties, 3 is get flag, x(i) is property flag.
for i = 1:length(x)
  v.(p{i}) = c.(p{i});
end

if length(x) == 1
  v = v.(p{1});
end