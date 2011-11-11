classdef SkyIlluminationPredictor < LocalIlluminationPredictor
    % Predicts the lighting based on a shadow boundary
    %
    
    %% Private properties
    properties (SetAccess=private, GetAccess=public)
        % number of sun azimuth bins
        sunAzimuths = [];
        
        % number of sun zenith bins
        sunZeniths = [];
                
        % Pre-computed data
        data = [];
               
        % sky parameters
        skyParams = [];
        
        % non-parametric distribution parameters
        skyEdges = []; skyCenters = []; skyProbs = [];
        nonSkyEdges = []; nonSkyCenters = []; nonSkyProbs = [];
    end
    
    properties (Constant)
        % name of file
        modelName = 'skyPredictor';
    end
    
    methods
        %% Constructor
        function obj = SkyIlluminationPredictor(varargin)
            % parse arguments
            defaultArgs = struct('NbAzimuthBins', 32, 'NbZenithBins', 5, 'AlignHistogram', 0, 'Verbose', 0);
            args = parseargs(defaultArgs, varargin{:});
            
            obj = obj@LocalIlluminationPredictor(args.Verbose, args.NbAzimuthBins, ...
                args.NbZenithBins, args.AlignHistogram);
            myfprintf(obj.verbose, 'Created sky lighting predictor.\n');
            
            % compute bin centers
            [h, i, obj.sunAzimuths] = angularHistogram([], obj.nbAzimuthBins, obj.alignHistogram);
            [h, i, obj.sunZeniths] = angularHistogram([], obj.nbZenithBins*4, 1); % zenith goes from 0 to pi/2 only
            obj.sunZeniths = obj.sunZeniths(obj.sunZeniths >= 0  & obj.sunZeniths <= pi/2);
            
            % pre-compute sky parameters
            t = 2.17; % clear sky
            obj.skyParams = getTurbidityMapping(3)*[t 1]';
        end
        
        %% Initializes the lighting classifier
        function obj = initialize(obj)
            % call the super-cass method
            obj = initialize@LocalIlluminationPredictor(obj);
            obj.data = load(fullfile(obj.classifBasePath, sprintf('%s.mat', obj.modelName)));
            
            % compute non-parametric distribution of data
            [obj.skyEdges, obj.skyCenters, obj.skyProbs] = computeDistribution(obj, obj.data.skyErrors, 50, [-0.5 0.5]);
%             [obj.nonSkyEdges, obj.nonSkyCenters, obj.nonSkyProbs] = obj.computeDistribution(obj.data.nonSkyErrors, 50, [-0.5 0.5]);
        end
        
        %% Saves the object lighting classifier
        function save(obj)
            outputFile = fullfile(obj.classifBasePath, sprintf('%s.mat', obj.modelName));
            [m,m,m] = mkdir(fileparts(outputFile));
            save(outputFile, 'obj');
        end
        
        %% Compute non-parametric distribution
        function [histEdges, histCenters, histProbs] = computeDistribution(obj, errors, nbBins, lims) 
            histEdges = linspace(lims(1), lims(2), nbBins+1);
            histCenters = linspace(lims(1), lims(2), nbBins*2+1);
            histCenters = histCenters(2:2:end);
            histProbs = histc(errors, histEdges(1:end-1));
            histProbs = histProbs./sum(histProbs);
        end
        
        %% Display distribution
        function displayDistribution(obj)
            bar(histCenters, histValues, 'hist');
            title('Luminance errors (predicted - actual)');
        end
        
        %% Predict the lighting given that the pixels belong to the sky
        function illProb = probIlluminationGivenObject(obj, up, vp, lp, vh, f)
            % call the super-cass method
            obj = probIlluminationGivenObject@LocalIlluminationPredictor(obj);
            
            % compute difference, convert to probabilities
            diffMap = computeLuminanceDifference(obj, up, vp, lp, vh, f);
            illProb = computeIlluminationProbability(obj, diffMap, obj.skyEdges, obj.skyProbs);
        end
        
        function illProb = probIlluminationGivenObjectAndK(obj, up, vp, lp, kOpt, vh, f)
            % call the super-cass method
