function report(dir, suffix, table)

% report(dir, suffix)
% Report AP scores for all models.
% If table=1 we output an HTML table.
% If table=2 we output a latex table.

globals;
pascal_init;

for i=1:length(VOCopts.classes)
  cls = VOCopts.classes{i};
  try
    load([dir cls suffix]);
    score(i) = ap;
    fprintf('%s %.3f\n', cls, ap);
  catch
    score(i) = ap;
    fprintf('%s\n', cls);
  end
end
fprintf('average %.3f\n', mean(score));

% HTML table
if nargin > 2 && table == 1
  fprintf('<table border="0" cellspacing="10"><tr>\n');
  fprintf('<td>dir=%s, suffix=%s</td>\n', dir, suffix);
  for i=1:length(VOCopts.classes)
    fprintf('<td><b>%s</b></td>\n', VOCopts.classes{i});
  end
  fprintf('</tr><tr><td></td>\n');
  for i=1:length(VOCopts.classes)
    fprintf('<td>%.3f</td>\n', score(i));
  end
  fprintf('</tr></table>\n');
end

% latex table
if nargin > 2 && table == 2
  % header
  fprintf('dir=%s, suffix=%s\n', dir, suffix);
  fprintf('\\begin{tabular}{');
  for i=1:length(VOCopts.classes)
    fprintf('c');
  end
  fprintf('}\n');

  % category names
  for i=1:length(VOCopts.classes)
    fprintf('%s', VOCopts.classes{i});
    if i < length(VOCopts.classes)
      fprintf(' & ');
    end  
  end
  fprintf(' \\\\ \n');
    
  % scores
  for i=1:length(VOCopts.classes)
    fprintf('%.3f', score(i));
    if i < length(VOCopts.classes)
      fprintf(' & ');
    end
  end
  
  % end table
  fprintf('\n\\end{tabular}\n');
end
