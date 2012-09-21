%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function interpBoundarySubPixel(boundaries, interpMap)
%  Retrieves image values at sub-pixel boundary locations using interpolation.
%
% Input parameters:
%  - boundaries: image boundaries
%  - interpMap: map of values to interpolate (e.g. ground probability)
%
% Output parameters:
%  - meanBndInterpVal: mean of interpolated values for each boundary
%  - bndInterpVal: interpolated values for each pixel of each boundary
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [meanBndInterpVal, bndInterpVal] = interpBoundarySubPixel(boundaries, interpMap)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Consult the LICENSE.txt file for licensing information
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute probability of ground at each boundary point
boundariesCat = max(cat(1, boundaries{:}), 1);
boundariesCatInterpVal = interp2(1:size(interpMap,2), 1:size(interpMap,1), ...
    double(interpMap), min(boundariesCat(:,1), size(interpMap,2)), min(boundariesCat(:,2), size(interpMap,1)));

% compute mean for each boundary line
boundariesLength = cellfun(@(x) length(x), boundaries);
boundariesCumsum = [0 cumsum(boundariesLength)];
boundariesLineInd = arrayfun(@(i) boundariesCumsum(i)+1:boundariesCumsum(i+1), 1:(length(boundariesCumsum)-1), 'UniformOutput', 0);

bndInterpVal = cellfun(@(x) boundariesCatInterpVal(x), boundariesLineInd, 'UniformOutput', 0);
meanBndInterpVal = cellfun(@(x) mean(x), bndInterpVal);
