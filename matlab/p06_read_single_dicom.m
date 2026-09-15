%% p06_read_single_dicom
% Read one DICOM file: show pixel image + key tags + pixel stats.
% Edit dcmPath below, or leave empty to pick the first .dcm under OrigCTData.

thisDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(thisDir);
dataRoot = fullfile(repoRoot, 'data', 'OrigCTData');

%% User option: set a full path to one .dcm, or leave '' to auto-pick
dcmPath = '';
% Example (edit to your file):
% dcmPath = 'D:\AI_assist_project\CT3D\data\OrigCTData\...\something.dcm';

if isempty(dcmPath)
    % Prefer a slice from the known chest axial series if present
    preferDir = fullfile(dataRoot, 'cmb_aml', 'MSB-05167', ...
        '1959-12-18-CT_Chest-92091', '3-AXIAL ST 3.0 X 3.0-47508');
    prefer = dir(fullfile(preferDir, '*.dcm'));
    if ~isempty(prefer)
        dcmPath = fullfile(prefer(1).folder, prefer(1).name);
    else
        files = dir(fullfile(dataRoot, '**', '*.dcm'));
        if isempty(files)
            error('No .dcm under %s. Set dcmPath manually.', dataRoot);
        end
        dcmPath = fullfile(files(1).folder, files(1).name);
    end
end

if ~isfile(dcmPath)
    error('File not found: %s', dcmPath);
end

fprintf('\n=== Single DICOM ===\n');
fprintf('File: %s\n', dcmPath);
fprintf('Size on disk: %.1f KB\n', dir(dcmPath).bytes / 1024);

%% Header (metadata)
info = dicominfo(dcmPath);

fprintf('\n--- Key tags ---\n');
print_tag(info, 'SOPClassUID');
print_tag(info, 'Modality');
print_tag(info, 'Manufacturer');
print_tag(info, 'ManufacturerModelName');
print_tag(info, 'PatientID');
print_tag(info, 'StudyDescription');
print_tag(info, 'SeriesDescription');
print_tag(info, 'SeriesNumber');
print_tag(info, 'InstanceNumber');
print_tag(info, 'Rows');
print_tag(info, 'Columns');
print_tag(info, 'BitsAllocated');
print_tag(info, 'BitsStored');
print_tag(info, 'PixelRepresentation');
print_tag(info, 'PhotometricInterpretation');
print_tag(info, 'SamplesPerPixel');
print_tag(info, 'RescaleSlope');
print_tag(info, 'RescaleIntercept');
print_tag(info, 'WindowCenter');
print_tag(info, 'WindowWidth');
print_tag(info, 'PixelSpacing');
print_tag(info, 'SliceThickness');
print_tag(info, 'ImagePositionPatient');
print_tag(info, 'ImageOrientationPatient');
print_tag(info, 'SliceLocation');
print_tag(info, 'TransferSyntaxUID');

%% Pixel data
raw = dicomread(dcmPath);
fprintf('\n--- Pixel array ---\n');
fprintf('class: %s\n', class(raw));
fprintf('size:  %s\n', mat2str(size(raw)));
fprintf('min/max (stored): %g / %g\n', min(raw(:)), max(raw(:)));

% Stored value -> HU (or other real world value)
slope = 1;
intercept = 0;
if isfield(info, 'RescaleSlope')
    slope = double(info.RescaleSlope);
end
if isfield(info, 'RescaleIntercept')
    intercept = double(info.RescaleIntercept);
end
hu = double(raw) * slope + intercept;
fprintf('Rescale: HU = stored * %.4f + %.1f\n', slope, intercept);
fprintf('min/max (HU): %g / %g\n', min(hu(:)), max(hu(:)));

%% Display window
if isfield(info, 'WindowCenter') && isfield(info, 'WindowWidth')
    wc = double(info.WindowCenter(1));
    ww = double(info.WindowWidth(1));
else
    wc = 40;
    ww = 400;
end
clim = [wc - ww / 2, wc + ww / 2];

if ~usejava('desktop')
    set(0, 'DefaultFigureVisible', 'off');
end

fig = figure('Name', 'Single DICOM', 'Color', 'w', 'Position', [80 80 1100 480]);
subplot(1, 2, 1);
imagesc(raw);
axis image off;
colormap(gca, gray);
title(sprintf('Stored pixels  [%s]', class(raw)));
colorbar;

subplot(1, 2, 2);
imagesc(hu, clim);
axis image off;
colormap(gca, gray);
title(sprintf('HU  window C=%.0f W=%.0f', wc, ww));
colorbar;

sgtitle(short_title(dcmPath, info), 'Interpreter', 'none');

outDir = fullfile(repoRoot, 'data', 'processed', 'viewer');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end
outPng = fullfile(outDir, 'single_dicom_preview.png');
exportgraphics(fig, outPng, 'Resolution', 140);
fprintf('\nSaved preview: %s\n', outPng);

% Optional: dump full header field names to text
outTxt = fullfile(outDir, 'single_dicom_tags.txt');
fid = fopen(outTxt, 'w');
fprintf(fid, 'File: %s\n\n', dcmPath);
fn = fieldnames(info);
for i = 1:numel(fn)
    fprintf(fid, '%s\n', fn{i});
end
fclose(fid);
fprintf('Tag name list: %s  (%d fields)\n', outTxt, numel(fn));
fprintf('Tip: in Command Window run  openvar(''info'')  to browse the full header.\n');
fprintf('Done.\n');

function print_tag(info, name)
    if ~isfield(info, name)
        fprintf('%-28s  (missing)\n', name);
        return;
    end
    v = info.(name);
    if isnumeric(v)
        if isscalar(v)
            fprintf('%-28s  %g\n', name, v);
        else
            fprintf('%-28s  %s\n', name, mat2str(v(:).', 6));
        end
    elseif ischar(v) || isstring(v)
        fprintf('%-28s  %s\n', name, char(string(v)));
    else
        fprintf('%-28s  <%s>\n', name, class(v));
    end
end

function t = short_title(dcmPath, info)
    [~, name, ext] = fileparts(dcmPath);
    desc = '';
    if isfield(info, 'SeriesDescription')
        desc = char(string(info.SeriesDescription));
    end
    inst = '';
    if isfield(info, 'InstanceNumber')
        inst = sprintf('  Inst=%g', info.InstanceNumber);
    end
    t = sprintf('%s%s%s  |  %s', name, ext, inst, desc);
end
