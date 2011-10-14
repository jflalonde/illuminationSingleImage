function orderResultsBy

%% Setup
setPath;
typeName = 'SkyClassifEstimateHorizonVoteNonWeighted';
resultsPathName = 'testResultsViz';
outputBasePath = fullfile(basePath, 'testResultsVizSorted');
resultsInfo = load(fullfile(basePath, 'testResultsViz', sprintf('%s.mat', typeName)));

% we'd like to order the results by that type of errors:
errorTypes = {'multErrors', 'wallErrors', 'pedsErrors', 'shadowErrors', 'skyErrors'};

%%
for e=1:length(errorTypes)
    errorType = errorTypes{e};
    errors = resultsInfo.(errorType);
    
    validErrorInd = find(all(errors>-1, 2));
    [s,sind] = sort(errors(validErrorInd));
    
    outputPath = fullfile(outputBasePath, typeName, errorType);
    [m,m,m] = mkdir(outputPath);
    
    % create a bunch of symbolic links
    for i=1:length(sind)
        curInd = validErrorInd(sind(i))';
        srcPath = fullfile('..', '..', '..', resultsPathName, typeName, sprintf('%s-%s', resultsInfo.directories{curInd}, strrep(resultsInfo.files{curInd}, '.mat', '')));
        linkName = fullfile(outputPath, sprintf('%04d', i));
        cmd = sprintf('ln -s %s %s', srcPath, linkName);
        system(cmd);
    end
end