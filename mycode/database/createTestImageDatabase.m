%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function createTestImageDatabase
%  Converts a set of images to our XML database format. 
% 
% Input parameters:
%
% Output parameters:
%   
%
% Notes:
%       N
%       ^
%       |
%  W <--+--> E
%       |
%       v
%       S
%
%  - azimuth is positive from N (0) to E (90)
%  - zenith is positive from zenith (0)
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function createTestImageDatabase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set paths
setPath;

origDbBasePath = fullfile(illUnderstandingResultsPath, 'labelmeDb');
origDbPath = fullfile(origDbBasePath, 'all');
origImagesPath = fullfile(illUnderstandingResultsPath, 'labelmeImages');

dbPath = fullfile(basePath, 'trainDb');
imagesPath = fullfile(basePath, 'trainImages');

dbInfo = load(fullfile(origDbBasePath, 'personFiles.mat'));

[m,m,m] = mkdir(dbPath);

doSave = 1;
doDisplay = 0;
recompute = 1;
parallelized = 0;
randomized = 0;

%% Create database
testFiles = strrep(dbInfo.trainFiles, '.jpg', '.xml');
testDirectories = dbInfo.trainDirectories;
processResultsDatabaseFiles(origDbPath, testFiles, testDirectories, dbPath, @dbFnCreateImageDatabase, ...
    parallelized, randomized, ...
    'DoSave', doSave, 'DoDisplay', doDisplay, 'Recompute', recompute, ...
    'OrigDbPath', origDbPath, 'OrigImagesPath', origImagesPath, ...
    'DbPath', dbPath, 'ImagesPath', imagesPath);

function ret = dbFnCreateImageDatabase(outputBasePath, imgInfo, varargin) 
ret = 0;

% parse arguments
defaultArgs = struct('DoSave', 0, 'DoDisplay', 0, 'Recompute', 0, ...
    'OrigDbPath', [], 'OrigImagesPath', [], 'DbPath', [], 'ImagesPath', []);
args = parseargs(defaultArgs, varargin{:});

% make sure it isn't already there
outputXmlFile = fullfile(outputBasePath, imgInfo.file.folder, imgInfo.file.filename);

if ~args.Recompute && exist(outputXmlFile, 'file')
    fprintf('Already computed!\n'); 
    return;
end

%% Keep only good images with sun visible
if ~(isfield(imgInfo, 'manualLabeling') && str2double(imgInfo.manualLabeling.isGood) && str2double(imgInfo.manualLabeling.visibleNew))
	fprintf('Not including this image... Skipping\n');
    return;
end

%% Remove fields we don't care about
newImgInfo.image = imgInfo.image;
newImgInfo.file = imgInfo.file;
newImgInfo.object = imgInfo.object;
newImgInfo.cameraParams = imgInfo.cameraParams;
newImgInfo.manualLabeling = imgInfo.manualLabeling;

%% Save
if args.DoSave
    % copy image
    origImgPath = fullfile(args.OrigImagesPath, imgInfo.image.folder, imgInfo.image.filename);
    dstImgPath = fullfile(args.ImagesPath, imgInfo.image.folder, imgInfo.image.filename);
    [m,m,m] = mkdir(fileparts(dstImgPath));
    copyfile(origImgPath, dstImgPath);
    
    % save the xml file
    [m,m,m] = mkdir(fileparts(outputXmlFile));
    write_xml(outputXmlFile, newImgInfo);
end

