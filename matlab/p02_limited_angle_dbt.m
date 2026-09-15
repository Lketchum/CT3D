%% 02_limited_angle_dbt
% Bridge from CT to DBT: same phantom, three angular coverages.
%   A) 180 views / 180 deg     -- CT-like FBP
%   B)  25 views /  25 deg     -- GE-like DBT sweep (see ParameterSettings_GE)
%   C)   9 views / 2.5 deg     -- LAVI phantom default (ParameterSettings_Phantom)

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

%% Phantom
N = 256;
img = phantom('Modified Shepp-Logan', N);

cases = {
    'CT 180 deg / 180 views',  0:179
    'DBT-like 25 deg / 25 views', linspace(-12.5, 12.5, 25)
    'LAVI phantom 2.5 deg / 9 views', linspace(-1.25, 1.25, 9)
};

nCase = size(cases, 1);
recon = cell(nCase, 1);
metrics = cell(nCase, 1);

fprintf('\n=== Phase 1  |  limited-angle FBP (DBT vs CT) ===\n');
for i = 1:nCase
    theta = cases{i, 2};
    sino = radon(img, theta);
    rec = iradon(sino, theta, 'linear', 'Ram-Lak', 1, N);
    rec = match_intensity(img, rec);
    recon{i} = rec;
    metrics{i} = recon_metrics(img, rec);
    print_metrics(cases{i, 1}, metrics{i});
end

%% Figures
fig = figure('Name', '02 Limited-angle DBT', 'Color', 'w', 'Position', [60 60 1180 700]);
subplot(2, 4, 1); imagesc(img); axis image off; colormap(gca, gray); title('Phantom (GT)');

for i = 1:nCase
    theta = cases{i, 2};
    sino = radon(img, theta);
    subplot(2, 4, i + 1);
    imagesc(sino); axis tight; colormap(gca, gray);
    title(sprintf('Sino: %s', cases{i, 1}));
    xlabel('view'); ylabel('detector');

    subplot(2, 4, i + 5);
    imagesc(recon{i}); axis image off; colormap(gca, gray);
    title(sprintf('FBP  SSIM=%.3f', metrics{i}.ssim));
end

sgtitle('Limited angle = missing Fourier coverage \rightarrow streak / depth blur');

figPath = fullfile(outDir, '02_limited_angle_dbt.png');
exportgraphics(fig, figPath, 'Resolution', 140);
fprintf('Saved %s\n', figPath);

save(fullfile(outDir, '02_limited_angle_metrics.mat'), 'cases', 'metrics', 'recon');
fprintf('Done.\n');
