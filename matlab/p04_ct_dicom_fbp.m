%% p04_ct_dicom_fbp
% Load a reconstructed axial CT series from data/OrigCTData, treat one
% slice as ground truth, then run the same BP / FBP / limited-angle path
% as p01 and p02.
%
% These files are CT volumes, not DBT projections. Do not feed them into
% LAVI Reconstruction.m Clinical mode.

thisDir = fileparts(mfilename('fullpath'));
addpath(fullfile(thisDir, 'recon'));

repoRoot = fileparts(thisDir);
dataRoot = fullfile(repoRoot, 'data', 'OrigCTData');
outDir = fullfile(repoRoot, 'data', 'processed', 'phase1');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

if ~usejava('desktop')
    set(0, 'DefaultFigureVisible', 'off');
end

%% User options
% Leave seriesDir empty to use the default chest axial series (or auto-pick).
seriesDir = fullfile(dataRoot, 'cmb_aml', 'MSB-05167', ...
    '1959-12-18-CT_Chest-92091', '3-AXIAL ST 3.0 X 3.0-47508');
sliceIndex = [];          % empty = middle slice
reconSize = 256;          % downsample before Radon
huMin = -1000;
huMax = 400;
thetaFull = 0:179;
thetaDbt = linspace(-12.5, 12.5, 25);
thetaNarrow = linspace(-1.25, 1.25, 9);

%% Resolve series
if ~isfolder(seriesDir)
    fprintf('Default series missing. Scanning %s ...\n', dataRoot);
    seriesList = discover_axial_ct_series(dataRoot);
    if isempty(seriesList)
        error('No axial CT series (>=16 slices) found under %s', dataRoot);
    end
    fprintf('Available axial CT series:\n');
    for i = 1:numel(seriesList)
        fprintf('  [%2d] %4d slices  %s\n  %s\n', i, seriesList(i).nFiles, ...
            seriesList(i).description, seriesList(i).path);
    end
    seriesDir = seriesList(1).path;
end

fprintf('\n=== Phase 1  |  real CT DICOM -> FBP ===\n');
fprintf('Series: %s\n', seriesDir);

%% Load volume (HU)
tLoad = tic;
[vol, meta] = load_dicom_volume(seriesDir);
fprintf('Loaded %dx%dx%d HU  (%.1f s)  %s\n', ...
    meta.Rows, meta.Columns, meta.nSlices, toc(tLoad), meta.SeriesDescription);
fprintf('PixelSpacing=[%.3f %.3f] mm  SliceThickness=%.2f mm\n', ...
    meta.PixelSpacing(1), meta.PixelSpacing(2), meta.SliceThickness);

if isempty(sliceIndex)
    sliceIndex = round(meta.nSlices / 2);
end
sliceIndex = max(1, min(meta.nSlices, sliceIndex));

huSlice = vol(:, :, sliceIndex);
img = hu_to_recon_image(huSlice, huMin, huMax);
if reconSize < size(img, 1)
    img = imresize(img, [reconSize, reconSize], 'bilinear');
end
N = size(img, 1);

%% Orthogonal preview
axMid = vol(:, :, sliceIndex);
corMid = squeeze(vol(round(size(vol, 1) / 2), :, :))';
sagMid = squeeze(vol(:, round(size(vol, 2) / 2), :))';

%% Forward project and reconstruct
sino = radon(img, thetaFull);
imgBP = match_intensity(img, iradon(sino, thetaFull, 'linear', 'none', 1, N));
sinoFilt = apply_ramp_filter(sino, 'ram-lak', 1);
imgFBP = match_intensity(img, iradon(sinoFilt, thetaFull, 'linear', 'none', 1, N));

imgDbt = match_intensity(img, iradon(radon(img, thetaDbt), thetaDbt, 'linear', 'Ram-Lak', 1, N));
imgNarrow = match_intensity(img, iradon(radon(img, thetaNarrow), thetaNarrow, 'linear', 'Ram-Lak', 1, N));

fprintf('Slice %d / %d, recon %dx%d, HU clip [%d, %d]\n', ...
    sliceIndex, meta.nSlices, N, N, huMin, huMax);
print_metrics('BP (matched)', recon_metrics(img, imgBP));
print_metrics('FBP 180 deg', recon_metrics(img, imgFBP));
print_metrics('FBP 25 deg', recon_metrics(img, imgDbt));
print_metrics('FBP 2.5 deg', recon_metrics(img, imgNarrow));

%% Figures
climHu = [huMin huMax];

figVol = figure('Name', '04 CT volume', 'Color', 'w', 'Position', [60 60 1100 360]);
subplot(1, 3, 1); imagesc(axMid, climHu); axis image off; colormap(gca, gray);
title(sprintf('Axial slice %d', sliceIndex));
subplot(1, 3, 2); imagesc(corMid, climHu); axis image off; colormap(gca, gray);
title('Coronal (mid)');
subplot(1, 3, 3); imagesc(sagMid, climHu); axis image off; colormap(gca, gray);
title('Sagittal (mid)');
sgtitle(sprintf('%s  |  %s  |  %d slices', meta.PatientID, meta.SeriesDescription, meta.nSlices), ...
    'Interpreter', 'none');
volFigPath = fullfile(outDir, '04_ct_volume_views.png');
exportgraphics(figVol, volFigPath, 'Resolution', 140);

figRec = figure('Name', '04 CT FBP', 'Color', 'w', 'Position', [60 80 1180 700]);
subplot(2, 3, 1); imagesc(img); axis image off; colormap(gca, gray); title('GT slice (scaled HU)');
subplot(2, 3, 2); imagesc(sino); axis tight; colormap(gca, gray); title('Sinogram 180 deg');
xlabel('angle'); ylabel('detector');
subplot(2, 3, 3); imagesc(imgBP); axis image off; colormap(gca, gray);
title(sprintf('BP  SSIM=%.3f', recon_metrics(img, imgBP).ssim));
subplot(2, 3, 4); imagesc(imgFBP); axis image off; colormap(gca, gray);
title(sprintf('FBP 180 deg  SSIM=%.3f', recon_metrics(img, imgFBP).ssim));
subplot(2, 3, 5); imagesc(imgDbt); axis image off; colormap(gca, gray);
title(sprintf('FBP 25 deg  SSIM=%.3f', recon_metrics(img, imgDbt).ssim));
subplot(2, 3, 6); imagesc(imgNarrow); axis image off; colormap(gca, gray);
title(sprintf('FBP 2.5 deg  SSIM=%.3f', recon_metrics(img, imgNarrow).ssim));
sgtitle('Real CT: same reconstruction scheme as phantom (slice-wise 2D)');
recFigPath = fullfile(outDir, '04_ct_dicom_fbp.png');
exportgraphics(figRec, recFigPath, 'Resolution', 140);

metrics = struct( ...
    'seriesDir', seriesDir, ...
    'sliceIndex', sliceIndex, ...
    'reconSize', N, ...
    'bp', recon_metrics(img, imgBP), ...
    'fbp', recon_metrics(img, imgFBP), ...
    'dbt', recon_metrics(img, imgDbt), ...
    'narrow', recon_metrics(img, imgNarrow));
save(fullfile(outDir, '04_ct_dicom_metrics.mat'), 'metrics', 'meta', 'img', 'imgFBP');
fprintf('Saved %s\n', volFigPath);
fprintf('Saved %s\n', recFigPath);
fprintf('Done.\n');
