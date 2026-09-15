function clim = window_clim(center, width)
%WINDOW_CLIM  HU display range from window center / width.
    clim = [center - width / 2, center + width / 2];
end
