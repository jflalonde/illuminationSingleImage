function [boxes] = detect(input, model, thresh, bbox, ...
                          overlap, label, fid, id, maxsize)

% boxes = detect(input, model, thresh, bbox, overlap, label, fid, id, maxsize)
% Detect objects in input using a model and a score threshold.
% Higher threshold leads to fewer detections.
%
% The function returns a matrix with one row per detected object.  The
% last column of each row gives the score of the detection.  The
% column before last specifies the component used for the detection.
% The first 4 columns specify the bounding box for the root filter and
% subsequent columns specify the bounding boxes of each part.
%
% If bbox is not empty, we pick best detection with significant overlap. 
% If label and fid are included, we write feature vectors to a data file.

if nargin > 3 && ~isempty(bbox)
  latent = true;
else
  latent = false;
end

if nargin > 6 && fid ~= 0
  write = true;
else
  write = false;
end

if nargin < 9
  maxsize = inf;
end

% we assume color images
input = color(input);

% prepare model for convolutions
rootfilters = [];
for i = 1:length(model.rootfilters)
  rootfilters{i} = model.rootfilters{i}.w;
end
partfilters = [];
for i = 1:length(model.partfilters)
  partfilters{i} = model.partfilters{i}.w;
end

% cache some data
for c = 1:model.numcomponents
  ridx{c} = model.components{c}.rootindex;
  oidx{c} = model.components{c}.offsetindex;
  root{c} = model.rootfilters{ridx{c}}.w;
  rsize{c} = [size(root{c},1) size(root{c},2)];
  numparts{c} = length(model.components{c}.parts);
  for j = 1:numparts{c}
    pidx{c,j} = model.components{c}.parts{j}.partindex;
    didx{c,j} = model.components{c}.parts{j}.defindex;
    part{c,j} = model.partfilters{pidx{c,j}}.w;
    psize{c,j} = [size(part{c,j},1) size(part{c,j},2)];
    % reverse map from partfilter index to (component, part#)
    rpidx{pidx{c,j}} = [c j];
  end
end

% we pad the feature maps to detect partially visible objects
padx = ceil(model.maxsize(2)/2+1);
pady = ceil(model.maxsize(1)/2+1);

% the feature pyramid
interval = model.interval;
[feat, scales] = featpyramid(input, model.sbin, interval);

% detect at each scale
best = -inf;
ex = [];
boxes = [];
for level = interval+1:length(feat)
  scale = model.sbin/scales(level);    
  if size(feat{level}, 1)+2*pady < model.maxsize(1) || ...
     size(feat{level}, 2)+2*padx < model.maxsize(2) || ...
     (write && ftell(fid) >= maxsize)
    continue;
  end
  
  if latent
    skip = true;
    for c = 1:model.numcomponents
      root_area = (rsize{c}(1)*scale) * (rsize{c}(2)*scale);
      box_area = (bbox(3)-bbox(1)+1) * (bbox(4)-bbox(2)+1);
      if (root_area/box_area) >= overlap && (box_area/root_area) >= overlap
        skip = false;
      end
    end
    if skip
      continue;
    end
  end
    
  % convolve feature maps with filters 
  featr = padarray(feat{level}, [pady padx 0], 0);
  rootmatch = fconv(featr, rootfilters, 1, length(rootfilters));
  if length(partfilters) > 0
    featp = padarray(feat{level-interval}, [2*pady 2*padx 0], 0);
    partmatch = fconv(featp, partfilters, 1, length(partfilters));
  end
  
  for c = 1:model.numcomponents
    % root score + offset
    score = rootmatch{ridx{c}} + model.offsets{oidx{c}}.w;  
    
    % add in parts
    for j = 1:numparts{c}
      def = model.defs{didx{c,j}}.w;
      anchor = model.defs{didx{c,j}}.anchor;
      % the anchor position is shifted to account for misalignment
      % between features at different resolutions
      ax{c,j} = anchor(1) + 1;
      ay{c,j} = anchor(2) + 1;
      match = partmatch{pidx{c,j}};
      [M, Ix{c,j}, Iy{c,j}] = dt(-match, def(1), def(2), def(3), def(4));
      score = score - M(ay{c,j}:2:ay{c,j}+2*(size(score,1)-1), ...
                        ax{c,j}:2:ax{c,j}+2*(size(score,2)-1));
    end

    if ~latent
      % get all good matches
      I = find(score > thresh);
      [Y, X] = ind2sub(size(score), I);        
      tmp = zeros(length(I), 4*(1+numparts{c})+2);
      for i = 1:length(I)
        x = X(i);
        y = Y(i);
        [x1, y1, x2, y2] = rootbox(x, y, scale, padx, pady, rsize{c});
        b = [x1 y1 x2 y2];
        if write
          rblocklabel = model.rootfilters{ridx{c}}.blocklabel;
          oblocklabel = model.offsets{oidx{c}}.blocklabel;      
          f = featr(y:y+rsize{c}(1)-1, x:x+rsize{c}(2)-1, :);
          xc = round(x + rsize{c}(2)/2 - padx);
          yc = round(y + rsize{c}(1)/2 - pady);
          ex = [];
          ex.header = [label; id; level; xc; yc; ...
                       model.components{c}.numblocks; ...
                       model.components{c}.dim];
          ex.offset.bl = oblocklabel;
          ex.offset.w = 1;
          ex.root.bl = rblocklabel;
          width1 = ceil(rsize{c}(2)/2);
          width2 = floor(rsize{c}(2)/2);
          f(:,1:width2,:) = f(:,1:width2,:) + flipfeat(f(:,width1+1:end,:));
          ex.root.w = f(:,1:width1,:);
          ex.part = [];
        end
        for j = 1:numparts{c}
          [probex, probey, px, py, px1, py1, px2, py2] = ...
              partbox(x, y, ax{c,j}, ay{c,j}, scale, padx, pady, ...
                      psize{c,j}, Ix{c,j}, Iy{c,j});
          b = [b px1 py1 px2 py2];
          if write
            if model.partfilters{pidx{c,j}}.fake
              continue;
            end
            pblocklabel = model.partfilters{pidx{c,j}}.blocklabel;
            dblocklabel = model.defs{didx{c,j}}.blocklabel;
            f = featp(py:py+psize{c,j}(1)-1,px:px+psize{c,j}(2)-1,:);
            def = -[(probex-px)^2; probex-px; (probey-py)^2; probey-py];
            partner = model.partfilters{pidx{c,j}}.partner;
            if partner > 0
              k = rpidx{partner}(2);
              [kprobex, kprobey, kpx, kpy, kpx1, kpy1, kpx2, kpy2] = ...
                  partbox(x, y, ax{c,k}, ay{c,k}, scale, padx, pady, ...
                          psize{c,k}, Ix{c,k}, Iy{c,k});
              kf = featp(kpy:kpy+psize{c,k}(1)-1,kpx:kpx+psize{c,k}(2)-1,:);
              % flip linear term in horizontal deformation model
              kdef = -[(kprobex-kpx)^2; kpx-kprobex; ...
                       (kprobey-kpy)^2; kprobey-kpy];
              f = f + flipfeat(kf);
              def = def + kdef;
            else
              width1 = ceil(psize{c,j}(2)/2);
              width2 = floor(psize{c,j}(2)/2);
              f(:,1:width2,:) = f(:,1:width2,:) + flipfeat(f(:,width1+1:end,:));
              f = f(:,1:width1,:);
            end
            ex.part(j).bl = pblocklabel;
            ex.part(j).w = f;
            ex.def(j).bl = dblocklabel;
            ex.def(j).w = def;
          end
        end
        if write
          exwrite(fid, ex);
        end
        tmp(i,:) = [b c score(I(i))];
      end
      boxes = [boxes; tmp];
    end

    if latent
      % get best match
      for x = 1:size(score,2)
        for y = 1:size(score,1)
          if score(y, x) > best
            [x1, y1, x2, y2] = rootbox(x, y, scale, padx, pady, rsize{c});
            % intesection with bbox
            xx1 = max(x1, bbox(1));
            yy1 = max(y1, bbox(2));
            xx2 = min(x2, bbox(3));
            yy2 = min(y2, bbox(4));
            w = (xx2-xx1+1);
            h = (yy2-yy1+1);
            if w > 0 && h > 0
              % check overlap with bbox
              inter = w*h;
              a = (x2-x1+1) * (y2-y1+1);
              b = (bbox(3)-bbox(1)+1) * (bbox(4)-bbox(2)+1);
              o = inter / (a+b-inter);
              if (o >= overlap)
                best = score(y, x);
                boxes = [x1 y1 x2 y2];
                if write
                  f = featr(y:y+rsize{c}(1)-1, x:x+rsize{c}(2)-1, :);
                  rblocklabel = model.rootfilters{ridx{c}}.blocklabel;
                  oblocklabel = model.offsets{oidx{c}}.blocklabel;      
                  xc = round(x + rsize{c}(2)/2 - padx);
                  yc = round(y + rsize{c}(1)/2 - pady);          
                  ex = [];
                  ex.header = [label; id; level; xc; yc; ...
                               model.components{c}.numblocks; ...
                               model.components{c}.dim];
                  ex.offset.bl = oblocklabel;
                  ex.offset.w = 1;
                  ex.root.bl = rblocklabel;
                  width1 = ceil(rsize{c}(2)/2);
                  width2 = floor(rsize{c}(2)/2);
                  f(:,1:width2,:) = f(:,1:width2,:) + ...
                      flipfeat(f(:,width1+1:end,:));
                  ex.root.w = f(:,1:width1,:);
                  ex.part = [];
                end
                for j = 1:numparts{c}
                  [probex, probey, px, py, px1, py1, px2, py2] = ...
                      partbox(x, y, ax{c,j}, ay{c,j}, scale, ...
                              padx, pady, psize{c,j}, Ix{c,j}, Iy{c,j});
                  boxes = [boxes px1 py1 px2 py2];
                  if write
                    if model.partfilters{pidx{c,j}}.fake
                      continue;
                    end
                    p = featp(py:py+psize{c,j}(1)-1, ...
                              px:px+psize{c,j}(2)-1, :);
                    def = -[(probex-px)^2; probex-px; (probey-py)^2; probey-py];
                    pblocklabel = model.partfilters{pidx{c,j}}.blocklabel;
                    dblocklabel = model.defs{didx{c,j}}.blocklabel;
                    partner = model.partfilters{pidx{c,j}}.partner;
                    if partner > 0
                      k = rpidx{partner}(2);
                      [kprobex, kprobey, kpx, kpy, kpx1, kpy1, kpx2, kpy2] = ...
                          partbox(x, y, ax{c,k}, ay{c,k}, scale, padx, pady, ...
                                  psize{c,k}, Ix{c,k}, Iy{c,k});
                      kp = featp(kpy:kpy+psize{c,k}(1)-1, ...
                                 kpx:kpx+psize{c,k}(2)-1, :);
                      % flip linear term in horizontal deformation model
                      kdef = -[(kprobex-kpx)^2; kpx-kprobex; ...
                               (kprobey-kpy)^2; kprobey-kpy];
                      p = p + flipfeat(kp);
                      def = def + kdef;
                    else
                      width1 = ceil(psize{c,j}(2)/2);
                      width2 = floor(psize{c,j}(2)/2);
                      p(:,1:width2,:) = p(:,1:width2,:) + ...
                          flipfeat(p(:,width1+1:end,:));
                      p = p(:,1:width1,:);
                    end
                    ex.part(j).bl = pblocklabel;
                    ex.part(j).w = p;
                    ex.def(j).bl = dblocklabel;
                    ex.def(j).w = def;
                  end
                end
                boxes = [boxes c best];
              end
            end
          end
        end
      end
    end
  end
end

if latent && write && ~isempty(ex)
  exwrite(fid, ex);
end

% The functions below compute a bounding box for a root or part 
% template placed in the feature hierarchy.
%
% coordinates need to be transformed to take into account:
% 1. padding from convolution
% 2. scaling due to sbin & image subsampling
% 3. offset from feature computation    

function [x1, y1, x2, y2] = rootbox(x, y, scale, padx, pady, rsize)
x1 = (x-padx)*scale+1;
y1 = (y-pady)*scale+1;
x2 = x1 + rsize(2)*scale - 1;
y2 = y1 + rsize(1)*scale - 1;

function [probex, probey, px, py, px1, py1, px2, py2] = ...
    partbox(x, y, ax, ay, scale, padx, pady, psize, Ix, Iy)
probex = (x-1)*2+ax;
probey = (y-1)*2+ay;
px = double(Ix(probey, probex));
py = double(Iy(probey, probex));
px1 = ((px-2)/2+1-padx)*scale+1;
py1 = ((py-2)/2+1-pady)*scale+1;
px2 = px1 + psize(2)*scale/2 - 1;
py2 = py1 + psize(1)*scale/2 - 1;

% write an example to the data file
function exwrite(fid, ex)
fwrite(fid, ex.header, 'int32');
buf = [ex.offset.bl; ex.offset.w(:); ...
       ex.root.bl; ex.root.w(:)];
fwrite(fid, buf, 'single');
for j = 1:length(ex.part)
  if ~isempty(ex.part(j).w)
    buf = [ex.part(j).bl; ex.part(j).w(:); ...
           ex.def(j).bl; ex.def(j).w(:)];
    fwrite(fid, buf, 'single');
  end
end
