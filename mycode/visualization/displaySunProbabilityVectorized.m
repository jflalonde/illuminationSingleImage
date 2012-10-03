%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function displaySunProbabilityVectorized(latLongMap, alignHistogramAzimuths)
%  Display P(Sun) zenith and azimuth in a vectorized format. Much better than bitmaps! 
%
% Input parameters:
%
% Output parameters:
%   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function displaySunProbabilityVectorized(latLongMap, alignHistogramAzimuths, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parse arguments
defaultArgs = struct('DrawCameraFrame', 0, 'FocalLength', 0, 'CamZenith', 0, 'ImgDims', [], ...
    'GtSunZenith', [], 'GtSunAzimuth', [], ...
    'EstSunZenith', [], 'EstSunAzimuth', [], ...
    'DrawFlipped', 0, 'Normalize', 0, 'Axes', []);
args = parseargs(defaultArgs, varargin{:});

%% 
[h,i,c, phiEdges] = angularHistogram([], size(latLongMap, 2), alignHistogramAzimuths);
[h,i,c, thetaEdges] = angularHistogram([], size(latLongMap, 1)*4, 0);

thetaEdges = thetaEdges(thetaEdges>=0 & thetaEdges <= pi/2);

%% obtain patch coordinates
allPatches = {};

for a=1:size(latLongMap, 2)
    for z=1:size(latLongMap, 1)
        % order: clockwise, from bottom-left
        patchPhi = [phiEdges(a) phiEdges(a) phiEdges(a+1) phiEdges(a+1)];
        patchTheta = [thetaEdges(z+1) thetaEdges(z) thetaEdges(z) thetaEdges(z+1)];
        
        curPatch = cat(1, patchPhi, patchTheta);
        allPatches = cat(1, allPatches, {curPatch});
    end
end

%% warp patches to "sky angular" view
% h = figure; hold on;
hold on;  
for i=1:length(allPatches)
    patchPhi = allPatches{i}(1,:);
    patchTheta = allPatches{i}(2,:);
    
    % compute 3-D direction
    dx = sin(patchTheta).*sin(patchPhi);
    dy = cos(patchTheta);
    dz = -sin(patchTheta).*cos(patchPhi);

    % warp in image space
    thetaAngular = atan2(dx, -dz); % azimuth
    phiAngular = atan2(sqrt(dx.^2+dz.^2), dy); % zenith

    r = phiAngular./(pi/2);

    uAngular = r.*sin(thetaAngular)./2+1/2;
    vAngular = 1/2-r.*cos(thetaAngular)./2;

    indPos = find(dy>0);

    uAngular = uAngular(indPos);
    vAngular = vAngular(indPos);
    
    % display patch
    patch(uAngular, vAngular, latLongMap(i), 'EdgeColor', 'none', 'LineStyle', 'none');

end

if ~isempty(args.Axes)
    axis(args.Axes, 'equal', 'off');
%     set(h, 'Color', 'none');
    set(args.Axes, 'Color', 'none');
    if args.Normalize
        set(args.Axes, 'Clim', [0 1]);
    end
%     colormap(jet(1024));
end


%% Draw camera frame
if args.DrawCameraFrame
    nbPts = 100;
    imgHeight = args.ImgDims(1); imgWidth = args.ImgDims(2);

    % left vert
    x = repmat(-imgWidth/2, 1, nbPts);
    y = linspace(-imgHeight/2, imgHeight/2, nbPts);

    % top bar
    x = cat(2, x, linspace(-imgWidth/2, imgWidth/2, nbPts));
    y = cat(2, y, repmat(imgHeight/2, 1, nbPts));

    % right vert
    x = cat(2, x, repmat(imgWidth/2, 1, nbPts));
    y = cat(2, y, linspace(imgHeight/2, -imgHeight/2, nbPts));

    z = repmat(-args.FocalLength, size(y));
    camPts = cat(1, x, y, z);

    % rotate them
    theta = (args.CamZenith-pi/2);
    R = [1 0 0; 0 cos(theta) sin(theta); 0 -sin(theta) cos(theta)];
    camPtsR = R*camPts;
    camPtsRN = camPtsR ./ repmat(sqrt(sum(camPtsR.^2, 1)), 3, 1);

    thetaAngular = atan2(camPtsRN(1,:), -camPtsRN(3,:)); % azimuth
    phiAngular = atan2(sqrt(camPtsRN(1,:).^2+camPtsRN(3,:).^2), camPtsRN(2,:)); % zenith

    r = phiAngular./(pi/2);

    uAngular = r.*sin(thetaAngular)./2+1/2;
    vAngular = 1/2-r.*cos(thetaAngular)./2;

    indPos = find(camPtsRN(2,:)>0);

    uAngular = uAngular(indPos);
    vAngular = vAngular(indPos);

    % re-scale
%     uAngular = uAngular.*500;
%     vAngular = (1-vAngular).*500;

    plot(uAngular', vAngular', 'k-', 'LineWidth', 3);
end

%% Ground truth sun position
if ~isempty(args.GtSunZenith)
    addSun(args.GtSunZenith, args.GtSunAzimuth, 'c');
    if args.DrawFlipped
        addSun(args.GtSunZenith, args.GtSunAzimuth+pi, 'c');
    end
end

%% Estimated (max likelihood) sun position
if ~isempty(args.EstSunZenith)
    addSun(args.EstSunZenith, args.EstSunAzimuth, 'y');
    if args.DrawFlipped
        addSun(args.EstSunZenith, args.EstSunAzimuth+pi, 'y');
    end
end

%% Useful function: draw a sun position
    function addSun(sunZenith, sunAzimuth, color)
        r = sunZenith./(pi/2);

        uSun = r.*sin(sunAzimuth)./2+1/2;
        vSun = 1/2-r.*cos(sunAzimuth)./2;

%         sunPointsH = plot(uSun*500, (1-vSun)*500);
        sunPointsH = plot(uSun, vSun);
        set(sunPointsH, 'LineStyle', 'none', 'Marker', 'o', 'Color', 'k', 'MarkerSize', 15, 'LineWidth', 2, 'MarkerFaceColor', color);
    end
end