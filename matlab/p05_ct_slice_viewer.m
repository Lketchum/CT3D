%% p05_ct_slice_viewer
% Volume workstation: load OrigCTData, show linked MPR, operate on slices.
% Run this in the MATLAB desktop (needs a figure window), not matlab -batch.

thisDir = fileparts(mfilename('fullpath'));
addpath(fullfile(thisDir, 'recon'));
addpath(fullfile(thisDir, 'viewer'));

repoRoot = fileparts(thisDir);
dataRoot = fullfile(repoRoot, 'data', 'OrigCTData');
if ~isfolder(dataRoot)
    error('Put CT DICOM under %s', dataRoot);
end

if ~usejava('awt')
    error('p05 needs the MATLAB desktop GUI. Open MATLAB and run p05_ct_slice_viewer.');
end

app = CTSliceViewer(dataRoot); %#ok<NASU>
fprintf('CT Volume Workstation is open.\n');
fprintf('  DICOM slice: drag the yellow-labeled slider under Axial (or type a number).\n');
fprintf('  Coronal / Sagittal sliders change the other two planes.\n');
fprintf('  Right panel: 3D model from the stacked CT volume (Bone / Skin / Volume / MIP).\n');
fprintf('  Window preset is brightness/contrast only; it does not change slice position.\n');
