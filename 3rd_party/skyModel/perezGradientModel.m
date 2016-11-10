%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function lum = perezGradientModel(a, b, theta)
%  Synthesizes the sky according to the Perez sky model, the
%  gradient-dependent part only.
% 
% Input parameters:
%  - a, b: the 2 gradient-related weather coefficients
%  - theta: zenith angle of sky element
%
% Output parameters:
%  - lum: luminance map (same dimensions as theta)
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lum = perezGradientModel(a, b, theta)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lum = 1 + a.*exp(b./cos(theta));
