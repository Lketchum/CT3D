function seriesDir = default_teach_series()
%DEFAULT_TEACH_SERIES  Resolve a chest axial series under data/OrigCTData.
    thisDir = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(fileparts(thisDir));
    dataRoot = fullfile(repoRoot, 'data', 'OrigCTData');
    seriesDir = fullfile(dataRoot, 'cmb_aml', 'MSB-05167', ...
        '1959-12-18-CT_Chest-92091', '3-AXIAL ST 3.0 X 3.0-47508');
    if isfolder(seriesDir)
        return;
    end
    files = dir(fullfile(dataRoot, '**', '*.dcm'));
    if isempty(files)
        error('No DICOM under %s', dataRoot);
    end
    % Pick folder with most .dcm (likely a volume series)
    folders = unique({files.folder});
    counts = cellfun(@(f) numel(dir(fullfile(f, '*.dcm'))), folders);
    [~, i] = max(counts);
    seriesDir = folders{i};
end
