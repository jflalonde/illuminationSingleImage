%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function sOpt = optimizeSigma(k, nbBins, alignHistogram, edge)
%  Retrieves the sigma which makes an angular gaussian have k probability
%  between the edges. 
% 
% Input parameters:
%
% Output parameters:
%   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sOpt = optimizeSigma(k, nbBins, alignHistogram, edge)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 4
    edge = pi/2;
end

% initial value for sigma
s0 = 1;
[h,i,c] = angularHistogram([], nbBins, alignHistogram);

% optimize for sigma
sOpt = fminsearch(@(s) gaussianAreaError(s), s0, []);

    function err = gaussianAreaError(sigma)
        
        g = angularGaussian(0, sigma, nbBins, alignHistogram);
        a = sum(g(c >= -edge & c <= edge));
        
        % minimize sum of squares
        err = (a - k)^2;
    end
end