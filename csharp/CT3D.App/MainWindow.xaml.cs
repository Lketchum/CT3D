using CT3D.Core;
using CT3D.Dicom;
using Microsoft.Win32;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media.Imaging;

namespace CT3D.App;

public partial class MainWindow : Window
{
    private readonly DicomSeriesReader _seriesReader = new();
    private VolumeData? _volume;
    private double _windowWidth = 2000;
    private double _windowCenter = 500;

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
        SliceSlider.IsEnabled = false;
        StatusText.Text = "正在读取 DICOM 序列…";

        try
        {
            _volume = await _seriesReader.LoadAsync(dialog.FolderName);
            SliceSlider.Minimum = 0;
            SliceSlider.Maximum = _volume.Depth - 1;
            SliceSlider.Value = (_volume.Depth - 1) / 2;
            SliceSlider.IsEnabled = true;
            EmptyStateText.Visibility = Visibility.Collapsed;
            StatusText.Text =
                $"{_volume.Width} × {_volume.Height} × {_volume.Depth}，" +
                $"spacing {_volume.SpacingX:F2} × " +
                $"{_volume.SpacingY:F2} × {_volume.SpacingZ:F2} mm";
            RenderCurrentSlice();
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
        }
    }

    private void SliceSlider_ValueChanged(
        object sender,
        RoutedPropertyChangedEventArgs<double> e)
    {
        RenderCurrentSlice();
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
        _windowWidth = double.Parse(
            values[0],
            System.Globalization.CultureInfo.InvariantCulture);
        _windowCenter = double.Parse(
            values[1],
            System.Globalization.CultureInfo.InvariantCulture);
        RenderCurrentSlice();
    }

    private void RenderCurrentSlice()
    {
        if (_volume is null || SliceImage is null || SliceText is null)
        {
            return;
        }

        var sliceIndex = Math.Clamp(
            (int)Math.Round(SliceSlider.Value),
            0,
            _volume.Depth - 1);
        var pixels = WindowLevel.CreateAxialSlice(
            _volume,
            sliceIndex,
            _windowWidth,
            _windowCenter);
        var bitmap = BitmapSource.Create(
            _volume.Width,
            _volume.Height,
            96,
            96,
            System.Windows.Media.PixelFormats.Gray8,
            null,
            pixels,
            _volume.Width);

        bitmap.Freeze();
        SliceImage.Source = bitmap;
        SliceText.Text = $"{sliceIndex + 1} / {_volume.Depth}";
    }
}