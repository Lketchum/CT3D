function [vol, meta] = load_dicom_volume(seriesDir)
%LOAD_DICOM_VOLUME  Load one CT series as HU volume [rows x cols x slices].
    if ~isfolder(seriesDir)
        error('Series folder not found: %s', seriesDir);
    end

    files = dir(fullfile(seriesDir, '*.dcm'));
    if isempty(files)
        error('No .dcm files in %s', seriesDir);
    end

    info0 = dicominfo(fullfile(seriesDir, files(1).name));
    usedFallback = false;
    try
        [V, spatial] = dicomreadVolume(seriesDir);
        vol = single(squeeze(V));
        meta.spatial = spatial;
    catch readErr
        warning('dicomreadVolume failed (%s). Falling back to per-file read.', readErr.message);
        [vol, spatial] = load_dicom_loop(seriesDir, files);
        meta.spatial = spatial;
        usedFallback = true;
    end

    slope = 1;
    intercept = 0;
    if isfield(info0, 'RescaleSlope')
        slope = single(info0.RescaleSlope);
    end
    if isfield(info0, 'RescaleIntercept')
        intercept = single(info0.RescaleIntercept);
    end
    vol = vol * slope + intercept;

    meta.seriesDir = seriesDir;
    meta.nSlices = size(vol, 3);
    meta.Rows = size(vol, 1);
    meta.Columns = size(vol, 2);
    meta.usedFallback = usedFallback;
    meta.RescaleSlope = slope;
    meta.RescaleIntercept = intercept;
    if isfield(info0, 'PixelSpacing')
        meta.PixelSpacing = info0.PixelSpacing;
    else
        meta.PixelSpacing = [NaN; NaN];
    end
    if isfield(info0, 'SliceThickness')
        meta.SliceThickness = info0.SliceThickness;
    else
        meta.SliceThickness = NaN;
    end
    meta.Modality = get_dicom_str(info0, 'Modality');
    meta.SeriesDescription = get_dicom_str(info0, 'SeriesDescription');
    meta.PatientID = get_dicom_str(info0, 'PatientID');
    meta.Manufacturer = get_dicom_str(info0, 'Manufacturer');
end

function [vol, spatial] = load_dicom_loop(seriesDir, files)
    n = numel(files);
    zpos = zeros(n, 1);
    inst = zeros(n, 1);
    for i = 1:n
        info = dicominfo(fullfile(seriesDir, files(i).name));
        if isfield(info, 'ImagePositionPatient')
            zpos(i) = info.ImagePositionPatient(3);
        else
            zpos(i) = i;
        end
        if isfield(info, 'InstanceNumber')
            inst(i) = info.InstanceNumber;
        else
            inst(i) = i;
        end
    end
    if numel(unique(zpos)) == n
        [~, order] = sort(zpos);
    else
        [~, order] = sort(inst);
    end
    files = files(order);

    sample = dicomread(fullfile(seriesDir, files(1).name));
    vol = zeros(size(sample, 1), size(sample, 2), n, 'single');
    for k = 1:n
        vol(:, :, k) = single(dicomread(fullfile(seriesDir, files(k).name)));
    end
    spatial = struct('sortKey', 'ImagePositionPatient');
end

function s = get_dicom_str(info, fieldName)
    if isfield(info, fieldName)
        s = char(string(info.(fieldName)));
    else
        s = '';
    end
end
