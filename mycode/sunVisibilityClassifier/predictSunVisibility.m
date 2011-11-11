function [vis, prob] = predictSunVisibility(img, visibilityClassifier)
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

visibilityFeatures = computeSunVisibilityFeatures(img, visibilityFeaturesOpts{:});     

% Test classifier (re-scale the same way as input)
visibilityFeaturesScaled = scaleFeaturesSVM(visibilityFeatures, ...
    visibilityClassifier.minVal, visibilityClassifier.scale); 

[vis, d, prob] = svmpredict([], visibilityFeaturesScaled, ...
    visibilityClassifier.model, '-b 1');