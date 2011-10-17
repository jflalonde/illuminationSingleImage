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

% get system-dependent hostname
[d, host] = system('hostname');

if isdeployed || (~isempty(strfind(lower(host), 'cmu')) && ...
        isempty(strfind(lower(host), 'jf-mac'))) || ...
        ~isempty(strfind(lower(host), 'compute'))
    
    % at CMU
    basePath = '/nfs/hn01/jlalonde';
    resultsBasePath = '/usr3/jlalonde/results';
else
    
    % on my laptop
    basePath = '/Users/jflalonde/Documents/research';   
    resultsBasePath = fullfile(basePath, 'results');
end

projectName = 'illuminationSingleImage';

if nargin == 0 || isempty(str)
    fprintf('Options: ''code'', ''codeUtils'', ''results'', ''data'', ''status'', ''logs''.\n');
    path = '';
else
    
    switch(str)
        case 'code'
            path = fullfile(basePath, 'code', 'projects', projectName);

        case 'codeUtils'
            path = fullfile(basePath, 'code', 'projects', 'utils');
        
        case 'results'
            path = fullfile(resultsBasePath, projectName);

        case 'data'
            path = fullfile(basePath, 'data', projectName);

        case 'status'
            path = fullfile(basePath, 'results', projectName, 'status');
            
        case 'logs'
            path = fullfile(basePath, 'logs');
            
        otherwise
            error('Invalid option');
    end

    if ~isempty(varargin)
        path = fullfile(path, varargin{:});
    end
end