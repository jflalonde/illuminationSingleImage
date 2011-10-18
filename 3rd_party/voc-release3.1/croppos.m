function [im, box] = croppos(im, box)

% [newim, newbox] = croppos(im, box)
% Crop positive example to speed up latent search.

% crop image around bounding box
pad = 0.5*((box(3)-box(1)+1)+(box(4)-box(2)+1));
x1 = max(1, round(box(1) - pad));
y1 = max(1, round(box(2) - pad));
x2 = min(size(im, 2), round(box(3) + pad));
y2 = min(size(im, 1), round(box(4) + pad));

im = im(y1:y2, x1:x2, :);
box([1 3]) = box([1 3]) - x1 + 1;
box([2 4]) = box([2 4]) - y1 + 1;
