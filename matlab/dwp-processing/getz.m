function z = getz(sigma0, sigma1, zcali_path, debug)

if nargin < 4
    debug = false;
end

% load the zcali file
load(zcali_path);
% the zcali file contains the following variables:
% sigma0_fitted, sigma1_fitted, z_values

if isvarname('zcali') && isstruct(zcali)
    sigma0_fitted = zcali.sigma0_fitted;
    sigma1_fitted = zcali.sigma1_fitted;
    z_values = zcali.z_values;
end

if debug == true
    % plot the zcali data loaded
    figure(1); 
    yyaxis left;
    hold on;
    plot(z_values, sigma0_fitted, 'b');
    plot(z_values, sigma1_fitted, 'r');

    yyaxis right;
    % plot the axial F curve
    plot(z_values, axialf(sigma0_fitted, sigma1_fitted), 'k');
end

% calculate the z values for a given sigma0 and sigma1
z = interp1(axialf(sigma0_fitted, sigma1_fitted), z_values, axialf(sigma0, sigma1), 'pchip');

end


function F = axialf(wn,wp)

F = (wp.*wp-wn.*wn)./(wp.*wp+wn.*wn);

end