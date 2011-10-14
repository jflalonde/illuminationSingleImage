%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function cueSunProb = getIlluminationMarginal(cuePredictor, pCueGivenEvidence, pSunGivenCueAndEvidence)
%  Retrieve sun marginal
% 
% Input parameters:
%
% Output parameters:
%   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cueSunProb = getIlluminationMarginal(cuePredictor, pSun, pCueGivenEvidence, pSunGivenCueAndEvidence)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isempty(pCueGivenEvidence)
    [bnet, sunNodeInd, cueInd, nbNodes] = buildCueModel(pSun, pCueGivenEvidence, pSunGivenCueAndEvidence);
    
    engine = pearl_inf_engine(bnet, 'tree');
    
    % enter (empty) evidence
    engine = enter_evidence(engine, cell(1,nbNodes));
    
    % get sun marginals
    margSun = marginal_nodes(engine, sunNodeInd);
    cueSunProb = margSun.T(:)';
    
else
    cueSunProb = cuePredictor.constantProbAz();
end
    