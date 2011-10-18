function model = trainbox(name, model, pos, overlap)

% model = trainbox(name, model, pos, overlap)
% Train bounding box prediction function.

globals;

try
  load([cachedir name '_box']);
catch
  [boxes, bboxes] = poslatent(name, model, pos, overlap);
  save([cachedir name '_box'], 'boxes', 'bboxes');
end

for c = 1:model.numcomponents
  A = [boxes{c}(:,3)-boxes{c}(:,1)];
  for j=1:4:size(boxes{c}, 2);
    A = [A boxes{c}(:, j:j+1)];
  end

  model.components{c}.x1 = A \ bboxes{c}(:,1);
  model.components{c}.y1 = A \ bboxes{c}(:,2);
  model.components{c}.x2 = A \ bboxes{c}(:,3);
  model.components{c}.y2 = A \ bboxes{c}(:,4);
end

function [boxes, bboxes] = poslatent(name, model, pos, overlap)
model.interval = 5;
for c = 1:model.numcomponents
  boxes{c} = [];
  bboxes{c} = [];
end
numpos = length(pos);
pixels = model.minsize * model.sbin;
minsize = 1.2 * prod(pixels);  
for i = 1:numpos
  fprintf('%s: latent positive: %d/%d\n', name, i, numpos);
  bbox = [pos(i).x1 pos(i).y1 pos(i).x2 pos(i).y2];
  % skip small examples
  if (bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1) < minsize
    continue
  end
  im = color(imread(pos(i).im));
  % get example
  box = detect(im, model, 0, bbox, overlap);
  if ~isempty(box)
    c = box(1,end-1);
    boxes{c}(end+1,:) = box(1:end-2);
    bboxes{c}(end+1,:) = bbox;
    showboxes(im, box);
  end
  % get flipped example
  im = im(:,end:-1:1,:);
  oldx1 = bbox(1);
  oldx2 = bbox(3);
  bbox(1) = size(im,2) - oldx2 + 1;
  bbox(3) = size(im,2) - oldx1 + 1;
  box = detect(im, model, 0, bbox, overlap);
  if ~isempty(box)
    c = box(1,end-1);
    boxes{c}(end+1,:) = box(1:end-2);
    bboxes{c}(end+1,:) = bbox;
    showboxes(im, box);
  end
end

