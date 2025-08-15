#!/bin/bash

#This script will spit out the total time elapsed for a full 100 array
#run for a specified job. The example below gave the elapsed time for
#bootstrap 07.

#Run the following command if in the log folder, and change the path
#and jobid as necessary

# jobid=33873955 bash ../../scripts/duration.sh


if [ -z "$jobid" ]; then
    echo "Error: jobid variable not set. Pass it via --export=jobid=XX"
    exit 1
fi

start=$(sacct -j ${jobid} --format=Start --parsable2 | tail -n +2 | sort | head -n 1)
end=$(sacct -j ${jobid} --format=End --parsable2 | tail -n +2 | sort | tail -n 1)

start_epoch=$(date -d "$start" +%s)
end_epoch=$(date -d "$end" +%s)

duration=$((end_epoch - start_epoch))

# Convert seconds to H:M:S
printf "Total runtime: %02d:%02d:%02d\n" $((duration/3600)) $(( (duration%3600)/60 )) $((duration%60))
