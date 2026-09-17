namespace CT3D.Core;

public static class WindowLevel
{
    public static byte[] ToDisplayBytes(
        SliceImage slice,
        double windowWidth,
        double windowCenter)
    {
        ArgumentNullException.ThrowIfNull(slice);

        if (windowWidth <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(windowWidth),
                "Window width must be positive.");
        }

        var pixels = new byte[slice.Pixels.Length];
        var lower = windowCenter - windowWidth / 2.0;

        for (var index = 0; index < pixels.Length; index++)
        {
            var normalized = (slice.Pixels[index] - lower) / windowWidth;
            var value = Math.Round(
                normalized * 255.0,
                MidpointRounding.AwayFromZero);
            pixels[index] = (byte)Math.Clamp(value, 0, 255);
        }

        return pixels;
    }

    public static byte[] CreateAxialSlice(
        VolumeData volume,
        int sliceIndex,
        double windowWidth,
        double windowCenter)
    {
        var slice = MprExtractor.ExtractAxisAligned(
            volume,
            MprPlane.Axial,
            sliceIndex);
        return ToDisplayBytes(slice, windowWidth, windowCenter);
    }
}
