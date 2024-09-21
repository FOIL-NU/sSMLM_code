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

## Usage
First, transfer your data to the HPC cluster, preferably in a subfolder in the `scratch` directory. Next, copy the relevant ImageJ macro script to the same directory as the data. Open the ImageJ macro script and modify the roi regions for the 0th and 1st order images to match the regions in your data.

Then, navigate to the `home` directory and run the following command:
```
python generatescripts.py <foldername>
```
where `<foldername>` is the name of the folder containing the data. You need not include the full path to the folder if the folder is in your scratch directory. The script first creates subfolders in your data folder for the output files. It then generates a job script for each file in the folder `scripts`. To submit the job scripts to the HPC cluster, run the following command:
```
./run_all.sh
```
This will submit all the job scripts to the HPC cluster. You can monitor the status of the jobs using the `squeue --me` command.