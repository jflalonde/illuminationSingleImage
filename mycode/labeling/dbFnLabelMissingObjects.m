%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function ret=dbFnLabelMissingObjects(outputBasePath, annotation, varargin)
%  
% 
% Input parameters:
%
% Output parameters:
%   
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ret = dbFnLabelMissingObjects(outputBasePath, imgInfo, varargin) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2007 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ret = 0;  

% parse arguments
defaultArgs = struct('ObjectsType', [], 'ImagesPath', [], 'DbPath', [], 'Recompute', 0, 'DoSave', 0);
args = parseargs(defaultArgs, varargin{:});

%% Check if we need to compute it
if ~args.Recompute && (isfield(imgInfo, 'manualLabeling') && isfield(imgInfo.manualLabeling, 'allObjectsLabeled'))
    fprintf('Already computed! Skipping...\n');
    return;
end

if isfield(imgInfo, 'manualLabeling') && ~str2double(imgInfo.manualLabeling.isGood)
    fprintf('Already labelled as bad! Skipping...\n');
    return;
end
    
%% Read the image and information
imgPath = fullfile(args.ImagesPath, imgInfo.image.folder, imgInfo.image.filename);
img = imread(imgPath);

%% Prepare question
objectListStr = sprintf('%ss', args.ObjectsType{1});
for o=2:length(args.ObjectsType)-1
    objectListStr = sprintf('%s, %ss', objectListStr, args.ObjectsType{2});
end
if length(args.ObjectsType) == 2
    objectListStr = sprintf('%s or %ss', objectListStr, args.ObjectsType{end});
elseif length(args.ObjectsType) > 2
    objectListStr = sprintf('%s, or %ss', objectListStr, args.ObjectsType{end});
end
questionStr = sprintf('Can you find any %s that are NOT labeled in this image?', objectListStr);

%% Ask the user to indicate whether or not all objects in the image are labelled
figHandle = figure(1); hold off;
set(figHandle, 'Position', [194 104 1066 680]);
LMplot(imgInfo, img);
title(questionStr);
% imshow(img, 'InitialMagnification', 'fit'); 
[uInput, uDescription] = askUserInput(figHandle, questionStr, {{'y', 'Yes'}, {'n', 'No'}, {'b', 'Bad image'}, {'d', 'Don''t know'}, {'q', 'Quit'}});
fprintf('You''ve indicated: %s\n', uDescription);

%% Parse user input
if strcmp(uInput, 'y')
    imgInfo.manualLabeling.allObjectsLabeled = 0;
    
elseif strcmp(uInput, 'n')
    imgInfo.manualLabeling.allObjectsLabeled = 1;
    
elseif strcmp(uInput, 'b')
    imgInfo.manualLabeling.isGood = 0;
    
elseif strcmp(uInput, 'd')
    % don't know -> not all objects are labeled (won't be selected for test set)
    imgInfo.manualLabeling.allObjectsLabeled = 0;
        
elseif strcmp(uInput, 'q')
    % quit without saving
    ret = 1;
    return;
else
    fprintf('Wrong input, skipping...\n');
end

%% Save xml information
if args.DoSave
    outputXmlFile = fullfile(outputBasePath, imgInfo.file.folder, imgInfo.file.filename);
    fprintf('Saving file %s...\n', outputXmlFile);
    write_xml(outputXmlFile, imgInfo);
end
