%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function sunAzimuth = labelSunOcclusionForEachObject(figHandle, focalLength, horizonLine, imgWidth)
%  Asks a user to idenfity which objects are *not* lit directly by the sun.
% 
% Input parameters:
%  - figHandle: handle to the figure containing the image
%
% Output parameters:
%  - sunAzimuth: azimuth of the sun (radians)
%  
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [isVisible, isValid] = labelSunOcclusionForEachObject(figHandle, objectBbox, isVisible)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameters
if nargin < 3
    isVisible = true(size(objectBbox, 1), 1);
end

% drawing
objectWidth = 3;
visibleColor = [1 1 0.4];
occludedColor = [0 0.25 0.5];

keyOptions = {{'w', 'Write results'}, {'q', 'Quit'}, {'t', 'Toggle visibility'}};
displayOptions(keyOptions);

figure(figHandle); hold on;

%% Build bounding boxes
objectHandles = zeros(size(objectBbox, 1), 1);
for o=1:length(objectHandles)
    objectHandles(o) = rectangle('Position', objectBbox(o,:), 'EdgeColor', visibleColor, 'LineWidth', objectWidth);
end
updateObjects([]);

%% Setup callbacks
set(figHandle, 'WindowButtonDownFcn', {@callbackButtonDown, objectBbox}); 
set(figHandle, 'WindowButtonUpFcn', {@callbackButtonUp, objectBbox}); 
set(figHandle, 'KeyPressFcn', @callbackKeyPress);

%% Wait for confirmation that we're done
isValid = 0; 
visibility = 1;
downPx = [];

set(figHandle, 'Tag', '0');
waitfor(figHandle, 'Tag');

% the fun is over
% close(figHandle);

%% Save results

%% Key press callback
    function callbackKeyPress(src, eventdata)
        
        keyInd = find(strcmp(eventdata.Key, cellfun(@(x) x{1}, keyOptions, 'UniformOutput', 0)));
        if isempty(keyInd)
            % wrong option!
            fprintf('Wrong option! Try again.\n');
        else
            fprintf('You selected: %s\n', keyOptions{keyInd}{2});
            switch keyInd
                case 1
                    % quit and save the results
                    isValid = 1;
                    set(src, 'Tag', '1');
                    
                case 2
                    % quit without saving
                    isValid = 0;
                    set(src, 'Tag', '1');
                    
                case 3
                    % toggle visibility
                    visibility = ~visibility;
                    updateObjectsVisibility(visibility);
            end
        end
    end

%% Mouse click callback
    function callbackButtonDown(src, eventdata, objectBbox)
        selType = get(src, 'SelectionType');
        if strcmpi(selType, 'normal') || strcmpi(selType, 'extend') % left-click or shift-click
            % save click position
            px = get(get(src, 'CurrentAxes'), 'CurrentPoint');
            downPx = [px(1,1) px(1,2)]';
        end
    end

%% Mouse click callback
    function callbackButtonUp(src, eventdata, objectBbox)
        px = get(get(src, 'CurrentAxes'), 'CurrentPoint');
        curPx = [px(1,1) px(1,2)]';
        
        nbPts = sqrt(sum((curPx-downPx).^2));
        px = cat(1, linspace(downPx(1), curPx(1), nbPts), linspace(downPx(2), curPx(2), nbPts));
        
        % find closest object (stick, shadow, horizon line)
        selectedObjectsInd = selectObjects(px, objectBbox);
        
        % update the selected objects
        updateObjects(selectedObjectsInd);
    end

    %% Useful function: select object from mouse input
    function selectedObjectsInd = selectObjects(px, objectBbox)
        xPx = xrepmat(px(1,:), size(objectBbox, 1), 1);
        yPx = xrepmat(px(2,:), size(objectBbox, 1), 1);
        
        xBboxMin = xrepmat(objectBbox(:,1), 1, size(xPx, 2));
        yBboxMin = xrepmat(objectBbox(:,2), 1, size(xPx, 2));
        
        xBboxMax = xrepmat(objectBbox(:,1)+objectBbox(:,3), 1, size(xPx, 2));
        yBboxMax = xrepmat(objectBbox(:,2)+objectBbox(:,4), 1, size(xPx, 2));
        
        selectedObjectsInd = find(any(xPx >= xBboxMin & yPx >= yBboxMin & xPx <= xBboxMax & yPx <= yBboxMax, 2));
    end

    %% Useful function: update objects with user input
    function updateObjects(selectedObjectsInd)
        isVisible(selectedObjectsInd) = ~isVisible(selectedObjectsInd);
        
        set(objectHandles(isVisible), 'EdgeColor', visibleColor);
        set(objectHandles(~isVisible), 'EdgeColor', occludedColor);
    end

    %% Useful function: update object's visibility
    function updateObjectsVisibility(visibility)
        visibilityStr = {'off', 'on'};
        set(objectHandles, 'Visible', visibilityStr{visibility+1});
    end

    %% Display keyboard options
    function displayOptions(options)
        % Show the possible answers
        if ~isempty(options)
            fprintf('Possible options are: \n');
            for i=1:length(options)
                fprintf('\t ''%s'': %s\n', options{i}{1}, options{i}{2});
            end
        end
    end
end

