using CT3D.Core;
using CT3D.Dicom;
using CT3D.Rendering;
using Microsoft.Win32;
using System.Globalization;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media.Imaging;

namespace CT3D.App;

public partial class MainWindow : Window
{
    private readonly DicomSeriesReader _seriesReader = new();
    private readonly VtkImageReslice _reslice = new();
    private VolumeData? _volume;
    private double _windowWidth = 2000;
    private double _windowCenter = 500;
    private bool _updatingUi;

    public MainWindow()
    {
        InitializeComponent();
        WindowPreset.SelectedIndex = 0;
    }

    private async void OpenSeriesButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        var dialog = new OpenFolderDialog
        {
            Title = "选择 DICOM 序列文件夹",
            Multiselect = false
        };

        if (dialog.ShowDialog(this) != true)
        {
            return;
        }

        OpenSeriesButton.IsEnabled = false;
        SetSlidersEnabled(false);
        StatusText.Text = "正在读取 DICOM 序列…";
        LoadProgress.Value = 0;
        LoadProgress.Visibility = Visibility.Visible;

        var progress = new Progress<DicomLoadProgress>(update =>
        {
            LoadProgress.Value = update.Total == 0
                ? 0
                : update.Completed * 100.0 / update.Total;
            StatusText.Text = update.Stage == DicomLoadStage.Scanning
                ? $"正在扫描 DICOM：{update.Completed} / {update.Total}"
                : $"正在解码 CT：{update.Completed} / {update.Total}";
        });

        try
        {
            _volume = await Task.Run(
                () => _seriesReader.LoadAsync(dialog.FolderName, progress));
            _reslice.SetInputData(_volume);

            _updatingUi = true;
            SliderX.Minimum = 0;
            SliderX.Maximum = _volume.Width - 1;
            SliderX.Value = (_volume.Width - 1) / 2.0;
            SliderY.Minimum = 0;
            SliderY.Maximum = _volume.Height - 1;
            SliderY.Value = (_volume.Height - 1) / 2.0;
            SliderZ.Minimum = 0;
            SliderZ.Maximum = _volume.Depth - 1;
            SliderZ.Value = (_volume.Depth - 1) / 2.0;
            _updatingUi = false;

            SetSlidersEnabled(true);
            EmptyStateText.Visibility = Visibility.Collapsed;
            StatusText.Text =
                $"{_volume.Width} × {_volume.Height} × {_volume.Depth}，" +
                $"spacing {_volume.SpacingX:F2} × " +
                $"{_volume.SpacingY:F2} × {_volume.SpacingZ:F2} mm";
            RenderAllViews();
        }
        catch (Exception exception)
        {
            _volume = null;
            StatusText.Text = "加载失败";
            MessageBox.Show(
                this,
                exception.Message,
                "DICOM 加载错误",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
        finally
        {
            OpenSeriesButton.IsEnabled = true;
            LoadProgress.Visibility = Visibility.Collapsed;
        }
    }

    private void LinkedSlider_ValueChanged(
        object sender,
        RoutedPropertyChangedEventArgs<double> e)
    {
        if (_updatingUi || _volume is null)
        {
            return;
        }

        RenderAllViews();
    }

    private void WindowPreset_SelectionChanged(
        object sender,
        SelectionChangedEventArgs e)
    {
        if (WindowPreset.SelectedItem is not ComboBoxItem item ||
            item.Tag is not string preset)
        {
            return;
        }

        var values = preset.Split(',');
        _windowWidth = double.Parse(values[0], CultureInfo.InvariantCulture);
        _windowCenter = double.Parse(values[1], CultureInfo.InvariantCulture);
        RenderAllViews();
    }

    private void SlabSettings_Changed(object sender, SelectionChangedEventArgs e)
    {
        RenderAllViews();
    }

    private void ObliqueAngleSlider_ValueChanged(
        object sender,
        RoutedPropertyChangedEventArgs<double> e)
    {
        if (ObliqueAngleText is not null)
        {
            ObliqueAngleText.Text = $"{ObliqueAngleSlider.Value:0}°";
        }

        RenderAllViews();
    }

    private void RenderAllViews()
    {
        if (_volume is null ||
            AxialImage is null ||
            CoronalImage is null ||
            SagittalImage is null ||
            ObliqueImage is null)
        {
            return;
        }

        var x = (int)Math.Round(SliderX.Value);
        var y = (int)Math.Round(SliderY.Value);
        var z = (int)Math.Round(SliderZ.Value);
        var slab = GetSelectedSlab();
        var mode = GetSelectedSlabMode();

        TextX.Text = $"{x + 1} / {_volume.Width}";
        TextY.Text = $"{y + 1} / {_volume.Height}";
        TextZ.Text = $"{z + 1} / {_volume.Depth}";

        AxialImage.Source = ToBitmap(
            _reslice.ResliceOrthogonal(MprPlane.Axial, z, slab, mode));
        CoronalImage.Source = ToBitmap(
            _reslice.ResliceOrthogonal(MprPlane.Coronal, y, slab, mode));
        SagittalImage.Source = ToBitmap(
            _reslice.ResliceOrthogonal(MprPlane.Sagittal, x, slab, mode));
        ObliqueImage.Source = ToBitmap(
            _reslice.ResliceObliqueDegrees(
                x,
                y,
                z,
                ObliqueAngleSlider.Value));
    }

    private BitmapSource ToBitmap(SliceImage slice)
    {
        var pixels = WindowLevel.ToDisplayBytes(
            slice,
            _windowWidth,
            _windowCenter);

        // Encode physical spacing into DPI so Uniform stretch keeps aspect.
        var dpiX = 25.4 / slice.SpacingX;
        var dpiY = 25.4 / slice.SpacingY;
        var bitmap = BitmapSource.Create(
            slice.Width,
            slice.Height,
            dpiX,
            dpiY,
            System.Windows.Media.PixelFormats.Gray8,
            null,
            pixels,
            slice.Width);

        bitmap.Freeze();
        return bitmap;
    }

    private int GetSelectedSlab()
    {
        if (SlabCombo?.SelectedItem is ComboBoxItem item &&
            int.TryParse(Convert.ToString(item.Content), out var slab))
        {
            return slab;
        }

        return 1;
    }

    private SlabMode GetSelectedSlabMode()
    {
        if (SlabModeCombo?.SelectedItem is ComboBoxItem item &&
            string.Equals(
                Convert.ToString(item.Content),
                "mip",
                StringComparison.OrdinalIgnoreCase))
        {
            return SlabMode.Mip;
        }

        return SlabMode.Mean;
    }

    private void SetSlidersEnabled(bool enabled)
    {
        SliderX.IsEnabled = enabled;
        SliderY.IsEnabled = enabled;
        SliderZ.IsEnabled = enabled;
    }
}
