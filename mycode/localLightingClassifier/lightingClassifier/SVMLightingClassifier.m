classdef SVMLightingClassifier < LightingClassifier
    % Uses a SVM to classify the local lighting
    %
    
    %% Constant properties
    properties (Constant)
        % results paths
        classifBasePath = '/nfs/hn01/jlalonde/results/illuminationUnderstanding/localLightingClassifier/classifiers/svm';
    end
    
    %% Private properties
    properties (SetAccess=private, GetAccess=public)
        % number of illumination clusters
        nbIlluminationClusters = 0;
        
        % SVM parameter: penalty
        C = [];
        
        % SVM parameter: kernel
        G = [];
        
        % Actual SVM model
        models = svmtrain(1, 1);
        
        %
        minVal = [];
        scale = []; 
        
        % names of features to use
        featuresToUse = [];
        
        % whether to align histograms or not
        alignHistogram = 0;
    end
    
    methods
        %% Constructor
        function obj = SVMLightingClassifier(modelName, verbose, varargin)
            % parse arguments
            defaultArgs = struct('NbIlluminationClusters', 2, 'FeaturesToUse', [], 'AlignHistogram', 0);
            args = parseargs(defaultArgs, varargin{:});
            
            obj = obj@LightingClassifier(modelName, verbose);
            myfprintf(obj.verbose, 'Created SVM lighting classifier %s\n', obj.modelName);
            
            obj.nbIlluminationClusters = args.NbIlluminationClusters;
            obj.featuresToUse = args.FeaturesToUse;
            obj.alignHistogram = args.AlignHistogram;
            
            % default parameters
            obj.C = 0.01.*ones(1, obj.nbIlluminationClusters);
            obj.G = 0.01.*ones(1, obj.nbIlluminationClusters);
        end
        
        %% Initializes the lighting classifier
        function obj = initialize(obj)
            % call the super-cass method
            obj = initialize@LightingClassifier(obj);
            
            objInfo = load(fullfile(obj.classifBasePath, sprintf('%s.mat', obj.modelName)));
            obj = objInfo.obj;
        end
        
        %% Saves the object lighting classifier
        function save(obj)
            outputFile = fullfile(obj.classifBasePath, sprintf('%s.mat', obj.modelName));
            [m,m,m] = mkdir(fileparts(outputFile));
            save(outputFile, 'obj');
        end
        
        %% Trains the classifier
        function obj = train(obj, sunClusters, features, varargin)
            % parse arguments
            defaultArgs = struct('BalanceData', 1, 'CrossValidate', 0, 'UseRBF', 0);
            args = parseargs(defaultArgs, varargin{:});
            
            %
            obj.minVal = zeros(obj.nbIlluminationClusters, size(features, 2));
            obj.scale = zeros(obj.nbIlluminationClusters, size(features, 2));

            for c=1:obj.nbIlluminationClusters
                myfprintf(obj.verbose, 'Training cluster %d...\n', c); tic;
                
                curLabels = cat(1, 2*(sunClusters==c)+1*(sunClusters~=c));
                
                if args.BalanceData
                    % balance training sets
                    negInd = find(curLabels==1);
                    posInd = find(curLabels==2);
                    nbToKeep = min(length(negInd), length(posInd));
                    
                    randInd = randperm(length(negInd));
                    negInd = negInd(randInd(1:nbToKeep));
                    randInd = randperm(length(posInd));
                    posInd = posInd(randInd(1:nbToKeep));
                    
                    curLabels = curLabels(cat(1, negInd, posInd));
                    curFeatures = features(cat(1, negInd, posInd), :);
                else
                    curFeatures = features;
                end
                
                [curFeaturesScaled, obj.minVal(c,:), scaleMat] = scaleFeaturesSVM(curFeatures);
                obj.scale(c,:) = diag(scaleMat);
                
                % weight relative classes
                w = [1 nnz(curLabels==1)/nnz(curLabels==2)];
                
                if args.CrossValidate
                    Cparam = 1./(2.^(0:15));
                    if args.UseRBF
                        Cparam = 100./(2.^(0:15));
                        Gparam = 1./(2.^(0:15));
                    else
                        Gparam = 0;
                    end
                    acc = zeros(length(Gparam), length(Cparam));
                    
                    for i=1:length(Cparam)
                        for j=1:length(Gparam)
                            cmd = sprintf('-s 0 -t %d -g %g -m 1000 -w1 %g -w2 %g -v 5 -c %g', args.UseRBF*2, ...
                                Gparam(j), w(1), w(2), Cparam(i));
                            acc(j,i) = svmtrain(curLabels, curFeaturesScaled, cmd);
                        end
                    end
                    [m,mind] = max(acc(:));
                    [row,col] = ind2sub(size(acc), mind);
                    obj.C(c) = Cparam(col);
                    obj.G(c) = Gparam(row);
                    myfprintf(obj.verbose, 'After cross-validation, best C found to be %g, and best G found to be %g.\n', obj.C(c), obj.G(c));
                end
                
                cmd = sprintf('-s 0 -t %d -g %g -c %g -m 1000 -w1 %g -w2 %g -b 1', args.UseRBF*2, obj.G(c), obj.C(c), w(1), w(2));
                obj.models(c) = svmtrain(curLabels, curFeaturesScaled, cmd);
                
                fprintf('done in %.2fs\n', toc);
            end
        end
        
        %% Apply classifier
        function [labels, probabilities] = test(obj, testFeatures)
            % run all classifiers
            probabilities = zeros(size(testFeatures,1), 2, obj.nbIlluminationClusters);
            predictedLabels = zeros(size(testFeatures,1), obj.nbIlluminationClusters);
            for c=1:obj.nbIlluminationClusters
                testFeaturesScaled = scaleFeaturesSVM(testFeatures, obj.minVal(c,:), obj.scale(c,:)');
                [predictedLabels(:,c), a, probabilities(:,:,c)] = svmpredict(ones(size(testFeaturesScaled,1),1), testFeaturesScaled, obj.models(c), '-b 1');
            end
            
            if obj.nbIlluminationClusters==1
                % we're in the binary classification case
                labels = 3-predictedLabels;
                return;
            end
            
            % combine outputs
            labels = zeros(size(predictedLabels,1),1);
            probabilities = squeeze(probabilities(:,2,:));
            for i=1:size(predictedLabels,1)
                nbTrue = nnz(predictedLabels(i,:)==2);
                
                switch nbTrue
                    case 0
                        % no detector fired on that instance. Keep index of highest scoring
                        [m, labels(i)] = max(probabilities(i,:));
                        
                    case 1
                        % single detector fired. Keep that one.
                        labels(i) = find(predictedLabels(i,:)==2);
                        
                    otherwise
                        % more than one detector fired. Keep index of highest scoring among them.
                        ind = find(predictedLabels(i,:)==2);
                        [m,mind] = max(probabilities(i,ind));
                        labels(i) = ind(mind);
                end
            end
        end
    end
end