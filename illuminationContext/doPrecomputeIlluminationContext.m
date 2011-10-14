%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function doPrecomputeIlluminationContext
%  
% 
% Input parameters:
%
% Output parameters:
%   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function doPrecomputeIlluminationContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup
addpath ../;
setPath;

dbPath = fullfile(basePath, 'testDb');
imagesPath = fullfile(basePath, 'testImages');
outputBasePath = dbPath;

%% User parameters
recompute = 1;
doSave = 1;

%% Call the database
dbFn = @dbFnPrecomputeIlluminationContext;
parallelized = 1;
randomized = 1;
[files, directories] = getFilesFromDirectory(dbPath, '', '', '', '.xml', 1);
processResultsDatabaseFiles(dbPath, files, directories, outputBasePath, dbFn, parallelized, randomized, ...
    'ImagesPath', imagesPath, 'DbPath', dbPath, 'Recompute', recompute, 'DoSave', doSave);        

%%
function ret = dbFnPrecomputeIlluminationContext(outputBasePath, imgInfo, varargin)
ret = 0;

% parse arguments
defaultArgs = struct('Recompute', 0, 'DoSave', 0, 'ImagesPath', [], 'DbPath', []);
args = parseargs(defaultArgs, varargin{:});

%% Prepare output
imgInfo.illContext.filename = fullfile('illContext', imgInfo.image.folder, strrep(imgInfo.image.filename, '.jpg', '.mat'));
outputFile = fullfile(outputBasePath, imgInfo.illContext.filename);
if ~args.Recompute && exist(outputFile, 'file')
    fprintf('Already computed! Skipping...\n');
    return;
end

%% Load image and geometric context
geomContextInfo = load(fullfile(args.DbPath, imgInfo.geomContext.filename));
img = im2double(imread(fullfile(args.ImagesPath, imgInfo.image.folder, imgInfo.image.filename)));

%% Compute weighted histograms
minLimits = [0 -100 -100];
maxLimits = [100 100 100];
nbBins = 50;

imgLab = rgb2lab(img);
imgLab = reshape(imgLab, size(img,1)*size(img,2), size(img,3));

histoSky = myHistoNDWeighted(imgLab, reshape(geomContextInfo.allSkyMask, numel(geomContextInfo.allGroundMask), 1), nbBins, minLimits, maxLimits);
histoGround = myHistoNDWeighted(imgLab, reshape(geomContextInfo.allGroundMask, numel(geomContextInfo.allGroundMask), 1), nbBins, minLimits, maxLimits);
histoVert = myHistoNDWeighted(imgLab, reshape(geomContextInfo.allWallsMask, numel(geomContextInfo.allGroundMask), 1), nbBins, minLimits, maxLimits);

histoSky = sparse(reshape(histoSky, nbBins^2, nbBins));
histoGround = sparse(reshape(histoGround, nbBins^2, nbBins));
histoVert = sparse(reshape(histoVert, nbBins^2, nbBins));

%% Save results
if args.DoSave
    [m,m,m] = mkdir(fileparts(outputFile));
    save(outputFile, 'histoSky', 'histoGround', 'histoVert');
    
    outputXmlFile = fullfile(outputBasePath, imgInfo.file.folder, imgInfo.file.filename);
    write_xml(outputXmlFile, imgInfo);
end
        

