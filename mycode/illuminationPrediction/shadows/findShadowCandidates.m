%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function findShadowCandidates(img, varargin)
%   Finds set of candidates for shadow identification. Long intensity edges
%   found on the ground region.
%  
% 
% Input parameters:
%  - img: input image
%  - varargin: optional arguments
%    - 'Mask': select lines from that region of the image only (typically ground)
%    - 'HorizonLine': y-coordinate of the horizon line
%    - 'FocalLength': focal length, in pixels
%    - 'DoLongLines': 0 or [1]: extract long lines, uses edgelets only otherwise
%    - 'DoDisplay': [0] or 1: display the results
%
% Output parameters:
%  - shadowCandidates: long lines detected on the ground
%  - groundMask: region where the lines were detected
%  - labImg: L*a*b* version of the input image (to avoid recomputing it several times)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [shadowCandidates, groundMask, labImg] = findShadowCandidates(img, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% parse arguments
defaultArgs = struct('GroundMask', ones(size(img,1), size(img,2)), 'DoDisplay', 0, 'PctDiagonal', 0.01);
args = parseargs(defaultArgs, varargin{:});

edgeThresh = 0.3;

% dilate the ground just a bit
groundMask = imdilate(args.GroundMask, strel('disk', 0.01*sqrt(size(img,1)^2+size(img,2)^2)));

%%
% use the fact that CIELAB is more discriminative for shadows, as per Khan's paper
labImg = rgb2lab(img);

% Find edges in discriminative channel (reflectance)
imgDisc = labImg(:,:,2);
imgDisc = (imgDisc + 50)/100;

% re-scale in [0,1] interval
edgeDisc = cannyEdgesFromImageRegion(imgDisc, groundMask>0, edgeThresh);
% edgeDisc = edge(imgDisc, 'canny', edgeThresh);

% Find edges in non-discriminative channel (both shadows + reflectance)
imgNonDisc = labImg(:,:,1);
imgNonDisc = imgNonDisc./100;
edgeNonDisc = cannyEdgesFromImageRegion(imgNonDisc, groundMask>0, edgeThresh);
% edgeNonDisc = edge(imgNonDisc, 'canny', edgeThresh);

edgePot = (edgeNonDisc-edgeDisc)>0;

[dX, dY] = gradient(conv2(imgNonDisc, fspecial('gaussian', 7, 1.5), 'same'));
    
% Find long lines 
shadowCandidates = APPgetLargeConnectedEdgesNew([], args.PctDiagonal*sqrt(size(img,1).^2+size(img,2).^2), dX, dY, edgePot);

% keep those on the ground only. 

% lineGndPct = 0.5; % at least that % should lie on the ground to be considered
% linesGroundWeight = meanLineIntensity(im2double(groundMask), allShadowCandidates, 0);

% linesShadowInd = linesGroundWeight >= lineGndPct;
% shadowCandidates = allShadowCandidates(linesShadowInd, :);

%% Display?
if args.DoDisplay
    gMask = im2double(repmat(groundMask>0, [1 1 3]));
    imgGnd = img.*gMask + img.*(1-gMask)*0.5;
    
    figure(101), hold off, imshow(imgGnd); hold on; plot(shadowCandidates(:, [1 2])', shadowCandidates(:, [3 4])', 'LineWidth', 3, 'Color', 'b');
    drawnow;
end


