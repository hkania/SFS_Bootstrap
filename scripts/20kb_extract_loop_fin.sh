#!/bin/bash

#SBATCH -o log/20kb.out
#SBATCH -e log/20kb.err
#SBATCH --mem=100G
#SBATCH -p common
#SBATCH -c 35
#SBATCH --mail-type=ALL
#SBATCH --mail-user=kania.hannah@duke.edu

#This script will take input VCF files for designated chromosome numbers
#and break them into smaller VCFs that are 20kb windows of the original
#chromosome length.

#To generalize, you will need to change the input file paths carefully.
#The script took about 2 hours and 40 minutes for ~26 chromosomes!

#Move to correct folder
cd /work/hpk4/sfs_boot

#Activate conda environment
source /hpc/group/yoderlab/jcs165/miniconda3/etc/profile.d/conda.sh
conda activate mapping_calling

#Process each chromosome, 6-32 (already did 1-5)
for CHR in {6..32}; do

	#Input VCF file (bgzipped and indexed)
	VCF=fastsim_biallelic_snps_final.withAA_noOut_chr${CHR}.vcf.gz

	#Make output directory
	OUTPUT_DIR=/work/hpk4/sfs_boot/outputs/20kb_vcf_${CHR}

	mkdir -p ${OUTPUT_DIR}

	#Set step size
	STEP=20000

	#Process the chromosome VCF file
	echo "Starting to split VCF file for chromosome ${CHR}"
	date

	bcftools index -s ${VCF} | while read CHROM LENGTH _; do
	echo "Processing $CHROM (length: $LENGTH bp)"

	#Loop in 20kb steps
		for ((START=1; START<=LENGTH; START+=STEP )); do
			END=$((START + STEP - 1))
			if [ $END -gt $LENGTH ]; then
				END=$LENGTH
			fi

			REGION="${CHROM}:${START}-${END}"
			OUTFILE=${OUTPUT_DIR}/${CHROM}_${START}_${END}.vcf.gz

			echo "Extracting region $REGION -> $OUTFILE"
			bcftools view -r "$REGION" "$VCF" -Oz -o ${OUTFILE}
			tabix -p vcf ${OUTFILE}
		done
	done
done

echo "Done with script"
date
