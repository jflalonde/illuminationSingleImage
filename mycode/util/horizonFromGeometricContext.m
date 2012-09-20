%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function horizonLine = horizonFromGeometricContext(skyMask, groundMask)
%  Estimates the horizon line from the sky and ground masks. Heuristic, but
%  works quite well in practice.
%  
% Input parameters:
%  - skyMask: 1 = sky, 0 = not sky
%  - groundMask: 1 = ground, 0 = not ground
%
% Output parameters:
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function horizonLine = horizonFromGeometricContext(skyMask, groundMask)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2010 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[rSky, cSky] = find(skyMask>0); %#ok
[rGnd, cGnd] = find(groundMask>0); %#ok

skyLoPt = prctile(rSky,99);
gndHiPt = prctile(rGnd,1);

if ~isnan(skyLoPt) && ~isnan(gndHiPt)
    % in between lowest point of sky, and highest point of ground (robustly)
    horizonLine = prctile(rSky,99) + 0.7*(prctile(rGnd,1) - prctile(rSky, 99));
elseif ~isnan(gndHiPt)
    horizonLine = gndHiPt;
elseif ~isnan(skyLoPt)
    horizonLine = skyLoPt;
else
    horizonLine = size(skyMask,1)/2;
end
