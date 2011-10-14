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
function evaluateIlluminationEstimation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup
addpath ../;
setPath;

dbPath = fullfile(basePath, 'testDb');
imagesPath = fullfile(basePath, 'testImages');
combPath = fullfile(basePath, 'localIlluminationPredictors', 'combination');
typeName = 'SkyClassifEstimateHorizonVoteNonWeighted';
doSave = 1;
outputPath = fullfile(basePath, 'testResultsViz');
resultsPath = fullfile(basePath, 'testResults', typeName);

%% Load files and results
[files, directories] = getFilesFromDirectory(resultsPath, '', '', '', '.mat', 1);
resultsData = cellfun(@(f,d) load(fullfile(resultsPath, d, f) ), files, directories, 'UniformOutput', 0);

%% Load database
testDb = loadDatabaseFast(dbPath, '', '', 1);
% files = files(1:10);

%% Load combination parameters
skyCombParams = load(fullfile(combPath, 'sky.mat'));
shadowsCombParams = load(fullfile(combPath, 'shadows.mat'));
wallsCombParams = load(fullfile(combPath, 'walls.mat'));
pedsCombParams = load(fullfile(combPath, 'peds.mat'));

%% Load prior
priorPath = fullfile(singleImageResultsPath, 'illuminationPriors', 'sunPosition', 'gpsAndTimeJoint-1000000.mat');
illPrior = load(priorPath);
c = linspace(0, pi/2, 5*2+1); c = c(2:2:end);
illPrior = interp1(linspace(0, pi/2, size(illPrior.priorSunPositionDist, 1)), sum(illPrior.priorSunPositionDist, 2), c);
illPrior = repmat(illPrior(:), [1 32]); illPrior = illPrior./sum(illPrior(:));

%% 
nbMaxima = 2;
doDisplay = 0;

% cue combination
multErrors = -ones(length(files), nbMaxima);
voteErrors = -ones(length(files), nbMaxima);
weightedMultErrors = -ones(length(files), nbMaxima);
weightedVoteErrors = -ones(length(files), nbMaxima);

% independent cues
wallErrors = -ones(length(files), nbMaxima);
shadowErrors = -ones(length(files), nbMaxima);
pedsErrors = -ones(length(files), nbMaxima);
skyErrors = -ones(length(files), nbMaxima);

% features for weighting
skyAreas = zeros(length(files), 1);
nbPeds = zeros(length(files), 1);
wallsAreas = zeros(length(files), 1);
nbShadowLines = zeros(length(files), 1);

