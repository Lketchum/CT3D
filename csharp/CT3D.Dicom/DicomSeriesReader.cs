using CT3D.Core;
using FellowOakDicom;
using FellowOakDicom.Imaging;
using FellowOakDicom.IO;

namespace CT3D.Dicom;

public sealed class DicomSeriesReader
{
    public async Task<VolumeData> LoadAsync(
        string directory,
        CancellationToken cancellationToken = default)
    {
        if (!Directory.Exists(directory))
        {
            throw new DirectoryNotFoundException(directory);
        }

        var slices = new List<SliceInfo>();

        foreach (var path in Directory.EnumerateFiles(
                     directory,
                     "*",
                     SearchOption.AllDirectories))
        {
            cancellationToken.ThrowIfCancellationRequested();

            try
            {
                var file = await DicomFile.OpenAsync(
                    path,
                    FileReadOption.ReadLargeOnDemand);
                var dataset = file.Dataset;

                if (!dataset.Contains(DicomTag.PixelData))
                {
                    continue;
                }

                slices.Add(CreateSliceInfo(path, dataset));
            }
            catch (DicomFileException)
            {
                // Ignore non-DICOM files in the selected directory.
            }
        }

        if (slices.Count == 0)
        {
            throw new InvalidDataException(
                "No DICOM images with pixel data were found.");
        }

        slices.Sort(static (left, right) =>
        {
            var positionOrder = left.Position.CompareTo(right.Position);
            return positionOrder != 0
                ? positionOrder
                : left.InstanceNumber.CompareTo(right.InstanceNumber);
        });

        ValidateSeries(slices);

        var first = slices[0];
        var voxels = new float[
            checked(first.Width * first.Height * slices.Count)];
        var sliceSize = first.Width * first.Height;

        for (var z = 0; z < slices.Count; z++)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var file = await DicomFile.OpenAsync(slices[z].Path);
            DecodeFrame(file.Dataset, voxels.AsSpan(z * sliceSize, sliceSize));
        }

        return new VolumeData(
            voxels,
            first.Width,
            first.Height,
            slices.Count,
            first.SpacingX,
            first.SpacingY,
            CalculateSpacingZ(slices));
    }

    private static SliceInfo CreateSliceInfo(
        string path,
        DicomDataset dataset)
    {
        var pixelData = DicomPixelData.Create(dataset);

        if (pixelData.NumberOfFrames != 1)
        {
            throw new NotSupportedException(
                "The initial reader supports one frame per DICOM file.");
        }

        var pixelSpacing = dataset.GetValues<double>(DicomTag.PixelSpacing);
        var orientation = dataset.GetValues<double>(
            DicomTag.ImageOrientationPatient);
        var imagePosition = dataset.GetValues<double>(
            DicomTag.ImagePositionPatient);

        if (pixelSpacing.Length < 2 ||
            orientation.Length < 6 ||
            imagePosition.Length < 3)
        {
            throw new InvalidDataException(
                $"Required spatial metadata is missing in '{path}'.");
        }

        var normalX =
            orientation[1] * orientation[5] -
            orientation[2] * orientation[4];
        var normalY =
            orientation[2] * orientation[3] -
            orientation[0] * orientation[5];
        var normalZ =
            orientation[0] * orientation[4] -
            orientation[1] * orientation[3];
        var projectedPosition =
            imagePosition[0] * normalX +
            imagePosition[1] * normalY +
            imagePosition[2] * normalZ;

        return new SliceInfo(
            path,
            pixelData.Width,
            pixelData.Height,
            pixelSpacing[1],
            pixelSpacing[0],
            projectedPosition,
            dataset.GetSingleValueOrDefault(DicomTag.InstanceNumber, 0));
    }

    private static void ValidateSeries(IReadOnlyList<SliceInfo> slices)
    {
        var first = slices[0];

        foreach (var slice in slices)
        {
            if (slice.Width != first.Width || slice.Height != first.Height)
            {
                throw new InvalidDataException(
                    "All slices must have identical dimensions.");
            }

            if (Math.Abs(slice.SpacingX - first.SpacingX) > 1e-6 ||
                Math.Abs(slice.SpacingY - first.SpacingY) > 1e-6)
            {
                throw new InvalidDataException(
                    "All slices must have identical pixel spacing.");
            }
        }
    }

    private static double CalculateSpacingZ(IReadOnlyList<SliceInfo> slices)
    {
        if (slices.Count == 1)
        {
            return 1.0;
        }

        var distances = new double[slices.Count - 1];

        for (var index = 1; index < slices.Count; index++)
        {
            distances[index - 1] = Math.Abs(
                slices[index].Position - slices[index - 1].Position);
        }

        Array.Sort(distances);
        var spacing = distances[distances.Length / 2];

        if (spacing <= 1e-6)
        {
            throw new InvalidDataException(
                "Unable to determine a positive slice spacing.");
        }

        return spacing;
    }

    private static void DecodeFrame(
        DicomDataset dataset,
        Span<float> destination)
    {
        var pixelData = DicomPixelData.Create(dataset);

        if (pixelData.Syntax.IsEncapsulated)
        {
            throw new NotSupportedException(
                "Compressed DICOM requires a fo-dicom codec package.");
        }

        if (pixelData.SamplesPerPixel != 1 ||
            pixelData.BitsAllocated is not (8 or 16))
        {
            throw new NotSupportedException(
                "Only 8-bit and 16-bit monochrome images are supported.");
        }

        var frame = pixelData.GetFrame(0).Data;
        var slope = dataset.GetSingleValueOrDefault(
            DicomTag.RescaleSlope,
            1.0);
        var intercept = dataset.GetSingleValueOrDefault(
            DicomTag.RescaleIntercept,
            0.0);

        if (destination.Length != pixelData.Width * pixelData.Height)
        {
            throw new ArgumentException(
                "Destination size does not match the DICOM frame.",
                nameof(destination));
        }

        for (var index = 0; index < destination.Length; index++)
        {
            var storedValue = pixelData.BitsAllocated == 8
                ? DecodeStoredValue(frame[index], pixelData)
                : DecodeStoredValue(
                    ReadUInt16(
                        frame,
                        index * 2,
                        pixelData.Syntax.Endian),
                    pixelData);
            destination[index] = (float)(storedValue * slope + intercept);
        }
    }

    private static ushort ReadUInt16(
        byte[] data,
        int offset,
        Endian endian)
    {
        return endian == Endian.Little
            ? (ushort)(data[offset] | data[offset + 1] << 8)
            : (ushort)(data[offset] << 8 | data[offset + 1]);
    }

    private static int DecodeStoredValue(
        int rawValue,
        DicomPixelData pixelData)
    {
        var lowBit = pixelData.HighBit - pixelData.BitsStored + 1;
        var mask = (1 << pixelData.BitsStored) - 1;
        var value = rawValue >> lowBit & mask;

        if (pixelData.PixelRepresentation == PixelRepresentation.Signed)
        {
            var signBit = 1 << (pixelData.BitsStored - 1);

            if ((value & signBit) != 0)
            {
                value -= 1 << pixelData.BitsStored;
            }
        }

        return value;
    }

    private sealed record SliceInfo(
        string Path,
        int Width,
        int Height,
        double SpacingX,
        double SpacingY,
        double Position,
        int InstanceNumber);
}
