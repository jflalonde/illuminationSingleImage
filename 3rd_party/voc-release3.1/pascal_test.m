function [boxes1, boxes2] = pascal_test(cls, model, testset, suffix)

% [boxes1, boxes2] = pascal_test(cls, model, testset, suffix)
% Compute bounding boxes in a test set.
% boxes1 are bounding boxes from root placements
% boxes2 are bounding boxes using predictor function

globals;
pascal_init;
ids = textread(sprintf(VOCopts.imgsetpath, testset), '%s');

% run detector in each image
try
  load([cachedir cls '_boxes_' testset '_' suffix]);
catch
  for i = 1:length(ids);
    fprintf('%s: testing: %s %s, %d/%d\n', cls, testset, VOCyear, ...
            i, length(ids));
    im = imread(sprintf(VOCopts.imgpath, ids{i}));  
    boxes = detect(im, model, model.thresh);
    if ~isempty(boxes)
      b1 = boxes(:,[1 2 3 4 end]);
      b1 = clipboxes(im, b1);
      boxes1{i} = nms(b1, 0.5);
      if length(model.partfilters) > 0
        b2 = getboxes(model, boxes);
        b2 = clipboxes(im, b2);
        boxes2{i} = nms(b2, 0.5);
      else
        boxes2{i} = boxes1{i};
      end
    else
      boxes1{i} = [];
      boxes2{i} = [];
    end
    showboxes(im, boxes1{i});
  end    
  save([cachedir cls '_boxes_' testset '_' suffix], 'boxes1', 'boxes2');
end
