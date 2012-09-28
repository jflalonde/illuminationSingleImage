%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function localLightingFeatures = computeLocalLightingFeatures(img, objBbox, varargin)
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
function feats = computeLocalLightingFeatures(img, objBbox, varargin)

defaultArgs = struct('GIST', 0, 'SmallImg', 0, 'HOG', 0, ...
    'GISTBottom', 0, 'SmallImgBottom', 0, 'HOGBottom', 0, ...
    'Shadows', 0, 'ImgBoundaries', [], 'BoundaryProbabilities', []);
args = parseargs(defaultArgs, varargin{:});
        
feats = [];
[imgHeight, imgWidth, c] = size(img);

%% GIST descriptor
if args.GIST
    % GIST: tight bounding box, coarse split, low frequency content

    % parameters
    gistNbBlocks = 3;
    gistOrientationsPerScale = [2 2 2 2 2];
    gistObjSize = 128;
    
    % use the original bounding box
    objBboxExp = objBbox; %expandBbox(objBbox, -0.25, [imgHeight, imgWidth], 'ExpandHeight', 0);
    
    objImg = getObjImg(img, objBboxExp, [imgHeight imgWidth]);
    feats.GIST = computeGIST(objImg, gistOrientationsPerScale, gistObjSize, gistNbBlocks);

else
    feats.GIST = [];
end

%% GIST descriptor around the foot region
if args.GISTBottom
    % GIST: tight bounding box, coarse split, low frequency content

    % parameters
    gistNbBlocks = 3;
    gistOrientationsPerScale = [2 2 2 2 2];
    gistObjSize = 128;
    
    objBboxExp = getBottomBbox(objBbox, imgWidth, imgHeight);
    objImg = getObjImg(img, objBboxExp, [imgHeight imgWidth]);
    
    feats.GISTBottom = computeGIST(objImg, gistOrientationsPerScale, gistObjSize, gistNbBlocks);

else
    feats.GISTBottom = [];
end

%% Down-sampled image
if args.SmallImg
    % parameters
    smallImgNbBlocks = 5;
    smallImgSize = 128;
    
    % get tight bounding box
    objBboxExp = objBbox; %expandBbox(objBbox, -0.25, [imgHeight, imgWidth], 'ExpandHeight', 0);
    objImg = getObjImg(img, objBboxExp, [imgHeight imgWidth]);
    
    feats.SmallImg = computeSmallImg(objImg, smallImgSize, smallImgNbBlocks);
    
else
    feats.SmallImg = [];
end

%% Down-sampled image at the feet
if args.SmallImgBottom
    % parameters
    smallImgNbBlocks = 5;
    smallImgSize = 128;
    
    % get tight bounding box
    objBboxExp = getBottomBbox(objBbox, imgWidth, imgHeight);
    objImg = getObjImg(img, objBboxExp, [imgHeight imgWidth]);
    
    feats.SmallImgBottom = computeSmallImg(objImg, smallImgSize, smallImgNbBlocks);
    
else
    feats.SmallImgBottom = [];
end

%% HOG on the object
if args.HOG
    % parameters
    hogBlockSize = 10; % coarse
    hogImgSize = [128 64];
    
    objImg = getObjImg(img, objBbox, [imgHeight imgWidth]);
    
    feats.HOG = computeHOG(objImg, hogImgSize, hogBlockSize);
else
    feats.HOG = [];
end

%% HOG at the bottom
if args.HOGBottom
    % parameters
    hogBlockSize = 7; % 5 = 14x5x22 matrix, 7 = 19x7x22
    hogImgSize = [64 64];
    
    objBboxExp = getBottomBbox(objBbox, imgWidth, imgHeight);
    objImg = getObjImg(img, objBboxExp, [imgHeight imgWidth]);
    
    feats.HOGBottom = computeHOG(objImg, hogImgSize, hogBlockSize);
else
    feats.HOGBottom = [];
end

