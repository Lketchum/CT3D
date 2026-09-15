%% t01_hu_and_window
% Lesson 1: stored -> HU -> window/level -> uint8 gray.
%
%   HU = stored * Slope + Intercept
%   lo = WL - WW/2;  hi = WL + WW/2
%   gray8 = clip((HU-lo)/(hi-lo), 0, 1) * 255
%
% >>> STUDENT: change WL/WW presets and watch soft tissue vs lung vs bone.

clear; clc;
addpath(fullfile(fileparts(mfilename('fullpath')), 'lib'));
outDir = teach_out_dir();

cache = fullfile(outDir, 't00_series.mat');
if ~isfile(cache)
    t00_load_series;
end
S = load(cache, 'stored', 'meta');
stored = S.stored;
meta = S.meta;

hu = stored_to_hu(stored, meta.RescaleSlope, meta.RescaleIntercept);
mid = round(size(hu, 3) / 2);
sliceHu = hu(:, :, mid);

presets = struct( ...
    'name', {'Soft tissue', 'Lung', 'Bone'}, ...
    'WL', {40, -600, 400}, ...
    'WW', {400, 1500, 1800});

figure('Name', 't01 HU and window', 'Color', 'w', 'Position', [40 40 1100 700]);
subplot(2, 3, 1);
imagesc(stored(:, :, mid)); axis image off; colormap(gca, gray); colorbar;
title('1) Stored');

subplot(2, 3, 2);
imagesc(sliceHu); axis image off; colormap(gca, gray); colorbar;
title(sprintf('2) HU = stored*%g%+g', meta.RescaleSlope, meta.RescaleIntercept));

subplot(2, 3, 3);
histogram(sliceHu(sliceHu > -900), 80);
xlabel('HU'); ylabel('count'); title('HU histogram'); grid on;

for p = 1:3
    g = apply_window_uint8(sliceHu, presets(p).WL, presets(p).WW);
    subplot(2, 3, 3 + p);
    imshow(g);
    title(sprintf('%s  WL=%d WW=%d', presets(p).name, presets(p).WL, presets(p).WW));
end
sgtitle('t01: rescale + window level  (display only; volume unchanged)');

exportgraphics(gcf, fullfile(outDir, 't01_hu_window.png'), 'Resolution', 120);

%% >>> STUDENT: implement your own window without calling apply_window_uint8
% myWL = 40; myWW = 400;
% lo = myWL - myWW/2;
% hi = myWL + myWW/2;
% t = (sliceHu - lo) / (hi - lo);
% t = min(max(t, 0), 1);
% myGray = uint8(round(t * 255));
% figure; imshow(myGray); title('my window');

fprintf('Open lib/stored_to_hu.m and lib/apply_window_uint8.m — then fill STUDENT block.\n');
fprintf('Done t01.\n');
