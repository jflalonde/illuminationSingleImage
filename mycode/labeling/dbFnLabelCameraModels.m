%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function ret=dbFnLabelCameraModels(outputBasePath, annotation, varargin)
%  
% 
% Input parameters:
%
% Output parameters:
%   
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ret = dbFnLabelCameraModels(outputBasePath, imgInfo, varargin) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2007 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ret = 0;  
global cameraDb;

% parse arguments
defaultArgs = struct('ImagesPath', [], 'DbPath', [], 'Recompute', 0, 'DoSave', 0);
args = parseargs(defaultArgs, varargin{:});

%% Prepare output
if ~args.Recompute && isfield(imgInfo, 'cameraParams') && isfield(imgInfo.cameraParams, 'focalLength')
    fprintf('Already computed! Skipping...\n');
    return;
end

%% Load focal length from EXIF 
imgPath = fullfile(args.ImagesPath, imgInfo.image.folder, imgInfo.image.filename);
exifData = exifread(imgPath);
iminfo = imfinfo(imgPath);

if isempty(exifData) || ~isfield(exifData, 'Model')
    fprintf('No camera information in EXIF available! Approximating focal...\n');
    
    imgInfo.cameraParams.focalLength = str2double(imgInfo.image.size.width)*10/7;
    imgInfo.cameraParams.gt = 0;
    
else
    % find camera name in camera database
    cameraNames = arrayfun(@(x) x.model, cameraDb.camera, 'UniformOutput', 0);
    cameraInd = find(strcmp(cameraNames, exifData.Model));
    
    if isempty(cameraInd)
        [sensorWidth, sensorHeight] = getCameraSensorDimensions(exifData.Model);
        cameraDb.camera(end+1).model = exifData.Model;
        cameraDb.camera(end).sensor.width = num2str(sensorWidth);
        cameraDb.camera(end).sensor.height = num2str(sensorHeight);
    else
        sensorWidth = str2double(cameraDb.camera(cameraInd).sensor.width);
    end
    
    % make sure to rescale appropriately
    ratio = min([str2double(imgInfo.image.size.height) str2double(imgInfo.image.size.width)] ./ [iminfo.Height iminfo.Width]);
    
    % compute focal length from exif data and sensor dimensions
    imgInfo.cameraParams.focalLength = ratio * exifData.PixelXDimension * exifData.FocalLength / sensorWidth;
end


%% Save information 
if args.DoSave
    outputXmlFile = fullfile(outputBasePath, imgInfo.file.folder, imgInfo.file.filename);
    write_xml(outputXmlFile, imgInfo);
end