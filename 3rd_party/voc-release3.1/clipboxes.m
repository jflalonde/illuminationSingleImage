function boxes = clipboxes(im, boxes)

% boxes = clipboxes(im, boxes)
% Clips boxes to image boundary.

if ~isempty(boxes)
  boxes(:,1) = max(boxes(:,1), 1);
  boxes(:,2) = max(boxes(:,2), 1);
  boxes(:,3) = min(boxes(:,3), size(im, 2));
  boxes(:,4) = min(boxes(:,4), size(im, 1));
end
