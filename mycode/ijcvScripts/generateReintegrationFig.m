%% Setup
addpath ../;
setPath;

dbPath = fullfile(basePath, 'testDb');
imagesPath = fullfile(basePath, 'testImages');

typeName = 'SkyClassifEstimateHorizonVoteNonWeighted';
resultsPathName = 'testResultsViz';
resultsPath = fullfile(basePath, 'testResults', typeName);

outputBasePath = fullfile(basePath, 'ijcvFigs', 'imgReintegration');

%% Load input image
% imgFolder = 'static_outdoor_street_city_cambridge_uk';
% imgFilename = 'IMG_8716.xml';

imgFolder = 'static_street_cambridge';
imgFilename = 'p1010670.xml';

imgInfo = load_xml(fullfile(dbPath, imgFolder, imgFilename));
imgInfo = imgInfo.document;

geomContextInfo = load(fullfile(dbPath, imgInfo.geomContext.filename));
resultsInfo = load(fullfile(resultsPath, imgInfo.file.folder, strrep(imgInfo.file.filename, '.xml', '.mat')));
img = imread(fullfile(imagesPath, imgInfo.image.folder, imgInfo.image.filename));

groundMask = cat(3, geomContextInfo.allGroundMask, geomContextInfo.allSkyMask, geomContextInfo.allWallsMask);
[m,groundMask] = max(groundMask, [], 3); groundMask = groundMask == 1;

%% Load shadow information
segInfo = load(fullfile(dbPath, imgInfo.wseg25.filename));
shadowInfo = load(fullfile(dbPath, imgInfo.shadows.filename));

%%
boundariesPxInd = convertBoundariesToPxInd(resultsInfo.shadowBoundaries, size(img));

% compute gradients
gx = zeros(size(img, 1), size(img, 2));
gy = zeros(size(img, 1), size(img, 2));

[gxT, gyT] = calculate_gradients(rgb2gray(img), 0, 0);

% remove gradients which don't belong to shadows
gx(boundariesPxInd) = gxT(boundariesPxInd);
gy(boundariesPxInd) = gyT(boundariesPxInd);

% all gradients have the same magnitude
gMag = sqrt(gx.^2+gy.^2);
gx(boundariesPxInd) = gx(boundariesPxInd)./gMag(boundariesPxInd); 
gy(boundariesPxInd) = gy(boundariesPxInd)./gMag(boundariesPxInd);

gx(isnan(gx)) = 0;
gy(isnan(gy)) = 0;

imgShadows = poisson_solver_function_neumann(gx, gy);
imgShadows = imgShadows./max(imgShadows(:));
figure(1), imshow(img);
figure(2), imshow(imgShadows), colorbar;
figure(3), imshow((imgShadows.*groundMask)); 
figure(4), imshow(groundMask);

%% Save
[m,m,m] = mkdir(outputBasePath);
imwrite(img, fullfile(outputBasePath, 'img.jpg'), 'Quality', 100);
imwrite(imgShadows, fullfile(outputBasePath, 'imgShadows.jpg'), 'Quality', 100);
imwrite(imgShadows.*groundMask, fullfile(outputBasePath, 'imgShadowGround.jpg'), 'Quality', 100);
imwrite((imgShadows.*groundMask)>0, fullfile(outputBasePath, 'imgShadowGroundThresh.jpg'), 'Quality', 100);
imwrite(groundMask, fullfile(outputBasePath, 'ground.jpg'), 'Quality', 100); 

imshow(img), displayBoundariesSubPixel(gcf, resultsInfo.shadowBoundaries, 'r', 5);
export_fig(gcf, fullfile(outputBasePath, 'imgWithShadows.jpg'), '-native', '-painters');
