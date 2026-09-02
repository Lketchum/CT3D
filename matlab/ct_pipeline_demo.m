function ct_pipeline_demo(dataRoot, renderMode)
% CT 3D visualization workflow for the LungCT-Diagnosis dataset.
% Example:
%   ct_pipeline_demo('E:\SelfProject\CTData\LungCT-Diagnosis')
%   ct_pipeline_demo('E:\SelfProject\CTData\LungCT-Diagnosis', 'bone')
% or simply:
%   ct_pipeline_demo

    if nargin < 1 || isempty(dataRoot)
        dataRoot = 'E:\SelfProject\CTData\LungCT-Diagnosis';
    end
    if nargin < 2 || isempty(renderMode)
        renderMode = 'all';
    end

    if ~exist(dataRoot, 'dir')
        error('CT data root does not exist: %s', dataRoot);
    end

    seriesList = findDicomSeries(dataRoot);
    if isempty(seriesList)
        error('No DICOM CT series found under %s', dataRoot);
    end

    fprintf('Found %d CT DICOM series. Loading the largest one...\n', numel(seriesList));
    for k = 1:min(5, numel(seriesList))
        fprintf('%d. %s (%d slices)\n', k, seriesList(k).folder, seriesList(k).numFiles);
        if ~isempty(seriesList(k).description)
            fprintf('   Series: %s\n', seriesList(k).description);
        end
    end

    selectedSeries = seriesList(1);
    fprintf('\nSelected series: %s\n', selectedSeries.folder);

    [volume, meta] = loadCTVolume(selectedSeries.files);
    fprintf('Volume size: [%d %d %d]\n', size(volume, 1), size(volume, 2), size(volume, 3));
    fprintf('HU range: [%.1f, %.1f]\n', min(volume(:)), max(volume(:)));

    windowCenter = 40;
    windowWidth = 400;
    voxelSpacing = estimateVoxelSpacing(meta);
    showCTOverview(volume, voxelSpacing, windowCenter, windowWidth);
    renderModes = normalizeRenderModes(renderMode);
    renderResults = showCT3D(volume, voxelSpacing, renderModes);

    outputDir = fullfile(fileparts(mfilename('fullpath')), 'output');
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    figOverview = findobj('Type', 'figure', 'Name', 'CT Volume Overview');

    if ~isempty(figOverview)
        saveas(figOverview, fullfile(outputDir, 'ct_overview.png'));
    end
    for i = 1:numel(renderResults)
        fig3D = findobj('Type', 'figure', 'Name', renderResults(i).figureName);
        if ~isempty(fig3D)
            saveas(fig3D, fullfile(outputDir, renderResults(i).fileName));
            if strcmp(renderResults(i).mode, 'body')
                saveas(fig3D, fullfile(outputDir, 'ct_3d_view.png'));
            end
        end
    end

    fprintf('\nMATLAB visualization workflow completed. Output images saved in: %s\n', outputDir);
end

function seriesList = findDicomSeries(root)
    dcmFiles = findFilesRecursive(root, '.dcm');
    seriesList = struct('uid', {}, 'folder', {}, 'description', {}, 'files', {}, 'numFiles', {});
    if isempty(dcmFiles)
        return;
    end

    seriesIndex = containers.Map('KeyType', 'char', 'ValueType', 'double');
    for i = 1:numel(dcmFiles)
        info = dicominfo(dcmFiles{i});
        modality = valueToChar(getfieldSafe(info, 'Modality', ''));
        if ~isempty(modality) && ~strcmpi(modality, 'CT')
            continue;
        end

        [folder, ~, ~] = fileparts(dcmFiles{i});
        uid = valueToChar(getfieldSafe(info, 'SeriesInstanceUID', folder));
        if isempty(uid)
            uid = folder;
        end

        if isKey(seriesIndex, uid)
            idx = seriesIndex(uid);
            seriesList(idx).files{end + 1} = dcmFiles{i};
            seriesList(idx).numFiles = numel(seriesList(idx).files);
        else
            idx = numel(seriesList) + 1;
            seriesIndex(uid) = idx;
            seriesList(idx).uid = uid;
            seriesList(idx).folder = folder;
            seriesList(idx).description = valueToChar(getfieldSafe(info, 'SeriesDescription', ''));
            seriesList(idx).files = {dcmFiles{i}};
            seriesList(idx).numFiles = 1;
        end
    end

    if ~isempty(seriesList)
        [~, order] = sort([seriesList.numFiles], 'descend');
        seriesList = seriesList(order);
    end
end

