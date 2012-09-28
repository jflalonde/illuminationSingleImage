%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function lineHandle = displayAnglePie(centerAngle, devAngle, radius, nbPts, varargin)
%  Displays the pie angle in the orientation we want. Nicer than using
%  the built-in 'rose' function.
% 
% Input parameters:
%
% Output parameters:
%   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lineHandle = displayAnglePie(centerAngle, devAngle, radius, nbPts, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% rotate
centerAngle = -centerAngle+pi/2;

% compute arc
anglePts = linspace(centerAngle-devAngle, centerAngle+devAngle, nbPts);

% convert to cartesian coordinates
[xPts, yPts] = pol2cart(anglePts, repmat(radius, size(anglePts)));

% append origin
xPts = cat(2, 0, xPts, 0);
yPts = cat(2, 0, yPts, 0);

% plot
lineHandle = patch(xPts, yPts, 1, varargin{:});

% text
[centerPtX, centerPtY] = pol2cart(centerAngle, 1.25*radius);
textHandle = text(centerPtX, centerPtY, num2str(radius), 'HorizontalAlignment', 'center');