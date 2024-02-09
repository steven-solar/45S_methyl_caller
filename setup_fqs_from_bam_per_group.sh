#!/bin/bash

if [ -z ${SLURM_CPUS_PER_TASK+x} ]; then
    cpus=32
else
    cpus=$SLURM_CPUS_PER_TASK
fi

bam=$1
chr=$2
out=$3

echo "bam=$1
chr=$2
out=$3"

echo "samtools view -h -@$cpus $bam $chr \
    | samtools fastq -@$cpus -T 'MM,ML,Mm,Ml' \
    | bgzip -@$cpus > $out/$chr.fq.gz"

samtools view -h -@$cpus $bam $chr \
    | samtools fastq -@$cpus -T 'MM,ML,Mm,Ml' \
    | bgzip -@$cpus > $out/$chr.fq.gz
