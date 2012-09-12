%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function doLabelMissingLabelmeObjects
%  Label missing objects in LabelMe
% 
% Input parameters:
%
% Output parameters:
%   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function doLabelMissingLabelmeObjects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup
addpath ../;
setPath;

dbPath = fullfile(basePath, 'labelmeDb', 'personTrain');
outputBasePath = fullfile(dbPath, 'onlineLabelme');

%% User parameters
objectType = 'person';

%% Call the database function
dbFn = @dbFnLabelMissingLabelmeObjects;
parallelized = 1;
randomized = 1;
processResultsDatabaseFast(dbPath, '', '', outputBasePath, dbFn, parallelized, randomized, ...
    'ObjectType', objectType, 'DbPath', dbPath);

%%
function r = dbFnLabelMissingLabelmeObjects(outputBasePath, imgInfo, varargin)
r = 0;

%%
urlStr = sprintf('\"http://labelme.csail.mit.edu/"tool.html?collection"=LabelMe&mode=f&folder=%s&image=%s\"', imgInfo.image.folder, imgInfo.image.filename);
web(urlStr, '-browser');

%%
u = input('Are you done? (y/N)', 's');
if strcmp(u, 'y')
    r = 1;
    [g, lockFile] = acquireLock(outputBasePath, imgInfo.image.folder, imgInfo.image.filename);
    delete(lockFile);
    return;
end
    