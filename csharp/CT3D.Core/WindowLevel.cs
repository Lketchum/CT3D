namespace CT3D.Core;

public static class WindowLevel
{
    public static byte[] CreateAxialSlice(
        VolumeData volume,
        int sliceIndex,
        double windowWidth,
        double windowCenter)
    {
        ArgumentNullException.ThrowIfNull(volume);

        if ((uint)sliceIndex >= (uint)volume.Depth)
        {
            throw new ArgumentOutOfRangeException(nameof(sliceIndex));
        }

        if (windowWidth <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(windowWidth),
                "Window width must be positive.");
        }

        var pixels = new byte[checked(volume.Width * volume.Height)];
        var lower = windowCenter - windowWidth / 2.0;
        var sourceOffset = sliceIndex * volume.Width * volume.Height;

        for (var index = 0; index < pixels.Length; index++)
        {
            var normalized =
                (volume.Voxels[sourceOffset + index] - lower) / windowWidth;
            var value = Math.Round(
                normalized * 255.0,
                MidpointRounding.AwayFromZero);
            pixels[index] = (byte)Math.Clamp(value, 0, 255);
        }

        return pixels;
    }
}
