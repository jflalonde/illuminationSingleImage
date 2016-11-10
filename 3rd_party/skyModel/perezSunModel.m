%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function lum = perezSunModel(c, d, e, theta, gamma)
%  Synthesizes the sun contribution to the sky model
% 
% Input parameters:
%  - c, d, e: the 3 sun-related weather coefficients
%  - theta: zenith angle of sky element
%  - gamma: angular difference between sky element and sun
%
% Output parameters:
%  - lum: luminance map (same dimensions as theta, gamma)
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lum = perezSunModel(c, d, e, gamma)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lum = 1 + c.*exp(d.*gamma) + e.*cos(gamma).^2;
