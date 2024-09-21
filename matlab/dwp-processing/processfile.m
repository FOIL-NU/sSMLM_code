function [ts_output, recon_im, corr] = processfile(csvpath_0, csvpath_1, img_type, varargin)
% processfiles v3

% create an input parser
parser = inputParser;

% define the default values
default_corr_pxsz = 10;
default_recon_pxsz = 20;
default_img_pxsz = 110;
default_zcali_path = nan;
default_plot_hist = false;
default_central_wavelength = 700;

% define the optional parameters
addParameter(parser, 'corr_pxsz', default_corr_pxsz, @isnumeric);
addParameter(parser, 'recon_pxsz', default_recon_pxsz, @isnumeric);
addParameter(parser, 'img_pxsz', default_img_pxsz, @isnumeric);
addParameter(parser, 'zcali_path', default_zcali_path, @ischar);
addParameter(parser, 'speccali_path', nan, @ischar);
addParameter(parser, 'plot_hist', default_plot_hist, @islogical);
addParameter(parser, 'order0_roi', nan(1,4), @isnumeric);
addParameter(parser, 'order1_roi', nan(1,4), @isnumeric);
addParameter(parser, 'central_wavelength', default_central_wavelength, @isnumeric);

% parse the input
parse(parser, varargin{:});

% extract the optional parameters
corr_pxsz = parser.Results.corr_pxsz;
recon_pxsz = parser.Results.recon_pxsz;
img_pxsz = parser.Results.img_pxsz;
zcali_path = parser.Results.zcali_path;
speccali_path = parser.Results.speccali_path;
plot_hist = parser.Results.plot_hist;
order0_roi = parser.Results.order0_roi;
order1_roi = parser.Results.order1_roi;
central_wavelength = parser.Results.central_wavelength;

if nargin < 3
    error('specify image type');
else
    % check if img_type is a string
    if ~ischar(img_type)
        error('img_type must be a string');
    end
end

if nargin < 2
    error('specify csv path for 1st order');
else
    % check if csvpath_1 is a csv file
    if ~strcmpi(csvpath_1(end-3:end), '.csv')
        % append .csv to the end of the file
        csvpath_1 = [csvpath_1, '.csv'];
    end
end

if nargin < 1
    error('specify csv path for 0th order');
else
    % check if csvpath_0 is a csv file
    if ~strcmpi(csvpath_0(end-3:end), '.csv')
        % append .csv to the end of the file
        csvpath_0 = [csvpath_0, '.csv'];
    end
end

% print that reading the csv files
fprintf('Reading the csv files...\n');
ts_table0 = readtable(csvpath_0,'preservevariablenames',true);
ts_table1 = readtable(csvpath_1,'preservevariablenames',true);

% load the spectral calibration file
if ~isnan(speccali_path)
    speccali = load(speccali_path);
    speccali = speccali.speccali;
else
    speccali = nan;
end

if isstruct(speccali)
    % find the closest wavelength to the central wavelength
    [~, idx] = min(abs(speccali.wavelengths - central_wavelength));

    if all(isnan(order0_roi)) || all(isnan(order1_roi))
        mid_x0 = (min(ts_table0{:, 'x [nm]'}) + max(ts_table0{:, 'x [nm]'})) / 2;
        mid_y0 = (min(ts_table0{:, 'y [nm]'}) + max(ts_table0{:, 'y [nm]'})) / 2;
    else
        mid_x0 = (order0_roi(1) + (order0_roi(3)) / 2) * img_pxsz;
        mid_y0 = (order0_roi(2) + (order0_roi(4)) / 2) * img_pxsz;
        xoff = (order1_roi(1) - order0_roi(1)) * img_pxsz;
        % yoff = (order1_roi(2) - order0_roi(2)) * img_pxsz;
    end

    ts_table0{:, 'x [nm]'} = (ts_table0{:, 'x [nm]'} - mid_x0) .* speccali.xscale(idx) + mid_x0;
    ts_table0{:, 'y [nm]'} = (ts_table0{:, 'y [nm]'} - mid_y0) .* speccali.yscale(idx) + mid_y0;
else
    warning('No spectral calibration file found');
end

% correct the x and y values of the 1st order
[xcomp, ycomp] = corr_xy(ts_table0, ts_table1, 1, 1, corr_pxsz);

