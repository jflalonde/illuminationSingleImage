%% Useful function: angular mean
function meanAngle = angularMean(angles, weights)

if nargin < 2
    weights = ones(size(angles));
end

[xa, ya] = pol2cart(angles, 1);

meanX = sum(xa.*weights)./sum(weights);
meanY = sum(ya.*weights)./sum(weights);

meanAngle = cart2pol(meanX, meanY);