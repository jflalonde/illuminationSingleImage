function bbox = process(image, model, thresh)

% bbox = process(image, model, thresh)
% Detect objects that score above a threshold, return bonding boxes.
% If the threshold is not included we use the one in the model.
% This should lead to high-recall but low precision.

if nargin < 3
  thresh = model.thresh
end

boxes = detect(image, model, thresh);
bbox = getboxes(model, boxes);
bbox = nms(bbox, 0.5);
bbox = clipboxes(image, bbox);
