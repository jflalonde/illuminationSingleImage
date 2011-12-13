function prob = normalizeConfidences(modelInfo, confidences, componentId)
% Normalizes the confidence based on pre-computed sigmoid parameters
%
% ----------
% Jean-Francois Lalonde

if nargin < 3
    componentId = 0;
end

if componentId == 0
    if ~isfield(modelInfo.model, 'A')
        error('Model hasn''t been normalized yet!');
    end

    % recover parameters, and normalize detector outputs
    A = modelInfo.model.A;
    B = modelInfo.model.B;
else
    if ~isfield(modelInfo.indepComponentModel.model(componentId), 'A')
        error('Component %d hasn''t been normalized yet!', componentId);
    end

    % recover parameters, and normalize detector outputs
    A = modelInfo.indepComponentModel.model(componentId).A;
    B = modelInfo.indepComponentModel.model(componentId).B;
end

prob = logisticProb([A B], confidences);

