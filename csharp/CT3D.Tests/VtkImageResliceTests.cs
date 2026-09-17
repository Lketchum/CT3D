using CT3D.Core;
using CT3D.Rendering;

namespace CT3D.Tests;

public sealed class VtkImageResliceTests
{
    [Fact]
    public void OrthogonalAndObliqueResliceProduceImages()
    {
        var volume = new VolumeData(
            Enumerable.Range(0, 27).Select(i => (float)i).ToArray(),
            width: 3,
            height: 3,
            depth: 3,
            spacingX: 1,
            spacingY: 1,
            spacingZ: 1);

        var reslice = new VtkImageReslice();
        reslice.SetInputData(volume);

        var axial = reslice.ResliceOrthogonal(MprPlane.Axial, 1, 1, SlabMode.Mean);
        var oblique = reslice.ResliceObliqueDegrees(1, 1, 1, 30, outSize: 16);

        Assert.Equal(3, axial.Width);
        Assert.Equal(3, axial.Height);
        Assert.Equal(16, oblique.Width);
        Assert.Equal(16, oblique.Height);
    }
}
