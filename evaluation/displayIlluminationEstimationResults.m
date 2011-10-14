%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function displayIlluminationEstimationResults
%  Creates a visualization of the illumination estimation results.
%  
% 
% Input parameters:
%
% Output parameters:
%   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function displayIlluminationEstimationResults
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup
addpath ../;
setPath;

%% Setup
addpath ../;
setPath;

dbPath = fullfile(basePath, 'testDb');
imagesPath = fullfile(basePath, 'testImages');

typeName = 'SkyClassifEstimateHorizonVoteNonWeighted';
resultsPath = fullfile(basePath, 'testResults', typeName);
outputBasePath = fullfile(basePath, 'testResultsViz', typeName);

priorPath = fullfile(singleImageResultsPath, 'illuminationPriors', 'sunPosition', 'gpsAndTimeJoint-1000000.mat');
illPrior = load(priorPath);
c = linspace(0, pi/2, 5*2+1); c = c(2:2:end);
illPrior = interp1(linspace(0, pi/2, size(illPrior.priorSunPositionDist, 1)), sum(illPrior.priorSunPositionDist, 2), c);

alignHistogram = 1;
normalize = 1;

doSave = 1;
displayAll = 0;
displayAllPrior = 1;
displayShadows = 1;
displayWalls = 1;
displayPedestrians = 1;
displaySky = 1;

%% Call the database
dbFn = @dbFnDisplayIlluminationEstimationResults;
parallelized = 0;
randomized = 0;
[files, directories] = getFilesFromDirectory(dbPath, '', '', '', '.xml', 1);

ind = strcmp(files, 'IMG_8966.xml') & strcmp(directories, 'static_outdoor_street_city_cambridge_uk');

processResultsDatabaseFiles(dbPath, files, directories, outputBasePath, dbFn, parallelized, randomized, ...
    'ImagesPath', imagesPath, 'DbPath', dbPath, 'ResultsPath', resultsPath, ...
    'AlignHistogram', alignHistogram, 'Normalize', normalize, 'DoSave', doSave, ...
    'DisplayAll', displayAll, 'DisplayAllPrior', displayAllPrior, 'DisplayShadows', displayShadows, 'DisplayWalls', displayWalls, ...
    'DisplayPedestrians', displayPedestrians, 'DisplaySky', displaySky, ...
    'IllPrior', illPrior);

%%
function ret = dbFnDisplayIlluminationEstimationResults(outputBasePath, imgInfo, varargin)
ret = 0;

% parse arguments
defaultArgs = struct('ImagesPath', [], 'DbPath', [], 'ResultsPath', [], ...
    'AlignHistogram', 0, 'Normalize', 0, ...
    'DoSave', 0, ...
    'DisplayAll', 0, 'DisplayAllPrior', 0, 'DisplayShadows', 0, 'DisplayWalls', 0, 'DisplayPedestrians', 0, 'DisplaySky', 0, ...
    'IllPrior', []);
args = parseargs(defaultArgs, varargin{:});

%% Load common image information
img = im2double(imread(fullfile(args.ImagesPath, imgInfo.image.folder, imgInfo.image.filename)));
resultsInfo = load(fullfile(args.ResultsPath, imgInfo.file.folder, strrep(imgInfo.file.filename, '.xml', '.mat')));
geomContextInfo = load(fullfile(args.DbPath, imgInfo.geomContext.filename));

focalLength = str2double(imgInfo.cameraParams.focalLength);
horizonLine = str2double(imgInfo.manualLabeling.horizonLine);
thetac = pi/2-atan2(size(img,1)/2-horizonLine, focalLength);

gtSunAzimuth = str2double(imgInfo.manualLabeling.sunAzimuth);
gtSunZenith = pi/4;

sunDialPosition = [size(img,2)/2, horizonLine + 3*(size(img,1)-horizonLine)/4];

outputPath = fullfile(outputBasePath, sprintf('%s-%s', imgInfo.image.folder, strrep(imgInfo.image.filename, '.jpg', '')));
if args.DoSave
    [m,m,m] = mkdir(outputPath);
end

% draw original image (with and without horizon)
figure; imshow(img);

if args.DoSave
    export_fig(fullfile(outputPath, 'img.pdf'), '-painters', '-native', '-q100', gcf);
end

hold on; plot([0 size(img,2)], [horizonLine horizonLine], '--r', 'LineWidth', 4);

if args.DoSave
    export_fig(fullfile(outputPath, 'imgHorizon.pdf'), '-painters', '-native', '-q100', gcf);
end

