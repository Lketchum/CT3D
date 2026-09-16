using CT3D.Core;

namespace CT3D.Tests;

public sealed class VolumeDataTests
{
    [Fact]
    public void IndexerUsesXFastestLayout()
    {
        var volume = new VolumeData(
            [0, 1, 2, 3, 4, 5, 6, 7],
            width: 2,
            height: 2,
            depth: 2,
            spacingX: 0.5,
            spacingY: 0.5,
            spacingZ: 1.0);

        Assert.Equal(0, volume[0, 0, 0]);
        Assert.Equal(1, volume[1, 0, 0]);
        Assert.Equal(2, volume[0, 1, 0]);
        Assert.Equal(4, volume[0, 0, 1]);
        Assert.Equal(7, volume[1, 1, 1]);
    }

    [Fact]
    public void ConstructorRejectsMismatchedVoxelCount()
    {
        Assert.Throws<ArgumentException>(() =>
            new VolumeData(
                [1, 2, 3],
                width: 2,
                height: 2,
                depth: 1,
                spacingX: 1,
                spacingY: 1,
                spacingZ: 1));
    }
}
