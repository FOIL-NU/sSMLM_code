% Zeroth and First Order CSVs should be placed into folders labeled
% tsezeroth and tsefirst, respectively, within the root folder of a given 
% experiment. Spectral and axial calibration files should be placed in the 
% root folder as well

clear; clc;

root_path = 'PATH_TO_FILE';

filenames = dir(fullfile(root_path,'tsefirst','*.csv')); 
filelist = {filenames.name}';

if ~isfolder(fullfile(root_path,'tsoutput'))
    mkdir(fullfile(root_path,'tsoutput'));
end

% open a file to output some text
fid = fopen(fullfile(root_path,'matching_log.txt'),'a');
fprintf(fid, 'Running analyze_batch.m -- %s\n', ...
    datestr(now,'yyyy-mm-dd HH:MM:SS'));

for ii = 1:height(filenames)
    filename = filelist{ii};
    filename = filename(1:end-6);

    fname_out = fullfile(root_path,'tsoutput',sprintf('%s.csv',filename));
    fname_png = fullfile(root_path,'tsoutput',sprintf('%s.png',filename));
    fname_hist = fullfile(root_path,'tsoutput',sprintf('%s_hist.png',filename));
    fname_speccali = fullfile(root_path,'speccali.mat');

    if ~isfile(fname_out)
        fprintf(fid, 'Processing %s\n',filename);

        fname0 = fullfile(root_path,'tsezeroth',sprintf('%s_0',filename));
        fname1 = fullfile(root_path,'tsefirst',sprintf('%s_1',filename));
        
        % run the image processing code
        [tsoutput, recon_im, corr] = processfile(fname0, fname1, 'odwp',...
            'order0_roi', [0, 0, 380, 366], ...
            'order1_roi', [942, 0, 410, 366], ...
            'corr', [1.000, 1.000, -1490, -1380], ... % Remove this parameter to process with Auto-Alignment
            'speccali_path', fname_speccali, ...  % Remove this parameter to process without speccali
            'plot_hist', true);
                
        % save the processed thunderstorm data
        writetable(tsoutput,fname_out);

        % save the reconstructed image
        imwrite(recon_im',fname_png);

        % save the figure plotted by weihong_analyze
        formatfig(gcf, 'presentation', fname_hist);
        
        % write the correction factors to the log file
        fprintf(fid, 'using automatic alignment\n');
        fprintf(fid, 'corr = [%.03f, %.03f, %d, %d]\n\n', corr);
    else
        fprintf('%s already exists. Skipping.\n',fname_out);
    end
end

fclose(fid);