function model = addparts(model, c, numparts)

% model = addparts(model, c, numparts)
% Initialize parts from root filter.

% interpolate root filter
ridx = model.components{c}.rootindex;
weights = imresize(model.rootfilters{ridx}.w, 2, 'bicubic');

% we select parts using energy of positive weights
energy = sum(max(weights, 0).^2, 3);

% force the model to be symmetric with respect to the y axis
energy = energy + energy(:,end:-1:1);

% pick part sizes so they can approximatelly cover the object
area = prod(model.rootfilters{ridx}.size) * 4 / numparts;

% possible part shapes
k = 0;
for h = 3:1:size(weights, 1)-2
  for w = 3:1:size(weights, 2)-2
    if (w*h <= area*1.2 && w*h >= area && ...
        w >= h-4 && w <= h+4 && h >= w-4 && h <= w+4)
      k = k+1;
      template{k} = fspecial('average', [h w]);
    end
  end
end
  
% picking parts: at each iteration we pick a pair of symmetric parts
% or a part in the center of the template
numadded = 0;
while numadded < numparts
  % stop if we covered 80% of the object
  % covered = sum(sum(energy == 0));
  % if covered > prod(size(energy))*0.80
  %   break;
  % end

  for i = 1:k
    score = conv2(energy, template{i}, 'valid');
    tmp = score;
    
    % we don't want symmetric parts to overlap 
    % so we "zero" the score of certain placements
    center = size(energy, 2)/2;
    z = max(center-size(template{i}, 2)+2, 1);
    score(:,z:end) = -inf;
    
    % we don't want symmetric parts if we only have one left to pick
    if numadded == numparts-1
      score(:,:) = -inf;
    end
    
    % we always allow centered parts 
    m = size(template{i}, 2)/2;
    if m == round(m)
      score(:,center-m+1) = tmp(:,center-m+1);
    end
    
    % pick best part with this shape
    [v, Y] = max(score);
    [v, x] = max(v);
    y = Y(x);
    ys(i) = y;
    xs(i) = x;
    vs(i) = v;
  end
  
  % pick best part, over all shapes
  [foo, i] = max(vs);

  % determine if the part has a symmetric partner
  xsp = size(weights, 2)-(xs(i)+size(template{i}, 2)-1)+1;
  haspartner = (xsp ~= xs(i));

  % add part
  [model, energy, pidx] = add(model, energy, weights, template{i}, ...
                              xs(i), ys(i), c, haspartner, false);
  numadded = numadded + 1;
  
  % add symmetric part
  if haspartner
    [model, energy, partner] = add(model, energy, weights, template{i}, ...
                                   xsp, ys(i), c, haspartner, true);
    numadded = numadded + 1;
    % indicate that these parts mirror eachother
    model.partfilters{pidx}.partner = partner;
    model.partfilters{partner}.partner = pidx;
  end
end

function [model, energy, pidx] = add(model, energy, w, template, ...
                                     x, y, c, haspartner, fake)
% add partfilter
pidx = length(model.partfilters) + 1;
model.partfilters{pidx}.w = ...
    w(y:y+size(template,1)-1, x:x+size(template,2)-1, :);
model.partfilters{pidx}.fake = fake;
model.partfilters{pidx}.partner = 0;

height = size(template,1);
% parts without symmetric partners are defined using symmetric filters
if haspartner
  width = ceil(size(template,2));
else
  width = ceil(size(template,2)/2);
end

% add feature block
if ~fake
  model.numblocks = model.numblocks + 1;
  model.partfilters{pidx}.blocklabel = model.numblocks;
  model.blocksizes(model.numblocks) = width * height * 31;  
  wsize = model.blocksizes(model.numblocks);
  model.regmult(model.numblocks) = 1;
  model.learnmult(model.numblocks) = 1;
  model.lowerbounds{model.numblocks} = -100*ones(wsize,1);
end

% add deformation model
didx = length(model.defs) + 1;
model.defs{didx}.anchor = [x y];
model.defs{didx}.w = [0.1 0 0.1 0];
if ~fake
  model.numblocks = model.numblocks + 1;
  model.defs{didx}.blocklabel = model.numblocks;
  model.blocksizes(model.numblocks) = 4;
  model.regmult(model.numblocks) = 10;
  model.learnmult(model.numblocks) = 0.1;
  model.lowerbounds{model.numblocks} = [0.01 -100 0.01 -100];
end

% link part to component
j = length(model.components{c}.parts) + 1;
model.components{c}.parts{j}.partindex = pidx;
model.components{c}.parts{j}.defindex = didx;
if ~fake
  model.components{c}.dim = ...
      model.components{c}.dim + 6 + wsize;
  model.components{c}.numblocks = model.components{c}.numblocks + 2;
end

% zero energy in root
for xp = x:x+size(template,2)-1
  for yp = y:y+size(template,1)-1
    energy(yp, xp) = 0;
  end
end
