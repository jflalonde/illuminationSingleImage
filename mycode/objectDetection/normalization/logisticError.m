function err = logisticError(AB, conf, labels)

% original implementation

p = logisticProb(AB, conf);
err = -sum(labels.*log(p)+(1-labels).*log(1-p));
return;

% re-formulation proposed by Lin, Lin, and Weng make the algorithm
% more stable

A = AB(1); B = AB(2);
cond = A*conf+B;

posCondInd = cond >= 0;

% err = -sum(labels.*log(p)+(1-labels).*log(1-p));
err = zeros(size(cond));

% if cond >= 0
err(posCondInd) = labels(posCondInd).*(cond(posCondInd)) + log(1+exp(-cond(posCondInd)));

% if cond < 0
err(~posCondInd) = (labels(~posCondInd)-1).*(cond(~posCondInd)) + log(1+exp(cond(~posCondInd)));

err = sum(err);
