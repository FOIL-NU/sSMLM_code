function [f,x,y] = ash2(xdata,ydata,binsize,xlim,ylim,kernel)
%% ASH2 Computes the bivariate averaged shifted histograms
% |[_] = ash2(xdata,ydata)| computes the average shifted histogram of a given 
% xd|ata| and |ydata| with a |binsize| of 1 on each dimension, smoothed using 
% the default kernel.
% 
% |[_] = ash2(xdata,ydata,binsize,xlim,ylim)| additionally specifies the bin 
% limits to use on the data. If the vector is longer than 2, the extrema values 
% are used.
% 
% |[_] = ash2(xdata,ydata,binsize,xlim,ylim,kernel)| additionally specfies the 
% kernel used to average the histogram over, must be odd-lengthed on each dimension.
%% Arguments
% |xdata,ydata|  input array of x and y data to estimate the density function, 
% Nx1 vector of datapoints. Dimensions of |xdata| and |ydata| should be equal.
% 
% |binsize|      size of bins to use, scalar or 1x2 vector of |[xbinsize,ybinsize]|.
% 
% |xlim,ylim|    specifies bin limits on the data to use, 1x2 vector of |[xmin,xmax]| 
% and |[ymin,ymax]| respectively. If the vector is longer than 2, the extrema 
% values are used.
% 
% |kernel|       kernel function to use, odd sized square matrix.
%% Outputs
% |f|            output estimated density.
% 
% |x,y|          coordinates of corresponding density.
%% Changelog
%%
% 
%  2022-03-15 initial version
%  2022-03-16 change xlim to take the extrema values, split data to xdata and ydata.
%  2022-03-18 cleaned up code with arguments block, added default binsize, reordered kernel input to the last.
%  2024-03-15 changed from using histcounts2 to a custom function `bighistcounts2` to overcome the limitations of 1024 bins in histcounts2
%
arguments
    xdata {mustBeVector(xdata), mustBeNumeric(xdata)}
    ydata {mustBeVector(ydata), mustBeNumeric(ydata), mustBeEqualSize(xdata,ydata)}
    binsize {mustBeShorterThan(binsize,2)} = 1
    xlim {mustBeVector(xlim,'allow-all-empties'), mustBeNumeric(xlim)} = [min(xdata), max(xdata)]
    ylim {mustBeVector(ylim,'allow-all-empties'), mustBeNumeric(ylim)} = [min(ydata), max(ydata)]
    kernel {mustBeMatrix(kernel,'allow-all-empties'), mustBeNumeric(kernel)} = [1;2;1]*[1,2,1]
end
if isempty(binsize)
    binsize = [1,1];
elseif isscalar(binsize)
    binsize = [binsize, binsize];
end
if isempty(xlim)
    xlim = [min(xdata), max(xdata)];
else
    assert(xlim(1) <= xlim(end), 'x limit bounds should be strictly increasing.');
end
if isempty(ylim)
    ylim = [min(ydata), max(ydata)];
else 
    assert(ylim(1) <= ylim(end), 'y limit bounds should be strictly increasing.');
end
assert(all(mod(size(kernel),2) == 1),'kernel size is not odd.')
kernel = kernel / sum(kernel,'all');
xedges = ((floor(xlim(1)/binsize(1))-0.5):(ceil(xlim(end)/binsize(1))+0.5))*binsize(1);
yedges = ((floor(ylim(1)/binsize(2))-0.5):(ceil(ylim(end)/binsize(2))+0.5))*binsize(2);
n = conv2(bighistcounts2(xdata,ydata,binsize,xlim,ylim),kernel);
f = n(((size(kernel,1)+1)/2):(end-(size(kernel,1)-1)/2), ...
      ((size(kernel,2)+1)/2):(end-(size(kernel,2)-1)/2));
x = (xedges(1:end-1) + xedges(2:end)) / 2;
y = (yedges(1:end-1) + yedges(2:end)) / 2;
end
%% Custom validation functions
function mustBeEqualSize(a,b)
    % Test for equal size
    if ~isequal(size(a),size(b))
        eid = 'Size:notEqual';
        msg = 'Size of first input must equal size of second input.';
        throwAsCaller(MException(eid,msg))
    end
end
function mustBeShorterThan(A,len_max)
    % Test for size range
    if isvector(A) && (length(A) <= len_max)
        return;
    else
        eid = 'Size:wrongSize';
        msg = ['Size of input must be less than: ', num2str(len_max)];
        throwAsCaller(MException(eid,msg))
    end
end
function mustBeMatrix(A,allowEmpty)
    % Test for matrix
    if nargin == 2
        if ((ischar(allowEmpty) && isrow(allowEmpty)) || (isstring(allowEmpty) && isscalar(allowEmpty) && strlength(allowEmpty)>0)) &&...
                startsWith("allow-all-empties",allowEmpty,"IgnoreCase",true)
            if isempty(A)
                return;
            end
        else
            error(message('MATLAB:validatorUsage:invalidSecondInput','mustBeMatrix','allow-all-empties'));
        end
    end
    
    if ismatrix(A)
        return;
    end
    
    throwAsCaller(MException(message('MATLAB:validators:mustBeMatrix')));
end