%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function buildCueModel
%  Builds the sun visibility graphical model.
%
% Input parameters:
%  - pSun: 1 x nbIllDims
%  - pCueGivenEvidence: nbCues x nbCueDims (2, true or false)
%  - pSunGivenCueAndEvidence: nbCues x nbIllDims x nbCueDims (2, true or false)
%
% Output parameters:
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [bnet, sunInd, cueInd, nbNodes] = buildCueModel(pSun, pCueGivenEvidence, pSunGivenCueAndEvidence)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% nodes indices (N cues)
% sun = 1;
% local = 2:N+1

N = size(pCueGivenEvidence, 1);

nbIllDim = size(pSunGivenCueAndEvidence, 2);
nbCueDim = size(pCueGivenEvidence, 2);

sunInd = 1;
cueInd = 2:N+1;

% count number of nodes and get node sizes
nbNodes = length(sunInd) + length(cueInd);
nodeSizes = zeros(1, nbNodes);

nodeSizes(sunInd) = nbIllDim; % sun node
nodeSizes(cueInd) = nbCueDim*nbIllDim; % cue node

% create graph
dag = zeros(nbNodes, nbNodes);

% sun to cue edges
dag(sunInd, cueInd) = 1; 

% create discrete model
bnet = mk_bnet(dag, nodeSizes, 'discrete', 1:nbNodes);

% create conditional probability tables
bnet.CPD = cell(1, nbNodes);

% sun variables
bnet.CPD{sunInd} = tabular_CPD(bnet, sunInd, 'CPT', pSun(:));

% cue nodes
for k = 1:length(cueInd)
    % compute P(cue | sun) \propto P(sun_i | cue_i, evidence_i) * P(cue_i | evidence_i)
    % cpt = nbIllDim x (nbIllDim*nbCueDim)
    
    % joint over local illumination and cue identity variables: [c1l(1:n), c2l(1:n), ...]
    cpt = zeros(nbIllDim, nbIllDim*nbCueDim);
    
    for l = 1:nbIllDim        
        for c = 1:nbCueDim
            cpt(l, (c-1)*nbIllDim+l) = pCueGivenEvidence(k, c) * pSunGivenCueAndEvidence(k, l, c);
        end
    end
    
    % cue variables
    bnet.CPD{cueInd(k)} = tabular_CPD(bnet, cueInd(k), 'CPT', cpt);
end
