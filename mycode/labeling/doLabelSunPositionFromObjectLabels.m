%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function doLabelSunPositionFromObjectLabels
%  Asks the user to label the sun position in all the images of a database.
%  Uses (vertical) object labels to position the vertical stick
%  automatically and (hopefully) speed up the process. 
% 
% Input parameters:
%
% Output parameters:
%   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function doLabelSunPositionFromObjectLabels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup
addpath ../;
setPath;

% dbBasePath = fullfile(basePath, 'labelmeDb');
% dbPath = fullfile(dbBasePath, 'all');
% imagesPath = fullfile(basePath, 'labelmeImages');

dbPath = '/Users/jflalonde/Documents/phd/results/illuminationSingleImage/geomContextDb';
imagesPath = '/Users/jflalonde/Documents/phd/results/illuminationSingleImage/geomContextImages';
outputBasePath = dbPath;

%% User parameters
recompute = 0;
doSave = 1;
objectType = 'person';

%% Tmp: fix labels for Derek-imported images
% derekDataBasePath = fullfile(dataBasePath, 'labelmePop');
% derekFieldname = 'ts';
% derekTestInfo = load(fullfile(derekDataBasePath, 'popTestset.mat'));
% 
% if strcmp(derekFieldname, 'vs')
%     inds = 1:length(derekTestInfo.(derekFieldname).filelist);
% else
%     inds = derekTestInfo.(derekFieldname).good_inds;
% end
% 
% % build the imgInfo structure
% folders = derekTestInfo.(derekFieldname).folderlist(inds);
% files = strrep(derekTestInfo.(derekFieldname).filelist(inds), '.jpg', '.xml');

%% Fix visibility labels
% dbInfo = load(fullfile(dbBasePath, sprintf('%sFiles.mat', objectType)));

% files = strrep(cat(2, dbInfo.trainFiles, dbInfo.testFiles, dbInfo.valFiles), '.jpg', '.xml');
% directories = cat(2, dbInfo.trainDirectories, dbInfo.testDirectories, dbInfo.valDirectories);

%% Call the database function
dbFn = @dbFnLabelSunPositionFromObjectLabels;
parallelized = 0;
randomized = 1;
% processResultsDatabaseFiles(dbPath, files, directories, outputBasePath, ...
processResultsDatabaseFast(dbPath, '', '', outputBasePath, ...
    dbFn, parallelized, randomized, ...
    'ObjectType', objectType, 'ImagesPath', imagesPath, 'DbPath', dbPath, ...
    'Recompute', recompute, 'DoSave', doSave);

% we're done: close all windows
close all;
