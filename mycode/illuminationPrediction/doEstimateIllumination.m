%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function doEstimateIllumination
%  
% 
% Input parameters:
%
% Output parameters:
%   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function doEstimateIllumination
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup
addpath ../;
setPath;

dbPath = fullfile(basePath, 'testDb');
imagesPath = fullfile(basePath, 'testImages');
outputBasePath = fullfile(basePath, 'testResults');

skyDbPath = fullfile(singleImageResultsPath, 'sky', 'skyDb-Hsv.mat');

%% User parameters
recompute = 1;
doSave = 1;
doDisplay = 0;
verbose = 1;

% General parameters
doEstimateHorizon = 1;
doVote = 1;
doWeightVote = 0;
doCueConfidence = 0;

doVote = double(~doCueConfidence & doVote);

% Sky parameters
doSky = 1;
doSkyClassif = 1;
skyDb = load(skyDbPath);

% Shadows parameters
doShadows = 1;

% Walls parameters 
doWalls = 1;

% Pedestrian parameters
doPedestrians = 1;

%% Build type name
typeName = buildResultsName(doSkyClassif, doEstimateHorizon, doVote, doWeightVote, doCueConfidence);
fprintf('Type: %s\n', typeName);
outputPath = fullfile(outputBasePath, typeName);

%% Load local illumination predictors
nbZenithBins = 5;
nbAzimuthBins = 32;
alignHistogram = 1;

skyIllPredictor = SkyIlluminationPredictor('Verbose', verbose, 'NbAzimuthBins', nbAzimuthBins, 'NbZenithBins', nbZenithBins, 'AlignHistogram', alignHistogram);
skyIllPredictor = skyIllPredictor.initialize();

shadowsIllPredictor = ShadowsIlluminationPredictor('Verbose', verbose, 'NbAzimuthBins', nbAzimuthBins, 'AlignHistogram', alignHistogram);
shadowsIllPredictor = shadowsIllPredictor.initialize();

wallIllPredictor = WallIlluminationPredictor('Verbose', verbose, 'NbAzimuthBins', nbAzimuthBins, 'AlignHistogram', alignHistogram);
wallIllPredictor = wallIllPredictor.initialize();

pedIllPredictor = PedestrianIlluminationPredictor('Verbose', verbose, 'NbAzimuthBins', nbAzimuthBins, 'AlignHistogram', alignHistogram);
pedIllPredictor = pedIllPredictor.initialize();

%% Call the database
dbFn = @dbFnEstimateIllumination;
parallelized = 0;
randomized = 0;
[files, directories] = getFilesFromDirectory(dbPath, '', '', '', '.xml', 1);
imgFolder = 'april21_static_outdoor_kendall';
imgFilename = 'img_1006.xml';
ind = strcmp(directories, imgFolder) & strcmp(files, imgFilename);
processResultsDatabaseFiles(dbPath, files(ind), directories(ind), outputPath, dbFn, parallelized, randomized, ...
    'ImagesPath', imagesPath, 'DbPath', dbPath, ...
    'Recompute', recompute, 'DoSave', doSave, 'DoDisplay', doDisplay, ...
    'DoEstimateHorizon', doEstimateHorizon, 'DoVote', doVote, 'DoWeightVote', doWeightVote, 'DoCueConfidence', doCueConfidence, ...
    'DoSky', doSky, 'SkyPredictor', skyIllPredictor, 'DoSkyClassif', doSkyClassif, 'SkyDb', skyDb, ...
    'DoShadows', doShadows, 'ShadowsPredictor', shadowsIllPredictor, ...
    'DoWalls', doWalls, 'WallPredictor', wallIllPredictor, ...
    'DoPedestrians', doPedestrians, 'PedestrianPredictor', pedIllPredictor);        
