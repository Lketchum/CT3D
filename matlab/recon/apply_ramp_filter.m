function sinoFilt = apply_ramp_filter(sino, filterName, cutoff)
%APPLY_RAMP_FILTER  1D ramp filter along the detector axis of a sinogram.
%   sino       [nDet x nAngles]
%   filterName 'ram-lak' | 'shepp-logan' | 'cosine' | 'hamming' | 'hann' | 'none'
%   cutoff     fraction of Nyquist in (0, 1], default 1
%
%   Frequency-domain design matches MATLAB iradon (Ram-Lak * window).

    if nargin < 2 || isempty(filterName)
        filterName = 'ram-lak';
    end
    if nargin < 3 || isempty(cutoff)
        cutoff = 1;
    end

    [nDet, nAng] = size(sino);
    nfft = max(64, 2^nextpow2(2 * nDet));
    H = design_ramp_kernel(nfft, filterName, cutoff);

    sinoFilt = zeros(nDet, nAng);
    for k = 1:nAng
        P = fft(sino(:, k), nfft);
        pf = real(ifft(P .* H));
        sinoFilt(:, k) = pf(1:nDet);
    end
end

function H = design_ramp_kernel(nfft, filterName, d)
    filt = 2 * (0:(nfft / 2)) / nfft;
    w = 2 * pi * (0:numel(filt) - 1) / nfft;

    switch lower(filterName)
        case {'none', 'bp'}
            filt(:) = 1;
            filt(1) = 0;
        case {'ram-lak', 'ramlak'}
            % already |omega|
        case 'shepp-logan'
            filt(2:end) = filt(2:end) .* (sin(w(2:end) / (2 * d)) ./ (w(2:end) / (2 * d)));
        case 'cosine'
            filt(2:end) = filt(2:end) .* cos(w(2:end) / (2 * d));
        case 'hamming'
            filt(2:end) = filt(2:end) .* (0.54 + 0.46 * cos(w(2:end) / d));
        case 'hann'
            filt(2:end) = filt(2:end) .* (1 + cos(w(2:end) / d)) / 2;
        otherwise
            error('Unknown filter: %s', filterName);
    end

    filt(w > pi * d) = 0;
    H = [filt, filt(end - 1:-1:2)].';
end
