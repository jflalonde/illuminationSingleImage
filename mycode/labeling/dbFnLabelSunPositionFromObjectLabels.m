%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function ret=dbFnLabelSunPositionFromObjectLabels(outputBasePath, annotation, varargin)
%  
% 
% Input parameters:
%
% Output parameters:
%   
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ret = dbFnLabelSunPositionFromObjectLabels(outputBasePath, imgInfo, varargin) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2007 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ret = 0;  

% parse arguments
defaultArgs = struct('ObjectType', [], 'ImagesPath', [], 'DbPath', [], 'Recompute', 0, 'DoSave', 0);
args = parseargs(defaultArgs, varargin{:});

%% Tmp
% if ~str2double(imgInfo.manualLabeling.visible)
%     fprintf('Not visible, skipping...\n');
%     return;
% end

%% Prepare output
if ~args.Recompute && isfield(imgInfo, 'manualLabeling') && isfield(imgInfo.manualLabeling, 'visibleNew')
    fprintf('Already computed! Skipping...\n');
    return;
end

if isfield(imgInfo, 'manualLabeling') && ~isfield(imgInfo.manualLabeling, 'isGood')
    fprintf('Image is bad! Skipping...\n');
    return;
end

if isfield(imgInfo, 'manualLabeling')
    visStr = {'occluded', 'visible'};
    fprintf('Image previously labeled as %s...\n', visStr{str2double(imgInfo.manualLabeling.visible)+1});
end

outputXmlFile = fullfile(args.DbPath, imgInfo.file.folder, imgInfo.file.filename);

%% If the sun was visible, we're done
if 0
    fprintf('*** HACK for new visibility ***\n');
    if str2double(imgInfo.manualLabeling.visible)
        imgInfo.manualLabeling.visibleNew = 1;

        % HACK! new visibility
        if args.DoSave
            write_xml(outputXmlFile, imgInfo);
        end
        return;
    end
end

%% Find all the object's bounding boxes
if isfield(imgInfo, 'object')
    objectInd = LMobjectindex(imgInfo, args.ObjectType);
    if isempty(objectInd)
        fprintf('There are no %ss in the image. Skipping...\n', args.ObjectType);
        return;
    end

    objectBbox = zeros(length(objectInd), 4);
    for o=1:length(objectInd)
        curObject = imgInfo.object(objectInd(o));
        xPts = str2double({curObject.polygon.pt(:).x});
        yPts = str2double({curObject.polygon.pt(:).y});

        % minx, miny, width, height
        objectBbox(o, 1) = min(xPts);
        objectBbox(o, 2) = min(yPts);
        objectBbox(o, 3) = max(xPts)-min(xPts);
        objectBbox(o, 4) = max(yPts)-min(yPts);
    end
else
    objectBbox = [];
end

%% Read the image and information
img = imreadTrans(fullfile(args.ImagesPath, imgInfo.image.folder, imgInfo.image.filename));
focalLength = str2double(imgInfo.cameraParams.focalLength);
imgWidth = size(img,2);
imgHeight = size(img,1);

%% Horizon
% get the estimated horizon line (if we don't already have it!)
if isfield(imgInfo, 'manualLabeling') && isfield(imgInfo.manualLabeling, 'horizonLine')
    horizonLine = str2double(imgInfo.manualLabeling.horizonLine);
    
% elseif isfield(imgInfo, 'geomContext')
%     geomContextInfo = load(fullfile(args.DbPath, imgInfo.geomContext.filename));
%     [m,mind] = max(cat(3, geomContextInfo.allSkyMask, geomContextInfo.allGroundMask, geomContextInfo.allWallsMask), [], 3);
%     skyMask = mind == 1;
%     groundMask = mind == 2;
%     horizonLine = horizonFromGeometricContext(skyMask, groundMask);
else
    horizonLine = imgHeight/2;
end

% make sure all objects lie below the horizon
if ~isempty(objectBbox)
    horizonLine = min(horizonLine, min(objectBbox(:,2)+objectBbox(:,4)))+1;
end

%% Read the previously-computed results, if available
if isfield(imgInfo, 'manualLabeling') && isfield(imgInfo.manualLabeling, 'sunAzimuth')
    sunAzimuth = str2double(imgInfo.manualLabeling.sunAzimuth);
else
    sunAzimuth = pi/2;
end

%% Ask the user to label the sun direction
figHandle = figure(1);
imshow(img);
[sunAzimuth, horizonLine, wedgeAngle, isVisible, isValid, isGood] = labelSunPositionFromObjectLabels(figHandle, focalLength, horizonLine, imgWidth, imgHeight, objectBbox, sunAzimuth);

if ~isValid
    ret = 1;
    [g, lockFile] = acquireLock(outputBasePath, imgInfo.file.folder, imgInfo.file.filename);
    if exist(lockFile, 'file')
        delete(lockFile);
    end
    return;
end

%% Save xml information
if args.DoSave
    imgInfo.manualLabeling.isGood = isGood;
    imgInfo.manualLabeling.sunAzimuth = sunAzimuth;
    % HACK! -> new visibility
    imgInfo.manualLabeling.visibleNew = isVisible;
    imgInfo.manualLabeling.horizonLine = horizonLine;
    imgInfo.manualLabeling.wedgeAngle = wedgeAngle;
    
    fprintf('Saving file %s...\n', outputXmlFile);
    write_xml(outputXmlFile, imgInfo);
end
