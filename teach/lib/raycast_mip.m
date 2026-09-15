function img = raycast_mip(vol, spacingXYZ, viewSize, stepMm)
%RAYCAST_MIP  Orthographic MIP along +Z in volume index space (teaching version).
%
%   Idea of ray casting:
%     For each output pixel (i,j), cast a ray through the volume,
%     sample HU along the ray, take max (MIP) or integrate (X-ray-like).
%
%   This simplified demo shoots rays along Z for an axial-looking MIP.
%   Change the ray direction in STUDENT code to rotate the view.

    if nargin < 4 || isempty(stepMm)
        stepMm = min(spacingXYZ);
    end
    [nY, nX, nZ] = size(vol);
    dy = spacingXYZ(1);
    dx = spacingXYZ(2);
    dz = spacingXYZ(3);

    % Output grid covers full Y-X extent
    img = zeros(viewSize(1), viewSize(2));
    yLin = linspace(1, nY, viewSize(1));
    xLin = linspace(1, nX, viewSize(2));

    zStart = 1;
    zEnd = nZ;
    nSteps = max(2, ceil((zEnd - zStart) * dz / stepMm));
    zSamples = linspace(zStart, zEnd, nSteps);

    for i = 1:viewSize(1)
        for j = 1:viewSize(2)
            y = yLin(i);
            x = xLin(j);
            vmax = -inf;
            for k = 1:nSteps
                v = sample_trilinear(vol, y, x, zSamples(k));
                if v > vmax
                    vmax = v;
                end
            end
            img(i, j) = vmax;
        end
    end
end
