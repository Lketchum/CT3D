%% t00_load_series
% Lesson 0: stack DICOM files into a 3D array of STORED pixels (not HU yet).
% Open lib/load_series_stored.m and read the sort-by-ImagePositionPatient loop.

clear; clc;
addpath(fullfile(fileparts(mfilename('fullpath')), 'lib'));

seriesDir = default_teach_series();
fprintf('Series: %s\n', seriesDir);

[stored, meta] = load_series_stored(seriesDir);

fprintf('stored size: %s  class=%s\n', mat2str(size(stored)), class(stored));
fprintf('PixelSpacing (row,col) mm: [%.4f %.4f]\n', meta.PixelSpacing(1), meta.PixelSpacing(2));
fprintf('SliceThickness=%.3f  SliceSpacing=%.3f\n', meta.SliceThickness, meta.SliceSpacing);
fprintf('RescaleSlope=%g  RescaleIntercept=%g\n', meta.RescaleSlope, meta.RescaleIntercept);
fprintf('NOTE: volume is still STORED values. Convert to HU in t01.\n');

% mid = round(meta.nSlices / 2);
mid = 10;
figure('Name', 't00 stored mid-slice', 'Color', 'w');
imagesc(stored(:, :, mid));
axis image off; colormap(gray); colorbar;
title(sprintf('Stored pixels  slice %d/%d  (not HU)', mid, meta.nSlices));

outDir = teach_out_dir();
exportgraphics(gcf, fullfile(outDir, 't00_stored_mid.png'), 'Resolution', 120);
save(fullfile(outDir, 't00_series.mat'), 'stored', 'meta', 'seriesDir');
fprintf('Saved %s\n', fullfile(outDir, 't00_series.mat'));
