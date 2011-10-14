%% Setup
addpath ../;
setPath;

dbPath = fullfile(basePath, 'testDb');
imagesPath = fullfile(basePath, 'testImages');

typeName = 'SkyClassifEstimateHorizonVoteNonWeighted';
resultsPathName = 'testResultsViz';
resultsPath = fullfile(basePath, 'testResults', typeName);

outputBasePath = fullfile(basePath, 'ijcvFigs', 'imgConfidence');
[m,m,m] = mkdir(outputBasePath);

%% Prior
priorPath = fullfile(singleImageResultsPath, 'illuminationPriors', 'sunPosition', 'gpsAndTimeJoint-1000000.mat');
illPrior = load(priorPath);
c = linspace(0, pi/2, 5*2+1); c = c(2:2:end);
illPrior = interp1(linspace(0, pi/2, size(illPrior.priorSunPositionDist, 1)), sum(illPrior.priorSunPositionDist, 2), c);
illPrior = repmat(illPrior(:), [1 32]); 

%% Load input image
imgFolders = {'static_outdoor_street_city_cambridge_uk', 'static_outdoor_street_city_cambridge_uk', 'static_park_outdoor_boston', 'static_outdoor_urban_city_street_boston', 'static_boston_street_april', 'static_outdoor_street_city_cambridge_uk', 'static_boston_street_april', 'nov7_static_outdoor'};
imgFilenames = {'IMG_8830.xml', 'IMG_8964.xml', 'IMG_0877.xml', 'IMG_6485.xml', 'p1010081.xml', 'IMG_8821.xml', 'p1010241.xml', 'img_0600.xml'};

allProbSun = [];
allImg = {};
allFocal = [];
allHorizon = [];
allThetac = [];

for f=1:length(imgFilenames)
    imgInfo = load_xml(fullfile(dbPath, imgFolders{f}, imgFilenames{f}));
    imgInfo = imgInfo.document;
    
    resultsInfo = load(fullfile(resultsPath, imgInfo.file.folder, strrep(imgInfo.file.filename, '.xml', '.mat')));
    img = imread(fullfile(imagesPath, imgInfo.image.folder, imgInfo.image.filename));

    curProbSun = resultsInfo.probSun.*illPrior;
    curProbSun = curProbSun./sum(curProbSun(:));
    
    allProbSun = cat(3, allProbSun, curProbSun);
    allImg = cat(1, allImg, img);
    allFocal = cat(2, allFocal, str2double(imgInfo.cameraParams.focalLength));
    allHorizon = cat(2, allHorizon, str2double(imgInfo.manualLabeling.horizonLine));
    allThetac = cat(2, allThetac, pi/2-atan2(size(img,1)/2-allHorizon(f), allFocal(f)));
    
end

%% Compute normalization
maxVal = max(allProbSun(:));

for f=1:length(imgFilenames)
    
    curProbSun = allProbSun(:,:,f)./maxVal;
    [mlZenith, mlAzimuth] = getMLSun(curProbSun, resultsInfo.sunAzimuths);
    
    displaySunProbabilityVectorized(curProbSun, 1, ...
        'DrawCameraFrame', 1, 'FocalLength', allFocal(f), 'CamZenith', allThetac(f), ...
        'ImgDims', size(allImg{f}), 'Normalize', 1, ...
        'EstSunZenith', mlZenith, 'EstSunAzimuth', mlAzimuth);
    
    export_fig(fullfile(outputBasePath, sprintf('img_%d.pdf', f)), '-painters', gcf);
    
    sunDialPosition = [size(allImg{f},2)/2, allHorizon(f) + 3*(size(allImg{f},1)-allHorizon(f))/4];
    drawSunDialFromSunPosition(allImg{f}, [mlZenith, mlAzimuth], allHorizon(f), allFocal(f), ...
        'StickPosition', sunDialPosition);
    
    export_fig(fullfile(outputBasePath, sprintf('imgStick_%d.pdf', f)), '-painters', '-native', gcf);
    
    imwrite(allImg{f}, fullfile(outputBasePath, sprintf('imgOrig_%d.jpg', f)), 'Quality', 100);
end
    
    