if args.Normalize
    illPrior = repmat(args.IllPrior(:), [1 size(resultsInfo.probSun, 2)]); illPrior = illPrior./sum(illPrior(:));
    probSun = resultsInfo.probSun .* illPrior;
    probSun = probSun./sum(probSun(:));
    
    probSunCat = cat(3, illPrior, resultsInfo.shadowsProbSun, resultsInfo.wallsProbSun, resultsInfo.skyProbSun, resultsInfo.pedsProbSun);
    maxVal = max(probSunCat(:));
else
    maxVal = 1;
end


%% Everything (only prob)
if args.DisplayAll
    azimuthEstimates = diplaySunProbAndError(resultsInfo.probSun, resultsInfo.sunAzimuths, focalLength, thetac, size(img), ...
        gtSunZenith, gtSunAzimuth, 'Shadows');

    if args.DoSave
        export_fig(fullfile(outputPath, 'allProb.pdf'), '-painters', gcf);
    end
    
    drawSunDialFromSunPosition(img, [gtSunZenith, azimuthEstimates], horizonLine, focalLength, ...
        'StickPosition', sunDialPosition);
    
    if args.DoSave
        export_fig(fullfile(outputPath, 'allDial.pdf'), '-painters', '-q100', '-native', gcf);
    end
end

%% Everything with prior (only prob)
if args.DisplayAllPrior
    illPrior = repmat(args.IllPrior(:), [1 size(resultsInfo.probSun, 2)]); illPrior = illPrior./sum(illPrior(:));
    probSun = resultsInfo.probSun .* illPrior;
    probSun = probSun./sum(probSun(:));
    
    [azimuthEstimate, zenithEstimate] = diplaySunProbAndError(probSun, resultsInfo.sunAzimuths, focalLength, thetac, size(img), ...
        gtSunZenith, gtSunAzimuth, 'Shadows', 'EstimateZenith', 1);
    
    if args.DoSave
        export_fig(fullfile(outputPath, 'allPriorProb.pdf'), '-painters', gcf);
    end
    
    displaySunProbabilityVectorized(illPrior./maxVal, 1, ...
        'DrawCameraFrame', 1, 'FocalLength', focalLength, 'CamZenith', thetac, 'ImgDims', size(img), 'Normalize', args.Normalize);
    
    if args.DoSave
        export_fig(fullfile(outputPath, 'illPrior.pdf'), '-painters', gcf);
    end

    drawSunDialFromSunPosition(img, [zenithEstimate, azimuthEstimate], horizonLine, focalLength, ...
        'StickPosition', sunDialPosition);
    
    if args.DoSave
        export_fig(fullfile(outputPath, 'allPriorDial.pdf'), '-painters', '-q100', '-native', gcf);
    end
end

%% Shadows
if args.DisplayShadows
    % display shadow boundaries, long lines, sun prob (azimuth)
    imgGround = img.*repmat(geomContextInfo.allGroundMask>0.5, [1 1 3]);
    figure, imshow(imgGround), hold on;
    displayBoundariesSubPixel(gcf, resultsInfo.shadowBoundaries, 'r', 5);
    if ~isempty(resultsInfo.shadowLines)
        plot(resultsInfo.shadowLines(:, [1 2])', resultsInfo.shadowLines(:, [3 4])', 'b', 'LineWidth', 3)
    end
    
    if args.DoSave
        export_fig(fullfile(outputPath, 'shadowsImg.pdf'), '-nocrop', '-q100', '-native', '-painters', gcf);
    end

    azimuthEstimates = diplaySunProbAndError(resultsInfo.shadowsProbSun./maxVal, resultsInfo.sunAzimuths, focalLength, thetac, size(img), ...
        gtSunZenith, gtSunAzimuth, 'Shadows', 'DisplayGtSun', 0, 'DrawFlipped', 1, 'Normalize', args.Normalize);

    if args.DoSave
        export_fig(fullfile(outputPath, 'shadowsProb.pdf'), '-painters', gcf);
    end
    
    drawSunDialFromSunPosition(img, [gtSunZenith, azimuthEstimates], horizonLine, focalLength, ...
        'StickPosition', sunDialPosition, 'DrawFlipped', 1);
        
    if args.DoSave
        export_fig(fullfile(outputPath, 'shadowsDial.pdf'), '-painters', '-q100', '-native', gcf);
    end

end

