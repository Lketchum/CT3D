function hu = stored_to_hu(stored, slope, intercept)
%STORED_TO_HU  Convert DICOM stored pixels to Hounsfield Units.
%
%   Formula (DICOM Rescale):
%       HU = stored * RescaleSlope + RescaleIntercept
%
%   Typical CT: slope=1, intercept=-1024
%   Air ~ -1000 HU, water = 0 HU, bone >> +200 HU

    hu = double(stored) * double(slope) + double(intercept);
end
