function bbox = detectObjectsParams(img, modelInfo, varargin)
% Detects objects in an image, and exposes the parameters
%
% ----------
% Jean-Francois Lalonde

%
defaultArgs = struct('Threshold', [], 'DoBboxPrediction', 0, 'DoNMS', 1, ...
    'NMSThreshold', 0.5, 'DoClipBoxes', 1, 'Normalize', 0);
args = parseargs(defaultArgs, varargin{:});

% run detector
if isempty(args.Threshold)
    bbox = detect(img, modelInfo.model, modelInfo.model.thresh);
else
    bbox = detect(img, modelInfo.model, args.Threshold);
end

if args.DoBboxPrediction
    % this is available only if bounding box prediction has been trained
    bbox = getboxes(modelInfo.model, bbox);
end

if args.DoNMS
    % non-maximal suppression
    bbox = nms(bbox, args.NMSThreshold);
end

if args.DoClipBoxes
    % clip bounding boxes to image's dimensions
    bbox = clipboxes(img, bbox);
end

% normalize output?
if args.Normalize && ~exist('normConf', 'var') && ~isempty(bbox);
    % normalize output
    normConf = normalizeConfidences(modelInfo, bbox(:,end));

    % save bounding boxes
    bbox = [bbox(:, 1:4), normConf];
else
    bbox = bbox(:, 1:4);
end