%% Vertical surfaces
if args.DisplayWalls
    % display surface masks, sun prob (azimuth)
    alpha = 0.5;
    imgComp = displayMaskOverlay(img, geomContextInfo.wallFacing>0, [1 0 0], alpha);
    imgComp = displayMaskOverlay(imgComp, geomContextInfo.wallLeft>0, [0 1 0], alpha);
    imgComp = displayMaskOverlay(imgComp, geomContextInfo.wallRight>0, [0 0 1], alpha);
    figure; imshow(imgComp); %title('Red = facing, green = right, blue = left'); axis off;
    
    if args.DoSave
        export_fig(fullfile(outputPath, 'wallsImg.pdf'), '-q100', '-native', '-painters', gcf);
    end
    
    azimuthEstimates = diplaySunProbAndError(resultsInfo.wallsProbSun./maxVal, resultsInfo.sunAzimuths, focalLength, thetac, size(img), ...
        gtSunZenith, gtSunAzimuth, 'Walls', 'DisplayGtSun', 0, 'Normalize', args.Normalize);
    
    if args.DoSave
        export_fig(fullfile(outputPath, 'wallsProb.pdf'), '-painters', gcf);
    end
    
    drawSunDialFromSunPosition(img, [gtSunZenith, azimuthEstimates], horizonLine, focalLength, ...
        'StickPosition', sunDialPosition);
    
    if args.DoSave
        export_fig(fullfile(outputPath, 'wallsDial.pdf'), '-painters', '-q100', '-native', gcf);
    end

end

%% Pedestrians
if args.DisplayPedestrians
    detInfo = load(fullfile(args.DbPath, imgInfo.detObjects.person.filename));
    
    figure; imshow(img); hold on;
    
    % display detections, local visibility, local estimates, sun prob (azimuth)
    for i=1:size(detInfo.objBboxes,1)
        if detInfo.pObj(i,2)>0.5
            % original display is upside-down
            pLocalLighting = detInfo.pLocalLightingGivenObject(i,[2 1 4 3]);
            assert(length(pLocalLighting)==4); % hack that works for 4 only
            displayObjectOnFigure(detInfo.objBboxes(i,:), pLocalLighting, ...
                'DisplayVisibility', 0, 'ProbVisibility', detInfo.pLocalVisibility(i,2), ...
                'DisplayObjectLikelihood', 1, 'ObjectLikelihood', double(detInfo.pObj(i,2)>0.5), ...
                'DisplayPositionHistogram2D', 0, 'AlignHistogram', args.AlignHistogram);
        end
    end
    
    if args.DoSave
        export_fig(fullfile(outputPath, 'pedsImg.pdf'), '-nocrop', '-q100', '-native', '-painters', gcf);
    end
    
    azimuthEstimates = diplaySunProbAndError(resultsInfo.pedsProbSun./maxVal, resultsInfo.sunAzimuths, focalLength, thetac, size(img), ...
        gtSunZenith, gtSunAzimuth, 'Pedestrians', 'DisplayGtSun', 0, 'Normalize', args.Normalize);
    
    if args.DoSave
        export_fig(fullfile(outputPath, 'pedsProb.pdf'), '-painters',  gcf);
    end
    
    drawSunDialFromSunPosition(img, [gtSunZenith, azimuthEstimates], horizonLine, focalLength, ...
        'StickPosition', sunDialPosition);
    
    if args.DoSave
        export_fig(fullfile(outputPath, 'pedsDial.pdf'), '-painters', '-q100', '-native', gcf);
    end

end

%% Sky
if args.DisplaySky
    % display sky mask, sun prob (zenith - azimuth)
    figure; 
    imshow(displayMaskOverlay(img, geomContextInfo.allSkyMask>0.5, [1 0 0], 0.25));
    
    if args.DoSave
        export_fig(fullfile(outputPath, 'skyImg.pdf'), '-nocrop', '-q100', '-native', '-painters', gcf);
    end
    
    [azimuthEstimate, zenithEstimate] = diplaySunProbAndError(resultsInfo.skyProbSun./maxVal, resultsInfo.sunAzimuths, focalLength, thetac, size(img), ...
        gtSunZenith, gtSunAzimuth, 'Sky', 'EstimateZenith', 1, 'DisplayGtSun', 0, 'Normalize', args.Normalize);

%     azimuthEstimates = diplaySunProbAndError(resultsInfo.skyProbSun, resultsInfo.sunAzimuths, focalLength, thetac, size(img), ...
%         gtSunZenith, gtSunAzimuth, 'Sky', 'DisplayGtSun', 0);
    
    if args.DoSave
        export_fig(fullfile(outputPath, 'skyProb.pdf'), '-painters', gcf);
    end
    
    drawSunDialFromSunPosition(img, [zenithEstimate, azimuthEstimate], horizonLine, focalLength, ...
        'StickPosition', sunDialPosition);
    
    % draw horizon line
%     hold on; plot([0 size(img,2)], [horizonLine horizonLine], '--r', 'LineWidth', 2);
    
    if args.DoSave
        export_fig(fullfile(outputPath, 'skyDial.pdf'), '-painters', '-q100', '-native', gcf);
    end
end

if ~args.DoSave
    pause;
end

close all;