%             obj = probIlluminationGivenObject@LocalIlluminationPredictor(obj);
            
            % compute difference, convert to probabilities
            diffMap = computeLuminanceDifferenceGivenK(obj, up, vp, lp(:,3), kOpt, vh, f);
            illProb = computeIlluminationProbability(obj, diffMap, obj.skyEdges, obj.skyProbs);
        end
        
        function illProb = probIlluminationGivenObjectAndKColor(obj, up, vp, lp, kOpt, vh, f)
            % call the super-cass method
%             obj = probIlluminationGivenObject@LocalIlluminationPredictor(obj);
            
            % compute difference, convert to probabilities
            diffMap = computeLuminanceDifferenceGivenKColor(obj, up, vp, lp, kOpt, vh, f);
            illProb = computeIlluminationProbabilityColor(obj, diffMap);
        end
        
        %% Predict the lighting given that the pixels do not belong to the sky
        function illProb = probIlluminationGivenNonObject(obj, up, vp, lp, vh, f)
            % call the super-cass method
            obj = probIlluminationGivenNonObject@LocalIlluminationPredictor(obj);
            
            % compute difference, convert to probabilities
            diffMap = computeLuminanceDifference(obj, up, vp, lp, vh, f);
            illProb = computeIlluminationProbability(obj, diffMap, obj.nonSkyEdges, obj.nonSkyProbs);
        end
        
        %% Predict lighting for a set of pixels
        function diffMap = computeLuminanceDifference(obj, up, vp, lp, vh, f)
            % up, vp, lp = [N 1];
            
            % Compute the probability for scale factors, assuming independence between color channels
            kNbBins = 55;
            kRange = linspace(0.01, 0.4, kNbBins); % compress range of k to most likely values
            kRangeRep = xrepmat(kRange, [length(up) 1]);
            
            lpRep = xrepmat(lp, [1 kNbBins]);
            upRep = xrepmat(up, [1 kNbBins]);
            vpRep = xrepmat(vp, [1 kNbBins]);
            
            diffMap = NaN.*ones(obj.nbZenithBins, obj.nbAzimuthBins, length(up), length(kRange));
                        
            a = obj.skyParams(1); b = obj.skyParams(2); c = obj.skyParams(3); d = obj.skyParams(4); e = obj.skyParams(5);
            
            % compute luminance difference at each pixel (for each value of k)
            for zeInd=1:size(diffMap,1)
                for azInd=1:size(diffMap,2)
                    lpp = exactSkyModelRatio(a, b, c, d, e, f, upRep, vpRep, vh, 1, 0, -obj.sunAzimuths(azInd), obj.sunZeniths(zeInd));
                    diffMap(zeInd, azInd, :, :) = permute(kRangeRep.*lpp - lpRep, [3 4 1 2]);
                end
            end
            
            % find k that minimizes sum of squared differences over all pixels
            % independently at each sun position
%             [m,mind] = min(sum(diffMap.^2, 3), [], 4);
            ssdMap = sum(diffMap.^2, 3);
            diffMapk = zeros(obj.nbZenithBins, obj.nbAzimuthBins, length(up));
            for r=1:size(diffMap,1)
                for c=1:size(diffMap,2)
                    % keep index that's closest to 2nd prctile ("robust min")
                    d = ssdMap(r,c,:,:) - prctile(ssdMap(r,c,:,:), 2, 4);
                    [m,mind] = min(d.^2);
                    diffMapk(r,c,:) = diffMap(r,c,:,mind);
                end
            end
            diffMap = diffMapk;
        end
        
        function diffMap = computeLuminanceDifferenceGivenK(obj, up, vp, lp, kOpt, vh, f)
            % only fit on a subset of the pixels
            [up, vp, lp] = subsamplePixels(obj, up, vp, lp);
            
            % up, vp, lp = [N 1];
            diffMap = NaN.*ones(obj.nbZenithBins, obj.nbAzimuthBins, length(up));
            a = obj.skyParams(1); b = obj.skyParams(2); c = obj.skyParams(3); d = obj.skyParams(4); e = obj.skyParams(5);
            
            % compute luminance difference at each pixel
            for zeInd=1:size(diffMap,1)
                for azInd=1:size(diffMap,2)
                    lpp = exactSkyModelRatio(a, b, c, d, e, f, up, vp, vh, 1, 0, -obj.sunAzimuths(azInd), obj.sunZeniths(zeInd));
                    diffMap(zeInd, azInd, :) = permute(kOpt(zeInd, azInd).*lpp - lp, [3 1 2]);
                end
            end
        end
        
        function diffMap = computeLuminanceDifferenceGivenKColor(obj, up, vp, lp, kOpt, vh, f)
            % only fit on a subset of the pixels
            [up, vp, lp] = subsamplePixels(obj, up, vp, lp);
            up = repmat(up, [1 3]);
            vp = repmat(vp, [1 3]);
            
            % up, vp, lp = [N 1];
            diffMap = NaN.*ones(obj.nbZenithBins, obj.nbAzimuthBins, length(up), 3);
