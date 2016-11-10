%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function lum = exactSunModel(c, d, e, f, up, vp, vh, phi, phiSun, thetaSun)
%  Synthesizes the sun contribution to the sky model
% 
% Input parameters:
%  - c, d, e: Perez sky model parameters
%  - f: camera focal length (in pixels)
%  - up: x-coordinates of pixels in image
%  - vp: y-coordinates of pixels in image
%  - vh: horizon line (0 = center of image)
%  - phi: camera azimuth angle (in radians)
%  - phiSun: sun azimuth angle (in radians)
%  - thetaSun: sun zenith angle (in radians)
%
% Output parameters:
%  - lum: luminance map in image coordinates (same dimensions as up and up)
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lum = exactSunModel(c, d, e, f, up, vp, vh, phi, phiSun, thetaSun)

phic = phi;
thetac = pi/2+atan2(vh, f);

fc = f;
thetap = pixelZenithAngle(thetac, fc, up, vp);
phip = pixelAzimuthAngle(thetac, phic, fc, up, vp);

deltaPhi = abs(phiSun - phip);
gamma = acos(cos(thetaSun) .* cos(thetap) + sin(thetaSun) .* sin(thetap) .* cos(deltaPhi));

% plug in Perez sky model
lum = perezSunModel(c, d, e, gamma);

