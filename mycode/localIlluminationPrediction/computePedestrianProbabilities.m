function [pObj, pLocalVisibility, pLocalLightingGivenObject, ...
    pLocalLightingGivenNonObject] = computePedestrianProbabilities(img, boxes, ...
    localVisibilityClassifier, lightingGivenObjectClassifier, lightingGivenNonObjectClassifier)
% Computes probabilities needed by the pedestrian illumination predictor.
%
% ----------
% Jean-Francois Lalonde

nbObjects = size(boxes, 1);

% We need:
% - pObj: probability of object (from the normalized object detector)
% - pLocalVisibility: probability that object has sun directly shining on it
% - pLocalLightingGivenObject: probability of sun position given that the 
%   detection is an actual pedestrian
% - pLocalLightingGivenNonObject: probability of sun position given that
%   the detection is _not_ a pedestrian.
pObj = [1-boxes(:,end), boxes(:, end)];
pLocalVisibility = zeros(nbObjects, 2);
pLocalLightingGivenObject = zeros(nbObjects, 4);
pLocalLightingGivenNonObject = zeros(nbObjects, 4);
for i_obj = 1:nbObjects
    % compute visibility features (shadow vs sunlit) 
    visibilityFeatures = computeLocalVisibilityFeatures(img, boxes(i_obj,:), ...
        'GIST', 1, 'SmallImg', 1, 'HSVHistogram', 1);
    
    % run local visibility classifier
    pLocalVisibility(i_obj,:) = applyLocalClassifier(visibilityFeatures, ...
        localVisibilityClassifier);
    
    % compute local lighting features (sun direction)
    lightingFeatures = computeLocalLightingFeatures(img, boxes(i_obj,:), ...
        'HOG', 1);
        
    % run local lighting classifier
    pLocalLightingGivenObject(i_obj,:) = applyLocalClassifier(lightingFeatures, ...
        lightingGivenObjectClassifier);

    % run local lighting classifier
    pLocalLightingGivenNonObject(i_obj,:) = applyLocalClassifier(lightingFeatures, ...
        lightingGivenNonObjectClassifier);
end