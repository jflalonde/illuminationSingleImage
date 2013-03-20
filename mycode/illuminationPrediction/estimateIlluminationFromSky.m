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
    ~, focalLength, horizonLine, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parse arguments
defaultArgs = struct('DoSkyClassif', 0, 'SkyDb', [], 'UseIJCVVersion', 0);
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
    
    if any(meanSkyColor > 254/255)
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
            fprintf('Sky is clear...');
            skyLabel = 'clear';
            
        case 2
            % patchy clouds. Segment first
            fprintf('Sky is patchy...');
            skyLabel = 'patchy';
            skySeg = imageBasedCloudSegmentation(img, skyMask);
            skyMask = skyMask.*skySeg;
            
        case 3 % can't be overcast!
            % overcast. Can't fit our model
            fprintf('Sky is overcast...');
            skyLabel = 'overcast';
            illProb = skyPredictor.constantProb();
            return;
    end
end

%% Extract pixel information

skyArea = nnz(skyMask(:))./numel(skyMask(:));

% use gamma = 2.2
% gamma = 2.2;
% img = img.^(1/gamma);
% invRespFunction = repmat(linspace(0,1,1000)', 1, 3).^gamma;
% img = correctImage(img, invRespFunction, logical(skyMask));

% extract up, vp, lp for all pixels above the horizon line
imgxyY = rgb2xyY(img);
[up, vp, lp] = getFullSkyInfo(skyMask, imgxyY, img);

%% Compute probability of the sun given the sky
if args.UseIJCVVersion
    % IJCV version
    
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
    
else
    % ICCV'09 version
    skyWeight = skyMask .* skyProb;
    [~, ~, wp] = getFullSkyInfo(skyMask, skyWeight, img);
    
    thetaSuns = repmat(skyPredictor.sunZeniths', 1, length(skyPredictor.sunAzimuths));
    phiSuns = repmat(skyPredictor.sunAzimuths, length(skyPredictor.sunZeniths), 1);
    
    % speed things up a bit: randomly select 10,000 of them
    randInd = randperm(length(up));
    nbToKeep = min(10000, length(randInd));
    up = up(randInd(1:nbToKeep));
    vp = vp(randInd(1:nbToKeep));
    lp = lp(randInd(1:nbToKeep),:);
    wp = wp(randInd(1:nbToKeep));
    
    % Compute the probability for scale factors, assuming independence between color channels
    fprintf('using the ICCV''09 algorithm...'); 
    kNbBins = 55;
    kRange = linspace(0.01, 0.4, kNbBins); % compress range of k to most likely values
    % kRange = 0:0.01:0.5;
    kRangeRep = repmat(kRange, [size(up) 3]);
    lpRep = repmat(permute(lp, [1 3 2]), size(kRange));
    wpRep = repmat(wp, [size(kRange), 3]);
    sumWp = sum(wpRep);
    resnormMap = NaN.*ones(size(thetaSuns, 1), size(thetaSuns, 2), 3, length(kRange));
    
    upRep = repmat(up, 1, 3);
    vpRep = repmat(vp, 1, 3);
    
    % assume we're indeed fitting on clear sky
    t = 2.17;
    a = zeros(size(lp)); b = zeros(size(lp)); c = zeros(size(lp)); d = zeros(size(lp)); e = zeros(size(lp));
    for j=1:3
        coeff = getTurbidityMapping(j)*[t 1]';
        a(:,j) = coeff(1); b(:,j) = coeff(2); c(:,j) = coeff(3); d(:,j) = coeff(4); e(:,j) = coeff(5);
    end
    
    for i=1:numel(phiSuns)
        [row,col] = ind2sub(size(phiSuns), i);
        
        lpp = permute(exactSkyModelRatio(a, b, c, d, e, focalLength, upRep, vpRep, vh, 1, 0, phiSuns(i), thetaSuns(i)), [1 3 2]);
        resnormMap(row, col, :, :) = permute(sum((lpRep - kRangeRep.*repmat(lpp, [1 kNbBins 1])).^2.*wpRep, 1)./sumWp, [4 1 3 2]);
    end
    
    % Convert to probabilities
    sigma = 0.1;
    illProb = resnormToProbability(resnormMap, sigma);
    
    
end
illProb = illProb./sum(illProb(:));

    % In-line helper -- convert residual norm to "probabilities"
    function probMap = resnormToProbability(resnormMap, sigma)
        
        probMap = exp(-resnormMap./(2*sigma^2));
        probMap(isnan(resnormMap)) = 0;
        
        probMap = exp(sum(log(prctile(cat(3, probMap(:,:,3,:), prod(probMap(:,:,1:2,:), 3)), 98, 4)), 3));
        
        probMap = probMap./sum(probMap(:));
    end

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

end