%% Shadows
if args.Shadows
    % look only around the feet
    objBboxExp = expandBbox(objBbox, 0.3, [imgHeight, imgWidth], 'ExpandWidth', 0);
    objBboxExp = expandBbox(objBboxExp, 1, [imgHeight, imgWidth], 'ExpandHeight', 0);
    
    % keep only bottom part
    objBboxExp(2) = objBbox(2) + 2*(objBbox(4)-objBbox(2))/3;
        
    % get shadow boundary direction
    boundaryThetas = computeBoundaryOrientationsSubPixel(args.ImgBoundaries);

    % weight by how much they seem to "emanate" from center of object
    
    % compute angle between center of line and reference point
    refPoint = [objBbox(1) + (objBbox(3)-objBbox(1))/2, objBbox(4)];
    centerPoints = cellfun(@(b) mean(b,1), args.ImgBoundaries, 'UniformOutput', 0);
    
    centerThetas = cellfun(@(c) atan2(c(2)-refPoint(2), c(1)-refPoint(1)), centerPoints);
    
    % weight is angle between vector and line direction
    angularWeight = 1-min(angularError(centerThetas, boundaryThetas), angularError(centerThetas, boundaryThetas+pi))./(pi/2);
    
    boundaryWeight = angularWeight.*args.BoundaryProbabilities';
    
    % find boundaries which lie only close to the bottom of the object
    pctInside = cellfun(@(b) nnz(b(:,1) >= objBboxExp(1) & b(:,1) <= objBboxExp(3) & b(:,2) >= objBboxExp(2) & b(:,2) <= objBboxExp(4))./size(b,1), args.ImgBoundaries);
    indInside = pctInside > 0;
    
    % re-orient boundaries to make the "point outside the center"
    boundaryThetas(centerThetas>0 & boundaryThetas<0) = boundaryThetas(centerThetas>0 & boundaryThetas<0)+pi;
    boundaryThetas(centerThetas<0 & boundaryThetas>0) = boundaryThetas(centerThetas<0 & boundaryThetas>0)-pi;
    
    % replicate per pixel, compute histogram
    allBoundaryWeights = arrayfun(@(w,b) repmat(w, size(b{1},1),1), boundaryWeight(indInside), args.ImgBoundaries(indInside), 'UniformOutput', 0);
    allBoundaryWeights = cat(1, allBoundaryWeights{:});
    
    allBoundaryThetas = arrayfun(@(t,b) repmat(t, size(b{1},1),1), boundaryThetas(indInside), args.ImgBoundaries(indInside), 'UniformOutput', 0);
    allBoundaryThetas = cat(1, allBoundaryThetas{:});
    
    % histogram of boundary orientations, weighted by probability of shadow
    nbBins = 8;
    if ~isempty(allBoundaryThetas)
        histo = myHistoNDWeighted(allBoundaryThetas, allBoundaryWeights, nbBins, -pi, pi);
    else
        histo = zeros(1, nbBins);
    end
    
    % normalize histogram by area of region
    histo = histo ./ ((objBboxExp(3)-objBboxExp(1))*(objBboxExp(4)-objBboxExp(2)));
    
    feats.Shadows = histo(:);
else
    feats.Shadows = [];
end

%% Useful function: gist on an image
function gist = computeGIST(img, orientationsPerScale, objSize, nbBlocks)

% resize to standard size
objImg = imresize(img, [objSize objSize]);

% get intensity channel only
objImg = rgb2gray(objImg);

% compute GIST descriptor
G = createGabor(orientationsPerScale, objSize(1));

% Computing gist requires 1) prefilter image, 2) filter image and collect output energies
%     output = prefilt_nocontrast(double(objImg).*255, 4); % -> do we really need that step?
gist = gistGabor(objImg, nbBlocks, G);

%% Useful function: sumbsampled image
function smallImg = computeSmallImg(img, imgSize, nbBlocks)

img = imresize(img, [imgSize imgSize]);
img = rgb2gray(img);

% down-sample
smallImg = downN(img, nbBlocks);

% append marginals (along x- and y- directions)
hMean = sum(smallImg,2); hMean = hMean./sum(hMean(:));
vMean = sum(smallImg,1); vMean = vMean./sum(vMean(:));

smallImg = cat(1, smallImg(:), hMean(:), vMean(:));

%% Useful function: compute HOG
function hog = computeHOG(img, imgSize, blockSize)

objImg = imresize(img, imgSize);

% compute HOG features
hog = features_sensitive(objImg, blockSize);
hog = hog(:);


%% Useful function
function objImg = getObjImg(img, objBbox, imgDims)
    
% make sure there's no overflow
objBbox = max(round(objBbox), 1);
objBbox([1 3]) = min(objBbox([1 3]), imgDims(2));
objBbox([2 4]) = min(objBbox([2 4]), imgDims(1));

% extract window around object
objImg = img(objBbox(2):objBbox(4), objBbox(1):objBbox(3), :);

%% Useful function: get bounding box around the feet region
function objBboxExp = getBottomBbox(objBbox, imgWidth, imgHeight)

% look only around the feet
objBboxExp = expandBbox(objBbox, 0.3, [imgHeight, imgWidth], 'ExpandWidth', 0);
objBboxExp = expandBbox(objBboxExp, 1, [imgHeight, imgWidth], 'ExpandHeight', 0);

% keep only bottom part
objBboxExp(2) = objBbox(2) + 2*(objBbox(4)-objBbox(2))/3;
