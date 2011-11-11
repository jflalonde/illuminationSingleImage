function trainSunVisibilityClassifier
% Trains a sun visibility classifier based on features computed
% over the whole image.
% 
%   trainSunVisibilityClassifier
% 
% ----------
% Jean-Francois Lalonde

%% Setup

newBasePath = getPathName('results', 'visibilityClassifier');
outputBasePath = getPathName('results', 'globalModel', 'visibility');
featuresBasePath = fullfile(newBasePath, 'features');

featuresFilename = 'person';
doSave = 0;
crossValidate = 0;
doDisplay = 1;

initrand();

%% Load features and compute labels
featsInfo = load(fullfile(featuresBasePath, sprintf('%s-new.mat', featuresFilename)));

% append validation images to the training set
featsInfo.trainingLabels = cat(1, featsInfo.trainingLabels, featsInfo.valLabels);
featsInfo.trainingFeatures = cat(1, featsInfo.trainingFeatures, featsInfo.valFeatures);

%% Balance the training dataset
labels = unique(featsInfo.trainingLabels);
nbInstancesPerLabel = zeros(size(labels));
for l=1:length(labels)
    nbInstancesPerLabel(l) = nnz(featsInfo.trainingLabels == labels(l));
end

minNbInstances = min(nbInstancesPerLabel);

trainingFeatures = []; trainingLabels = [];
for l=1:length(labels)
    indCurLabel = find(featsInfo.trainingLabels == labels(l));
    randInd = randperm(length(indCurLabel));
    indCurLabel = indCurLabel(randInd(1:minNbInstances));
    
    trainingFeatures = cat(1, trainingFeatures, featsInfo.trainingFeatures(indCurLabel,:));
    trainingLabels = cat(1, trainingLabels, featsInfo.trainingLabels(indCurLabel,:));
end

trainingFeatures(isnan(trainingFeatures)) = 0;
featsInfo.testFeatures(isnan(featsInfo.testFeatures)) = 0;

%% Train SVM classifier
[trainingFeaturesScaled, minVal, scale] = scaleFeaturesSVM(trainingFeatures);

if crossValidate
    bestcv = 0;
    for log2c = -5:2:10
        cmd = ['-s 0 -t 0 -m 1000 -v 5 -c ', num2str(2^log2c)];
        cv = svmtrain(trainingLabels, trainingFeaturesScaled, cmd);
        if (cv >= bestcv),
            bestcv = cv; bestc = 2^log2c; 
        end
        fprintf('%g %g (best c=%g, rate=%g)\n', log2c, cv, bestc, 0);
    end
else 
    bestc = 10;
end

model = svmtrain(trainingLabels, trainingFeaturesScaled, sprintf('-s 0 -t 0 -g 0.1 -c %g -m 1000 -b 1', bestc));

% Test classifier (re-scale the same way as input)
testFeaturesScaled = scaleFeaturesSVM(featsInfo.testFeatures, minVal, scale);
testLabels = featsInfo.testLabels; 
[predictedLabels, acc, testProbabilities] = svmpredict(testLabels, testFeaturesScaled, model, '-b 1');

%% Confusion matrix
displayConfusionMatrix(predictedLabels, testLabels, doDisplay);

%% save
if doSave
    outputFile = fullfile(outputBasePath, 'pSunGivenFeatures.mat');
    save(outputFile, 'model', 'minVal', 'scale');
end