function result = mc_explain_cube(vol, i, j, k, iso, spacingXYZ)
%MC_EXPLAIN_CUBE  Hand-walk one voxel cube through Marching Cubes steps.
%   Corners numbered as classic MC (see comments). Prints case id and
%   linearly interpolated edge cut points — the core math of MC.

    if nargin < 6
        spacingXYZ = [1 1 1];
    end
    spacingXYZ = spacingXYZ(:)';

    % Corner offsets (y,x,z) relative to (i,j,k)
    off = [0 0 0; 1 0 0; 1 1 0; 0 1 0; 0 0 1; 1 0 1; 1 1 1; 0 1 1];
    vals = zeros(8, 1);
    posMm = zeros(8, 3);
    for c = 1:8
        yy = i + off(c, 1);
        xx = j + off(c, 2);
        zz = k + off(c, 3);
        vals(c) = double(vol(yy, xx, zz));
        posMm(c, :) = ([yy, xx, zz] - 1) .* spacingXYZ;
    end

    cfg = 0;
    for c = 1:8
        if vals(c) >= iso
            cfg = bitor(cfg, bitshift(uint16(1), c - 1));
        end
    end

    % Edges: endpoints as corner indices 1..8
    edgeEnds = [1 2; 2 3; 3 4; 4 1; 5 6; 6 7; 7 8; 8 5; 1 5; 2 6; 3 7; 4 8];
    cuts = zeros(0, 3);
    cutEdge = [];
    for e = 1:12
        a = edgeEnds(e, 1);
        b = edgeEnds(e, 2);
        aboveA = vals(a) >= iso;
        aboveB = vals(b) >= iso;
        if aboveA ~= aboveB
            % Linear interpolate where the field crosses iso
            t = (iso - vals(a)) / (vals(b) - vals(a) + eps);
            t = min(max(t, 0), 1);
            p = posMm(a, :) + t * (posMm(b, :) - posMm(a, :));
            cuts(end + 1, :) = p; %#ok<AGROW>
            cutEdge(end + 1) = e - 1; %#ok<AGROW>
        end
    end

    result.cfg = cfg;
    result.vals = vals;
    result.cuts = cuts;
    result.cutEdge = cutEdge;
    result.posMm = posMm;

    fprintf('Cube (%d,%d,%d)  iso=%.1f  case=%d (0..255)\n', i, j, k, iso, cfg);
    fprintf('  corner HU: %s\n', mat2str(vals.', 4));
    fprintf('  cut edges (0-based): %s\n', mat2str(cutEdge));
    fprintf('  #cut points: %d  (these become triangle vertices)\n', size(cuts, 1));
end
