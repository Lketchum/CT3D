%% p05_snapshot_mpr
% Headless check of load + MPR slice ops (no GUI). Writes one PNG.

thisDir = fileparts(mfilename('fullpath'));
addpath(fullfile(thisDir, 'recon'));
addpath(fullfile(thisDir, 'viewer'));

repoRoot = fileparts(thisDir);
dataRoot = fullfile(repoRoot, 'data', 'OrigCTData');
outDir = fullfile(repoRoot, 'data', 'processed', 'viewer');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

seriesDir = fullfile(dataRoot, 'cmb_aml', 'MSB-05167', ...
    '1959-12-18-CT_Chest-92091', '3-AXIAL ST 3.0 X 3.0-47508');
if ~isfolder(seriesDir)
    seriesList = discover_axial_ct_series(dataRoot);
    seriesDir = seriesList(1).path;
end

[vol, meta] = load_dicom_volume(seriesDir);
idx = [round(meta.Rows / 2), round(meta.Columns / 2), round(meta.nSlices / 2)];
[axImg, corImg, sagImg] = extract_mpr_planes(vol, idx, 1, 'mean');
clim = window_clim(40, 400);

if ~usejava('desktop')
    set(0, 'DefaultFigureVisible', 'off');
end

fig = figure('Color', 'w', 'Position', [40 40 1200 420]);
subplot(1, 3, 1); imagesc(axImg, clim); axis image off; colormap(gca, gray);
title(sprintf('Axial z=%d', idx(3)));
subplot(1, 3, 2); imagesc(corImg, clim); axis image off; colormap(gca, gray);
title(sprintf('Coronal y=%d', idx(1)));
subplot(1, 3, 3); imagesc(sagImg, clim); axis image off; colormap(gca, gray);
title(sprintf('Sagittal x=%d', idx(2)));
sgtitle(sprintf('MPR  |  %s  |  %dx%dx%d', meta.SeriesDescription, ...
    meta.Rows, meta.Columns, meta.nSlices), 'Interpreter', 'none');

outPath = fullfile(outDir, 'mpr_default_soft_tissue.png');
exportgraphics(fig, outPath, 'Resolution', 140);
fprintf('Loaded %dx%dx%d  HU(center)=%.0f\n', size(vol, 1), size(vol, 2), size(vol, 3), ...
    vol(idx(1), idx(2), idx(3)));
fprintf('Saved %s\n', outPath);
