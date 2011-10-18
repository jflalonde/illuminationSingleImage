classdef VOCObjectDetector < ObjectDetector
    % VOCObjectDetector Implementation of the ObjectDetector interface
    % which uses the object detector by P. Felzenszwalb, D. McAllester, D. Ramaman.
    %   
    % Note: the training code is not quite working...
    
    %% Constant properties
    properties (Constant)
        % training paths
        dataBasePath = '/nfs/hn01/jlalonde/data/illuminationUnderstanding';
        vocDbName = 'VOC2009';
        
        % results paths
        resultsBasePath = '/nfs/hn01/jlalonde/results/illuminationUnderstanding';
    end
    
    %% Private properties
    properties (SetAccess = private, GetAccess = public)
        modelInfo = [];
        
        % additional paths (they are created in the constructor)
        vocBasePath = [];   % fullfile(dataBasePath, vocDbName);
        vocDbPath = [];     % fullfile(vocBasePath, 'Annotations');
        vocImgSetPath = []; % fullfile(vocBasePath, 'ImageSets', 'Main');
        
        detectorBasePath = []; % fullfile(dataBasePath, 'objectDetection', 'detectors');
        
        % labelme paths
        labelmeImagesPath = []; % fullfile(resultsBasePath, 'labelmeImages'); 

        % whether the components should be independent or not
        indepComponents = 0;
        
        % whether features should be symmetrized or not
        symmetrize = 0;
        
        % whether HOG should be normalized or not
        normalizeHOG = 1;
        
        % bounding box expansion
        bboxExpansionFactor = 0;
        
        % whether to align the angular histogram with axes or not
        alignHistogram = 0;
        
        % whether to expand the bounding box to include the ground (below object)
        bboxExpandBottom = 0;
        
        % whether to use a down-sampled version of the image
        smallImg = 0;

        % specify sub-directory for cache
        cacheSubDir = '';
    end
    
    %% Public methods
    methods
        %% Constructor
        function vocObj = VOCObjectDetector(verbose, modelName, varargin)
            % parse arguments
            defaultArgs = struct('UseIllumination', 0, 'IndependentComponents', 0, ...
                                 'Symmetrize', [], 'NormalizeHOG', 1, 'BboxExpansionFactor', 0, ...
                                 'AlignHistogram', 0, 'BboxExpandBottom', 0, 'SmallImg', 0);
            args = parseargs(defaultArgs, varargin{:});

            vocObj = vocObj@ObjectDetector(verbose, modelName, args.UseIllumination);
            myfprintf(vocObj.verbose, 'Created VOC object detector %s\n', vocObj.modelName);
            
            vocObj.indepComponents = args.IndependentComponents;
            vocObj.normalizeHOG = args.NormalizeHOG;
            vocObj.bboxExpansionFactor = args.BboxExpansionFactor;
            vocObj.alignHistogram = args.AlignHistogram;
            vocObj.bboxExpandBottom = args.BboxExpandBottom;
            vocObj.smallImg = args.SmallImg;
            
            if isempty(args.Symmetrize)
                % wasn't specified: use UseIllumination
                vocObj.symmetrize = ~args.UseIllumination;
            else
                vocObj.symmetrize = args.Symmetrize;
            end

            % voc paths
            vocObj.vocBasePath = fullfile(vocObj.dataBasePath, vocObj.vocDbName);
            vocObj.vocDbPath = fullfile(vocObj.vocBasePath, 'Annotations');
            vocObj.vocImgSetPath = fullfile(vocObj.vocBasePath, 'ImageSets', 'Main');
            
            vocObj.detectorBasePath = fullfile(vocObj.resultsBasePath, 'objectDetection', 'detectors');
            
            % labelme paths
            vocObj.labelmeImagesPath = fullfile(vocObj.resultsBasePath, 'labelmeImages');
        end
        
        %% Initializes the object detector
        function vocObj = initialize(vocObj)
            % call the super-cass method 
            vocObj = initialize@ObjectDetector(vocObj);
            
            % simply load the model
            inputFile = fullfile(vocObj.detectorBasePath, sprintf('%s.mat', vocObj.modelName));
            vocObj.modelInfo = load(inputFile, 'model', 'indepComponentModel');

            paramsInfo = load(inputFile);

            % load additional parameters
            if isfield(paramsInfo, 'useIllumination')
                vocObj.useIllumination = paramsInfo.useIllumination;
            end
            if isfield(paramsInfo, 'indepComponents')
                vocObj.indepComponents = paramsInfo.indepComponents;
            end
            if isfield(paramsInfo, 'normalizeHOG')
                vocObj.normalizeHOG = paramsInfo.normalizeHOG;
            end
            if isfield(paramsInfo, 'symmetrize')
                vocObj.symmetrize = paramsInfo.symmetrize;
            end
            if isfield(paramsInfo, 'bboxExpansionFactor')
                vocObj.bboxExpansionFactor = paramsInfo.bboxExpansionFactor;
            end
            if isfield(paramsInfo, 'alignHistogram')
                vocObj.alignHistogram = paramsInfo.alignHistogram;
            end
            if isfield(paramsInfo, 'bboxExpandBottom')
                vocObj.bboxExpandBottom = paramsInfo.bboxExpandBottom;
            end
            if isfield(paramsInfo, 'smallImg')
                vocObj.smallImg = paramsInfo.smallImg;
            end
            
            if ~isfield(vocObj.modelInfo.model, 'normalizeHOG')
                vocObj.modelInfo.model.normalizeHOG = vocObj.normalizeHOG;
            end
            
            if ~isfield(vocObj.modelInfo.model, 'symmetrize')
                vocObj.modelInfo.model.symmetrize = vocObj.symmetrize;
            end
            
            myfprintf(vocObj.verbose, 'Initialized VOC object detector with model %s\n', vocObj.modelName);
        end
        
        %% Saves itself to file
        function save(vocObj, forceOverwrite)
            if nargin < 2
                forceOverwrite = 0;
            end
            
            outputFile = fullfile(vocObj.detectorBasePath, sprintf('%s.mat', vocObj.modelName));

            doSave = 0;
            if exist(outputFile, 'file') && ~forceOverwrite
                u = input('File already exists! Are you sure? (y/N): ', 's');
                if strcmp(u, 'y')
                    doSave = 1;
                end
            else
                doSave = 1;
            end
            
            if doSave
                if isfield(vocObj.modelInfo, 'indepComponentModel')
                    indepComponentModel = vocObj.modelInfo.indepComponentModel;
                else
                    indepComponentModel = [];
                end

                if isfield(vocObj.modelInfo, 'model')
                    model = vocObj.modelInfo.model;
                else
                    model = [];
                end

                indepComponents = vocObj.indepComponents;
                symmetrize = vocObj.symmetrize;
                normalizeHOG = vocObj.normalizeHOG;
                useIllumination = vocObj.useIllumination;
                bboxExpansionFactor = vocObj.bboxExpansionFactor;
                alignHistogram = vocObj.alignHistogram;
                bboxExpandBottom = vocObj.bboxExpandBottom;
                smallImg = vocObj.smallImg;

                save(outputFile, 'model', 'indepComponentModel', 'indepComponents', 'symmetrize', 'normalizeHOG', 'useIllumination', 'bboxExpansionFactor', 'alignHistogram', 'bboxExpandBottom', 'smallImg');
                myfprintf(vocObj.verbose, 'Saved %s.\n', outputFile);
            end
        end
        
        %% Save normalization parameters
        function vocObj = saveNormalizationParameters(vocObj, A, B, componentId, forceOverwrite)
            if nargin < 4
                componentId = 0;
            end
            
            if nargin < 5
                forceOverwrite = 0;
            end
            
            % add A and B to file
            myfprintf(vocObj.verbose, 'Saving normalization parameters A=%.3f, B=%.3f\n', A, B);
            if componentId == 0 || ~vocObj.indepComponents
                vocObj.modelInfo.model.A = A;
                vocObj.modelInfo.model.B = B;
            else
                vocObj.modelInfo.indepComponentModel.model(componentId).A = A;
                vocObj.modelInfo.indepComponentModel.model(componentId).B = B;
            end
            
            save(vocObj, forceOverwrite);
        end
        
        %% Normalizes the confidence based on pre-computed sigmoid parameters
        function prob = normalizeConfidences(vocObj, confidences, componentId)
            if nargin < 3
                componentId = 0;
            end
            
            if componentId == 0
                if ~isfield(vocObj.modelInfo.model, 'A')
                    error('Model hasn''t been normalized yet!');
                end
                
                % recover parameters, and normalize detector outputs
                A = vocObj.modelInfo.model.A;
                B = vocObj.modelInfo.model.B;
            else
                if ~isfield(vocObj.modelInfo.indepComponentModel.model(componentId), 'A')
                    error('Component %d hasn''t been normalized yet!', componentId);
                end
                
                % recover parameters, and normalize detector outputs
                A = vocObj.modelInfo.indepComponentModel.model(componentId).A;
                B = vocObj.modelInfo.indepComponentModel.model(componentId).B;    
            end
            
            prob = logisticProb([A B], confidences);
        end
        
        %% Clears the cache
        function clearCache(vocObj)
            cacheDir = getCacheDir(vocObj);
            [s,m] = rmdir(cacheDir, 's');
            if s
                myfprintf(vocObj.verbose, 'Cache successfully deleted\n');
            else
                myfprintf(vocObj.verbose, 'Error in deleting cache: %s\n', m);
            end
        end
        
        %% Returns number of components
        function nbComponents = getNumberOfComponents(vocObj)
            if isempty(vocObj.modelInfo.indepComponentModel)
                nbComponents = length(vocObj.modelInfo.model.components);
            else
                nbComponents = length(vocObj.modelInfo.indepComponentModel.model);
            end
        end
        
        %% Sets the "active" independent component (will be used in detectObjects)
        function vocObj = setActiveIndepComponent(vocObj, i)
            if i > 0 && i <= getNumberOfComponents(vocObj)
                myfprintf(vocObj.verbose, 'Activating component %d\n', i);
                vocObj.modelInfo.model = vocObj.modelInfo.indepComponentModel.model(i);
            else
                myfprintf(vocObj.verbose, 'Disabling independent components');
                vocObj.modelInfo.model = [];
            end
        end

        %% Keep only a subset of independent components
        function vocObj = keepSubsetIndepComponent(vocObj, ind)
            vocObj.modelInfo.indepComponentModel.model = vocObj.modelInfo.indepComponentModel.model(ind);
        end

        %% Detects objects in an image (varargin is the optional threshold)
        function bbox = detectObjects(vocObj, img, varargin)
            % call the super-class method
            detectObjects@ObjectDetector(vocObj);
            
            myfprintf(vocObj.verbose, 'Detecting objects in image...'); tic;
            if isfield(vocObj.modelInfo, 'model') && ~isempty(vocObj.modelInfo.model)
                % detect objects using dependent components
                bbox = process(img, vocObj.modelInfo.model, varargin{:}); 
                
                % compensate for larger bounding boxes
                bbox = vocObj.shrinkBbox(bbox);

            elseif isfield(vocObj.modelInfo, 'indepComponentModel') && ~isempty(vocObj.modelInfo.indepComponentModel)
                % detect objects using independent components
                bbox = [];
                for i=1:length(vocObj.modelInfo.indepComponentModel)
                    % detect objects using component i
                    vocObj.setActiveIndepComponent(i);
                    curBbox = detectObjectsParams(img, 'DoBboxPrediction', 0, 'DoNMS', 0, 'DoClipBoxes', 0);
                    
                    % normalize output
                    normConf = vocObj.normalizeConfidences(curBbox(:,end), i);
                
                    % save bounding boxes
                    bbox = cat(1, bbox, cat(2, curBbox(:, 1:4), normConf));
                end
                
                % NMS and clip boxes
                bbox = nms(bbox, 0.5);
                bbox = clipboxes(img, bbox);
                
                % reset active component
                vocObj.setActiveIndepComponent(-1);
                
            else
                myfprintf(vocObj.verbose, 'Couldn''t find model...');
                bbox = [];
            end
            myfprintf(vocObj.verbose, 'done in %.2fs\n', toc);
        end
        
        %% Detects objects in an image, with more parameters
        function bbox = detectObjectsParams(vocObj, img, varargin)
            defaultArgs = struct('Threshold', [], 'DoBboxPrediction', 0, 'DoNMS', 1, 'NMSThreshold', 0.5, 'DoClipBoxes', 1, 'Normalize', 0);
            args = parseargs(defaultArgs, varargin{:});

            % run detector
            if isfield(vocObj.modelInfo, 'model') && ~isempty(vocObj.modelInfo.model)
                % detect objects using dependent components
                if isempty(args.Threshold)
                    bbox = detect(img, vocObj.modelInfo.model, vocObj.modelInfo.model.thresh);
                else
                    bbox = detect(img, vocObj.modelInfo.model, args.Threshold);
                end

                % resize bounding boxes
                bbox = vocObj.shrinkBbox(bbox);
                
                if args.DoBboxPrediction
                    % this is available only if bounding box prediction has been trained
                    bbox = getboxes(vocObj.modelInfo.model, bbox);
                end

            elseif isfield(vocObj.modelInfo, 'indepComponentModel') && ~isempty(vocObj.modelInfo.indepComponentModel)
                % detect objects using independent components
                bbox = [];
                for i=1:vocObj.getNumberOfComponents()
                    % detect objects using component i
                    vocObjTmp = setActiveIndepComponent(vocObj, i);
                    curBbox = detectObjectsParams(vocObjTmp, img, 'Threshold', args.Threshold, ...
                                                  'DoBboxPrediction', args.DoBboxPrediction, 'DoNMS', ...
                                                  0, 'DoClipBoxes', 0);
                    
                    % normalize output
                    normConf = normalizeConfidences(vocObj, curBbox(:,end), i);
                    
                    % save bounding boxes
                    bbox = cat(1, bbox, cat(2, curBbox(:, 1:4), normConf));
                end
            end
                       
            if args.DoNMS
                % non-maximal suppression
                bbox = nms(bbox, args.NMSThreshold);
            end
            
            if args.DoClipBoxes
                % clip bounding boxes to image's dimensions
                bbox = clipboxes(img, bbox);
            end
            
            % normalize output?
            if args.Normalize && ~exist('normConf', 'var') && ~isempty(bbox);
                % normalize output
                normConf = normalizeConfidences(vocObj, bbox(:,end));
                
                % save bounding boxes
                bbox = [bbox(:, 1:4), normConf];
            end
        end
        
        %% Detects objects in an image with known component weights
        function bbox = detectObjectsWeightedComponents(vocObj, img, componentWeight, varargin)
            defaultArgs = struct('DoNMS', 1, 'DoClipBoxes', 1, 'Threshold', []);
            args = parseargs(defaultArgs, varargin{:});

            bbox = [];
            if isfield(vocObj.modelInfo, 'indepComponentModel') && ~isempty(vocObj.modelInfo.indepComponentModel)
                if vocObj.getNumberOfComponents() ~= length(componentWeight)
                    error('Number of components should be the same as length of component weights');
                end

                % make sure all components have the same size (to evaluate the same windows)
                rootSize = [];
                for i=1:vocObj.getNumberOfComponents()
                    curRootSize = vocObj.modelInfo.indepComponentModel.model(i).rootfilters{1}.size;
                    if i == 1
                        rootSize = curRootSize;
                    elseif ~isequal(curRootSize, rootSize)
                        error('All components should have the same size');
                    end
                end
                
                % detect objects using independent components
                detectorConf = [];
                detectorScore = [];
                
                % only loop over non-zero weights
                for i=1:vocObj.getNumberOfComponents()
                    % score each window using component i
                    vocObjTmp = setActiveIndepComponent(vocObj, i);
                    curBbox = detectObjectsParams(vocObjTmp, img, 'Threshold', -Inf, ...
                                                  'DoBboxPrediction', 0, 'DoNMS', 0, 'DoClipBoxes', 0);
                    
                    % normalize output
                    detScore = curBbox(:,end);
                    normConf = normalizeConfidences(vocObj, detScore, i);
                    % HACK!!
                    % normConf = curBbox(:,end);

                    % save bounding boxes
                    if isempty(bbox)
                        bbox = curBbox(:,1:4);
                    else
                        if ~isequal(bbox, curBbox(:, 1:4))
                            error('Components aren''t generating the same bounding boxes: they probably don''t have the same size!');
                        end
                    end
                    detectorConf = cat(2, detectorConf, normConf);
                    detectorScore = cat(2, detectorScore, detScore);
                end
            else
                error('Illumination-aware detector assumes independent components at this point.\n');
            end
            
            % threshold based on each detector's output
            detectorScoreInd = false(size(detectorScore));
            for i=1:vocObj.getNumberOfComponents()
                if isempty(args.Threshold)
                    % use the automatically computed threshold (high recall)
                    thresh = vocObj.modelInfo.indepComponentModel.model(i).thresh;
                elseif numel(args.Threshold == size(detectorConf,2))
                    % each detector's threshold is given
                    thresh = args.Threshold(i);
                else
                    % use same threshold for each component
                    thresh = args.Threshold;
                end
                detectorScoreInd(:,i) = detectorScore(:,i) > thresh;
            end
            
            % combine detectors
            windowConf = sum(repmat(componentWeight, size(detectorScore,1), 1) .* detectorScoreInd .* detectorConf, 2) ./ ...
                (sum(detectorScoreInd .* repmat(componentWeight, size(detectorScore,1), 1), 2) + eps);

            % sum over the illumination dimension
