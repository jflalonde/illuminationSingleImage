%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function estimateIlluminationFromPedestrians
%
%
% Input parameters:
%
% Output parameters:
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [pedsSunProb, nbObjects, allPedsSunProb] = estimateIlluminationFromPedestrians(img, pedPredictor, ...
    pObj, pLocalVisibility, pLocalLightingGivenObjects, pLocalLightingGivenNonObjects, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parse arguments
defaultArgs = struct('DoVote', 0, 'DoWeightVote', 0, 'DoCueConfidence', 0);
args = parseargs(defaultArgs, varargin{:});

nbObjects = 0;

%% Integrate cue confidence (use BNT for easy marginalization)
if args.DoCueConfidence
    % prepare probability tables
    pPedGivenEvidence = []; %zeros(3, 2);
    pSunGivenPedAndEvidence = []; %zeros(3, wallPredictor.nbAzimuthBins, 2);
    
    if ~isempty(pObj)
        objInd = find(pObj(:,2) >= 0.5 & pLocalVisibility(:,2) >= 0.5);
        nbObjects = length(objInd);
        
        for i=objInd(:)'
            pSunProb = pedPredictor.probIlluminationGivenObject(pLocalLightingGivenObjects(i,:));
            npSunProb = pedPredictor.probIlluminationGivenNonObject(pLocalLightingGivenNonObjects(i,:));
            
            pPedGivenEvidence = cat(1, pPedGivenEvidence, pObj(i,:));
            pSunGivenPedAndEvidence = cat(1, pSunGivenPedAndEvidence, cat(3, npSunProb, pSunProb));
        end
        
        pSun = pedPredictor.constantProbAz();
        pedsSunProb = getIlluminationMarginal(pedPredictor, pSun, pPedGivenEvidence, pSunGivenPedAndEvidence);
    
    else
        pedsSunProb = pedPredictor.constantProbAz();
    end
    
else
    
    pedsSunProb = [];
    
    if ~isempty(pObj)
        objInd = find(pObj(:,2) >= 0.5 & pLocalVisibility(:,2) >= 0.5);
        nbObjects = length(objInd);
        for i=objInd(:)'
            pedSunProb = pedPredictor.probIlluminationGivenObject(pLocalLightingGivenObjects(i,:));
            pedsSunProb = cat(1, pedsSunProb, pedSunProb);
        end
    end
    
    % combine
    if ~isempty(pedsSunProb)
        allPedsSunProb = pedsSunProb;
        if args.DoVote
            if args.DoWeightVote
                pedsSunProb = sum(pedsSunProb.*repmat(pObj(objInd,2), [1 size(pedsSunProb,2)]), 1)./sum(pObj(objInd,2));
            else
                pedsSunProb = sum(pedsSunProb, 1);
            end
        else
            pedsSunProb = prod(pedsSunProb, 1);
        end
    else
        pedsSunProb = pedPredictor.constantProbAz();
    end
end

pedsSunProb = pedPredictor.replicateConstAzimuthProb(pedsSunProb);