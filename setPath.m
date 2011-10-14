%% Path setup for the single image illumination project
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear global;
global logFileRoot;

% host-dependent paths
[a, host] = system('hostname');

if isdeployed || (~isempty(strfind(lower(host), 'cmu')) && isempty(strfind(lower(host), 'jf-mac'))) || ~isempty(strfind(lower(host), 'compute'))
    % at CMU
    codeBasePath = '/nfs/hn01/jlalonde/code';
    resultsBasePath = '/nfs/hn01/jlalonde/results';
    dataBasePath = '/nfs/hn01/jlalonde/data';
    logFileRoot = '/nfs/hn01/jlalonde/status/logs';
else
    % on my laptop
    laptopBasePath = '/Users/jflalonde/Documents/phd';
    codeBasePath = fullfile(laptopBasePath, 'code');
    resultsBasePath = fullfile(laptopBasePath, 'results');
    dataBasePath = fullfile(laptopBasePath, 'data');
    logFileRoot = fullfile(laptopBasePath, 'logs');
    % this option: read-only
    % resultsBasePath = 'http://balaton.graphics.cs.cmu.edu/jlalonde/results';
    % dataBasePath= 'http://balaton.graphics.cs.cmu.edu/jlalonde/data';    
end

projectName = 'illuminationSingleImage';

webcamsResultsPath = fullfile(resultsBasePath, 'webcamSequence');
webcamsDataPath = dataBasePath;

singleImageResultsPath = fullfile(resultsBasePath, 'singleImageIllumination');
shadowsResultsPath = fullfile(resultsBasePath, 'shadowDetection');

illUnderstandingResultsPath = fullfile(resultsBasePath, 'illuminationUnderstanding');

basePath = fullfile(resultsBasePath, projectName);
dataBasePath = fullfile(dataBasePath, projectName);
statusBasePath = fullfile(resultsBasePath, projectName, 'status');

path3rdParty = fullfile(codeBasePath, 'matlab', 'trunk', '3rd_party');
pathMyCode = fullfile(codeBasePath, 'matlab', 'trunk', 'mycode/');
rootPath = fullfile(pathMyCode, projectName);

%% Turn off some annoying warnings
warning off Images:initSize:adjustingMag;

randSeed = sum(100*clock) + sum(host);
if ~isempty(strfind(version, '7.7'))
    RandStream.setDefaultStream(RandStream('mt19937ar','seed', randSeed))
else
    rand('twister', randSeed);
end

% Restore to initial state
restoredefaultpath;

%% Setup project paths
addpath(rootPath);
addpath(fullfile(rootPath, 'database'));
addpath(fullfile(rootPath, 'evaluation'));
addpath(fullfile(rootPath, 'ijcvScripts'));
addpath(fullfile(rootPath, 'illuminationContext'));
addpath(fullfile(rootPath, 'illuminationPrediction'));
addpath(fullfile(rootPath, 'localIlluminationPrediction'));
addpath(fullfile(rootPath, 'localIlluminationPrediction', 'localIlluminationPredictors'));
addpath(fullfile(rootPath, 'util'));
addpath(fullfile(rootPath, 'visualization'));

%% Setup mycode paths
addpath(fullfile(pathMyCode, 'database'));
addpath(fullfile(pathMyCode, 'database', 'commonProcessing'));
addpath(fullfile(pathMyCode, 'database', 'labelme'));
addpath(fullfile(pathMyCode, 'histogram'));
addpath(fullfile(pathMyCode, 'xml'));
addpath(fullfile(pathMyCode, 'xml', 'load_xml'));
addpath(fullfile(pathMyCode, 'html'));
addpath(fullfile(pathMyCode, 'util'));
addpath(fullfile(pathMyCode, 'util', 'webcams'));
addpath(fullfile(pathMyCode, 'imageCompositing'));

%% Setup other projects' paths

% Webcams
webcamPath = fullfile(pathMyCode, 'webcamSequence');
addpath(fullfile(webcamPath, 'util'));
addpath(fullfile(webcamPath, 'radiometricCalibration'));
addpath(fullfile(webcamPath, 'visualization', 'cameraParameters'));
addpath(fullfile(webcamPath, 'skyModeling'));
addpath(fullfile(webcamPath, 'skyModeling', 'skyModel'));
addpath(fullfile(webcamPath, 'skyModeling', 'fitting', 'turbidity'));

% Single image 
singleImagePath = fullfile(pathMyCode, 'singleImageIllumination');
addpath(fullfile(singleImagePath, 'util'));
addpath(fullfile(singleImagePath, 'singleImage'));
addpath(fullfile(singleImagePath, 'sky'));
addpath(fullfile(singleImagePath, 'scene', 'shadows'));
addpath(fullfile(singleImagePath, 'visualization'));

% Shadow detection
shadowDetectionPath = fullfile(pathMyCode, 'shadowDetection');
addpath(fullfile(shadowDetectionPath, 'util'));
addpath(fullfile(shadowDetectionPath, 'features'));
addpath(fullfile(shadowDetectionPath, 'learning')); 
addpath(fullfile(shadowDetectionPath, 'visualization'));