function fileList = findFilesRecursive(root, extension)
    fileList = {};
    if ~exist(root, 'dir')
        return;
    end

    d = dir(root);
    for i = 1:numel(d)
        if strcmp(d(i).name, '.') || strcmp(d(i).name, '..')
            continue;
        end

        fullPath = fullfile(root, d(i).name);
        if d(i).isdir
            nestedFiles = findFilesRecursive(fullPath, extension);
            if ~isempty(nestedFiles)
                fileList = [fileList(:); nestedFiles(:)];
            end
        else
            [~, ~, fileExt] = fileparts(fullPath);
            if strcmpi(fileExt, extension)
                fileList{end + 1} = fullPath;
            end
        end
    end
end

function [volume, meta] = loadCTVolume(dcmFiles)
    if isempty(dcmFiles)
        error('No DICOM files were provided.');
    end

    numSlices = numel(dcmFiles);
    sliceOrder = zeros(numSlices, 1);
    imageStack = cell(numSlices, 1);
    meta = struct('filename', {}, 'InstanceNumber', {}, 'ImagePositionPatient', {}, ...
        'ImageOrientationPatient', {}, 'PixelSpacing', {}, 'SliceThickness', {});
    expectedRows = [];
    expectedCols = [];

    for i = 1:numSlices
        info = dicominfo(dcmFiles{i});
        image = dicomread(dcmFiles{i});
        image = squeeze(image);
        if ndims(image) ~= 2
            error('Expected a single 2-D CT slice, but %s has image size [%s].', ...
                dcmFiles{i}, num2str(size(image)));
        end

        if isempty(expectedRows)
            expectedRows = size(image, 1);
            expectedCols = size(image, 2);
        elseif size(image, 1) ~= expectedRows || size(image, 2) ~= expectedCols
            error('Slice size mismatch in %s. Expected [%d %d], got [%d %d].', ...
                dcmFiles{i}, expectedRows, expectedCols, size(image, 1), size(image, 2));
        end

        if isfield(info, 'RescaleSlope') && isfield(info, 'RescaleIntercept')
            image = double(image) * double(info.RescaleSlope) + double(info.RescaleIntercept);
        else
            image = double(image);
        end

        imageStack{i} = image;
        if isfield(info, 'ImagePositionPatient') && numel(info.ImagePositionPatient) >= 3 ...
                && isfield(info, 'ImageOrientationPatient') && numel(info.ImageOrientationPatient) >= 6
            rowDirection = double(info.ImageOrientationPatient(1:3));
            colDirection = double(info.ImageOrientationPatient(4:6));
            sliceNormal = cross(rowDirection(:), colDirection(:));
            sliceOrder(i) = dot(double(info.ImagePositionPatient(1:3)), sliceNormal);
        elseif isfield(info, 'ImagePositionPatient') && numel(info.ImagePositionPatient) >= 3
            sliceOrder(i) = double(info.ImagePositionPatient(3));
        elseif isfield(info, 'SliceLocation')
            sliceOrder(i) = double(info.SliceLocation);
        elseif isfield(info, 'InstanceNumber')
            sliceOrder(i) = double(info.InstanceNumber);
        else
            sliceOrder(i) = i;
        end

        meta(i).filename = dcmFiles{i};
        meta(i).InstanceNumber = getfieldSafe(info, 'InstanceNumber', i);
        meta(i).ImagePositionPatient = getfieldSafe(info, 'ImagePositionPatient', [0, 0, sliceOrder(i)]);
        meta(i).ImageOrientationPatient = getfieldSafe(info, 'ImageOrientationPatient', []);
        meta(i).PixelSpacing = getfieldSafe(info, 'PixelSpacing', [1; 1]);
        meta(i).SliceThickness = getfieldSafe(info, 'SliceThickness', 1);
    end

    [~, order] = sort(sliceOrder);
    volume = zeros(size(imageStack{1}, 1), size(imageStack{1}, 2), numSlices, 'double');

    for i = 1:numSlices
        volume(:, :, i) = imageStack{order(i)};
    end

    meta = meta(order);
    fprintf('Loaded %d slices from CT series.\n', numSlices);
end

function value = getfieldSafe(structIn, fieldName, defaultValue)
    if isfield(structIn, fieldName)
        value = structIn.(fieldName);
    else
        value = defaultValue;
    end
end

function textValue = valueToChar(value)
    if ischar(value)
        textValue = value;
    elseif isstring(value)
        textValue = char(value);
    elseif isnumeric(value)
        textValue = num2str(value);
    else
        textValue = '';
    end
