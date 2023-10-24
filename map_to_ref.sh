#!/bin/bash

ml load minimap2

fastq_path=$1
ref=$2
prefix=$3
SCRIPT_DIR=$4

mkdir -p temp read_breakdown

chrs=("chr13" "chr14" "chr15" "chr21" "chr22" "none")

for chr in ${chrs[@]}; do
    echo "$chr"
    minimap2 \
        -t 32 \
        -a \
        -x map-ont \
        -y \
        --MD \
        -Y \
        $ref \
        $fastq_path/$chr.fastq.gz \
    | samtools view -@32 -F 260 -h -O SAM \
    > temp/$chr.sam

    samtools view -@32 temp/$chr.sam > temp/$chr.no_header.sam
    samtools view -@32 -H temp/$chr.sam > temp/$chr.just_header.sam

    paftools.js sam2paf temp/$chr.sam > temp/$chr.paf

    python $SCRIPT_DIR/filter_both.py temp/$chr.no_header.sam temp/$chr.paf sam > temp/$chr.filtered.sam
    python $SCRIPT_DIR/filter_both.py temp/$chr.no_header.sam temp/$chr.paf paf > temp/$chr.filtered.paf

    awk '{print $1, $3, $4, $5}' temp/$chr.filtered.paf > temp/$chr.filtered.bed
    grep_str=$(bash $SCRIPT_DIR/get_chimeras.sh temp/$chr.filtered.bed)
    if [[ $grep_str == "" ]]; then
        cp temp/$chr.filtered.paf $chr.paf
        cp temp/$chr.filtered.bed $chr.bed
        cat temp/$chr.just_header.sam temp/$chr.filtered.sam | samtools sort -@32 -O BAM --write-index -o $chr.bam##idx##$chr.bam.bai -
    else
        grep -v -E $grep_str temp/$chr.filtered.paf > $chr.paf
        grep -v -E $grep_str temp/$chr.filtered.bed > $chr.bed
        cat temp/$chr.just_header.sam temp/$chr.filtered.sam | grep -v -E $grep_str | samtools sort -@32 -O BAM --write-index -o $chr.bam##idx##$chr.bam.bai -
    fi

    echo -e "final paf (reads to ref) $(cat $chr.paf | wc -l)"
    echo -e "final sam (reads to ref) $(samtools view -@32 $chr.bam | wc -l)"
done
