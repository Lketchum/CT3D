using CT3D.Core;

namespace CT3D.Tests;

public sealed class WindowLevelTests
{
    [Fact]
    public void AxialSliceMapsWindowToByteRange()
    {
        var volume = new VolumeData(
            [-100, 0, 100, 200],
            width: 2,
            height: 2,
            depth: 1,
            spacingX: 1,
            spacingY: 1,
            spacingZ: 1);

        var pixels = WindowLevel.CreateAxialSlice(
            volume,
            sliceIndex: 0,
            windowWidth: 200,
            windowCenter: 0);

        Assert.Equal([0, 128, 255, 255], pixels);
    }

    [Fact]
    public void AxialSliceReadsRequestedDepth()
    {
        var volume = new VolumeData(
            [-100, -100, 100, 100],
            width: 2,
            height: 1,
            depth: 2,
            spacingX: 1,
            spacingY: 1,
            spacingZ: 1);

        var pixels = WindowLevel.CreateAxialSlice(
            volume,
            sliceIndex: 1,
            windowWidth: 200,
            windowCenter: 0);

        Assert.Equal([255, 255], pixels);
    }
}
