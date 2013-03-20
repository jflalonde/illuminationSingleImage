function demoEstimateIllumination
% Demonstration of how to use the illumination estimation code.
%
% See:
%   J.-F. Lalonde, A. A. Efros, and S. G. Narasimhan, "Estimating the 
%   Natural Illumination Conditions from a Single Outdoor Image," 
%   International Journal of Computer Vision, vol. 98, no. 2, pp. 123?145, 
%   Jun. 2012.
%
% ----------
% Jean-Francois Lalonde

%% User parameters

% Setting this to false will compute the geometric context and detect
% shadows on the test image. Basically, set this to false if you're running
% the code on your own images.
demoMode = true;

dataPath = 'data';
skyDbPath = fullfile(dataPath, 'skyDb-Hsv.mat');
sunVisibilityPath = fullfile(dataPath, 'pSunGivenFeatures.mat');
objectDetectorPath = fullfile(dataPath, 'objectDetector', 'personVOC2008.mat');

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

%% Load the image
img = im2double(imread(fullfile(dataPath, 'img.jpg')));

%% Compute geometric context and shadows
if demoMode
    % We're in demo mode, so just load previously-computed data
    
    % Geometric context information
    geomContextInfo = load(fullfile(dataPath, 'geomContext.mat'));

    % Shadows information
    bndInfo = load(fullfile(dataPath, 'wseg25.mat'));
    boundaries = bndInfo.boundaries;

    shadowInfo = load(fullfile(dataPath, 'shadows.mat'));
    boundaryLabels = shadowInfo.boundaryLabels;
    indStrongBnd = shadowInfo.indStrongBnd;
    allBoundaryProbabilities = shadowInfo.allBoundaryProbabilities;
    
else
    % We're not in demo mode. Actually compute what we need.
  
    % First, compute geometric context
    classifiersPath = getPathName('codeUtilsPrivate', '3rd_party', 'GeometricContext', 'data');
    classifiers = load(fullfile(classifiersPath, 'ijcvClassifier.mat'));

    geomContextInfo = computeGeometricContext(img, classifiers);
    
    % Second, detect shadows on the ground
    [boundaries, boundaryProbabilities, boundaryLabels, indStrongBnd] = ...
        detectShadows(img, 'groundProb', geomContextInfo.allGroundMask);
    
    allBoundaryProbabilities = zeros(length(boundaries), 1);
    allBoundaryProbabilities(indStrongBnd) = boundaryProbabilities;
end

% Approximation to the focal length
focalLength = size(img,2)*10/7;

% We'll estimate the horizon line later...
horizonLine = [];

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
    geomContextInfo, boundaries, boundaryLabels);

fprintf('Probability that sun is visible: %.2f.\n', prob(2));

%% Load local illumination predictors
nbZenithBins = 5;
nbAzimuthBins = 32;
alignHistogram = 1;

skyPredictor = SkyIlluminationPredictor(...
   'NbAzimuthBins', nbAzimuthBins, 'NbZenithBins', nbZenithBins, ...
   'AlignHistogram', alignHistogram);
skyPredictor = skyPredictor.initialize();

shadowsPredictor = ShadowsIlluminationPredictor(...
   'NbAzimuthBins', nbAzimuthBins, 'AlignHistogram', alignHistogram);
shadowsPredictor = shadowsPredictor.initialize();

wallPredictor = WallIlluminationPredictor(...
   'NbAzimuthBins', nbAzimuthBins, 'AlignHistogram', alignHistogram);
wallPredictor = wallPredictor.initialize();

pedsPredictor = PedestrianIlluminationPredictor(...
   'NbAzimuthBins', nbAzimuthBins, 'AlignHistogram', alignHistogram);
pedsPredictor = pedsPredictor.initialize();

%% Detect pedestrians
fprintf('Running pedestrian detector...'); tstart = tic;
objectDetectorInfo = load(objectDetectorPath);
boxes = detectObjectsParams(img, objectDetectorInfo, 'Normalize', 1);
fprintf('found %d bounding boxes in %.2fs.\n', size(boxes, 1), toc(tstart));

%% Estimate the horizon line
if isempty(horizonLine)
    horizonLine = horizonFromGeometricContext(geomContextInfo.allSkyMask>0.5, geomContextInfo.allGroundMask>0.5);
end

