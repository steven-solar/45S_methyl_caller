#!/bin/bash

bam=$1
chr_list_f=$2
out=$3

mkdir -p $out

while read -r chr; do
	samtools view -h -@$SLURM_CPUS_PER_TASK $bam $chr | samtools fastq -@$SLURM_CPUS_PER_TASK -T 'MM,ML,Mm,Ml' | bgzip -@$SLURM_CPUS_PER_TASK > $out/$chr.fq.gz
done < $chr_list_f
