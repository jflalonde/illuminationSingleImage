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
function doLabelCameraModels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup
setPath;

dbPath = fullfile(basePath, 'labelmeDb', 'all');
imagesPath = '/usr1/projects/labelme/Images';
outputBasePath = dbPath;

%% User parameters
recompute = 0;
doSave = 1;

%% Load the camera database
cameraDbPath = fullfile(singleImageResultsPath, 'cameraDb.xml');
global cameraDb;
if exist(cameraDbPath, 'file')
    cameraDb = load_xml(cameraDbPath);
    cameraDb = cameraDb.document;
else
    cameraDb.camera = [];
end

%% Call the database function
dbFn = @dbFnLabelCameraModels;
parallelized = 0;
randomized = 1;
processResultsDatabaseFast(dbPath, '', '', outputBasePath, dbFn, parallelized, randomized, ...
    'ImagesPath', imagesPath, 'DbPath', dbPath, 'Recompute', recompute, 'DoSave', doSave);

%% Save camera database
write_xml(cameraDbPath, cameraDb);
