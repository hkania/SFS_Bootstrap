#!/bin/bash

#SBATCH -o log/best_run_loop.out
#SBATCH -e log/best_run_loop.err
#SBATCH --mem=1G
#SBATCH -p scavenger
#SBATCH -c 2
#SBATCH --time=0-01:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=kania.hannah@duke.edu

#This script will loop over the 100 Run folders produced via
#the fastsimcoal array for each bootstrap replicate and pull out the best
#run parameter values. It will add those values and which bootstrap
#they came from to a TSV file that can be used for bootstrapping in R!
#Change the seq as fit.

#Set environment variables
BOOT_TABLE=/work/hpk4/sfs_boot/outputs/param_info/bootstrap_params.tsv

echo "Starting script!"
date

for replicate in $(seq -w 1 50); do
	echo "Processing bootstrap replicate ${replicate}"
	BOOTSTRAP=${replicate}
	DIR=/work/hpk4/sfs_boot/outputs/SFS_merge/bs${BOOTSTRAP}

	#Initiate the all liklihoods file
	echo -e "Run\tMaxEstLhood" > ${DIR}/all_lhoods.tsv

	for i in {1..100}; do
    		file="${DIR}/Run${i}/EarlyGeneFlow/EarlyGeneFlow.bestlhoods"
    		if [ -f "$file" ]; then
        	lhood=$(grep -v MaxObsL "$file" | awk '{print $9}')
        	echo -e "${i}\t${lhood}" >> ${DIR}/all_lhoods.tsv
    	else
        	echo -e "${i}\tNA" >> ${DIR}/all_lhoods.tsv
    	fi
	done

	BEST_LIKLIHOOD=$(grep -v NA ${DIR}/all_lhoods.tsv | sort -nk2 | tail -n 2 | head -n 1)
	echo ${BEST_LIKLIHOOD} > ${DIR}/best_liklihood.txt

	BEST_RUN=$(cut -d " " -f 1 ${DIR}/best_liklihood.txt)
	echo "best run for replicate ${replicate} = ${BEST_RUN}"
	RUN_FILE=${DIR}/Run${BEST_RUN}/EarlyGeneFlow/EarlyGeneFlow.bestlhoods
	echo "run file for replicate ${replicate} = ${RUN_FILE}"

	NGRIS=$(tail -n 1 ${RUN_FILE} | cut -f 1)
	NMUR=$(tail -n 1 ${RUN_FILE} | cut -f 2)
	NANC=$(tail -n 1 ${RUN_FILE} | cut -f 3)
	TDIV=$(tail -n 1 ${RUN_FILE} | cut -f 4)
	MIG1=$(tail -n 1 ${RUN_FILE} | cut -f 5)
	MIG2=$(tail -n 1 ${RUN_FILE} | cut -f 6)
	TPROP=$(tail -n 1 ${RUN_FILE} | cut -f 7)
	TISO=$(tail -n 1 ${RUN_FILE} | cut -f 8)
	MAXE=$(tail -n 1 ${RUN_FILE} | cut -f 9)
	MAXO=$(tail -n 1 ${RUN_FILE} | cut -f 10)

	echo -e "${BOOTSTRAP}\t${NGRIS}\t${NMUR}\t${NANC}\t${TDIV}\t${MIG1}\t${MIG2}\t${TPROP}\t${TISO}\t${MAXE}\t${MAXO}" >> ${BOOT_TABLE}
	echo "completed best run determination for replicate ${replicate}"
done

echo "Done with script"
date

