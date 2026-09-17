namespace CT3D.Core;

public sealed class SliceImage
{
    public SliceImage(
        float[] pixels,
        int width,
        int height,
        double spacingX,
        double spacingY)
    {
        ArgumentNullException.ThrowIfNull(pixels);

        if (width <= 0 || height <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(width));
        }

        if (pixels.Length != checked(width * height))
        {
            throw new ArgumentException(
                "Pixel count must match the image dimensions.",
                nameof(pixels));
        }

        Pixels = pixels;
        Width = width;
        Height = height;
        SpacingX = spacingX;
        SpacingY = spacingY;
    }

    public float[] Pixels { get; }

    public int Width { get; }

    public int Height { get; }

    public double SpacingX { get; }

    public double SpacingY { get; }
}
