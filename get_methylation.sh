#!/bin/bash

MODKIT=$my_tools/modkit

ref=$1
subregion_bed=$2
if [[ $# -gt 2 ]]; then
	TR_fa=$3
	read_path=$4
	SCRIPT_DIR=$5
fi

mkdir -p modkit_beds modkit_beds/logs read_breakdown

subregion=$(awk '{printf "%s:%d-%d", $1, $2, $3}' $subregion_bed)

for bam in ../alignment/*.bam; do
	group=$(basename $bam | cut -d. -f1)
	echo $group
	if [[ $# -gt 2 ]]; then
		sbatch --time=1-0 --mem=64g --cpus-per-task=16 -o modkit_beds/logs/$group.out get_methylation_per_group.sh $ref $subregion_bed $TR_fa $read_path $SCRIPT_DIR $group
	else
		sbatch --time=1-0 --mem=64g --cpus-per-task=16 -o modkit_beds/logs/$group.out get_methylation_per_group.sh $ref $subregion_bed $group
	fi
done
