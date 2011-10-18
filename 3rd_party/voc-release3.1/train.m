function model = train(name, model, pos, neg, warp, randneg, iter, ...
                       negiter, maxsize, keepsv, overlap, cont, C, J)

% model = train(name, model, pos, neg, warp, randneg, iter,
%               negiter, maxsize, keepsv, overlap, cont, C, J)
% Train LSVM.
%
% warp=1 uses warped positives
% warp=0 uses latent positives
% randneg=1 uses random negaties
% randneg=0 uses hard negatives
% iter is the number of training iterations
% negiter is the number of data-mining steps within each training iteration
% maxsize is the maximum size of the training data file
% keepsv=true keeps support vectors between iterations
% overlap is the minimum overlap in latent positive search
% cont=true we restart training from a previous run
% C & J are the parameters for LSVM objective function

if nargin < 9
  maxsize = 2^28;
end

if nargin < 10
  keepsv = false;
end

if nargin < 11
  overlap = 0.7;
end

if nargin < 12
  cont = false;
end

if nargin < 13
  C = 0.002*model.numcomponents;
end

if nargin < 14
  J = 1;
end

globals;
hdrfile = [tmpdir name '.hdr'];
datfile = [tmpdir name '.dat'];
modfile = [tmpdir name '.mod'];
inffile = [tmpdir name '.inf'];
lobfile = [tmpdir name '.lob'];

labelsize = 5;  % [label id level x y]
negpos = 0;     % last position in data mining

% approximate bound on the number of examples used in each iteration
dim = 0;
for i = 1:model.numcomponents
  dim = max(dim, model.components{i}.dim);
end
maxnum = floor(maxsize / (dim * 4));

if ~cont
  % reset data file
  fid = fopen(datfile, 'wb');
  fclose(fid);
  % reset header file
  writeheader(hdrfile, 0, labelsize, model);  
  % reset info file
  fid = fopen(inffile, 'w');
  fclose(fid);
  % reset initial model 
  fid = fopen(modfile, 'wb');
  fwrite(fid, zeros(sum(model.blocksizes), 1), 'double');
  fclose(fid);
  % reset lower bounds
  writelob(lobfile, model)
end

for t = 1:iter
  fprintf('iter: %d/%d\n', t, iter);
    
  % remove old positives
  [labels, ignore1, ignore2] = readinfo(inffile);
  I = find(labels == -1);
  rewritedat(datfile, inffile, hdrfile, I);
  num = length(I);

  % add new positives
  fid = fopen(datfile, 'a');
  if warp > 0
    numadded = poswarp(name, t, model, warp, pos, fid);
    numpositives = numadded;
  else
    [numadded, numpositives] = poslatent(name, t, model, pos, overlap, fid);
  end
  num = num + numadded;
  fclose(fid);

  for i = 1:model.numcomponents
    fprintf('component %d got %d positives\n', i, numpositives(i));
  end

  % data mine negatives
  for tneg = 1:negiter
    fprintf('iter: %d/%d, neg iter %d/%d\n', t, iter, tneg, negiter);
        
    % add new negatives
    fid = fopen(datfile, 'a');
    if randneg > 0
      num = num + negrandom(name, t, model, randneg, neg, maxnum-num, fid);
    else
      [numadded, negpos] = neghard(name, t, model, neg, maxsize, ...
                                   fid, negpos);
      num = num + numadded;
    end
    fclose(fid);
        
    % learn model
    writeheader(hdrfile, num, labelsize, model);
    % reset initial model 
    fid = fopen(modfile, 'wb');
    fwrite(fid, zeros(sum(model.blocksizes), 1), 'double');
    fclose(fid);
    cmd = sprintf('./learn %.4f %.4f %s %s %s %s %s', ...
                  C, J, hdrfile, datfile, modfile, inffile, lobfile);
    fprintf('executing: %s\n', cmd);
    status = unix(cmd);
    if status ~= 0
      fprintf('command `%s` failed\n', cmd);
      keyboard;
    end
    
    fprintf('parsing model\n');
    blocks = readmodel(modfile, model);
    model = parsemodel(model, blocks);
    [labels, vals, unique] = readinfo(inffile);
    
    % compute threshold for high recall
    P = find((labels == 1) .* unique);
    pos_vals = sort(vals(P));
    model.thresh = pos_vals(ceil(length(pos_vals)*0.05));

    % cache model
    save([cachedir name '_model_' num2str(t) '_' num2str(tneg)], 'model');
    
    % keep negative support vectors?
    if keepsv
      % N = find((labels == -1) .* unique .* (vals >= -1.1));
      % sv = round(maxnum/2);
      % if length(N) > sv
      %   N = N(randperm(length(N)));
      %   N = N(1:sv);
      % end
      % old caching rule
      U = find((labels == -1) .* unique);
      V = vals(U);
      [ignore, S] = sort(-V);
      sv = round(maxnum/2);
      if length(S) > sv
        S = S(1:sv);
      end
      N = U(S);
    else
      N = [];
    end    
    fprintf('rewriting data file\n');
    I = [P; N];
    rewritedat(datfile, inffile, hdrfile, I);
    num = length(I);    
    fprintf('cached %d positive and %d negative examples\n', ...
            length(P), length(N));    
  end
end

