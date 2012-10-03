%% Useful function: median line intensity
function [medianIntensities, linesX, linesY] = medianLineIntensity(img, lines, interpType)

if nargin == 2
    interpType = 'linear';
end

% get mean intensity on the right
v = [lines(:,2)-lines(:,1) lines(:,4)-lines(:,3)];

% one point per pixel (densely sampled)
lineLengths = sqrt(sum(v.^2, 2));
nbPts = floor(lineLengths);

linesX = arrayfun(@(i) repmat(lines(i,1), 1, nbPts(i)) + linspace(0,1,nbPts(i)).*repmat(v(i,1), 1, nbPts(i)), (1:length(nbPts))', 'UniformOutput', 0);
linesY = arrayfun(@(i) repmat(lines(i,3), 1, nbPts(i)) + linspace(0,1,nbPts(i)).*repmat(v(i,2), 1, nbPts(i)), (1:length(nbPts))', 'UniformOutput', 0);

nbChannels = size(img, 3);
medianIntensities = cell(size(lines, 1), nbChannels);
for c=1:nbChannels
    medianIntensities(:,c) = cellfun(@(x,y) interp2(1:size(img,2), 1:size(img,1), img(:,:,c), x, y, interpType), linesX, linesY, 'UniformOutput', 0)';
end
