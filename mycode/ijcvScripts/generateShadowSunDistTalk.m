
setPath;

shadowInfo = load('~/nfs/results/illuminationSingleImage/localIlluminationPredictors/shadowPredictorGtGroundMask74-nobad.mat');
shadowImagesPath = fullfile(shadowsResultsPath, 'trainingImages');
shadowDbPath = fullfile(shadowsResultsPath, 'trainingDb');
outputBasePath = fullfile(basePath, 'ijcvFigs', 'sunDistTalk');
[m,m,m] = mkdir(outputBasePath);

%%
nbBins = 18;
histEdges = linspace(0, pi/2, nbBins+1);
histCenters = linspace(0,pi/2,2*nbBins+1);
histCenters = histCenters(2:2:end);
h = histc(shadowInfo.sErrors, histEdges);
h = h(1:end-1);
h = h./sum(h(:));

figure;
plot(histCenters*180/pi, h, 'b', 'LineWidth', 6);
grid on;

% xlabel('min \{ \angle(\alpha_i,\Delta \phi_s), \angle(\alpha_i+\pi,\Delta \phi_s) \} (degrees)');
% ylabel('P(\Delta\phi_s)');
axis([0 90 0 0.2]);

set(gcf, 'Color', 'none');
set(gca, 'Color', 'none');
set(gca, 'XColor', 'w', 'YColor', 'w', 'LineWidth', 1);

[m,m,m] = mkdir(outputBasePath);
export_fig(fullfile(outputBasePath, 'shadowDist.pdf'), '-painters', gcf);

%% Example images
% top walls: 3/74
shadowDb = loadDatabaseFast(shadowDbPath, '', '', 0, 'Loading shadow dataset');

%%
imgInd = 10;
imgInfo = shadowDb(shadowInfo.labeledImgInd(imgInd)); imgInfo = imgInfo.document;
img = imread(fullfile(shadowImagesPath, imgInfo.image.folder, imgInfo.image.filename));

horizonLine = str2double(imgInfo.cameraParams.horizonLine);
sunAzimuth = str2double(imgInfo.manualLabeling.sunAzimuth);

if isfield(imgInfo.cameraParams, 'focalLength')
    focalLength = str2double(imgInfo.cameraParams.focalLength);
else
    focalLength = str2double(imgInfo.image.size.width)*10/7;
end

% insert sun dial
drawSunDialFromSunPosition(img, [pi/4, sunAzimuth], horizonLine, focalLength);
export_fig(fullfile(outputBasePath, 'shadowDialPpl.pdf'), '-painters', '-native', '-q100', gcf);


% shadows: 10/74
