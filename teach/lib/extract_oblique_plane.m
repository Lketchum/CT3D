function sliceImg = extract_oblique_plane(vol, spacingXYZ, originXYZ, normal, uAxis, outSize, outSpacing)
%EXTRACT_OBLIQUE_PLANE  Sample a 2D plane from a 3D volume (general MPR).
%
%   Physical coords (mm), volume index (y,x,z) 1-based:
%       y = py / dy + 1,  x = px / dx + 1,  z = pz / dz + 1
%
%   Plane: point originXYZ, unit normal n.
%   Image axes: uAxis (unit), vAxis = cross(n, uAxis) normalized.
%   For pixel (i,j) centered:
%       p = origin + (j - c_u)*outSpacing * u + (i - c_v)*outSpacing * v
%   then trilinear-sample vol at p.

    spacingXYZ = spacingXYZ(:)';
    originXYZ = originXYZ(:);
    normal = normal(:) / norm(normal);
    uAxis = uAxis(:) / norm(uAxis);
    vAxis = cross(normal, uAxis);
    if norm(vAxis) < 1e-8
        error('uAxis nearly parallel to normal');
    end
    vAxis = vAxis / norm(vAxis);
    % Re-orthogonalize u
    uAxis = cross(vAxis, normal);
    uAxis = uAxis / norm(uAxis);

    nOut = outSize(1);
    mOut = outSize(2);
    cu = (mOut + 1) / 2;
    cv = (nOut + 1) / 2;
    dy = spacingXYZ(1);
    dx = spacingXYZ(2);
    dz = spacingXYZ(3);

    sliceImg = zeros(nOut, mOut);
    for i = 1:nOut
        for j = 1:mOut
            p = originXYZ + (j - cu) * outSpacing * uAxis + (i - cv) * outSpacing * vAxis;
            % p = [py; px; pz] in mm from volume corner (0,0,0)
            y = p(1) / dy + 1;
            x = p(2) / dx + 1;
            z = p(3) / dz + 1;
            sliceImg(i, j) = sample_trilinear(vol, y, x, z);
        end
    end
end
