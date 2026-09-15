function [faces, verts] = ct_isosurface(vol, meta, huThresh)
%CT_ISOSURFACE  Extract a surface mesh from HU volume (physical mm).
    [volSmall, voxelSize] = prepare_volume_render(vol, meta, 128);
    [nR, nC, nS] = size(volSmall);
    [X, Y, Z] = meshgrid( ...
        (0:nC - 1) * voxelSize(2), ...
        (0:nR - 1) * voxelSize(1), ...
        (0:nS - 1) * voxelSize(3));
    fv = isosurface(X, Y, Z, volSmall, huThresh);
    faces = fv.faces;
    verts = fv.vertices;
end
