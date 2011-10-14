
setPath;

wallInfo = load('~/nfs/results/illuminationSingleImage/localIlluminationPredictors/wallsPredictorRandomNonWalls.mat');
% shadowImagesPath = fullfile(shadowsResultsPath, 'trainingImages');
% shadowDbPath = fullfile(shadowsResultsPath, 'trainingDb');
outputBasePath = fullfile(basePath, 'ijcvFigs', 'sunDist');
[m,m,m] = mkdir(outputBasePath);

%%
b=mnrfit(wallInfo.wInts(:), (wallInfo.wErrors(:)<=pi/2)+1);

x = linspace(0,1,20);
y = mnrval(b, x'); 

figure;
wallLabels = wallInfo.wErrors<=pi/2;
plot(wallInfo.wInts, wallLabels, 'o', 'MarkerSize', 5);
hold on;
plot(x, y(:,2), 'k', 'LineWidth', 2);
grid on;

xlabel('b_i');
ylabel('P(\angle(\beta_i, \Delta\phi_s) < 90^\circ)');

legend('Data points', 'Logistic regression', 'Location', 'NorthWest');

set(gcf, 'Color', 'none');

export_fig(fullfile(outputBasePath, 'wallDist.pdf'), '-painters', gcf);


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
