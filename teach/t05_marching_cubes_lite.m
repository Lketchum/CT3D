%% t05_marching_cubes_lite
% Lesson 5: isosurface mesh from a scalar field (Marching Cubes idea).
%
%   Per unit cube:
%     1) mark 8 corners above/below iso  -> case id 0..255
%     2) find edges that cross the iso (linear interpolation)
%     3) connect cut points into triangles (lookup table in production MC)
%
%   Here:
%     - mc_explain_cube: hand math on ONE cube (print + plot cuts)
%     - marching_cubes_diy: your own cube walk (simplified triangulation)
%     - marching_cubes_lite: reference mesh (isosurface = full MC)
%
% >>> STUDENT: change isoHU (bone ~300, skin ~-200) and compare meshes.

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

% Small downsampled block around chest center
step = 4;
vol = hu(1:step:end, 1:step:end, 1:step:end);
sp = spacing * step;
isoHU = 300;  % >>> STUDENT: try -200 for body surface

% Find a cube that actually crosses the iso (for explanation)
found = false;
for k = 1:size(vol, 3) - 1
    for j = 1:size(vol, 2) - 1
        for i = 1:size(vol, 1) - 1
            c = vol(i:i + 1, j:j + 1, k:k + 1);
            if min(c(:)) < isoHU && max(c(:)) >= isoHU
                expl = mc_explain_cube(vol, i, j, k, isoHU, sp);
                found = true;
                break;
            end
        end
        if found, break; end
    end
    if found, break; end
end

fprintf('Building DIY mesh (simplified)...\n');
t0 = tic;
[fDiy, vDiy] = marching_cubes_diy(vol, isoHU, sp);
fprintf('  DIY: %d faces, %d verts (%.1f s)\n', size(fDiy, 1), size(vDiy, 1), toc(t0));

fprintf('Building reference isosurface (full MC)...\n');
t0 = tic;
[fRef, vRef] = marching_cubes_lite(vol, isoHU, sp);
fprintf('  Ref: %d faces, %d verts (%.1f s)\n', size(fRef, 1), size(vRef, 1), toc(t0));

figure('Name', 't05 MC', 'Color', [0.08 0.08 0.1], 'Position', [40 40 1100 480]);
subplot(1, 2, 1);
if ~isempty(fDiy)
    patch('Faces', fDiy, 'Vertices', vDiy, ...
        'FaceColor', [0.85 0.85 0.8], 'EdgeColor', [0.3 0.3 0.3], 'EdgeAlpha', 0.2);
end
axis equal tight off; view(35, 20); camlight headlight; lighting gouraud;
title(sprintf('DIY cube-walk  iso=%d', isoHU), 'Color', 'w');
set(gca, 'Color', [0.08 0.08 0.1]);

subplot(1, 2, 2);
if ~isempty(fRef)
    patch('Faces', fRef, 'Vertices', vRef, ...
        'FaceColor', [0.93 0.93 0.9], 'EdgeColor', 'none');
end
axis equal tight off; view(35, 20); camlight headlight; lighting gouraud;
title(sprintf('Reference isosurface  iso=%d', isoHU), 'Color', 'w');
set(gca, 'Color', [0.08 0.08 0.1]);
sgtitle('t05: Marching Cubes — voxels become a triangle mesh', 'Color', 'w');

exportgraphics(gcf, fullfile(outDir, 't05_mc.png'), 'Resolution', 120);
fprintf('Done t05. Read mc_explain_cube.m (lerp on edges) then marching_cubes_diy.m\n');
