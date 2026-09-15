%% 01_shepp_logan_fbp
% Phase 1 baseline: 2D Shepp-Logan phantom, full-angle BP vs FBP.
% Requires Image Processing Toolbox (phantom / radon / iradon / ssim).

thisDir = fileparts(mfilename('fullpath'));
addpath(fullfile(thisDir, 'recon'));

repoRoot = fileparts(thisDir);
outDir = fullfile(repoRoot, 'data', 'processed', 'phase1');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

if ~usejava('desktop')
    set(0, 'DefaultFigureVisible', 'off');
end

%% Geometry
N = 256;
theta = 0:179;
filterName = 'ram-lak';
cutoff = 1.0;

%% Phantom and forward projection (Radon transform)
img = phantom('Modified Shepp-Logan', N);
sino = radon(img, theta);

%% Backprojection (no filter) and FBP
imgBP = iradon(sino, theta, 'linear', 'none', 1, N);
sinoFilt = apply_ramp_filter(sino, filterName, cutoff);
imgFBP = iradon(sinoFilt, theta, 'linear', 'none', 1, N);
imgFBPRef = iradon(sino, theta, 'linear', 'Ram-Lak', 1, N);

% BP intensity is a sum of smeared rays; affine-match for fair metrics
imgBPMatch = match_intensity(img, imgBP);
imgFBPMatch = match_intensity(img, imgFBP);

%% Metrics
fprintf('\n=== Phase 1  |  2D Shepp-Logan FBP ===\n');
fprintf('Phantom %dx%d, %d views over 180 deg, filter=%s\n', N, N, numel(theta), filterName);
print_metrics('BP (matched)', recon_metrics(img, imgBPMatch));
print_metrics('FBP (ours)', recon_metrics(img, imgFBPMatch));
print_metrics('FBP (iradon)', recon_metrics(img, match_intensity(img, imgFBPRef)));

%% Filter frequency response (why Ram-Lak exists)
nfft = max(64, 2^nextpow2(2 * size(sino, 1)));
[freq, Hram] = ramp_freq_response(nfft, 'ram-lak', 1);
[~, Hhann] = ramp_freq_response(nfft, 'hann', 1);

%% Figures
fig1 = figure('Name', '01 Shepp-Logan BP vs FBP', 'Color', 'w', 'Position', [80 80 1100 720]);
subplot(2, 3, 1); imagesc(img); axis image off; colormap(gca, gray); title('Phantom (GT)');
subplot(2, 3, 2); imagesc(sino); axis tight; colormap(gca, gray); title('Sinogram (Radon)');
xlabel('angle'); ylabel('detector');
subplot(2, 3, 3); plot(freq, Hram, 'k', freq, Hhann, 'r'); grid on;
xlim([-0.5 0.5]); xlabel('cycles / sample'); ylabel('|H(f)|');
title('Ram-Lak vs Hann-windowed'); legend('Ram-Lak', 'Hann', 'Location', 'south');
subplot(2, 3, 4); imagesc(imgBPMatch); axis image off; colormap(gca, gray); title('BP (blurred)');
subplot(2, 3, 5); imagesc(imgFBPMatch); axis image off; colormap(gca, gray); title('FBP Ram-Lak');
subplot(2, 3, 6); imagesc(abs(imgFBPMatch - img)); axis image off; colormap(gca, gray); title('|FBP - GT|');
sgtitle('Phase 1: full-angle 2D reconstruction');

figPath = fullfile(outDir, '01_shepp_logan_fbp.png');
exportgraphics(fig1, figPath, 'Resolution', 140);
fprintf('Saved %s\n', figPath);

metrics = struct( ...
    'N', N, ...
    'nViews', numel(theta), ...
    'filter', filterName, ...
    'bp', recon_metrics(img, imgBPMatch), ...
    'fbp', recon_metrics(img, imgFBPMatch));
save(fullfile(outDir, '01_shepp_logan_metrics.mat'), 'metrics', 'img', 'imgBPMatch', 'imgFBPMatch');
fprintf('Done.\n');
