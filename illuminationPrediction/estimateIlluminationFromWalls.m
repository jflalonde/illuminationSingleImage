%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function estimateIlluminationFromWalls
%  
% 
% Input parameters:
%
% Output parameters:
%   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [wallsSunProb, wallsArea, allWallsSunProb] = estimateIlluminationFromWalls(img, wallPredictor, ...
    maskLeft, maskFacing, maskRight, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parse arguments
defaultArgs = struct('DoVote', 0, 'DoWeightVote', 0, 'DoCueConfidence', 0);
args = parseargs(defaultArgs, varargin{:});

wallsArea = [0 0 0];

%% Integrate cue confidence (use BNT for easy marginalization)
if args.DoCueConfidence
    % prepare probability tables
    pWallGivenEvidence = []; %zeros(3, 2); 
    pSunGivenWallAndEvidence = []; %zeros(3, wallPredictor.nbAzimuthBins, 2);
    
    masks = cat(3, maskLeft, maskFacing, maskRight);
    for i=1:3
        curWallMask = masks(:,:,i);
        curWallProb = mean(curWallMask(curWallMask>0));
        
        wallsArea(i) = nnz(curWallMask(:)>0)./numel(curWallMask(:));
        
        [wSunProb, valid] = wallPredictor.probIlluminationGivenObject(img, curWallMask, i);
        nwSunProb = wallPredictor.probIlluminationGivenNonObject(img, curWallMask);
        
        if valid
            pWallGivenEvidence = cat(1, pWallGivenEvidence, [1-curWallProb, curWallProb]);
            pSunGivenWallAndEvidence = cat(1, pSunGivenWallAndEvidence, cat(3, nwSunProb, wSunProb));
        end
    end
    
    pSun = wallPredictor.constantProbAz();
    wallsSunProb = getIlluminationMarginal(wallPredictor, pSun, pWallGivenEvidence, pSunGivenWallAndEvidence);
        
else
    %% Compute probability maps
    wallsSunProb = []; wallsProb = [];
    masks = cat(3, maskLeft, maskFacing, maskRight);
    for i=1:3
        curWallMask = masks(:,:,i);
        wallsThreshold = 0.25;
        wallsArea(i) = nnz(curWallMask(:)>wallsThreshold)./numel(curWallMask(:));
        
        [wallSunProb, valid] = wallPredictor.probIlluminationGivenObject(img, curWallMask>wallsThreshold, i);
        if valid
            wallsProb = cat(1, wallsProb, mean(curWallMask(curWallMask>wallsThreshold)));
            wallsSunProb = cat(1, wallsSunProb, wallSunProb);
        end
    end
    
    % combine walls
    if ~isempty(wallsSunProb)
        allWallsSunProb = wallsSunProb;
        if args.DoVote
            if args.DoWeightVote
                wallsSunProb = sum(wallsSunProb.*repmat(wallsProb, [1 size(wallsSunProb,2)]), 1)./sum(wallsProb);
            else
                wallsSunProb = sum(wallsSunProb, 1);
            end
        else
            wallsSunProb = prod(wallsSunProb, 1);
        end
    else
        % return constant probability map
        wallsSunProb = wallPredictor.constantProbAz();
    end
end

wallsSunProb = wallPredictor.replicateConstAzimuthProb(wallsSunProb);