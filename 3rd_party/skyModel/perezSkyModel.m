%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function lum = perezSkyModel(a, b, c, d, e, theta, gamma)
%  Synthesizes the sky according to the Perez sky model.
% 
% Input parameters:
%  - a, b, c, d, e: the 5 weather coefficients
%  - theta: zenith angle of sky element
%  - gamma: angular difference between sky element and sun
%
% Output parameters:
%  - lum: luminance map (same dimensions as theta, gamma)
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lum = perezSkyModel(a, b, c, d, e, theta, gamma)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lum = perezGradientModel(a, b, theta) .* perezSunModel(c, d, e, gamma);
