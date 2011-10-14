%% Setup
addpath ../;
setPath;

dbPath = fullfile(basePath, 'testDb');
imagesPath = fullfile(basePath, 'testImages');

typeName = 'SkyClassifEstimateHorizonVoteNonWeighted';
resultsPathName = 'testResultsViz';

resultsPath = fullfile(basePath, 'testResults', typeName);
outputBasePath = fullfile(basePath, 'testResultsVizNN');

%% Prior
priorPath = fullfile(singleImageResultsPath, 'illuminationPriors', 'sunPosition', 'gpsAndTimeJoint-1000000.mat');
illPrior = load(priorPath);
c = linspace(0, pi/2, 5*2+1); c = c(2:2:end);
illPrior = interp1(linspace(0, pi/2, size(illPrior.priorSunPositionDist, 1)), sum(illPrior.priorSunPositionDist, 2), c);
illPrior = repmat(illPrior(:), [1 32]); 

%% Load database
imgDb = loadDatabaseFast(dbPath, '', '', 1);

%% Load input image
imgFolder = 'static_park_outdoor_boston';
imgFilename = 'IMG_0894.jpg';
imgInd = find(arrayfun(@(i) strcmp(i.document.image.folder, imgFolder) & strcmp(i.document.image.filename, imgFilename), imgDb));
imgInfo = imgDb(imgInd).document;

illContextInfo = load(fullfile(dbPath, imgInfo.illContext.filename));
newInfo = load(fullfile(resultsPath, imgInfo.image.folder, strrep(imgInfo.image.filename, '.jpg', '.mat')));
    
[mlZenith, mlAzimuth] = getMLSun(newInfo.probSun .* illPrior, newInfo.sunAzimuths);
    
%% Compute distances
illContextDist = zeros(1, length(imgDb));
newDist = zeros(1, length(imgDb));

alphaZe = 0.1; alphaAz = 1;

for i=1:length(imgDb)
    curImgInfo = imgDb(i).document;
    
    % compute illumination context distance
    curIllContextInfo = load(fullfile(dbPath, curImgInfo.illContext.filename));
    illContextDist(i) = chisq(illContextInfo.histoSky, curIllContextInfo.histoSky) + ...
        chisq(illContextInfo.histoGround, curIllContextInfo.histoGround);
    
    % compute angular distance in sun orientation
    curNewInfo = load(fullfile(resultsPath, curImgInfo.image.folder, strrep(curImgInfo.image.filename, '.jpg', '.mat')));
    
    [curMlZenith, curMlAzimuth] = getMLSun(curNewInfo.probSun .* illPrior, curNewInfo.sunAzimuths);
    newDist(i) = alphaZe*angularError(mlZenith, curMlZenith) + alphaAz*angularError(mlAzimuth, curMlAzimuth);
end

%% Retrieve nearest neighbors
[s,sindIllContext] = sort(illContextDist);
[s,sindNew] = sort(newDist);

%% Save as symbolic links
sindType = {sindIllContext, sindNew};
sType = {'illContext', 'new'};

for s=1:2
    outputPath = fullfile(outputBasePath, sprintf('%s-%s', imgFolder, imgFilename), sType{s});
    [m,m,m] = mkdir(outputPath);
    for i=1:50
        curInd = sindType{s}(i);
        srcPath = fullfile('..', '..', '..', resultsPathName, typeName, sprintf('%s-%s', imgDb(curInd).document.file.folder, strrep(imgDb(curInd).document.file.filename, '.xml', '')));
        linkName = fullfile(outputPath, sprintf('%04d', i));
        cmd = sprintf('ln -s %s %s', srcPath, linkName);
        system(cmd);
    end
end