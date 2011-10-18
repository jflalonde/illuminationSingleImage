%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function doPrecomputeSunVisibilityFeatures
%  Pre-computes sun visibility features.
%
% Input parameters:
%
% Output parameters:
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function doPrecomputeSunVisibilityFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

setPath;

dbBasePath = fullfile(basePath, 'labelmeDb');
dbPath = fullfile(dbBasePath, 'all');
imagesPath = fullfile(basePath, 'labelmeImages');
outputBasePath = dbPath;
skyDbPath = fullfile(singleImageResultsPath, 'sky', 'skyDb-Hsv-new.mat');

%% Load files
objectType = 'person';
dbInfo = load(fullfile(dbBasePath, sprintf('%sFiles.mat', objectType)));

files = strrep(cat(2, dbInfo.trainFiles, dbInfo.testFiles, dbInfo.valFiles), '.jpg', '.xml');
directories = cat(2, dbInfo.trainDirectories, dbInfo.testDirectories, dbInfo.valDirectories);

%% User parameters
recompute = 0;
doSave = 1;

visibilityFeaturesOpts = {'GeometricContextArea', 1, 'MeanSkyColor', 1, 'MeanGroundIntensity', 1, ...
                    'MaxGroundCluster', 1, 'MaxWallsCluster', 1, 'SceneContrast', 1, 'SVHistogram', ...
                    1, 'LogHistogram', 1, 'GroundShadows', 1};
% visibilityFeaturesOpts = {'GroundShadows', 1, 'SkyCategory', 0};
% visibilityFeaturesOpts = {'SVHistogram', 1, 'LogHistogram', 1};

%% Call the database function
dbFn = @dbFnPrecomputeSunVisibilityFeatures;
parallelized = 1;
randomized = 1;
processResultsDatabaseFiles(dbPath, files, directories, outputBasePath, dbFn, parallelized, randomized, ...
                            'ImagesPath', imagesPath, 'DbPath', dbPath, 'SkyDbPath', skyDbPath, ...
                            'Recompute', recompute, 'DoSave', doSave, 'VisibilityFeaturesOpts', ...
                            visibilityFeaturesOpts);

%% Function that gets called for each image
function ret = dbFnPrecomputeSunVisibilityFeatures(outputBasePath, imgInfo, varargin)
ret = 0;

% parse arguments
defaultArgs = struct('ImagesPath', [], 'DbPath', [], 'SkyDbPath', [], 'Recompute', 0, 'DoSave', 0, ...
                     'VisibilityFeaturesOpts', []);
args = parseargs(defaultArgs, varargin{:});

imgInfo.visibilityFeatures.filename = fullfile('visibilityFeatures', imgInfo.file.folder, ...
                                               strrep(imgInfo.file.filename, '.xml', '.mat'));
outputFile = fullfile(outputBasePath, imgInfo.visibilityFeatures.filename);

defaultSubArgs = struct('GeometricContextArea', 0, 'MeanSkyColor', 0, 'MeanGroundIntensity', 0, ...
                        'MaxGroundCluster', 0, 'MaxWallsCluster', 0, 'SceneContrast', 0, 'GroundShadows', ...
                        0, 'SkyCategory', 0, 'LogHistogram', 0, 'SVHistogram', 0);
subArgs = parseargs(defaultSubArgs, args.VisibilityFeaturesOpts{:});

%% Check what to recompute
visibilityArgs = {};
if exist(outputFile, 'file')
    load(outputFile, 'visibilityFeatures');
    
    % figure out which result has already been computed 
    computeAny = 0;
    fNames = fieldnames(subArgs);
    for f=1:length(fNames)
        if subArgs.(fNames{f})
            if ~args.Recompute && isfield(visibilityFeatures, fNames{f}) && ~isempty(visibilityFeatures.(fNames{f}))
                fprintf('%s is already computed...\n', fNames{f});
            else
                visibilityArgs = [visibilityArgs, {fNames{f}, 1}];
                computeAny = 1;
            end
        end
    end
    
    if ~computeAny
        fprintf('Already computed! Skipping...\n');
        return;
    end
else
    visibilityFeatures = [];
    visibilityArgs = args.VisibilityFeaturesOpts;
end

%% read image
img = im2double(imread(fullfile(args.ImagesPath, imgInfo.image.folder, imgInfo.image.filename)));

%% Check what additional information we need
% visibilityArgs = args.VisibilityFeaturesOpts;
if subArgs.GeometricContextArea
    % load geometric context information
    geomContextInfo = load(fullfile(args.DbPath, imgInfo.geomContext.filename));
    
    visibilityArgs = [visibilityArgs, {'GeometricContextGround', geomContextInfo.allGroundMask}];
    visibilityArgs = [visibilityArgs, {'GeometricContextWalls', geomContextInfo.allWallsMask}];
    visibilityArgs = [visibilityArgs, {'GeometricContextSky', geomContextInfo.allSkyMask}];
end

