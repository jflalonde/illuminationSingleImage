function geomContextInfo = computeGeometricContext(img, classifiers)
% Computes the necessary information from geometric context.
%
%   geomContextInfo = computeGeometricContext(img, classifiers)
%
% 'classifiers' is obtained by loading Derek's 'ijcvClassifier.mat' file:
%
%   classifiers = load('ijcvClassifiers.mat');
%
% Note:
%   Assumes that the geometric context code from Derek Hoiem has been
%   installed properly and is in the path.
%
% ----------
% Jean-Francois Lalonde


% run the geometric context classifier
[pg, ~, imsegs] = ijcvTestImage(img, [], classifiers);

% convert to image maps
[cimages, cnames] = pg2confidenceImages(imsegs, {pg});
cimages = cimages{1}; 

% get the necessary geometric context information
gndDimInd = find(strcmp(cnames, '000'));
skyDimInd = find(strcmp(cnames, 'sky'));
verDimInd = find(strcmp(cnames, '090'));

cimg = cimages(:,:,[gndDimInd, skyDimInd, verDimInd]);
[~,maxInd] = max(cimg, [], 3);
geomContextInfo.allGroundMask = cimages(:,:,gndDimInd);
geomContextInfo.allSkyMask = cimages(:,:,skyDimInd);
geomContextInfo.allWallsMask = cimages(:,:,verDimInd);

% extract walls probabilities
leftDimInd = find(strcmp(cnames, '090-045'));
rightDimInd = find(strcmp(cnames, '090-135'));
frontDimInd = find(strcmp(cnames, '090-090'));
solDimInd = find(strcmp(cnames, '090-sol'));
porDimInd = find(strcmp(cnames, '090-por'));

[~,mind] = max(cimages(:,:,[leftDimInd, rightDimInd, frontDimInd, ...
    solDimInd, porDimInd]), [], 3);

% this is flipped
geomContextInfo.wallLeft = cimages(:,:,rightDimInd) .* ...
    double(mind == 1);
geomContextInfo.wallRight = cimages(:,:,leftDimInd) .* ...
    double(mind == 2);
geomContextInfo.wallFacing = cimages(:,:,frontDimInd) .* ...
    double(mind == 3);
