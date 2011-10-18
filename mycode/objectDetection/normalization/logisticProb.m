function p = logisticProb(AB, conf)

% original implementation by Platt
p = 1./ (1+exp(AB(1)*conf+AB(2)));

return;


% re-formulation proposed by [Lin, Lin, and Weng] make the algorithm
% more stable

A = AB(1); B = AB(2);
cond = A*conf+B;

posCondInd = cond >= 0;

p = zeros(size(cond));

% if cond >= 0
p(posCondInd) = exp(-cond(posCondInd)) ./ (1+exp(-cond(posCondInd)));

% if cond < 0
p(~posCondInd) = 1 ./ (1+exp(cond(~posCondInd)));

% if cond >= 0
%     p = exp(-cond) ./ (1+exp(-cond));
%     err = labels.*(cond) + log(1+exp(-cond));
% else
%     p = 1 ./ (1+exp(cond));
%     err = (labels-1).*(cond) + log(1+exp(cond));
% end

% err = -sum(labels.*log(p)+(1-labels).*log(1-p));