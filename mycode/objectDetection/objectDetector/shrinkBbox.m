function bboxShrunk = shrinkBbox(bbox, bboxExpansionFactor, bboxExpandBottom)
% Shrink bounding boxes, bbox = [x1 y1 x2 y2 ...]
% 
% ----------
% Jean-Francois Lalonde

if bboxExpandBottom
    bboxShrunk = shrinkBboxBottom(bbox);
else
    bboxShrunk = shrinkBboxHelper(bbox, bboxExpansionFactor);
end

    function bboxShrunk = shrinkBboxHelper(bbox, expansionFactor, varargin)

        % parse arguments
        defaultArgs = struct('ShrinkWidth', 1, 'ShrinkHeight', 1);
        args = parseargs(defaultArgs, varargin{:});

        bboxShrunk = bbox;

        % compute shrink factor
        shrinkFactor = expansionFactor/(1+expansionFactor);

        if args.ShrinkHeight
            % same top, height = height - factor
            bboxShrunk(:,2) = bbox(:,2);
            bboxHeight = bbox(:,4)-bbox(:,2)+1;
            bboxShrunk(:,4) = bbox(:,4) - bboxHeight.*shrinkFactor;
        end

        if args.ShrinkWidth
            % keep the bounding box centered.
            widthShrinkFactor = shrinkFactor/2;
            bboxWidth = bbox(:,3)-bbox(:,1)+1;
            bboxShrunk(:,1) = bbox(:,1) + bboxWidth.*widthShrinkFactor;
            bboxShrunk(:,3) = bbox(:,3) - bboxWidth.*widthShrinkFactor;
        end
    end

    % Shrink bounding box
    function bboxShrunk = shrinkBboxBottom(bbox)
        bboxShrunk = shrinkBboxHelper(bbox, 1.25, 'ShrinkHeight', 0);
        bboxShrunk = shrinkBboxHelper(bboxShrunk, 0.2, 'ShrinkWidth', 0);
    end
end
