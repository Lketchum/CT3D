%% p05_snapshot_3d
% Headless 3D model from stacked CT DICOM (bone isosurface).

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
fprintf('Volume %dx%dx%d  spacing=[%.3f %.3f]  thick=%.2f\n', ...
    size(vol, 1), size(vol, 2), size(vol, 3), ...
    meta.PixelSpacing(1), meta.PixelSpacing(2), meta.SliceThickness);

fprintf('Extracting bone isosurface (HU=300)...\n');
t0 = tic;
[faces, verts] = ct_isosurface(vol, meta, 300);
fprintf('  %d faces, %d verts  (%.1f s)\n', size(faces, 1), size(verts, 1), toc(t0));

if ~usejava('desktop')
    set(0, 'DefaultFigureVisible', 'off');
end

fig = figure('Color', [0.05 0.05 0.08], 'Position', [40 40 900 720]);
ax = axes(fig);
patch(ax, 'Faces', faces, 'Vertices', verts, ...
    'FaceColor', [0.93 0.93 0.90], 'EdgeColor', 'none', 'FaceAlpha', 0.96);
view(ax, 35, 18);
axis(ax, 'equal', 'off', 'tight');
camlight(ax, 'headlight');
lighting(ax, 'gouraud');
title(ax, sprintf('3D bone model  |  %s  |  %d slices', ...
    meta.SeriesDescription, meta.nSlices), 'Color', [0.95 0.95 0.95], 'Interpreter', 'none');
set(ax, 'Color', [0.05 0.05 0.08]);

outPath = fullfile(outDir, 'volume_bone_model.png');
exportgraphics(fig, outPath, 'Resolution', 140);
fprintf('Saved %s\n', outPath);
