%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Example code which demonstrates the use of the sky model.
% 
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imgDims = [480 640 3]; % 640x480 color image
k = [0.2 0.2 0.05];
skyParams = convertTurbidityToSkyParams(2.2, k); % t=2.2, clear sky
vh = -100; % looking up
f = 800; % focal length in pixels
phiCam = 0; % facing north

thetaSun = pi/2-(10*pi/180); % 10 degrees to horizon

% synthesize the sky with the sun behind the camera
phiSun = pi; 
skySunBehind = reconstructSkyFromFullModel(imgDims, skyParams, vh, f, phiCam, thetaSun, phiSun);

% synthesize the sky with the sun in front of the camera
phiSun = 0;
skySunFront = reconstructSkyFromFullModel(imgDims, skyParams, vh, f, phiCam, thetaSun, phiSun);

% display results
figure;
subplot(1,2,1), imshow(xyz2rgb(xyY2xyz(skySunBehind))), title('Sun behind');
subplot(1,2,2), imshow(xyz2rgb(xyY2xyz(skySunFront))), title('Sun in front');