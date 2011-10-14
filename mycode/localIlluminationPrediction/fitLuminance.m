%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [fOpt, yhOpt, oOpt, resnorm] = fitLuminanceFullZenith(xp, yp, lp, f0, yh0, maxyh, lz0, phiSun, thetaSun, varargin)
%  Fits the sky model to the gradient only in order to recover the horizon
%  line and the focal length of the camera.
%
% Input parameters:
%  - yp: y-coordinates of all input pixels (with respect to the center of the image, y-axis pointing up
%  - lp: raw luminance values observed at each pixel, scaled by mean luminance value observed at height ym (can be anywhere)
%  - ym: height where the mean luminance is used to rescale (see lp)
%
% Output parameters:
%  - lzOpt: optimal value for the zenith luminance
%  - resnorm: residual norm after fitting
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function kOpt = fitLuminance(xp, yp, lp, f, yh, phiCam, phiSun, thetaSun, channelInd)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 9
    % by default: optimize luminance
    channelInd = 3;
end

% use turbidity-related parameters
t = 2.17; % clear sky
skyParams = getTurbidityMapping(channelInd)*[t 1]';
a = skyParams(1); b = skyParams(2); c = skyParams(3); d = skyParams(4); e = skyParams(5);

% setup starting point
k0 = 1;

% lower and upper bound
lb = 0;
ub = inf;

% Levenberg-Marquadt non-linear least-squares
options = optimset('Display', 'off');
kOpt = lsqnonlin(@optLuminance, k0, lb, ub, options);

% function that we're trying to optimize
    function F = optLuminance(k)
        % compute the full-sky luminance ratio
        ratio = exactSkyModelRatio(a, b, c, d, e, f, xp, yp, yh, k, phiCam, phiSun, thetaSun);
        F = lp(:,3) - ratio;
    end
end


