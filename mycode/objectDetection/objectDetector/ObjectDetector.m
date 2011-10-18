classdef ObjectDetector
    % ObjectDetector Defines general object detector class (must be sub-classed)
    %   Detailed explanation goes here
    
    properties (SetAccess = protected, GetAccess = public)
        isInitialized = false;
        verbose = 0;
        modelName = '';
        useIllumination = 0;
    end
        
    methods 
        % constructor
        function obj = ObjectDetector(verbose, modelName, useIllumination)
            if nargin == 0
                verbose = 0;
            end
            obj.verbose = verbose;
            obj.modelName = modelName;
            obj.useIllumination = useIllumination;
        end
        
        % initializes the object detector
        function obj = initialize(obj)
            if obj.isInitialized
                error('Object already initialized!');
            end
            obj.isInitialized = true;
        end
            
        % detect objects in an input image
        function detectObjects(obj)
            if ~obj.isInitialized
                error('Object detector must be initialized before it can detect objects!');
            end
        end
    end
end

