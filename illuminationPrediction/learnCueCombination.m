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
function learnCueCombination
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup
addpath ../;
setPath;

dbPath = fullfile(basePath, 'testDb');
% imagesPath = fullfile(basePath, 'trainImages');
outputPath = fullfile(basePath, 'localIlluminationPredictors', 'combination');
outputPathViz = fullfile(basePath, 'testResultsViz', 'combination', 'testSet');
doSave = 0;

typeName = 'SkyClassifEstimateHorizonVoteNonWeighted';
resultsPath = fullfile(basePath, 'testResults', typeName);

%% Load files
[files, directories] = getFilesFromDirectory(resultsPath, '', '', '', '.mat', 1);
% files = files(1:10);

%% 
nbMaxima = 2;
wallErrors = zeros(length(files), nbMaxima);
shadowErrors = zeros(length(files), nbMaxima);
pedsErrors = zeros(length(files), nbMaxima);
skyErrors = zeros(length(files), nbMaxima);

skyArea = zeros(length(files), 1);
wallsArea = zeros(length(files), 3);
nbPeds = zeros(length(files), 1);
nbShadowLines = zeros(length(files), 1);

for f=1:length(files)
    imgInfo = load_xml(fullfile(dbPath, directories{f}, strrep(files{f}, '.mat', '.xml')));
    imgInfo = imgInfo.document;
    
    gtSunAzimuth = str2double(imgInfo.manualLabeling.sunAzimuth);
    resultsData = load(fullfile(resultsPath, directories{f}, files{f}));
    
    wallErrors(f,:) = computeEstimationError(resultsData.wallsProbSun, resultsData.sunAzimuths, gtSunAzimuth, nbMaxima);
    shadowErrors(f,:) = computeEstimationError(resultsData.shadowsProbSun, resultsData.sunAzimuths, gtSunAzimuth, nbMaxima);
    pedsErrors(f,:) = computeEstimationError(resultsData.pedsProbSun, resultsData.sunAzimuths, gtSunAzimuth, nbMaxima);
    skyErrors(f,:) = computeEstimationError(resultsData.skyProbSun, resultsData.sunAzimuths, gtSunAzimuth, nbMaxima);
    
    skyArea(f) = resultsData.skyArea;
    wallsArea(f,:) = resultsData.wallsArea;
    nbPeds(f) = resultsData.nbPeds;
    nbShadowLines(f) = size(resultsData.shadowLines, 1);
end
    
validWallErrors = wallErrors(all(wallErrors>-1, 2),:);
validShadowErrors = shadowErrors(all(shadowErrors>-1, 2),:);
validPedsErrors = pedsErrors(all(pedsErrors>-1, 2),:);
validSkyErrors = skyErrors(all(skyErrors>-1, 2),:);

%% Compute mapping between features and illumination prediction error

%% Test: shadows
figure;
validShadowsInd = find(nbShadowLines>1);
plot(nbShadowLines(validShadowsInd), 1-min(shadowErrors(validShadowsInd, :), [], 2)/pi, 'o', 'MarkerSize', 5, 'LineWidth', 1);
plot(nbShadowLines(validShadowsInd), min(shadowErrors(validShadowsInd, :), [], 2)*180/pi, 'o', 'MarkerSize', 5, 'LineWidth', 1);
hold on;

% p=polyfit(nbShadowLines(validShadowsInd), 1-min(shadowErrors(validShadowsInd, :), [], 2)/pi, 1);
% x=linspace(1,60,50); plot(x, polyval(p, x), '-');
x = nbShadowLines(validShadowsInd);
% y = 1-min(shadowErrors(validShadowsInd, :), [], 2)/pi;
y = min(shadowErrors(validShadowsInd, :), [], 2)*180/pi;
p=robustfit(x, y);

x1=linspace(1,60,50); plot(x1, p(1)+p(2)*x1, '-', 'LineWidth', 3);

% axis([0 40 0.5 1]);

xlabel('Number of shadow lines');
ylabel('1-error');
legend('Training data', 'Linear fit (robust)', 'Location', 'SouthEast');
grid on; 

if doSave
	set(gca, 'LineWidth', 1);
    set(gcf, 'Color', 'none');
    export_fig(fullfile(outputPathViz, 'shadows.pdf'), '-painters', gcf);
    lims = [1 40];
    save(fullfile(outputPath, 'shadows.mat'), 'p', 'x', 'y', 'lims');
end
    

