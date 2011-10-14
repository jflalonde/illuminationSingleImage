%% Build type name
function typeName = buildResultsName(doSkyClassif, doHorizonLine, doVote, doWeightVote, doCueConfidence)

skyClassifType = {'', 'SkyClassif'};
horizonType = {'', 'EstimateHorizon'};
voteType = {'', 'Vote'};
weightVoteType = {'NonWeighted', 'Weighted'};
cueConfType = {'', 'CueConf'};

typeName = sprintf('%s%s%s%s', ...
        skyClassifType{doSkyClassif+1}, horizonType{doHorizonLine+1}, ...
        voteType{doVote+1}, weightVoteType{doWeightVote+1}, cueConfType{doCueConfidence+1});
