function [pctImages, tH, lH] = displayCumulError(errors, nbBins, degErrors, dispRand, normalize, varargin)

if nargin < 4
    dispRand = 1;
end

if nargin < 5
    normalize = 0;
end

angleEdges = linspace(0, 180, nbBins);
angleCenters = linspace(0, 180, nbBins*2+1);
angleCenters = angleCenters(2:2:end);

hE = histc(errors*180/pi, angleEdges);
chE = cumsum(hE); 
if normalize 
    chE = chE./max(chE(:));
end


hold on;
plot(angleCenters, chE, varargin{:});

if dispRand
    plot([0 180], [0 max(chE(:))], 'k:', 'LineWidth', 3);
end

% plot vertical lines at degErrors
tH = zeros(1, length(degErrors)); lH = zeros(1, length(degErrors));
for d=1:length(degErrors)
    degErrVal = interp1(angleCenters, chE, degErrors(d));
    tH(d) = text(degErrors(d)-2, degErrVal+0.05/max(chE(:)), sprintf('%.1f%%', degErrVal/max(chE(:))*100), 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom');
	plot(degErrors(d), degErrVal, 's', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
    lH(d) = plot([degErrors(d) degErrors(d)], [0 1000], '-k', 'LineWidth', 1);
end

grid on;
axis([0 180 0 max(chE(:))]);

if normalize
    ylabel('% of images');
else
    ylabel('Number of images');
end

xlabel('Error (deg)');
set(gca, 'LineWidth', 1);

% return fraction of images have less than % error
pctImages = [];
for d=1:length(degErrors)
    pctImages = cat(2, pctImages, interp1(angleCenters, chE, degErrors(d)));
end