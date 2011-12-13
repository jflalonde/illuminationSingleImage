%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function visibilityFeatures = computeSunVisibilityFeatures(img, varargin)
%  Computes features which might indicate that the sun is visible on the
%  ground or not.
% 
% Input parameters:
%
% Output parameters:
%   
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function visibilityFeatures = computeSunVisibilityFeatures(img, varargin)     

defaultArgs = struct('GeometricContextArea', 0, 'GroundMask', [], 'WallsMask', [], 'SkyMask', [], ...
    'MeanSkyColor', 0, ...%'SkyMask', [], ...
    'MeanGroundIntensity', 0, ...%'GroundMask', [], ...
    'MaxGroundCluster', 0, 'GroundProb', [], ...
    'MaxWallsCluster', 0, 'WallRight', [], 'WallLeft', [], 'WallFacing', [], ...
    'SceneContrast', 0, ...%'WallsMask', [], GroundMask, []
    'GroundShadows', 0, 'NewImgSize', [], 'ShadowBoundaries', [], ...%GroundProb, []
    'SkyCategory', 0, 'SkyProbMask', [], 'SkyDbFeatures', [], 'SkyDbLabels', [], ...
    'LogHistogram', 0, ... %GroundProb, []
    'SVHistogram', 0 ... %GroundProb, []
    );
args = parseargs(defaultArgs, varargin{:});
        
visibilityFeatures = [];

%% Percentage of image occupied by each class
if args.GeometricContextArea
    nbPixels = size(img,1)*size(img,2);
    visibilityFeatures.GeometricContextArea = cat(2, ...
        nnz(args.GroundMask)./nbPixels, ...
        nnz(args.WallsMask)./nbPixels, ...
        nnz(args.SkyMask)./nbPixels);
    
else
    visibilityFeatures.GeometricContextArea = [];
end

%% Mean sky color
if args.MeanSkyColor
    % make sure we do see the sky
    if nnz(args.SkyMask)
        imgVec = reshape(img, size(img,1)*size(img,2), 3);
        visibilityFeatures.MeanSkyColor = mean(imgVec(args.SkyMask,:), 1);
    else
        visibilityFeatures.MeanSkyColor = [NaN NaN NaN];
    end
else
    visibilityFeatures.MeanSkyColor = [];
end

%% Mean ground intensity
if args.MeanGroundIntensity
    % make sure we do see the ground
    if nnz(args.GroundMask)
        imgGray = rgb2gray(img);
        imgVec = reshape(imgGray, size(img,1)*size(img,2), 1);
        visibilityFeatures.MeanGroundIntensity = mean(imgVec(args.GroundMask));
    else
        visibilityFeatures.MeanGroundIntensity = NaN;
    end
else
    visibilityFeatures.MeanGroundIntensity = [];
end

%% Brightest of two ground clusters
% -> if sun is visible, there might be shadow regions which might bring down the mean intensity
if args.MaxGroundCluster
    % make sure we do see the ground
    imgGray = rgb2gray(img);
    imgVec = reshape(imgGray, size(img,1)*size(img,2), 1);
    
    % cluster and compute means
    meanIntensities = clusterAndMeanPixels(imgVec(args.GroundProb>0), args.GroundProb(args.GroundProb>0), 2);
    visibilityFeatures.MaxGroundCluster = sort(meanIntensities);
else
    visibilityFeatures.MaxGroundCluster = [];
end

%% Walls clusters
% -> if sun is visible, there might be shadow regions which might bring down the mean intensity
if args.MaxWallsCluster
    imgGray = rgb2gray(img);
    imgVec = reshape(imgGray, size(img,1)*size(img,2), 1);

    % cluster each wall to find max intensity
    meanRight = clusterAndMeanPixels(imgVec(args.WallRight>0), args.WallRight(args.WallRight>0), 2);
    meanLeft = clusterAndMeanPixels(imgVec(args.WallLeft>0), args.WallLeft(args.WallLeft>0), 2);
    meanFacing = clusterAndMeanPixels(imgVec(args.WallFacing>0), args.WallFacing(args.WallFacing>0), 2);
    
    % sort results
    visibilityFeatures.MaxWallsCluster = sort(cat(2, meanRight, meanLeft, meanFacing));
else
    visibilityFeatures.MaxWallsCluster = [];
end

%% Contrast in the ground and walls
if args.SceneContrast
    imgVec = reshape(img, size(img,1)*size(img,2), size(img,3));
    
    if nnz(args.GroundMask) > 10
        [groundAcm, groundKe] = computeContrastMeasures(hist(imgVec(args.GroundMask,:), linspace(0,1,256)));
    else
        groundAcm = NaN; groundKe = NaN;
    end
    if nnz(args.WallsMask) > 10
        [wallsAcm, wallsKe] = computeContrastMeasures(hist(imgVec(args.WallsMask,:), linspace(0,1,256)));
    else
        wallsAcm = NaN; wallsKe = NaN;
    end
    
    visibilityFeatures.SceneContrast = [groundAcm, groundKe, wallsAcm, wallsKe];
else
    visibilityFeatures.SceneContrast = [];
end

