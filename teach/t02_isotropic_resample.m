%% t02_isotropic_resample
% Lesson 2: anisotropic CT -> cubic voxels via interpolation.
%
%   Your chest series: ~0.70 x 0.70 x 3.0 mm  => Z is much coarser.
%   targetSpacing = min(dx,dy,dz)
%   V_iso = interp3(V, new physical grid)   % 'cubic' ~ tricubic
%
% Also compare hand trilinear sample_trilinear vs interp3.
%
% >>> STUDENT: change method to 'linear', or shrink crop for speed.

clear; clc;
addpath(fullfile(fileparts(mfilename('fullpath')), 'lib'));
outDir = teach_out_dir();

cache = fullfile(outDir, 't00_series.mat');
if ~isfile(cache)
    t00_load_series;
end
S = load(cache, 'stored', 'meta');
hu = stored_to_hu(S.stored, S.meta.RescaleSlope, S.meta.RescaleIntercept);

% Crop a small ROI for interactive teaching (full volume cubic resample is heavy)
cy = round(size(hu, 1) / 2);
cx = round(size(hu, 2) / 2);
cz = round(size(hu, 3) / 2);
half = [64 64 20];  % >>> STUDENT: try larger half for more context
y1 = max(1, cy - half(1)); y2 = min(size(hu, 1), cy + half(1));
x1 = max(1, cx - half(2)); x2 = min(size(hu, 2), cx + half(2));
z1 = max(1, cz - half(3)); z2 = min(size(hu, 3), cz + half(3));
crop = hu(y1:y2, x1:x2, z1:z2);

spacing = [S.meta.PixelSpacing(1); S.meta.PixelSpacing(2); S.meta.SliceSpacing];
fprintf('Original spacing [dy dx dz] = [%.3f %.3f %.3f] mm\n', spacing);
fprintf('Crop size %s\n', mat2str(size(crop)));

fprintf('Resampling cubic (interp3 cubic)...\n');
t0 = tic;
[volIso, spIso] = resample_isotropic(crop, spacing, 'cubic');
fprintf('  iso size %s  spacing=%.3f mm  (%.1f s)\n', mat2str(size(volIso)), spIso(1), toc(t0));

% Hand trilinear check at one point
y = size(crop, 1) / 2; x = size(crop, 2) / 2; z = size(crop, 3) / 2;
vHand = sample_trilinear(crop, y + 0.3, x + 0.4, z + 0.2);
fprintf('sample_trilinear demo value = %.3f HU\n', vHand);

% Sagittal look: before vs after (aspect should look less "squashed")
sag0 = squeeze(crop(:, round(size(crop, 2) / 2), :))';
sag1 = squeeze(volIso(:, round(size(volIso, 2) / 2), :))';

figure('Name', 't02 isotropic', 'Color', 'w', 'Position', [40 40 1000 420]);
subplot(1, 2, 1);
imagesc(sag0); axis image; colormap(gray);
daspect([spacing(3), spacing(1), 1]);
title(sprintf('Sagittal crop  dz=%.2f mm (anisotropic)', spacing(3)));
subplot(1, 2, 2);
imagesc(sag1); axis image; colormap(gray);
daspect([spIso(3), spIso(1), 1]);
title(sprintf('After isotropic  d=%.2f mm', spIso(1)));
sgtitle('t02: tricubic / cubic resampling to cubic voxels');

exportgraphics(gcf, fullfile(outDir, 't02_isotropic.png'), 'Resolution', 120);
save(fullfile(outDir, 't02_iso_crop.mat'), 'volIso', 'spIso', 'crop', 'spacing');
fprintf('Done t02. Read lib/resample_isotropic.m and lib/sample_trilinear.m\n');
