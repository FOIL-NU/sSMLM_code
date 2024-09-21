function histcounts = bighistcounts2(xdata, ydata, binsize, xlim, ylim)

numBinsX = ceil(xlim(end)/binsize(1)) - floor(xlim(1)/binsize(1));
numBinsY = ceil(ylim(end)/binsize(2)) - floor(ylim(1)/binsize(2));

idxX = max(min(floor((xdata - xlim(1)) / binsize(1)) + 1, numBinsX), 1);
idxY = max(min(floor((ydata - ylim(1)) / binsize(2)) + 1, numBinsY), 1);

linearidx = sub2ind([numBinsX, numBinsY], idxX, idxY);

histcounts = accumarray(linearidx, 1, [numBinsX*numBinsY, 1]);
histcounts = reshape(histcounts, [numBinsX, numBinsY]);

end