%% Setup
addpath ../;
setPath;

dbPath = fullfile(basePath, 'testDb');
imagesPath = fullfile(basePath, 'testImages');

typeName = 'SkyClassifEstimateHorizonVoteNonWeighted';
resultsPathName = 'testResultsViz';
resultsPath = fullfile(basePath, 'testResults', typeName);

outputBasePath = fullfile(basePath, 'ijcvFigs', 'imgWalls');

%% Load input image
imgFolder = 'static_outdoor_urban_city_street_boston';
imgFilename = 'IMG_6585.xml';

imgInfo = load_xml(fullfile(dbPath, imgFolder, imgFilename));
imgInfo = imgInfo.document;

geomContextInfo = load(fullfile(dbPath, imgInfo.geomContext.filename));
resultsInfo = load(fullfile(resultsPath, imgInfo.file.folder, strrep(imgInfo.file.filename, '.xml', '.mat')));
img = imread(fullfile(imagesPath, imgInfo.image.folder, imgInfo.image.filename));

%% Generate images for sky, ground, vertical surfaces
imgFacing = img;
imgFacing(repmat(geomContextInfo.wallFacing, [1 1 3])==0) = 0;

imgRight = img;
imgRight(repmat(geomContextInfo.wallRight, [1 1 3])==0) = 0;

imgLeft = img;
imgLeft(repmat(geomContextInfo.wallLeft, [1 1 3])==0) = 0;

%% Generate prob map for each vertical surface
focalLength = str2double(imgInfo.cameraParams.focalLength);
horizonLine = str2double(imgInfo.manualLabeling.horizonLine);
thetac = pi/2-atan2(size(img,1)/2-horizonLine, focalLength);

wallLeftProbSun = repmat(resultsInfo.allWallsProbSun(1,:), 5, 1);
wallFacingProbSun = repmat(resultsInfo.allWallsProbSun(2,:), 5, 1);
wallRightProbSun = repmat(resultsInfo.allWallsProbSun(3,:), 5, 1);

maxVal = max(resultsInfo.allWallsProbSun(:));

diplaySunProbAndError(wallLeftProbSun./maxVal, resultsInfo.sunAzimuths, focalLength, thetac, size(img), ...
    pi/4, 0, 'Walls', 'DisplayGtSun', 0, 'Normalize', 1);

diplaySunProbAndError(wallFacingProbSun./maxVal, resultsInfo.sunAzimuths, focalLength, thetac, size(img), ...
    pi/4, 0, 'Walls', 'DisplayGtSun', 0, 'Normalize', 1);

diplaySunProbAndError(wallRightProbSun./maxVal, resultsInfo.sunAzimuths, focalLength, thetac, size(img), ...
    pi/4, 0, 'Walls', 'DisplayGtSun', 0, 'Normalize', 1);

%% Save
[m,m,m] = mkdir(outputBasePath);
export_fig(fullfile(outputBasePath, 'leftProb.pdf'), '-painters', figure(1));
export_fig(fullfile(outputBasePath, 'facingProb.pdf'), '-painters', figure(2));
export_fig(fullfile(outputBasePath, 'rightProb.pdf'), '-painters', figure(3));


%% Save
[m,m,m] = mkdir(outputBasePath);
imwrite(img, fullfile(outputBasePath, 'img.jpg'), 'Quality', 100);
imwrite(imgLeft, fullfile(outputBasePath, 'left.jpg'), 'Quality', 100);
imwrite(imgFacing, fullfile(outputBasePath, 'facing.jpg'), 'Quality', 100);
imwrite(imgRight, fullfile(outputBasePath, 'right.jpg'), 'Quality', 100);