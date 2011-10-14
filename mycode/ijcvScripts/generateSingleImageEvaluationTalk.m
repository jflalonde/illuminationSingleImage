
function generateSingleImageEvaluationTalk


setPath;
resultsInfo = load('~/nfs/results/illuminationSingleImage/testResultsViz/SkyClassifEstimateHorizonVoteNonWeighted.mat');

outputBasePath = fullfile(basePath, 'ijcvFigs', 'quantAzimuthTalk');
[m,m,m] = mkdir(outputBasePath);

multErrors = resultsInfo.multErrors;
validWallErrors = resultsInfo.wallErrors(all(resultsInfo.wallErrors>-1, 2),:);
validShadowErrors = resultsInfo.shadowErrors(all(resultsInfo.shadowErrors>-1, 2),:);
validPedsErrors = resultsInfo.pedsErrors(all(resultsInfo.pedsErrors>-1, 2),:);
validSkyErrors = resultsInfo.skyErrors(all(resultsInfo.skyErrors>-1, 2),:);

%% Bunch of small figures?
nbBins = 100;
cmap = colormap(lines(5));
lineWidth = 8;

sH = figure; [d, sT, sL] = displayCumulError(min(validShadowErrors, [], 2), nbBins, [22.5 45], 0, 0, 'Color', cmap(1,:), 'LineWidth', lineWidth, 'LineStyle', '-', 'Marker', 'none', 'MarkerFaceColor', cmap(1,:));
axis([0 180 0 250]);

pH = figure; [d, pT, pL] = displayCumulError(validPedsErrors(:,1), nbBins, [22.5 45], 0, 0, 'Color', cmap(1,:), 'LineWidth', lineWidth, 'LineStyle', '-', 'Marker', 'none', 'MarkerFaceColor', cmap(1,:));
axis([0 180 0 250]);

wH = figure; [d, wT, wL] = displayCumulError(validWallErrors(:,1), nbBins, [22.5 45], 0, 0, 'Color', cmap(1,:), 'LineWidth', lineWidth, 'LineStyle', '-', 'Marker', 'none', 'MarkerFaceColor', cmap(1,:));
axis([0 180 0 250]);

kH = figure; [d, kT, kL] = displayCumulError(validSkyErrors(:,1), nbBins, [22.5 45], 0, 0, 'Color', cmap(1,:), 'LineWidth', lineWidth, 'LineStyle', '-', 'Marker', 'none', 'MarkerFaceColor', cmap(1,:));
axis([0 180 0 250]);

aH = figure; [d, aT, aL] = displayCumulError(multErrors(:,1), nbBins, [22.5 45], 0, 0, 'Color', cmap(1,:), 'LineWidth', lineWidth, 'LineStyle', '-', 'Marker', 'none', 'MarkerFaceColor', cmap(1,:));
axis([0 180 0 250]);

% change text color, hide vertical bars
set(sT, 'Color', 'w'); set(sL, 'Visible', 'off');
set(sH, 'Color', 'none'); set(gca(sH), 'Visible', 'off');

set(pT, 'Color', 'w'); set(pL, 'Visible', 'off');
set(pH, 'Color', 'none'); set(gca(pH), 'Visible', 'off');

set(wT, 'Color', 'w'); set(wL, 'Visible', 'off');
set(wH, 'Color', 'none'); set(gca(wH), 'Visible', 'off');

set(kT, 'Color', 'w'); set(kL, 'Visible', 'off');
set(kH, 'Color', 'none'); set(gca(kH), 'Visible', 'off');

set(aT, 'Color', 'w'); set(aL, 'Visible', 'off');
set(aH, 'Color', 'none'); set(gca(aH), 'Visible', 'off');

%% Save the axes as well
h = figure; 
axis([0 180 0 250]); grid on;

set(gca(h), 'Color', 'none', 'XColor', 'w', 'YColor', 'w', 'LineWidth', 2);
set(h, 'Color', 'none');

export_fig(fullfile(outputBasePath, 'axes.pdf'), '-painters', h);

%%
export_fig(fullfile(outputBasePath, 'quantAzimuthShadows.pdf'), '-painters', sH);
export_fig(fullfile(outputBasePath, 'quantAzimuthPeds.pdf'), '-painters', pH);
export_fig(fullfile(outputBasePath, 'quantAzimuthWalls.pdf'), '-painters', wH);
export_fig(fullfile(outputBasePath, 'quantAzimuthSky.pdf'), '-painters', kH);
export_fig(fullfile(outputBasePath, 'quantAzimuthAll.pdf'), '-painters', aH);
