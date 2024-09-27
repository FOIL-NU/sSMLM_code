import sys
import os
import hashlib
import argparse
import yaml


def generate_sh_scripts(directory, runtime, memory):
    # search for the file 'config.yaml' and load it
    with open('config.yaml', 'r') as file:
        config = yaml.safe_load(file)

    allocation = config['allocation']
    username = config['username']
    
    if not os.path.isdir(directory):
        # check if prepending scratch/<username> helps
        if os.path.isdir(os.path.join('/scratch', username, directory)):
            directory = os.path.join('/scratch', username, directory)
        else: 
            print("Directory cannot be located.")
            return
        
    filelist = os.listdir(directory)

    # find a file that ends with '.ijm' in the target directory
    ijm_filename = None
    for filename in os.listdir(directory):
        if filename.endswith('.ijm'):
            ijm_filename = filename
            print("Found .ijm file: {}".format(ijm_filename))

            break

    if ijm_filename is None:
        print("No .ijm files found in the target directory. Please add a .ijm file to the target directory.")
        return

    # create a empty array to store the unique job names
    job_names = []

    # Create the logfiles and scripts directories if they don't exist
    check_make_directory('logfiles')
    check_make_directory('scripts')

    # create output directories for the processed files
    check_make_directory(os.path.join(directory, 'tsefirst'))
    check_make_directory(os.path.join(directory, 'tsezeroth'))
    check_make_directory(os.path.join(directory, 'png'))

    # Loop through all files in the directory
    for filename in filelist:
        # Check if the file ends with '.nd2'
        if filename.endswith('.nd2'):
            full_path = os.path.join('scripts', filename[:-4])

            # compute a checksum on the filename
            checksum = hashlib.sha256(filename[:-4].encode('utf-8')).hexdigest()
            # truncate the checksum to 8 characters
            job_name = checksum[:8]
            job_names.append(job_name)

            with open("{}.sh".format(full_path), "w") as file:
                file.write("#!/bin/bash\n")
                file.write("#SBATCH -A {}             # Allocation\n".format(allocation))
                file.write("#SBATCH -p short                # Queue\n")
                file.write("#SBATCH -t {}                   # Walltime/duration of the job\n".format(runtime))
                file.write("#SBATCH -N 1                    # Number of Nodes\n")
                file.write("#SBATCH --mem={}                # Memory per node in GB needed for a job. Also see --mem-per-cpu\n".format(memory))
                file.write("#SBATCH --ntasks-per-node=16    # Number of Cores (Processors)\n")
                file.write("#SBATCH --job-name=\"ij{}\"     # Name of job\n".format(job_name))
                file.write("\n")
                file.write("# Load modules\n")
                file.write("module load singularity\n")
                file.write("\n")
                file.write("# Run the container\n")
                file.write("singularity exec --containall --bind \"/home/{}\":\"/mnt/scripts\" \\\n".format(username))
                file.write("    --bind \"{}\":\"/mnt/data\" \\\n".format(directory))
                file.write("    /home/{}/imagej.sif \\\n".format(username))
                file.write("xvfb-run -a \\\n")
                file.write("ImageJ-linux64 --ij2 --console --run /mnt/data/{}.ijm \\\n".format(ijm_filename[:-4]))
                file.write("\"root_path='/mnt/data/', file='{}'\"\n".format(filename))
                file.write("\n")
                file.write("# Move processed files to subfolders\n")
                file.write("mv \"{}/{}_1.csv\" \"{}/tsefirst\"\n".format(directory, filename[:-4], directory))
                file.write("mv \"{}/{}_1-protocol.txt\" \"{}/tsefirst\"\n".format(directory, filename[:-4], directory))
                file.write("mv \"{}/{}_0.csv\" \"{}/tsezeroth\"\n".format(directory, filename[:-4], directory))
                file.write("mv \"{}/{}_0-protocol.txt\" \"{}/tsezeroth\"\n".format(directory, filename[:-4], directory))
                file.write("mv \"{}/{}_0.png\" \"{}/png\"\n".format(directory, filename[:-4], directory))
                file.write("mv \"{}/{}_1.png\" \"{}/png\"\n".format(directory, filename[:-4], directory))

    # Create a master .sh file to run sbatch on all generated .sh files
    with open("run_all.sh", "w") as master_file:
        master_file.write("#!/bin/bash\n")
        for filename in filelist:
            sh_path = os.path.join('scripts', filename[:-4] + '.sh')
            err_path = os.path.join('logfiles', filename[:-4] + '.err')
            out_path = os.path.join('logfiles', filename[:-4] + '.out')

            if filename.endswith('.nd2'):
                master_file.write("sbatch -e {} -o {} {}\n".format(err_path, out_path, sh_path))

        # delete the sh files in the scripts directory
        master_file.write("rm scripts/*.sh\n")
        master_file.write("echo \"All jobs submitted.\"\n")

    print("\n \
        {} shell script files have been generated for batch processing.\n \
        Run 'chmod +x run_all.sh' to make it executable,\n \
        then run ./run_all.sh to submit all jobs.".format(len(job_names)))


def check_make_directory(directory):
    if not os.path.isdir(directory):
        os.mkdir(directory)
        print("Created directory: {}".format(directory))


def main():
    args = parse_args()
    generate_sh_scripts(args.directory, args.runtime, args.memory)


def parse_args():
    parser = argparse.ArgumentParser(description="Generate shell scripts for batch processing of .nd2 files.")
    parser.add_argument("directory", type=str, help="The directory containing the files to process.")
    parser.add_argument("--runtime", "-r", type=str, default="03:30:00", help="The walltime/duration of the job (default: 03:00:00).")
    parser.add_argument("--memory", "-mem", "-m", type=str, default="32G", help="Memory per node in GB needed for a job (default: 32G).")
    return parser.parse_args()


if __name__ == "__main__":
    main()