end

function voxelSpacing = estimateVoxelSpacing(meta)
    pixelSpacing = double(meta(1).PixelSpacing);
    if numel(pixelSpacing) < 2
        pixelSpacing = [1; 1];
    end

    sliceSpacing = double(meta(1).SliceThickness);
    if numel(meta) > 1
        positions = zeros(numel(meta), 1);
        hasPositions = true;
        for i = 1:numel(meta)
            if numel(meta(i).ImagePositionPatient) >= 3 && numel(meta(i).ImageOrientationPatient) >= 6
                rowDirection = double(meta(i).ImageOrientationPatient(1:3));
                colDirection = double(meta(i).ImageOrientationPatient(4:6));
                sliceNormal = cross(rowDirection(:), colDirection(:));
                positions(i) = dot(double(meta(i).ImagePositionPatient(1:3)), sliceNormal);
            else
                hasPositions = false;
                break;
            end
        end
        if hasPositions
            spacingFromPosition = median(abs(diff(sort(positions))));
            if spacingFromPosition > 0
                sliceSpacing = spacingFromPosition;
            end
        end
    end

    voxelSpacing = [pixelSpacing(1), pixelSpacing(2), sliceSpacing];
end

function imgOut = huWindow(img, center, width)
    img = double(img);
    lower = center - width / 2;
    upper = center + width / 2;
    imgOut = (img - lower) / (upper - lower);
    imgOut(imgOut < 0) = 0;
    imgOut(imgOut > 1) = 1;
    imgOut = uint8(255 * imgOut);
end

function showCTOverview(volume, voxelSpacing, windowCenter, windowWidth)
    [rows, cols, slices] = size(volume);
    midZ = round(slices / 2);
    midRow = round(rows / 2);
    midCol = round(cols / 2);

    axial = huWindow(squeeze(volume(:, :, midZ)), windowCenter, windowWidth);
    sagittal = huWindow(permute(squeeze(volume(:, midCol, :)), [2 1]), windowCenter, windowWidth);
    coronal = huWindow(permute(squeeze(volume(midRow, :, :)), [2 1]), windowCenter, windowWidth);

    sampleSlices = round(linspace(1, slices, min(12, slices)));
    montageFrames = cell(numel(sampleSlices), 1);
    for i = 1:numel(sampleSlices)
        montageFrames{i} = huWindow(squeeze(volume(:, :, sampleSlices(i))), windowCenter, windowWidth);
    end

    figure('Name', 'CT Volume Overview', 'Color', 'w', 'NumberTitle', 'off');
    subplot(2,2,1);
    imagesc((0:cols - 1) * voxelSpacing(2), (0:rows - 1) * voxelSpacing(1), axial);
    colormap gray;
    title('Axial');
    axis image; axis off;

    subplot(2,2,2);
    imagesc((0:rows - 1) * voxelSpacing(1), (0:slices - 1) * voxelSpacing(3), sagittal);
    title('Sagittal');
    axis image; axis off;

    subplot(2,2,3);
    imagesc((0:cols - 1) * voxelSpacing(2), (0:slices - 1) * voxelSpacing(3), coronal);
    title('Coronal');
    axis image; axis off;

    subplot(2,2,4);
    montage(montageFrames, 'Size', [1, numel(montageFrames)]);
    title('Axial Montage');
end

function renderModes = normalizeRenderModes(renderMode)
    if ischar(renderMode) || isstring(renderMode)
        renderMode = lower(strtrim(char(renderMode)));
        if strcmp(renderMode, 'all')
            renderModes = {'body', 'bone', 'lung', 'soft'};
        else
            renderModes = {renderMode};
        end
    elseif iscell(renderMode)
        renderModes = cell(size(renderMode));
        for i = 1:numel(renderMode)
            renderModes{i} = lower(strtrim(char(renderMode{i})));
        end
    else
        error('renderMode must be a string or a cell array of strings.');
    end

    validModes = {'body', 'bone', 'lung', 'soft'};
    for i = 1:numel(renderModes)
        if ~ismember(renderModes{i}, validModes)
            error('Unknown 3D render mode: %s. Valid modes are: body, bone, lung, soft, all.', renderModes{i});
        end
    end
end

function renderResults = showCT3D(volume, voxelSpacing, renderModes)
    renderResults = struct('mode', {}, 'figureName', {}, 'fileName', {});
    bodyMask = createBodyMask(volume);

    for i = 1:numel(renderModes)
        mode = renderModes{i};
        [mask, style] = createRenderMask(volume, bodyMask, mode);
        figureName = sprintf('3D CT %s Surface', upperFirst(mode));

        renderSurface(mask, voxelSpacing, figureName, style);

        renderResults(i).mode = mode;
        renderResults(i).figureName = figureName;
        renderResults(i).fileName = sprintf('ct_3d_%s.png', mode);
    end
