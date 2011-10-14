%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function angles = computeBoundaryAngles(boundaries)
%  Trains P(sun | image boundary, boundary orientation).
% 
% Input parameters:
%
% Output parameters:
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function boundaryAngles = computeBoundaryAngles(boundaries, horizonLine, focalLength, cameraHeight, u0)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% convert to lines in 3-D
boundaries3D = cellfun(@(b) convertLineImg23D(b', horizonLine, focalLength, cameraHeight, u0), boundaries, 'UniformOutput', 0);

% compute angles
boundaryAngles = cellfun(@(b) lineOrientation(b(1,:), b(3,:)), boundaries3D);
    
    function theta = lineOrientation(x, y)
        A=cat(2, x(:), y(:), ones((size(x(:)))));
        [u,s,v] = svd(A);
        
        [m,mind]=max([abs(v(1,3)), abs(v(2,3))]);
        
        theta = [atan2(1, -v(2,3)/v(1,3)), atan2(-v(1,3)/v(2,3), 1)];
        theta = theta(mind);
    end
end