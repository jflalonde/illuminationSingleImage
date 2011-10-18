%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function preloadLocalLightingFeatures
%  Pre-loads local lighting features
% 
% Input parameters:
%
% Output parameters:
%   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function preloadVisibilityFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup
setPath;

dbBasePath = fullfile(basePath, 'labelmeDb');
dbPath = fullfile(dbBasePath, 'all');
outputBasePath = fullfile(basePath, 'visibilityClassifier', 'features');

%% User parameters
doSave = 1;
objectType = 'person';

dbInfo = load(fullfile(dbBasePath, sprintf('%sFiles.mat', objectType)));

trainDbPath = fullfile(dbBasePath, sprintf('%sTrainDb.mat', objectType));
testDbPath = fullfile(dbBasePath, sprintf('%sTestDb.mat', objectType));
valDbPath = fullfile(dbBasePath, sprintf('%sValDb.mat', objectType));


%% Load data

% train
labelmeDbTrain = reloadDatabaseFiles(dbPath, strrep(dbInfo.trainFiles, '.jpg', '.xml'), ...
                                     dbInfo.trainDirectories, trainDbPath, 'Loading training data...');
fprintf('Loading training features and labels...\n');
[trainingFeatures, trainingLabels, trainingFeaturesInd] = loadVisibilityFeatures(labelmeDbTrain, ...
                                                  dbPath);

% test
labelmeDbTest = reloadDatabaseFiles(dbPath, strrep(dbInfo.testFiles, '.jpg', '.xml'), dbInfo.testDirectories, ...
                                    testDbPath, 'Loading test data...');
fprintf('Loading test features and labels...\n');
[testFeatures, testLabels, testFeaturesInd] = loadVisibilityFeatures(labelmeDbTest, dbPath);

% validation
labelmeDbVal = reloadDatabaseFiles(dbPath, strrep(dbInfo.valFiles, '.jpg', '.xml'), dbInfo.valDirectories, ...
                                    valDbPath, 'Loading validation data...');
fprintf('Loading validation features and labels...\n');
[valFeatures, valLabels, valFeaturesInd] = loadVisibilityFeatures(labelmeDbVal, dbPath);


%% Save
if doSave
    outputFile = fullfile(outputBasePath, sprintf('%s-new.mat', objectType));
    [m,m,m] = mkdir(fileparts(outputFile));
    save(outputFile, 'trainingFeatures', 'trainingLabels', 'trainingFeaturesInd', 'testFeatures', ...
         'testLabels', 'testFeaturesInd', 'valFeatures', 'valLabels', 'valFeaturesInd');
end

%% load visibility features and labels
function [features, labels, featuresInd] = loadVisibilityFeatures(imgDb, dbPath)

features = [];
labels = [];

featuresInd = containers.Map();
for i=1:length(imgDb)
    imgInfo = imgDb(i).document;

    if ~str2double(imgInfo.manualLabeling.isGood)
        continue;
    end
    
    % load features from objects
    imgFeatsInfo = load(fullfile(dbPath, imgInfo.visibilityFeatures.filename));
    featuresToLoad = sort(fieldnames(imgFeatsInfo.visibilityFeatures));

    curFeatures = [];
    for f=1:length(featuresToLoad)
        % original version
        tmpFeatures = imgFeatsInfo.visibilityFeatures.(featuresToLoad{f});

        if i==1
            % compute only once: store the indices of the current feature
            featuresInd(featuresToLoad{f}) = (length(curFeatures)+1):(length(curFeatures) + ...
                                                              length(tmpFeatures));
        end

        curFeatures = cat(2, curFeatures, tmpFeatures(:)');
    end
    
    features = cat(1, features, curFeatures);
    
    sunVisible = str2double(imgInfo.manualLabeling.visibleNew);
    labels = cat(1, labels, sunVisible);
end
