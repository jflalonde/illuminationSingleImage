%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function probSun = combineCues()
%  Runs a detector on a set of single images
% 
% Input parameters:
%
% Output parameters:
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function probSun = combineCues(method, shadowsProbSun, wallsProbSun, pedsProbSun, skyProbSun, illPrior, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parse arguments
defaultArgs = struct('SkyParams', [], 'SkyLims', [], 'SkyVal', 0, ...
        'ShadowsParams', [], 'ShadowsLims', [], 'ShadowsVal', 0, ...
        'WallsParams', [], 'WallsLims', [], 'WallsVal', 0, ...
        'PedsParams', [], 'PedsLims', [], 'PedsVal', 0);
args = parseargs(defaultArgs, varargin{:});

if nargin < 1 || isempty(method)
    fprintf('Cue combination options are: ''mult'', ''weightedMult'', ''vote'', ''weightedVote''\n');
    probSun = [];
    return;
end

switch method
    case 'mult'
        probSun = skyProbSun .* shadowsProbSun .* wallsProbSun .* pedsProbSun .* illPrior;
        
    case 'weightedMult'
        skyWeight = computeWeight(args.SkyParams, args.SkyLims, args.SkyVal);
        shadowsWeight = computeWeight(args.ShadowsParams, args.ShadowsLims, args.ShadowsVal);
        wallsWeight = computeWeight(args.WallsParams, args.WallsLims, args.WallsVal);
        pedsWeight = computeWeight(args.PedsParams, args.PedsLims, args.PedsVal);
        
        % re-weight according to max
%         maxWeight = max([skyWeight shadowsWeight wallsWeight pedsWeight]);
%         skyWeight = double(skyWeight==maxWeight);
%         shadowsWeight = double(shadowsWeight==maxWeight);
%         wallsWeight = double(wallsWeight==maxWeight);
%         pedsWeight = double(pedsWeight==maxWeight);
        
        % 4 x 2
        pCueGivenEvidence = cat(1, skyWeight, shadowsWeight, wallsWeight, pedsWeight);
        pCueGivenEvidence = cat(2, 1-pCueGivenEvidence, pCueGivenEvidence);
        
        % 4 x ill x 2
        pSunGivenCueAndEvidence = zeros(4, numel(illPrior), 2);
        % non-object -> uniform
        pSunGivenCueAndEvidence(:, :, 1) = 1/numel(illPrior);
        % object
        pSunGivenCueAndEvidence(1, :, 2) = skyProbSun(:);
        pSunGivenCueAndEvidence(2, :, 2) = shadowsProbSun(:);
        pSunGivenCueAndEvidence(3, :, 2) = wallsProbSun(:);
        pSunGivenCueAndEvidence(4, :, 2) = pedsProbSun(:);
        
        probSun = getIlluminationMarginal([], illPrior(:), pCueGivenEvidence, pSunGivenCueAndEvidence);
        probSun = reshape(probSun, size(illPrior, 1), size(illPrior, 2));
        
    case 'vote'
        probSun = skyProbSun + shadowsProbSun + wallsProbSun + pedsProbSun;
        probSun = probSun./sum(probSun(:));
        probSun = probSun.*illPrior;
        
    case 'weightedVote'
        skyWeight = computeWeight(args.SkyParams, args.SkyLims, args.SkyVal);
        shadowsWeight = computeWeight(args.ShadowsParams, args.ShadowsLims, args.ShadowsVal);
        wallsWeight = computeWeight(args.WallsParams, args.WallsLims, args.WallsVal);
        pedsWeight = computeWeight(args.PedsParams, args.PedsLims, args.PedsVal);
        
        [skyWeight shadowsWeight wallsWeight pedsWeight];
        
        % re-weight according to max
%         maxWeight = max([skyWeight shadowsWeight wallsWeight pedsWeight]);
%         skyWeight = double(skyWeight==maxWeight);
%         shadowsWeight = double(shadowsWeight==maxWeight);
%         wallsWeight = double(wallsWeight==maxWeight);
%         pedsWeight = double(pedsWeight==maxWeight);
        
        probSun = skyProbSun*skyWeight + shadowsProbSun*shadowsWeight + ...
            wallsProbSun*wallsWeight + pedsProbSun*pedsWeight;
        probSun = probSun ./ sum(cat(2, skyWeight, shadowsWeight, wallsWeight, pedsWeight));
        
        probSun = probSun.*illPrior;            
end
% normalize
probSun = probSun./sum(probSun(:));

% useful function: compute weight for a given cue
function w = computeWeight(params, lims, val)

% clamp to 0 if feature not available
if val == 0
    w = 0;
    return;
end

% make sure val is within the training range
val = min(val, lims(2));
val = max(val, lims(1));

w = params(1) + params(2)*val;
