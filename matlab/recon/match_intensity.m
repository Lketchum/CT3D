function rec = match_intensity(ref, rec)
%MATCH_INTENSITY  Least-squares scale and offset so rec matches ref.
%   Unfiltered backprojection is a sum of smeared rays, so its raw
%   dynamic range is not comparable to the phantom. Affine matching
%   isolates the spatial-blur error from a global intensity bias.

    ref = double(ref);
    rec0 = double(rec);
    A = [rec0(:), ones(numel(rec0), 1)];
    coeff = A \ ref(:);
    rec = reshape(coeff(1) * rec0(:) + coeff(2), size(rec0));
end
