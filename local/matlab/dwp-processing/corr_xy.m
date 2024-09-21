function [xcomp, ycomp] = corr_xy(ts_table0, ts_table1, xfact, yfact, sample_px)

% check if ts_table0 and ts_table1 are tables, otherwise convert them
if istable(ts_table0) == 0 && ischar(ts_table0) == 1
    ts_table0 = readtable(ts_table0, ...
        'preservevariablenames', true);
end
if istable(ts_table1) == 0 && ischar(ts_table1) == 1
    ts_table1 = readtable(ts_table1, ...
        'preservevariablenames', true);
end

if nargin < 4
    sample_px = 20;
end

% get the maximum values of ts_table0 and ts_table1
max_x0 = max(ts_table0{:, 'x [nm]'});
max_y0 = max(ts_table0{:, 'y [nm]'});
max_x1 = max(ts_table1{:, 'x [nm]'})*xfact;
max_y1 = max(ts_table1{:, 'y [nm]'})*yfact;

% % get the sample values of ts_table0 and ts_table1
% n_frames = max(ts_table0{:, 'frame'});
% x0 = ts_table0{ts_table0{:, 'frame'} > n_frames - 1000, 'x [nm]'};
% y0 = ts_table0{ts_table0{:, 'frame'} > n_frames - 1000, 'y [nm]'};
% x1 = ts_table1{ts_table1{:, 'frame'} > n_frames - 1000, 'x [nm]'}*xfact;
% y1 = ts_table1{ts_table1{:, 'frame'} > n_frames - 1000, 'y [nm]'}*yfact;

x0 = ts_table0{:, 'x [nm]'};
y0 = ts_table0{:, 'y [nm]'};
x1 = ts_table1{:, 'x [nm]'}*xfact;
y1 = ts_table1{:, 'y [nm]'}*yfact;

% check if ash2 is a function, otherwise fall back to using histcounts2
if exist('ash2', 'file') == 2
    im0 = ash2(x0, y0, sample_px, [0, max(max_x0,max_x1)], [0, max(max_y0,max_y1)])';
    im1 = ash2(x1, y1, sample_px, [0, max(max_x0,max_x1)], [0, max(max_y0,max_y1)])';
else
    im0 = bighistcounts2(x0, y0, 'binwidth', [sample_px, sample_px], 'xbinlimits', [0, max(max_x0,max_x1)], 'ybinlimits', [0, max(max_y0,max_y1)])';
    im1 = bighistcounts2(x1, y1, 'binwidth', [sample_px, sample_px], 'xbinlimits', [0, max(max_x0,max_x1)], 'ybinlimits', [0, max(max_y0,max_y1)])';
end

% perform cross correlation on the images
corr_im = normxcorr2(im0, im1);

% perform a low pass filter on the cross correlation image
corr_im = imgaussfilt(corr_im, 50);

[ypeak, xpeak] = find(corr_im == max(corr_im(:)));
xcomp = -(xpeak-size(im0,2))*sample_px;
ycomp = -(ypeak-size(im0,1))*sample_px;

end