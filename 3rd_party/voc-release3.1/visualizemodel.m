function visualizemodel(model, components)

% visualizemodel(model)
% Visualize a model.

clf;
if nargin < 2
  components = 1:model.numcomponents;
end

k = 1;
for i = components
  visualizecomponent(model, i, length(components), k);
  k = k+1;
end

function visualizecomponent(model, c, nc, k)

% make picture of root filter
pad = 2;
bs = 20;
w = foldHOG(model.rootfilters{model.components{c}.rootindex}.w);
scale = max(w(:));
im = HOGpicture(w, bs);
im = imresize(im, 2);
im = padarray(im, [pad pad], 0);
im = uint8(im * (255/scale));

% draw root
numparts = length(model.components{c}.parts);
if numparts > 0
  subplot(nc,3,1+3*(k-1));
else
  subplot(nc,1,k);
end
imagesc(im)
colormap gray;
axis equal;
axis off;

% draw parts and deformation model
if numparts > 0
  def_im = zeros(size(im));
  def_scale = 500;
  for i = 1:numparts
    % part filter
    w = model.partfilters{model.components{c}.parts{i}.partindex}.w;
    p = HOGpicture(foldHOG(w), bs);
    p = padarray(p, [pad pad], 0);
    p = uint8(p * (255/scale));    
    % border 
    p(:,1:2*pad) = 128;
    p(:,end-2*pad+1:end) = 128;
    p(1:2*pad,:) = 128;
    p(end-2*pad+1:end,:) = 128;
    % paste into root
    def = model.defs{model.components{c}.parts{i}.defindex};
    x1 = (def.anchor(1)-1)*bs+1;
    y1 = (def.anchor(2)-1)*bs+1;
    x2 = x1 + size(p, 2)-1;
    y2 = y1 + size(p, 1)-1;
    im(y1:y2, x1:x2) = p;
    
    % deformation model
    probex = size(p,2)/2;
    probey = size(p,1)/2;
    for y = 2*pad+1:size(p,1)-2*pad
      for x = 2*pad+1:size(p,2)-2*pad
        px = ((probex-x)/bs);
        py = ((probey-y)/bs);
        v = [px^2; px; py^2; py];
        p(y, x) = def.w * v * def_scale;
      end
    end
    def_im(y1:y2, x1:x2) = p;
  end
  
  % plot parts
  subplot(nc,3,2+3*(k-1));
  imagesc(im); 
  colormap gray;
  axis equal;
  axis off;
  
  % plot deformation model
  subplot(nc,3,3+3*(k-1));
  imagesc(def_im);
  colormap gray;
  axis equal;
  axis off;
end

% set(gcf, 'Color', 'white')