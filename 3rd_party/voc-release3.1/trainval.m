function [ap1, ap2] = trainval(cls)

globals;
load([cachedir cls '_final']);
[boxes1, boxes2] = pascal_test(cls, model, 'trainval', VOCyear);
ap1 = pascal_eval(cls, boxes1, 'trainval', ['1_' VOCyear]);
ap2 = pascal_eval(cls, boxes2, 'trainval', ['2_' VOCyear]);
