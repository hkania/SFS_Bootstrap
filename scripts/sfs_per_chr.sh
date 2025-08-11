#!/bin/bash

#SBATCH -o log/sfs_per_chr20.out
#SBATCH -e log/sfs_per_chr20.err
#SBATCH --mem=80G #You will need more for larger chromosomes!
#SBATCH -p scavenger
#SBATCH -c 4
#SBATCH --time=40:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=kania.hannah@duke.edu

#This example runs on chromosome 20 of the M. murinus genome.
#Depending on the size of the chromosome you may need more memory.
#This script will take each of the 50 simulated VCF files per chromosome
#and generate a SFS file for a resulting 50 SFS files.

#Activate conda environment for easySFS
source /hpc/group/yoderlab/jcs165/miniconda3/etc/profile.d/conda.sh
conda activate fastsimcoal

#move to correct folder
cd /work/hpk4/sfs_boot

#Define variables
POP_FILE=/work/hpk4/sfs_boot/pop_file_noOut.txt
CHROM=20
VCF=/work/hpk4/sfs_boot/outputs/20kb_vcf_${CHROM}/bootstrap_reps
OUTDIR=/work/hpk4/sfs_boot/outputs/20kb_vcf_${CHROM}/bootstrap_reps/outSFS

mkdir -p ${OUTDIR}

echo "Starting loop to create bootstrap SFS for chromosome ${CHROM}"
date

for bootstrap in $(seq -w 1 50); do
	echo "Processing bootstrap ${bootstrap}"
	./easySFS.py -i ${VCF}/rep_${bootstrap}/bootstrap_${bootstrap}.vcf.gz \
		-p ${POP_FILE} -a -f --unfolded -v --proj 40,54 \
		-o ${OUTDIR}/sfs_bs${bootstrap}
done

echo "Done with script"
date
