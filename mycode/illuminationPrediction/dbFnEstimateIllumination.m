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

%% Shadows information
bndInfo = load(fullfile(args.DbPath, imgInfo.wseg25.filename));
shadowInfo = load(fullfile(args.DbPath, imgInfo.shadows.filename));

%% Pedestrian detection information
detInfo = load(fullfile(args.DbPath, imgInfo.detObjects.person.filename));

%% Do we need to estimate the horizon?
if args.DoEstimateHorizon
    horizonLine = [];
else
    horizonLine = str2double(imgInfo.manualLabeling.horizonLine);
end

%% Estimate the illumination
[probSun, skyData, shadowsData, wallsData, pedsData] = ...
    estimateIllumination(img, focalLength, horizonLine, ...
    'GeomContextInfo', geomContextInfo, ...
    'DoVote', args.DoVote, 'DoWeightVote', args.DoWeightVote, 'DoCueConfidence', args.DoCueConfidence, ...
    'DoSky', args.DoSky, 'SkyPredictor', args.SkyPredictor, 'DoSkyClassif', args.DoSkyClassif, 'SkyDb', args.SkyDb, ...
    'DoShadows', args.DoShadows, 'ShadowsPredictor', args.ShadowsPredictor, 'BndInfo', bndInfo, 'ShadowInfo', shadowInfo, ...
    'DoWalls', args.DoWalls, 'WallPredictor', args.WallPredictor, ...
    'DoPedestrians', args.DoPedestrians, 'PedestrianPredictor', args.PedestrianPredictor, 'DetInfo', detInfo);

%% Save the results
if args.DoSave
    [m,m,m] = mkdir(fileparts(outputFile)); %#ok
    sunAzimuths = args.SkyPredictor.sunAzimuths;
    sunZeniths = args.SkyPredictor.sunZeniths;
    
    % pull stuff out of the output structures
    skyProbSun = skyData.probSun;
    shadowsProbSun = shadowsData.probSun;
    walsProbSun = wallsData.probSun;
    pedsProbSun = pedsData.probSun;
    
    shadowLines = shadowsData.lines;
    nbPeds = pedsData.nb;
    wallsArea = wallsData.area;
    skyArea = skyData.area;
    skyLabel = skyData.label;
    
    save(outputFile, 'probSun', 'skyProbSun', 'shadowsProbSun', 'wallsProbSun', 'pedsProbSun', ...
        'sunAzimuths', 'sunZeniths', ...
        'shadowLines', 'nbPeds', 'wallsArea', 'skyArea', 'skyLabel');
    %         'allWallsProbSun', 'allPedsProbSun', ...
    %         'shadowBoundaries', ...
end
