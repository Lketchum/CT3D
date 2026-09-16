# CT3D C# Workstation

Initial .NET 8 migration of the MATLAB teaching pipeline.

## Projects

- `CT3D.Core`: contiguous 3D volume data, HU windowing, and later MPR/mesh algorithms
- `CT3D.Dicom`: DICOM series loading with fo-dicom
- `CT3D.App`: Windows WPF workstation shell
- `CT3D.Tests`: core algorithm tests

## Run

```powershell
dotnet run --project csharp/CT3D.App
```

Choose a directory containing one uncompressed axial CT DICOM file per slice.
The initial reader sorts slices by projected patient position, converts stored
values to HU, and displays the selected axial slice.

## Current limits

- One frame per DICOM file
- 8-bit or 16-bit monochrome pixels
- Uncompressed transfer syntaxes
- Axial preview only; MPR and Marching Cubes are the next milestones
