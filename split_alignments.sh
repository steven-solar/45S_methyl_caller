#!/bin/bash

SCRIPT_DIR=$1
chrs=("chr13" "chr14" "chr15" "chr21" "chr22" "none")

for chr in ${chrs[@]}; do
    echo "$chr"
    mkdir -p read_breakdown/$chr
    while read line; do
        readname=$(echo $line | awk '{print $1}')
        mkdir -p "read_breakdown/$chr/$readname"
    done <  <(samtools view $chr.bam)
    samtools view "$chr.bam" | python $SCRIPT_DIR/split.py $chr "temp/$chr.just_header.sam"
    for sam in read_breakdown/$chr/*/*.sam; do
        name=$(echo $sam | cut -d. -f 1)
        samtools view -h -O BAM --write-index -o "$name.bam##idx##$name.bam.bai" $sam
    done
done
