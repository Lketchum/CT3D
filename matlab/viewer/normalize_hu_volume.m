function vn = normalize_hu_volume(vol, huMin, huMax)
%NORMALIZE_HU_VOLUME  Map HU to [0, 1] for volshow / isosurface.
    if nargin < 2 || isempty(huMin)
        huMin = -1000;
    end
    if nargin < 3 || isempty(huMax)
        huMax = 1500;
    end
    vn = (single(vol) - huMin) / (huMax - huMin);
    vn = min(max(vn, 0), 1);
end
