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

% Approximation to the focal length
focalLength = size(img,2)*10/7;

%% Load local illumination predictors
classifPath = fullfile('data', 'localIlluminationClassifiers');

lightingGivenObjectClassifier = load(fullfile(classifPath, 'lighting', ...
    'pLocalGivenFeatures-person-4classes-10.mat'));

lightingGivenNonObjectClassifier = load(fullfile(classifPath, 'lighting', ...
    'pLocalGivenFeatures-nonPerson-4classes-10.mat'));

% local visibility predictor (shadow vs sunlit)
localVisibilityClassifier = load(fullfile(classifPath, 'visibility', ...
    'pLocalGivenFeatures-person-3classes-5.mat'));


%% First, run the sun visibility classifier
fprintf('Computing probability that sun is visible...\n');

% Load the sun visibility classifier
sunVisibilityClassifierInfo = load(sunVisibilityPath);

% Predict the sun visibility
[~, prob] = predictSunVisibility(img, sunVisibilityClassifierInfo, ...
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
fprintf('Running pedestrian detector...');
objectDetectorInfo = load(objectDetectorPath);
boxes = detectObjectsParams(img, objectDetectorInfo, 'Normalize', 1);
fprintf('done.\n');

%% Compute local lighting probabilities for all detections
nbObjects = size(boxes, 1);

% We need:
% - pObj: probability of object (from the normalized object detector)
% - pLocalVisibility: probability that object has sun directly shining on it
% - pLocalLightingGivenObject: probability of sun position given that the 
%   detection is an actual pedestrian
% - pLocalLightingGivenNonObject: probability of sun position given that
%   the detection is _not_ a pedestrian.
pObj = [1-boxes(:,end), boxes(:, end)];
pLocalVisibility = zeros(nbObjects, 2);
pLocalLightingGivenObject = zeros(nbObjects, 4);
pLocalLightingGivenNonObject = zeros(nbObjects, 4);
for i_obj = 1:nbObjects
    % compute visibility features (shadow vs sunlit) 
    visibilityFeatures = computeLocalVisibilityFeatures(img, boxes(i_obj,:), ...
        'GIST', 1, 'SmallImg', 1, 'HSVHistogram', 1);
    
    % run local visibility classifier
    pLocalVisibility(i_obj,:) = applyLocalClassifier(visibilityFeatures, ...
        localVisibilityClassifier);
    
    % compute local lighting features (sun direction)
    lightingFeatures = computeLocalLightingFeatures(img, boxes(i_obj,:), ...
        'HOG', 1);
        
    % run local lighting classifier
    pLocalLightingGivenObject(i_obj,:) = applyLocalClassifier(lightingFeatures, ...
        lightingGivenObjectClassifier);

    % run local lighting classifier
    pLocalLightingGivenNonObject(i_obj,:) = applyLocalClassifier(lightingFeatures, ...
        lightingGivenNonObjectClassifier.lightingGivenNonObjectClassifier);
end

%% Estimate the illumination
detInfo = struct('pObj', pObj, 'pLocalVisibility', pLocalVisibility, ...
    'pLocalLightingGivenObject', pLocalLightingGivenObject, ...
    'pLocalLightingGivenNonObject', pLocalLightingGivenNonObject);

[probSun, skyData, shadowsData, wallsData, pedsData] = ...
    estimateIllumination(img, focalLength, [], ...
    'DoVote', 1, ...
    'GeomContextInfo', geomContextInfo, ...
    'DoSky', 1, 'SkyPredictor', skyPredictor, 'DoSkyClassif', doSkyClassif, 'SkyDb', skyDb, ...
    'DoShadows', 0, 'ShadowsPredictor', shadowsPredictor, 'BndInfo', bndInfo, 'ShadowInfo', shadowInfo, ...
    'DoWalls', 1, 'WallPredictor', wallPredictor, ...
    'DoPedestrians', 1, 'PedestrianPredictor', pedsPredictor, 'DetInfo', detInfo);

%% Load the prior, and combine with the data term
priorPath = fullfile('data', 'illuminationPriors', 'gpsAndTimeJoint-1000000.mat');
illPrior = load(priorPath);

c = linspace(0, pi/2, nbZenithBins*2+1); c = c(2:2:end);
illPrior = interp1(linspace(0, pi/2, size(illPrior.priorSunPositionDist, 1)), sum(illPrior.priorSunPositionDist, 2), c);
illPrior = repmat(illPrior(:), [1 nbAzimuthBins]); 

probSun = probSun .* illPrior;
probSun = probSun ./ sum(probSun(:));

%% Display some results
figure;
nrows = 1; ncols = 6;
axesId = 1;

axesId = displayResult(axesId, skyData.probSun, 'Sky only');
axesId = displayResult(axesId, shadowsData.probSun, 'Shadows only');
axesId = displayResult(axesId, wallsData.probSun, 'Vertical surfaces only');
axesId = displayResult(axesId, pedsData.probSun, 'Pedestrians only');
axesId = displayResult(axesId, illPrior, 'Prior');
displayResult(axesId, probSun, 'Combined');

    % helper function for displaying individual results
    function axesId = displayResult(axesId, probSun, titleStr)
        displaySunProbabilityVectorized(probSun, 1, 'Axes', ...
            subplot_tight(nrows, ncols, axesId));
        % for some reason, 'title' messes things up, so just place the text
        % directly
        text(0.5, 1.1, titleStr, 'HorizontalAlignment', 'center');
        axesId = axesId + 1;
    end

end


