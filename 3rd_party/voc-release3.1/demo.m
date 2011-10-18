function demo()

test('000034.jpg', 'car');
test('000061.jpg', 'person');
test('000084.jpg', 'bicycle');

function test(name, cls)
% load and display image
im=imread(name);
clf;
image(im);
axis equal; 
axis on;
disp('input image');
disp('press any key to continue'); pause;

% load and display model
load(['VOC2007/' cls '_final']);
visualizemodel(model);
disp([cls ' model']);
disp('press any key to continue'); pause;

% detect objects
boxes = detect(im, model, 0);
top = nms(boxes, 0.5);
showboxes(im, top);
%print(gcf, '-djpeg90', '-r0', [cls '.jpg']);
disp('detections');
disp('press any key to continue'); pause;

% get bounding boxes
bbox = getboxes(model, boxes);
top = nms(bbox, 0.5);
bbox = clipboxes(im, top);
showboxes(im, bbox);
disp('bounding boxes');
disp('press any key to continue'); pause;
