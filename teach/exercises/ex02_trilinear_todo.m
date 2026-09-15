%% ex02_trilinear_todo
% Implement sample_trilinear yourself in this file (copy signature).
% Compare against teach/lib/sample_trilinear.m on random points.

addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'lib'));
outDir = teach_out_dir();
if ~isfile(fullfile(outDir, 't02_iso_crop.mat'))
    error('Run t02_isotropic_resample first');
end
S = load(fullfile(outDir, 't02_iso_crop.mat'), 'crop');
vol = S.crop;

% TODO: write my_sample_trilinear below, then test:
% err = abs(my_sample_trilinear(vol, 10.3, 12.7, 5.2) - sample_trilinear(vol, 10.3, 12.7, 5.2));

function val = my_sample_trilinear(vol, y, x, z)
    val = NaN;  % TODO
end
