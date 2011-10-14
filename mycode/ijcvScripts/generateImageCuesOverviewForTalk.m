%% Setup
addpath ../;
setPath;

dbPath = fullfile(basePath, 'testDb');
imagesPath = fullfile(basePath, 'testImages');

outputBasePath = fullfile(basePath, 'ijcvFigs', 'imgCues');

%% Load input image
imgFolder = 'static_outdoor_street_city_cambridge_uk';
imgFilename = 'IMG_8966.xml';

imgInfo = load_xml(fullfile(dbPath, imgFolder, imgFilename));
imgInfo = imgInfo.document;

geomContextInfo = load(fullfile(dbPath, imgInfo.geomContext.filename));
img = imread(fullfile(imagesPath, imgInfo.image.folder, imgInfo.image.filename));

%% Generate images for sky, ground, vertical surfaces
imgGround = img;
imgGround(repmat(geomContextInfo.allGroundMask, [1 1 3])<0.5) = 0;

imgSky = img;
imgSky(repmat(geomContextInfo.allSkyMask, [1 1 3])<0.5) = 0;

imgVert = img;
imgVert(repmat(geomContextInfo.wallFacing+geomContextInfo.wallRight+geomContextInfo.wallLeft, [1 1 3])==0) = 0;

%% Save
[m,m,m] = mkdir(outputBasePath);
imwrite(img, fullfile(outputBasePath, 'img.jpg'), 'Quality', 100);
imwrite(imgGround, fullfile(outputBasePath, 'ground.jpg'), 'Quality', 100);
imwrite(imgSky, fullfile(outputBasePath, 'sky.jpg'), 'Quality', 100);
imwrite(imgVert, fullfile(outputBasePath, 'vert.jpg'), 'Quality', 100); 

%% Save boundaries
segInfo = load(fullfile(dbPath, imgInfo.wseg25.filename));
shadowsInfo = load(fullfile(dbPath, imgInfo.shadows.filename));

figure; 
displayBoundariesSubPixel(gcf, segInfo.boundaries(shadowsInfo.indStrongBnd), 'r', 5);
axis ij image off;
set(gca, 'Color', 'none'); 
set(gcf, 'Color', 'none');

export_fig(fullfile(outputBasePath, 'boundaries.png'), '-native');