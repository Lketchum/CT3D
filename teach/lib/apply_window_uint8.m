function gray8 = apply_window_uint8(hu, windowCenter, windowWidth)
%APPLY_WINDOW_UINT8  Map HU to 8-bit display with window level/width.
%
%   Window maps a HU interval to [0, 255]:
%       lo = WL - WW/2
%       hi = WL + WW/2
%       gray = (HU - lo) / (hi - lo)   then clip to [0,1], *255
%
%   Outside [lo, hi] is saturated to black or white.
%   This does NOT change the volume; only the displayed gray values.

    lo = windowCenter - windowWidth / 2;
    hi = windowCenter + windowWidth / 2;
    if hi <= lo
        error('windowWidth must be positive');
    end
    t = (double(hu) - lo) / (hi - lo);
    t = min(max(t, 0), 1);
    gray8 = uint8(round(t * 255));
end
