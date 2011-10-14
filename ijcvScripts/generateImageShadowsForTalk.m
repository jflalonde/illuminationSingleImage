%% Setup
addpath ../;
setPath;

dbPath = fullfile(basePath, 'testDb');
imagesPath = fullfile(basePath, 'testImages');

typeName = 'SkyClassifEstimateHorizonVoteNonWeighted';
resultsPathName = 'testResultsViz';
resultsPath = fullfile(basePath, 'testResults', typeName);

outputBasePath = fullfile(basePath, 'ijcvFigs', 'imgShadows');
[m,m,m] = mkdir(outputBasePath);

%% Load input image
imgFolder = 'april21_static_outdoor_kendall';
imgFilename = 'img_1006.xml';

imgInfo = load_xml(fullfile(dbPath, imgFolder, imgFilename));
imgInfo = imgInfo.document;

geomContextInfo = load(fullfile(dbPath, imgInfo.geomContext.filename));
resultsInfo = load(fullfile(resultsPath, imgInfo.file.folder, strrep(imgInfo.file.filename, '.xml', '.mat')));
img = im2double(imread(fullfile(imagesPath, imgInfo.image.folder, imgInfo.image.filename)));

%%
figure, imshow(img), hold on;
displayBoundariesSubPixel(gcf, resultsInfo.shadowBoundaries, 'r', 5);
export_fig(fullfile(outputBasePath, 'shadowBoundaries.pdf'), '-nocrop', '-q100', '-native', '-painters', gcf);

figure, imshow(img), hold on;
plot(resultsInfo.shadowLines(:, [1 2])', resultsInfo.shadowLines(:, [3 4])', 'r', 'LineWidth', 5)
export_fig(fullfile(outputBasePath, 'shadowLines.pdf'), '-nocrop', '-q100', '-native', '-painters', gcf);

%% Show shadows on a warped top-down view
horizonLine = str2double(imgInfo.manualLabeling.horizonLine);
focalLength = str2double(imgInfo.cameraParams.focalLength);

groundMask = geomContextInfo.allGroundMask>0.5;
[r,c] = find(groundMask);

ptsOrig = [1 1 size(img,2) size(img,2); size(img,1) min(r)+100 min(r)+100 size(img,1)];
pts3D = convertLineImg23D(ptsOrig, horizonLine, focalLength, 1.6, size(img,2)/2);

ptsOrig = cat(1, ptsOrig, ones(1, size(ptsOrig, 2)));
pts3D = cat(1, pts3D([1 3],:), ones(1, size(pts3D, 2)));

H = vgg_mrdivs(ptsOrig, pts3D);

nbPx = 1000;
imgNew = zeros(nbPx, nbPx, 3);

xNew = linspace(min(pts3D(1,:), [], 2), max(pts3D(1,:), [], 2), nbPx);
yNew = linspace(max(pts3D(1,:), [], 2)*2+min(pts3D(2,:), [], 2), min(pts3D(2,:), [], 2), nbPx);

[x3DNew, y3DNew] = meshgrid(xNew, yNew);

ptImgNew = inv(H)*cat(1, x3DNew(:)', y3DNew(:)', ones(1, numel(x3DNew)));
ptImgNew = ptImgNew./repmat(ptImgNew(3,:), 3, 1);

for c=1:3
    imgNew(:,:,c) = reshape(interp2(1:size(img,2), 1:size(img,1), img(:,:,c).*groundMask, ptImgNew(1,:), ptImgNew(2,:)), nbPx, nbPx);
end

imwrite(imgNew, fullfile(outputBasePath, 'groundProj.jpg'), 'Quality', 100);
imwrite(img, fullfile(outputBasePath, 'img.jpg'), 'Quality', 100);

%% Ground mask
imgGround = img;
imgGround(repmat(groundMask, [1 1 3])==0) = 0;
imwrite(imgGround, fullfile(outputBasePath, 'ground.jpg'), 'Quality', 100);
