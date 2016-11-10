%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function lum = exactGradientModel(a, b, f, up, vp, vh)
%  Synthesizes the sky gradient part only.
% 
% Input parameters:
%  - a, b: Perez sky model parameters
%  - f: camera focal length (in pixels)
%  - up: x-coordinates of pixels in image
%  - vp: y-coordinates of pixels in image
%  - vh: horizon line (0 = center of image)
%
% Output parameters:
%  - lum: luminance map in image coordinates (same dimensions as up and vp)
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lum = exactGradientModel(a, b, f, up, vp, vh)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% convert to camera parameters
thetac = pi/2+atan2(vh, f);
thetap = pixelZenithAngle(thetac, f, up, vp);

% plug in Perez sky model
lum = perezGradientModel(a, b, thetap);

