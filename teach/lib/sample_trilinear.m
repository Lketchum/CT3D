function val = sample_trilinear(vol, y, x, z)
%SAMPLE_TRILINEAR  Manual trilinear sample at continuous (y,x,z) 1-based index.
%   Write this by hand before trusting interp3 — core of resampling / MPR / rays.

    [nY, nX, nZ] = size(vol);
    if y < 1 || x < 1 || z < 1 || y > nY || x > nX || z > nZ
        val = 0;
        return;
    end

    y0 = floor(y);
    x0 = floor(x);
    z0 = floor(z);
    y1 = min(y0 + 1, nY);
    x1 = min(x0 + 1, nX);
    z1 = min(z0 + 1, nZ);
    y0 = max(y0, 1);
    x0 = max(x0, 1);
    z0 = max(z0, 1);

    yd = y - y0;
    xd = x - x0;
    zd = z - z0;

    c000 = double(vol(y0, x0, z0));
    c100 = double(vol(y1, x0, z0));
    c010 = double(vol(y0, x1, z0));
    c110 = double(vol(y1, x1, z0));
    c001 = double(vol(y0, x0, z1));
    c101 = double(vol(y1, x0, z1));
    c011 = double(vol(y0, x1, z1));
    c111 = double(vol(y1, x1, z1));

    c00 = c000 * (1 - yd) + c100 * yd;
    c10 = c010 * (1 - yd) + c110 * yd;
    c01 = c001 * (1 - yd) + c101 * yd;
    c11 = c011 * (1 - yd) + c111 * yd;

    c0 = c00 * (1 - xd) + c10 * xd;
    c1 = c01 * (1 - xd) + c11 * xd;

    val = c0 * (1 - zd) + c1 * zd;
end
