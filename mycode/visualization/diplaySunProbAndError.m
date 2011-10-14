function [azimuthEstimate, zenithEstimate] = diplaySunProbAndError(probSun, sunAzimuths, focalLength, thetac, imgDims, ...
    gtSunZenith, gtSunAzimuth, cueName, varargin)

% parse arguments
defaultArgs = struct('DisplayGtSun', 1, 'EstimateZenith', 0, 'DrawFlipped', 0, 'Normalize', 0);
args = parseargs(defaultArgs, varargin{:});

[err, azimuthEstimate] = computeEstimationError(probSun, sunAzimuths, gtSunAzimuth, 2);
if ~isempty(azimuthEstimate)
    if args.EstimateZenith
        [m,mind] = max(probSun(:));
        [r,c] = ind2sub(size(probSun), mind);
        
        sunZeniths = linspace(0, pi/2, size(probSun,1)*2+1);
        sunZeniths = sunZeniths(2:2:end);
        
        azimuthEstimate = sunAzimuths(c);
        zenithEstimate = sunZeniths(r);
    else
        zenithEstimate = gtSunZenith;
    end
    
    % check if we have two equal estimates. If so, take minimum error (for
    % display purposes)
    if length(unique(azimuthEstimate))==1 && length(azimuthEstimate)>1
        [err, mind] = min(err, [], 2);
    else
        mind = 1;
    end

else
    % set zenith to -1, fake values to azimuth
    zenithEstimate = -1;
    azimuthEstimate = 0; mind = 1;
end

if ~args.DisplayGtSun
    gtSunZenith = [];
    gtSunAzimuth = [];
end

displaySunProbabilityVectorized(probSun, 1, ...
    'DrawCameraFrame', 1, 'FocalLength', focalLength, 'CamZenith', thetac, 'ImgDims', imgDims, ...
    'GtSunZenith', gtSunZenith, 'GtSunAzimuth', gtSunAzimuth, ...
    'EstSunZenith', zenithEstimate, 'EstSunAzimuth', azimuthEstimate(mind), ...
    'DrawFlipped', args.DrawFlipped, 'Normalize', args.Normalize);
% title(sprintf('P(Sun | %s), err = %.1fdeg', cueName, err(mind)*180/pi));
    