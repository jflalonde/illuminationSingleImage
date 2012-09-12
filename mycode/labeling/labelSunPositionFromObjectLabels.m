function [sunAzimuth, horizonLine, wedgeAngle, isVisible, isValid, isGood] = ...
    labelSunPositionFromObjectLabels(figHandle, focalLength, horizonLine, ...
    imgWidth, imgHeight, objectBbox, sunAzimuth)
% function sunAzimuth = labelSunPositionFromObjectLabels(figHandle, focalLength, horizonLine, imgWidth)
%  Asks a user to estimate the relative sun position with respect to the
%  camera.
% 
% Input parameters:
%  - figHandle: handle to the figure containing the image
%  - focalLenght: camera focal length (in pixels)
%  - horizonLine: horizon line in the image (in pixels, from top of image)
%  - imgWidth: width of image (in pixels)
%
% Output parameters:
%  - sunAzimuth: azimuth of the sun (radians)



%% Default parameters
% geometric
cameraHeight = 1.6;     % meters
stickHeight = 1.7;      % meters
pos3D = [0 0 -7.5]';    % initial position, meters
sunZenith = pi/4;       % 45 degrees down from zenith
if nargin < 7
    % 90 degrees to the right
    sunAzimuth = pi/2;
end

% drawing
objectWidth = 4;
objectColor = [1 0 0];
shadowColor = [0.2 0.2 0.3];
wedgeWidth = 1;
wedgeColor = [0.2 0.2 0.8];

keyOptions = {{'w', 'Write results'}, {'o', 'Occluded sun'}, {'b', 'Bad image'}, {'q', 'Quit'}, ...
    {'leftarrow', 'Previous object'}, {'rightarrow', 'Next object'}};
displayOptions(keyOptions);

%% Prepare set of contact points
if ~isempty(objectBbox)
    contactPts = cat(2, objectBbox(:,1) + objectBbox(:,3)/2, objectBbox(:,2) + objectBbox(:,4));
    [s,sind] = sort(contactPts(:,1));
    contactPts = contactPts(sind, :);
    contactInd = ceil(size(contactPts, 1)/2); % initialize to middle object
    fprintf('%d object\n', size(contactPts, 1));
else
    contactPts = [];
    contactInd = [];
end

%% Build horizon line
hLineInfo.horizonLine = horizonLine;
hLineInfo.pt2D = [1 imgWidth; hLineInfo.horizonLine hLineInfo.horizonLine];

hLineProps = {'Color', 'r', 'LineWidth', 2, 'LineStyle', '--'};
hLineInfo.lineHandle = line(hLineInfo.pt2D(1,:), hLineInfo.pt2D(2,:), hLineProps{:});
set(hLineInfo.lineHandle, 'XData', [], 'YData', []);

%% Build shadow wedge (to capture uncertainty in estimation)
wedgeInfo.nbPts = 50;
wedgeInfo.wedgeAngle = pi/4;
wedgeInfo.radius = stickHeight.*tan(sunZenith).*0.8;
wedgeInfo.pt2D = zeros(2, 3);
wedgeProps = {'Color', wedgeColor, 'LineWidth', wedgeWidth, 'Marker', 'none'};
wedgeInfo.lineHandle = line([0 0 0], [0 0 0], wedgeProps{:});
set(wedgeInfo.lineHandle, 'XData', [], 'YData', [], 'Visible', 'off');

%% Build shadow
% compute 3-D position based on input sun azimuth
shadowInfo.pt3D = shadowFromSun(sunAzimuth, pos3D);
shadowInfo.pt2D = zeros(2,2);
shadowProps = {'Color', shadowColor, 'LineWidth', objectWidth, 'Marker', '.', 'MarkerSize', objectWidth*3};
shadowInfo.lineHandle = line([0 0 0], [0 0 0], shadowProps{:});
set(shadowInfo.lineHandle, 'XData', [], 'YData', []);

