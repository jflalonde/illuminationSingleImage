function model = pascal_train(cls, n)

% model = pascal_train(cls)
% Train a model using the PASCAL dataset.

globals; 
[pos, neg] = pascal_data(cls);
spos = split(pos, n);

% train root filters using warped positives & random negatives
try
  load([cachedir cls '_random']);
catch
  for i=1:n
    models{i} = initmodel(spos{i});
    models{i} = train(cls, models{i}, spos{i}, neg, 1, 1, 1, 1, 2^28);
  end
  save([cachedir cls '_random'], 'models');
end

% merge models and train using latent detections & hard negatives
try 
  load([cachedir cls '_hard']);
catch
  model = mergemodels(models);
  model = train(cls, model, pos, neg(1:200), 0, 0, 2, 2, 2^28, true, 0.7);
  save([cachedir cls '_hard'], 'model');
end

% add parts and update models using latent detections & hard negatives.
try 
  load([cachedir cls '_parts']);
catch
  for i=1:n
    model = addparts(model, i, 6);
  end 
  % use more data mining iterations in the beginning
  model = train(cls, model, pos, neg(1:200), 0, 0, 1, 4, 2^30, true, 0.7);
  model = train(cls, model, pos, neg(1:200), 0, 0, 6, 2, 2^30, true, 0.7, true);
  save([cachedir cls '_parts'], 'model');
end

% update models using full set of negatives.
try 
  load([cachedir cls '_mine']);
catch
  model = train(cls, model, pos, neg, 0, 0, 1, 3, 2^30, true, 0.7, true, ...
                0.003*model.numcomponents, 2);
  save([cachedir cls '_mine'], 'model');
end

% train bounding box prediction
try
  load([cachedir cls '_final']);
catch
  model = trainbox(cls, model, pos, 0.7);
  save([cachedir cls '_final'], 'model');
end
