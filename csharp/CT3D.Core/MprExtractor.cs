namespace CT3D.Core;

public static class MprExtractor
{
    public static SliceImage ExtractAxisAligned(
        VolumeData volume,
        MprPlane plane,
        int index,
        int slabThickness = 1,
        SlabMode slabMode = SlabMode.Mean)
    {
        ArgumentNullException.ThrowIfNull(volume);

        slabThickness = Math.Max(1, slabThickness);
        var half = (slabThickness - 1) / 2;

        return plane switch
        {
            MprPlane.Axial => ExtractAxial(volume, index, half, slabMode),
            MprPlane.Coronal => ExtractCoronal(volume, index, half, slabMode),
            MprPlane.Sagittal => ExtractSagittal(volume, index, half, slabMode),
            _ => throw new ArgumentOutOfRangeException(nameof(plane))
        };
    }

    public static SliceImage ExtractOblique(
        VolumeData volume,
        double originXMm,
        double originYMm,
        double originZMm,
        double normalX,
        double normalY,
        double normalZ,
        double uAxisX,
        double uAxisY,
        double uAxisZ,
        int outWidth,
        int outHeight,
        double outSpacingMm)
    {
        ArgumentNullException.ThrowIfNull(volume);

        if (outWidth <= 0 || outHeight <= 0 || outSpacingMm <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(outWidth));
        }

        Normalize(ref normalX, ref normalY, ref normalZ);
        Normalize(ref uAxisX, ref uAxisY, ref uAxisZ);

        Cross(
            normalX, normalY, normalZ,
            uAxisX, uAxisY, uAxisZ,
            out var vX, out var vY, out var vZ);

        if (Length(vX, vY, vZ) < 1e-8)
        {
            throw new ArgumentException(
                "uAxis is nearly parallel to the plane normal.");
        }

        Normalize(ref vX, ref vY, ref vZ);
        Cross(
            vX, vY, vZ,
            normalX, normalY, normalZ,
            out uAxisX, out uAxisY, out uAxisZ);
        Normalize(ref uAxisX, ref uAxisY, ref uAxisZ);

        var cu = (outWidth + 1) / 2.0;
        var cv = (outHeight + 1) / 2.0;
        var pixels = new float[checked(outWidth * outHeight)];

        for (var row = 0; row < outHeight; row++)
        {
            for (var col = 0; col < outWidth; col++)
            {
                var px =
                    originXMm +
                    (col + 1 - cu) * outSpacingMm * uAxisX +
                    (row + 1 - cv) * outSpacingMm * vX;
                var py =
                    originYMm +
                    (col + 1 - cu) * outSpacingMm * uAxisY +
                    (row + 1 - cv) * outSpacingMm * vY;
                var pz =
                    originZMm +
                    (col + 1 - cu) * outSpacingMm * uAxisZ +
                    (row + 1 - cv) * outSpacingMm * vZ;

                pixels[row * outWidth + col] = TrilinearSampler.Sample(
                    volume,
                    px / volume.SpacingX,
                    py / volume.SpacingY,
                    pz / volume.SpacingZ);
            }
        }

        return new SliceImage(
            pixels,
            outWidth,
            outHeight,
            outSpacingMm,
            outSpacingMm);
    }

    private static SliceImage ExtractAxial(
        VolumeData volume,
        int index,
        int half,
        SlabMode mode)
    {
        index = Math.Clamp(index, 0, volume.Depth - 1);
        var lo = Math.Max(0, index - half);
        var hi = Math.Min(volume.Depth - 1, index + half);
        var pixels = new float[volume.Width * volume.Height];

        for (var y = 0; y < volume.Height; y++)
        {
            for (var x = 0; x < volume.Width; x++)
            {
                pixels[y * volume.Width + x] = Aggregate(
                    mode,
                    lo,
                    hi,
                    z => volume[x, y, z]);
            }
        }

        return new SliceImage(
            pixels,
            volume.Width,
            volume.Height,
            volume.SpacingX,
            volume.SpacingY);
    }

    private static SliceImage ExtractCoronal(
        VolumeData volume,
        int index,
        int half,
        SlabMode mode)
    {
        index = Math.Clamp(index, 0, volume.Height - 1);
        var lo = Math.Max(0, index - half);
        var hi = Math.Min(volume.Height - 1, index + half);
        var pixels = new float[volume.Width * volume.Depth];

        for (var z = 0; z < volume.Depth; z++)
        {
            var row = volume.Depth - 1 - z;
            for (var x = 0; x < volume.Width; x++)
            {
                pixels[row * volume.Width + x] = Aggregate(
                    mode,
                    lo,
                    hi,
                    y => volume[x, y, z]);
            }
        }

        return new SliceImage(
            pixels,
            volume.Width,
            volume.Depth,
            volume.SpacingX,
            volume.SpacingZ);
    }

    private static SliceImage ExtractSagittal(
        VolumeData volume,
        int index,
        int half,
        SlabMode mode)
    {
        index = Math.Clamp(index, 0, volume.Width - 1);
        var lo = Math.Max(0, index - half);
        var hi = Math.Min(volume.Width - 1, index + half);
        var pixels = new float[volume.Height * volume.Depth];

        for (var z = 0; z < volume.Depth; z++)
        {
            var row = volume.Depth - 1 - z;
            for (var y = 0; y < volume.Height; y++)
            {
                pixels[row * volume.Height + y] = Aggregate(
                    mode,
                    lo,
                    hi,
                    x => volume[x, y, z]);
            }
        }

        return new SliceImage(
            pixels,
            volume.Height,
            volume.Depth,
            volume.SpacingY,
            volume.SpacingZ);
    }

    private static float Aggregate(
        SlabMode mode,
        int lo,
        int hi,
        Func<int, float> sample)
    {
        if (mode == SlabMode.Mip)
        {
            var max = float.NegativeInfinity;
            for (var i = lo; i <= hi; i++)
            {
                max = Math.Max(max, sample(i));
            }

            return float.IsNegativeInfinity(max) ? 0f : max;
        }

        double sum = 0;
        var count = 0;
        for (var i = lo; i <= hi; i++)
        {
            sum += sample(i);
            count++;
        }

        return count == 0 ? 0f : (float)(sum / count);
    }

    private static void Normalize(ref double x, ref double y, ref double z)
    {
        var length = Length(x, y, z);
        if (length < 1e-12)
        {
            throw new ArgumentException("Vector length must be positive.");
        }

        x /= length;
        y /= length;
        z /= length;
    }

    private static double Length(double x, double y, double z) =>
        Math.Sqrt(x * x + y * y + z * z);

    private static void Cross(
        double ax,
        double ay,
        double az,
        double bx,
        double by,
        double bz,
        out double cx,
        out double cy,
        out double cz)
    {
        cx = ay * bz - az * by;
        cy = az * bx - ax * bz;
        cz = ax * by - ay * bx;
    }
}
