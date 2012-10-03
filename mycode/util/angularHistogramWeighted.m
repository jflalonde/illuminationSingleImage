%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [angularHist, histInd, binCenters, binEdges] = angularHistogram(angles, nbBins, align)
%  Compute the histogram in angular space (wraps at pi=-pi) 
%
% Input parameters:
%
% Output parameters:
%   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [angularHist, histInd, binCenters, binEdges] = angularHistogramWeighted(angles, weights, nbBins, align)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 3
    align = 0;
end

if align
    [angularHist, histInd, binCenters, binEdges] = angularHistogramAligned(angles, nbBins, weights);
else
    [angularHist, histInd, binCenters, binEdges] = angularHistogramNorm(angles, nbBins, weights);
end
