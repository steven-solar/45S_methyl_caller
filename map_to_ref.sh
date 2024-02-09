#!/bin/bash

ml load minimap2

fastq_path=$1
ref=$2
SCRIPT_DIR=$3

mkdir -p temp read_breakdown logs

jids=""

for fastq in $fastq_path/*; do
    group=$(basename $fastq | cut -d. -f1)
    echo $group
    jids+=":$(sbatch --time=04:00:00 --mem=64g --cpus-per-task=16 -o logs/$group.out map_to_ref_per_group.sh $fastq $ref $SCRIPT_DIR $group)"
done
