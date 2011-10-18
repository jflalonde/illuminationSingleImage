function model = mergemodels(models)

% model = mergemodels(models)
% Merge a set of models into a single mixture model.

model = models{1};

for m = 2:length(models)
  % merge offsets
  no = length(model.offsets);
  for i = 1:length(models{m}.offsets)
    oldblocklabel = models{m}.offsets{i}.blocklabel;
    newblocklabel = model.numblocks+1;
    model.numblocks = newblocklabel;
    model.offsets{no+i} = models{m}.offsets{i};
    model.offsets{no+i}.blocklabel = newblocklabel;
    model.blocksizes(newblocklabel) = models{m}.blocksizes(oldblocklabel);
    model.regmult(newblocklabel) = models{m}.regmult(oldblocklabel);
    model.learnmult(newblocklabel) = models{m}.learnmult(oldblocklabel);
    model.lowerbounds{newblocklabel} = models{m}.lowerbounds{oldblocklabel};
  end

  % merge rootfilters
  nr = length(model.rootfilters);
  for i = 1:length(models{m}.rootfilters)
    oldblocklabel = models{m}.rootfilters{i}.blocklabel;
    newblocklabel = model.numblocks+1;
    model.numblocks = newblocklabel;        
    model.rootfilters{nr+i} = models{m}.rootfilters{i};
    model.rootfilters{nr+i}.blocklabel = newblocklabel;
    model.blocksizes(newblocklabel) = models{m}.blocksizes(oldblocklabel);
    model.regmult(newblocklabel) = models{m}.regmult(oldblocklabel);
    model.learnmult(newblocklabel) = models{m}.learnmult(oldblocklabel);
    model.lowerbounds{newblocklabel} = models{m}.lowerbounds{oldblocklabel};
  end
  
  % merge partfilters
  np = length(model.partfilters);
  for i = 1:length(models{m}.partfilters)
    model.partfilters{np+i} = models{m}.partfilters{i};
    if model.partfilters{np+i}.partner > 0
      model.partfilters{np+i}.partner = model.partfilters{np+i}.partner + np;
    end
    if ~models{m}.partfilters{i}.fake
      oldblocklabel = models{m}.partfilters{i}.blocklabel;
      newblocklabel = model.numblocks+1;
      model.numblocks = newblocklabel;
      model.partfilters{np+i}.blocklabel = newblocklabel;
      model.blocksizes(newblocklabel) = models{m}.blocksizes(oldblocklabel);
      model.regmult(newblocklabel) = models{m}.regmult(oldblocklabel);
      model.learnmult(newblocklabel) = models{m}.learnmult(oldblocklabel);
      model.lowerbounds{newblocklabel} = models{m}.lowerbounds{oldblocklabel};
    end
  end

  % merge def params
  nd = length(model.defs);
  for i = 1:length(models{m}.defs)
    model.defs{nd+i} = models{m}.defs{i};
    if ~models{m}.partfilters{i}.fake
      oldblocklabel = models{m}.defs{i}.blocklabel;
      newblocklabel = model.numblocks+1;
      model.numblocks = newblocklabel;        
      model.defs{nd+i}.blocklabel = newblocklabel;
      model.blocksizes(newblocklabel) = models{m}.blocksizes(oldblocklabel);
      model.regmult(newblocklabel) = models{m}.regmult(oldblocklabel);
      model.learnmult(newblocklabel) = models{m}.learnmult(oldblocklabel);
      model.lowerbounds{newblocklabel} = models{m}.lowerbounds{oldblocklabel};
    end
  end

  % merge components
  nc = model.numcomponents;
  for i = 1:models{m}.numcomponents
    model.numcomponents = model.numcomponents+1;
    model.components{nc+i} = models{m}.components{i};
    model.components{nc+i}.offsetindex = ...
        models{m}.components{i}.offsetindex + no;
    model.components{nc+i}.rootindex = ...
        models{m}.components{i}.rootindex + nr;    
    for j = 1:length(model.components{nc+i}.parts)
      model.components{nc+i}.parts{j}.partindex = ...
          model.components{nc+i}.parts{j}.partindex + np;
      model.components{nc+i}.parts{j}.defindex = ...
          model.components{nc+i}.parts{j}.defindex + nd;
    end
  end

  model.maxsize = max(model.maxsize, models{m}.maxsize);
  model.minsize = min(model.minsize, models{m}.minsize);
end
