function [ap] = pascal(cls, n)

% [ap1, ap2] = pascal(cls, n)
% Train and score a model with n components.

globals;
pascal_init;

model = pascal_train(cls, n);
[boxes1, boxes2] = pascal_test(cls, model, 'test', VOCyear);
ap1 = pascal_eval(cls, boxes1, 'test', ['1_' VOCyear]);
ap2 = pascal_eval(cls, boxes2, 'test', ['2_' VOCyear]);
ap = [ap1 ap2];
