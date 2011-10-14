%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function trainSkyIlluminationPredictor
%  Trains P(sun | image (pixel or superpixel), (pixel or superpixel) color).
% 
% Input parameters:
%
% Output parameters:
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trainSkyIlluminationPredictor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Initialization
setPath; 

outputBasePath = fullfile(basePath, 'localIlluminationPredictors');
webcamDbPath = fullfile(outputBasePath, 'skyWebcamData.mat');

doSave = 1;

%% Load database
webcamDb = load(webcamDbPath);

%% Loop over all training images
skyErrors = [];
for i=1:length(webcamDb.imgPaths)
    % load image and sky mask
    img = im2double(imread(webcamDb.imgPaths{i}));
    skyMask = im2double(imread(webcamDb.imgSkyMaskPaths{i}))>0.5;
    skyMask(floor(webcamDb.imgHorizonLines(i))-2:end,:) = 0;
    
    % use gamma = 2.2
    gamma = 2.2;
    invRespFunction = repmat(linspace(0,1,1000)', 1, 3).^gamma;
    img = correctImage(img, invRespFunction, skyMask);
    
    imgxyY = rgb2xyY(img);
    [up, vp, lp] = getFullSkyInfo(skyMask, imgxyY, img, 1);
    
    f = webcamDb.imgFocalLengths(i);
    yh = size(img,1)/2-webcamDb.imgHorizonLines(i);
    phiCam = webcamDb.imgCamAzimuths(i);
    phiSun = webcamDb.imgSunAzimuths(i);
    thetaSun = webcamDb.imgSunZeniths(i);
    
    % randomly sample up, vp, and lp
    randInd = randperm(length(up));
    nbPixelsToKeep = min(10000, length(up));
    up = up(randInd(1:nbPixelsToKeep));
    vp = vp(randInd(1:nbPixelsToKeep));
    lp = lp(randInd(1:nbPixelsToKeep),:);
    
    % fit optimal k
    kOpt = fitLuminance(up, vp, lp, f, yh, phiCam, phiSun, thetaSun);
    
    % compute difference between predicted and actual sky intensity
    t = 2.17; % clear sky
    skyParams = getTurbidityMapping(3)*[t 1]';
    a = skyParams(1); b = skyParams(2); c = skyParams(3); d = skyParams(4); e = skyParams(5);
    
    predictedSky = exactSkyModelRatio(a, b, c, d, e, f, up, vp, yh, kOpt, phiCam, phiSun, thetaSun);
    curSkyErrors = predictedSky - lp(:,3);
    
    % randomly select 1000 points from there
    randInd = randperm(length(curSkyErrors));
    curSkyErrors = curSkyErrors(randInd(1:1000));
    
    skyErrors = cat(1, skyErrors, curSkyErrors);
end

%% Save data
if doSave
    outputFile = fullfile(outputBasePath, 'skyPredictor.mat');
    files = webcamDb.imgPaths;
    save(outputFile, 'skyErrors', 'files');
end