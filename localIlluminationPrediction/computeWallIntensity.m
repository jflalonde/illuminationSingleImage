%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function trainWallsIlluminationPredictor
%  Trains P(sun | vertical surface, vertical surface max. intensity).
% 
% Input parameters:
%
% Output parameters:
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function wallInt = computeWallIntensity(imgInt, wallMask)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imgVec = reshape(imgInt, size(imgInt,1)*size(imgInt,2), 1);

% cluster into 2 groups: shadow and non-shadow
wallPixels = imgVec(wallMask>0);
[clusterInd, clusterCenter] = kmeans(wallPixels, 2, 'Replicates', 10);

% compute the weighted mean intensity on the brightest cluster
[m, mind] = max(clusterCenter);
wallInt = mean(wallPixels(clusterInd==mind));
% wallInt = sum(wallPixels(clusterInd==mind).*wallWeight(indWall(clusterInd == mind)))./sum(wallWeight(indWall(clusterInd == mind)));
