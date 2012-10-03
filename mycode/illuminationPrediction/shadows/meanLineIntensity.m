%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function meanIntensities = meanLineIntensity(img, lines, doRobust)
%  Computes the mean intensity along each line
% 
% Input parameters:
%  - img: input image
%  - lines: input lines
%  - doRobust: throw away outliers before computing the mean intensity
%
% Output parameters:
%  - meanIntensities: mean intensity for each input line
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function meanIntensities = meanLineIntensity(img, lines, doRobust)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nbPts = 30;

% sample points along each line 
v = [lines(:,2)-lines(:,1) lines(:,4)-lines(:,3)];

linesX = repmat(lines(:,1), 1, nbPts) + repmat(linspace(0,1,nbPts), size(lines,1), 1).*repmat(v(:,1), 1, nbPts);
linesY = repmat(lines(:,3), 1, nbPts) + repmat(linspace(0,1,nbPts), size(lines,1), 1).*repmat(v(:,2), 1, nbPts);

% compute "robust" mean, between 5 and 95 prctiles
intensities = interp2(1:size(img,2), 1:size(img,1), img, linesX, linesY);
if doRobust
    indValid = intensities>repmat(prctile(intensities, 5, 2), 1, size(intensities,2)) & intensities < repmat(prctile(intensities, 95, 2), 1, size(intensities, 2));
else
    indValid = ones(size(intensities));
end

meanIntensities = zeros(size(indValid, 1), 1);
for j=1:size(indValid, 1)
    meanIntensities(j) = mean(intensities(j, indValid(j,:)));
end