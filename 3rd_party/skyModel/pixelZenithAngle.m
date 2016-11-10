%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function thetap = pixelZenithAngle(thetac, fc, up, vp)
%   Converts pixel coordinates to zenith angles.
% 
% Input parameters:
%  - thetac: camera zenith angle (in radians)
%  - fc: camera focal length
%  - up: x-coordinates of pixels in image
%  - vp: y-coordinates of pixels in image
%
% Output parameters:
%  - thetap: pixel zenith angle
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function thetap = pixelZenithAngle(thetac, fc, up, vp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

thetap = acos((sin(thetac).*vp+cos(thetac).*fc)./(fc.^2+up.^2+vp.^2).^(1/2));