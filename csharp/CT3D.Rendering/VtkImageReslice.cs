using CT3D.Core;

namespace CT3D.Rendering;

/// <summary>
/// Managed stand-in for vtkImageData + vtkImageReslice.
/// Official ActiViz (Kitware.VTK) is commercial and not on nuget.org;
/// this type mirrors the VTK reslice workflow so the app can later swap
/// to native VTK without rewriting the WPF layer.
/// </summary>
public sealed class VtkImageReslice
{
    private VolumeData? _volume;

    public void SetInputData(VolumeData volume)
    {
        ArgumentNullException.ThrowIfNull(volume);
        _volume = volume;
    }

    public SliceImage ResliceOrthogonal(
        MprPlane plane,
        int index,
        int slabThickness = 1,
        SlabMode slabMode = SlabMode.Mean)
    {
        EnsureVolume();
        return MprExtractor.ExtractAxisAligned(
            _volume!,
            plane,
            index,
            slabThickness,
            slabMode);
    }

    public SliceImage ResliceObliqueDegrees(
        int x,
        int y,
        int z,
        double tiltDegreesAboutX,
        int outSize = 192)
    {
        EnsureVolume();
        var volume = _volume!;

        x = Math.Clamp(x, 0, volume.Width - 1);
        y = Math.Clamp(y, 0, volume.Height - 1);
        z = Math.Clamp(z, 0, volume.Depth - 1);

        var angle = tiltDegreesAboutX * Math.PI / 180.0;
        var originX = x * volume.SpacingX;
        var originY = y * volume.SpacingY;
        var originZ = z * volume.SpacingZ;
        var outSpacing = Math.Min(
            volume.SpacingX,
            Math.Min(volume.SpacingY, volume.SpacingZ));

        // Matches teach/t03: rotate the cut normal about X.
        return MprExtractor.ExtractOblique(
            volume,
            originX,
            originY,
            originZ,
            normalX: 0,
            normalY: Math.Sin(angle),
            normalZ: Math.Cos(angle),
            uAxisX: 1,
            uAxisY: 0,
            uAxisZ: 0,
            outWidth: outSize,
            outHeight: outSize,
            outSpacingMm: outSpacing);
    }

    private void EnsureVolume()
    {
        if (_volume is null)
        {
            throw new InvalidOperationException(
                "Call SetInputData before reslicing.");
        }
    }
}
