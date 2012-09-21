classdef LightingClassifier
    % LightingClassifier defines the general lighting classifier class (must be sub-classed)
    %   This classifier learns how the appearance of an object predicts the
    %   illumination conditions. It should be the case that it outputs a
    %   confident prediction if an object is indeed present in the window,
    %   and not confident (and hopefully wrong) otherwise. 
    
    properties (SetAccess = protected, GetAccess = public)
        isInitialized = false;
        verbose = 0;
        modelName = '';
    end
        
    methods 
        % constructor
        function obj = LightingClassifier(modelName, verbose)
            if nargin >= 2
                obj.verbose = verbose;
            end
            obj.modelName = modelName;
        end
        
        % initializes the object detector
        function obj = initialize(obj)
            if obj.isInitialized
                error('Already initialized!');
            end
            obj.isInitialized = true;
        end
        
        % train the classifier
        function obj = train(obj)
            if ~obj.isInitialized
                error('Must be initialized before it can be trained!');
            end
        end
            
        % detect objects in an input image
        function predictLighting(obj)
            if ~obj.isInitialized
                error('Must be initialized before it can predict lighting!');
            end
        end
    end
end

