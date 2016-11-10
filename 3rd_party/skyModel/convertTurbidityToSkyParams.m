%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function skyParams = convertTurbidityToSkyParams(turbidity, k)
%  Converts turbidity to sky parameters. Also appends
%  the scale factors at the end, if given. 
% 
% Input parameters:
%  - turbidity
%  - [k]: scale factors for each channels
%
% Output parameters:
%  - skyParams: parameters (a,b,c,d,e), 6x3 (if k specified), 5x3 otherwise
%   
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function skyParams = convertTurbidityToSkyParams(turbidity, k)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin > 1, nbParams = 6; else nbParams = 5; end

skyParams = zeros(nbParams, 3);
for ch=1:3
    skyParams(1:5,ch) = getTurbidityMapping(ch)*[turbidity 1]';
end

if nargin > 1
    skyParams(6,:) = k(:)';
end