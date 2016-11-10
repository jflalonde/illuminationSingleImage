%% Path setup for the webcam sequence project
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2007 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear global;
global logFileRoot;

% host-dependent paths
[a, host] = system('hostname');

if (isdeployed || ~isempty(strfind(lower(host), 'cmu')) || ~isempty(strfind(lower(host), 'compute'))) && isempty(strfind(lower(host), 'jf-mac'))
    % at CMU
    codeBasePath = '/nfs/hn01/jlalonde/code';
    basePath = '/nfs/hn25/jlalonde/results/webcamSequence';
    dataBasePath = '/nfs/hn01/jlalonde/data';
    logFileRoot = '/nfs/hn01/jlalonde/status/logs';
else
    % on my laptop
    codeBasePath = '/Users/jflalonde/Documents/phd/code';
    basePath = '/Users/jflalonde/Documents/phd/results/webcamSequence';
    dataBasePath = '/Users/jflalonde/Documents/phd/data';
    logFileRoot = '/Users/jflalonde/Documents/phd/data/logs';
end

statusBasePath = '/nfs/hn01/jlalonde/status/siggraphAsia09';

path3rdParty = fullfile(codeBasePath, 'matlab/trunk/3rd_party');
pathMyCode = fullfile(codeBasePath, 'matlab/trunk/mycode/');
rootPath = fullfile(pathMyCode, 'webcamSequence');

%% Turn off some annoying warnings
warning off Images:initSize:adjustingMag;

%% Initialize the random number generator (otherwise initialized to the same value each time!)
randSeed = sum(100*clock) + sum(host);
if ~isempty(strfind(version, '7.7'))
    RandStream.setDefaultStream(RandStream('mt19937ar','seed', randSeed))
else
    rand('twister', randSeed);
end
     
if isdeployed
    return;
end

% Restore to initial state
restoredefaultpath;

%% Setup mycode paths
addpath(fullfile(pathMyCode, 'database'));
addpath(fullfile(pathMyCode, 'database', 'commonProcessing'));
addpath(fullfile(pathMyCode, 'histogram'));
addpath(fullfile(pathMyCode, 'xml'));
addpath(fullfile(pathMyCode, 'xml', 'load_xml'));
addpath(fullfile(pathMyCode, 'html'));

%% Setup util paths
utilPath = fullfile(pathMyCode, 'util');
addpath(utilPath);
addpath(fullfile(utilPath, 'rendering'));
addpath(fullfile(utilPath, 'labelme'));
addpath(fullfile(utilPath, 'webcams'));

%% Setup project paths
addpath(rootPath);
addpath(fullfile(rootPath, 'datasetCreation'));
addpath(fullfile(rootPath, 'datasetSummary')); 
addpath(fullfile(rootPath, 'datasetProcessing'));
addpath(fullfile(rootPath, 'datasetManagement'));
addpath(fullfile(rootPath, 'visualization'));
addpath(fullfile(rootPath, 'visualization', 'cameraParameters'));
addpath(fullfile(rootPath, 'pca'));
addpath(fullfile(rootPath, 'pca', 'canonicalDay'));
addpath(fullfile(rootPath, 'illuminationContext'));
addpath(fullfile(rootPath, 'learning'));
addpath(fullfile(rootPath, 'sequenceAlignment'));
addpath(fullfile(rootPath, 'skyLabeling'));
addpath(fullfile(rootPath, 'skyModeling'));
addpath(fullfile(rootPath, 'skyModeling', 'fitting'));
addpath(fullfile(rootPath, 'skyModeling', 'fitting', 'luminance'));
addpath(fullfile(rootPath, 'skyModeling', 'fitting', 'turbidity'));
addpath(fullfile(rootPath, 'skyModeling', 'matching'));
addpath(fullfile(rootPath, 'skyModeling', 'matchingTimeOfDay'));
addpath(fullfile(rootPath, 'skyModeling', 'globalModel'));
addpath(fullfile(rootPath, 'skyModeling', 'fullModel'));
addpath(fullfile(rootPath, 'skyModeling', 'fullModel', 'fitting'));
addpath(fullfile(rootPath, 'skyModeling', 'fullModel', 'matching'));
addpath(fullfile(rootPath, 'skyModeling', 'fullModel', 'syntheticValidation'));
addpath(fullfile(rootPath, 'skyModeling', 'fullModel', 'visualization'));
addpath(fullfile(rootPath, 'skyModeling', 'skyModel'));
addpath(fullfile(rootPath, 'radiometricCalibration'));
addpath(fullfile(rootPath, 'radiometricCalibration', 'wildValidation'));
addpath(fullfile(rootPath, 'cameraParameters'));
addpath(fullfile(rootPath, 'cameraParameters', 'allParams'));
addpath(fullfile(rootPath, 'skyCalibration'));
addpath(fullfile(rootPath, 'groundTruth'));
addpath(fullfile(rootPath, 'transformations'));
addpath(fullfile(rootPath, 'transformations', 'singleImage'));
addpath(fullfile(rootPath, 'util'));
addpath(fullfile(rootPath, 'webcamClipart'));
addpath(fullfile(rootPath, 'webcamRelighting'));
addpath(fullfile(rootPath, 'siggraphScripts', 'danielle'));
addpath(fullfile(rootPath, 'gpsCoordinates'));


