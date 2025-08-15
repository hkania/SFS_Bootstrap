# SFS_Bootstrap

### This repository holds the scripts used to generate the bootstrap replicates for the fastsimcoal2 Microcebus run.

### Steps:
1. Run [20kb_extract_loop_fin.sh](https://github.com/hkania/SFS_Bootstrap/blob/main/scripts/20kb_extract_loop_fin.sh).
  * This script takes all 32 chromosome VCF files and chunks them into VCF files representing sites within 20kb windows based on each chromosome's length.
    > The 20kb size was chosen based on LD calculated from the data.
2. Run [bootstrap_vcf_scav.sh](https://github.com/hkania/SFS_Bootstrap/blob/main/scripts/bootstrap_vcf_scav.sh) for each chromosome.
  * This script will resample, with replacement, from the 20kb VCF files for that chromosome to equal the same number of files and generate a concatenated VCF file with those sites. As such, some sites may be present multiple times. This will make each bootstrap VCF replicate, 50 per each chromosome.
2. Run [sfs_per_chr.sh](https://github.com/hkania/SFS_Bootstrap/blob/main/scripts/sfs_per_chr.sh)
  * This script will take each bootstrap VCF replicate and generate an SFS file.
3. Run [merge_sfs.sh](https://github.com/hkania/SFS_Bootstrap/blob/main/scripts/merge_sfs.sh)
  * This script will take each of the 50 replicate SFS files per chromosome and join the to the corresponding replicates of all the chromosomes. You will then have 50 SFS files representing different bootstrap VCF replicates across the entire M. murinus genome.
    > Note: Dependent script [mergeSFS_4th.r](https:/mergeSFS_4th.r/github.com/hkania/SFS_Bootstrap/blob/main/scripts/mergeSFS_4th.r) is the R script which performs the merge of the tables
4. Run [fastsimcoal_array_loop.sh](https://github.com/hkania/SFS_Bootstrap/blob/main/scripts/fastsimcoal_array_loop.sh)
  * This script will take each of the 50 merged SFS files and run fastimcoal2 with the parameters denoted by the best-fit model with 100 repititions. Takes between 30 and 50 hours to complete per bootstrap rep.
5. Run [best_run_loop.sh](https://github.com/hkania/SFS_Bootstrap/blob/main/scripts/best_run_loop.sh)
  * This script will run through each bootstrap replicate SFS folder and mine each of the 100 fastsimcoal2 runs for their best liklihood parameter values. It will then decide which of the 100 runs produced the best liklihood parameters and print those parameter values to a file which can be used for determining confidence intervals of the original parameters from fastsimcoal2 run on the orignial data.

### Complimentary Scripts:
* [duration.sh](https://github.com/hkania/SFS_Bootstrap/blob/main/scripts/duration.sh)
  * This script will print the total time elapsed for an array job. This was used to determine the total run time for the fastsimcoal2 arrays, which take between 30 and 50 hours for 100 runs to complete. The duration varies based on the number of parallel arrays being run.