for f=randperm(length(testDb))%1:length(files)
    imgInfo = testDb(f).document;
    resultsInd = find(strcmp(directories, imgInfo.image.folder) & strcmp(files, strrep(imgInfo.image.filename, '.jpg', '.mat')));
    
    if isempty(resultsInd)
        continue;
    end
    
    curResultsData = resultsData{resultsInd};
        
    gtSunAzimuth = str2double(imgInfo.manualLabeling.sunAzimuth);
    
    wallErrors(f,:) = computeEstimationError(curResultsData.wallsProbSun, curResultsData.sunAzimuths, gtSunAzimuth, nbMaxima);
    shadowErrors(f,:) = computeEstimationError(curResultsData.shadowsProbSun, curResultsData.sunAzimuths, gtSunAzimuth, nbMaxima);
    pedsErrors(f,:) = computeEstimationError(curResultsData.pedsProbSun, curResultsData.sunAzimuths, gtSunAzimuth, nbMaxima);
    skyErrors(f,:) = computeEstimationError(curResultsData.skyProbSun, curResultsData.sunAzimuths, gtSunAzimuth, nbMaxima, 'EstimateJoint', 1);
    
    % try cue combination
    probSunMult = combineCues('mult', curResultsData.shadowsProbSun, curResultsData.wallsProbSun, ...
        curResultsData.pedsProbSun, curResultsData.skyProbSun, illPrior);
    multErrors(f,:) = computeEstimationError(probSunMult, curResultsData.sunAzimuths, gtSunAzimuth, nbMaxima);
    probSunVote = combineCues('vote', curResultsData.shadowsProbSun, curResultsData.wallsProbSun, ...
        curResultsData.pedsProbSun, curResultsData.skyProbSun, illPrior);
    voteErrors(f,:) = computeEstimationError(probSunVote, curResultsData.sunAzimuths, gtSunAzimuth, nbMaxima);
    
    % load features for weighting
    skyAreas(f) = curResultsData.skyArea .* (skyErrors(f,1)>-1);
    nbShadowLines(f) = size(curResultsData.shadowLines, 1) .* (all(shadowErrors(f,:), 2)>-1);
    wallsAreas(f) = sum(curResultsData.wallsArea) .* (wallErrors(f,1)>-1);
    nbPeds(f) = curResultsData.nbPeds .* (pedsErrors(f,1)>-1);
        
    % weighted mult
    probSunWeightedMult = combineCues('weightedMult', curResultsData.shadowsProbSun, ...
        curResultsData.wallsProbSun, curResultsData.pedsProbSun, curResultsData.skyProbSun, illPrior, ...
        'SkyParams', skyCombParams.p, 'SkyLims', skyCombParams.lims, 'SkyVal', skyAreas(f), ...
        'ShadowsParams', shadowsCombParams.p, 'ShadowsLims', shadowsCombParams.lims, 'ShadowsVal', nbShadowLines(f), ...
        'WallsParams', wallsCombParams.p, 'WallsLims', wallsCombParams.lims, 'WallsVal', wallsAreas(f), ...
        'PedsParams', pedsCombParams.p, 'PedsLims', pedsCombParams.lims, 'PedsVal', nbPeds(f));
    weightedMultErrors(f,:) = computeEstimationError(probSunWeightedMult, curResultsData.sunAzimuths, gtSunAzimuth, nbMaxima);

    % weighted vote
    probSunWeightedVote = combineCues('weightedVote', curResultsData.shadowsProbSun, curResultsData.wallsProbSun, ...
        curResultsData.pedsProbSun, curResultsData.skyProbSun, illPrior, ...
        'SkyParams', skyCombParams.p, 'SkyLims', skyCombParams.lims, 'SkyVal', skyAreas(f), ...
        'ShadowsParams', shadowsCombParams.p, 'ShadowsLims', shadowsCombParams.lims, 'ShadowsVal', nbShadowLines(f), ...
        'WallsParams', wallsCombParams.p, 'WallsLims', wallsCombParams.lims, 'WallsVal', wallsAreas(f), ...
        'PedsParams', pedsCombParams.p, 'PedsLims', pedsCombParams.lims, 'PedsVal', nbPeds(f));
    weightedVoteErrors(f,:) = computeEstimationError(probSunWeightedVote, curResultsData.sunAzimuths, gtSunAzimuth, nbMaxima);
    
    fprintf('%s\n', fullfile(imgInfo.image.folder, imgInfo.image.filename));

    if doDisplay
        figure(1);
        plot(curResultsData.sunAzimuths*180/pi, [sum(curResultsData.shadowsProbSun, 1); sum(curResultsData.wallsProbSun, 1); sum(curResultsData.pedsProbSun, 1); sum(probSunWeightedMult, 1)]'); title(sprintf('%.2f, %.2f, %.2f', gtSunAzimuth*180/pi, wallErrors(f,1)*180/pi, weightedMultErrors(f,1)*180/pi));
        legend('Shadows', 'Walls', 'Peds', 'WMult', 'Location', 'NorthOutside');
        set(gcf, 'Position', [36 324 560 611]);
        
        figure(2);
        imshow(fullfile(imagesPath, imgInfo.image.folder, imgInfo.image.filename));
        set(gcf, 'Position', [705 439 512 384]);
        pause;
    end
    
end
    
validWallErrors = wallErrors(all(wallErrors>-1, 2),:);
validShadowErrors = shadowErrors(all(shadowErrors>-1, 2),:);
validPedsErrors = pedsErrors(all(pedsErrors>-1, 2),:);
validSkyErrors = skyErrors(all(skyErrors>-1, 2),:);

assert(all(~any(multErrors==-1)));

%% How often are each feature useful
fprintf('Walls: %.2f%%\n', nnz(all(wallErrors>-1, 2))/size(wallErrors,1)*100);
fprintf('Shadows: %.2f%%\n', nnz(all(shadowErrors>-1, 2))/size(shadowErrors,1)*100);
fprintf('Pedestrians: %.2f%%\n', nnz(all(pedsErrors>-1, 2))/size(pedsErrors,1)*100);
fprintf('Sky: %.2f%%\n', nnz(all(skyErrors>-1, 2))/size(skyErrors,1)*100);

%% Display cumulative histograms for first peak, best of both peaks
nbBins = 100;
figure(1);
subplot(2,2,1); pctImages = displayCumulError(validWallErrors(:,1), nbBins, [22.5 45 90], 1, 1, 'LineWidth', 3); title(sprintf('Walls (%.1f %.1f %.1f)', pctImages(1)*100, pctImages(2)*100, pctImages(3)*100));
subplot(2,2,2); pctImages = displayCumulError(validPedsErrors(:,1), nbBins, [22.5 45 90], 1, 1, 'LineWidth', 3); title(sprintf('Pedestrians (%.1f %.1f %.1f)', pctImages(1)*100, pctImages(2)*100, pctImages(3)*100));
subplot(2,2,3); pctImages = displayCumulError(validSkyErrors(:,1), nbBins, [22.5 45 90], 1, 1, 'LineWidth', 3); title(sprintf('Sky (%.1f %.1f %.1f)', pctImages(1)*100, pctImages(2)*100, pctImages(3)*100));
subplot(2,2,4); pctImages = displayCumulError(min(validShadowErrors, [], 2), nbBins, [22.5 45 90], 1, 1, 'LineWidth', 3); title(sprintf('Shadows (%.1f %.1f %.1f)', pctImages(1)*100, pctImages(2)*100, pctImages(3)*100));
set(gcf, 'Position', [5 30 1272 905]);

figure(2);
subplot(2,2,1); pctImages = displayCumulError(multErrors(:,1), nbBins, [22.5 45 90], 1, 1, 'LineWidth', 3); title(sprintf('Mult (%.1f %.1f %.1f)', pctImages(1)*100, pctImages(2)*100, pctImages(3)*100));
subplot(2,2,2); pctImages = displayCumulError(voteErrors(:,1), nbBins, [22.5 45 90], 1, 1, 'LineWidth', 3); title(sprintf('Vote (%.1f %.1f %.1f)', pctImages(1)*100, pctImages(2)*100, pctImages(3)*100));
subplot(2,2,3); pctImages = displayCumulError(weightedMultErrors(:,1), nbBins, [22.5 45 90], 1, 1, 'LineWidth', 3); title(sprintf('Weighted Mult (%.1f %.1f %.1f)', pctImages(1)*100, pctImages(2)*100, pctImages(3)*100));
subplot(2,2,4); pctImages = displayCumulError(weightedVoteErrors(:,1), nbBins, [22.5 45 90], 1, 1, 'LineWidth', 3); title(sprintf('Weighted Vote (%.1f %.1f %.1f)', pctImages(1)*100, pctImages(2)*100, pctImages(3)*100));
set(gcf, 'Position', [5 30 1272 905]);

%% Save
if doSave
    export_fig(figure(1), fullfile(outputPath, sprintf('%s-1.pdf', typeName)));
    export_fig(figure(2), fullfile(outputPath, sprintf('%s-2.pdf', typeName)));
    save(fullfile(outputPath, sprintf('%s.mat', typeName)), 'multErrors', 'voteErrors', 'wallErrors', 'pedsErrors', 'skyErrors', 'shadowErrors', 'files', 'directories');
end