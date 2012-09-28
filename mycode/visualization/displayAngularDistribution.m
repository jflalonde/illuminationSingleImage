function displayAngularDistribution(angularDist, centerAngles)

% find out how wide each "piece of pie" should be
nbBins = length(angularDist);
pieWidth = pi/nbBins;

if nargin < 2
    % find center of bins
    centerAngles = linspace(-pi, pi, 2*nbBins+1);
    centerAngles = centerAngles(1:2:end);
end

for a=1:nbBins
    displayAnglePie(centerAngles(a), pieWidth, angularDist(a), 50, 'FaceColor', 'b', 'FaceAlpha', 0.5, 'LineWidth', 1);
end
axisLim = 1.01*max(angularDist);
axis([-axisLim axisLim -axisLim axisLim]);
axis equal off;
