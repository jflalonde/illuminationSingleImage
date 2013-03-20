function [boundaries, boundaryProbabilities, boundaryLabels, indStrongBnd] = ...
    detectShadows(img, varargin)
% Runs the boundary shadow detection algorithm from [Lalonde et al. 2010]
%
%
% Note:
%   Assumes the shadow detection code is installed and available in the
%   path.
% 
% ----------
% Jean-Francois Lalonde

% write text on the command line
verbose = 1;

% probability of ground
groundProb = []; 

% display stuff
debug = false;

shadowDataPath = getPathName('codeShadowDetection', 'mycode', 'data');

parseVarargin(varargin{:});

% load the classifier
classifierInfo = load(fullfile(shadowDataPath, 'bdt-eccv10.mat'));

% load texton dictionary and filter bank
univTextons = load(fullfile(shadowDataPath, 'univTextons_128.mat'));
textonFilterBank = load(fullfile(shadowDataPath, 'filterBank.mat'));

% parameters for the CRF
lambda = 0.5;
beta = 16;

% Find boundaries
myfprintf(verbose, 'Finding image boundaries...\n');
[boundaries, ~, neighbors, fseg] = extractImageBoundaries(img);

% Let's display them
if debug
    figure(1); imshow(img);
    displayBoundaries(figure(1), boundaries, 'b', 3);
    title(sprintf('Oversegmentation, %d boundaries found', length(boundaries)));
end

% Compute boundary features
myfprintf(verbose, 'Computing boundary features (this will take a while...)\n');
bndFeatures = computeAllShadowBoundaryFilterFeatures(img, boundaries, ...
    'Verbose', verbose, ...
    'RGBFilters', 1, 'LABFilters', 1, 'ILLFilters', 1, 'NbScales', 4, ...
    'Textons', 1, 'UnivTextons', univTextons.clusterCenters, 'TextonFilterBank', textonFilterBank.filterBank);

% Compute image features (unused)
myfprintf(verbose, 'Computing image features...\n');
imageFeatures = computeImageFeatures(img, 'Verbose', verbose, 'RGBContrast', 1);

% Run the boundary classifier
myfprintf(verbose, 'Applying boundary classifier...\n');
[boundaryProbabilities, indStrongBnd] = applyLocalBoundaryClassifier(img, [], ...
    classifierInfo, bndFeatures, imageFeatures, ...
    boundaries, neighbors.junction_fragmentlist, neighbors.fragment_junctionlist);

% Let's display them
if debug
    figure(2); imshow(img);
    displayBoundariesProb(figure(2), boundaries(indStrongBnd), boundaryProbabilities, 3);
    title('Boundary probability (for strong boundaries only)');
end

% Run the CRF

% compute segment features
spFeatures = computeShadowSegmentFeatures(img, fseg, 'RGBHist', 1);
spFeats = spFeatures.RGBHist.mean;

withStr = {'without', 'with'};
useGroundProb = double(~isempty(groundProb));
myfprintf(verbose, 'Applying CRF %s geometric context...\n', withStr{useGroundProb+1});
boundaryLabels = applyBoundaryGrouping(lambda, beta, boundaries, neighbors.junction_fragmentlist, ...
    'UseShadowProbability', 1, 'ShadowProb', boundaryProbabilities, 'ShadowProbInd', indStrongBnd, ...
    'UseGroundProbability', useGroundProb, 'GroundMask', groundProb, ...
    'UseSegFeatures', 1, 'SegFeatures', spFeats, 'BndToSegId', neighbors.fragment_segments);

% Let's display the CRF labels
if debug
    figure(3); imshow(img);
    displayBoundaries(figure(3), boundaries(boundaryLabels==0), 'r', 3);
    groundStr = {'Shadows', 'Ground shadows'};
    title(sprintf('%s detected', groundStr{useGroundProb+1}));
end
