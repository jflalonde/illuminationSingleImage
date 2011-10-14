%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function trainWallsIlluminationPredictor
%  Trains P(sun | vertical surface, vertical surface max. intensity).
% 
% Input parameters:
%
% Output parameters:
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trainWallsIlluminationPredictor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Initialization
setPath; 

geomContextDbPath = fullfile(basePath, 'geomContextDb');
geomContextImagesPath = fullfile(basePath, 'geomContextImages');
outputBasePath = fullfile(basePath, 'localIlluminationPredictors');

doSave = 1;
doDisplay = 0;
minWallNbPixels = 50;

%% Load the geometric dataset
geomContextDb = loadDatabaseFast(geomContextDbPath, '', '', 0);

%% Load the geometric context labels
geomContextLbl = load(fullfile(geomContextImagesPath, 'allimsegs2.mat'));

%% find clear-sky images only
imgVisible = arrayfun(@(x) str2double(x.document.manualLabeling.visibleNew) && str2double(x.document.manualLabeling.isGood), geomContextDb);
sunAzimuths = arrayfun(@(x) str2double(x.document.manualLabeling.sunAzimuth), geomContextDb);
fprintf('Estimating distribution using %d images...\n', nnz(imgVisible));

indVisible = find(imgVisible);

%% Gather boundary features and labels
wInts = []; nwInts = [];
wErrors = []; nwErrors = [];

for i=indVisible
    fprintf('%d/%d...\n', find(i==indVisible), length(indVisible));
    imgInfo = geomContextDb(i).document;
    img = im2double(imread(fullfile(geomContextImagesPath, imgInfo.image.folder, imgInfo.image.filename)));
    
    % get sun and camera parameters
    sunAzimuth = sunAzimuths(i);
    
    % load ground truth geometric context surfaces
    segImage = geomContextLbl.imsegs(i).segimage;
    
    % maskLeft -> surface points towards the left
    wLabels = [2 3 4]; % left, facing, right
    wAngles = [-pi/2 -pi pi/2];
        
    for l=1:length(wLabels)
        wallMask = ismember(segImage, find(geomContextLbl.imsegs(i).labels==wLabels(l)));
    
        if nnz(wallMask) > minWallNbPixels
            % compute intensity
            wallInt = computeWallIntensity(rgb2gray(img), wallMask);
            wInts = cat(2, wInts, wallInt);
            
            wErrors = cat(2, wErrors, angularError(wAngles(l), sunAzimuth));
        end
    end
    
    % porous and solid: random?
    nwLabels = [5 6];
    nwAngles = rand(1,2)*2*pi-pi;% [-pi -pi];
    
    for l=1:length(nwLabels)
        wallMask = ismember(segImage, find(geomContextLbl.imsegs(i).labels==nwLabels(l)));
        
        if nnz(wallMask) > minWallNbPixels
            % compute intensity
            wallInt = computeWallIntensity(rgb2gray(img), wallMask);
            nwInts = cat(2, nwInts, wallInt);
            
            nwErrors = cat(2, nwErrors, angularError(nwAngles(l), sunAzimuth));
        end
    end
end

%% Display results
if doDisplay
%     figure(1), hist(sErrors, 20), title('Shadows');
%     figure(2), hist(nsErrors, 20), title('Non-shadows');
%     figure, x = linspace(0,pi/2-eps,25+1); y = histc(a.sErrors, x); y=y./sum(y); plot(linspace(0,pi/2,25), smooth(y(1:end-1), 'lowess')), axis([0 pi/2 0 0.1]);
%     title('Shadows');
%     figure, x = linspace(0,pi/2-eps,25+1); y = histc(a.nsErrors, x); y=y./sum(y); plot(linspace(0,pi/2,25), smooth(y(1:end-1), 'lowess')), axis([0 pi/2 0 0.1]);
%     title('Non-shadows');
end

%% Save results
if doSave
    outputFile = fullfile(outputBasePath, 'wallsPredictorRandomNonWalls-.mat');
    [m,m,m] = mkdir(fileparts(outputFile));
    
    % also save files on which this was computed
    files = arrayfun(@(x) x.document.image.filename, geomContextDb(indVisible), 'UniformOutput', 0);
    save(outputFile, 'wInts', 'wErrors', 'nwInts', 'nwErrors', 'files');
end
