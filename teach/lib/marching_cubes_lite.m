function [faces, verts] = marching_cubes_lite(vol, iso, spacingXYZ)
%MARCHING_CUBES_LITE  Build an isosurface mesh (educational wrapper).
%
%   Full 256-case MC tables are large; MATLAB isosurface implements the same
%   idea (classify cube corners -> cut edges -> triangles). We use it for the
%   whole volume, and keep the hand math in mc_explain_cube / edge lerp.
%
%   Physical vertex coords use spacingXYZ = [dy dx dz] mm.

    if nargin < 3
        spacingXYZ = [1 1 1];
    end
    spacingXYZ = spacingXYZ(:)';
    vol = double(vol);
    [nY, nX, nZ] = size(vol);

    [X, Y, Z] = meshgrid( ...
        (0:nX - 1) * spacingXYZ(2), ...
        (0:nY - 1) * spacingXYZ(1), ...
        (0:nZ - 1) * spacingXYZ(3));

    fv = isosurface(X, Y, Z, vol, iso);
    faces = fv.faces;
    verts = fv.vertices;
end