% Illumination understanding
illUnderstandingPath = fullfile(pathMyCode, 'illuminationUnderstanding');
addpath(fullfile(illUnderstandingPath, 'util'));
addpath(fullfile(illUnderstandingPath, 'visualization'));
addpath(fullfile(illUnderstandingPath, 'objectDetection', 'normalization'));

% Environment map
envMapPath = fullfile(pathMyCode, 'envMapping');
addpath(fullfile(envMapPath, 'imageBased'));
addpath(fullfile(envMapPath, 'conversion'));

% Util
utilPath = fullfile(pathMyCode, 'util');
addpath(utilPath);

%% Setup 3rd party paths

% Arguments parsing
addpath(fullfile(path3rdParty, 'parseArgs'));
% Progress bar
addpath(fullfile(path3rdParty, 'progressbar'));
% Color conversion
addpath(fullfile(path3rdParty, 'color'));
% Useful stuff
addpath(fullfile(path3rdParty, 'util'));
% lightspeed
addpath(fullfile(path3rdParty, 'lightspeed'));
% Poisson integration
addpath(fullfile(path3rdParty, 'poisson'));
% Filters
segPath = fullfile(path3rdParty, 'segmentationBerkeley');
addpath(segPath);
addpath(fullfile(segPath, 'Detectors'));
addpath(fullfile(segPath, 'Filters'));
addpath(fullfile(segPath, 'Gradients'));
addpath(fullfile(segPath, 'Textons'));
addpath(fullfile(segPath, 'Util'));
% Derek's occlusion boundary
addpath(fullfile(path3rdParty, 'im2boundary', 'src'));
addpath(fullfile(path3rdParty, 'im2boundary', 'src', 'andrew'));
addpath(fullfile(path3rdParty, 'im2boundary', 'src', 'bp'));
addpath(fullfile(path3rdParty, 'im2boundary', 'src', 'display'));
addpath(fullfile(path3rdParty, 'im2boundary', 'data'));
% Boosted decision trees
addpath(fullfile(path3rdParty, 'boost'));
% Piotr
% Improved Fast Gauss Transform
addpath(fullfile(path3rdParty, 'IFGT'));
% Bilateral filtering
addpath(fullfile(path3rdParty, 'bfilter2'));
% n-cuts
addpath(fullfile(path3rdParty, 'Ncut9'));
% color constancy
addpath(fullfile(path3rdParty, 'colorConstancy'));
addpath(fullfile(path3rdParty, 'colorConstancySpatFreq', 'code'));
addpath(fullfile(path3rdParty, 'colorConstancySpatFreq', 'data'));
% graph cuts
addpath(fullfile(path3rdParty, 'GCMex1.3'));
% poisson w/ dirichlet
addpath(fullfile(path3rdParty, 'poissondirichlet'));
% Piotr Dollar's matlab toolbox
pathPiotrToolbox = fullfile(path3rdParty, 'piotr_toolbox');
addpath(genpath(fullfile(pathPiotrToolbox, 'classify')));
addpath(genpath(fullfile(pathPiotrToolbox, 'filters')));
addpath(genpath(fullfile(pathPiotrToolbox, 'images')));
addpath(genpath(fullfile(pathPiotrToolbox, 'matlab')));
% matting
addpath(fullfile(path3rdParty, 'matting'));
% texture synthesis
addpath(fullfile(path3rdParty, 'quilt'));
% Sun position
addpath(fullfile(path3rdParty, 'sunPosition'));
% Object detector
% addpath(fullfile(path3rdParty, 'voc-release3.1'));
% Pascal devkit
addpath(fullfile(path3rdParty, 'VOCdevkit'));
addpath(fullfile(path3rdParty, 'VOCdevkit', 'VOCcode'));
% Labelme toolbox
addpath(fullfile(path3rdParty, 'LabelMeToolbox'));
% Labelme mechanical turk
addpath(fullfile(path3rdParty, 'LabelMeMechanicalTurk'));
% export fig
addpath(fullfile(path3rdParty, 'export_fig'));
% for SVM normalization of outputs
addpath(fullfile(path3rdParty, 'cvpr06src', 'detection'));
% for GIST
addpath(fullfile(path3rdParty, 'gist'));
% SVM
addpath(fullfile(path3rdParty, 'libsvm-mat-3.0-1'));
% Bayes net toolbox
addpath(fullfile(path3rdParty, 'FullBNT'));
addpath(genpathKPM(fullfile(path3rdParty, 'FullBNT')));

% vgg
addpath(fullfile(path3rdParty, 'vgg_matlab'));
addpath(fullfile(path3rdParty, 'vgg_matlab', 'vgg_numerics'));
addpath(fullfile(path3rdParty, 'vgg_matlab', 'vgg_general'));
addpath(fullfile(path3rdParty, 'vgg_matlab', 'vgg_image'));


%% Setup geometric context paths
appPath = fullfile(path3rdParty, 'geometricContext');
addpath(appPath);
addpath(fullfile(appPath, 'crf'));
addpath(fullfile(appPath, 'geom'));
addpath(fullfile(appPath, 'ijcv06'));
addpath(fullfile(appPath, 'mcmc'));
addpath(fullfile(appPath, 'textons'));
addpath(fullfile(appPath, 'tools', 'drawing'));
addpath(fullfile(appPath, 'tools', 'misc')); 
addpath(fullfile(appPath, 'tools', 'weightedstats'));

 