% get positive examples by warping positive bounding boxes
% we create virtual examples by flipping each image left to right
function num = poswarp(name, t, model, c, pos, fid)
numpos = length(pos);
warped = warppos(name, model, c, pos);
ridx = model.components{c}.rootindex;
oidx = model.components{c}.offsetindex;
rblocklabel = model.rootfilters{ridx}.blocklabel;
oblocklabel = model.offsets{oidx}.blocklabel;
dim = model.components{c}.dim;
width1 = ceil(model.rootfilters{ridx}.size(2)/2);
width2 = floor(model.rootfilters{ridx}.size(2)/2);
pixels = model.rootfilters{ridx}.size * model.sbin;
minsize = prod(pixels);
num = 0;
for i = 1:numpos
    fprintf('%s: iter %d: warped positive: %d/%d\n', name, t, i, numpos);
    bbox = [pos(i).x1 pos(i).y1 pos(i).x2 pos(i).y2];
    % skip small examples
    if (bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1) < minsize
      continue
    end    
    % get example
    im = warped{i};
    feat = features(im, model.sbin);
    feat(:,1:width2,:) = feat(:,1:width2,:) + flipfeat(feat(:,width1+1:end,:));
    feat = feat(:,1:width1,:);
    fwrite(fid, [1 2*i-1 0 0 0 2 dim], 'int32');
    fwrite(fid, [oblocklabel 1], 'single');
    fwrite(fid, rblocklabel, 'single');
    fwrite(fid, feat, 'single');    
    % get flipped example
    feat = features(im(:,end:-1:1,:), model.sbin);    
    feat(:,1:width2,:) = feat(:,1:width2,:) + flipfeat(feat(:,width1+1:end,:));
    feat = feat(:,1:width1,:);
    fwrite(fid, [1 2*i 0 0 0 2 dim], 'int32');
    fwrite(fid, [oblocklabel 1], 'single');
    fwrite(fid, rblocklabel, 'single');
    fwrite(fid, feat, 'single');
    num = num+2;    
end

% get positive examples using latent detections
% we create virtual examples by flipping each image left to right
function [num, numpositives] = poslatent(name, t, model, pos, overlap, fid)
numpos = length(pos);
model.interval = 5;
numpositives = zeros(model.numcomponents, 1);
pixels = model.minsize * model.sbin;
minsize = prod(pixels);
num = 0;
for i = 1:numpos
  fprintf('%s: iter %d: latent positive: %d/%d\n', name, t, i, numpos);
  bbox = [pos(i).x1 pos(i).y1 pos(i).x2 pos(i).y2];
  % skip small examples
  if (bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1) < minsize
    continue
  end
  % get example
  im = color(imread(pos(i).im));
  [im, bbox] = croppos(im, bbox);
  box = detect(im, model, 0, bbox, overlap, 1, fid, 2*i-1);
  if ~isempty(box)
    c = box(1,end-1);
    numpositives(c) = numpositives(c)+1;
    num = num+1;
    showboxes(im, box);
  end
  % get flipped example
  im = im(:,end:-1:1,:);
  oldx1 = bbox(1);
  oldx2 = bbox(3);
  bbox(1) = size(im,2) - oldx2 + 1;
  bbox(3) = size(im,2) - oldx1 + 1;
  box = detect(im, model, 0, bbox, overlap, 1, fid, 2*i);
  if ~isempty(box)
    c = box(1,end-1);
    numpositives(c) = numpositives(c)+1;
    num = num+1;
    showboxes(im, box);
  end
end

% get hard negative examples
function [num, j] = neghard(name, t, model, neg, maxsize, fid, negpos)
model.interval = 2;
numneg = length(neg);
num = 0;
j = negpos;
for i = 1:numneg
  j = j+1;
  if j > numneg
    j = 1;
  end
  fprintf('%s: iter %d: hard negatives: %d/%d (%d)\n', name, t, i, numneg, j);
  im = imread(neg(j).im);
  boxes = detect(im, model, -1.05, [], 0, -1, fid, j, maxsize);
  num = num+size(boxes, 1);
  showboxes(im, boxes);
  if ftell(fid) >= maxsize
    fprintf('reached memory limit\n');
    break;
  end
end

% get random negative examples
function num = negrandom(name, t, model, c, neg, maxnum, fid)
numneg = length(neg);
rndneg = floor(maxnum/numneg);
ridx = model.components{c}.rootindex;
oidx = model.components{c}.offsetindex;
rblocklabel = model.rootfilters{ridx}.blocklabel;
oblocklabel = model.offsets{oidx}.blocklabel;
rsize = model.rootfilters{ridx}.size;
width1 = ceil(rsize(2)/2);
width2 = floor(rsize(2)/2);
dim = model.components{c}.dim;
num = 0;
for i = 1:numneg
  fprintf('%s: iter %d: random negatives: %d/%d\n', name, t, i, numneg);
  im = color(imread(neg(i).im));
  feat = features(double(im), model.sbin);  
  if size(feat,2) > rsize(2) && size(feat,1) > rsize(1)
    for j = 1:rndneg
      x = random('unid', size(feat,2)-rsize(2)+1);
      y = random('unid', size(feat,1)-rsize(1)+1);
      f = feat(y:y+rsize(1)-1, x:x+rsize(2)-1,:);
      f(:,1:width2,:) = f(:,1:width2,:) + flipfeat(f(:,width1+1:end,:));
      f = f(:,1:width1,:);
      fwrite(fid, [-1 (i-1)*rndneg+j 0 0 0 2 dim], 'int32');
      fwrite(fid, [oblocklabel 1], 'single');
      fwrite(fid, rblocklabel, 'single');
      fwrite(fid, f, 'single');
    end
    num = num+rndneg;
  end
end

