classdef ShadowsIlluminationPredictor < LocalIlluminationPredictor
    % Predicts the lighting based on a shadow boundary
    %
    
    %% Private properties
    properties (SetAccess=private, GetAccess=public)
        % Pre-computed data
        data = [];
    end
    
    properties (Constant)
        % name of file
        modelName = 'shadowPredictorGtGroundMask74-nobad';
    end
    
    methods
        %% Constructor
        function obj = ShadowsIlluminationPredictor(varargin)
            % parse arguments
            defaultArgs = struct('NbAzimuthBins', 32, 'NbZenithBins', 5, 'AlignHistogram', 0, 'Verbose', 0);
            args = parseargs(defaultArgs, varargin{:});
            
            obj = obj@LocalIlluminationPredictor(args.Verbose, args.NbAzimuthBins, ...
                args.NbZenithBins, args.AlignHistogram);
            myfprintf(obj.verbose, 'Created shadows lighting predictor.\n');
        end
        
        %% Initializes the lighting classifier
        function obj = initialize(obj)
            % call the super-cass method
            obj = initialize@LocalIlluminationPredictor(obj);
            obj.data = load(fullfile(obj.classifBasePath, sprintf('%s.mat', obj.modelName)));
            
            % histogram the errors
                     
        end
        
        %% Saves the object lighting classifier
        function save(obj)
            outputFile = fullfile(obj.classifBasePath, sprintf('%s.mat', obj.modelName));
            [m,m,m] = mkdir(fileparts(outputFile));
            save(outputFile, 'obj');
        end
        
        %% Display distribution
        function illProb = probIlluminationGivenObject(obj, bndOrientation)
            % call the super-cass method
            obj = probIlluminationGivenObject@LocalIlluminationPredictor(obj);
            
            illProb = obj.getIlluminationProb(obj.data.sErrors, obj.data.sLengths, bndOrientation);
        end
        
        %% Predict the lighting
        function illProb = probIlluminationGivenNonObject(obj, bndOrientation)
            % call the super-cass method
            obj = probIlluminationGivenNonObject@LocalIlluminationPredictor(obj);
            
            illProb = obj.getIlluminationProb(obj.data.nsErrors, obj.data.nsLengths, bndOrientation);
        end
        
        %% Predict the illumination histogram
        function prob = getIlluminationProb(obj, errors, lengths, bndOrientation)
            % mirror about pi/2
            errors = cat(2, errors, pi-errors);
            lengths = cat(2, lengths, lengths);
            
            % mirror about 0
            errors = cat(2, errors, -errors);
            lengths = cat(2, lengths, lengths);
            
            % rotate by boundary orientation
            errors = errors + bndOrientation;
            
            % put in [-pi, pi] interval
            errors = mod(errors, 2*pi);
            errors(errors>pi) = errors(errors>pi)-2*pi;
            
            % weight each error by the length of its line (longer lines should count more)
            indErrors = lengths>prctile(lengths,5) & lengths<prctile(lengths,95);
            prob = angularHistogramWeighted(errors(indErrors), lengths(indErrors), obj.nbAzimuthBins, obj.alignHistogram);
%             prob = angularHistogram(errors(lengths<10), obj.nbAzimuthBins, obj.alignHistogram);
            
            % smooth -> pad before and after
            nbPad = 5;
            tmpProb = cat(2, prob(end:-1:end-nbPad+1), prob, prob(1:nbPad));
            tmpProb = conv2(tmpProb, fspecial('gaussian', [1 3], 1), 'same');
            prob = tmpProb(nbPad+1:end-nbPad);
            
            % normalize
            prob = prob./sum(prob(:));
            prob = prob(:)';
        end
        
    end
end