if isstruct(speccali)
    corr = [speccali.xscale(idx), speccali.yscale(idx), xcomp, ycomp];
else
    corr = [1, 1, xcomp, ycomp];
end

% correct the x1 and y1 values with the correction factors
ts_table1{:, 'x [nm]'} = ts_table1{:, 'x [nm]'} + xcomp;
ts_table1{:, 'y [nm]'} = ts_table1{:, 'y [nm]'} + ycomp;

% sort the tables by frame
ts_table0 = sortrows(ts_table0, 'frame');
ts_table1 = sortrows(ts_table1, 'frame');

[matched_idx0, matched_idx1] = matchlocalizations(ts_table0, ts_table1);

% filter the localizations by the matched indices
tsnew_table0 = ts_table0(ismember(ts_table0{:, 'id'}, matched_idx0), :);
tsnew_table1 = ts_table1(ismember(ts_table1{:, 'id'}, matched_idx1), :);

[~, sorted_idx0] = sort(matched_idx0);
[~, sorted_idx1] = sort(matched_idx1);
[~, inv_sorted_idx0] = sort(sorted_idx0);
[~, inv_sorted_idx1] = sort(sorted_idx1);

% sort the tables so that the indices matches matched_idx0 and matched_idx1
tsnew_table0 = tsnew_table0(inv_sorted_idx0, :);
tsnew_table1 = tsnew_table1(inv_sorted_idx1, :);

% filter the localizations where abs(y_1 - y_0) < 450 and abs(x_1 - x_0) < 2200
sel = (abs(tsnew_table1{:, 'y [nm]'} - tsnew_table0{:, 'y [nm]'}) < 450) & ...
    (abs(tsnew_table1{:, 'x [nm]'} - tsnew_table0{:, 'x [nm]'}) < 2200);

if plot_hist == true
    % analyze the matching histograms after filtering
    figure(1); clf;
    subplot(2,2,1); hold on;
    histogram(tsnew_table1{:,'x [nm]'} - tsnew_table0{:,'x [nm]'},'binwidth',10);
    xlabel('x position (nm)');
    ylabel('count');
    title('x position histograms');

    subplot(2,2,3); hold on;
    histogram(tsnew_table1{:,'y [nm]'} - tsnew_table0{:,'y [nm]'},'binwidth',10);
    xlabel('y position (nm)');
    ylabel('count');
    title('y position histograms');

    tsnew_table0 = tsnew_table0(sel, :);
    tsnew_table1 = tsnew_table1(sel, :);

    subplot(2,2,2); hold on;
    histogram(tsnew_table1{:,'x [nm]'} - tsnew_table0{:,'x [nm]'},'binwidth',10);
    xlabel('x position (nm)');
    ylabel('count');
    title('x position histograms');

    subplot(2,2,4); hold on;
    histogram(tsnew_table1{:,'y [nm]'} - tsnew_table0{:,'y [nm]'},'binwidth',10);
    xlabel('y position (nm)');
    ylabel('count');
    title('y position histograms');
end

% prepare the output file

% make a new table with the following headers:
% id, frame, x [nm], y [nm], z [nm], centroid [nm], sigmax0 [nm], ...
% sigmay0 [nm], sigmax1 [nm], sigmay1 [nm], uncertainty [nm], ...
% uncertainty0 [nm], uncertainty1 [nm], intensity [photon], ...
% intensity0 [photon], intensity1 [photon], offset [photon], ...
% offset0 [photon],  offset1 [photon], bkgstd [photon], ...
% bkgstd0 [photon], bkgstd1 [photon]

ts_output = table('Size', [length(tsnew_table0{:, 'frame'}), 22], ...
    'VariableNames', {'id', 'frame', ...
    'x [nm]', 'y [nm]', 'z [nm]', 'centroid [nm]', ...
    'sigmax0 [nm]', 'sigmay0 [nm]', 'sigmax1 [nm]', 'sigmay1 [nm]', ...
    'uncertainty [nm]', 'uncertainty0 [nm]', 'uncertainty1 [nm]', ...
    'intensity [photon]', 'intensity0 [photon]', 'intensity1 [photon]', ...
    'offset [photon]', 'offset0 [photon]', 'offset1 [photon]', ...
    'bkgstd [photon]', 'bkgstd0 [photon]', 'bkgstd1 [photon]'}, ...
    'VariableTypes', {'uint32', 'uint32', 'double', 'double', 'double', ...
    'double', 'double', 'double', 'double', 'double', 'double', 'double', ...
    'double', 'double', 'double', 'double', 'double', 'double', 'double', ...
    'double', 'double', 'double'});

