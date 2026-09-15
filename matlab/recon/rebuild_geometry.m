function parameter = rebuild_geometry(parameter)
%REBUILD_GEOMETRY  Recompute derived sizes and voxel/detector grids.
%   Call after changing nx/ny/nz/nu/nv or physical spacings.

    parameter.DSR = parameter.DSD - parameter.DDR;
    parameter.sx = parameter.nx .* parameter.dx;
    parameter.sy = parameter.ny .* parameter.dy;
    parameter.sz = (parameter.nz .* parameter.dz) + parameter.DAG;
    parameter.su = parameter.nu .* parameter.du;
    parameter.sv = parameter.nv .* parameter.dv;

    parameter.xs = (parameter.nx - 1:-1:0) * parameter.dx;
    parameter.ys = (-(parameter.ny - 1) / 2:1:(parameter.ny - 1) / 2) * parameter.dy;
    parameter.zs = (0:1:parameter.nz - 1) * parameter.dz + parameter.DAG;
    parameter.us = (parameter.nu - 1:-1:0) * parameter.du;
    parameter.vs = (-(parameter.nv - 1) / 2:1:(parameter.nv - 1) / 2) * parameter.dv;

    parameter.tubeDeg = linspace(-parameter.tubeAngle / 2, parameter.tubeAngle / 2, parameter.nProj);
    parameter.detectorDeg = linspace(-parameter.detAngle / 2, parameter.detAngle / 2, parameter.nProj);
    parameter.sliceRange = 1:parameter.nz;
    parameter.iROI = 1:parameter.ny;
    parameter.jROI = 1:parameter.nx;
end
