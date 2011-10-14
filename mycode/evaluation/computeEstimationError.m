function [err, azimuthEstimates] = computeEstimationError(probSun, sunAzimuths, gtSunAzimuth, nbMaxima, varargin)

% parse arguments
defaultArgs = struct('EstimateJoint', 0);
args = parseargs(defaultArgs, varargin{:});

% constant estimate -> unavailable cue
if length(unique(probSun))==1
    err = -1;
    azimuthEstimates = [];
    return;
end

if args.EstimateJoint
    % get maximum over entire hemisphere
    azimuthEstimates = zeros(1, nbMaxima);
    err = zeros(1, nbMaxima);
    
    for i=1:nbMaxima
        
        [m,mind] = max(probSun(:));
        [r,c] = ind2sub(size(probSun), mind);

        azimuthEstimates(1,i) = sunAzimuths(c);
        err(1,i) = angularError(azimuthEstimates(1,i), gtSunAzimuth);
        
        probSun(min(max(r-1:r+1, 1), size(probSun,1)),min(max(c-1:c+1, 1), size(probSun,2))) = 0;
    end
    
else
    % use azimuth marginal only
    azProbSun = sum(probSun, 1);

    err = zeros(1, nbMaxima);
    azimuthEstimates = zeros(1, nbMaxima);
    for i=1:nbMaxima
        [m,mind] = max(azProbSun);
        azimuthEstimates(1,i) = sunAzimuths(mind);
        err(1,i) = angularError(azimuthEstimates(1,i), gtSunAzimuth);
        
        % zero-out maxima (and local surroundings)
        azProbSun(mind) = 0;
        azProbSun(mod(mind,length(azProbSun))+1) = 0;
        azProbSun(mod(mind-2,length(azProbSun))+1) = 0;
    end
end