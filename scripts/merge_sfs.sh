#!/bin/bash

#This script can be run with a simple bash command and is very quick!
#It takes the SFS files produced for each chromosome and merges based on bootstrap replicate. You should end up with 50 mereged SFS files.
#Run the command: bash merge_sfs.sh
#It will run on bootstrap reps 1-50 & edit as you see fit (ie. if you only need runs 10-15 edit the seq argument)


#Define environment variables
SCRIPT=/work/hpk4/sfs_boot/scripts/mergeSFS_4th.r
OUTDIR=/work/hpk4/sfs_boot/outputs

#Load R module
module load R/4.4.3

#Run R script
for bootstrap in $(seq -w 1 10); do
	echo "Processing bootstrap ${bootstrap} SFS files"
	#Make Bootstrap Directory with soft links to each SFS file
	TEMP=${OUTDIR}/SFS_merge/bs${bootstrap}
	mkdir -p ${TEMP}
	cd ${TEMP}
	for path in ${OUTDIR}/20kb_vcf_*/bootstrap_reps/outSFS/sfs_bs${bootstrap}/fastsimcoal2/*jointDAFpop1_0.obs; do
		num=$(echo "$path" | grep -oP '20kb_vcf_\K\d+')
		ln -s "$path" "$TEMP/bootstrap_${bootstrap}_chrom${num}_jointDAFpop1_0.obs"
	done
	#Run the R script
	Rscript ${SCRIPT} ${TEMP}/*.obs

	#Ammend final fine to have the first line
	echo "1 observation" > ${TEMP}/final_merged_jointDAFpop1_0.obs
	cat ${TEMP}/merged_jointDAFpop1_0.obs >> ${TEMP}/final_merged_jointDAFpop1_0.obs

	#Remove temporary files
	rm ${TEMP}/*chrom*.obs
	rm ${TEMP}/merged_jointDAFpop1_0.obs
	echo "Merged bootstrap ${bootstrap}, you can find the resulting file at ${TEMP}/final_merged_jointDAFpop1_0.obs"
done
