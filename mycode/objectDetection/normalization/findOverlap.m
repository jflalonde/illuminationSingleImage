%% Useful function: finds a set of detections which overlap with bounding boxes
function [detInd, bboxInd, maxOverlap] = findOverlap(detections, bbox, minOverlap)

% inputs may be empty
if isempty(bbox) || isempty(detections)
    detInd = [];
    bboxInd = [];
    return;
end

% assign detections to ground truth objects
detInd = zeros(size(detections, 1), 1);
bboxInd = zeros(size(detections, 1), 1);
maxOverlap = zeros(size(detections, 1), 1);
for d=1:size(detections, 1)
    % assign detection to ground truth object if any
    bb=detections(d,1:4);
    
    ov = zeros(1, size(bbox, 1));
    for j=1:size(bbox, 1)
        bbgt = bbox(j,1:4);
        
        % compute intersection
        bi=[max(bb(1),bbgt(1)) ; max(bb(2),bbgt(2)) ; min(bb(3),bbgt(3)) ; min(bb(4),bbgt(4))];
        iw=bi(3)-bi(1)+1;
        ih=bi(4)-bi(2)+1;
    
        if iw>0 && ih>0
            % compute overlap as area of intersection / area of union
            ua=(bb(3)-bb(1)+1)*(bb(4)-bb(2)+1)+(bbgt(3)-bbgt(1)+1)*(bbgt(4)-bbgt(2)+1)-iw*ih;
            ov(j)=iw*ih/ua;
        end
    end
    
    detInd(d) = any(ov >= minOverlap);
    [maxOverlap(d),bboxInd(d)] = max(ov);
end

% keep indices only
detInd = find(detInd);
bboxInd = bboxInd(detInd);
maxOverlap = maxOverlap(detInd);

