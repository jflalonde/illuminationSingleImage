% helper function for displaying individual results
function axesId = displaySingleProbMap(axesId, probSun, focalLength, camZenith, ...
    imgDims, nrowsFig, ncolsFig, titleStr)

displaySunProbabilityVectorized(probSun, 1, ...
    'DrawCameraFrame', 1, 'FocalLength', focalLength, ...
    'CamZenith', camZenith, 'ImgDims', imgDims, ...
    'Axes', subplot_tight(nrowsFig, ncolsFig, axesId));

% for some reason, 'title' messes things up, so just place the text
% directly
text(0.5, 1.1, titleStr, 'HorizontalAlignment', 'center');
axesId = axesId + 1;

