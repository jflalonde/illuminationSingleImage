classdef WallIlluminationPredictor < LocalIlluminationPredictor
    % Predicts the lighting based on a shadow boundary
    %
    
    %% Private properties
    properties (SetAccess=private, GetAccess=public)
        % Pre-computed data
        data = [];
        
        % Models (for walls and non-walls) fitted to data
        wModel = [];
        nwModel = [];
        
        % wall angles 1=facing left, 2=facing camera, 3=facing right
        wallAngles = [-pi/2 -pi pi/2];
    end
    
    properties (Constant)
        % name of file
        modelName = 'wallsPredictor';
    end
    
    methods
        %% Constructor
        function obj = WallIlluminationPredictor(varargin)
            % parse arguments
            defaultArgs = struct('NbAzimuthBins', 32, 'NbZenithBins', 5, 'AlignHistogram', 0, 'Verbose', 0);
            args = parseargs(defaultArgs, varargin{:});
            
            obj = obj@LocalIlluminationPredictor(args.Verbose, args.NbAzimuthBins, ...
                args.NbZenithBins, args.AlignHistogram);
            myfprintf(obj.verbose, 'Created wall lighting predictor.\n');
        end
        
        %% Initializes the lighting classifier
        function obj = initialize(obj)
            % call the super-cass method
            obj = initialize@LocalIlluminationPredictor(obj);
            obj.data = load(fullfile(obj.classifBasePath, sprintf('%s.mat', obj.modelName)));
            
            % fit sigmoid to data
            obj.wModel.b=mnrfit(obj.data.wInts(:), (obj.data.wErrors(:)<=pi/2)+1);
            obj.nwModel.b=mnrfit(obj.data.nwInts(:), (obj.data.nwErrors(:)<=pi/2)+1);
            
            % robustly fit linear model
%             [b, stats] = robustfit(obj.data.wInts(:), obj.data.wErrors(:));
%             obj.model.b = b;
%             obj.model.sigma = stats.robust_s;
            
        end
        
        %% Saves the object lighting classifier
        function save(obj)
            outputFile = fullfile(obj.classifBasePath, sprintf('%s.mat', obj.modelName));
            [m,m,m] = mkdir(fileparts(outputFile));
            save(outputFile, 'obj');
        end
        
        %% Predict the illumination histogram
        function [illProb, valid] = probIlluminationGivenObject(obj, img, objMask, wallInd)
            % call the super-cass method
            obj = probIlluminationGivenObject@LocalIlluminationPredictor(obj);
            
            % obtain illumination if it's a "wall", facing with corresponding direction
            [illProb, valid] = probIllumination(obj, img, obj.wModel, objMask, obj.wallAngles(wallInd));
        end
        
        %% Predict the lighting
        function [illProb, valid] = probIlluminationGivenNonObject(obj, img, objMask)
            % call the super-cass method
            obj = probIlluminationGivenNonObject@LocalIlluminationPredictor(obj);
            
            % obtain illumination if it's a "non-wall", facing forward
            [illProb, valid] = probIllumination(obj, img, obj.nwModel, objMask, rand*2*pi-pi);
        end
        
        %% Predict lighting
        function [illProb, valid] = probIllumination(obj, img, model, objMask, wallAngle)
            % make sure we've got enough pixels to work with
            if nnz(objMask) < 50
                illProb = constantProbAz(obj);
                valid = 0;
                return;
            end
            
            valid = 1;
            
            % compute the wall intensity
            wallInt = computeWallIntensity(rgb2gray(img), objMask);
            
            % get probability of sun on same side as wall
            sunDirProb = mnrval(model.b, wallInt); sunDirProb = sunDirProb(2);
            
            % generate gaussian with area corresponding to sunDirProb
            if sunDirProb > 0.5
                sOpt = optimizeSigma(sunDirProb, obj.nbAzimuthBins, obj.alignHistogram);
                illProb = angularGaussian(wallAngle, sOpt, obj.nbAzimuthBins, obj.alignHistogram);
            else
                % predict sun in opposite direction
                sOpt = optimizeSigma(1-sunDirProb, obj.nbAzimuthBins, obj.alignHistogram);
                illProb = angularGaussian(wallAngle+pi, sOpt, obj.nbAzimuthBins, obj.alignHistogram);
            end
            
        end
    end
end