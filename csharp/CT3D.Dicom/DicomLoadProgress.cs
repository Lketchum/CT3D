namespace CT3D.Dicom;

public enum DicomLoadStage
{
    Scanning,
    Decoding
}

public sealed record DicomLoadProgress(
    DicomLoadStage Stage,
    int Completed,
    int Total);
