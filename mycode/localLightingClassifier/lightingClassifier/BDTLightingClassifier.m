classdef BDTLightingClassifier < LightingClassifier
    % Uses a BDT to classify the local lighting
    %
    
    %% Constant properties
    properties (Constant)
        % results paths
        classifBasePath = '/nfs/hn01/jlalonde/results/illuminationUnderstanding/localLightingClassifier/classifiers/bdt';
    end
    
    %% Private properties
    properties (SetAccess=private, GetAccess=public)
        % number of illumination clusters
        nbIlluminationClusters = 0;
        
        % BDT parameter: number of nodes per tree
        nbNodes = 0;
        
        % BDT parameter: number of trees
        nbTrees = 0;
        
        % Actual SVM model
        model = [];
        
        % names of features to use
        featuresToUse = [];
        
        % whether to align histograms or not
        alignHistogram = 0;

    end
    
    methods
        %% Constructor
        function obj = BDTLightingClassifier(modelName, verbose, varargin)
            % parse arguments
            defaultArgs = struct('NbIlluminationClusters', 2, 'FeaturesToUse', [], 'AlignHistogram', 0);
            args = parseargs(defaultArgs, varargin{:});
            
            obj = obj@LightingClassifier(modelName, verbose);
            myfprintf(obj.verbose, 'Created BDT lighting classifier %s\n', obj.modelName);
            
            obj.nbIlluminationClusters = args.NbIlluminationClusters;
            obj.featuresToUse = args.FeaturesToUse;
            obj.alignHistogram = args.AlignHistogram;
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
            defaultArgs = struct('NbTrees', 5, 'NbNodes', 10, 'BalanceData', 0);
            args = parseargs(defaultArgs, varargin{:});
            
            obj.nbTrees = args.NbTrees;
            obj.nbNodes = args.NbNodes;
            
            % compute weights
            if args.BalanceData
                [h,hInd] = histc(sunClusters, unique(sunClusters));
                weights = min(h)./h(hInd);
            else
                weights = [];
            end
            
            if obj.nbIlluminationClusters == 2
                % change labels to [-1,1]
                sunClusters = sunClusters*2-3;
                obj.model = train_boosted_dt_2c(features, [], ...
                    sunClusters, obj.nbTrees, obj.nbNodes, 0, weights);
            else
                obj.model = train_boosted_dt_mc(features, [], ...
                    sunClusters, obj.nbTrees, obj.nbNodes, 0, weights);
            end
        end
        
        %% Apply classifier
        function [labels, probabilities] = test(obj, testFeatures)
            % run BDT
            confidences = test_boosted_dt_mc(obj.model, testFeatures);
            
            % get probabilities
            probabilities = 1./(1+exp(-confidences));
            
            % get labels
            if size(probabilities,2)==1
                probabilities = cat(2, 1-probabilities, probabilities);
            end
            [m,labels] = max(probabilities, [], 2);
        end
    end
end