function outDir = teach_out_dir()
%TEACH_OUT_DIR  data/processed/teach
    thisDir = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(fileparts(thisDir));
    outDir = fullfile(repoRoot, 'data', 'processed', 'teach');
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end
end
