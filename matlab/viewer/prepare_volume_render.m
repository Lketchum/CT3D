function [volSmall, voxelSize] = prepare_volume_render(vol, meta, maxDim)
%PREPARE_VOLUME_RENDER  Downsample HU volume for 3D display.
    if nargin < 3 || isempty(maxDim)
        maxDim = 160;
    end
    vol = single(vol);
    scale = min(1, maxDim / max(size(vol)));
    if scale < 0.999
        volSmall = imresize3(vol, scale, 'linear');
    else
        volSmall = vol;
    end

    pxy = meta.PixelSpacing(:)';
    if numel(pxy) < 2 || any(isnan(pxy))
        pxy = [1 1];
    end
    pz = meta.SliceThickness;
    if isnan(pz) || pz <= 0
        pz = 1;
    end
    voxelSize = [pxy(1) / scale, pxy(2) / scale, pz / scale];
end
