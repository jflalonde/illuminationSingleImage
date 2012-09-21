function prob = applyLocalVisibilityClassifier(featsInfo, classifInfo, nbLightingBins, ...
    uo, vo, horizonLine, imageWidth, focalLength)

% select features
feats = [];
for f=1:length(classifInfo.featuresToUse)
    feats = cat(2, feats, featsInfo.(classifInfo.featuresToUse{f})');
end

if isobject(classifInfo)
    % it's the OVA classifier
    % run all classifiers
    scores = zeros(size(feats,1), 2, classifInfo.nbIlluminationClusters);
    predictedLabels = zeros(size(feats,1), classifInfo.nbIlluminationClusters);
    for c=1:classifInfo.nbIlluminationClusters
        featsScaled = scaleFeaturesSVM(feats, classifInfo.minVal(c,:), classifInfo.scale(c,:)');
        [predictedLabels(:,c), a, scores(:,:,c)] = svmpredict(ones(size(featsScaled,1),1), featsScaled, classifInfo.models(c), '-b 1');
    end
    
    % combine outputs
    combinedLabels = zeros(size(predictedLabels,1),1);
    scores = squeeze(scores(:,2,:));
    if size(predictedLabels,1)==1
        scores = scores';
    end
    prob = scores./repmat(sum(scores,2), [1 classifInfo.nbIlluminationClusters]);
    
    for i=1:size(predictedLabels,1)
        nbTrue = nnz(predictedLabels(i,:)==2);
        
        switch nbTrue
            case 0
                % no detector fired on that instance. Keep index of highest scoring
                [m, combinedLabels(i)] = max(scores(i,:));
%                 prob(i,:) = 1./classifInfo.nbIlluminationClusters; % -> equal probability
                
            case 1
                % single detector fired. Keep that one.
                combinedLabels(i) = find(predictedLabels(i,:)==2);
                
            otherwise
                % more than one detector fired. Keep index of highest scoring among them.
                ind = find(predictedLabels(i,:)==2);
                [m,mind] = max(scores(i,ind));
                combinedLabels(i) = ind(mind);
        end
    end
else
    % it's the svmlib thingie
    
    
    % scale local features
    featsScaled = scaleFeaturesSVM(feats, classifInfo.minVal, classifInfo.scale);
    
    % apply classifier on features to get P(l_i | e_l)
    [p, a, prob] = svmpredict(ones(size(featsScaled, 1), 1), featsScaled, classifInfo.model, '-b 1');
end

% do we need to warp angles to the image space using image parameters?
if isfield(classifInfo, 'warpAngles') && classifInfo.warpAngles
    % THIS FAILS. WHY?
    
    % get probabilities in original fine space (before grouping)
    newProb = zeros(size(classifInfo.binEdges));
    for g=1:length(classifInfo.groupsInd)
        newProb(classifInfo.groupsInd{g}) = prob(g)./length(classifInfo.groupsInd{g});
    end
    
    [h,b,newBinCenters] = angularHistogram([], length(classifInfo.binEdges));
    
    % finely sample probabilities
    fineBinCenters = linspace(-pi,pi,360+1); fineBinCenters(end) = [];
    fineProb = interp1([newBinCenters pi], [newProb newProb(1)], fineBinCenters, 'linear');
    
    % warp back to sun direction angles
    unwarpedBinCenters = image2SunAngle(uo, vo, horizonLine, imageWidth/2, focalLength, fineBinCenters);
    
    % equally sample unwarped angles
    [s,sind] = sort(unwarpedBinCenters); % to avoid jump
    unwarpedFineProb(sind) = interp1(unwarpedBinCenters(sind), fineProb(sind), fineBinCenters);
        
    % remove NaNs
    indNan = isnan(unwarpedFineProb);
    unwarpedFineProb = unwarpedFineProb(~indNan);
    fineBinCenters = fineBinCenters(~indNan);
    
    % re-integrate into histogram in sun space
    [h,b,c,unwarpedEdges]= angularHistogram([], nbLightingBins);
    
    unwarpedProb = zeros(1, nbLightingBins);
    unwarpedProb(1) = sum(unwarpedFineProb(fineBinCenters<unwarpedEdges(1) | fineBinCenters>=unwarpedEdges(end)));
    for e=2:length(unwarpedEdges)
        unwarpedProb(e) = sum(unwarpedFineProb(fineBinCenters>=unwarpedEdges(e-1) & fineBinCenters<unwarpedEdges(e)));
    end

% 
%     unwarpedProb = zeros(1, nbLightingBins);
%     unwarpedProb(1) = sum(fineProb(unwarpedBinCenters<unwarpedEdges(1) | unwarpedBinCenters>=unwarpedEdges(end)));
%     for e=2:length(unwarpedEdges)
%         unwarpedProb(e) = sum(fineProb(unwarpedBinCenters>=unwarpedEdges(e-1) & unwarpedBinCenters<unwarpedEdges(e)));
%     end
    
    % re-normalize
    unwarpedProb = unwarpedProb./sum(unwarpedProb);
    prob = unwarpedProb;
end

%     % apply classifier
%     if args.DoCascade
%         % apply cascaded classifiers on features to get P(l_i | e_l)
%         [p, pLocal] = testLocalVisibilityClassifierCascade(allLocalFeatures, ...
%             args.LocalClassifier.modelOccludedVisible, args.LocalClassifier.minValOccludedVisible, args.LocalClassifier.scaleOccludedVisible, ...
%             args.LocalClassifier.modelOvercastShadow, args.LocalClassifier.minValOvercastShadow, args.LocalClassifier.scaleOvercastShadow);
%     end