end

function bodyMask = createBodyMask(volume)
    bodyMask = volume > -650;
    bodyMask = keepLargestComponents(bodyMask, 1);
    bodyMask = smooth3(bodyMask) > 0.5;
end

function [mask, style] = createRenderMask(volume, bodyMask, mode)
    switch mode
        case 'body'
            mask = bodyMask;
            style.color = [0.80, 0.62, 0.45];
            style.alpha = 0.35;
            style.title = '3D CT Body Surface';
        case 'bone'
            mask = volume > 250 & bodyMask;
            mask = keepLargestComponents(mask, 12);
            style.color = [0.92, 0.90, 0.82];
            style.alpha = 0.80;
            style.title = '3D CT Bone Surface';
        case 'lung'
            mask = volume > -1000 & volume < -450;
            if exist('imclearborder', 'file') == 2
                mask = imclearborder(mask, 26);
            end
            mask = keepLargestComponents(mask, 2);
            style.color = [0.30, 0.70, 0.95];
            style.alpha = 0.50;
            style.title = '3D CT Lung Surface';
        case 'soft'
            mask = volume > -300 & volume < 200 & bodyMask;
            mask = keepLargestComponents(mask, 8);
            style.color = [0.95, 0.45, 0.45];
            style.alpha = 0.32;
            style.title = '3D CT Soft Tissue Surface';
        otherwise
            error('Unsupported 3D render mode: %s.', mode);
    end

    if ~any(mask(:))
        error('3D render mode "%s" did not produce any voxels. Try another mode or threshold.', mode);
    end
end

function maskOut = keepLargestComponents(maskIn, componentCount)
    if exist('bwconncomp', 'file') ~= 2
        maskOut = maskIn;
        return;
    end

    components = bwconncomp(maskIn, 26);
    if components.NumObjects == 0
        maskOut = maskIn;
        return;
    end

    sizes = cellfun(@numel, components.PixelIdxList);
    [~, order] = sort(sizes, 'descend');
    selected = order(1:min(componentCount, numel(order)));
    maskOut = false(size(maskIn));
    for i = 1:numel(selected)
        maskOut(components.PixelIdxList{selected(i)}) = true;
    end
end

function renderSurface(mask, voxelSpacing, figureName, style)
    [rowIdx, colIdx, sliceIdx] = ind2sub(size(mask), find(mask));
    rowMin = max(1, min(rowIdx) - 10);
    rowMax = min(size(mask, 1), max(rowIdx) + 10);
    colMin = max(1, min(colIdx) - 10);
    colMax = min(size(mask, 2), max(colIdx) + 10);
    sliceMin = max(1, min(sliceIdx) - 10);
    sliceMax = min(size(mask, 3), max(sliceIdx) + 10);

    cropMask = mask(rowMin:rowMax, colMin:colMax, sliceMin:sliceMax);
    downsampleFactor = max(1, round(max(size(cropMask, 1), size(cropMask, 2)) / 160));
    cropMask = cropMask(1:downsampleFactor:end, 1:downsampleFactor:end, 1:downsampleFactor:end);
    cropMask = smooth3(cropMask) > 0.5;

    x = ((colMin - 1):downsampleFactor:(colMax - 1)) * voxelSpacing(2);
    y = ((rowMin - 1):downsampleFactor:(rowMax - 1)) * voxelSpacing(1);
    z = ((sliceMin - 1):downsampleFactor:(sliceMax - 1)) * voxelSpacing(3);
    x = x(1:size(cropMask, 2));
    y = y(1:size(cropMask, 1));
    z = z(1:size(cropMask, 3));
    [xGrid, yGrid, zGrid] = meshgrid(x, y, z);

    figure('Name', figureName, 'Color', 'w', 'NumberTitle', 'off');
    patch(isosurface(xGrid, yGrid, zGrid, cropMask, 0.5), ...
        'FaceColor', style.color, 'EdgeColor', 'none', 'FaceAlpha', style.alpha);
    axis image; grid on; view(3);
    xlabel('X (mm)'); ylabel('Y (mm)'); zlabel('Z (mm)');
    camlight('headlight'); lighting gouraud;
    title(style.title);
end

function textValue = upperFirst(textValue)
    textValue(1) = upper(textValue(1));
end
