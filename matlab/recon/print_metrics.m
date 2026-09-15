function print_metrics(label, m)
%PRINT_METRICS  One-line metric dump for the command window.
    fprintf('  %-18s  RMSE=%.4f  MAE=%.4f  PCC=%.4f  SSIM=%.4f\n', ...
        label, m.rmse, m.mae, m.pcc, m.ssim);
end
