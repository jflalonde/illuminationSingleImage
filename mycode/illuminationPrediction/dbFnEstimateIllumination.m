%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function ret = dbFnEstimateIllumination(outputBasePath, annotation, varargin)
%  
% 
% Input parameters:
%
% Output parameters:
%   
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ret = dbFnEstimateIllumination(outputBasePath, imgInfo, varargin) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2007 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ret = 0;  

% parse arguments
defaultArgs = struct('Recompute', 0, 'RecomputeStruct', [], 'DoSave', 0, 'DoDisplay', 0, ...
    'ImagesPath', [], 'DbPath', [], ...
    'DoEstimateHorizon', 0, 'DoVote', 0, 'DoWeightVote', 0, 'DoCueConfidence', 0, ...
    'DoSky', 1, 'SkyPredictor', [], 'DoSkyClassif', 0, 'SkyDb', [], ...
    'DoShadows', 1, 'ShadowsPredictor', [], ...
    'DoWalls', 1, 'WallPredictor', [], ...
    'DoPedestrians', 1, 'PedestrianPredictor', []);
args = parseargs(defaultArgs, varargin{:});

%% Prepare output
outputFile = fullfile(outputBasePath, imgInfo.image.folder, strrep(imgInfo.image.filename, '.jpg', '.mat'));
if ~args.Recompute && exist(outputFile, 'file')
    fprintf('Already computed! Skipping...\n');
    return;
end

args.RecomputeStruct.recomputeOpts.sky.filename = fullfile(imgInfo.image.folder, strrep(imgInfo.image.filename, '.jpg', '.mat'));
args.RecomputeStruct.recomputeOpts.shadows.filename = fullfile(imgInfo.image.folder, strrep(imgInfo.image.filename, '.jpg', '.mat'));
args.RecomputeStruct.recomputeOpts.walls.filename = fullfile(imgInfo.image.folder, strrep(imgInfo.image.filename, '.jpg', '.mat'));

%% Read the image
img = imreadTrans(fullfile(args.ImagesPath, imgInfo.image.folder, imgInfo.image.filename));
focalLength = str2double(imgInfo.cameraParams.focalLength);

% initialize random number generator to make sure results are reproducible
initrand(mean(img(:)));

%% Geometric context information
geomContextInfo = load(fullfile(args.DbPath, imgInfo.geomContext.filename));

%% Do we need to estimate the horizon?
if args.DoEstimateHorizon
    horizonLine = horizonFromGeometricContext(geomContextInfo.allSkyMask>0.5, geomContextInfo.allGroundMask>0.5);
else
    horizonLine = str2double(imgInfo.manualLabeling.horizonLine);
end


%% Estimate illumination using sky
if args.DoSky
    [skyProbSun, skyLabel, skyArea] = estimateIlluminationFromSky(img, args.SkyPredictor, geomContextInfo.allSkyMask, geomContextInfo.segImage, ...
        focalLength, horizonLine, 'DoSkyClassif', args.DoSkyClassif, 'SkyDb', args.SkyDb);
else
    % uniform
    skyProbSun = args.SkyPredictor.constantProb();
    skyLabel = 'noestimate';
    skyArea = 0;
end

%% Shadows
if args.DoShadows
    bndInfo = load(fullfile(args.DbPath, imgInfo.wseg25.filename));
    shadowInfo = load(fullfile(args.DbPath, imgInfo.shadows.filename));
    
    if args.DoCueConfidence
        % keep all boundaries (strong)
%         shadowBoundaries = bndInfo.boundaries(shadowInfo.indStrongBnd);
        shadowBoundaries = bndInfo.boundaries(shadowInfo.boundaryLabels==0);
    else
        % only keep most likely boundaries
        shadowPrecisionThresh = 0.75;
        shadowBoundaries = bndInfo.boundaries(shadowInfo.allBoundaryProbabilities>shadowPrecisionThresh);
