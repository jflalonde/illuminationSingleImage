%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [shadowFeatures, shadowClusters, clusterInd, shadowAbsFeatures] = computeShadowFeatures(img, sceneMask, potShadowLines)%  Retrieves (hopefully) shadow lines from an image.
%  Computes the shadow features for each detected shadow line
% 
% Input parameters:
%  - img: input image
%
% Output parameters:
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [shadowFeatures, shadowClusters, clusterInd, shadowAbsFeatures] = computeShadowFeatures(img, sceneMask, potShadowLines)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imgGray = rgb2gray(img);

r = 2;
deltaLines = cat(2, repmat(r.*cos(potShadowLines(:, 5)+pi/2), 1, 2), repmat(r.*sin(potShadowLines(:, 5)+pi/2), 1, 2));
newLinesRight = potShadowLines(:, 1:4) + deltaLines;
newLinesLeft = potShadowLines(:, 1:4) - deltaLines;

meanRightInt = medianLineIntensity(imgGray, newLinesRight, 'nearest');
meanLeftInt = medianLineIntensity(imgGray, newLinesLeft, 'neraest');

minInt = min([meanLeftInt meanRightInt], [], 2);
maxInt = max([meanLeftInt meanRightInt], [], 2);

shadowAbsFeatures = cat(2, minInt, maxInt);

% re-scale with respect to min/max of the scene indensities

prctileT = 3;
sceneMin = prctile(imgGray(sceneMask>0), prctileT);
sceneMax = prctile(imgGray(sceneMask>0), 100-prctileT);

minInt = (minInt-sceneMin)./(sceneMax-sceneMin);
maxInt = (maxInt-sceneMin)./(sceneMax-sceneMin);

% cluster them in 3 groups: reflectance edges in shadow and light, and shadow edges
% oversegment a little bit for more robustness?
shadowFeatures = cat(2, minInt, maxInt);

if size(shadowFeatures,1) > 5
    [clusterInd, cx] = kmeans(shadowFeatures, 4, 'Replicates', 20);
else
    clusterInd = 1; cx = shadowFeatures;
end

% figure out which of them are shadows (simple threshold, but would be better to learn)
shadowClusters = cat(2, cx(:,1), cx(:,2)-cx(:,1));
