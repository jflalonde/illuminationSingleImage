%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function findShadowLines(img, varargin)
%  Retrieves (hopefully) shadow lines from an image.
%  
% 
% Input parameters:
%  - img: input image
%  - varargin: optional arguments
%    - 'Mask': select lines from that region of the image only (typically ground)
%    - 'SceneMask': mask segmenting the scene wrt the sky (1=scene, 0=non-scene)
%    - 'HorizonLine': y-coordinate of the horizon line
%    - 'FocalLength': focal length, in pixels
%    - 'DoLongLines': 0 or [1]: extract long lines, uses edgelets only otherwise
%    - 'DoDisplay': [0] or 1: display the results
%
% Output parameters:
%  - shadowLines: detected shadow lines
%  - lineAngles3D: angle of each line in 3-D
%  - lineLengths3D: length of each line in 3-D
%  - potShadowLines: 
%  - shadowFeatures: 
%  - clusterInd: 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [shadowLines, lineAngles3D, lineLengths3D, potShadowLines, shadowFeatures, clusterInd] = findShadowLines(img, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parse arguments
mask = ones(size(img,1), size(img,2));
focalLength = size(img,2)*10/7; % Derek's approximation
horizonLine = size(img,1)/2;
cameraHeight = 1.6; % assume typical height

defaultArgs = struct('Mask', mask, 'SceneMask', mask, 'HorizonLine', horizonLine, 'CameraHeight', 0, ...
    'FocalLength', focalLength, 'DoLongLines', 1, 'DoDisplay', 0);
args = parseargs(defaultArgs, varargin{:});

% Default parameters
if ~args.CameraHeight
    args.CameraHeight = cameraHeight;
end

%% Find shadow lines
if args.DoLongLines
    % use the fact that CIELAB is more discriminative for shadows, as per Khan's paper    
    labImg = rgb2lab(img);
    
    % Find edges in discriminative channel (reflectance)
    [dXA, dYA] = gradient(conv2(labImg(:,:,2), fspecial('gaussian', 7, 1.5), 'same'));
    edgeMagA = sqrt(dXA.^2 + dYA.^2);
    edgeMagAn = edgeMagA./prctile(edgeMagA(:), 95);
    
    % Find edges in the non-discriminative channel (shadow)
    [dXL, dYL] = gradient(conv2(labImg(:,:,1), fspecial('gaussian', 7, 1.5), 'same'));
    edgeMagL = sqrt(dXL.^2 + dYL.^2);
    edgeMagLn = edgeMagL./prctile(edgeMagL(:), 95);
    
    indBad = edgeMagLn-edgeMagAn < 0;
    
    % normalize gradients (different scale factors for color channels?)
    dXLn = dXL./prctile(dXL(:), 98); dYLn = dYL./prctile(dYL(:), 98);
    dXAn = dXA./prctile(dXA(:), 98); dYAn = dYA./prctile(dYA(:), 98);
    
    dXDiff = dXLn-dXAn;
    dYDiff = dYLn-dYAn;
    
    dXDiff(indBad) = 0;
    dYDiff(indBad) = 0;
    
    edgePot = mycanny(dXDiff, dYDiff);
    
    % keep only large edges in luminance
    weakEdgesInd = edgeMagL(edgePot) < 1.5;
    edgePotInd = find(edgePot);
    edgePot(edgePotInd(weakEdgesInd)) = 0;
    
    lines = APPgetLargeConnectedEdgesNew([], 0.01*sqrt(size(img,1).^2+size(img,2).^2), dXDiff, dYDiff, edgePot);
%     lines = APPgetLargeConnectedEdgesNew(rgb2gray(img), 0.01*sqrt(size(img,1).^2+size(img,2).^2));
     
%% Find edgelets
else
    % detect edgelets only
    [dX, dY] = gradient(conv2(grayImg, fspecial('gaussian', 7, 1.5), 'same'));
    imgCanny = edge(grayImg, 'canny', 0.5);
    [r,c] = find(imgCanny);
    
    ind = sub2ind(size(imgCanny), r, c);
    theta = atan2(dY(ind), dX(ind)) - pi/2;
    
    lines = cat(2, c, c+cos(theta), r, r+sin(theta), theta, ones(size(r)));
end

%% Keep only lines which lie on the ground

lineGndPct = 0.5; % at least that % should lie on the ground to be considered
linesGroundWeight = meanLineIntensity(double(args.Mask>0), lines, 0);

linesShadowInd = linesGroundWeight >= lineGndPct;
potShadowLines = lines(linesShadowInd, :);

%% Compute mean color on both sides of the line
if size(potShadowLines,1)
    [shadowFeatures, shadowClusters, clusterInd] = computeShadowFeatures(img, args.SceneMask, potShadowLines);
    
    % keep 80% of them (from computed distribution on training images)
    % 80: 0.31, 0.18
    % 90: 0.38, 0.14
%     params = [0.2207 sqrt(0.0118); 0.2673 sqrt(0.0119)];
%     shadowLike = [normpdf(shadowClusters(:,1)', params(1,1), params(1,2)); normpdf(shadowClusters(:,2)', params(2,1), params(2,2))]';
%     shadowLike = exp(sum(log(shadowLike),2));
    
%     clusterIndShadow = find(shadowLike > 5);
%     [m,clusterIndShadow] = max(shadowLike);
%     shadowLike = [normlike(params(1,:), shadowFeatures(:,1)) normlike(params(2,:), shadowFeatures(:,2))];
%     clusterIndShadow = find(shadowClusters(:,1) < 0.31 & shadowClusters(:,2) > 0.15);
%     clusterIndShadow = find(shadowClusters(:,1) < 0.3 & shadowClusters(:,2) > 0.25 & shadowClusters(:,2) < 0.6);
    
    [s,sind]= sort(shadowClusters(:,2), 'descend');
    clusterIndShadow = sind(1:min(2, size(shadowFeatures, 1)));
%     [m,clusterIndShadow] = max(shadowClusters(:,2));

    shadowInd = false(size(clusterInd));
    for i=1:length(clusterIndShadow)
        shadowInd = shadowInd | clusterInd == clusterIndShadow(i);
    end
    
    shadowLines = potShadowLines(shadowInd, :);
else
    shadowLines = potShadowLines;
    shadowFeatures = [];
    clusterInd = [];
end

%% Compute angles
if nnz(linesShadowInd)
    [lineAngles3D, lineLengths3D] = computeAnglesFromShadowLines(shadowLines, args.FocalLength, args.CameraHeight, args.HorizonLine, size(img,2));
else
    shadowLines = [];
    lineAngles3D = [];
    lineLengths3D = [];
end

%% Display?
if args.DoDisplay
    figure(11), hold off, imshow(img); hold on; plot(shadowLines(:, [1 2])', shadowLines(:, [3 4])', 'LineWidth', 3, 'Color', 'b');
    plot([1, size(img,2)], [args.HorizonLine args.HorizonLine], '--r', 'LineWidth', 3);
end





