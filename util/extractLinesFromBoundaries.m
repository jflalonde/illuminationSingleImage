%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function lines = extractLinesFromBoundaries(img, boundaries)
%  Extract long lines from a set of boundaries.
% 
% Input parameters:
%
% Output parameters:
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lines = extractLinesFromBoundaries(img, boundaries)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% convert boundaries to edge map
shadowImg = zeros(size(img,1), size(img,2));
boundariesPxInd = convertBoundariesToPxInd(boundaries, size(img));
shadowImg(boundariesPxInd) = 1;

[dX, dY] = gradient(conv2(shadowImg, fspecial('gaussian', 7, 1.5), 'same'));
lines = APPgetLargeConnectedEdgesNew([], 0.01*sqrt(size(img,1).^2+size(img,2).^2), dX, dY, shadowImg, 100);

%% display
%   figure(1), hold off, imshow(shadowImg)
%   figure(1), hold on, plot(lines(:, [1 2])', lines(:, [3 4])', 'LineWidth', 3)
