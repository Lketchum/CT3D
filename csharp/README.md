# CT3D C# Workstation

.NET 8 migration of the MATLAB teaching / viewer pipeline.

## Projects

- `CT3D.Core`: volume data, windowing, orthogonal MPR, slab, oblique trilinear
- `CT3D.Dicom`: DICOM series loading with fo-dicom
- `CT3D.Rendering`: VTK-style `VtkImageReslice` facade over Core MPR
- `CT3D.App`: WPF linked axial / coronal / sagittal / oblique views
- `CT3D.Tests`: core and reslice tests

## Run

```powershell
dotnet run --project csharp/CT3D.App
```

## Current MPR capabilities

| Feature | MATLAB | C# WPF |
|---|---|---|
| Axial | yes | yes |
| Coronal / Sagittal | yes | yes |
| Linked X/Y/Z indices | viewer | yes |
| Slab mean / MIP | viewer | yes |
| Oblique + trilinear | teach t03 | yes |

## VTK note

Official Kitware ActiViz (`Kitware.VTK`) is commercial and is not published as a free nuget.org package.
`CT3D.Rendering.VtkImageReslice` mirrors the `vtkImageData` + `vtkImageReslice` workflow in managed C# so WPF can already use MPR; swapping to native ActiViz later should only require replacing this facade.

## Current limits

- One frame per DICOM file
- 8-bit or 16-bit monochrome pixels
- Uncompressed transfer syntaxes
- Oblique preview is a single tilt-about-X plane (same idea as teach/t03)
- Marching Cubes / volume rendering are still future milestones
