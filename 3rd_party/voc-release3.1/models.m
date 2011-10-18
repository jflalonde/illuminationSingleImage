function models(dir, suffix)

% models(dir, suffix)
% Make pictures of models.

globals;
pascal_init;

for i=1:length(VOCopts.classes)
  cls = VOCopts.classes{i};
  load([dir cls suffix]);
  visualizemodel(model);
  name = [cls '_model.jpg'];
  print('-djpeg95', name);
end
