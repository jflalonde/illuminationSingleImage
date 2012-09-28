function feat = features_sensitive(img, sbin)

% compute features
feat = features(img, sbin);

% keep only constrast-sensitive dimensions
feat = feat(:,:,[1:18 28:31]);