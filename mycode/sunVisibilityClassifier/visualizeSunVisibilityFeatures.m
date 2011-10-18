%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function visualizeSunVisibilityFeatures
%  Visualizes the various pre-computed sun visibility features to see if
%  there's hope.
% 
% Input parameters:
%
% Output parameters:
%   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function visualizeSunVisibilityFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup
setPath;
dbPath = fullfile(basePath, 'labelmeDb', 'all');
imagesPath = fullfile(basePath, 'labelmeImages');

%% Load database
labelmeDb = loadDatabaseFast(dbPath, '', '', 1);

%% Pre-load features and labels
geometricContextArea = zeros(length(labelmeDb), 3);
meanSkyColor = zeros(length(labelmeDb), 3);
meanGroundIntensity = zeros(length(labelmeDb), 1);
maxGroundCluster = zeros(length(labelmeDb), 2);
sceneContrast = zeros(length(labelmeDb), 4);
groundShadows = zeros(length(labelmeDb), 4);
skyCategory = zeros(length(labelmeDb), 1);
logHistogram = zeros(length(labelmeDb), 5);
svHistogram = zeros(length(labelmeDb), 6);

% 1=visible, -1=invisible, 0=unlabelled
labels = zeros(length(labelmeDb), 1);
labelsC = [-1 1];

for i=1:length(labelmeDb)
    imgInfo = labelmeDb(i).document;
    if ~isfield(imgInfo, 'visibilityFeatures')
        continue;
    end
    featsInfo = load(fullfile(dbPath, imgInfo.visibilityFeatures.filename), 'visibilityFeatures');
    
   try
        geometricContextArea(i,:) = featsInfo.visibilityFeatures.GeometricContextArea;
        meanSkyColor(i,:) = featsInfo.visibilityFeatures.MeanSkyColor;
        meanGroundIntensity(i,:) = featsInfo.visibilityFeatures.MeanGroundIntensity;
        maxGroundCluster(i,:) = featsInfo.visibilityFeatures.MaxGroundCluster;
        sceneContrast(i,:) = featsInfo.visibilityFeatures.SceneContrast;
        groundShadows(i,:) = featsInfo.visibilityFeatures.GroundShadows;
        skyCategory(i,:) = featsInfo.visibilityFeatures.SkyCategory;
        logHistogram(i,:) = featsInfo.visibilityFeatures.LogHistogram;
        svHistogram(i,:) = featsInfo.visibilityFeatures.SVHistogram;

        if isfield(imgInfo, 'manualLabeling') && str2double(imgInfo.manualLabeling.isGood)
            labels(i) = labelsC(str2double(imgInfo.manualLabeling.visible)+1);
        end
   catch
       fprintf('Error for image %d\n', i);
   end
end
indGood = find(labels~=0);
fprintf('Found %d labelled images\n', nnz(labels));

% fix: if sky color is not available, set to 0
meanSkyColor(isnan(meanSkyColor)) = 0;

%% Visualize feature overlap
% visFeatures = groundShadows(indGood,4);
visFeatures = sceneContrast(indGood, 2);
visFeatureName = 'Ground Shadows';
visLabels = labels(indGood);

figure;
nbBins = 15; histBins = linspace(min(visFeatures),max(visFeatures),nbBins);
posHist = histc(visFeatures(visLabels == 1), histBins); posHist = posHist./sum(posHist(:));
negHist = histc(visFeatures(visLabels == -1), histBins); negHist = negHist./sum(negHist(:));

bar(histBins, cat(2, negHist, posHist)); legend('Occluded', 'Visible'); 
% set(gca, 'XLim', [0 1]); 
set(gcf, 'Position', [305 677 746 246]);
title(visFeatureName);

