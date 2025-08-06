#!/bin/bash

#SBATCH -o log/bootstrap_vcf_trial_cat_scav.out
#SBATCH -e log/bootstrap_vcf_trial_cat_scav.err
#SBATCH --mem=250G
#SBATCH -p scavenger
#SBATCH -c 35
#SBATCH --mail-type=ALL
#SBATCH --mail-user=kania.hannah@duke.edu

#This script will take a set of VCF files generated using 20kb_extract_loop_fin.sh
#and output 50 new bootstrap VCF files that are sampled with replacement
#to a final concatenated VCF file equal the total number of VCF files generated
#from the 20kb script. It takes ~11 hours to run on one set of 20kb chunks, but
#will vary with chromosome size. For example, chromosome 1 of M. murinus had
#5714 VCF files from the 20kb step, and one bootstrap replicate for the
#concatentated VCF file took ~14 minutes to generate.

#You will need to edit the variables below as fit. It currently mirrors the
#commands for chromosome 2.

#Set variables
VCF_DIR=/work/hpk4/sfs_boot/outputs/20kb_vcf_2

#Make text file with all vcf files
ls ${VCF_DIR}/*.vcf.gz > ${VCF_DIR}/vcf_list.txt

VCF_LIST=${VCF_DIR}/vcf_list.txt
mapfile -t VCF_FILES < "$VCF_LIST"

NUM_FILES=${#VCF_FILES[@]}

OUTDIR=/work/hpk4/sfs_boot/outputs/20kb_vcf_2/bootstrap_reps
mkdir -p ${OUTDIR}

#Temporary file used for merge list (will be reused each time)
TEMP_LIST=$(mktemp)

#Move to correct directory
cd ${VCF_DIR}

#Activate conda environment
source /hpc/group/yoderlab/jcs165/miniconda3/etc/profile.d/conda.sh
conda activate mapping_calling

#Put chunk size to decrease the load on BCF cat step
CHUNK_SIZE=15
CHUNK_SIZE2=10

#Perform 50 bootstrap replicates
for REP in $(seq -w 1 50); do
	echo "Running bootstrap replicate $REP..."

	#Output file names
	OUT_REP_DIR="${OUTDIR}/rep_${REP}"
	mkdir -p ${OUT_REP_DIR}
	OUT_VCF="${OUT_REP_DIR}/bootstrap_${REP}.vcf.gz"
	SAMPLE_DIR="${OUT_REP_DIR}/sample_info"
	SAMPLE_NAMES="${SAMPLE_DIR}/sample_names_${REP}.txt"
	mkdir -p ${SAMPLE_DIR}

	#Empty Temp Files
	> "$TEMP_LIST"
	> "$SAMPLE_NAMES"

	#Resample with replacement
	for ((i = 0; i < NUM_FILES; i++)); do
		RAND_INDEX=$((RANDOM % NUM_FILES))
		FILE="${VCF_FILES[$RAND_INDEX]}"
		echo "$FILE" >> "$TEMP_LIST"
		basename "$FILE" >> "$SAMPLE_NAMES"
	done

	# Create a directory for chunk files
	CHUNK_DIR1="${OUT_REP_DIR}/chunks_round1_${REP}"
	mkdir -p "$CHUNK_DIR1"

	# Split VCF list into chunks of CHUNK_SIZE
	split -l $CHUNK_SIZE "$TEMP_LIST" "$CHUNK_DIR1/chunk_"

	# Merge each chunk into an intermediate VCF
	INTERMEDIATE_LIST1="${CHUNK_DIR1}/intermediate_vcfs.txt"
	> "$INTERMEDIATE_LIST1"

	for chunk_file in "$CHUNK_DIR1"/chunk_*; do
		chunk_vcf="${chunk_file}.vcf.gz"
		bcftools concat -a -f "$chunk_file" --threads 35 -Oz -o "$chunk_vcf"
		tabix -p vcf "$chunk_vcf"
		echo "$chunk_vcf" >> "$INTERMEDIATE_LIST1"
	done

	# Create a directory for chunk files a second time
	CHUNK_DIR2="${OUT_REP_DIR}/chunks_round2_${REP}"

	# Split VCF list into chunks of CHUNK_SIZE2
	mkdir -p "$CHUNK_DIR2"
	split -l $CHUNK_SIZE2 "$INTERMEDIATE_LIST1" "$CHUNK_DIR2/chunk2_"

	INTERMEDIATE_LIST2="${CHUNK_DIR2}/intermediate_vcfs_round2.txt"
	> "$INTERMEDIATE_LIST2"

	for chunk_file in "$CHUNK_DIR2"/chunk2_*; do
		chunk_vcf="${chunk_file}.vcf.gz"
                bcftools concat -a -f "$chunk_file" --threads 35 -Oz -o "$chunk_vcf"
		tabix -p vcf "$chunk_vcf"
		echo "$chunk_vcf" >> "$INTERMEDIATE_LIST2"
	done

	#Merge the final VCF with sampled files
	bcftools concat -a -f "$INTERMEDIATE_LIST2" --threads 35 -Oz -o "$OUT_VCF"

	#Index the merged VCF
	if [[ -s "$OUT_VCF" ]]; then
		tabix -p vcf "$OUT_VCF"
	else
		echo "Warning: Final merged VCF is empty or missing"
	fi

	echo "  -> Sample list: $SAMPLE_NAMES"
done

# Clean up
rm "$TEMP_LIST"

echo "All 50 bootstraps completed. See $OUTDIR for results."
echo "Done with script"
date
