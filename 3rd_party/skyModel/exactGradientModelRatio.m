%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function lum = exactGradientModel(a, b, f, up, vp, vh)
% Compute the ratio of luminance with respect to an arbitrary elevation
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
function ratio = exactGradientModelRatio(a, b, f, up, vp, vh, lz)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


ratio = lz .* exactGradientModel(a, b, f, up, vp, vh) ./ perezGradientModel(a, b, 0);