%% Estimate the illumination
localPedestrianClassifiers = struct(...
    'localVisibilityClassifier', localVisibilityClassifier, ...
    'lightingGivenObjectClassifier', lightingGivenObjectClassifier, ...
    'lightingGivenNonObjectClassifier', lightingGivenNonObjectClassifier.lightingGivenNonObjectClassifier);

fprintf('Estimating illumination...\n'); tstart = tic;
[probSun, skyData, shadowsData, wallsData, pedsData] = ...
    estimateIllumination(img, focalLength, horizonLine, ...
    'DoVote', 1, ...
    'GeomContextInfo', geomContextInfo, ...
    'DoSky', doSky, 'SkyPredictor', skyPredictor, 'DoSkyClassif', doSkyClassif, 'SkyDb', skyDb, ...
    'DoShadows', doShadows, 'ShadowsPredictor', shadowsPredictor, 'Boundaries', boundaries, ...
    'BoundaryLabels', boundaryLabels, 'AllBoundaryProbabilities', allBoundaryProbabilities, 'IndStrongBnd', indStrongBnd, ...
    'DoWalls', doWalls, 'WallPredictor', wallPredictor, ...
    'DoPedestrians', doPedestrians, 'PedestrianPredictor', pedsPredictor, ...
    'BoundingBoxes', boxes, 'LocalPedestrianLightingClassifiers', localPedestrianClassifiers);
fprintf('Illumination estimated in %.2fs\n', toc(tstart));

%% Load the prior, and combine with the data term
priorPath = fullfile('data', 'illuminationPriors', 'gpsAndTimeJoint-1000000.mat');
illPrior = load(priorPath);

c = linspace(0, pi/2, nbZenithBins*2+1); c = c(2:2:end);
illPrior = interp1(linspace(0, pi/2, size(illPrior.priorSunPositionDist, 1)), sum(illPrior.priorSunPositionDist, 2), c);
illPrior = repmat(illPrior(:), [1 nbAzimuthBins]); 

probSun = probSun .* illPrior;
probSun = probSun ./ sum(probSun(:));

%% Display some results
[nrows, ncols, ~] = size(img);
imgDims = [nrows ncols];

camZenith = pi/2-atan2(size(img,1)/2-horizonLine, focalLength);

% Display the individual and combined probability maps (as in Fig. 11 of
% the IJCV paper)
figure(1);
nrowsFig = 1; ncolsFig = 6;
axesId = 1;

axesId = displaySingleProbMap(axesId, skyData.probSun, focalLength, camZenith, ...
    imgDims, nbAzimuthBins, alignHistogram, [], nrowsFig, ncolsFig, 'Sky only');
axesId = displaySingleProbMap(axesId, shadowsData.probSun, focalLength, camZenith, ...
    imgDims, nbAzimuthBins, alignHistogram, pi/4, nrowsFig, ncolsFig, 'Shadows only');
axesId = displaySingleProbMap(axesId, wallsData.probSun, focalLength, camZenith, ...
    imgDims, nbAzimuthBins, alignHistogram, pi/4, nrowsFig, ncolsFig, 'Vertical surfaces only');
axesId = displaySingleProbMap(axesId, pedsData.probSun, focalLength, camZenith, ...
    imgDims, nbAzimuthBins, alignHistogram, pi/4, nrowsFig, ncolsFig, 'Pedestrians only');
axesId = displaySingleProbMap(axesId, illPrior, focalLength, camZenith, ...
    imgDims, [], [], [], nrowsFig, ncolsFig, 'Prior');
displaySingleProbMap(axesId, probSun, focalLength, camZenith, ...
    imgDims, nbAzimuthBins, alignHistogram, [], nrowsFig, ncolsFig, 'Combined');

% Find the maximum likelihood sun position, and insert a "virtual sun dial"
% in the image
[~,~,sunAzimuths] = angularHistogram([], nbAzimuthBins, alignHistogram);
[mlZenith, mlAzimuth] = getMLSun(probSun, sunAzimuths);

h = figure(2); clf;
imshow(img);
ax = get(h, 'CurrentAxes');

% draw horizon line
line([0 size(img,2)], horizonLine.*[1 1], 'Color', 'r', 'LineWidth', 3, 'LineStyle', '--', ...
    'Parent', ax);

% draw sun dial
drawSunDialFromSunPosition(img, [mlZenith mlAzimuth], horizonLine, focalLength, ...
    'CameraHeight', 1.2, 'StickHeight', 1, 'Axes', ax);

title('Inserted sun dial');
legend('Estimated horizon line');
