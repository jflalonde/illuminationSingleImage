%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function reconstructedImg = reconstructSkyFromFullModel(imgDims, params, vh, f, phiCam, thetaSun, phiSun)
%  Synthesizes the sky according to the input parameters.
% 
% Input parameters:
%  - imgDims: dimensions of the output image [height width nbChannels]
%  - params: the weather coefficients (6xnbChannels, rows = a,b,c,d,e,k)
%  - vh: horizon line (where 0 = center of the image, pointing up)
%  - f: focal length of the camera
%  - phiCam: camera azimuth angle
%  - thetaSun: sun zenith angle
%  - phiSun: sun azimuth angle
%
% Output parameters:
%  - reconstructedImg: rendered sky (in the xyY color space)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function reconstructedImg = reconstructSkyFromFullModel(imgDims, params, vh, f, phiCam, thetaSun, phiSun)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imgHeight = imgDims(1);
imgWidth = imgDims(2);
nbChannels = imgDims(3);

[uRange, vRange] = meshgrid(1:imgWidth, 1:imgHeight);
upVec = (uRange - imgWidth/2) - 0.5;
vpVec = (imgHeight/2 - vRange) + 0.5;

vhImg = floor(imgHeight/2 - vh + 0.5);

% synthesize each channel
reconstructedImg = zeros(imgHeight, imgWidth, nbChannels);
for ch = 1:nbChannels
    reconstructedImg(:,:,ch) = exactSkyModelRatio(params(1,ch), params(2,ch), params(3,ch), params(4,ch), params(5,ch), ...
        f, upVec, vpVec, vh, params(6,ch), phiCam, phiSun, thetaSun);
end

% black out what's below the horizon
reconstructedImg(vhImg:end,:,:) = 0;

