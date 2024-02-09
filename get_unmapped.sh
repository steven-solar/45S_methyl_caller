#!/bin/bash

if [ -z ${SLURM_CPUS_PER_TASK+x} ]; then
    cpus=32
else
    cpus=$SLURM_CPUS_PER_TASK
fi

bam=$1
out=$2

echo "bam=$1
out=$2"

echo "samtools view -h -@$cpus -f 4 $bam | samtools fastq -@$cpus -T 'MM,ML,Mm,Ml' - | bgzip -@$cpus > $out/unmap.fq.gz"

samtools view -h -@$cpus -f 4 $bam | samtools fastq -@$cpus -T 'MM,ML,Mm,Ml' - | bgzip -@$cpus > $out/unmap.fq.gz