%             detectorProb = sum(detectorProb, 2);
            bbox = cat(2, bbox, windowConf);
            
            % only keep non-zero weights
            bbox = bbox(windowConf>0, :);
                       
            if args.DoNMS
                % non-maximal suppression
                bbox = nms(bbox, 0.5);
            end
            
            if args.DoClipBoxes
                % clip bounding boxes to image's dimensions
                bbox = clipboxes(img, bbox);
            end
        end
                


        %% Loads positive and negative training examples from an input image database
        function [pos, neg] = loadTrainingDataFromObjectDb(vocObj, className, objectDb, reload)
            if nargin < 4
                reload = 0;
            end
            
            % positive training examples from labelme
            pos = loadPositiveTrainingDataFromObjectDb(vocObj, className, objectDb, reload);
            
            % negative training examples from Pascal VOC 2009
            neg = loadNegativeTrainingData(vocObj, className, reload);
        end
        
        %% Indicates whether we've already loaded the training data
        function hasData = hasTrainingData(vocObj)
            cacheDir = vocObj.getCacheDir;
            hasData = exist(fullfile(cacheDir, 'posTraining.mat'), 'file') & exist(fullfile(cacheDir, 'negTraining.mat'), 'file');
        end
        
        %% Splits the input data based on internal parameters
        function splitData = splitData(vocObj, data, nbClusters)
            if vocObj.useIllumination
                splitData = splitDataByIllumination(vocObj, data, nbClusters);
            else
                splitData = splitDataByAspectRatio(vocObj, data, nbClusters);
            end
        end
        
        %% Splits the input data based on bounding boxes
        function splitData = splitDataByAspectRatio(vocObj, data, nbClusters)
            % just use the original function
            splitData = split(data, nbClusters);
        end
        
        %% Splits the input data based on illumination
        function splitData = splitDataByIllumination(vocObj, data, nbClusters)
            % 
            sunVisible = cat(1, data(:).visible);
            sunAzimuth = cat(1, data(:).sunAzimuth);
            cInd = getIllClusterFromLabel(sunVisible, sunAzimuth, nbClusters+1, vocObj.alignHistogram);
            cInd(~sunVisible) = nbClusters+1;
            
            splitData = cell(1, nbClusters+1);
            for i=1:nbClusters+1
                splitData{i} = data(cInd==i);
            end
        end
        
        %% Train!
        function vocObj = train(vocObj, className, splitPosData, negData, equalSize, parallelize)
            if nargin < 5
                equalSize = 0;
            end

            if nargin < 6
                parallelize = 0;
            end
            
            initrand();
            
            if vocObj.indepComponents
                vocObj = trainIndependentModels(vocObj, className, splitPosData, negData, equalSize, parallelize);
            else
                vocObj = trainDependentModels(vocObj, className, splitPosData, negData, equalSize);
            end
        end
        
        %% Train multiple independent 1-component models
        function vocObj = trainIndependentModels(vocObj, className, splitPosData, negData, equalSize, parallelize)
            if nargin < 5
                equalSize = 0;
            end

            if nargin < 6
                parallelize = 0;
            end

            % limit memory size (2^30 = 1GB)
            maxSize = 2^31;

            if equalSize
                % force all components to have the same root filter dimensions -> compute over all training data
                allPosData = cat(2, splitPosData{:});         
                initSize = computeFilterSize(vocObj, allPosData, 8);
            else
                initSize = [];
            end
            
            vocObj.modelInfo.indepComponentModel = [];
            for i=1:length(splitPosData)
                if parallelize
                    gotLock = acquireLock(vocObj.getCacheDir, '', sprintf('model-%d', i));
                else
                    gotLock = true;
                end

                if gotLock
                    vocObjTmp = vocObj.setCacheSubDir(sprintf('model-%d', i));
                    
                    % train root filters using warped positives & random negatives
                    myfprintf(vocObjTmp.verbose, 'Initializing independent model %d...\n', i);
                    model = trainInitializeSingleModel(vocObjTmp, className, splitPosData{i}, negData, ...
                                                       maxSize, initSize, sprintf('init-%d.mat', i));
                    
                    % train using latent detections & hard negatives
                    cont = false; C = 0.003; J = 2;
                    myfprintf(vocObjTmp.verbose, 'Training model %d with hard negatives...\n', i);
                    model = trainMineHardNegatives(vocObjTmp, className, model, splitPosData{i}, negData, 2, 3, ...
                                                   maxSize, sprintf('mine-%d.mat', i), cont, C, J);
                    
                    vocObj.modelInfo.indepComponentModel.model(i) = model;
                end
            end
        end
        
      
        %% Train 1 multiple-component model
        function vocObj = trainDependentModels(vocObj, className, splitPosData, negData, equalSize)
            % concatenate split positive data
            allPosData = cat(2, splitPosData{:});
            
            % randomly permute?
            allPosData = allPosData(randperm(length(allPosData)));
            
            if equalSize
                initSize = computeFilterSize(vocObj, allPosData, 8);
            else
                initSize = [];
            end
            
            % limit memory size (2^30 = 1GB)
            maxSize = 2^31;

            % train root filters using warped positives & random negatives
            % (warped to bbox)
            myfprintf(vocObj.verbose, 'Training root filters using warped positives and random negatives...\n');
            models = trainInitialize(vocObj, className, splitPosData, negData, maxSize, initSize, 'init.mat');
            
            % merge models
            myfprintf(vocObj.verbose, 'Merging models...\n');
            model = mergemodels(models);
            
            % update models using full set of negatives
            myfprintf(vocObj.verbose, 'Training latent detections and hard negatives...\n');
            cont = false; C = 0.003.*length(splitPosData); J = 2;
            model = trainMineHardNegatives(vocObj, className, model, allPosData, negData, 3, 5, maxSize, 'mine.mat', cont, C, J);

            vocObj.modelInfo.model = model;
            myfprintf(vocObj.verbose, 'All done!\n');
        end
        
        %% Expand bounding box
        function bboxExpanded = expandBboxBottom(vocObj, bbox, imgSize)
            % make sure we expand the bounding box in such a way that will
            % make it easier to split HOG features
            bboxExpanded = expandBbox(bbox, 0.2, imgSize, 'ExpandWidth', 0);
            bboxExpanded = expandBbox(bboxExpanded, 1.25, imgSize, 'ExpandHeight', 0);
        end
        
        %% Shrink bounding box
        function bboxShrunk = shrinkBboxBottom(vocObj, bbox)
            bboxShrunk = shrinkBbox(bbox, 1.25, 'ShrinkHeight', 0);
            bboxShrunk = shrinkBbox(bboxShrunk, 0.2, 'ShrinkWidth', 0);
        end
        
        
        %% Expand bounding box
        % bbox = [x1 y1 x2 y2 ...]
        function bboxExpanded = expandBbox(vocObj, bbox, imgSize)
            if vocObj.bboxExpandBottom
                bboxExpanded = expandBboxBottom(vocObj, bbox, imgSize);
            else
                bboxExpanded = expandBbox(bbox, vocObj.bboxExpansionFactor, imgSize);
            end
        end

        %% Shrink bounding boxes
        % bbox = [x1 y1 x2 y2 ...]
        function bboxShrunk = shrinkBbox(vocObj, bbox)
            if vocObj.bboxExpandBottom
                bboxShrunk = shrinkBboxBottom(vocObj, bbox);
            else
                bboxShrunk = shrinkBbox(bbox, vocObj.bboxExpansionFactor);
            end
        end
    end
    
    %% Private methods
    methods (Access = private)
        
        %% Initialize models
        function models = trainInitialize(vocObj, className, splitPosData, negData, maxSize, initSize, outputPath)
            outputPath = fullfile(vocObj.getCacheDir, outputPath);
            if exist(outputPath, 'file')
                load(outputPath);
            else
                % train root filter for each cluster using warped positives
                models = cell(1, length(splitPosData));
                for i=1:length(splitPosData)
                    % train root filter for each cluster using warped positives
                    if ~isempty(initSize)
                        models{i} = initmodel(splitPosData{i}, vocObj.symmetrize, vocObj.normalizeHOG, vocObj.bboxExpandBottom, vocObj.smallImg, 8, initSize);
                    else
                        % automatically determines the root filter size
                        models{i} = initmodel(splitPosData{i}, vocObj.symmetrize, vocObj.normalizeHOG, vocObj.bboxExpandBottom, vocObj.smallImg, 8);
                    end
                    models{i} = train(className, models{i}, splitPosData{i}, negData, 1, 1, 1, 1, maxSize, vocObj.getCacheDir);
                end
                save(outputPath, 'models');
            end
        end
        
        %% Initialize single model
        function model = trainInitializeSingleModel(vocObj, className, posData, negData, maxSize, initSize, outputPath)
            outputPath = fullfile(vocObj.getCacheDir, outputPath);
            if exist(outputPath, 'file')
                load(outputPath);
            else
                % train root filter for each cluster using warped positives
                if ~isempty(initSize)
                    model = initmodel(posData, vocObj.symmetrize, vocObj.normalizeHOG, vocObj.bboxExpandBottom, vocObj.smallImg, 8, initSize);
                else
                    % automatically determines the root filter size
                    model = initmodel(posData, vocObj.symmetrize, vocObj.normalizeHOG, vocObj.bboxExpandBottom, vocObj.smallImg, 8);
                end
                model = train(className, model, posData, negData, 1, 1, 1, 1, maxSize, vocObj.getCacheDir);
                save(outputPath, 'model');
            end
        end
        
        %% Latent root & hard negatives
        function model = trainMineHardNegatives(vocObj, className, modelInit, allPosData, negData, nbIter, nbNegIter, maxSize, outputPath, cont, C, J)
            outputPath = fullfile(vocObj.getCacheDir, outputPath);
            if exist(outputPath, 'file')    
                load(outputPath);
            else
                model = train(className, modelInit, allPosData, negData, 0, 0, nbIter, nbNegIter, maxSize, vocObj.getCacheDir, cont, C, J);
                save(outputPath, 'model');
            end
        end
        
        %% Loads positive training data from an object database
        function pos = loadPositiveTrainingDataFromObjectDb(vocObj, className, objectDb, reload)
            cacheDir = vocObj.getCacheDir;
            outputFile = fullfile(cacheDir, 'posTraining.mat');
            if ~reload && exist(outputFile, 'file')
                myfprintf(vocObj.verbose, 'Re-loading existing positive training data file...\n');
                load(outputFile);
                return;
            end
            
            myfprintf(vocObj.verbose, 'Loading positive training data...')
            pos = [];
            for i=1:length(objectDb);
                objInfo = objectDb(i).document;
                
                imgPath = fullfile(vocObj.labelmeImagesPath, objInfo.image.folder, objInfo.image.filename);

                % add object
                pos = cat(2, pos, addSingleTrainingExample(vocObj, imgPath, objInfo, 0));
                
                % add flipped version
                pos = cat(2, pos, addSingleTrainingExample(vocObj, imgPath, objInfo, 1));
            end
            myfprintf(vocObj.verbose, 'done.\n');
            
            % save to file
            save(outputFile, 'pos');
        end        
        
        %% Useful function: save a single entry
        function pos = addSingleTrainingExample(vocObj, imgPath, objInfo, flip)
            [xn yn] = getLMpolygon(objInfo.polygon);
            bbox = [min(xn) min(yn) max(xn) max(yn)];
            
            imgSize = [str2double(objInfo.image.size.height) str2double(objInfo.image.size.width)];
            bbox = vocObj.expandBbox(bbox, imgSize);
            
            if flip
                % flip bounding box
                imgWidth = imgSize(2);
                bbox(1) = imgWidth - bbox(1) + 1;
                bbox(3) = imgWidth - bbox(3) + 1;
                bbox([1 3]) = bbox([3 1]); % flip min and max x
                
                % save a flipped version of the image
                imgPathFlip = strrep(imgPath, '.jpg', '_flipped.jpg');
                if ~exist(imgPathFlip, 'file')
                    imwrite(flipdim(imread(imgPath), 2), imgPathFlip);
                end
                pos.im = imgPathFlip;
                
                % azimuth multiplier (-1 if it's flipped, 1 otherwise)
                azMult = -1;
            else
                pos.im = imgPath;
                azMult = 1;
            end

            pos.x1 = bbox(1);
            pos.y1 = bbox(2);
            pos.x2 = bbox(3);
            pos.y2 = bbox(4);
            
            % add sun position
            if vocObj.useIllumination
                % keep object only if sun position is available and image is good
                pos.sunAzimuth = azMult*str2double(objInfo.sun.azimuth);
                pos.visible = str2double(objInfo.sun.visible);
            end
        end
       
        
        %% Loads negative training data
        function neg = loadNegativeTrainingData(vocObj, className, reload)
            cacheDir = vocObj.getCacheDir;
            outputFile = fullfile(cacheDir, 'negTraining.mat');
            if ~reload && exist(outputFile, 'file')
                myfprintf(vocObj.verbose, 'Re-loading existing negative training data file...\n');
                load(outputFile); 
                return;
            end
            
            % load list of images
            fid = fopen(fullfile(vocObj.vocImgSetPath, 'train.txt'));
            ids = textscan(fid, '%s'); ids = ids{1};
            fclose(fid);
            
            % select images which do *not* contain the object of interest
            myfprintf(vocObj.verbose, 'Loading negative examples...');
            neg = [];
            for i=1:length(ids);
                rec = PASreadrecord(fullfile(vocObj.vocDbPath, sprintf('%s.xml', ids{i})));
                
                clsinds = strmatch(className, {rec.objects(:).class}, 'exact');
                if isempty(clsinds)
                    newneg.im = fullfile(vocObj.dataBasePath, rec.imgname);
                    neg = cat(2, neg, newneg);
                end
            end
            myfprintf(vocObj.verbose, 'done.\n');
            
            % save loaded data to file
            save(outputFile, 'neg');
        end
        
        %% Compute size of root filter
        function initSize = computeFilterSize(vocObj, allPosData, sbin)
            
            % pick mode of aspect ratios (code from initmodel)
            h = [allPosData(:).y2]' - [allPosData(:).y1]' + 1;
            w = [allPosData(:).x2]' - [allPosData(:).x1]' + 1;
            xx = -2:.02:2;
            filter = exp(-[-100:100].^2/400);
            aspects = hist(log(h./w), xx);
            aspects = convn(aspects, filter, 'same');
            [peak, I] = max(aspects);
            aspect = exp(xx(I));
            
            % pick 50 percentile area (original: 20 prctile!)
            area = prctile(h.*w, 50);
            %                 areas = sort(h.*w);
            %                 area = areas(floor(length(areas) * 0.2));
            %                 area = max(min(area, 5000), 3000);
            
            % pick dimensions
            w = sqrt(area/aspect);
            h = w*aspect;
            
            initSize = [round(h/sbin) round(w/sbin)];            
        end
        
        %% Creates the cache directory
        function cacheDir = getCacheDir(vocObj, componentId)
            % create cache directory if it doesn't already exist
            cacheDir = fullfile(vocObj.detectorBasePath, vocObj.modelName, vocObj.cacheSubDir);
            [m,m,m] = mkdir(cacheDir);
        end

        %% Sets a sub-directory for the cache
        function vocObj = setCacheSubDir(vocObj, cacheSubDir)
            vocObj.cacheSubDir = cacheSubDir;
        end
    end
end
    