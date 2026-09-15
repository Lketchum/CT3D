function [axImg, corImg, sagImg] = extract_mpr_planes(vol, idx, slab, mode)
%EXTRACT_MPR_PLANES  Axial / coronal / sagittal images at a voxel index.
%   vol  [row x col x slice] HU
%   idx  [row, col, slice]
%   slab odd thickness in voxels (1 = single slice)
%   mode 'mean' or 'mip'

    if nargin < 3 || isempty(slab)
        slab = 1;
    end
    if nargin < 4 || isempty(mode)
        mode = 'mean';
    end

    [nR, nC, nS] = size(vol);
    r = min(max(round(idx(1)), 1), nR);
    c = min(max(round(idx(2)), 1), nC);
    s = min(max(round(idx(3)), 1), nS);
    half = floor((max(slab, 1) - 1) / 2);

    axImg = reduce_slab(vol, 3, s, half, mode);
    corImg = reduce_slab(vol, 1, r, half, mode)';
    sagImg = reduce_slab(vol, 2, c, half, mode)';
end

function img = reduce_slab(vol, dim, center, half, mode)
    n = size(vol, dim);
    lo = max(1, center - half);
    hi = min(n, center + half);
    switch dim
        case 1
            slab = vol(lo:hi, :, :);
        case 2
            slab = vol(:, lo:hi, :);
        case 3
            slab = vol(:, :, lo:hi);
        otherwise
            error('dim must be 1, 2, or 3');
    end
    if strcmpi(mode, 'mip')
        img = squeeze(max(slab, [], dim));
    else
        img = squeeze(mean(slab, dim));
    end
end
