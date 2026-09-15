classdef CTSliceViewer < handle
    %CTSLICEVIEWER  Browse DICOM slices with sliders and a 3D volume model.

    properties
        DataRoot
        SeriesList
        Vol
        Meta
        Idx
        WindowCenter = 40
        WindowWidth = 400
        Slab = 1
        SlabMode = 'mean'
        ActiveView = 'axial'
        Mode3D = 'Bone'
    end

    properties (Access = private)
        Fig
        DropSeries
        LblStatus
        SliderC
        SliderW
        DropPreset
        DropSlab
        DropMode
        Drop3D
        SliderZ
        SliderY
        SliderX
        SpinZ
        SpinY
        SpinX
        LblZ
        AxAxial
        AxCoronal
        AxSagittal
        ImAxial
        ImCoronal
        ImSagittal
        LineAxX
        LineAxY
        LineCorX
        LineCorY
        LineSagX
        LineSagY
        Panel3D
        Viewer3D
        VolumeObj
        Ax3D
        UseVolshow = false
        Updating = false
        Hu3DMin = -1000
        Hu3DMax = 1500
    end

    methods
        function obj = CTSliceViewer(dataRoot)
            if nargin < 1 || isempty(dataRoot)
                error('dataRoot is required');
            end
            obj.DataRoot = dataRoot;
            obj.build_ui();
            obj.refresh_series_list();
            obj.try_load_default();
        end
    end

    methods (Access = private)
        function build_ui(obj)
            obj.Fig = uifigure('Name', 'CT Volume Workstation', ...
                'Position', [40 40 1380 860], ...
                'Color', [0.12 0.12 0.12]);
            obj.Fig.WindowScrollWheelFcn = @(~, evt) obj.on_scroll(evt);
            obj.Fig.KeyPressFcn = @(~, evt) obj.on_key(evt);

            root = uigridlayout(obj.Fig, [3, 1]);
            root.RowHeight = {86, '1.35x', '1x'};
            root.ColumnWidth = {'1x'};
            root.BackgroundColor = [0.12 0.12 0.12];
            root.Padding = [8 8 8 8];
            root.RowSpacing = 6;

            ctrl = uigridlayout(root, [2, 10]);
            ctrl.ColumnWidth = {58, '1.4x', 64, 58, 110, 48, 70, 80, 90, 110};
            ctrl.RowHeight = {30, 40};
            ctrl.BackgroundColor = [0.12 0.12 0.12];

            uilabel(ctrl, 'Text', 'Series', 'FontColor', [0.9 0.9 0.9]);
            obj.DropSeries = uidropdown(ctrl, 'ValueChangedFcn', @(~, ~) obj.on_load());
            uibutton(ctrl, 'Text', 'Load', 'ButtonPushedFcn', @(~, ~) obj.on_load());
            uilabel(ctrl, 'Text', 'Window', 'FontColor', [0.9 0.9 0.9]);
            names = {ct_window_presets().name};
            obj.DropPreset = uidropdown(ctrl, 'Items', names, 'Value', 'Soft tissue', ...
                'ValueChangedFcn', @(~, ~) obj.on_preset());
            uilabel(ctrl, 'Text', 'Slab', 'FontColor', [0.9 0.9 0.9]);
            obj.DropSlab = uidropdown(ctrl, 'Items', {'1', '3', '5', '7'}, 'Value', '1', ...
                'ValueChangedFcn', @(~, ~) obj.on_slab());
            obj.DropMode = uidropdown(ctrl, 'Items', {'mean', 'mip'}, 'Value', 'mean', ...
                'ValueChangedFcn', @(~, ~) obj.on_slab());
            uilabel(ctrl, 'Text', '3D model', 'FontColor', [0.9 0.9 0.9]);
            obj.Drop3D = uidropdown(ctrl, 'Items', {'Bone', 'Skin', 'Volume render', 'MIP'}, ...
                'Value', 'Bone', 'ValueChangedFcn', @(~, ~) obj.on_3d_mode());

            lblC = uilabel(ctrl, 'Text', 'Center', 'FontColor', [0.85 0.85 0.85]);
            lblC.Layout.Row = 2;
            obj.SliderC = uislider(ctrl, 'Limits', [-1200 2000], 'Value', obj.WindowCenter, ...
                'ValueChangedFcn', @(~, ~) obj.on_window(), 'FontColor', [0.8 0.8 0.8]);
            obj.SliderC.Layout.Row = 2;
            obj.SliderC.Layout.Column = [2 4];
            lblW = uilabel(ctrl, 'Text', 'Width', 'FontColor', [0.85 0.85 0.85]);
            lblW.Layout.Row = 2;
            lblW.Layout.Column = 5;
            obj.SliderW = uislider(ctrl, 'Limits', [50 4000], 'Value', obj.WindowWidth, ...
                'ValueChangedFcn', @(~, ~) obj.on_window(), 'FontColor', [0.8 0.8 0.8]);
            obj.SliderW.Layout.Row = 2;
            obj.SliderW.Layout.Column = [6 8];
            obj.LblStatus = uilabel(ctrl, 'Text', 'Drag the DICOM slice slider under the axial view.', ...
                'FontColor', [0.9 0.85 0.4]);
            obj.LblStatus.Layout.Row = 2;
            obj.LblStatus.Layout.Column = [9 10];

            mid = uigridlayout(root, [1, 2]);
            mid.ColumnWidth = {'1.15x', '1x'};
            mid.BackgroundColor = [0.08 0.08 0.08];
            axialPanel = obj.make_view_panel(mid, 'Axial  |  drag to change DICOM slice');
            obj.AxAxial = axialPanel.Ax;
            obj.SliderZ = axialPanel.Slider;
            obj.SpinZ = axialPanel.Spin;
            obj.LblZ = axialPanel.Label;
            obj.SliderZ.ValueChangingFcn = @(~, evt) obj.on_slice_changing('z', evt.Value);
            obj.SliderZ.ValueChangedFcn = @(src, ~) obj.on_slice_changed('z', src.Value);
            obj.SpinZ.ValueChangedFcn = @(src, ~) obj.on_slice_changed('z', src.Value);

            obj.Panel3D = uipanel(mid, 'Title', '3D volume model (from stacked DICOM)', ...
                'ForegroundColor', [0.95 0.95 0.95], 'BackgroundColor', [0.05 0.05 0.05]);
            obj.build_3d_host(obj.Panel3D);

            bot = uigridlayout(root, [1, 2]);
            bot.BackgroundColor = [0.08 0.08 0.08];
            corPanel = obj.make_view_panel(bot, 'Coronal  |  front-back');
            obj.AxCoronal = corPanel.Ax;
            obj.SliderY = corPanel.Slider;
            obj.SpinY = corPanel.Spin;
            obj.SliderY.ValueChangingFcn = @(~, evt) obj.on_slice_changing('y', evt.Value);
            obj.SliderY.ValueChangedFcn = @(src, ~) obj.on_slice_changed('y', src.Value);
            obj.SpinY.ValueChangedFcn = @(src, ~) obj.on_slice_changed('y', src.Value);

            sagPanel = obj.make_view_panel(bot, 'Sagittal  |  left-right');
            obj.AxSagittal = sagPanel.Ax;
            obj.SliderX = sagPanel.Slider;
            obj.SpinX = sagPanel.Spin;
            obj.SliderX.ValueChangingFcn = @(~, evt) obj.on_slice_changing('x', evt.Value);
            obj.SliderX.ValueChangedFcn = @(src, ~) obj.on_slice_changed('x', src.Value);
            obj.SpinX.ValueChangedFcn = @(src, ~) obj.on_slice_changed('x', src.Value);

            obj.style_axes(obj.AxAxial, '');
            obj.style_axes(obj.AxCoronal, '');
            obj.style_axes(obj.AxSagittal, '');
            obj.ImAxial = imagesc(obj.AxAxial, 0);
            obj.ImCoronal = imagesc(obj.AxCoronal, 0);
            obj.ImSagittal = imagesc(obj.AxSagittal, 0);
            colormap(obj.AxAxial, gray);
            colormap(obj.AxCoronal, gray);
            colormap(obj.AxSagittal, gray);
            hold(obj.AxAxial, 'on');
            hold(obj.AxCoronal, 'on');
            hold(obj.AxSagittal, 'on');
            obj.LineAxX = xline(obj.AxAxial, 1, 'r-', 'LineWidth', 0.8);
            obj.LineAxY = yline(obj.AxAxial, 1, 'r-', 'LineWidth', 0.8);
            obj.LineCorX = xline(obj.AxCoronal, 1, 'r-', 'LineWidth', 0.8);
            obj.LineCorY = yline(obj.AxCoronal, 1, 'r-', 'LineWidth', 0.8);
            obj.LineSagX = xline(obj.AxSagittal, 1, 'r-', 'LineWidth', 0.8);
            obj.LineSagY = yline(obj.AxSagittal, 1, 'r-', 'LineWidth', 0.8);
            obj.ImAxial.ButtonDownFcn = @(~, ~) obj.on_click('axial');
            obj.ImCoronal.ButtonDownFcn = @(~, ~) obj.on_click('coronal');
            obj.ImSagittal.ButtonDownFcn = @(~, ~) obj.on_click('sagittal');
        end

        function panel = make_view_panel(~, parent, titleText)
            wrap = uigridlayout(parent, [2, 1]);
            wrap.RowHeight = {'1x', 52};
            wrap.Padding = [2 2 2 2];
            wrap.BackgroundColor = [0.08 0.08 0.08];
            panel.Ax = uiaxes(wrap);
            row = uigridlayout(wrap, [1, 3]);
            row.ColumnWidth = {170, '1x', 80};
            row.BackgroundColor = [0.12 0.12 0.12];
            panel.Label = uilabel(row, 'Text', titleText, 'FontColor', [1 0.92 0.45], ...
                'FontWeight', 'bold');
            panel.Slider = uislider(row, 'Limits', [1 10], 'Value', 1, ...
                'MajorTicks', [], 'FontColor', [0.9 0.9 0.9]);
            panel.Spin = uispinner(row, 'Limits', [1 10], 'Value', 1, 'Step', 1, ...
                'RoundFractionalValues', 'on');
        end

        function build_3d_host(obj, parent)
            try
                obj.Viewer3D = viewer3d(parent);
                obj.Viewer3D.BackgroundColor = [0.05 0.05 0.08];
                obj.UseVolshow = true;
            catch
                obj.UseVolshow = false;
                obj.Ax3D = uiaxes(parent);
                obj.Ax3D.Color = [0.05 0.05 0.08];
                title(obj.Ax3D, '3D model', 'Color', [0.9 0.9 0.9]);
            end
        end

        function style_axes(~, ax, titleText)
            ax.Color = [0 0 0];
            ax.XColor = [0.6 0.6 0.6];
            ax.YColor = [0.6 0.6 0.6];
            ax.Title.String = titleText;
            ax.Title.Color = [0.9 0.9 0.9];
            ax.Toolbar.Visible = 'off';
            disableDefaultInteractivity(ax);
            axis(ax, 'image');
            ax.YDir = 'reverse';
        end

        function refresh_series_list(obj)
            obj.LblStatus.Text = 'Scanning OrigCTData ...';
            drawnow;
            obj.SeriesList = discover_axial_ct_series(obj.DataRoot);
            if isempty(obj.SeriesList)
                obj.DropSeries.Items = {'(no axial CT found)'};
                obj.LblStatus.Text = 'No axial CT series found under data/OrigCTData.';
                return;
            end
            labels = cell(numel(obj.SeriesList), 1);
            for i = 1:numel(obj.SeriesList)
                labels{i} = sprintf('%s  |  %d slices  |  %s', ...
                    obj.short_name(obj.SeriesList(i).path), ...
                    obj.SeriesList(i).nFiles, ...
                    obj.SeriesList(i).description);
            end
            obj.DropSeries.Items = labels;
            obj.DropSeries.ItemsData = 1:numel(obj.SeriesList);
            obj.DropSeries.Value = 1;
            obj.LblStatus.Text = sprintf('Found %d series. Drag DICOM slice slider under Axial.', numel(obj.SeriesList));
        end

        function try_load_default(obj)
            if isempty(obj.SeriesList)
                return;
            end
            prefer = fullfile('MSB-05167', '1959-12-18-CT_Chest-92091', '3-AXIAL ST 3.0 X 3.0-47508');
            for i = 1:numel(obj.SeriesList)
                if contains(obj.SeriesList(i).path, prefer)
                    obj.DropSeries.Value = i;
                    break;
                end
            end
            obj.on_load();
        end

        function on_load(obj)
            if isempty(obj.SeriesList)
                return;
            end
            i = obj.DropSeries.Value;
            seriesDir = obj.SeriesList(i).path;
            obj.LblStatus.Text = sprintf('Loading %s ...', seriesDir);
            drawnow;
            [obj.Vol, obj.Meta] = load_dicom_volume(seriesDir);
            obj.Idx = [round(obj.Meta.Rows / 2), round(obj.Meta.Columns / 2), round(obj.Meta.nSlices / 2)];
            obj.setup_slice_controls();
            obj.rebuild_3d();
            obj.redraw(true);
        end

        function setup_slice_controls(obj)
            nR = obj.Meta.Rows;
            nC = obj.Meta.Columns;
            nS = obj.Meta.nSlices;
            obj.SliderZ.Limits = [1 nS];
            obj.SliderY.Limits = [1 nR];
            obj.SliderX.Limits = [1 nC];
            obj.SpinZ.Limits = [1 nS];
            obj.SpinY.Limits = [1 nR];
            obj.SpinX.Limits = [1 nC];
            obj.SliderZ.MajorTicks = unique(round(linspace(1, nS, min(6, nS))));
            obj.SliderY.MajorTicks = unique(round(linspace(1, nR, min(6, nR))));
            obj.SliderX.MajorTicks = unique(round(linspace(1, nC, min(6, nC))));
        end

        function on_preset(obj)
            presets = ct_window_presets();
            names = {presets.name};
            k = find(strcmp(obj.DropPreset.Value, names), 1);
            obj.WindowCenter = presets(k).center;
            obj.WindowWidth = presets(k).width;
            obj.SliderC.Value = obj.WindowCenter;
            obj.SliderW.Value = obj.WindowWidth;
            obj.redraw(false);
        end

        function on_window(obj)
            obj.WindowCenter = obj.SliderC.Value;
            obj.WindowWidth = obj.SliderW.Value;
            obj.redraw(false);
        end

        function on_slab(obj)
            obj.Slab = str2double(obj.DropSlab.Value);
            obj.SlabMode = obj.DropMode.Value;
            obj.redraw(false);
        end

        function on_3d_mode(obj)
            obj.Mode3D = obj.Drop3D.Value;
            obj.apply_3d_style();
        end

        function on_slice_changing(obj, axisName, value)
            obj.apply_slice(axisName, value);
        end

        function on_slice_changed(obj, axisName, value)
            obj.apply_slice(axisName, value);
        end

        function apply_slice(obj, axisName, value)
            if isempty(obj.Vol) || obj.Updating
                return;
            end
            value = round(value);
            switch axisName
                case 'z'
                    obj.Idx(3) = value;
                    obj.ActiveView = 'axial';
                case 'y'
                    obj.Idx(1) = value;
                    obj.ActiveView = 'coronal';
                case 'x'
                    obj.Idx(2) = value;
                    obj.ActiveView = 'sagittal';
            end
            obj.clamp_idx();
            obj.redraw(false);
        end

        function on_click(obj, viewName)
            obj.ActiveView = viewName;
            if isempty(obj.Vol)
                return;
            end
            switch viewName
                case 'axial'
                    pt = obj.AxAxial.CurrentPoint;
                    obj.Idx(2) = round(pt(1, 1));
                    obj.Idx(1) = round(pt(1, 2));
                case 'coronal'
                    pt = obj.AxCoronal.CurrentPoint;
                    obj.Idx(2) = round(pt(1, 1));
                    obj.Idx(3) = round(pt(1, 2));
                case 'sagittal'
                    pt = obj.AxSagittal.CurrentPoint;
                    obj.Idx(1) = round(pt(1, 1));
                    obj.Idx(3) = round(pt(1, 2));
            end
            obj.clamp_idx();
            obj.redraw(false);
        end

        function on_scroll(obj, evt)
            if isempty(obj.Vol)
                return;
            end
            step = sign(evt.VerticalScrollCount);
            if step == 0
                return;
            end
            switch obj.ActiveView
                case 'axial'
                    obj.Idx(3) = obj.Idx(3) + step;
                case 'coronal'
                    obj.Idx(1) = obj.Idx(1) + step;
                case 'sagittal'
                    obj.Idx(2) = obj.Idx(2) + step;
            end
            obj.clamp_idx();
            obj.redraw(false);
        end

        function on_key(obj, evt)
            if isempty(obj.Vol)
                return;
            end
            switch evt.Key
                case 'uparrow'
                    obj.Idx(3) = obj.Idx(3) - 1;
                case 'downarrow'
                    obj.Idx(3) = obj.Idx(3) + 1;
                case 'leftarrow'
                    obj.Idx(2) = obj.Idx(2) - 1;
                case 'rightarrow'
                    obj.Idx(2) = obj.Idx(2) + 1;
                otherwise
                    return;
            end
            obj.clamp_idx();
            obj.redraw(false);
        end

        function rebuild_3d(obj)
            if isempty(obj.Vol)
                return;
            end
            [volSmall, voxelSize] = prepare_volume_render(obj.Vol, obj.Meta, 160);
            volN = normalize_hu_volume(volSmall, obj.Hu3DMin, obj.Hu3DMax);
            if obj.UseVolshow
                if ~isempty(obj.VolumeObj) && isvalid(obj.VolumeObj)
                    delete(obj.VolumeObj);
                end
                obj.VolumeObj = volshow(permute(volN, [2 1 3]), 'Parent', obj.Viewer3D);
                tform = affinetform3d(diag([voxelSize(2), voxelSize(1), voxelSize(3), 1]));
                try
                    obj.VolumeObj.Transformation = tform;
                catch
                end
                obj.apply_3d_style();
            else
                obj.draw_isosurface_axes();
            end
        end

        function apply_3d_style(obj)
            if ~obj.UseVolshow || isempty(obj.VolumeObj) || ~isvalid(obj.VolumeObj)
                if ~obj.UseVolshow
                    obj.draw_isosurface_axes();
                end
                return;
            end
            switch obj.Mode3D
                case 'Bone'
                    obj.VolumeObj.RenderingStyle = 'Isosurface';
                    obj.VolumeObj.IsosurfaceValue = obj.hu_to_norm(300);
                    obj.VolumeObj.Colormap = bone(256);
                case 'Skin'
                    obj.VolumeObj.RenderingStyle = 'Isosurface';
                    obj.VolumeObj.IsosurfaceValue = obj.hu_to_norm(-200);
                    obj.VolumeObj.Colormap = repmat([0.92 0.82 0.72], 256, 1);
                case 'Volume render'
                    obj.VolumeObj.RenderingStyle = 'GradientOpacity';
                    obj.VolumeObj.Colormap = gray(256);
                case 'MIP'
                    obj.VolumeObj.RenderingStyle = 'MaximumIntensityProjection';
                    obj.VolumeObj.Colormap = gray(256);
            end
        end

        function draw_isosurface_axes(obj)
            if isempty(obj.Ax3D) || ~isvalid(obj.Ax3D)
                return;
            end
            cla(obj.Ax3D);
            if strcmp(obj.Mode3D, 'Skin')
                thresh = -200;
                col = [0.92 0.82 0.72];
            else
                thresh = 300;
                col = [0.93 0.93 0.90];
            end
            [faces, verts] = ct_isosurface(obj.Vol, obj.Meta, thresh);
            if isempty(faces)
                title(obj.Ax3D, 'No surface at this HU', 'Color', [0.9 0.9 0.9]);
                return;
            end
            p = patch(obj.Ax3D, 'Faces', faces, 'Vertices', verts, ...
                'FaceColor', col, 'EdgeColor', 'none', 'FaceAlpha', 0.95); %#ok<NASGU>
            view(obj.Ax3D, 35, 18);
            axis(obj.Ax3D, 'equal', 'off', 'tight');
            camlight(obj.Ax3D, 'headlight');
            lighting(obj.Ax3D, 'gouraud');
            rotate3d(obj.Ax3D, 'on');
            title(obj.Ax3D, sprintf('3D %s  (rotate with mouse)', obj.Mode3D), 'Color', [0.9 0.9 0.9]);
        end

        function v = hu_to_norm(obj, hu)
            v = (hu - obj.Hu3DMin) / (obj.Hu3DMax - obj.Hu3DMin);
            v = min(max(v, 0.02), 0.98);
        end

        function redraw(obj, resetLimits)
            if isempty(obj.Vol)
                return;
            end
            [axImg, corImg, sagImg] = extract_mpr_planes(obj.Vol, obj.Idx, obj.Slab, obj.SlabMode);
            clim = window_clim(obj.WindowCenter, obj.WindowWidth);
            obj.ImAxial.CData = axImg;
            obj.ImCoronal.CData = corImg;
            obj.ImSagittal.CData = sagImg;
            obj.AxAxial.CLim = clim;
            obj.AxCoronal.CLim = clim;
            obj.AxSagittal.CLim = clim;

            if resetLimits
                obj.ImAxial.XData = [1 size(axImg, 2)];
                obj.ImAxial.YData = [1 size(axImg, 1)];
                obj.ImCoronal.XData = [1 size(corImg, 2)];
                obj.ImCoronal.YData = [1 size(corImg, 1)];
                obj.ImSagittal.XData = [1 size(sagImg, 2)];
                obj.ImSagittal.YData = [1 size(sagImg, 1)];
                axis(obj.AxAxial, 'image');
                axis(obj.AxCoronal, 'image');
                axis(obj.AxSagittal, 'image');
                obj.apply_aspect();
            end

            obj.LineAxX.Value = obj.Idx(2);
            obj.LineAxY.Value = obj.Idx(1);
            obj.LineCorX.Value = obj.Idx(2);
            obj.LineCorY.Value = obj.Idx(3);
            obj.LineSagX.Value = obj.Idx(1);
            obj.LineSagY.Value = obj.Idx(3);

            obj.Updating = true;
            obj.SliderZ.Value = obj.Idx(3);
            obj.SliderY.Value = obj.Idx(1);
            obj.SliderX.Value = obj.Idx(2);
            obj.SpinZ.Value = obj.Idx(3);
            obj.SpinY.Value = obj.Idx(1);
            obj.SpinX.Value = obj.Idx(2);
            obj.Updating = false;

            obj.LblZ.Text = sprintf('DICOM slice  %d / %d', obj.Idx(3), obj.Meta.nSlices);

            hu = obj.Vol(obj.Idx(1), obj.Idx(2), obj.Idx(3));
            obj.LblStatus.Text = sprintf( ...
                'DICOM %d/%d | HU=%d | (y,x,z)=(%d,%d,%d) | C=%.0f W=%.0f', ...
                obj.Idx(3), obj.Meta.nSlices, round(hu), ...
                obj.Idx(1), obj.Idx(2), obj.Idx(3), obj.WindowCenter, obj.WindowWidth);
        end

        function apply_aspect(obj)
            pxy = obj.Meta.PixelSpacing(:)';
            if numel(pxy) < 2 || any(isnan(pxy))
                pxy = [1 1];
            end
            pz = obj.Meta.SliceThickness;
            if isnan(pz) || pz <= 0
                pz = 1;
            end
            daspect(obj.AxAxial, [pxy(2), pxy(1), 1]);
            daspect(obj.AxCoronal, [pxy(2), pz, 1]);
            daspect(obj.AxSagittal, [pxy(1), pz, 1]);
        end

        function clamp_idx(obj)
            obj.Idx(1) = min(max(obj.Idx(1), 1), size(obj.Vol, 1));
            obj.Idx(2) = min(max(obj.Idx(2), 1), size(obj.Vol, 2));
            obj.Idx(3) = min(max(obj.Idx(3), 1), size(obj.Vol, 3));
        end
    end

    methods (Static)
        function name = short_name(seriesDir)
            parts = split(string(seriesDir), filesep);
            if numel(parts) >= 3
                name = char(strjoin(parts(end-2:end), ' / '));
            else
                name = char(parts(end));
            end
        end
    end
end
