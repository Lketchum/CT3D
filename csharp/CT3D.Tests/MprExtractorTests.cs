using CT3D.Core;

namespace CT3D.Tests;

public sealed class MprExtractorTests
{
    [Fact]
    public void AxialMatchesVolumeSlice()
    {
        var volume = CreateRampVolume();
        var slice = MprExtractor.ExtractAxisAligned(volume, MprPlane.Axial, 1);

        Assert.Equal(2, slice.Width);
        Assert.Equal(2, slice.Height);
        Assert.Equal(volume[0, 0, 1], slice.Pixels[0]);
        Assert.Equal(volume[1, 0, 1], slice.Pixels[1]);
        Assert.Equal(volume[0, 1, 1], slice.Pixels[2]);
        Assert.Equal(volume[1, 1, 1], slice.Pixels[3]);
    }

    [Fact]
    public void CoronalUsesPhysicalSpacingZ()
    {
        var volume = CreateRampVolume();
        var slice = MprExtractor.ExtractAxisAligned(volume, MprPlane.Coronal, 0);

        Assert.Equal(2, slice.Width);
        Assert.Equal(2, slice.Height);
        Assert.Equal(1.0, slice.SpacingX);
        Assert.Equal(2.0, slice.SpacingY);
        Assert.Equal(volume[0, 0, 1], slice.Pixels[0]);
        Assert.Equal(volume[0, 0, 0], slice.Pixels[2]);
    }

    [Fact]
    public void SagittalMipUsesMaximumAlongX()
    {
        var voxels = new float[]
        {
            1, 9,
            2, 3,
            4, 5,
            6, 7
        };
        var volume = new VolumeData(
            voxels,
            width: 2,
            height: 2,
            depth: 2,
            spacingX: 1,
            spacingY: 1,
            spacingZ: 1);

        var slice = MprExtractor.ExtractAxisAligned(
            volume,
            MprPlane.Sagittal,
            index: 0,
            slabThickness: 3,
            slabMode: SlabMode.Mip);

        Assert.Equal(9, slice.Pixels[2]);
    }

    [Fact]
    public void ObliqueSamplesCenterVoxel()
    {
        var voxels = new float[16];
        for (var i = 8; i < 12; i++)
        {
            voxels[i] = 42;
        }

        var volume = new VolumeData(
            voxels,
            width: 2,
            height: 2,
            depth: 4,
            spacingX: 1,
            spacingY: 1,
            spacingZ: 1);

        var slice = MprExtractor.ExtractOblique(
            volume,
            originXMm: 0.5,
            originYMm: 0.5,
            originZMm: 2.0,
            normalX: 0,
            normalY: 0,
            normalZ: 1,
            uAxisX: 1,
            uAxisY: 0,
            uAxisZ: 0,
            outWidth: 3,
            outHeight: 3,
            outSpacingMm: 1);

        Assert.Equal(42, slice.Pixels[4], 1);
    }

    private static VolumeData CreateRampVolume()
    {
        var voxels = new float[8];
        for (var z = 0; z < 2; z++)
        {
            for (var y = 0; y < 2; y++)
            {
                for (var x = 0; x < 2; x++)
                {
                    voxels[x + 2 * (y + 2 * z)] = x + 10 * y + 100 * z;
                }
            }
        }

        return new VolumeData(
            voxels,
            width: 2,
            height: 2,
            depth: 2,
            spacingX: 1,
            spacingY: 1,
            spacingZ: 2);
    }
}
