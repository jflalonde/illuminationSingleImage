%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function doLabelMissingObjects
%  Asks the user to say whether an object is in the image but hasn't been
%  labeled.
% 
% Input parameters:
%
% Output parameters:
%   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function doLabelMissingObjects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup
setPath;

dbPath = fullfile(basePath, 'labelmeDb', 'all');
imagesPath = fullfile(basePath, 'labelmeImages');
outputBasePath = dbPath;

%% User parameters
recompute = 0;
doSave = 1;
objectsType = {'person', 'car'};

%% Call the database function
dbFn = @dbFnLabelMissingObjects;
parallelized = 0;
randomized = 1;
processResultsDatabaseFast(dbPath, '', '', outputBasePath, dbFn, parallelized, randomized, ...
    'ObjectsType', objectsType, 'ImagesPath', imagesPath, 'DbPath', dbPath, 'Recompute', recompute, 'DoSave', doSave);

close all;