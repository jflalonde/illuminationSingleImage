function [ap1, ap2] = test(cls)

globals;
load([cachedir cls '_final']);
[boxes1, boxes2] = pascal_test(cls, model, 'test', VOCyear);
ap1 = pascal_eval(cls, boxes1, 'test', ['1_' VOCyear]);
ap2 = pascal_eval(cls, boxes2, 'test', ['2_' VOCyear]);
