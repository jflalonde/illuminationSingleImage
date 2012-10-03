%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function drawSunDial(img, camHeight, horizonLine)
%  
% 
% Input parameters:
%  - img: input image
%  - sunPosition: [theta phi]
%
% Output parameters:
%   
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function drawSunDialFromSunPosition(img, sunPosition, horizonLine, focalLength, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2007 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parse arguments
defaultArgs = struct('CameraHeight', 1.6, 'StickPosition', [size(img,2)/2 0.9.*size(img,1)], 'StickHeight', 1.5, ...
    'GtZenith', -1, 'GtAzimuth', 0, 'DrawFlipped', 0, 'Axes', []);
args = parseargs(defaultArgs, varargin{:});

if isempty(args.Axes)
    ax = gca;
else
    ax = args.Axes;
end
hold on;

objectWidth = 7;
objectColor = [1 0 0];
shadowColor = [0.2 0.2 0.8];
% shadowColor = hsv2rgb(rgb2hsv(objectColor).*[1 0.2 0.2]);
% shadowColor = objectColor.*0.5;

%% Find 3-D position on the ground where to draw the shadow
pos3D = convertLineImg23D(args.StickPosition(:), horizonLine, focalLength, args.CameraHeight, size(img,2)/2);

%% Find the ML sun direction
sunTheta = sunPosition(1);
sunPhi = sunPosition(2);

%% Draw the shadow line
if args.GtZenith >= 0
    drawShadowLine(args.GtAzimuth, args.GtZenith, pos3D, horizonLine, focalLength, args.CameraHeight, size(img,2)/2, args.StickHeight, ...
        [0.8 0 0], objectWidth);
end

drawShadowLine(sunPhi, sunTheta, pos3D, horizonLine, focalLength, args.CameraHeight, size(img,2)/2, args.StickHeight, ...
    shadowColor, objectWidth);

if args.DrawFlipped
    drawShadowLine(sunPhi+pi, sunTheta, pos3D, horizonLine, focalLength, args.CameraHeight, size(img,2)/2, args.StickHeight, ...
        shadowColor, objectWidth);
end

%% Draw the object on top
objectPx = convertLine3D2Img(cat(2, pos3D, pos3D + [0 args.StickHeight 0]'), horizonLine, focalLength, args.CameraHeight, size(img,2)/2);
plot(ax, objectPx(1,:), objectPx(2,:), 'LineWidth', objectWidth, 'Color', objectColor, 'Marker', '.', 'MarkerSize', objectWidth*3);


    function drawShadowLine(sunPhi, sunTheta, pos3D, horizonLine, focalLength, cameraHeight, u0, stickHeight, shadowColor, objectWidth)
        
        % sun is most likely to be visible
        shadowAngle = (pi/2 - sunPhi);
        shadowRadius = stickHeight*tan(pi-sunTheta);
        
        shadow3D = pos3D + [shadowRadius*cos(shadowAngle) 0 shadowRadius*sin(shadowAngle)]';
        if shadow3D(3) < 0.1
            v = pos3D-shadow3D; v = v./norm(v);
            shadow3D = shadow3D - (shadow3D(3)./v(3)-1).*v;
        end
        shadowPx = convertLine3D2Img(cat(2, pos3D, shadow3D), horizonLine, focalLength, cameraHeight, u0);
        plot(ax, shadowPx(1,:), shadowPx(2,:), 'LineWidth', objectWidth, 'Color', shadowColor, ...
            'Marker', '.', 'MarkerSize', objectWidth*3);
    end

end