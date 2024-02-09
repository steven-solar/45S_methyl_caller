#!/bin/bash

sample=$1

samtools merge -@32 - $sample/alignment/temp/chr13.sam $sample/alignment/temp/chr14.sam $sample/alignment/temp/chr15.sam $sample/alignment/temp/chr21.sam $sample/alignment/temp/chr22.sam $sample/alignment/temp/unmap.sam \
	| samtools sort -@32 - \
	| samtools depth -@32 -a -b /data/Phillippy2/projects/chm13_rdna_methylation_reanalysis/feature_45S_correlations/beds_refs/45S.bed - \
	| awk '{sum+=$3} END {print sum/NR}'