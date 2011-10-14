%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function trainShadowIlluminationPredictor
%  Trains P(sun | image boundary, boundary orientation).
% 
% Input parameters:
%
% Output parameters:
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trainShadowIlluminationPredictor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Initialization
setPath; 

shadowDbPath = fullfile(shadowsResultsPath, 'trainingDb');
shadowImagesPath = fullfile(shadowsResultsPath, 'trainingImages');
outputBasePath = fullfile(basePath, 'localIlluminationPredictors');

doSave = 0;
doDisplay = 1;

%% Load the shadow dataset
shadowDb = loadDatabaseFast(shadowDbPath, '', '', 0, 'Loading shadow dataset');

%% Find images which have the information we need
labeledImgInd = find(arrayfun(@(x) isfield(x.document, 'bndLabels') && isfield(x.document, 'manualLabeling') && isfield(x.document, 'spLabels'), shadowDb));
goodImgInfo = arrayfun(@(x) ~isfield(x.document.manualLabeling, 'isGood') || str2double(x.document.manualLabeling.isGood), shadowDb(labeledImgInd));
labeledImgInd = labeledImgInd(logical(goodImgInfo));

fprintf('Computing predictor with %d images...\n', length(labeledImgInd));

%% Gather boundary features and labels
sErrors = []; sLengths = [];
nsErrors = []; nsLengths = [];

for i=labeledImgInd(randperm(length(labeledImgInd)))
    fprintf('Image %d/%d...\n', find(i==labeledImgInd), length(labeledImgInd));
    imgInfo = shadowDb(i).document;
    
    % get sun and camera parameters
    sunAzimuth = str2double(imgInfo.manualLabeling.sunAzimuth);
    horizonLine = str2double(imgInfo.manualLabeling.horizonLine);
    if isfield(imgInfo.cameraParams, 'focalLength')
        focalLength = str2double(imgInfo.cameraParams.focalLength);
    else
        focalLength = str2double(imgInfo.image.size.width)*10/7;
    end
    cameraHeight = 1.6;
    u0 = str2double(imgInfo.image.size.width)/2;
    
    % load boundary labels and indices
    bndLblInfo = load(fullfile(shadowDbPath, imgInfo.bndLabels.filename));
    bndIndInfo = load(fullfile(shadowDbPath, imgInfo.(sprintf('wseg%d', bndLblInfo.segmentationParam)).filename));
    
    % keep all shadow boundaries
    shadowBoundaries = bndIndInfo.boundaries(logical(bndLblInfo.bndLabels));
    indBelowHorizon = cellfun(@(x) all(x(:,2) > horizonLine), shadowBoundaries);
    shadowBoundaries = shadowBoundaries(indBelowHorizon);
    
    % keep all non-shadow boundaries that lie below the horizon line (must be strong boundaries!)
    nonShadowBoundaries = bndIndInfo.boundaries(~logical(bndLblInfo.bndLabels));
    indBelowHorizon = cellfun(@(x) all(x(:,2) > horizonLine), nonShadowBoundaries);
    nonShadowBoundaries = nonShadowBoundaries(indBelowHorizon);
    
    img = im2double(imread(fullfile(shadowImagesPath, imgInfo.image.folder, imgInfo.image.filename)));
    imgEdges = zeros(size(img,1), size(img,2));
    sigmas = 2.^(0:3); cannyThresh = 0.3;
    for s=sigmas
        imgEdges = imgEdges + edge(rgb2gray(img), 'canny', cannyThresh, s);
    end
    imgEdges = imdilate(imgEdges>0, strel('disk', 3));
    
    indStrongBnd = getBoundaryIndicesFromEdges(nonShadowBoundaries, imgEdges, 'PctBoundaryLength', 0.75);
    nonShadowBoundaries = nonShadowBoundaries(indStrongBnd);
    
    % non-shadow boundaries must also be on the ground
    spLabelsInfo = load(fullfile(shadowDbPath, imgInfo.spLabels.filename));
    groundMask = imclose(ismember(spLabelsInfo.wseg, find(spLabelsInfo.segmentLabels==2)-1), strel('disk', 2));
    meanGroundProb = interpBoundarySubPixel(nonShadowBoundaries, groundMask);
    nonShadowBoundaries = nonShadowBoundaries(meanGroundProb > 0.5);
    
    % extract lines from shadow and non-shadow maps
    shadowLines = extractLinesFromBoundaries(img, shadowBoundaries);
    nonShadowLines = extractLinesFromBoundaries(img, nonShadowBoundaries);
    
    [sAngles, sLength] = computeAnglesFromShadowLines(shadowLines, focalLength, cameraHeight, horizonLine, size(img,2));
    [nsAngles, nsLength] = computeAnglesFromShadowLines(nonShadowLines, focalLength, cameraHeight, horizonLine, size(img,2));
    
    % normalize shadow lengths by image diagonal
    diagLength = sqrt(size(img,1)^2 + size(img,2)^2);
    sLength = sLength ./ diagLength;
    nsLength = nsLength ./ diagLength;
    
    % compute boundary angles
