
function generateSingleImageEvaluation


setPath;
resultsInfo = load('~/nfs/results/illuminationSingleImage/testResultsViz/SkyClassifEstimateHorizonVoteNonWeighted.mat');

outputBasePath = fullfile(basePath, 'ijcvFigs', 'quantAzimuth');
[m,m,m] = mkdir(outputBasePath);

multErrors = resultsInfo.multErrors;
validWallErrors = resultsInfo.wallErrors(all(resultsInfo.wallErrors>-1, 2),:);
validShadowErrors = resultsInfo.shadowErrors(all(resultsInfo.shadowErrors>-1, 2),:);
validPedsErrors = resultsInfo.pedsErrors(all(resultsInfo.pedsErrors>-1, 2),:);
validSkyErrors = resultsInfo.skyErrors(all(resultsInfo.skyErrors>-1, 2),:);

%% Single figure?
figure; 
nbBins = 20;
cmap = colormap(lines(5));
lineWidth = 3;
displayCumulError(min(validShadowErrors, [], 2), nbBins, [], 0, 1, 'Color', cmap(1,:), 'LineWidth', lineWidth, 'LineStyle', '-', 'Marker', 's', 'MarkerFaceColor', cmap(1,:));
displayCumulError(validPedsErrors(:,1), nbBins, [], 0, 1, 'Color', cmap(2,:), 'LineWidth', lineWidth, 'LineStyle', '-', 'Marker', 'o');
displayCumulError(validWallErrors(:,1), nbBins, [], 0, 1, 'Color', cmap(3,:), 'LineWidth', lineWidth, 'LineStyle', '-', 'Marker', '^');
displayCumulError(validSkyErrors(:,1), nbBins, [], 0, 1, 'Color', cmap(4,:), 'LineWidth', lineWidth, 'LineStyle', '-', 'Marker', 'v');
displayCumulError(multErrors(:,1), nbBins, [], 0, 1, 'Color', cmap(5,:), 'LineWidth', lineWidth, 'LineStyle', '-', 'Marker', 'x', 'MarkerFaceColor', cmap(5,:), 'MarkerSize', 10);

plot([0 180], [0 1], 'k:', 'LineWidth', 3);

plot([22.5 22.5], [0 1], '-k', 'LineWidth', 1);
plot([45 45], [0 1], '-k', 'LineWidth', 1);

legend('Shadows only (86% of images)', 'Pedestrians only (34% of images)', 'Vertical surfaces only (99% of images)', 'Sky only (28% of images)', 'All cues (100% of images)', 'Chance', 'Location', 'SouthEast');

set(gcf, 'Color', 'none');
set(gca, 'Color', 'none');
set(gca, 'LineWidth', 1);

% export_fig(fullfile(outputBasePath, 'quantAzimuth.pdf'), '-painters', gcf);

%% Bunch of small figures?
nbBins = 100;
cmap = colormap(lines(5));
lineWidth = 3;

sH = figure; displayCumulError(min(validShadowErrors, [], 2), nbBins, [22.5 45], 1, 0, 'Color', cmap(1,:), 'LineWidth', lineWidth, 'LineStyle', '-', 'Marker', 'none', 'MarkerFaceColor', cmap(1,:));
axis([0 180 0 250]);
legend('Shadows only', 'Chance', 'Location', 'SouthEast');

pH = figure; displayCumulError(validPedsErrors(:,1), nbBins, [22.5 45], 1, 0, 'Color', cmap(1,:), 'LineWidth', lineWidth, 'LineStyle', '-', 'Marker', 'none', 'MarkerFaceColor', cmap(1,:));
axis([0 180 0 250]);
legend('Pedestrians only', 'Chance', 'Location', 'SouthEast');

wH = figure; displayCumulError(validWallErrors(:,1), nbBins, [22.5 45], 1, 0, 'Color', cmap(1,:), 'LineWidth', lineWidth, 'LineStyle', '-', 'Marker', 'none', 'MarkerFaceColor', cmap(1,:));
axis([0 180 0 250]);
legend('Vertical surfaces only', 'Chance', 'Location', 'SouthEast');

kH = figure; displayCumulError(validSkyErrors(:,1), nbBins, [22.5 45], 1, 0, 'Color', cmap(1,:), 'LineWidth', lineWidth, 'LineStyle', '-', 'Marker', 'none', 'MarkerFaceColor', cmap(1,:));
axis([0 180 0 250]);
legend('Sky only', 'Chance', 'Location', 'SouthEast');

aH = figure; displayCumulError(multErrors(:,1), nbBins, [22.5 45], 1, 0, 'Color', cmap(1,:), 'LineWidth', lineWidth, 'LineStyle', '-', 'Marker', 'none', 'MarkerFaceColor', cmap(1,:));
axis([0 180 0 250]);
legend('All cues (with prior)', 'Chance', 'Location', 'SouthEast');

set(sH, 'Color', 'none');
set(pH, 'Color', 'none');
set(wH, 'Color', 'none');
set(kH, 'Color', 'none');
set(aH, 'Color', 'none');

%%
export_fig(fullfile(outputBasePath, 'quantAzimuthShadows.pdf'), '-painters', sH);
export_fig(fullfile(outputBasePath, 'quantAzimuthPeds.pdf'), '-painters', pH);
export_fig(fullfile(outputBasePath, 'quantAzimuthWalls.pdf'), '-painters', wH);
export_fig(fullfile(outputBasePath, 'quantAzimuthSky.pdf'), '-painters', kH);
export_fig(fullfile(outputBasePath, 'quantAzimuthAll.pdf'), '-painters', aH);