%             a = obj.skyParams(1); b = obj.skyParams(2); c = obj.skyParams(3); d = obj.skyParams(4); e = obj.skyParams(5);
            
            % assume we're indeed fitting on clear sky
            t = 2.17;
            a = zeros(size(lp)); b = zeros(size(lp)); c = zeros(size(lp)); d = zeros(size(lp)); e = zeros(size(lp));
            for j=1:3
                coeff = getTurbidityMapping(j)*[t 1]';
                a(:,j) = coeff(1); b(:,j) = coeff(2); c(:,j) = coeff(3); d(:,j) = coeff(4); e(:,j) = coeff(5);
            end
                        
            % compute luminance difference at each pixel
            for zeInd=1:size(diffMap,1)
                for azInd=1:size(diffMap,2)
                    lpp = exactSkyModelRatio(a, b, c, d, e, f, up, vp, vh, 1, 0, -obj.sunAzimuths(azInd), obj.sunZeniths(zeInd));
                    k = repmat(permute(kOpt(zeInd, azInd, :), [1 3 2]), size(lpp,1), 1);
                    diffMap(zeInd, azInd, :, :) = permute(k.*lpp - lp, [3 4 1 2]);
                end
            end
        end

        function prob = computeIlluminationProbabilityColor(obj, diffMap)
            sigma = 10;
            probMap = squeeze(exp(-sum(diffMap.^2, 3)./(2*sigma^2)));
            probMap(isnan(diffMap)) = 0;
            
            prob = exp(sum(log(cat(3, probMap(:,:,3), prod(probMap(:,:,1:2), 3))), 3));
        end
        

        % compute illumination probability given set of sky pixel
        % differences (wrt physical model)
        function prob = computeIlluminationProbability(obj, diffMap, histEdges, histProbs)
            sigma = 4;
            prob = exp(-sum(diffMap.^2./(2*sigma^2), 3));
            prob = prob./sum(prob(:)); 
            return;
            
            % convert each difference to probability using data-driven probability distribution
            prob = zeros(size(diffMap));
            [h, histInd] = histc(diffMap(:), histEdges);
            prob(histInd>0) = histProbs(histInd(histInd>0));
            prob(histInd==0) = min(histProbs(histProbs>0)); % assign minimum probability to errors which fall outside of the training data
            
            % take product over all pixels and normalize
            probCumul = prob(:,:,1);
            for i=2:size(prob,3)
                probCumul = prod(cat(3, probCumul, prob(:,:,i)), 3);
                probCumul = probCumul./sum(probCumul(:));
            end
            
            prob = probCumul;
%             prob = exp(sum(log(prob), 3));
%             prob = prob./sum(prob(:));
        end
        
        % find optimal k at each sun relative position
        function kOpt = optimizeLuminance(obj, up, vp, lp, vh, f, channelInd)
            
            kOpt = ones(obj.nbZenithBins, obj.nbAzimuthBins);
            [up, vp, lp] = subsamplePixels(obj, up, vp, lp);
                
            % compute luminance difference at each pixel (for each value of k)
            for zeInd=1:size(kOpt,1)
                for azInd=1:size(kOpt,2)
                    kOpt(zeInd, azInd) = fitLuminance(up, vp, lp, f, vh, 0, obj.sunAzimuths(azInd), obj.sunZeniths(zeInd), channelInd);
                end
            end
        end
        
        % select subset of pixels
        function [up, vp, lp] = subsamplePixels(obj, up, vp, lp)
            % subsample up, vp, lp
            nbPixelsToKeep = min(10000, length(up));
            randInd = randperm(length(up));
            up = up(randInd(1:nbPixelsToKeep));
            vp = vp(randInd(1:nbPixelsToKeep));
            lp = lp(randInd(1:nbPixelsToKeep),:);
        end
    end
end