function demoEstimateIllumination
% Demonstration of how to use the illumination estimation code.
%
% ----------
% Jean-Francois Lalonde

dataPath = 'data';
skyDbPath = fullfile(dataPath, 'skyDb-Hsv.mat');

%% User parameters
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

%% Load local illumination predictors
nbZenithBins = 5;
nbAzimuthBins = 32;
alignHistogram = 1;

skyPredictor = SkyIlluminationPredictor('Verbose', verbose, 'NbAzimuthBins', nbAzimuthBins, 'NbZenithBins', nbZenithBins, 'AlignHistogram', alignHistogram);
skyPredictor = skyPredictor.initialize();

shadowsPredictor = ShadowsIlluminationPredictor('Verbose', verbose, 'NbAzimuthBins', nbAzimuthBins, 'AlignHistogram', alignHistogram);
shadowsPredictor = shadowsPredictor.initialize();

wallPredictor = WallIlluminationPredictor('Verbose', verbose, 'NbAzimuthBins', nbAzimuthBins, 'AlignHistogram', alignHistogram);
wallPredictor = wallPredictor.initialize();

pedsPredictor = PedestrianIlluminationPredictor('Verbose', verbose, 'NbAzimuthBins', nbAzimuthBins, 'AlignHistogram', alignHistogram);
pedsPredictor = pedsPredictor.initialize();

%% Load the image and its relevant data
% imgFolder = 'april21_static_outdoor_kendall';
% imgFilename = 'img_1006.xml';

%% Estimate the illumination
[probSun, skyData, shadowsData, wallsData, pedsData] = ...
    estimateIllumination(img, focalLength, [], ...
    'DoVote', 1, ...
    'DoSky', doSky, 'SkyPredictor', skyPredictor, 'DoSkyClassif', doSkyClassif, 'SkyDb', skyDb, ...
    'DoShadows', doShadows, 'ShadowsPredictor', shadowsPredictor, ...
    'DoWalls', doWalls, 'WallPredictor', wallPredictor, ...
    'DoPedestrians', doPedestrians, 'PedestrianPredictor', pedsPredictor);

%% Display some results