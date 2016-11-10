%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  function ratio = exactSkyModelRatio(a, b, c, d, e, f, up, vp, vh, lz, phi, phiSun, thetaSun)
%    Synthesizes the full sky model, based on ratios of luminances
% 
% Input parameters:
%  - a, b, c, d, e: Perez sky model parameters
%  - f: camera focal length (in pixels)
%  - up: x-coordinates of pixels in image
%  - vp: y-coordinates of pixels in image
%  - vh: horizon line (0 = center of image)
%  - lz: zenith luminance
%  - phi: camera azimuth angle (in radians)
%  - phiSun: sun azimuth angle (in radians)
%  - thetaSun: sun zenith angle (in radians)
%
% Output parameters:
%  - ratio: ratio of luminances (with respect to zenith)
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ratio = exactSkyModelRatio(a, b, c, d, e, f, up, vp, vh, lz, phi, phiSun, thetaSun)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


ratio = lz .* exactSkyModel(a, b, c, d, e, f, up, vp, vh, phi, phiSun, thetaSun) ./ perezSkyModel(a, b, c, d, e, 0, thetaSun);