%         shadowBoundaries = bndInfo.boundaries(shadowInfo.boundaryLabels==0);
    end
    
    % force the ground to be zero below the horizon
    [m,mind] = max(cat(3, geomContextInfo.allGroundMask, geomContextInfo.allSkyMask, geomContextInfo.allWallsMask), [], 3);
    groundMask = imdilate(mind==1, strel('disk', 3));
    groundMask(1:ceil(horizonLine+1),:) = 0;
    
    % make sure shadows are on the ground (apply geometric context mask)
    meanGroundProb = interpBoundarySubPixel(shadowBoundaries, groundMask);
    shadowBoundaries = shadowBoundaries(meanGroundProb > 0.5);
    
    if ~isempty(shadowBoundaries)
        shadowLines = extractLinesFromBoundaries(img, shadowBoundaries);
        
        % concatenate probabilty of shadow in the last column of shadowLines
        probImg = zeros(size(img,1), size(img,2));
        for i=shadowInfo.indStrongBnd(:)'
            boundariesPxInd = convertBoundariesToPxInd(bndInfo.boundaries(i), size(img));
            probImg(boundariesPxInd) = shadowInfo.allBoundaryProbabilities(i);
        end
        
        shadowProbs = meanLineIntensity(probImg, shadowLines, 1);
        shadowLines = cat(2, shadowLines, shadowProbs);
        
        shadowsProbSun = estimateIlluminationFromShadows(img, args.ShadowsPredictor, shadowLines, ...
            focalLength, horizonLine, 'DoVote', args.DoVote, 'DoWeightVote', args.DoWeightVote, 'DoCueConfidence', args.DoCueConfidence);
    else
        shadowsProbSun = args.ShadowsPredictor.constantProb();
        shadowLines = [];
    end
else
    shadowsProbSun = args.ShadowsPredictor.constantProb();
    shadowLines = [];
end

%% Walls
if args.DoWalls
    % geom context is flipped: left <-> right
    [wallsProbSun, wallsArea, allWallsProbSun] = estimateIlluminationFromWalls(img, args.WallPredictor, ...
        geomContextInfo.wallRight, geomContextInfo.wallFacing, geomContextInfo.wallLeft, ...
        'DoVote', args.DoVote, 'DoWeightVote', args.DoWeightVote, 'DoCueConfidence', args.DoCueConfidence);
else
    wallsProbSun = args.WallPredictor.constantProb();
    wallsArea = 0;
end

%% Pedestrians
if args.DoPedestrians
    % load object information
    detInfo = load(fullfile(args.DbPath, imgInfo.detObjects.person.filename));
    [pedsProbSun, nbPeds, allPedsProbSun] = estimateIlluminationFromPedestrians(img, args.PedestrianPredictor, ...
        detInfo.pObj, detInfo.pLocalVisibility, ...
        detInfo.pLocalLightingGivenObject, detInfo.pLocalLightingGivenNonObject, ...
        'DoVote', args.DoVote, 'DoWeightVote', args.DoWeightVote, 'DoCueConfidence', args.DoCueConfidence);
else
    pedsProbSun = args.PedestrianPredictor.constantProb();
    nbPeds = 0;
end

%% Combine everything together
probSun = cat(3, skyProbSun, shadowsProbSun, wallsProbSun, pedsProbSun);
probSun = prod(probSun, 3);
probSun = probSun./sum(probSun(:));

%% Display the results
if args.DoDisplay
    
end

%% Save the results
if args.DoSave
    [m,m,m] = mkdir(fileparts(outputFile)); %#ok
    sunAzimuths = args.SkyPredictor.sunAzimuths;
    sunZeniths = args.SkyPredictor.sunZeniths;
    save(outputFile, 'probSun', 'skyProbSun', 'shadowsProbSun', 'wallsProbSun', 'pedsProbSun', ...
        'allWallsProbSun', 'allPedsProbSun', ...
        'sunAzimuths', 'sunZeniths', 'skyLabel', 'shadowBoundaries', ...
        'shadowLines', 'nbPeds', 'wallsArea', 'skyArea');
end
