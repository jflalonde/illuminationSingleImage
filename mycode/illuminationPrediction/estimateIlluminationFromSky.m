%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function estimateIllumination
%  
% 
% Input parameters:
%
% Output parameters:
%   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [illProb, skyLabel, skyArea] = estimateIlluminationFromSky(img, skyPredictor, skyProb, ...
    imgSuperpixels, focalLength, horizonLine, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parse arguments
defaultArgs = struct('DoSkyClassif', 0, 'SkyDb', []);
args = parseargs(defaultArgs, varargin{:});

%% Initialize
vh = size(img,1)/2 - horizonLine;

% for now: only keep superpixels with probability greater than 0.5
skyMask = (skyProb >= 0.5);
skyMask(floor(horizonLine):end,:) = 0;

skyArea = nnz(skyMask(:))./numel(skyMask(:));

% minimum number of visible sky pixels: 5% of image
minNbSkyPixels = 0.05*size(img,1)*size(img,2);
if nnz(skyMask) < minNbSkyPixels
    illProb = skyPredictor.constantProb();
    skyLabel = 'nosky';
    return;
end

%% We want to first classify and segment the sky
if args.DoSkyClassif
    % First, check if sky is completely saturated
    imgVec = reshape(img, size(img,1)*size(img,2), 3);
    meanSkyColor = mean(imgVec(skyMask, :), 1);
    
    if all(meanSkyColor > 250)
        fprintf('Sky is saturated!\n');
        skyLabel = 'saturated';
        
        % constant probability, normalized for zenith, sums to 1
        illProb = skyPredictor.constantProb();
        return;
    end
    
    % Determine which type of sky we're dealing with
    skyFeatures = computeSkyFeaturesHsv(img, skyMask);
    
    skyDist = chisqVec(skyFeatures(:), args.SkyDb.skyFeatures);
    [s,sind] = sort(skyDist);
    
    kSky = 5;
    skyVotes = [];
    while sum(skyVotes==max(skyVotes)) ~= 1
        skyVotes = histc(args.SkyDb.skyLabels(sind(1:kSky)), 1:length(unique(args.SkyDb.skyLabels)));
        kSky = kSky+1;
    end
    [m,skyLabel] = max(skyVotes);
    
    switch skyLabel
        case 1
            % sky is clear, fit on entire sky
            fprintf('Sky is clear...\n');
            skyLabel = 'clear';
            
        case 2
            % patchy clouds. Segment first
            fprintf('Sky is patchy...\n');
            skyLabel = 'patchy';
            skySeg = imageBasedCloudSegmentation(img, skyMask);
            skyMask = skyMask.*skySeg;
            
        case 3 % can't be overcast!
            % overcast. Can't fit our model
            fprintf('Sky is overcast...\n');
            skyLabel = 'overcast';
            illProb = skyPredictor.constantProb();
            return;
    end
end

%% Extract pixel information

skyArea = nnz(skyMask(:))./numel(skyMask(:));

% use gamma = 2.2
gamma = 2.2;
img = img.^(1/gamma);
% invRespFunction = repmat(linspace(0,1,1000)', 1, 3).^gamma;
% img = correctImage(img, invRespFunction, logical(skyMask));

% extract up, vp, lp for all pixels above the horizon line
imgxyY = rgb2xyY(img);
[up, vp, lp] = getFullSkyInfo(skyMask, imgxyY, img);

%% Optimize luminance over entire sky
kOpt = [];
for i=3
    % the two chrominance channels are very similar, no need to optimize
    % for them independently
    kOpt = cat(3, kOpt, skyPredictor.optimizeLuminance(up, vp, lp(:,[1 1 i]), vh, focalLength, i));
end
kOpt = kOpt(:,:,[1 1 1]);

% illProb = skyPredictor.probIlluminationGivenObjectAndK(up, vp, lp, kOpt, vh, focalLength);
illProb = skyPredictor.probIlluminationGivenObjectAndKColor(up, vp, lp, kOpt, vh, focalLength);
illProb = illProb./sum(illProb(:));

return;


% keep only sky superpixels
imgSuperpixels(~skyMask) = 0;
spInd = unique(imgSuperpixels); spInd(spInd==0) = [];

%% Loop over superpixels
skySunProb = [];
% get probability for each sky superpixel
for i=spInd(:)'
    % find out which pixels belong to the current superpixel
    curSpPxInd = find(imgSuperpixels==i);
    tf = ismember(ind, curSpPxInd);
    
%     skySunProb = cat(3, skySunProb, skyPredictor.probIlluminationGivenObject(up(tf), vp(tf), lp(tf,3), vh, focalLength));
    skySunProb = skyPredictor.probIlluminationGivenObjectAndK(up(tf), vp(tf), lp(tf,3), kOpt, vh, focalLength);
end
skySunProb = prod(skySunProb, 3);
skySunProb = skySunProb./sum(skySunProb(:));


