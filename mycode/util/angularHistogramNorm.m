%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function angularHist = angularHistogram(angles, nbBins)
% 
% Input parameters:
%
% Output parameters:
%   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [angularHist, histInd, binCenters, binEdges] = angularHistogramNorm(angles, nbBins, weights)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% quantize
binEdges = linspace(-pi, pi, 2*nbBins+1); binEdges(end) = binEdges(end)+2*eps;

if exist('weights', 'var')
    [h, binInd] = whistc(angles, weights, binEdges);
else
    [h, binInd] = histc(angles, binEdges);
end

% concatenate first and last together
binsIndCat = 1:2*nbBins;
binsIndCat = cat(1, binsIndCat, circshift(binsIndCat, [0 -1]));
binsIndCat = binsIndCat(:,2:2:end);
% put the last one first (by convention, start at the back)
binsIndCat = [binsIndCat(:,end) binsIndCat(:,1:end-1)];

angularHist = zeros(1, nbBins);
for b=1:nbBins
    angularHist(b) = sum((binInd==binsIndCat(1,b) | binInd==binsIndCat(2,b)));
end

% also return the index of each instance
[tf, i] = ismember(binInd, binsIndCat);
[r, histInd] = ind2sub(size(binsIndCat), i);

% save the centers and edges
binCenters = binEdges(2:2:end);
binEdges = binEdges(1:2:end);
