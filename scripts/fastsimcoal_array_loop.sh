#!/bin/bash

#SBATCH --mem=500
#SBATCH -p scavenger
#SBATCH -c 15
#SBATCH --time=10:00:00
#SBATCH --array=1-100%10

#This script takes a series of SFS files merged into 50 bootstrap replicates and
#loops across the 50 replicates (delegate as separate jobs as necessary) to run
#100 interations of fastsimcoal2 on each SFS replicate. One full job takes around
#xx hours, where each array takes around 1.5-4 hours to complete.

#To submit the job for bootstraps XX-XX (for example 49 & 50) copy the below command after ###
#while in the home directory (you should change path names as necessary)

### for i in $(seq -w 49 50); do sbatch --export=ALL,BOOTSTRAP=$i --job-name=fsc_bs${i} --output=log/fastsimcoal/slurm-%A_%a_bs${i}.out --error=log/fastsimcoal/slurm-%A_%a_bs${i}.err scripts/fastsimcoal_array_loop.sh ; done

# Bootstrap ID must be passed via --export=BOOTSTRAP=03
if [ -z "$BOOTSTRAP" ]; then
    echo "Error: BOOTSTRAP variable not set. Pass it via --export=BOOTSTRAP=XX"
    exit 1
fi

#Activate conda environment for fastsimcoal
source /hpc/group/yoderlab/jcs165/miniconda3/etc/profile.d/conda.sh
conda activate fastsimcoal

#Set variables
#BOOTSTRAP=02
PREFIX="EarlyGeneFlow"
HEAD_DIR=/work/hpk4/sfs_boot
BOOTSTRAP_DIR=${HEAD_DIR}/outputs/SFS_merge/bs${BOOTSTRAP}
RUN_DIR=${BOOTSTRAP_DIR}/Run${SLURM_ARRAY_TASK_ID}

#Make slurm array run diretory
mkdir -p ${RUN_DIR}

#Copy necessary fastsimcoal files to each slurm array run directory
cp ${HEAD_DIR}/${PREFIX}.tpl ${HEAD_DIR}/${PREFIX}.est ${RUN_DIR}
cp ${BOOTSTRAP_DIR}/final_merged_jointDAFpop1_0.obs ${RUN_DIR}/${PREFIX}_jointDAFpop1_0.obs

#Move to the run directory
cd ${RUN_DIR}

#Start the fastsimcoal runs!
echo "Running iteration $SLURM_ARRAY_TASK_ID for bootstrap ${BOOTSTRAP}"
date

fastsimcoal2 -t ${PREFIX}.tpl -e ${PREFIX}.est -d -0 -c 12 -n 1000000 -L 100 -q -s 0 -M

echo "Done with iteration $SLURM_ARRAY_TASK_ID for bootstrap ${BOOTSTRAP}"
date
