function [freq, H] = ramp_freq_response(nfft, filterName, cutoff)
%RAMP_FREQ_RESPONSE  Magnitude of the 1D ramp kernel for plotting.
    impulse = zeros(nfft / 2, 1);
    impulse(round(end / 2)) = 1;
    h = apply_ramp_filter(impulse, filterName, cutoff);
    H = fftshift(abs(fft(h, nfft)));
    freq = linspace(-0.5, 0.5, nfft);
end
