%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function phip = pixelAzimuthAngle(thetac, phic, fc, up, vp)
%   Converts pixel coordinates to azimuth angles.
% 
% Input parameters:
%  - thetac: camera zenith angle (in radians)
%  - phic: camera azimuth angle (in radians)
%  - fc: camera focal length
%  - up: x-coordinates of pixels in image
%  - vp: y-coordinates of pixels in image
%
% Output parameters:
%  - phip: pixel azimuth angle
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function phip = pixelAzimuthAngle(thetac, phic, fc, up, vp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

phip = atan2((sin(phic).*sin(thetac).*fc-cos(phic).*up-sin(phic).*cos(thetac).*vp),(cos(phic).*sin(thetac).*fc+sin(phic).*up-cos(phic).*cos(thetac).*vp));