if subArgs.MeanSkyColor
    % load the sky mask
    if ~exist('geomContextInfo', 'var')
        geomContextInfo = load(fullfile(args.DbPath, imgInfo.geomContext.filename));
    end
    [m,mind] = max(cat(3, geomContextInfo.allGroundMask, geomContextInfo.allWallsMask, geomContextInfo.allSkyMask), [], 3);

    visibilityArgs = [visibilityArgs, {'SkyMask', mind==3}];
end

if subArgs.MeanGroundIntensity
    % load the sky mask
    if ~exist('geomContextInfo', 'var')
        geomContextInfo = load(fullfile(args.DbPath, imgInfo.geomContext.filename));
    end
    [m,mind] = max(cat(3, geomContextInfo.allGroundMask, geomContextInfo.allWallsMask, geomContextInfo.allSkyMask), [], 3);

    visibilityArgs = [visibilityArgs, {'GroundMask', mind==1}];
end

if subArgs.MaxGroundCluster
    % load the sky mask
    if ~exist('geomContextInfo', 'var')
        geomContextInfo = load(fullfile(args.DbPath, imgInfo.geomContext.filename));
    end
    visibilityArgs = [visibilityArgs, {'GroundProb', geomContextInfo.allGroundMask}];
end

if subArgs.MaxWallsCluster
    if ~exist('geomContextInfo', 'var')
        geomContextInfo = load(fullfile(args.DbPath, imgInfo.geomContext.filename));
    end

    visibilityArgs = [visibilityArgs, {'WallRight', geomContextInfo.wallRight}, {'WallLeft', geomContextInfo.wallLeft}, {'WallFacing', geomContextInfo.wallFacing}];
end

if subArgs.SceneContrast
    % load the sky mask
    if ~exist('geomContextInfo', 'var')
        geomContextInfo = load(fullfile(args.DbPath, imgInfo.geomContext.filename));
    end
    [m,mind] = max(cat(3, geomContextInfo.allGroundMask, geomContextInfo.allWallsMask, geomContextInfo.allSkyMask), [], 3);

    visibilityArgs = [visibilityArgs, {'GroundMask', mind==1, 'WallsMask', mind==2}];
end

if subArgs.GroundShadows
    % load the ground mask
    if ~exist('geomContextInfo', 'var')
        geomContextInfo = load(fullfile(args.DbPath, imgInfo.geomContext.filename));
    end
        
    % load the ground shadows & boundary information
    shadowInfo = load(fullfile(args.DbPath, imgInfo.shadows.filename));
    bndInfo = load(fullfile(args.DbPath, imgInfo.wseg25.filename));
    if isfield(imgInfo.bndFeatures, 'imageSize')
        newImgSize = [str2double(imgInfo.bndFeatures.imageSize.height), str2double(imgInfo.bndFeatures.imageSize.width)];
    else
        newImgSize = [];
    end
    
    visibilityArgs = [visibilityArgs, {'ShadowBoundaries', bndInfo.boundaries(shadowInfo.boundaryLabels==0), ...
                        'NewImgSize', newImgSize, 'GroundProb', geomContextInfo.allGroundMask}];
end

if subArgs.SkyCategory
    % load the sky mask
    if ~exist('geomContextInfo', 'var')
        geomContextInfo = load(fullfile(args.DbPath, imgInfo.geomContext.filename));
    end
    [m,mind] = max(cat(3, geomContextInfo.allGroundMask, geomContextInfo.allWallsMask, ...
                       geomContextInfo.allSkyMask), [], 3);
    skyProbMask = im2double(mind==2).*geomContextInfo.allSkyMask;
    
    % load the sky model
    skyDbInfo = load(args.SkyDbPath);

    visibilityArgs = [visibilityArgs, {'SkyProbMask', skyProbMask, 'SkyDbFeatures', skyDbInfo.skyFeatures, 'SkyDbLabels', skyDbInfo.skyLabels}];
end

if subArgs.LogHistogram
    % load the ground probability mask
    if ~exist('geomContextInfo', 'var')
        geomContextInfo = load(fullfile(args.DbPath, imgInfo.geomContext.filename));
    end
    
    visibilityArgs = [visibilityArgs, {'GroundProb', geomContextInfo.allGroundMask}];
end

if subArgs.SVHistogram
    % load the ground probability mask
    if ~exist('geomContextInfo', 'var')
        geomContextInfo = load(fullfile(args.DbPath, imgInfo.geomContext.filename));
    end
    
    visibilityArgs = [visibilityArgs, {'GroundProb', geomContextInfo.allGroundMask}];
end

%% Compute visibility features
newVisibilityFeatures = computeSunVisibilityFeatures(img, visibilityArgs{:});

%% Concatenate with existing features
fNames = fieldnames(newVisibilityFeatures);
for f=1:length(fNames)
    if ~isempty(newVisibilityFeatures.(fNames{f}))
        visibilityFeatures.(fNames{f}) = newVisibilityFeatures.(fNames{f});
    end
end

%% Save results?
if args.DoSave
    [m,m,m] = mkdir(fileparts(outputFile));
    save(outputFile, 'visibilityFeatures');
    
    outputXmlFile = fullfile(outputBasePath, imgInfo.file.folder, imgInfo.file.filename);
    write_xml(outputXmlFile, imgInfo);
end

