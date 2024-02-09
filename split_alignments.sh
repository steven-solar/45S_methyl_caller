#!/bin/bash

SCRIPT_DIR=$1

for bam in *.bam; do
    group=$(basename $bam | cut -d. -f1)
    echo "$group"
    mkdir -p read_breakdown/$group
    while read line; do
        readname=$(echo $line | awk '{print $1}')
        mkdir -p "read_breakdown/$group/$readname"
    done <  <(samtools view $group.bam)
    samtools view "$group.bam" | python $SCRIPT_DIR/split.py $group "temp/$group.just_header.sam"
    for sam in read_breakdown/$group/*/*.sam; do
        group=$(echo $sam | cut -d. -f 1)
        samtools view -h -O BAM --write-index -o "$group.bam##idx##$group.bam.bai" $sam
    done
done
