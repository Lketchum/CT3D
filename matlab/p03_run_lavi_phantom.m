%% 03_run_lavi_phantom
% Non-interactive LAVI-USP toolbox run: virtual Shepp-Logan -> FBP.
% Reconstruction.m itself opens a GUI; this script skips dialogs.
%
% Default is a downscaled phantom so the first CPU run finishes in minutes.
% Set quickMode = false to use the toolbox 128^3 / 280x350 detector settings.

thisDir = fileparts(mfilename('fullpath'));
addpath(fullfile(thisDir, 'recon'));

repoRoot = fileparts(thisDir);
toolboxDir = fullfile(repoRoot, 'vendor', 'DBT-Reconstruction');
if ~exist(fullfile(toolboxDir, 'FBP.m'), 'file')
    error('LAVI toolbox not found at %s. Run scripts/clone_dbt_toolbox.ps1 first.', toolboxDir);
end

outDir = fullfile(repoRoot, 'data', 'processed', 'phase1');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

if ~usejava('desktop')
    set(0, 'DefaultFigureVisible', 'off');
end

addpath(genpath(fullfile(toolboxDir, 'Functions')));
addpath(genpath(fullfile(toolboxDir, 'Parameters')));
addpath(toolboxDir);

global showinfo saveinfo animation
showinfo = uint8(1);
saveinfo = uint8(0);
animation = uint8(0);

%% Load toolbox phantom geometry, then optionally downscale
run(fullfile(toolboxDir, 'Parameters', 'ParameterSettings_Phantom.m'));

quickMode = true;
if quickMode
    parameter.nx = 64;
    parameter.ny = 64;
    parameter.nz = 64;
    parameter.nu = 140;
    parameter.nv = 176;
    parameter = rebuild_geometry(parameter);
    fprintf('quickMode=true  volume=%dx%dx%d  detector=%dx%d  nProj=%d\n', ...
        parameter.nx, parameter.ny, parameter.nz, parameter.nu, parameter.nv, parameter.nProj);
else
    fprintf('quickMode=false  using toolbox defaults (128^3, 280x350)\n');
end

%% Forward project and FBP
fprintf('Creating 3D Shepp-Logan phantom...\n');
data3d = single(phantom3d('Modified Shepp-Logan', parameter.nz));
data3d(data3d < 0) = eps;

fprintf('Projecting %d views (half cone-beam, tubeAngle=%.2f deg)...\n', ...
    parameter.nProj, parameter.tubeAngle);
tProj = tic;
dataProj = projection(data3d, parameter, []);
fprintf('  projection: %.1f s\n', toc(tProj));

fprintf('FBP (cutoff=0.75)...\n');
tFbp = tic;
dataRecon3d = FBP(dataProj, 'FBP', 0.75, parameter);
fprintf('  FBP: %.1f s\n', toc(tFbp));

vol = dataRecon3d{1, 1};
mid = round(parameter.nz / 2);
gtSlice = squeeze(data3d(:, :, mid));
recSlice = squeeze(vol(:, :, mid));
recSlice = match_intensity(gtSlice, recSlice);
m = recon_metrics(gtSlice, recSlice);
fprintf('Mid-slice vs GT:\n');
print_metrics('LAVI FBP', m);

%% Save mid-slice and a few neighbors
fig = figure('Name', '03 LAVI phantom FBP', 'Color', 'w', 'Position', [80 80 1000 420]);
subplot(1, 3, 1); imagesc(gtSlice); axis image off; colormap(gca, gray); title(sprintf('GT slice %d', mid));
subplot(1, 3, 2); imagesc(recSlice); axis image off; colormap(gca, gray); title(sprintf('FBP SSIM=%.3f', m.ssim));
subplot(1, 3, 3); imagesc(dataProj(:, :, round(parameter.nProj / 2))); axis image off; colormap(gca, gray);
title(sprintf('Proj %d / %d', round(parameter.nProj / 2), parameter.nProj));
sgtitle(sprintf('LAVI toolbox  |  DSD=%.0f mm  tube=%.2f deg  nProj=%d', ...
    parameter.DSD, parameter.tubeAngle, parameter.nProj));

figPath = fullfile(outDir, '03_lavi_phantom_fbp.png');
exportgraphics(fig, figPath, 'Resolution', 140);
save(fullfile(outDir, '03_lavi_phantom.mat'), 'parameter', 'dataProj', 'vol', 'm', 'quickMode');
fprintf('Saved %s\n', figPath);
fprintf('Done.\n');
