function model = initmodel(pos, sbin, size)

% model = initmodel(pos, sbin, size)
% Initialize model structure.
%
% If not supplied the dimensions of the model template are computed
% from statistics in the postive examples.
% 
% This should be documented! :-)
% model.sbin
% model.interval
% model.numblocks
% model.numcomponents
% model.blocksizes
% model.regmult
% model.learnmult
% model.maxsize
% model.minsize
% model.rootfilters{i}
%   .size
%   .w
%   .blocklabel
% model.partfilters{i}
%   .w
%   .blocklabel
% model.defs{i}
%   .anchor
%   .w
%   .blocklabel
% model.offsets{i}
%   .w
%   .blocklabel
% model.components{i}
%   .rootindex
%   .parts{j}
%     .partindex
%     .defindex
%   .offsetindex
%   .dim
%   .numblocks

% pick mode of aspect ratios
h = [pos(:).y2]' - [pos(:).y1]' + 1;
w = [pos(:).x2]' - [pos(:).x1]' + 1;
xx = -2:.02:2;
filter = exp(-[-100:100].^2/400);
aspects = hist(log(h./w), xx);
aspects = convn(aspects, filter, 'same');
[peak, I] = max(aspects);
aspect = exp(xx(I));

% pick 20 percentile area
areas = sort(h.*w);
area = areas(floor(length(areas) * 0.2));
area = max(min(area, 5000), 3000);

% pick dimensions
w = sqrt(area/aspect);
h = w*aspect;

% size of HOG features
if nargin < 4
  model.sbin = 8;
else
  model.sbin = sbin;
end

% size of root filter
if nargin < 5
  model.rootfilters{1}.size = [round(h/model.sbin) round(w/model.sbin)];
else
  model.rootfilters{1}.size = size;
end

% set up offset 
model.offsets{1}.w = 0;
model.offsets{1}.blocklabel = 1;
model.blocksizes(1) = 1;
model.regmult(1) = 0;
model.learnmult(1) = 20;
model.lowerbounds{1} = -100;

% set up root filter
model.rootfilters{1}.w = zeros([model.rootfilters{1}.size 31]);
height = model.rootfilters{1}.size(1);
% root filter is symmetric
width = ceil(model.rootfilters{1}.size(2)/2);
model.rootfilters{1}.blocklabel = 2;
model.blocksizes(2) = width * height * 31;
model.regmult(2) = 1;
model.learnmult(2) = 1;
model.lowerbounds{2} = -100*ones(model.blocksizes(2),1);

% set up one component model
model.components{1}.rootindex = 1;
model.components{1}.offsetindex = 1;
model.components{1}.parts = {};
model.components{1}.dim = 2 + model.blocksizes(1) + model.blocksizes(2);
model.components{1}.numblocks = 2;

% initialize the rest of the model structure
model.interval = 10;
model.numcomponents = 1;
model.numblocks = 2;
model.partfilters = {};
model.defs = {};
model.maxsize = model.rootfilters{1}.size;
model.minsize = model.rootfilters{1}.size;