%% Cross-validate
nbFolds = 5;
allLabels = labels(indGood);
allFeatures = cat(2, sceneContrast(indGood, [1 2]), meanSkyColor(indGood,:), maxGroundCluster(indGood, :), groundShadows(indGood,:), geometricContextArea(indGood, [1 2]));
allFeatures = cat(2, allFeatures, logHistogram(indGood, :), svHistogram(indGood,:));
% allFeatures = cat(2, sceneContrast(indGood, [1 2]), maxGroundCluster(indGood, :), groundShadows(indGood,:), geometricContextArea(indGood, 2));
% allFeatures = groundShadows(indGood,3);

indFolds = round(linspace(1, length(allLabels)+1, nbFolds+1));
randInd = randperm(length(allLabels));

acc = zeros(1, nbFolds);
accPos = zeros(1, nbFolds);
accNeg = zeros(1, nbFolds);
occProb = zeros(size(allLabels,1), 1);

for n=1:nbFolds
    indTest = randInd(indFolds(n):(indFolds(n+1)-1));
    indTrain = setdiff(randInd, indTest);
        
    % train (write labels with [1 2] instead of [-1 1])
    b = mnrfit(allFeatures(indTrain, :), ceil((allLabels(indTrain)+2)/2));
    
    % test
    p = mnrval(b, allFeatures(indTest,:)); 
    
    % try boosted decision trees
%     cl = train_boosted_dt_2c(allFeatures(indTrain,:), [], allLabels(indTrain), 10, 15);
%     c = test_boosted_dt_mc(cl, allFeatures(indTest,:));
%     p = repmat(1./(1+exp(-(1).*c)), [1 2]);
    
    indTmp = ~isnan(p(:,1));
    pt = p(indTmp,:); yt = allLabels(indTest(indTmp)); 
    
    % compute accuracy for each class independently
    accPos(n) = sum(pt(:,2)>=0.5 & yt==1)./sum(yt==1);
    accNeg(n) = sum(pt(:,2)<0.5 & yt==-1)./sum(yt==-1);
    
    acc(n) = mean([accPos(n) accNeg(n)]);
    occProb(indTest) = p(:,2);
    
    fprintf('Accuracy (for %.2f%% of images) = %.2f%%\n', nnz(indTmp)./nnz(indTest)*100, acc(n)*100);
end
fprintf('Mean accuracy: %.2f%% (vis = %.2f%%, occ = %.2f%%)\n', mean(acc)*100, mean(accPos)*100, mean(accNeg)*100);

%% Visualize hard examples
return;
classId = 1;
nbImagesToDisplay = 16;

if classId == -1
    [s,sind] = sort(occProb, 'descend');
else
    [s,sind] = sort(occProb);
end
imgInd = find(allLabels(sind) == classId);

imgSize = [240 320];

imgMontage = zeros(imgSize(1), imgSize(2), 3, nbImagesToDisplay);
for i=1:nbImagesToDisplay
    curInd = indGood(sind(imgInd(i)));
    imgMontage(:,:,:,i) = im2double(imresize(imread(fullfile(imagesPath, labelmeDb(curInd).document.image.folder, labelmeDb(curInd).document.image.filename)), imgSize, 'nearest'));
end

montage(imgMontage);

% get confident wrong answers
% allLabels == classId;

%% Visualize random montages from each class
return;
indPos = find(labels==1); indRand = randperm(length(indPos));
indPos = indPos(indRand(1:25));
imgSize = [120 160];

imgPos = []; 
for i=indPos(:)'
    imgPos = cat(4, imgPos, imresize(imread(fullfile(imagesPath, labelmeDb(i).document.image.folder, labelmeDb(i).document.image.filename)), imgSize, 'nearest'));
end

figure; montage(imgPos);

indNeg = find(labels==-1); indRand = randperm(length(indNeg));
indNeg = indNeg(indRand(1:25));

imgNeg = []; 
for i=indNeg(:)'
    imgNeg = cat(4, imgNeg, imresize(imread(fullfile(imagesPath, labelmeDb(i).document.image.folder, labelmeDb(i).document.image.filename)), imgSize, 'nearest'));
end

figure; montage(imgNeg);
