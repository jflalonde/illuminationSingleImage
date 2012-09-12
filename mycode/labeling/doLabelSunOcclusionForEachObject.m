%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function doLabelSunOcclusionForEachObject
%  Asks the user to label whether the sun shines directly on an object or
%  not. 
% 
% Input parameters:
%
% Output parameters:
%   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function doLabelSunOcclusionForEachObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup
setPath;

dbBasePath = fullfile(basePath, 'labelmeDb');
dbPath = fullfile(dbBasePath, 'all');
imagesPath = fullfile(basePath, 'labelmeImages');
outputBasePath = dbPath;


%% User parameters
recompute = 0;
doSave = 1;
objectType = 'person';


%% Fix visibility labels
dbInfo = load(fullfile(dbBasePath, sprintf('%sFiles.mat', objectType)));

files = strrep(cat(2, dbInfo.trainFiles, dbInfo.testFiles, dbInfo.valFiles), '.jpg', '.xml');
directories = cat(2, dbInfo.trainDirectories, dbInfo.testDirectories, dbInfo.valDirectories);

%% Call the database function
dbFn = @dbFnLabelSunOcclusionForEachObject;
parallelized = 0;
randomized = 1;
processResultsDatabaseFiles(dbPath, files, directories, outputBasePath, dbFn, parallelized, randomized, ...
    'ObjectType', objectType, 'ImagesPath', imagesPath, 'DbPath', dbPath, 'Recompute', recompute, 'DoSave', doSave);

close all;