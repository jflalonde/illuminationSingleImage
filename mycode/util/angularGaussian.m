%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function angularProb = angularGaussian(mu, sigma, nbBins, alignHistogram)
% 
% Input parameters:
%
% Output parameters:
%   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [angularProb, binCenters] = angularGaussian(mu, sigma, nbBins, align)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 4
    align = 0;
end

nbSamples = 1001;
if align
    % even number
    nbSamples = nbSamples-1;
end

% build high-resolution gaussian centered at 0
x = linspace(-pi, pi, nbSamples);
y = normpdf(x, 0, sigma);
y = y./sum(y);

% rotate
x = mod(x + mu, 2*pi);
x(x>pi) = x(x>pi)-2*pi;

[h, histInd, binCenters] = angularHistogram(x, nbBins, align);

angularProb = zeros(1, nbBins);
for i=1:length(angularProb)
    angularProb(i) = sum(y(histInd==i));
end

% round off eror
angularProb = angularProb./sum(angularProb);

