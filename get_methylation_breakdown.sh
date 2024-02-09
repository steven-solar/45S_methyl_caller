#!/bin/bash

if [ -z ${SLURM_CPUS_PER_TASK+x} ]; then
    cpus=32
else
    cpus=$SLURM_CPUS_PER_TASK
fi

MODKIT=$my_tools/modkit
SCRIPT_DIR=$1
ref=$2
group=$3
out_dir=$4
echo $group

mkdir -p $out_dir/get_methylation/read_breakdown/$group

if [[ $(ls $out_dir/alignment/read_breakdown/$group/* | wc -l) -gt 0 ]]; then
	for fp in $out_dir/alignment/read_breakdown/$group/*; do
		readname=$(basename $fp)
		echo $readname
		path=$out_dir/get_methylation/read_breakdown/$group/$readname
		mkdir -p $path $path/modkit_beds $path/logs
		for aln in $out_dir/alignment/read_breakdown/$group/$readname/*.bam; do
			num=$(basename $aln | cut -d. -f1)
			echo $num
			if [[ $# -eq 4 ]]; then
				$MODKIT/modkit pileup \
					--threads $cpus \
					--ref $ref \
					--cpg \
					--combine-strands \
					--ignore h \
					--only-tabs \
					--log $path/logs/$num.log \
					$aln \
					$path/modkit_beds/$num.bed
			else
				subregion_bed=$5
				subregion=$(awk '{printf "%s:%d-%d", $1, $2, $3}' $subregion_bed)
				$MODKIT/modkit pileup \
					--threads $cpus \
					--ref $ref \
					--region $subregion \
					--cpg \
					--combine-strands \
					--ignore h \
					--only-tabs \
					--log $path/logs/$num.log \
					$aln \
					$path/modkit_beds/$num.bed
			fi
		done
	done
fi
