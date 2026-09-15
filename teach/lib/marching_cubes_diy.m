function [faces, verts] = marching_cubes_diy(vol, iso, spacingXYZ)
%MARCHING_CUBES_DIY  Fully hand-written cube walk (teaching topology, not production).
%
%   For every unit cube:
%     - find edges where the field crosses iso (linear interpolation)
%     - if exactly 3 cut points: emit 1 triangle
%     - if 4+ cut points: fan-triangulate from the first cut
%
%   This is intentionally simplified (skips the classic 256-case table), so
%   some cubes get wrong connectivity. Use it to learn the pipeline, then
%   compare to marching_cubes_lite (isosurface / full MC).

    if nargin < 3
        spacingXYZ = [1 1 1];
    end
    spacingXYZ = spacingXYZ(:)';
    vol = double(vol);
    [nY, nX, nZ] = size(vol);

    verts = zeros(0, 3);
    faces = zeros(0, 3);
    edgeEnds = [1 2; 2 3; 3 4; 4 1; 5 6; 6 7; 7 8; 8 5; 1 5; 2 6; 3 7; 4 8];
    off = [0 0 0; 1 0 0; 1 1 0; 0 1 0; 0 0 1; 1 0 1; 1 1 1; 0 1 1];

    for k = 1:nZ - 1
        for j = 1:nX - 1
            for i = 1:nY - 1
                vals = zeros(8, 1);
                posMm = zeros(8, 3);
                for c = 1:8
                    yy = i + off(c, 1);
                    xx = j + off(c, 2);
                    zz = k + off(c, 3);
                    vals(c) = vol(yy, xx, zz);
                    posMm(c, :) = ([yy, xx, zz] - 1) .* spacingXYZ;
                end
                if all(vals >= iso) || all(vals < iso)
                    continue;
                end

                cuts = zeros(0, 3);
                for e = 1:12
                    a = edgeEnds(e, 1);
                    b = edgeEnds(e, 2);
                    if (vals(a) >= iso) ~= (vals(b) >= iso)
                        t = (iso - vals(a)) / (vals(b) - vals(a) + eps);
                        t = min(max(t, 0), 1);
                        cuts(end + 1, :) = posMm(a, :) + t * (posMm(b, :) - posMm(a, :)); %#ok<AGROW>
                    end
                end
                nCut = size(cuts, 1);
                if nCut < 3
                    continue;
                end
                base = size(verts, 1);
                verts = [verts; cuts]; %#ok<AGROW>
                for t = 2:nCut - 1
                    faces(end + 1, :) = base + [1, t, t + 1]; %#ok<AGROW>
                end
            end
        end
    end
end