%% Test: pedestrians
figure;
validPedsInd = find(nbPeds>0);
% plot(nbPeds(validPedsInd), 1-pedsErrors(validPedsInd,1)/pi, 'o', 'MarkerSize', 5, 'LineWidth', 1);
plot(nbPeds(validPedsInd), pedsErrors(validPedsInd,1)*180/pi, 'o', 'MarkerSize', 5, 'LineWidth', 1);

hold on;
% p=polyfit(nbPeds(validPedsInd), 1-pedsErrors(validPedsInd,1)/pi, 1);
% x=linspace(1,6,50); plot(x, polyval(p, x), '-');
% p=robustfit(nbPeds(validPedsInd), 1-pedsErrors(validPedsInd,1)/pi);
% p=robustfit(nbPeds(validPedsInd), log(pedsErrors(validPedsInd,1)*180/pi));
p=robustfit(nbPeds(validPedsInd), pedsErrors(validPedsInd,1)*180/pi);

x = nbPeds(validPedsInd);
y = pedsErrors(validPedsInd,1)*180/pi;
p2=nlinfit(x, y, @(p,x) p(1)*exp(p(2)*x), [1 1]);

xp=1:8; 
% yp = p2(1)*exp(p2(2)*xp);
yp = p(1)+p(2)*xp;
plot(xp, yp, '-', 'LineWidth', 3);

% axis([0 7 0 1]);

xlabel('Number of detected pedestrians');
ylabel('1-error');
legend('Training data', 'Linear fit (robust)', 'Location', 'SouthEast');
grid on;

if doSave
	set(gca, 'LineWidth', 1);
    set(gcf, 'Color', 'none');
    export_fig(fullfile(outputPathViz, 'peds.pdf'), '-painters', gcf);
    lims = [1 7];
    x = nbPeds(validPedsInd);
    y = 1-pedsErrors(validPedsInd,1)/pi;
    save(fullfile(outputPath, 'peds.mat'), 'p', 'x', 'y', 'lims');
end


%% Test: walls
figure;
totWallsArea = sum(wallsArea, 2);
validWallsInd = find(totWallsArea>0 & totWallsArea<1);

plot(totWallsArea(validWallsInd), 1-wallErrors(validWallsInd, 1)/pi, 'o', 'MarkerSize', 5, 'LineWidth', 1);
hold on;

% p=polyfit(totWallsArea(validWallsInd), 1-wallErrors(validWallsInd, 1)/pi, 1);
% x=linspace(0,1,50); plot(x, polyval(p, x), '-');
p=robustfit(totWallsArea(validWallsInd), 1-wallErrors(validWallsInd, 1)/pi);
x=linspace(0,1,50); plot(x, p(1)+p(2)*x, '-', 'LineWidth', 3);

xlabel('% of image taken by walls');
ylabel('1-error');
legend('Training data', 'Linear fit (robust)', 'Location', 'SouthEast');
grid on;

if doSave
	set(gca, 'LineWidth', 1);
    set(gcf, 'Color', 'none');
    export_fig(fullfile(outputPathViz, 'walls.pdf'), '-painters', gcf);
    lims = [0 1];
    x = totWallsArea(validWallsInd);
    y = 1-wallErrors(validWallsInd, 1)/pi;
    save(fullfile(outputPath, 'walls.mat'), 'p', 'x', 'y', 'lims');
end


%% Test: sky
figure;
validSkyInd = find(all(skyErrors>-1, 2) & skyArea<1);
plot(skyArea(validSkyInd), 1-skyErrors(validSkyInd, 1)/pi, 'o', 'MarkerSize', 5, 'LineWidth', 1);
hold on;

% p=polyfit(skyArea(validSkyInd), 1-skyErrors(validSkyInd, 1)/pi, 1);
% x=linspace(0,1,50); plot(x, polyval(p, x), '-');
p=robustfit(skyArea(validSkyInd), 1-skyErrors(validSkyInd, 1)/pi);
x=linspace(0,1,50); plot(x, p(1)+p(2)*x, '-', 'LineWidth', 3);

axis([0 0.7 0 1]);

xlabel('% of image taken by sky'); 
ylabel('1-error');
legend('Training data', 'Linear fit (robust)', 'Location', 'SouthEast');
grid on;

if doSave
	set(gca, 'LineWidth', 1);
    set(gcf, 'Color', 'none');
    export_fig(fullfile(outputPathViz, 'sky.pdf'), '-painters', gcf);
    lims = [0 1];
    x = skyArea(validSkyInd);
    y = 1-skyErrors(validSkyInd, 1)/pi;
    save(fullfile(outputPath, 'sky.mat'), 'p', 'x', 'y', 'lims');
end
