function demoEstimateIllumination
% Demonstration of how to use the illumination estimation code.
%
% ----------
% Jean-Francois Lalonde

%% User parameters

dataPath = 'data';
skyDbPath = fullfile(dataPath, 'skyDb-Hsv.mat');
sunVisibilityPath = fullfile(dataPath, 'pSunGivenFeatures.mat');
objectDetectorPath = fullfile(dataPath, 'objectDetector', 'personVOC2008.mat');

verbose = 1;

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

%% Load the image and its relevant data (see README.txt)
img = im2double(imread(fullfile(dataPath, 'img.jpg')));

% Geometric context information
geomContextInfo = load(fullfile(dataPath, 'geomContext.mat'));

% Shadows information
bndInfo = load(fullfile(dataPath, 'wseg25.mat'));
shadowInfo = load(fullfile(dataPath, 'shadows.mat'));

%% First, run the sun visibility classifier
fprintf('Computing probability that sun is visible...\n');

% Load the sun visibility classifier
sunVisibilityClassifierInfo = load(sunVisibilityPath);

% Predict the sun visibility
[vis, prob] = predictSunVisibility(img, sunVisibilityClassifierInfo, ...
    geomContextInfo, bndInfo, shadowInfo);

fprintf('Probability that sun is visible: %.2f.\n', prob(2));

%% Load local illumination predictors
nbZenithBins = 5;
nbAzimuthBins = 32;
alignHistogram = 1;

skyPredictor = SkyIlluminationPredictor('Verbose', verbose, ...
   'NbAzimuthBins', nbAzimuthBins, 'NbZenithBins', nbZenithBins, ...
   'AlignHistogram', alignHistogram);
skyPredictor = skyPredictor.initialize();

shadowsPredictor = ShadowsIlluminationPredictor('Verbose', verbose, ...
   'NbAzimuthBins', nbAzimuthBins, 'AlignHistogram', alignHistogram);
shadowsPredictor = shadowsPredictor.initialize();

wallPredictor = WallIlluminationPredictor('Verbose', verbose, ...
   'NbAzimuthBins', nbAzimuthBins, 'AlignHistogram', alignHistogram);
wallPredictor = wallPredictor.initialize();

pedsPredictor = PedestrianIlluminationPredictor('Verbose', verbose, ...
   'NbAzimuthBins', nbAzimuthBins, 'AlignHistogram', alignHistogram);
pedsPredictor = pedsPredictor.initialize();

%% Detect pedestrians
objectDetectorInfo = load(objectDetectorPath);
boxes = detectObjectsParams(img, objectDetectorInfo);

%% Estimate the illumination
[probSun, skyData, shadowsData, wallsData, pedsData] = ...
    estimateIllumination(img, focalLength, [], ...
    'DoVote', 1, ...
    'GeomContextInfo', geomContextInfo, ...
    'DoSky', doSky, 'SkyPredictor', skyPredictor, 'DoSkyClassif', doSkyClassif, 'SkyDb', skyDb, ...
    'DoShadows', doShadows, 'ShadowsPredictor', shadowsPredictor, 'BndInfo', bndInfo, 'ShadowInfo', shadowInfo, ...
    'DoWalls', doWalls, 'WallPredictor', wallPredictor, ...
    'DoPedestrians', doPedestrians, 'PedestrianPredictor', pedsPredictor, 'DetInfo', detInfo);

%% Display some results