%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function M = getTurbidityMapping(channelId)
%  Returns the turbidity mapping between turbidity and the constants
%  (a,b,c,d,e) from the Perez sky model. Taken from [Preetham et al., SIGGRAPH '99].
% 
% Input parameters:
%  - channelId: [1,3] channel in the xyY space
%
% Output parameters:
%  - M: turbidity mapping. [a b c d e] = M*[T 1]'
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function M = getTurbidityMapping(channelId)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2006-2009 Jean-Francois Lalonde
% Carnegie Mellon University
% Do not distribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch channelId
    case 1 % x
        M = [-0.0193 -0.2592; -0.0665 0.0008; -0.0004 0.2125; -0.0641 -0.8989; -0.0033 0.0452];
        
    case 2 % y     
        M = [-0.0167 -0.2608; -0.0950 0.0092; -0.0079 0.2102; -0.0441 -1.6537; -0.0109 0.0529];
        
    case 3 % Y
        M = [0.1787 -1.4630; -0.3554 0.4275; -0.0227 5.3251; 0.1206 -2.5771; -0.0670 0.3703];
        
    otherwise
        error('input channelID must be between 1 and 3!');
end