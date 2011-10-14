function imgResult = displayMaskOverlay(img, mask, maskColor, maskAlpha)

imgMask = repmat(permute(maskColor(:), [3 2 1]), [size(img,1) size(img,2)]);
imgMask = imgMask.*repmat(mask, [1 1 3]);

imgComb = maskAlpha*img + (1-maskAlpha)*imgMask;
imgResult = img;
imgResult(repmat(mask, [1 1 3])) = imgComb(repmat(mask, [1 1 3]));
