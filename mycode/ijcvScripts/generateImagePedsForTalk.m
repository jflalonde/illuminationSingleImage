%% Setup
addpath ../;
setPath;

dbPath = fullfile(basePath, 'testDb');
imagesPath = fullfile(basePath, 'testImages');

typeName = 'SkyClassifEstimateHorizonVoteNonWeighted';
resultsPathName = 'testResultsViz';
resultsPath = fullfile(basePath, 'testResults', typeName);

outputBasePath = fullfile(basePath, 'ijcvFigs', 'imgPeds');

%% Load input image
imgFolder = 'april21_static_outdoor_kendall';
imgFilename = 'img_1006.xml';

imgInfo = load_xml(fullfile(dbPath, imgFolder, imgFilename));
imgInfo = imgInfo.document;

geomContextInfo = load(fullfile(dbPath, imgInfo.geomContext.filename));
resultsInfo = load(fullfile(resultsPath, imgInfo.file.folder, strrep(imgInfo.file.filename, '.xml', '.mat')));
detInfo = load(fullfile(dbPath, imgInfo.detObjects.person.filename));
img = imread(fullfile(imagesPath, imgInfo.image.folder, imgInfo.image.filename));

%% Generate prob map for each pedestrian surface
focalLength = str2double(imgInfo.cameraParams.focalLength);
horizonLine = str2double(imgInfo.manualLabeling.horizonLine);
thetac = pi/2-atan2(size(img,1)/2-horizonLine, focalLength);

ped1ProbSun = repmat(resultsInfo.allPedsProbSun(1,:), 5, 1);
ped2ProbSun = repmat(resultsInfo.allPedsProbSun(2,:), 5, 1);

maxVal = max(resultsInfo.allPedsProbSun(:));

diplaySunProbAndError(ped1ProbSun./maxVal, resultsInfo.sunAzimuths, focalLength, thetac, size(img), ...
    pi/4, 0, 'Peds', 'DisplayGtSun', 0, 'Normalize', 1);

diplaySunProbAndError(ped2ProbSun./maxVal, resultsInfo.sunAzimuths, focalLength, thetac, size(img), ...
    pi/4, 0, 'Peds', 'DisplayGtSun', 0, 'Normalize', 1);

%% Save
[m,m,m] = mkdir(outputBasePath);
export_fig(fullfile(outputBasePath, 'ped1.pdf'), '-painters', figure(1));
export_fig(fullfile(outputBasePath, 'ped2.pdf'), '-painters', figure(2));


%% Save
[m,m,m] = mkdir(outputBasePath);
imwrite(img, fullfile(outputBasePath, 'img.jpg'), 'Quality', 100);
imwrite(imgLeft, fullfile(outputBasePath, 'left.jpg'), 'Quality', 100);
imwrite(imgFacing, fullfile(outputBasePath, 'facing.jpg'), 'Quality', 100);
imwrite(imgRight, fullfile(outputBasePath, 'right.jpg'), 'Quality', 100);