%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [lineAngles, lineLengths] = computeAnglesFromShadowLines(shadowLines, focalLength, cameraHeight, horizonLine, imgHeight)
%  Computes the angle and length of each shadow line based on camera
%  parameters. 
% 
% Input parameters:
%
% Output parameters:
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [lineAngles, lineLengths, lineLengths3D] = computeAnglesFromShadowLines(shadowLines, focalLength, cameraHeight, horizonLine, imgHeight)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% warp in top-down view
shadowLines3D = zeros(size(shadowLines,1), 6);
shadowLines3D(:,[1 3 5]) = convertLineImg23D(shadowLines(:,[1 3])', horizonLine, focalLength, cameraHeight, imgHeight/2)';
shadowLines3D(:,[2 4 6]) = convertLineImg23D(shadowLines(:,[2 4])', horizonLine, focalLength, cameraHeight, imgHeight/2)';

% compute angle wrt camera (pos z direction)
lineAngles = pi/2-atan2(shadowLines3D(:,6)-shadowLines3D(:,5), shadowLines3D(:,2)-shadowLines3D(:,1));

lineLengths3D = sqrt((shadowLines3D(:,6)-shadowLines3D(:,5)).^2 + (shadowLines3D(:,2)-shadowLines3D(:,1)).^2);
lineLengths = sqrt((shadowLines(:,3)-shadowLines(:,1)).^2 + (shadowLines(:,4)-shadowLines(:,2)).^2);
