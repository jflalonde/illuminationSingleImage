classdef LocalIlluminationPredictor
    % LightingClassifier defines the general lighting classifier class (must be sub-classed)
    %   This classifier learns how the appearance of an object predicts the
    %   illumination conditions. It should be the case that it outputs a
    %   confident prediction if an object is indeed present in the window,
    %   and not confident (and hopefully wrong) otherwise. 
    
    properties (SetAccess = protected, GetAccess = public)
        isInitialized = false;
        verbose = 0;
        
        % number of sun azimuth bins
        nbAzimuthBins = 0;
        
        % number of sun zenith bins
        nbZenithBins = 0;
        
        % whether to align the histogram or not (for azimuth)
        alignHistogram = 1;
    end
    
    properties (Constant)
        % results paths
        classifBasePath = getPathName('code', 'mycode', 'data', 'localIlluminationPredictors');
    end
        
    methods 
        % constructor
        function obj = LocalIlluminationPredictor(verbose, nbAzimuthBins, nbZenithBins, alignHistogram)
            obj.verbose = verbose;
            obj.nbAzimuthBins = nbAzimuthBins;
            obj.nbZenithBins = nbZenithBins;
            obj.alignHistogram = alignHistogram;
        end
        
        % initializes the object detector
        function obj = initialize(obj)
            if obj.isInitialized
                error('Already initialized!');
            end
            obj.isInitialized = true;
        end
            
        % predicts the lighting given an object
        function obj = probIlluminationGivenObject(obj)
            if ~obj.isInitialized
                error('Must be initialized before it can predict illumination!');
            end
        end

        % predicts the lighting given a non-object
        function obj = probIlluminationGivenNonObject(obj)
            if ~obj.isInitialized
                error('Must be initialized before it can predict illumination!');
            end
        end
        
        % Return constant probability dist
        function illProb = constantProb(obj)
            illProb = ones(obj.nbZenithBins, obj.nbAzimuthBins);
            illProb = illProb./sum(illProb(:));
        end
        
        % Return constant probability dist over azimuths only
        function illProb = constantProbAz(obj)
            illProb = 1/obj.nbAzimuthBins*ones(1, obj.nbAzimuthBins);
        end
        
        % Replicate constant azimuth probability map
        function illProb = replicateConstAzimuthProb(obj, azIllProb)
            illProb = repmat(azIllProb, obj.nbZenithBins, 1);
            illProb = illProb./sum(illProb(:));
        end
    end
end

