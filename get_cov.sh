#!/bin/bash

if [ -z ${SLURM_CPUS_PER_TASK+x} ]; then
    cpus=32
else
    cpus=$SLURM_CPUS_PER_TASK
fi

bam=$1
bed=$2
out=$3

samtools view -h -@$cpus -F 260 $bam \
	| samtools depth \
		-@$cpus \
		-a \
		-b $bed \
		- \
		| awk '{sum += $3} END {print sum/NR}' > $out
