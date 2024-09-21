# Overview
This directory contains the scripts and configuration files for running image processing code on the HPC cluster.

## Preliminaries
Copy the `home` directory to the home directory on the HPC cluster. The directory should contain the following files:
- `config.yaml`: configuration file for the image processing code (see below for more details) 
- `generatescripts.py`: script for generating job scripts for the HPC cluster

For running ImageJ/ThunderSTORM on the HPC cluster, you would need the following:
- `imagej.sif`: Singularity container for ImageJ containing ThunderSTORM
- `fake_zcali.yaml`: Dummy z calibration file for ThunderSTORM to run astigmatism analysis

Finally, the `imagej_scripts` directory contains the ImageJ macro scripts for running ThunderSTORM on the HPC cluster. It contains the following files:
- `process_0th.ijm`: ImageJ macro script for processing single color images
- `process_2ddwp.ijm`: ImageJ macro script for processing multi-color images with 2D-DWP
- `process_3ddwp.ijm`: ImageJ macro script for processing multi-color images with 3D-DWP
- `process_sddwp.ijm`: ImageJ macro script for processing multi-color images with SD-DWP

## Configuration
The `config.yaml` file contains the following fields:
- `allocation`: input the allocation id for the HPC cluster
- `username`: input the username for the HPC cluster

## Processing files
First, transfer your data to the HPC cluster, preferably in a subfolder in the `scratch` directory. Next, copy the relevant ImageJ macro script to the same directory as the data. Open the ImageJ macro script and modify the roi regions for the 0th and 1st order images to match the regions in your data.

Then, navigate to the `home` directory and run the following command:
```
python generatescripts.py <foldername>
```
where `<foldername>` is the name of the folder containing the data. You need not include the full path to the folder if the folder is in your scratch directory. The script first creates subfolders in your data folder for the output files. It then generates a job script for each file in the folder `scripts`. 

Finally, to submit the job scripts to the HPC cluster, run the following command:
```
./run_all.sh
```
This will submit all the job scripts to the HPC cluster. You can monitor the status of the jobs using the `squeue --me` command.

### Troubleshooting
As each file is processed, the job script outputs the output files directly to the input folder. When the job script is complete, the output files are moved to the corresponding output folders. If you encounter any issues with the job scripts, you can check the error logs in the `logfiles` directory. The error logs contain the standard output and error messages from the job scripts. You can also check the status of the jobs using the `squeue --me` command.

Generally, if your files are not moved to the correct output folders, this may indicate insufficient time for the job to complete. You can increase the time limit through `python generatescripts.py <foldername> --run-time <time>` where <time> is the time limit in the format `"HH:MM:SS"`. The default time limit is 3 hours.

If you encounter memory issues while running the job scripts, you can also specify the amount of memory allocated to the job using `python generatescripts.py <foldername> -m <memory>` where <memory> is the memory limit in the format `"XXG"`. The default memory limit is 32G.
