%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function feats = computeLocalVisibilityFeatures(img, objBbox, varargin)
%  Computes features which should predict the local lighting at an object
%  (sun position and visibility)
% 
% Input parameters:
%  - img: input image
%  - objBbox: bounding box of object of interest
%
% Output parameters:
%   
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function feats = computeLocalVisibilityFeatures(img, objBbox, varargin)

defaultArgs = struct('GIST', 0, 'SmallImg', 0, 'HOG', 0, 'LABHistogram', 0, 'HSVHistogram', 0);
args = parseargs(defaultArgs, varargin{:});
        
feats = [];
[imgHeight, imgWidth, c] = size(img);

%% GIST descriptor
if args.GIST
    % GIST: tight bounding box, coarse split, low frequency content

    % parameters
    gistNbBlocks = 3;
    gistOrientationsPerScale = [2 2 2 2];
    gistObjSize = 128;
    
    % 
    objBboxExp = objBbox; %expandBbox(objBbox, -0.25, [imgHeight, imgWidth], 'ExpandHeight', 0);
    objImg = getObjImg(img, objBboxExp, [imgHeight imgWidth]);

    % resize to standard size
    objImg = imresize(objImg, [gistObjSize gistObjSize]);
    
    % get intensity channel only
    objImg = rgb2gray(objImg);
    
    % compute GIST descriptor
    G = createGabor(gistOrientationsPerScale, gistObjSize(1));
    
    % Computing gist requires 1) prefilter image, 2) filter image and collect output energies
%     output = prefilt_nocontrast(double(objImg).*255, 4); % -> do we really need that step?
    output = objImg;
    
    % compute GIST on original image (no pre-filter)
    feats.GIST = gistGabor(output, gistNbBlocks, G);
    
else
    feats.GIST = [];
end

%% Down-sampled image
if args.SmallImg
    % parameters
    smallImgNbBlocks = 5;
    smallImgSize = 128;
    
    % 
    objBboxExp = objBbox; %expandBbox(objBbox, -0.25, [imgHeight, imgWidth], 'ExpandHeight', 0);
    objImg = getObjImg(img, objBboxExp, [imgHeight imgWidth]);
    
    objImg = imresize(objImg, [smallImgSize smallImgSize]);
    objImg = rgb2gray(objImg);

    % down-sample
    smallImg = downN(objImg, smallImgNbBlocks);
    
    % append marginals (along x- and y- directions)
    hMean = sum(smallImg,2); hMean = hMean./sum(hMean(:));
    vMean = sum(smallImg,1); vMean = vMean./sum(vMean(:));

    feats.SmallImg = cat(1, smallImg(:), hMean(:), vMean(:));
    
else
    feats.SmallImg = [];
end

%% HOG
if args.HOG
    % parameters
    hogBlockSize = 7; % 5 = 14x5x22 matrix, 7 = 19x7x22
    hogImgSize = [144 64];
    
    % grow the bounding box
    objBboxExp = expandBbox(objBbox, 0.25, [imgHeight, imgWidth]);
    objImg = getObjImg(img, objBboxExp, [imgHeight imgWidth]);
    
    objImg = imresize(objImg, hogImgSize);
    
    % compute HOG features
    hog = features_sensitive(objImg, hogBlockSize);

    % keep only bottom half (to capture shadow)
    hog = hog(ceil(size(hog,1)/2+1):end,:,:);
    
    feats.HOG = hog(:);
else
    feats.HOG = [];
end

%% LAB Histogram
if args.LABHistogram
    % parameters
    labNbBins = 5; 
    
    % 
    objImg = getObjImg(img, objBbox, [imgHeight imgWidth]);
    [joint, marg1, marg2, marg3] = computeHistogramFeatures(rgb2lab(objImg), labNbBins, [0 -100 -100], [100 100 100]);
    
    feats.LABHistogram = cat(1, marg1(:), marg2(:), marg3(:));
else
    feats.LABHistogram = [];
end

%% HSV Histogram
if args.HSVHistogram
    % parameters
    hsvNbBins = 5; 
    
    % 
    objImg = getObjImg(img, objBbox, [imgHeight imgWidth]);
    [joint, marg1, marg2, marg3] = computeHistogramFeatures(rgb2hsv(objImg), hsvNbBins, [0 -100 -100], [100 100 100]);
    
    feats.HSVHistogram = cat(1, marg1(:), marg2(:), marg3(:));
     
else
    feats.HSVHistogram = [];
end

%% Useful function: compute histograms
function [feats, feats1, feats2, feats3] = computeHistogramFeatures(objImg, nbBins, min, max)

objImgVec = reshape(objImg, size(objImg,1)*size(objImg,2), size(objImg,3));

hist3D = myHistoND(objImgVec, nbBins, min, max);
hist3D = hist3D./sum(hist3D(:));

% joint
feats = hist3D(:);

% marginals
feats1 = squeeze(sum(sum(hist3D,2),3));
feats2 = squeeze(sum(sum(hist3D,1),3));
feats3 = squeeze(sum(sum(hist3D,1),2));

%% Useful function
function objImg = getObjImg(img, objBbox, imgDims)
    
% make sure there's no overflow
objBbox = max(round(objBbox), 1);
objBbox([1 3]) = min(objBbox([1 3]), imgDims(2));
objBbox([2 4]) = min(objBbox([2 4]), imgDims(1));

% extract window around object
objImg = img(objBbox(2):objBbox(4), objBbox(1):objBbox(3), :);
