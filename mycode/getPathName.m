function path = getPathName(str, varargin)
% Returns path name for the illumination estimation project.
%
%   path = getPathName(str, varargin)
%
%   Here, 'varargin' works as in the matlab built-in 'fullfile', i.e. it
%   concatenates other strings into paths.
%
% See also:
%   fullfile
% 
% ----------
% Jean-Francois Lalonde

% use path to 'getPathName' to retrieve the base path
basePath = fileparts(fileparts(fileparts(fileparts(which('getPathName.m')))));

resultsBasePath = fullfile(basePath, 'results');
codeBasePath = fullfile(basePath, 'code');

projectName = 'illuminationSingleImage';

if nargin == 0 || isempty(str)
    fprintf('Options: ''code'', ''codeUtils'', ''results'', ''data'', ''status'', ''logs''.\n');
    if nargout == 1
        path = '';
    end
else
    
    switch(str)
        case 'code'
            path = fullfile(codeBasePath, projectName);

        case 'codeUtils'
            path = fullfile(codeBasePath, 'utils');
            
        case 'codeSkyModel'
            path = fullfile(codeBasePath, 'skyModel');
            
        case 'codeShadowDetection'
            path = fullfile(codeBasePath, 'shadowDetection');
            
        case 'codeUtilsPrivate'
            path = fullfile(codeBasePath, 'utilsPrivate');
        
        case 'results'
            path = fullfile(resultsBasePath, projectName);

        case 'data'
            path = fullfile(basePath, 'data', projectName);

        case 'status'
            path = fullfile(resultsBasePath, projectName, 'status');
            
        case 'logs'
            path = fullfile(basePath, 'logs');
            
        otherwise
            error('Invalid option');
    end

    if ~isempty(varargin)
        path = fullfile(path, varargin{:});
    end
end