% fill in the values
ts_output{:, 'id'} = (1:length(tsnew_table0{:, 'frame'}))';
ts_output{:, 'frame'} = tsnew_table0{:, 'frame'};

if strcmpi(img_type, 'sdwp')
    ts_output{:, 'x [nm]'} = (tsnew_table0{:, 'x [nm]'} + ...
        tsnew_table1{:, 'x [nm]'}) / 2;
    ts_output{:, 'y [nm]'} = (tsnew_table0{:, 'y [nm]'} + ...
        tsnew_table1{:, 'y [nm]'}) / 2;
elseif strcmpi(img_type, 'odwp')
    ts_output{:, 'x [nm]'} = tsnew_table0{:, 'x [nm]'};
    ts_output{:, 'y [nm]'} = tsnew_table0{:, 'y [nm]'};
else
    error('img_type must be either sdwp or odwp');
end

if ~isnan(zcali_path)
    if ismember('sigma2 [nm]', tsnew_table0.Properties.VariableNames)
        temp_sigma0 = tsnew_table0{:, 'sigma2 [nm]'};
    else
        temp_sigma0 = tsnew_table0{:, 'sigma [nm]'};
    end
    
    if ismember('sigma2 [nm]', tsnew_table1.Properties.VariableNames)
        temp_sigma1 = tsnew_table1{:, 'sigma2 [nm]'};
    else
        temp_sigma1 = tsnew_table1{:, 'sigma [nm]'};
    end
    
    ts_output{:, 'z [nm]'} = getz(temp_sigma0, temp_sigma1, zcali_path);
else
    ts_output{:, 'z [nm]'} = nan(length(tsnew_table0{:, 'frame'}), 1);
end

if isstruct(speccali)
    ts_output{:, 'centroid [nm]'} = dwp_px2wl( ...
        (tsnew_table1{:, 'x [nm]'} - xcomp + xoff) - ...
        tsnew_table0{:, 'x [nm]'}, speccali.fx);
    % disp(mean((tsnew_table1{:, 'x [nm]'} - xcomp + xoff) - ...
    %     tsnew_table0{:, 'x [nm]'}));
    % disp(speccali.xshift);
else
    ts_output{:, 'centroid [nm]'} = tsnew_table1{:, 'x [nm]'} - tsnew_table0{:, 'x [nm]'};
end

if ismember('sigma1 [nm]', tsnew_table0.Properties.VariableNames)
    ts_output{:, 'sigmax0 [nm]'} = tsnew_table0{:, 'sigma1 [nm]'};
    ts_output{:, 'sigmay0 [nm]'} = tsnew_table0{:, 'sigma2 [nm]'};
else
    ts_output{:, 'sigmax0 [nm]'} = tsnew_table0{:, 'sigma [nm]'};
    ts_output{:, 'sigmay0 [nm]'} = tsnew_table0{:, 'sigma [nm]'};
end

if ismember('sigma1 [nm]', tsnew_table1.Properties.VariableNames)
    ts_output{:, 'sigmax1 [nm]'} = tsnew_table1{:, 'sigma1 [nm]'};
    ts_output{:, 'sigmay1 [nm]'} = tsnew_table1{:, 'sigma2 [nm]'};
else
    ts_output{:, 'sigmax1 [nm]'} = tsnew_table1{:, 'sigma [nm]'};
    ts_output{:, 'sigmay1 [nm]'} = tsnew_table1{:, 'sigma [nm]'};
end

ts_output{:, 'uncertainty0 [nm]'} = tsnew_table0{:, 'uncertainty [nm]'};
ts_output{:, 'uncertainty1 [nm]'} = tsnew_table1{:, 'uncertainty [nm]'};
% take the root mean square of the uncertainties
ts_output{:, 'uncertainty [nm]'} = rms([tsnew_table0{:, 'uncertainty [nm]'}, tsnew_table1{:, 'uncertainty [nm]'}], 2);

