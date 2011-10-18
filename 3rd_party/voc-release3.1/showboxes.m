function showboxes(im, boxes)

% showboxes(im, boxes)
% Draw boxes on top of image.

clf;
image(im); 
axis equal;
axis on;
if ~isempty(boxes)
  numfilters = floor(size(boxes, 2)/4);
  for i = 1:numfilters
    x1 = boxes(:,1+(i-1)*4);
    y1 = boxes(:,2+(i-1)*4);
    x2 = boxes(:,3+(i-1)*4);
    y2 = boxes(:,4+(i-1)*4);
    if i == 1
      c = 'r';
    else
      c = 'b';
    end
    line([x1 x1 x2 x2 x1]', [y1 y2 y2 y1 y1]', 'color', c, 'linewidth', 3);
  end
end
drawnow;