%% Setup 3rd party paths
% vgg
addpath(fullfile(path3rdParty, 'vgg_matlab'));
addpath(fullfile(path3rdParty, 'vgg_matlab', 'vgg_numerics'));
addpath(fullfile(path3rdParty, 'vgg_matlab', 'vgg_general'));
addpath(fullfile(path3rdParty, 'vgg_matlab', 'vgg_image'));
% Arguments parsing
addpath(fullfile(path3rdParty, 'parseArgs'));
% Color conversion
addpath(fullfile(path3rdParty, 'color'));
% Lightspeed
addpath(fullfile(path3rdParty, 'lightspeed'));
% Useful stuff
addpath(fullfile(path3rdParty, 'util'));
% SIFT
addpath(fullfile(path3rdParty, 'sift'));
% Isomap
addpath(fullfile(path3rdParty, 'isomap'));
% Click 3-D points
addpath(fullfile(path3rdParty, 'click3DPoint'));
% Better dijkstra (with paths)
addpath(fullfile(path3rdParty, 'dijkstra'));
% Sun position
addpath(fullfile(path3rdParty, 'sunPosition'));
% Intrinsic images
addpath(fullfile(path3rdParty, 'intrinsicSequence'));
% Poisson solver
addpath(fullfile(path3rdParty, 'poisson'));
% Berkeley code
addpath(fullfile(path3rdParty, 'segmentationBerkeley', 'lib', 'matlab'));
% Texture synthesis
addpath(fullfile(path3rdParty, 'quilt'));
% for GMM
addpath(fullfile(path3rdParty, 'netlab'));
% for simulated annealing
addpath(fullfile(path3rdParty, 'anneal'));
% emd
addpath(fullfile(path3rdParty, 'emd'));
% mapping 
addpath(fullfile(path3rdParty, 'mmap'));
% progress bar
addpath(fullfile(path3rdParty, 'progressbar'));
% Peter Kovesi's functions
addpath(fullfile(path3rdParty, 'pkovesi'));
addpath(fullfile(path3rdParty, 'pkovesi', 'Robust'));
addpath(fullfile(path3rdParty, 'pkovesi', 'Projective'));
% Anat Levin's matting
addpath(fullfile(path3rdParty, 'matting'));
% O. Chapelle's svm code
addpath(fullfile(path3rdParty, 'primal_svm'));
% Anti-aliasing
addpath(fullfile(path3rdParty, 'myaa'));
% Laplacian pyramid code
addpath(fullfile(path3rdParty, 'pyramidMatching'));
addpath(fullfile(path3rdParty, 'pyramidMatching', 'MEX'));
% incremental SVD
addpath(fullfile(path3rdParty, 'svdUpdate'));
% sunrise/sunset
addpath(fullfile(path3rdParty, 'sunrise'));



%% Setup geometric context paths
appPath = fullfile(path3rdParty, 'geometricContext');
addpath(appPath);
addpath(fullfile(appPath, 'boosting'));
addpath(fullfile(appPath, 'crf'));
addpath(fullfile(appPath, 'geom'));
addpath(fullfile(appPath, 'ijcv06'));
addpath(fullfile(appPath, 'mcmc'));
addpath(fullfile(appPath, 'textons'));
addpath(fullfile(appPath, 'tools', 'drawing'));
addpath(fullfile(appPath, 'tools', 'misc')); 
addpath(fullfile(appPath, 'tools', 'weightedstats'));