%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function ret=dbFnLabelSunOcclusionForEachObject(outputBasePath, annotation, varargin)
%  
% 
% Input parameters:
%
% Output parameters:
%   
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ret = dbFnLabelSunOcclusionForEachObject(outputBasePath, imgInfo, varargin) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2007 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ret = 0;  

% parse arguments
defaultArgs = struct('ObjectType', [], 'ImagesPath', [], 'DbPath', [], 'Recompute', 0, 'DoSave', 0);
args = parseargs(defaultArgs, varargin{:});

%% Check if we need to compute it
if ~isfield(imgInfo, 'manualLabeling') || ~isfield(imgInfo.manualLabeling, 'visible')
    fprintf('Run doLabelSunPositionFromObjectLabels first!\n');
    return;
end

if ~str2double(imgInfo.manualLabeling.visibleNew)
    fprintf('Sun is not visible. Skipping...\n');
    return;
end

if (isfield(imgInfo, 'manualLabeling') && ~str2double(imgInfo.manualLabeling.isGood))
    fprintf('Bad image. Skipping...\n');
    return;
end

%% Temp: only re-label with visibleNew=1 and visible=0
if ~(~str2double(imgInfo.manualLabeling.visible) && str2double(imgInfo.manualLabeling.visibleNew))
    fprintf('*** HACK: no need to re-label objects here ***\n');
    return;
end

%% Make sure there's at least one object of the specified type
objectInd = LMobjectindex(imgInfo, args.ObjectType);
if isempty(objectInd)
    fprintf('Image has no %ss! Skipping...\n', args.ObjectType);
    return;
end

%% Make sure we've got all objects labeled
do = 0;
if isfield(imgInfo.manualLabeling, 'labeledObjects')
    for o=1:length(imgInfo.object)
        if ~isfield(imgInfo.object(o), 'sunVisible') || ~isempty(imgInfo.object(o).sunVisible)
            do = 1;
            break;
        end
    end
else 
    do = 1;
end

if ~do
    fprintf('All objects already labeled! Skipping...\n');
    return;
end

%% Read the image and information
img = imreadTrans(fullfile(args.ImagesPath, imgInfo.image.folder, imgInfo.image.filename));

%% Find all the object's bounding boxes
objectBbox = zeros(length(imgInfo.object), 4);
for o=1:length(imgInfo.object)
    curObject = imgInfo.object(o);
    xPts = str2double({curObject.polygon.pt(:).x});
    yPts = str2double({curObject.polygon.pt(:).y});
    
    % minx, miny, width, height
    objectBbox(o, 1) = min(xPts);
    objectBbox(o, 2) = min(yPts);
    objectBbox(o, 3) = max(xPts)-min(xPts);
    objectBbox(o, 4) = max(yPts)-min(yPts);
end

%% Ask the user to label the sun direction
figHandle = figure(1); hold off;
imshow(img, 'InitialMagnification', 'fit'); 
[isVisible, isValid] = labelSunOcclusionForEachObject(figHandle, objectBbox);

if ~isValid
    ret = 1;
    return;
end

%% Save xml information
if args.DoSave
    imgInfo.manualLabeling.labeledObjects = 1;
    
    % update each object's annotation with visible or not
    for o=1:length(imgInfo.object)
        imgInfo.object(o).sunVisible = isVisible(o);
    end
    
    outputXmlFile = fullfile(outputBasePath, imgInfo.file.folder, imgInfo.file.filename);
    fprintf('Saving file %s...\n', outputXmlFile);
    write_xml(outputXmlFile, imgInfo);
end
