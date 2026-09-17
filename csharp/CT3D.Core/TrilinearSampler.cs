namespace CT3D.Core;

public static class TrilinearSampler
{
    public static float Sample(VolumeData volume, double x, double y, double z)
    {
        ArgumentNullException.ThrowIfNull(volume);

        if (x < 0 || y < 0 || z < 0 ||
            x > volume.Width - 1 ||
            y > volume.Height - 1 ||
            z > volume.Depth - 1)
        {
            return 0f;
        }

        var x0 = (int)Math.Floor(x);
        var y0 = (int)Math.Floor(y);
        var z0 = (int)Math.Floor(z);
        var x1 = Math.Min(x0 + 1, volume.Width - 1);
        var y1 = Math.Min(y0 + 1, volume.Height - 1);
        var z1 = Math.Min(z0 + 1, volume.Depth - 1);

        var xd = x - x0;
        var yd = y - y0;
        var zd = z - z0;

        var c000 = volume[x0, y0, z0];
        var c100 = volume[x1, y0, z0];
        var c010 = volume[x0, y1, z0];
        var c110 = volume[x1, y1, z0];
        var c001 = volume[x0, y0, z1];
        var c101 = volume[x1, y0, z1];
        var c011 = volume[x0, y1, z1];
        var c111 = volume[x1, y1, z1];

        var c00 = c000 * (1 - xd) + c100 * xd;
        var c10 = c010 * (1 - xd) + c110 * xd;
        var c01 = c001 * (1 - xd) + c101 * xd;
        var c11 = c011 * (1 - xd) + c111 * xd;

        var c0 = c00 * (1 - yd) + c10 * yd;
        var c1 = c01 * (1 - yd) + c11 * yd;

        return (float)(c0 * (1 - zd) + c1 * zd);
    }
}
