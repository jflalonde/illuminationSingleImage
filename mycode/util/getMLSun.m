function [mlZenith, mlAzimuth] = getMLSun(probSun, sunAzimuths)

[m,mind] = max(probSun(:));
[r,c] = ind2sub(size(probSun), mind);

sunZeniths = linspace(0, pi/2, size(probSun,1)*2+1);
sunZeniths = sunZeniths(2:2:end);

mlAzimuth = sunAzimuths(c);
mlZenith = sunZeniths(r);