%% Build vertical pole
stickInfo.pt3D = [pos3D, pos3D + [0 stickHeight 0]'];
stickInfo.pt2D = zeros(2,2);
stickProps = {'Color', objectColor, 'LineWidth', objectWidth, 'Marker', '.', 'MarkerSize', objectWidth*3};
stickInfo.lineHandle = line([0 0 0], [0 0 0], stickProps{:});
set(stickInfo.lineHandle, 'XData', [], 'YData', []);

%% Setup callbacks

% control parameters
buttonDown = 0;
selectedObject = 3; % 1=stick, 2=shadow, 3=horizon

set(figHandle, 'WindowButtonMotionFcn', {@callbackButtonMotion, ...
    focalLength, cameraHeight, sunZenith, imgWidth, imgHeight});
set(figHandle, 'WindowButtonDownFcn', {@callbackButtonDown, ...
    focalLength, cameraHeight, sunZenith, imgWidth, imgHeight}); 
set(figHandle, 'WindowScrollWheelFcn', {@callbackMouseScroll, ...
    focalLength, cameraHeight, imgWidth, imgHeight});
set(figHandle, 'KeyPressFcn', {@callbackKeyPress});
set(figHandle, 'WindowButtonUpFcn', @callbackButtonUp);

%% Draw initial scene
updateWedge([]);
% updateObjects(contactPts(contactInd,:)', 1, focalLength, cameraHeight, sunZenith, imgWidth);
updateObjects([imgWidth/2 hLineInfo.horizonLine+(imgHeight-hLineInfo.horizonLine)/2]', 1, focalLength, cameraHeight, sunZenith, imgWidth);
drawObjects(focalLength, cameraHeight, imgWidth, imgHeight);

%% Wait for confirmation that we're done
isValid = 0; isGood = 1; isVisible = 1;

set(figHandle, 'Tag', '0');
waitfor(figHandle, 'Tag');

% the fun is over
% close(figHandle);

%% Save results
horizonLine = hLineInfo.horizonLine;
sunAzimuth = sunFromShadow(shadowInfo.pt3D);
sunAzimuth(sunAzimuth>pi) = sunAzimuth(sunAzimuth>pi)-2*pi;
sunAzimuth(sunAzimuth<-pi) = sunAzimuth(sunAzimuth<-pi)+2*pi;

wedgeAngle = wedgeInfo.wedgeAngle;

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
                    % sun is occluded
                    isValid = 1; isVisible = 0;
                    set(src, 'Tag', '1');
                    
                case 3
                    % bad image
                    isGood = 0; isValid = 1;
                    set(src, 'Tag', '1');
                    
                case 4
                    % quit without saving
                    isValid = 0;
                    set(src, 'Tag', '1');
                    
                case 5
                    % left arrow
                    if ~isempty(contactInd)
                        contactInd = mod(contactInd-2, size(contactPts, 1)) + 1;
                        updateObjects(contactPts(contactInd,:)', 1, focalLength, cameraHeight, sunZenith, imgWidth);
                        drawObjects(focalLength, cameraHeight, imgWidth, imgHeight);
                    end

                case 6
                    % right arrow
                    if ~isempty(contactInd)
                        contactInd = mod(contactInd, size(contactPts, 1)) + 1;
                        updateObjects(contactPts(contactInd,:)', 1, focalLength, cameraHeight, sunZenith, imgWidth);
                        drawObjects(focalLength, cameraHeight, imgWidth, imgHeight);
                    end
            end
            
        end
    end

    %% Mouse click callback
    function callbackButtonDown(src, eventdata, focalLength, cameraHeight, sunZenith, imgWidth, imgHeight)
        selType = get(src, 'SelectionType');
        if strcmpi(selType, 'normal') || strcmpi(selType, 'extend') % left-click or shift-click
            buttonDown = 1;
            
            px = get(get(src, 'CurrentAxes'), 'CurrentPoint');
            px = [px(1,1) px(1,2)]';
            
            % find closest object (stick, shadow, horizon line)
            selectedObject = selectObject(hLineInfo, stickInfo, shadowInfo, px);
            
            % update objects
            updateObjects(px, selectedObject, focalLength, cameraHeight, sunZenith, imgWidth);
            
            % draw objects
            drawObjects(focalLength, cameraHeight, imgWidth, imgHeight);
        end
    end

    %% Mouse release callback
    function callbackButtonUp(src, eventdata)
        buttonDown = 0;
    end
 

    %% Mouse motion callback
    function callbackButtonMotion(src, eventdata, focalLength, cameraHeight, sunZenith, imgWidth, imgHeight)
        if buttonDown
            px = get(get(src, 'CurrentAxes'), 'CurrentPoint');
            px = [px(1,1) px(1,2)]';
            
            % update objects
            updateObjects(px, selectedObject, focalLength, cameraHeight, sunZenith, imgWidth);
            
            % draw objects
            drawObjects(focalLength, cameraHeight, imgWidth, imgHeight);
        end
    end

    %% Mouse wheel callback
    function callbackMouseScroll(src, eventdata, focalLength, cameraHeight, imgWidth, imgHeight)
        % change the sun angle (in radians)
        sa = sunFromShadow(shadowInfo.pt3D);
        sa = sa + eventdata.VerticalScrollCount/20;
        shadowInfo.pt3D = shadowFromSun(sa, shadowInfo.pt3D);
        
        % change the angle (in radians!)
        wedgeInfo.wedgeAngle = min(max(wedgeInfo.wedgeAngle + eventdata.VerticalScrollCount/20, 0), pi);
        updateWedge([]);
        
        % re-draw the objects
        drawObjects(focalLength, cameraHeight, imgWidth, imgHeight);
    end

    %% Useful function: select object from mouse input
    function selectedObject = selectObject(hLineInfo, stickInfo, shadowInfo, px)
        % if we click above the horizon, then select the horizon line automatically
        if px(2) <= hLineInfo.horizonLine
            selectedObject = 3;
            return;
        end
        
        % point-to-point distance to ground contact point
        distContact = sqrt(sum((px - stickInfo.pt2D(:,1)).^2));
        
        % point-to-point distance to shadow extremity point
        distShadow = sqrt(sum((px - shadowInfo.pt2D(:,2)).^2));
        
        % point-to-line distance to horizon line
        pH1 = hLineInfo.pt2D(:,1); pH2 = hLineInfo.pt2D(:,2);
        v = [pH2(2)-pH1(2); -(pH2(1)-pH1(1))]; v = v./norm(v);
        r = pH1 - px;
        distHorizon = abs(dot(v, r));
                
        [minDist, selectedObject] = min([distContact, distShadow, distHorizon]);
        
        if minDist > 50
            % select the stick by default if we're too far from any object
            selectedObject = 1;
        end
        
    end

    %% Useful function: update objects with user input
    function updateObjects(px, selectedObject, focalLength, cameraHeight, sunZenith, imgWidth)
        
        pos3D = convertLineImg23D(px, hLineInfo.horizonLine, focalLength, cameraHeight, imgWidth/2);
        
        switch selectedObject
            case 1
                % stick contact point
                T = updateStick(pos3D);
                
                % move the shadow accordingly
                updateShadow([], T, sunZenith);
                
                % move the wedge accordingly
                updateWedge(T);
            case 2
                % rotate the shadow
                updateShadow(pos3D, [], sunZenith);
                
                % rotate the wedge
                updateWedge([]);
            case 3
                % horizon line
                hLineInfo.pt2D(2,:) = px(2);
                hLineInfo.horizonLine = px(2);
        end
    end

    %% Updates the 3-D position of the stick
    function T = updateStick(pos3D)
        % compute necessary transformation (translation)
        T = pos3D - stickInfo.pt3D(:,1);
        stickInfo.pt3D = stickInfo.pt3D + repmat(T, 1, 2);
    end

    %% Updates the 3-D position of the stick shadow
    function updateShadow(pos3D, T, sunZenith)
        % compute necessary transformation (rotation)
        if ~isempty(pos3D)
            stickHeight = stickInfo.pt3D(2,2) - stickInfo.pt3D(2,1);
            
            % compute 3-D vector between contact point and shadow point
            shadowDir = pos3D - shadowInfo.pt3D(:,1);
            shadowDir = shadowDir ./ norm(shadowDir) .* stickHeight .* tan(sunZenith);
            
            shadowInfo.pt3D(:,2) = shadowInfo.pt3D(:,1) + shadowDir;
        end
        
        % or maybe it's just a translation
        if ~isempty(T)
            shadowInfo.pt3D = shadowInfo.pt3D + repmat(T, 1, 2);
        end
    end

    %% Updates the 3-D position of the shadow wedge
    function updateWedge(T)
        % or maybe it's just a translation
        if ~isempty(T)
            wedgeInfo.pt3D = wedgeInfo.pt3D + repmat(T, 1, size(wedgeInfo.pt3D, 2));
        else
            angleRange = linspace(-wedgeInfo.wedgeAngle, wedgeInfo.wedgeAngle, wedgeInfo.nbPts);
            wedgeInfo.pt3D = cat(2, zeros(3, 1), cat(1, wedgeInfo.radius.*cos(angleRange), zeros(1, wedgeInfo.nbPts), wedgeInfo.radius.*sin(angleRange)), zeros(3,1));
            
            % compute necessary rotation
            rotAngle = atan2(shadowInfo.pt3D(3,2)-shadowInfo.pt3D(3,1), shadowInfo.pt3D(1,2)-shadowInfo.pt3D(1,1));
            R = [cos(rotAngle) 0 -sin(rotAngle); 0 1 0; sin(rotAngle) 0 cos(rotAngle)];
            
            wedgeInfo.pt3D = R*wedgeInfo.pt3D + repmat(stickInfo.pt3D(:,1), 1, size(wedgeInfo.pt3D, 2));
        end
    end

    %% Useful function: draw all objects
    function drawObjects(focalLength, cameraHeight, imgWidth, imgHeight)
        
        % shadow and stick
        drawWedge(hLineInfo.horizonLine, focalLength, cameraHeight, imgWidth);
        drawShadow(hLineInfo.horizonLine, focalLength, cameraHeight, imgWidth, imgHeight);
        drawStick(hLineInfo.horizonLine, focalLength, cameraHeight, imgWidth, imgHeight);
        
        % horizon line
        set(hLineInfo.lineHandle, 'XData', hLineInfo.pt2D(1,:), 'YData', hLineInfo.pt2D(2,:));
    end

    %% Useful function: draw the stick to the current figure
    function drawStick(horizonLine, focalLength, cameraHeight, imgWidth, imgHeight) 
        stickInfo.pt2D = convertLine3D2Img(stickInfo.pt3D, horizonLine, focalLength, cameraHeight, imgWidth/2);
        set(stickInfo.lineHandle, 'XData', stickInfo.pt2D(1,:), 'YData', stickInfo.pt2D(2,:));
        
        % vary the width as a function of depth
%         stickDepth = stickInfo.pt3D(3,1);
%         [objectWidthNew, markerWidth] = depthDependentWidth(stickDepth, objectWidth);
        [objectWidthNew, markerWidth] = heightDependentWidth(stickInfo.pt2D(2,1), horizonLine, imgHeight);
        set(stickInfo.lineHandle, 'LineWidth', objectWidthNew, 'MarkerSize', markerWidth);
    end

    %% Draw the stick shadow to the figure
    function drawShadow(horizonLine, focalLength, cameraHeight, imgWidth, imgHeight)
        shadowInfo.pt2D = convertLine3D2Img(shadowInfo.pt3D, horizonLine, focalLength, cameraHeight, imgWidth/2);
        set(shadowInfo.lineHandle, 'XData', shadowInfo.pt2D(1,:), 'YData', shadowInfo.pt2D(2,:));
        
        % vary the width as a function of depth
%         stickDepth = stickInfo.pt3D(3,1);
%         [objectWidthNew, markerWidth] = depthDependentWidth(stickDepth, objectWidth);
        [objectWidthNew, markerWidth] = heightDependentWidth(shadowInfo.pt2D(2,1), horizonLine, imgHeight);
        set(shadowInfo.lineHandle, 'LineWidth', objectWidthNew, 'MarkerSize', markerWidth);
    end

    %% Draw the shadow wedge to the figure
    function drawWedge(horizonLine, focalLength, cameraHeight, imgWidth)
        wedgeInfo.pt2D = convertLine3D2Img(wedgeInfo.pt3D, horizonLine, focalLength, cameraHeight, imgWidth/2);
        set(wedgeInfo.lineHandle, 'XData', wedgeInfo.pt2D(1,:), 'YData', wedgeInfo.pt2D(2,:));
    end

    %% Get dynamic object width that varies as a function of height in the image
    function [objectWidth, markerWidth] = heightDependentWidth(objectLine, horizonLine, imgHeight)
        maxObjectWidth = 10; 
        objectWidth = maxObjectWidth*(objectLine-horizonLine)/(imgHeight-horizonLine);
        markerWidth = 3*objectWidth;
        
        if objectWidth <= 3
            markerWidth = 1;
        elseif objectWidth == 4;
            markerWidth = 2;
        end
    end
    

    %% Get dynamic object width that varies as a function of depth
    function [objectWidth, markerWidth] = depthDependentWidth(depth, objectWidth)
        objectWidth = min(max(objectWidth .* 2*(7.5/depth), 1), 10);
        markerWidth = 3*objectWidth;
        
        if objectWidth <= 3
            markerWidth = 1;
        elseif objectWidth == 4
            markerWidth = 2;
        end
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

    %% Get shadow position from sun angle
    function pt3D = shadowFromSun(sunAzimuth, pt3D)
        sa = pi/2-sunAzimuth;
        pt3D = [pt3D(:,1), pt3D(:,1) + stickHeight.*[cos(sa+pi) 0 sin(sa+pi)]']; % shadow is in direction opposite to sun
    end

    %% Get sun angle from shadow position
    function sunAzimuth = sunFromShadow(pt3D)
        sunAzimuth = pi/2-atan2(pt3D(3,2)-pt3D(3,1), pt3D(1,2)-pt3D(1,1)) + pi;
    end
end

