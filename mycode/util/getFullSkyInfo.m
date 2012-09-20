%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [up, vp, lp] = getFullSkyInfo(skyMask, img, imgRGB, doFilter)
%  Retrieves useful information about the camera and the sky that will be
%  used for fitting.
% 
% Input parameters:
%  - skyMask: sky mask (1=sky, 0=no sky)
%  - img: input image (in whatever color space)
%  - imgRGB: image in RGB format
%
% Output parameters:
%  - up: x-coordinates of the visible sky
%  - vp: y-coordinates of the visible sky
%  - lp: (NxC) intensity of each visible sky pixel
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [up, vp, lp] = getFullSkyInfo(skyMask, img, imgRGB)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

skyMask = logical(skyMask);

%% Keep pixels that are correctly exposed (check original image)
threshUnSat = 254/255;
threshDark = 2/255;

indUnSat = true(size(img(:,:,1)));
indDark = true(size(img(:,:,1)));

for c=1:size(imgRGB,3)
    indUnSat = indUnSat & imgRGB(:,:,c) < threshUnSat;
    indDark = indDark & imgRGB(:,:,c) > threshDark;
end

indPx = indUnSat & indDark;
skyMask = (indPx & skyMask); 

%% Return correct indices
[ySky, xSky] = find(skyMask); 
[imgHeight, imgWidth, c] = size(img);

up = (xSky - imgWidth/2) - 0.5;
vp = (imgHeight/2 - ySky) + 0.5;

imgVec = reshape(img, imgWidth*imgHeight, c);
lp = imgVec(skyMask, :);

