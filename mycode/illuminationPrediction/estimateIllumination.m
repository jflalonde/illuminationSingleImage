function [probSun, skyData, shadowsData, wallsData, pedsData] = ...
    estimateIllumination(img, focalLength, horizonLine, varargin)
% Estimates the illumination parameters given an image.
%
%   estimateIllumination(...)
% 
%   If horizonLine = [], it will be estimated from the geometric context
%   labels.
%
% ----------
% Jean-Francois Lalonde

% parse arguments
defaultArgs = struct('DoVote', 0, 'DoWeightVote', 0, 'DoCueConfidence', 0, ...
    'GeomContextInfo', [], ...
    'DoSky', 0, 'SkyPredictor', [], 'DoSkyClassif', 0, 'SkyDb', [], ...
    'DoShadows', 0, 'ShadowsPredictor', [], 'Boundaries', [], ...
    'BoundaryLabels', [], 'AllBoundaryProbabilities', [], 'IndStrongBnd', [], ...
    'DoWalls', 0, 'WallPredictor', [], ...
    'DoPedestrians', 0, 'PedestrianPredictor', [], 'BoundingBoxes', [], ...
    'LocalPedestrianLightingClassifiers', []);
args = parseargs(defaultArgs, varargin{:});


%% Geometric context information
geomContextInfo = args.GeomContextInfo;

%% Shadows information
boundaries = args.Boundaries;
% shadowInfo = args.ShadowInfo;

%% Estimate illumination using sky
if args.DoSky
    fprintf('Estimating illumination from the sky...'); tstart = tic;
    [skyData.probSun, skyData.label, skyData.area] = estimateIlluminationFromSky(...
        img, args.SkyPredictor, geomContextInfo.allSkyMask, [], ...
        focalLength, horizonLine, 'DoSkyClassif', args.DoSkyClassif, 'SkyDb', args.SkyDb, ...
        'UseIJCVVersion', 0);
    fprintf('done in %.2fs\n', toc(tstart));
else
    % uniform
    skyData.probSun = args.SkyPredictor.constantProb();
    skyData.label = 'noestimate';
    skyData.area = 0;
end

%% Shadows
if args.DoShadows    
    fprintf('Estimating illumination from ground shadows...'); tstart = tic;
    if args.DoCueConfidence
        % keep all boundaries (strong)
%         shadowBoundaries = boundaries(shadowInfo.indStrongBnd);
        shadowBoundaries = boundaries(args.BoundaryLabels==0);
    else
        % only keep most likely boundaries
        shadowPrecisionThresh = 0.75;
        shadowBoundaries = boundaries(args.AllBoundaryProbabilities>shadowPrecisionThresh);
%         shadowBoundaries = boundaries(shadowInfo.boundaryLabels==0);
    end
    
    % force the ground to be zero below the horizon
    [~,mind] = max(cat(3, geomContextInfo.allGroundMask, geomContextInfo.allSkyMask, geomContextInfo.allWallsMask), [], 3);
    groundMask = imdilate(mind==1, strel('disk', 3));
    groundMask(1:ceil(horizonLine+1),:) = 0;
    
    % make sure shadows are on the ground (apply geometric context mask)
    meanGroundProb = interpBoundarySubPixel(shadowBoundaries, groundMask);
    shadowBoundaries = shadowBoundaries(meanGroundProb > 0.5);
    
    if ~isempty(shadowBoundaries)
        shadowLines = extractLinesFromBoundaries(img, shadowBoundaries);
        
        % concatenate probabilty of shadow in the last column of shadowLines
        probImg = zeros(size(img,1), size(img,2));
        for i=args.IndStrongBnd(:)'
            boundariesPxInd = convertBoundariesToPxInd(boundaries(i), size(img));
            probImg(boundariesPxInd) = args.AllBoundaryProbabilities(i);
        end
        
        shadowProbs = meanLineIntensity(probImg, shadowLines, 1);
        shadowLines = cat(2, shadowLines, shadowProbs);
        
        shadowsData.probSun = estimateIlluminationFromShadows(img, args.ShadowsPredictor, shadowLines, ...
            focalLength, horizonLine, 'DoVote', args.DoVote, 'DoWeightVote', args.DoWeightVote, 'DoCueConfidence', args.DoCueConfidence);
        shadowsData.lines = shadowLines;
    else
        shadowsData.probSun = args.ShadowsPredictor.constantProb();
        shadowsData.lines = [];
    end
    fprintf('done in %.2fs\n', toc(tstart));
else
    shadowsData.probSun = args.ShadowsPredictor.constantProb();
    shadowsData.lines = [];
end

%% Walls
if args.DoWalls
    fprintf('Estimating illumination from the vertical surfaces...'); 
    tstart = tic;
    % geom context is flipped wrt our convention: left <-> right
    [wallsData.probSun, wallsData.area] = estimateIlluminationFromWalls(img, args.WallPredictor, ...
        geomContextInfo.wallRight, geomContextInfo.wallFacing, geomContextInfo.wallLeft, ...
        'DoVote', args.DoVote, 'DoWeightVote', args.DoWeightVote, 'DoCueConfidence', args.DoCueConfidence);
    fprintf('done in %.2fs\n', toc(tstart));
else
    wallsData.probSun = args.WallPredictor.constantProb();
    wallsData.area = 0;
end

%% Pedestrians
if args.DoPedestrians
    % load object information
    fprintf('Estimating illumination from the pedestrians...'); tstart = tic;
    
    % Compute local lighting probabilities for all detections
    fprintf('Computing probabilities...');
    [pObj, pLocalVisibility, pLocalLightingGivenObject, ...
        pLocalLightingGivenNonObject] = computePedestrianProbabilities(img, ...
        args.BoundingBoxes, ...
        args.LocalPedestrianLightingClassifiers.localVisibilityClassifier, ...
        args.LocalPedestrianLightingClassifiers.lightingGivenObjectClassifier, ...
        args.LocalPedestrianLightingClassifiers.lightingGivenNonObjectClassifier);
    
    [pedsData.probSun, pedsData.nb] = estimateIlluminationFromPedestrians(...
        img, args.PedestrianPredictor, pObj, pLocalVisibility, ...
        pLocalLightingGivenObject, pLocalLightingGivenNonObject, ...
        'DoVote', args.DoVote, 'DoWeightVote', args.DoWeightVote, ...
        'DoCueConfidence', args.DoCueConfidence);
    
    fprintf('done in %.2fs\n', toc(tstart));
else
    pedsData.probSun = args.PedestrianPredictor.constantProb();
    pedsData.nb = 0;
end

%% Combine everything together
probSun = cat(3, skyData.probSun, shadowsData.probSun, wallsData.probSun, pedsData.probSun);
probSun = prod(probSun, 3);
probSun = probSun./sum(probSun(:));

