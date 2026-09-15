function [volIso, spacingIso] = resample_isotropic(vol, spacingXYZ, method)
%RESAMPLE_ISOTROPIC  Resample volume to cubic voxels.
%
%   spacingXYZ = [dy, dx, dz] in mm (row, col, slice) matching size(vol).
%   method     = 'linear' | 'cubic'  (tricubic via interp3)
%
%   CT often has dz >> dx. We choose targetSpacing = min(spacings),
%   then build a new grid and interpolate:
%       V_new(y',x',z') = interp( V, physical coordinates )
%
%   Note: true separable tricubic is what interp3(...,'cubic') approximates.

    if nargin < 3 || isempty(method)
        method = 'cubic';
    end
    spacingXYZ = spacingXYZ(:)';
    if numel(spacingXYZ) ~= 3
        error('spacingXYZ must be [dy dx dz]');
    end

    [nY, nX, nZ] = size(vol);
    dy = spacingXYZ(1);
    dx = spacingXYZ(2);
    dz = spacingXYZ(3);
    target = min(spacingXYZ);

    yOld = (0:nY - 1) * dy;
    xOld = (0:nX - 1) * dx;
    zOld = (0:nZ - 1) * dz;

    yNew = 0:target:yOld(end);
    xNew = 0:target:xOld(end);
    zNew = 0:target:zOld(end);

    [Xq, Yq, Zq] = meshgrid(xNew, yNew, zNew);
    % interp3 expects X,Y,Z from meshgrid matching V(y,x,z)
    [Xo, Yo, Zo] = meshgrid(xOld, yOld, zOld);
    volIso = interp3(Xo, Yo, Zo, double(vol), Xq, Yq, Zq, method, 0);
    volIso = single(volIso);
    spacingIso = [target, target, target];
end