ts_output{:, 'intensity0 [photon]'} = tsnew_table0{:, 'intensity [photon]'};
ts_output{:, 'intensity1 [photon]'} = tsnew_table1{:, 'intensity [photon]'};
% take the mean of the intensities
ts_output{:, 'intensity [photon]'} = mean([tsnew_table0{:, 'intensity [photon]'}, tsnew_table1{:, 'intensity [photon]'}], 2);

ts_output{:, 'offset0 [photon]'} = tsnew_table0{:, 'offset [photon]'};
ts_output{:, 'offset1 [photon]'} = tsnew_table1{:, 'offset [photon]'};
% take the mean of the offsets
ts_output{:, 'offset [photon]'} = mean([tsnew_table0{:, 'offset [photon]'}, tsnew_table1{:, 'offset [photon]'}], 2);

ts_output{:, 'bkgstd0 [photon]'} = tsnew_table0{:, 'bkgstd [photon]'};
ts_output{:, 'bkgstd1 [photon]'} = tsnew_table1{:, 'bkgstd [photon]'};
% take the mean of the bkgstds
ts_output{:, 'bkgstd [photon]'} = mean([tsnew_table0{:, 'bkgstd [photon]'}, tsnew_table1{:, 'bkgstd [photon]'}], 2);

% generate a reconstructed image
recon_im = ash2(ts_output{:,'x [nm]'}, ts_output{:,'y [nm]'}, recon_pxsz);

end


function [matched_idx0, matched_idx1] = matchlocalizations(ts_table0, ts_table1)
% extract the frames of the tables
frame0 = ts_table0{:, 'frame'};
frame1 = ts_table1{:, 'frame'};

n_frames = max([frame0; frame1]);

% extract the indices of the tables
idx0 = ts_table0{:, 'id'};
idx1 = ts_table1{:, 'id'};

% intialize the variables to store pairs of closest localizations
matched_idx0 = nan(min([length(idx0), length(idx1)]), 1);
matched_idx1 = nan(min([length(idx0), length(idx1)]), 1);
curr_idx = 1;

% print that we are matching the localizations
upd = textprogressbar(n_frames, 'startmsg', 'Matching localizations: ', 'showbar', true');

for i_frame = 1:n_frames
    % get the localizations in the current frame
    curr_idx0 = find(frame0 == i_frame);
    curr_idx1 = find(frame1 == i_frame);

    % get the temporary index of the current frame
    tmp_idx0 = idx0(curr_idx0);
    tmp_idx1 = idx1(curr_idx1);
    
    % get the x and y coordinates of the current frame
    tmp_x0 = ts_table0{curr_idx0, 'x [nm]'};
    tmp_y0 = ts_table0{curr_idx0, 'y [nm]'};
    tmp_x1 = ts_table1{curr_idx1, 'x [nm]'};
    tmp_y1 = ts_table1{curr_idx1, 'y [nm]'};
    
    % find the closest localizations
    [knn_idx1, ~] = knnsearch([tmp_x0, tmp_y0], [tmp_x1, tmp_y1], 'k', 1, 'nsmethod', 'exhaustive');

    if isempty(knn_idx1)
        continue
    end
    % calculate the y distance between the matched localizations
    ydist = abs(tmp_y1 - tmp_y0(knn_idx1));

    % find repeated indices, and keep the closest one
    tmp = [tmp_idx0(knn_idx1), tmp_idx1((1:length(knn_idx1))'), ydist];
    sorted_tmp = sortrows(tmp, 3);
    [~, unique_idx] = unique(sorted_tmp(:,1), 'stable');
    unique_tmp = sorted_tmp(unique_idx, :);

    n_indices = size(unique_tmp,1);
    matched_idx0(curr_idx:curr_idx+n_indices-1) = unique_tmp(:,1);
    matched_idx1(curr_idx:curr_idx+n_indices-1) = unique_tmp(:,2);
    curr_idx = curr_idx + n_indices;

    upd(i_frame);
    
end

% remove the nan values
matched_idx0 = matched_idx0(~isnan(matched_idx0));
matched_idx1 = matched_idx1(~isnan(matched_idx1));

end