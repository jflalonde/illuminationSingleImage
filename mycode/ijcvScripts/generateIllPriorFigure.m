
%%
addpath ../;
setPath;

%%
inputPath = fullfile(singleImageResultsPath, 'illuminationPriors', 'sunPosition');
outputPath = fullfile(basePath, 'ijcvFigs', 'illPrior');
[m,m,m] = mkdir(outputPath);

%% Load data

nbTries = 1e6;
gpsAndTime = load(fullfile(inputPath, sprintf('gpsAndTimePrior-%d.mat', nbTries)));
gpsAndTimeJoint = load(fullfile(inputPath, sprintf('gpsAndTimeJoint-%d.mat', nbTries)));
gpsOnly = load(fullfile(inputPath, sprintf('gpsOnly-%d.mat', nbTries)));
gpsGlobal = load(fullfile(inputPath, sprintf('globalPrior-%d.mat', nbTries)));

%% Plot
figure(1); hold on;

zAngle = linspace(0,pi/2,15).*180/pi;
dataZenith = cat(2, sum(gpsOnly.priorSunPositionDist, 2), sum(gpsAndTime.priorSunPositionDist, 2), sum(gpsAndTimeJoint.priorSunPositionDist, 2), sum(gpsGlobal.priorSunPositionDist, 2));
dataZenith= dataZenith./repmat(sum(dataZenith, 1), size(dataZenith,1), 1);

cmap = colormap(lines(4));

plot(zAngle, dataZenith(:,4), 'LineWidth', 3, 'Color', cmap(4,:));
plot(zAngle, dataZenith(:,1), 'LineWidth', 3, 'Color', cmap(1,:));
plot(zAngle, dataZenith(:,2), 'LineWidth', 3, 'Color', cmap(2,:), 'LineStyle', '-');
plot(zAngle, dataZenith(:,3), 'LineWidth', 3, 'Color', cmap(3,:), 'LineStyle', '--');

xlabel('Sun zenith \theta_s (deg)');
ylabel('P(\theta_s)');
legend('Earth uniform', 'Latitude only P(L)', 'Marginals P(L)P(D)P(T)', 'Joint P(L,D,T)', 'Location', 'SouthEast');
% set(gca, 'FontSize', 11);


set(gcf, 'Color', 'none');
set(gca, 'Color', 'none');
set(gca, 'LineWidth', 1);
grid on;

export_fig(fullfile(outputPath, 'illPrior.pdf'), '-painters', gcf);

% saveEpsFigure(gcf, fullfile(outputPath, 'illPriorFig-withUniform.eps'));