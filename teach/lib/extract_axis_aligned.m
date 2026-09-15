function sliceImg = extract_axis_aligned(vol, plane, index)
%EXTRACT_AXIS_ALIGNED  Classical MPR: axial / coronal / sagittal by indexing.
%   vol   [y x z]
%   plane 'axial' | 'coronal' | 'sagittal'
%   index 1-based slice index along the normal axis

    [nY, nX, nZ] = size(vol);
    switch lower(plane)
        case 'axial'
            index = min(max(round(index), 1), nZ);
            sliceImg = vol(:, :, index);
        case 'coronal'
            index = min(max(round(index), 1), nY);
            sliceImg = squeeze(vol(index, :, :))';
        case 'sagittal'
            index = min(max(round(index), 1), nX);
            sliceImg = squeeze(vol(:, index, :))';
        otherwise
            error('plane must be axial|coronal|sagittal');
    end
end
