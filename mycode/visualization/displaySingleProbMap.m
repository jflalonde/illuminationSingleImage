% helper function for displaying individual results
function axesId = displaySingleProbMap(axesId, probSun, focalLength, camZenith, ...
    imgDims, nbAzimuthBins, alignHistogram, estZenith, nrowsFig, ncolsFig, titleStr)

if ~isempty(nbAzimuthBins)
    [~,~,sunAzimuths] = angularHistogram([], nbAzimuthBins, alignHistogram);
    [mlZenith, mlAzimuth] = getMLSun(probSun, sunAzimuths);
    
    if ~isempty(estZenith)
        mlZenith = estZenith;
    end
else
    mlZenith = []; 
    mlAzimuth = [];
end

drawFlipped = 0;
if ~isempty(strfind(lower(titleStr), 'shadow'))
    drawFlipped = 1;
end

displaySunProbabilityVectorized(probSun, 1, ...
    'DrawCameraFrame', 1, 'FocalLength', focalLength, ...
    'CamZenith', camZenith, 'ImgDims', imgDims, ...
    'Axes', subplot_tight(nrowsFig, ncolsFig, axesId), ...
    'EstSunZenith', mlZenith, 'EstSunAzimuth', mlAzimuth, ...
    'DrawFlipped', drawFlipped);

% for some reason, 'title' messes things up, so just place the text
% directly
text(0.5, 1.1, titleStr, 'HorizontalAlignment', 'center');
axesId = axesId + 1;

