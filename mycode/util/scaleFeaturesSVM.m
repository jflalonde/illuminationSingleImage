function [scaledFeats, minVal, scale] = scaleFeaturesSVM(feats, minVal, scale)

if nargin < 3
    minVal = min(feats,[],1);
    maxVal = max(feats,[],1);
    diff = maxVal-minVal;
    
    scale = spdiags(1./diff',0,size(feats,2),size(feats,2));
    scale(isinf(scale)) = 0;
end

if ~issparse(scale)
    scale = spdiags(scale, 0, size(feats,2), size(feats,2));
end

scaledFeats = (feats - repmat(minVal,size(feats,1),1))*scale;