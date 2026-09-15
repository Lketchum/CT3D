%% ex01_hu_window_todo
% Fill the TODOs. Do not call stored_to_hu / apply_window_uint8.
% When done, your gray image should look like Soft-tissue window.

addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'lib'));
outDir = teach_out_dir();
S = load(fullfile(outDir, 't00_series.mat'), 'stored', 'meta');
stored = S.stored(:, :, round(end / 2));
slope = S.meta.RescaleSlope;
intercept = S.meta.RescaleIntercept;

% TODO 1: convert stored -> HU
hu = [];  % hu = stored * ? + ?;

% TODO 2: Soft tissue WL=40, WW=400 -> uint8
WL = 40; WW = 400;
gray8 = [];  % compute lo, hi, clip, scale to 0..255

assert(~isempty(hu) && ~isempty(gray8), 'Fill TODOs first');
figure; imshow(gray8); title('ex01 your window');
