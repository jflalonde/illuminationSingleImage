function model = parsemodel(model, blocks)

% parsemodel(model, blocks)
% Update model parameters from weight vector representation.

% update root filters
for i = 1:length(model.rootfilters)
  s = size(model.rootfilters{i}.w);
  width1 = ceil(s(2)/2);
  width2 = floor(s(2)/2);
  s(2) = width1;
  f = reshape(blocks{model.rootfilters{i}.blocklabel}, s);
  model.rootfilters{i}.w(:,1:width1,:) = f;
  model.rootfilters{i}.w(:,width1+1:end,:) = flipfeat(f(:,1:width2,:));
end

% update offsets
for i = 1:length(model.offsets)
  model.offsets{i}.w = blocks{model.offsets{i}.blocklabel};
end

% update part filters and deformation models
for i = 1:length(model.partfilters)
  if model.partfilters{i}.fake
    continue;
  end

  model.defs{i}.w = reshape(blocks{model.defs{i}.blocklabel}, ...
                            size(model.defs{i}.w));
  partner = model.partfilters{i}.partner;
  if partner == 0
    % part is self-symmetric
    s = size(model.partfilters{i}.w);
    width1 = ceil(s(2)/2);
    width2 = floor(s(2)/2);
    s(2) = width1;
    f = reshape(blocks{model.partfilters{i}.blocklabel}, s);
    model.partfilters{i}.w(:,1:width1,:) = f;
    model.partfilters{i}.w(:,width1+1:end,:) = flipfeat(f(:,1:width2,:));
  else
    % part has a symmetric partner
    f = reshape(blocks{model.partfilters{i}.blocklabel}, ...
                size(model.partfilters{i}.w));
    model.partfilters{i}.w = f;
    model.partfilters{partner}.w = flipfeat(f);
    % flip linear term in horizontal deformation model
    model.defs{partner}.w = model.defs{i}.w;
    model.defs{partner}.w(2) = -1*model.defs{partner}.w(2);
  end
end
