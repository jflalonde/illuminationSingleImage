classdef PedestrianIlluminationPredictor < LocalIlluminationPredictor
    % Predicts the lighting based on a shadow boundary
    %
    
    %% Private properties
    properties (SetAccess=private, GetAccess=public)
        % Pre-computed data
        data = [];
        
        % Model fitted to data
        model = [];
    end
    
    properties (Constant)
        % name of file
        modelName = 'pedestrianPredictor';
    end
    
    methods
        %% Constructor
        function obj = PedestrianIlluminationPredictor(varargin)
            % parse arguments
            defaultArgs = struct('NbAzimuthBins', 32, 'NbZenithBins', 5, 'AlignHistogram', 0, 'Verbose', 0);
            args = parseargs(defaultArgs, varargin{:});
            
            obj = obj@LocalIlluminationPredictor(args.Verbose, args.NbAzimuthBins, ...
                args.NbZenithBins, args.AlignHistogram);
            myfprintf(obj.verbose, 'Created pedestrian lighting predictor.\n');
        end
        
        %% Initializes the lighting classifier
        function obj = initialize(obj)
            % call the super-cass method
            obj = initialize@LocalIlluminationPredictor(obj);
%             obj.data = load(fullfile(obj.classifBasePath, sprintf('%s.mat', obj.modelName)));
        end
        
        %% Saves the object lighting classifier
        function save(obj)
            outputFile = fullfile(obj.classifBasePath, sprintf('%s.mat', obj.modelName));
            [m,m,m] = mkdir(fileparts(outputFile));
            save(outputFile, 'obj');
        end
        
        %% Predict the lighting given an object
        function illProb = probIlluminationGivenObject(obj, pLocalLighting)
            % call the super-cass method
            obj = probIlluminationGivenObject@LocalIlluminationPredictor(obj);
            illProb = obj.getIlluminationProb(pLocalLighting);
        end
        
        %% Predict the lighting given a non-object
        function illProb = probIlluminationGivenNonObject(obj, pLocalLighting)
            % call the super-cass method
            obj = probIlluminationGivenNonObject@LocalIlluminationPredictor(obj);
            illProb = obj.getIlluminationProb(pLocalLighting);
        end
        
        %% Predict the lighting
        function illProb = getIlluminationProb(obj, pLocalLighting)
            [h,i,c] = angularHistogram([], length(pLocalLighting), obj.alignHistogram);
            angDev = c(2)-c(1);
            sigma = optimizeSigma(0.95, obj.nbAzimuthBins, obj.alignHistogram, angDev);
            
            % simply re-histogram the input lighting (for now?)
            illProb = [];
            for p=1:length(pLocalLighting)
                illProb = cat(1, illProb, angularGaussian(c(p), sigma, obj.nbAzimuthBins, obj.alignHistogram));
            end
            
            illProb = repmat(pLocalLighting', 1, obj.nbAzimuthBins).*illProb;
            illProb = sum(illProb, 1);
            illProb = illProb./sum(illProb(:));
        end
    end
end