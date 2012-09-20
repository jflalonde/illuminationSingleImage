%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function skyFeatures = computeSkyFeatures(img, skyMask)
%  Computes features over the sky region of an image. Uses 3-D histograms
%  in HSV color space.
%  
% 
% Input parameters:
%  - img: input image
%  - skyMask: sky mask (1=sky, 0=no sky)
%
% Output parameters:
%  - skyFeatures: the 3-D HSV histogram
%   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function skyFeatures = computeSkyFeaturesHsv(img, skyMask)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imgLab = rgb2hsv(img);
imgLabVec = reshape(imgLab, size(img,1)*size(img,2), size(img,3));
        
% weighted histogram in Lab space of sky pixels. That's all
nbBins = 31;
% skyFeatures = myHistoNDWeighted(imgLabVec, skyMask(:), nbBins, [0 -100 -100], [100 100 100]); 
skyFeatures = myHistoND(imgLabVec(skyMask>0,:), nbBins, [0 0 0], [1 1 1]); 


        