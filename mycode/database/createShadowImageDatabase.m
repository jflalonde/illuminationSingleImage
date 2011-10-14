%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function createImageDatabase
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
function createShadowImageDatabase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set paths
setPath;

origImagesPath = fullfile(basePath, 'geometricContextImages');
dbPath = fullfile(basePath, 'geometricContextDb');

[m,m,m] = mkdir(dbPath);

doSave = 1;
doDisplay = 0;
recompute = 1;
parallelized = 0;
randomized = 0;

%% Create database
processImageDatabase(origImagesPath, '', '', dbPath, @dbFnCreateImageDatabase, parallelized, randomized, ...
    'DoSave', doSave, 'DoDisplay', doDisplay, 'Recompute', recompute, ...
    'ImagesPath', origImagesPath);

function ret = dbFnCreateImageDatabase(outputBasePath, imgInfo, varargin) 
ret = 0;

% parse arguments
defaultArgs = struct('DoSave', 0, 'DoDisplay', 0, 'Recompute', 0, 'ImagesPath', []);
args = parseargs(defaultArgs, varargin{:});

% make sure it isn't already there
imgInfo.file.folder = '.';
imgInfo.file.filename = sprintf('%s-%s.xml', strrep(lower(imgInfo.image.folder), './', ''), strrep(lower(imgInfo.image.filename), '.jpg', ''));
imgInfo.file.filename = strrep(imgInfo.file.filename, '.jpg', '');
outputXmlFile = fullfile(outputBasePath, imgInfo.file.folder, imgInfo.file.filename);

if ~args.Recompute && exist(outputXmlFile, 'file')
    fprintf('Already computed!\n'); 
    return;
end

%% Extract information
imgPath = fullfile(args.ImagesPath, imgInfo.image.folder, imgInfo.image.filename);
iminfo = imfinfo(imgPath);

imgInfo.image.size.height = iminfo.Height;
imgInfo.image.size.width = iminfo.Width;

% compute "default" focal length
imgInfo.cameraParams.focalLength = imgInfo.image.size.width*10/7;

%% Save
if args.DoSave    
    % save the xml file
    write_xml(outputXmlFile, imgInfo);
end

