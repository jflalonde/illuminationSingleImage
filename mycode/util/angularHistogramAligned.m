%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function angularHist = angularHistogram(angles, nbBins)
% 
% Input parameters:
%
% Output parameters:
%   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [angularHist, histInd, binCenters, binEdges] = angularHistogramAligned(angles, nbBins)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% quantize
binEdges = linspace(-pi, pi, nbBins+1); binEdges(end) = binEdges(end)+2*eps;
[h, histInd] = histc(angles, binEdges);

angularHist = h(1:end-1);

% save the centers
binCenters = linspace(-pi, pi, 2*nbBins+1);
binCenters = binCenters(2:2:end-1);
