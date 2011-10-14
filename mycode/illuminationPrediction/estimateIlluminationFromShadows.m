%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function estimateIllumination
%  
% 
% Input parameters:
%
% Output parameters:
%   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function shadowsSunProb = estimateIlluminationFromShadows(img, shadowPredictor, shadowLines, ...
    focalLength, horizonLine, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parse arguments
defaultArgs = struct('DoVote', 0, 'DoWeightVote', 0, 'DoCueConfidence', 0);
args = parseargs(defaultArgs, varargin{:});

cameraHeight = 1.6;
shadowsSunProb = [];

%% Integrate cue confidence (use BNT for easy marginalization)
if args.DoCueConfidence
    % prepare probability tables
    pShadowGivenEvidence = []; %zeros(3, 2); 
    pSunGivenShadowAndEvidence = []; %zeros(3, wallPredictor.nbAzimuthBins, 2);
    
    for i=1:size(shadowLines, 1)
        shadowAngle = computeAnglesFromShadowLines(shadowLines(i,:), focalLength, cameraHeight, horizonLine, size(img,2));
        
        sSunProb = shadowPredictor.probIlluminationGivenObject(shadowAngle);
        nsSunProb = shadowPredictor.probIlluminationGivenNonObject(shadowAngle);
        
        curShadowProb = shadowLines(i,end);
        
        pShadowGivenEvidence = cat(1, pShadowGivenEvidence, [1-curShadowProb, curShadowProb]);
        pSunGivenShadowAndEvidence = cat(1, pSunGivenShadowAndEvidence, cat(3, nsSunProb, sSunProb));
    end
    
    pSun = shadowPredictor.constantProbAz();
    shadowsSunProb = getIlluminationMarginal(shadowPredictor, pSun, pShadowGivenEvidence, pSunGivenShadowAndEvidence);
        
else
    
    %% Convert boundaries to lines
    if ~isempty(shadowLines)
        [shadowAngles, shadowLength] = computeAnglesFromShadowLines(shadowLines, focalLength, cameraHeight, horizonLine, size(img,2));
        
        %% Compute probability map
        for i=1:size(shadowLines,1)
            shadowsSunProb = cat(1, shadowsSunProb, shadowPredictor.probIlluminationGivenObject(shadowAngles(i)));
        end
        
        % each shadow boundary votes
        if args.DoVote
            if args.DoWeightVote
                shadowsSunProb = sum(shadowsSunProb.*repmat(shadowLines(:,end), [1 size(shadowsSunProb,2)]), 1)./sum(shadowLines(:,end));
            else
                shadowsSunProb = sum(shadowsSunProb, 1);
            end
        else
            shadowsSunProb = prod(shadowsSunProb, 1);
        end
        shadowsSunProb = shadowsSunProb./sum(shadowsSunProb(:));
    end
    
    if isempty(shadowsSunProb)
        shadowsSunProb = shadowPredictor.constantProbAz();
    end
end

shadowsSunProb = shadowPredictor.replicateConstAzimuthProb(shadowsSunProb);