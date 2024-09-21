# hpc

## Overview

This directory contains the scripts and configuration files for running image processing code on the HPC cluster.

## Preliminaries
Copy the `home` directory to the home directory on the HPC cluster. The directory should contain the following files:
- `config.yaml`: configuration file for the image processing code (see below for more details) 
- `generatescripts.py`: script for generating job scripts for the HPC cluster

For running ImageJ/ThunderSTORM on the HPC cluster, you would need the following:
- imagej.sif: Singularity container for ImageJ containing ThunderSTORM
- fake_zcali.yaml: Dummy z calibration file for ThunderSTORM to run astigmatism analysis

## Configuration
The `config.yaml` file contains the following fields:
- `allocation`: input the allocation id for the HPC cluster
- `username`: input the username for the HPC cluster

## Usage
First, transfer your data to the HPC cluster, preferably to the `scratch` directory. Then, navigate to the `home` directory and run the following command:
```
python generatescripts.py <foldername>
```
where `<foldername>` is the name of the folder containing the data. This will generate a job script for each file in the folder `scripts`. To submit the job scripts to the HPC cluster, run the following command:
```
./run_all.sh
```
This will submit all the job scripts to the HPC cluster. You can monitor the status of the jobs using the `squeue --me` command.
