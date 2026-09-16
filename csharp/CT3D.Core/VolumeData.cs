namespace CT3D.Core;

public sealed class VolumeData
{
    public VolumeData(
        float[] voxels,
        int width,
        int height,
        int depth,
        double spacingX,
        double spacingY,
        double spacingZ)
    {
        ArgumentNullException.ThrowIfNull(voxels);

        if (width <= 0 || height <= 0 || depth <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(width),
                "Volume dimensions must be positive.");
        }

        if (voxels.Length != checked(width * height * depth))
        {
            throw new ArgumentException(
                "Voxel count must match the volume dimensions.",
                nameof(voxels));
        }

        if (spacingX <= 0 || spacingY <= 0 || spacingZ <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(spacingX),
                "Voxel spacing must be positive.");
        }

        Voxels = voxels;
        Width = width;
        Height = height;
        Depth = depth;
        SpacingX = spacingX;
        SpacingY = spacingY;
        SpacingZ = spacingZ;
    }

    public float[] Voxels { get; }

    public int Width { get; }

    public int Height { get; }

    public int Depth { get; }

    public double SpacingX { get; }

    public double SpacingY { get; }

    public double SpacingZ { get; }

    public int GetIndex(int x, int y, int z)
    {
        if ((uint)x >= (uint)Width ||
            (uint)y >= (uint)Height ||
            (uint)z >= (uint)Depth)
        {
            throw new ArgumentOutOfRangeException(
                nameof(x),
                "Voxel coordinates are outside the volume.");
        }

        return x + Width * (y + Height * z);
    }

    public float this[int x, int y, int z] => Voxels[GetIndex(x, y, z)];
}
