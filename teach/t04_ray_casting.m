%% t04_ray_casting
% OPTIONAL for the 3D-visualization track (skip if focusing on MPR / meshes).
%
% This is volume RENDERING (MIP), not CT physical reconstruction (FBP).
% Reconstruction lives in matlab/p01-p04. Come back here when learning
% volume rendering after t03 + t05.
%
% Lesson: volume -> 2D image by casting rays (MIP).
%   For each output pixel (i,j):
%     walk samples along a ray through the volume
%     MIP: keep max HU along the ray
%
% >>> STUDENT: edit raycast_mip to change ray direction or integrate along ray.

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

% Downsample for speed
step = 3;
vol = hu(1:step:end, 1:step:end, 1:step:end);
sp = spacing * step;

fprintf('Ray-casting MIP (%dx%dx%d)...\n', size(vol, 1), size(vol, 2), size(vol, 3));
t0 = tic;
mip = raycast_mip(vol, sp, [180 180], min(sp));
fprintf('  %.1f s\n', toc(t0));

% Compare to a simple max along Z (same idea, no interpolation)
mipFast = squeeze(max(vol, [], 3));

figure('Name', 't04 ray casting', 'Color', 'w', 'Position', [40 40 900 400]);
subplot(1, 2, 1);
imshow(apply_window_uint8(mip, 300, 1500));
title('Ray-cast MIP (trilinear samples along Z)');
subplot(1, 2, 2);
imshow(apply_window_uint8(mipFast, 300, 1500));
title('Fast max([],3)  (same view, nearest)');
sgtitle('t04: voxels -> pixels via ray casting');

exportgraphics(gcf, fullfile(outDir, 't04_mip.png'), 'Resolution', 120);
fprintf('Done t04. Read lib/raycast_mip.m — rewrite the ray direction as exercise.\n');
