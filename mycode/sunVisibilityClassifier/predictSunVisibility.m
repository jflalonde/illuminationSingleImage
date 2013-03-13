function [vis, prob] = predictSunVisibility(img, visibilityClassifier, ...
    geomContextInfo, boundaries, boundaryLabels)
% Predicts the sun visibility in an image.
%
% See also:
%   computeSunVisibilityFeatures
%
% ----------
% Jean-Francois Lalonde

visibilityFeaturesOpts = {'GeometricContextArea', 1, 'MeanSkyColor', 1, 'MeanGroundIntensity', 1, ...
    'MaxGroundCluster', 1, 'MaxWallsCluster', 1, 'SceneContrast', 1, 'SVHistogram', ...
    1, 'LogHistogram', 1, 'GroundShadows', 1};

% parse the options
visibilityFeaturesOpts = parseVisibilityFeaturesOpts(visibilityFeaturesOpts, ...
    geomContextInfo, boundaries, boundaryLabels);

% compute visibility features
visibilityFeatures = computeSunVisibilityFeatures(img, visibilityFeaturesOpts{:});    

catFeatures = [];
featuresToLoad = sort(fieldnames(visibilityFeatures));
for f=1:length(featuresToLoad)
    % original version
    tmpFeatures = visibilityFeatures.(featuresToLoad{f});
    catFeatures = cat(2, catFeatures, tmpFeatures(:)');
end

% Re-scale features the same way as training data
visibilityFeaturesScaled = scaleFeaturesSVM(catFeatures, ...
    visibilityClassifier.minVal, visibilityClassifier.scale); 

% Run classifier
[vis, d, prob] = svmpredict(0, visibilityFeaturesScaled, visibilityClassifier.model, '-b 1');


function visibilityFeaturesOpts = parseVisibilityFeaturesOpts(visibilityFeaturesOpts, ...
    geomContextInfo, boundaries, boundaryLabels)
% Helper function

% extract masks from geometric context information
[m,mind] = max(cat(3, geomContextInfo.allGroundMask, geomContextInfo.allWallsMask, geomContextInfo.allSkyMask), [], 3);
groundMask = mind == 1;
wallsMask = mind == 2;
skyMask = mind == 3;

groundProb = geomContextInfo.allGroundMask;

defaultSubArgs = struct('GeometricContextArea', 0, 'MeanSkyColor', 0, 'MeanGroundIntensity', 0, ...
                        'MaxGroundCluster', 0, 'MaxWallsCluster', 0, 'SceneContrast', 0, 'GroundShadows', ...
                        0, 'SkyCategory', 0, 'LogHistogram', 0, 'SVHistogram', 0);
subArgs = parseargs(defaultSubArgs, visibilityFeaturesOpts{:});

if subArgs.GeometricContextArea
    % load geometric context information
    visibilityFeaturesOpts = cat(2, visibilityFeaturesOpts, ...
        {'GroundMask', groundMask, 'WallsMask', wallsMask, 'SkyMask', skyMask});
end

if subArgs.MeanSkyColor
    % load the sky mask
    visibilityFeaturesOpts = cat(2, visibilityFeaturesOpts, ...
        {'SkyMask', skyMask});
end

if subArgs.MeanGroundIntensity
   visibilityFeaturesOpts = cat(2, visibilityFeaturesOpts, ...
       {'GroundMask', groundMask});
end

if subArgs.MaxGroundCluster
    visibilityFeaturesOpts = cat(2, visibilityFeaturesOpts, ...
        {'GroundProb', groundProb});
end

if subArgs.MaxWallsCluster
    visibilityFeaturesOpts = cat(2, visibilityFeaturesOpts, ...
        {'WallRight', geomContextInfo.wallRight}, ...
        {'WallLeft', geomContextInfo.wallLeft}, ...
        {'WallFacing', geomContextInfo.wallFacing});
end

if subArgs.SceneContrast
    % load the sky mask
    visibilityFeaturesOpts = cat(2, visibilityFeaturesOpts, ...
        {'GroundMask', groundMask, 'WallsMask', wallsMask});
end

if subArgs.GroundShadows        
    % load the ground shadows & boundary information    
    visibilityFeaturesOpts = cat(2, visibilityFeaturesOpts, ...
        {'ShadowBoundaries', boundaries(boundaryLabels==0), ...
        'GroundProb', groundProb});
end

if subArgs.LogHistogram
    visibilityFeaturesOpts = cat(2, visibilityFeaturesOpts, ...
        {'GroundProb', geomContextInfo.allGroundMask});
end

if subArgs.SVHistogram
    visibilityFeaturesOpts = cat(2, visibilityFeaturesOpts, ...
        {'GroundProb', geomContextInfo.allGroundMask});
end
