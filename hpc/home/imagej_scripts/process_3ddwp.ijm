// Specify global variables
#@String root_path
#@String file

// add trailing slash to root_path if it doesn't exist
if (!endsWith(root_path, "/")) {
	root_path = root_path + "/";
}

processFile(root_path, file);

function processFile(input_folder, file) {
	// Generate filenames and output filenames
	input_filepath = input_folder + file;
	stripped_file = substring(file,0,lengthOf(file)-4);
	output_csvpath_zeroth = input_folder + stripped_file + "_0.csv";
	output_csvpath_first = input_folder + stripped_file + "_1.csv";
	output_pngpath_zeroth = input_folder + stripped_file + "_0.png";
	output_pngpath_first = input_folder + stripped_file + "_1.png";

	print("Processing " + input_filepath + "...");

	// Open the file
	run("Bio-Formats Importer", "open='" + input_filepath + "' color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack");

	// select the zeroth order ROI
	makeRectangle(0, 0, 600, 550);

	// Run ThunderSTORM analysis
	run("Camera setup", "offset=90.0 isemgain=false photons2adu=1.3 pixelsize=110.0");
	run("Run analysis", "filter=[Wavelet filter (B-Spline)] scale=2.0 order=3 detector=[Local maximum] connectivity=8-neighbourhood threshold=1.2*std(Wave.F1) estimator=[PSF: Gaussian] sigma=1.5 fitradius=3 method=[Weighted Least squares] full_image_fitting=false mfaenabled=false renderer=[Averaged shifted histograms] magnification=5.0 colorizez=false threed=false shifts=2 repaint=5000");
	run("Show results table", "action=duplicates distformula=600");

	// Export ThunderSTORM results
	run("Export results", "filepath='" + output_csvpath_zeroth + "' fileformat=[CSV (comma separated)] chi2=true offset=true saveprotocol=true bkgstd=true uncertainty=true intensity=true x=true sigma2=true y=true sigma1=true z=true id=true frame=true");

	// Save the zeroth order image
	selectWindow("Averaged shifted histograms");
	run("8-bit");
	saveAs("Png", output_pngpath_zeroth);

	// select the first order ROI
	selectWindow(stripped_file + ".nd2");
	makeRectangle(940, 0, 600, 550);

	// Run ThunderSTORM analysis
	run("Camera setup", "offset=90.0 isemgain=false photons2adu=1.3 pixelsize=110.0");
	run("Run analysis", "filter=[Wavelet filter (B-Spline)] scale=2.0 order=3 detector=[Local maximum] connectivity=8-neighbourhood threshold=1.1*std(Wave.F1) estimator=[PSF: Elliptical Gaussian (3D astigmatism)] sigma=2.5 fitradius=4 method=[Weighted Least squares] calibrationpath=[/mnt/scripts/fake_zcali.yaml] full_image_fitting=false mfaenabled=false renderer=[Averaged shifted histograms] magnification=5.0 colorizez=false threed=false shifts=2 repaint=5000");
	run("Show results table", "action=duplicates distformula=600");

	// Export ThunderSTORM results
	run("Export results", "filepath='" + output_csvpath_first + "' fileformat=[CSV (comma separated)] chi2=true offset=true saveprotocol=true bkgstd=true uncertainty=true intensity=true x=true sigma2=true y=true sigma1=true z=true id=true frame=true");

	// Save the first order image
	selectWindow("Averaged shifted histograms");
	run("8-bit");
	saveAs("Png", output_pngpath_first);

	// Close all open windows
	run("Close All");
}

run("Quit");
