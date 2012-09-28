%% Expand bounding box
% bbox = [x1 y1 x2 y2 ...]
function bboxExpanded = expandBbox(bbox, expansionFactor, imgSize, varargin)

% parse arguments
defaultArgs = struct('ExpandWidth', 1, 'ExpandHeight', 1);
args = parseargs(defaultArgs, varargin{:});

% keep all other fields
bboxExpanded = bbox;

if args.ExpandHeight
    % same top, height + height*factor;
    bboxExpanded(:,2) = bbox(:,2);
    bboxHeight = bbox(:,4)-bbox(:,2)+1;
    bboxExpanded(:,4) = bbox(:,4) + bboxHeight.*expansionFactor;
    
    % make sure we don't overflow
    bboxExpanded(:,4) = min(bboxExpanded(:,4), imgSize(:, 1));
end

if args.ExpandWidth
    % we want to keep the bounding box centered. Compute minimum width expansion on both sides
    bboxWidth = bbox(:,3)-bbox(:,1)+1;
    expLeft = (bbox(:,1)-1)./bboxWidth;
    expRight = (imgSize(:,2) - bbox(:,3))./bboxWidth;
    
    widthExpansionFactor = expansionFactor/2;
    widthExpansion = min([expLeft, expRight, repmat(widthExpansionFactor, size(expLeft,1), 1)], [], 2);
    
    bboxExpanded(:,1) = bbox(:,1) - bboxWidth.*widthExpansion;
    bboxExpanded(:,3) = bbox(:,3) + bboxWidth.*widthExpansion;
end