%     sBoundaryAngles = pi/2-computeBoundaryAngles(shadowBoundaries, horizonLine, focalLength, cameraHeight, u0);
%     nsBoundaryAngles = pi/2-computeBoundaryAngles(nonShadowBoundaries, horizonLine, focalLength, cameraHeight, u0);
    
    % save boundary length
%     sLength = cellfun(@(b) size(b,1), shadowBoundaries);
%     nsLength = cellfun(@(b) size(b,1), nonShadowBoundaries);
    
    % label = angular difference between sun and shadow
    sError = min(angularError(sAngles, sunAzimuth), angularError(sAngles+pi, sunAzimuth));
    nsError = min(angularError(nsAngles, sunAzimuth), angularError(nsAngles+pi, sunAzimuth));
    
    if doDisplay
        figure; subplot(1,3,1);
        imshow(img); hold on;
        plot(shadowLines(:, [1 2])', shadowLines(:, [3 4])', 'r', 'LineWidth', 3);
        plot(nonShadowLines(:, [1 2])', nonShadowLines(:, [3 4])', 'b', 'LineWidth', 3);

        subplot(1,3,2), plot(whistc(sError, sLength, linspace(0,pi/2,10)));
        if ~isempty(nsError)
            subplot(1,3,3), plot(whistc(nsError, nsLength, linspace(0,pi/2,10)));
        end
        set(gcf, 'Position', [33 595 1243 329]);
        pause; close all;
    end
    
    sErrors = cat(2, sErrors, sError(:)');
    nsErrors = cat(2, nsErrors, nsError(:)');
    
    sLengths = cat(2, sLengths, sLength(:)');
    nsLengths = cat(2, nsLengths, nsLength(:)');
end

%% Display results
if doDisplay
%     figure(1), hist(sErrors, 20), title('Shadows');
%     figure(2), hist(nsErrors, 20), title('Non-shadows');
    figure, x = linspace(0,pi/2-eps,25+1); y = histc(a.sErrors, x); y=y./sum(y); plot(linspace(0,pi/2,25), smooth(y(1:end-1), 'lowess')), axis([0 pi/2 0 0.1]);
    title('Shadows');
    figure, x = linspace(0,pi/2-eps,25+1); y = histc(a.nsErrors, x); y=y./sum(y); plot(linspace(0,pi/2,25), smooth(y(1:end-1), 'lowess')), axis([0 pi/2 0 0.1]);
    title('Non-shadows');
end

%% Save results
if doSave
    outputFile = fullfile(outputBasePath, 'shadowPredictorGtGroundMask74-nobad.mat');
    [m,m,m] = mkdir(fileparts(outputFile));
    
    % also save files on which this was computed
    save(outputFile, 'sErrors', 'nsErrors', 'sLengths', 'nsLengths', 'labeledImgInd');
end
