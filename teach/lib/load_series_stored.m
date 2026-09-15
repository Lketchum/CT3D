function [stored, meta] = load_series_stored(seriesDir)
%LOAD_SERIES_STORED  Load DICOM series as stored pixel values (NOT HU).
%   Students apply RescaleSlope/Intercept themselves in t01.
%
%   stored : [rows x cols x slices] single
%   meta   : PixelSpacing, SliceThickness, RescaleSlope/Intercept, ...

    if nargin < 1 || isempty(seriesDir) || ~isfolder(seriesDir)
        error('Provide a valid series folder of .dcm files.');
    end

    files = dir(fullfile(seriesDir, '*.dcm'));
    if isempty(files)
        error('No .dcm in %s', seriesDir);
    end

    n = numel(files);
    infos = cell(n, 1);
    zpos = zeros(n, 1);
    inst = zeros(n, 1);
    for i = 1:n
        infos{i} = dicominfo(fullfile(seriesDir, files(i).name));
        if isfield(infos{i}, 'ImagePositionPatient')
            zpos(i) = infos{i}.ImagePositionPatient(3);
        else
            zpos(i) = i;
        end
        if isfield(infos{i}, 'InstanceNumber')
            inst(i) = infos{i}.InstanceNumber;
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
    infos = infos(order);

    sample = dicomread(fullfile(seriesDir, files(1).name));
    stored = zeros(size(sample, 1), size(sample, 2), n, 'single');
    for k = 1:n
        stored(:, :, k) = single(dicomread(fullfile(seriesDir, files(k).name)));
    end

    info0 = infos{1};
    meta.seriesDir = seriesDir;
    meta.nSlices = n;
    meta.Rows = size(stored, 1);
    meta.Columns = size(stored, 2);
    meta.RescaleSlope = get_num(info0, 'RescaleSlope', 1);
    meta.RescaleIntercept = get_num(info0, 'RescaleIntercept', 0);
    if isfield(info0, 'PixelSpacing')
        meta.PixelSpacing = double(info0.PixelSpacing(:));
    else
        meta.PixelSpacing = [1; 1];
    end
    meta.SliceThickness = get_num(info0, 'SliceThickness', 1);
    meta.SeriesDescription = get_str(info0, 'SeriesDescription');
    meta.PatientID = get_str(info0, 'PatientID');
    if numel(unique(zpos(order))) == n
        meta.SliceLocations = zpos(order);
        meta.SliceSpacing = median(abs(diff(meta.SliceLocations)));
        if meta.SliceSpacing <= 0
            meta.SliceSpacing = meta.SliceThickness;
        end
    else
        meta.SliceLocations = (0:n - 1).' * meta.SliceThickness;
        meta.SliceSpacing = meta.SliceThickness;
    end
end

function v = get_num(info, name, defaultValue)
    if isfield(info, name)
        v = double(info.(name));
    else
        v = defaultValue;
    end
end

function s = get_str(info, name)
    if isfield(info, name)
        s = char(string(info.(name)));
    else
        s = '';
    end
end
