#!/bin/bash

ml load modkit 

if [ -z ${SLURM_CPUS_PER_TASK+x} ]; then
    cpus=32
else
    cpus=$SLURM_CPUS_PER_TASK
fi

SCRIPT_DIR=$1
ref=$2
group=$3
out_dir=$4
echo $group

if [[ $(samtools view -@$cpus -c $out_dir/alignment/$group.bam) -eq 0 ]]; then
	echo "empty bam"
	exit 0
fi

if [[ $# -eq 4 ]]; then
	modkit pileup \
		--threads $cpus \
		--ref $ref \
		--cpg \
		--combine-strands \
		--ignore h \
		--only-tabs \
		--log $out_dir/get_methylation/logs/$group.whole_region.log \
		$out_dir/alignment/$group.bam \
		$out_dir/get_methylation/modkit_beds/$group.whole_region.bed
else
	subregion_bed=$5
	subregion=$(awk '{printf "%s:%d-%d", $1, $2, $3}' $subregion_bed)
	modkit pileup \
		--threads $cpus \
		--ref $ref \
		--region $subregion \
		--cpg \
		--combine-strands \
		--ignore h \
		--only-tabs \
		--log $out_dir/get_methylation/logs/$group.subregion.log \
		../alignment/$group.bam \
		$out_dir/get_methylation/modkit_beds/$group.subregion.bed
fi
