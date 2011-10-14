%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function doLoadWebcamSkyData
%  Prepare data for training the sky illumination predictor.
% 
% Input parameters:
%
% Output parameters:
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function doLoadWebcamSkyData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Initialization
setPath; 

webcamsDbPath = fullfile(webcamsResultsPath, 'subSequenceDbHD');
skyMaskPath = fullfile(webcamsResultsPath, 'skyMasks');
webcamsImagesPath = fullfile(webcamsDataPath, 'webcamsHD');
outputBasePath = fullfile(basePath, 'localIlluminationPredictors');

doSave = 1;

%% Load the webcam dataset
sequenceNames = {'Berkeley', 'Estes', 'Arizona', 'Arnige', 'Portugal', 'Tokyo', 'Sundsvall', 'Vatican', 'Visby', 'Jericho'};

dbFn = @dbFnLoadWebcamSkyData;
parallelized = 0;
randomized = 0;
global imgPaths imgSunZeniths imgSunAzimuths imgSkyMaskPaths imgFocalLengths imgHorizonLines imgCamZeniths imgCamAzimuths;
processResultsDatabaseFast(webcamsDbPath, sequenceNames, '', outputBasePath, dbFn, ...
    parallelized, randomized, 'ImagesPath', webcamsImagesPath, 'DbPath', webcamsDbPath, ...
    'SkyMaskPath', skyMaskPath);

%% Save information
if doSave
    outputFile = fullfile(outputBasePath, 'skyWebcamData.mat');
    [m,m,m] = mkdir(fileparts(outputFile));
    save(outputFile, 'imgPaths', 'imgSunZeniths', 'imgSunAzimuths', 'imgSkyMaskPaths', ...
        'imgFocalLengths', 'imgHorizonLines', 'imgCamZeniths', 'imgCamAzimuths');
end

function r=dbFnLoadWebcamSkyData(outputBasePath, seqInfo, varargin)
r=0;
global imgPaths imgSunZeniths imgSunAzimuths imgSkyMaskPaths imgFocalLengths imgHorizonLines imgCamZeniths imgCamAzimuths;

% parse arguments
defaultArgs = struct('ImagesPath', [], 'DbPath', [], 'SkyMaskPath', []);
args = parseargs(defaultArgs, varargin{:});

% load data
seqData = loadSequenceData(seqInfo, args.DbPath, 'ClearDays', 1, 'Sun', 1, 'Files', 1, 'Dates', 1, ...
    'CameraParameters', 1);

% we need a list of images where the sky is clear, and their corresponding sun orientations
dates = seqData.years*10000 + seqData.months*100 + seqData.days;
indDay = arrayfun(@(x) find(dates == x), seqData.clearDays, 'UniformOutput', 0);
indDay = cat(2, indDay{:});

curImgPaths = cellfun(@(f) fullfile(args.ImagesPath, seqInfo.sequence.name, f), seqData.seqFiles(indDay), 'UniformOutput', 0);
curImgSunZeniths = seqData.sunZenith(indDay);
curImgSunAzimuths = seqData.sunAzimuth(indDay);
curImgSkyMaskPaths = repmat({fullfile(args.SkyMaskPath, seqInfo.sequence.name, 'mask.jpg')}, size(curImgSunZeniths));
curImgFocalLengths = repmat(seqData.focalLength, size(curImgSunZeniths));
curImgHorizonLines = repmat(seqData.horizonLine, size(curImgSunZeniths));
curImgCamZeniths = repmat(seqData.camZenith, size(curImgSunZeniths));
curImgCamAzimuths = repmat(seqData.camAzimuth, size(curImgSunZeniths));

imgPaths = cat(2, imgPaths, curImgPaths);
imgSunZeniths = cat(2, imgSunZeniths, curImgSunZeniths);
imgSunAzimuths = cat(2, imgSunAzimuths, curImgSunAzimuths);
imgSkyMaskPaths = cat(2, imgSkyMaskPaths, curImgSkyMaskPaths);
imgFocalLengths = cat(2, imgFocalLengths, curImgFocalLengths);
imgHorizonLines = cat(2, imgHorizonLines, curImgHorizonLines);
imgCamZeniths = cat(2, imgCamZeniths, curImgCamZeniths);
imgCamAzimuths = cat(2, imgCamAzimuths, curImgCamAzimuths);
