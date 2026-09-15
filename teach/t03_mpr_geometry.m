%% t03_mpr_geometry
% Lesson 3: MPR — axis-aligned indexing + oblique plane by normal vector.
%
%   Axial:    fix z, take vol(:,:,z)
%   Coronal:  fix y, take vol(y,:,:)
%   Sagittal: fix x, take vol(:,x,:)
%
%   Oblique: p(i,j) = origin + u*(j-cu)*s + v*(i-cv)*s
%            sample vol with trilinear at p
%
% >>> STUDENT: change `normal` / `uAxis` to rotate the cut.

clear; clc;
addpath(fullfile(fileparts(mfilename('fullpath')), 'lib'));
outDir = teach_out_dir();

cache = fullfile(outDir, 't00_series.mat');
if ~isfile(cache)
    t00_load_series;
end
S = load(cache, 'stored', 'meta');
hu = stored_to_hu(S.stored, S.meta.RescaleSlope, S.meta.RescaleIntercept);
spacing = [S.meta.PixelSpacing(1); S.meta.PixelSpacing(2); S.meta.SliceSpacing];

% Use a downsampled volume for oblique (nested loops are slow)
step = 2;
vol = hu(1:step:end, 1:step:end, 1:step:end);
sp = spacing * step;

iy = round(size(vol, 1) / 2);
ix = round(size(vol, 2) / 2);
iz = round(size(vol, 3) / 2);

ax = extract_axis_aligned(vol, 'axial', iz);
cor = extract_axis_aligned(vol, 'coronal', iy);
sag = extract_axis_aligned(vol, 'sagittal', ix);

% Oblique: 30 deg tilt about X
ang = deg2rad(30);  % >>> STUDENT: try 45, 60
normal = [0; sin(ang); cos(ang)];
uAxis = [1; 0; 0];
origin = [ ...
    (iy - 1) * sp(1); ...
    (ix - 1) * sp(2); ...
    (iz - 1) * sp(3)];

fprintf('Sampling oblique plane (may take ~10-30s)...\n');
t0 = tic;
obl = extract_oblique_plane(vol, sp, origin, normal, uAxis, [192 192], min(sp));
fprintf('  done in %.1f s\n', toc(t0));

WL = 40; WW = 400;
figure('Name', 't03 MPR', 'Color', 'w', 'Position', [40 40 1100 700]);
subplot(2, 2, 1); imshow(apply_window_uint8(ax, WL, WW)); title('Axial (index z)');
subplot(2, 2, 2); imshow(apply_window_uint8(cor, WL, WW)); title('Coronal (index y)');
subplot(2, 2, 3); imshow(apply_window_uint8(sag, WL, WW)); title('Sagittal (index x)');
subplot(2, 2, 4); imshow(apply_window_uint8(obl, WL, WW));
title(sprintf('Oblique  n=[%.2f %.2f %.2f]', normal(1), normal(2), normal(3)));
sgtitle('t03: MPR geometry');

exportgraphics(gcf, fullfile(outDir, 't03_mpr.png'), 'Resolution', 120);
fprintf('Done t03. Read lib/extract_axis_aligned.m and lib/extract_oblique_plane.m\n');
