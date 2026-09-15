function seriesList = discover_axial_ct_series(rootDir)
%DISCOVER_AXIAL_CT_SERIES  Find CT folders with enough slices for a volume.
%   Skips scout / topogram / angio folders (too few slices or name match).

    if nargin < 1 || isempty(rootDir)
        error('rootDir is required');
    end

    folders = unique(find_dcm_folders(rootDir));
    skipPat = '(scout|topogram|angio|mip)';
    keep = false(numel(folders), 1);
    nFiles = zeros(numel(folders), 1);
    desc = strings(numel(folders), 1);
    modality = strings(numel(folders), 1);

    for i = 1:numel(folders)
        d = dir(fullfile(folders{i}, '*.dcm'));
        nFiles(i) = numel(d);
        if nFiles(i) < 16
            continue;
        end
        try
            info = dicominfo(fullfile(folders{i}, d(1).name));
        catch
            continue;
        end
        if ~isfield(info, 'Modality') || ~strcmpi(strtrim(info.Modality), 'CT')
            continue;
        end
        if isfield(info, 'SeriesDescription')
            desc(i) = string(info.SeriesDescription);
        else
            desc(i) = "";
        end
        modality(i) = string(info.Modality);
        nameBlob = lower(strjoin([desc(i), string(folders{i})], ' '));
        if ~isempty(regexp(nameBlob, skipPat, 'once'))
            continue;
        end
        if isfield(info, 'ImageOrientationPatient')
            iop = info.ImageOrientationPatient(:)';
            if ~is_axial_iop(iop)
                continue;
            end
        end
        keep(i) = true;
    end

    folders = folders(keep);
    nFiles = nFiles(keep);
    desc = desc(keep);
    [nFiles, order] = sort(nFiles, 'descend');
    folders = folders(order);
    desc = desc(order);

    seriesList = struct('path', folders, 'nFiles', num2cell(nFiles), 'description', cellstr(desc));
end

function folders = find_dcm_folders(rootDir)
    files = dir(fullfile(rootDir, '**', '*.dcm'));
    folders = cell(numel(files), 1);
    for i = 1:numel(files)
        folders{i} = files(i).folder;
    end
end

function tf = is_axial_iop(iop)
    % Axial: row ~ [1 0 0], col ~ [0 1 0]
    target = [1 0 0 0 1 0];
    tf = norm(iop - target) < 0.15 || norm(iop + target) < 0.15;
end