%% Shadows on the ground
if args.GroundShadows
    if ~isempty(args.NewImgSize)
        groundProb = max(min(imresize(args.GroundProb, args.NewImgSize), 1), 0);
    else
        groundProb = args.GroundProb;
    end
    
    % count number of pixels that are shadows
    nbShadowPixels = sum(cellfun(@(x) size(x,1), args.ShadowBoundaries));
        
    % normalize by *ground* size!
    gndSize = sum(groundProb(:))./numel(groundProb);
    
    if ~isempty(args.ShadowBoundaries)
        % clear out shadows that are not ground
        shadowBoundaryGroundProb = interpBoundarySubPixel(args.ShadowBoundaries, groundProb);
        nbShadowPixelsNorm = sum(cellfun(@(x) size(x,1), args.ShadowBoundaries(shadowBoundaryGroundProb>0.3)));
    else
        nbShadowPixelsNorm = 0;
    end
    
    visibilityFeatures.GroundShadows = [nbShadowPixels nbShadowPixels/gndSize nbShadowPixelsNorm nbShadowPixelsNorm/gndSize];
    
else
    visibilityFeatures.GroundShadows = [];
end

%% Sky category
if args.SkyCategory
    % classify the input sky based on the sky database
    minNbSkyPixels = 0.02*size(img,1)*size(img,2);
    
    if nnz(args.SkyProbMask>0) > minNbSkyPixels
        skyLabel = classifySky(img, args.SkyProbMask, args.SkyDbFeatures, args.SkyDbLabels, 'NbNeighbors', 5);
        visibilityFeatures.SkyCategory = skyLabel;
    else
        visibilityFeatures.SkyCategory = NaN;
    end
    
else
    visibilityFeatures.SkyCategory = [];
end

%% Log-RGB histogram of the ground
if args.LogHistogram
    % convert image to normalized log-RGB colorspace
    imgGray = rgb2gray(img);
    imgVec = reshape(imgGray, size(img,1)*size(img,2), 1);
    % make sure there's no 0's or values greater than 1
    imgVec(imgVec<1/256) = 1/256;
    imgVec(imgVec>1) = 1;

    % normalized-log (as in Dale et al. ICCV'09)
    imgVecLogNorm = log2(imgVec);
    meanImgLog = mean(imgVecLogNorm, 1);
    imgVecLogNorm = imgVecLogNorm - repmat(meanImgLog, size(imgVec, 1), 1);
    imgVecLogNorm = imgVecLogNorm ./ repmat(var(imgVecLogNorm, 1), size(imgVec, 1), 1);
    
    % histogram with log-uniform bins, centered at the mean (to avoid global exposure factor)
    nbBins = 6; minEdge = -8; maxEdge = 0;
    histEdges = log2(linspace(2^minEdge, 2^maxEdge, nbBins+1)) - meanImgLog;
    logNormHist = whistnd(imgVecLogNorm, args.GroundProb(:), histEdges);
    logNormHist = logNormHist(1:end-1)./sum(logNormHist(1:end-1));
    
    % last entry is linear combination of the others: drop it
    visibilityFeatures.LogHistogram = logNormHist(1:end-1)';
else
    visibilityFeatures.LogHistogram = [];
end

%% Saturation-value histogram of the ground
if args.SVHistogram
    % convert image to HSV colorspace
    imgHsv = rgb2hsv(img);
    imgVec = reshape(imgHsv, size(img,1)*size(img,2), size(img,3));

    % compute histograms
    nbBins = 4;
    histEdges = linspace(0,1,nbBins+1); 
    sHisto = whistnd(imgVec(:,2), args.GroundProb(:), histEdges); sHisto = sHisto(1:end-1) ./ sum(sHisto(1:end-1)); 
    vHisto = whistnd(imgVec(:,3), args.GroundProb(:), histEdges); vHisto = vHisto(1:end-1) ./ sum(vHisto(1:end-1));

    % last entry is linear combination of the others: drop it
    visibilityFeatures.SVHistogram = cat(2, sHisto(1:end-1)', vHisto(1:end-1)');
    
else
    visibilityFeatures.SVHistogram = [];
end

%% Useful function: compute contrast measures
function [acm, ke] = computeContrastMeasures(imHisto)

imHistoCombined = sum(imHisto, 2);
imHisto = imHistoCombined'./sum(imHistoCombined(:));
xHisto = linspace(1/(2*256),1-1/(2*256),256);

% ACM
meanVal = sum(imHisto.*xHisto);
acm = sum(abs(xHisto-meanVal).*imHisto);

% Ke's measure
imHistoCumul = cumsum(imHisto);
ke = (find(imHistoCumul>=0.99, 1, 'first')+1) - (find(imHistoCumul<=0.01, 1, 'last')-1);
if isempty(ke)
    ke = find(imHistoCumul>=0.99, 1, 'first')+1;
end

%% Computes mean value of clusters found in the image region
function [meanVal, clusterInd] = clusterAndMeanPixels(imgVec, weightVec, k)

if length(imgVec) < k
    meanVal = repmat(NaN, 1, k);
    return;
end

% k-means the ground with k=2 (allow random restarts)
opts.nTrial = 2;
clusterInd = kmeans2(imgVec, k, opts);
 
meanVal = zeros(k, size(imgVec, 2));
for i=1:k
%     meanVal(i,:) = mean(imgVec(clusterInd==i,:), 1);
    meanVal(i,:) = sum(imgVec(clusterInd==i,:).*weightVec(clusterInd==i))./sum(weightVec(clusterInd==i));
end
meanVal = meanVal';
