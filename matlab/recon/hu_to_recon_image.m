function img = hu_to_recon_image(hu, huMin, huMax)
%HU_TO_RECON_IMAGE  Clip HU and scale to [0, 1] for Radon / FBP.
    if nargin < 2 || isempty(huMin)
        huMin = -1000;
    end
    if nargin < 3 || isempty(huMax)
        huMax = 400;
    end
    img = (double(hu) - huMin) / (huMax - huMin);
    img = min(max(img, 0), 1);
end
