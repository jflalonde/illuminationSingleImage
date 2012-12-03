%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function imageBasedCloudSegmentation(img, skyMask)
%  Segments the sky into 2 layers, based on the color only (purely
%  image-based). This function basically assumes blue sky with white clouds.
% 
% Input parameters: 
%  - img: input image
%  - skyMask: sky mask (1=sky, 0=no sky)
%
% Output parameters:
%  - skySeg: 1=definitely sky, 0 = definitely cloud
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function skySeg = imageBasedCloudSegmentation(img, skyMask)    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parameters

% minimum distance to merge clusters
minInterClusterDist = 0.05; 

% minimum distance to blue to be considered clear
minClearDist = 1.2;

%% Compute color distances
blueLab = squeeze((permute([0 0 1], [3 1 2])))';

% This assumes blue sky with white clouds
imgVec = reshape(img, size(img,1)*size(img,2), size(img,3));
skyPixels = imgVec(skyMask, :);

% bluePxDist = sqrt(sum((repmat(blueLab, size(skyPixels, 1), 1) - skyPixels).^2, 2));

%% Try to find 2 clusters
[id,cx] = kmeans(skyPixels, 2); cx = cx';

%% Merge if cluster centers are too close
clusterDist = sqrt(sum((cx(:,1)-cx(:,2)).^2));

if clusterDist < minInterClusterDist
    % unimodal distribution: all clear or all overcast
    clusterCenter = mean(cx, 2);
    blueDist = sqrt(sum((clusterCenter - blueLab').^2, 1));
    
    if blueDist <= minClearDist
        % clear sky
        skySeg = double(skyMask);
        fprintf('Clear sky after all...');
    else
        % overcast
        skySeg = zeros(size(skyMask));
    end
    
else
    % bimodal distribution: patchy clouds
    % figure out which one is closest to "blue"
    dist = sqrt(sum((cx - repmat(blueLab', 1, 2)).^2, 1));
    [minDist, mind] = min(dist);
    
    % make sure it's close enough
    if minDist <= minClearDist
        % patchy clouds
        indBlueCluster = sum((repmat(cx(:,mind), 1, size(skyPixels,1))-skyPixels').^2, 1) < ...
            sum((repmat(cx(:,mod(mind,2)+1), 1, size(skyPixels, 1))-skyPixels').^2, 1);
        
        indSky = find(skyMask);
        skySeg = double(skyMask);
        skySeg(indSky(~indBlueCluster)) = 0;
    
    else 
        % overcast
        skySeg = zeros(size(skyMask));
    end
end
