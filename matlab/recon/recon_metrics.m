function m = recon_metrics(ref, rec)
%RECON_METRICS  RMSE / MAE / PCC / SSIM between phantom and reconstruction.

    ref = double(ref);
    rec = double(rec);
    err = rec - ref;
    m.rmse = sqrt(mean(err(:).^2));
    m.mae = mean(abs(err(:)));
    c = corrcoef(ref(:), rec(:));
    m.pcc = c(1, 2);
    if exist('ssim', 'file') == 2
        m.ssim = ssim(rec, ref);
    else
        m.ssim = NaN;
    end
end
