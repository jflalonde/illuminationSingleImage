%% Useful function: angular error
function err = angularError(src, tgt)

[xs, ys] = pol2cart(src, 1);
[xt, yt] = pol2cart(tgt, 1);

err = acos(xs.*xt + ys.*yt);

