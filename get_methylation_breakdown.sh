#!/bin/bash

ml load modkit

MAX_JOBS=32

if [ -z ${SLURM_CPUS_PER_TASK+x} ]; then
    cpus=32
else
    cpus=$SLURM_CPUS_PER_TASK
fi

get_meth_read()
{
	SCRIPT_DIR=$1
	ref=$2
	group=$3
	out_dir=$4
	readname=$5
	subregion_bed=$6

	echo $readname
	path=$out_dir/get_methylation/read_breakdown/$group/$readname
	mkdir -p $path $path/modkit_beds $path/logs
	for aln in $out_dir/alignment/read_breakdown/$group/$readname/*.bam; do
		num=$(basename $aln | cut -d. -f1)
		echo $num
		if [[ $# -eq 5 ]]; then
			modkit pileup \
				--threads 1 \
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
			modkit pileup \
				--threads 1 \
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

}

SCRIPT_DIR=$1
ref=$2
group=$3
out_dir=$4
subregion_bed=$5
echo $group

mkdir -p $out_dir/get_methylation/read_breakdown/$group

if [[ $(ls $out_dir/alignment/read_breakdown/$group/* | wc -l) -gt 0 ]]; then
	for fp in $out_dir/alignment/read_breakdown/$group/*; do
		readname=$(basename $fp)
		while [ `jobs -p | wc -l` -ge ${MAX_JOBS} ]
		do
			sleep 5
		done
		get_meth_read $SCRIPT_DIR $ref $group $out_dir $readname $subregion_bed &
	done
	wait `jobs -p`
fi
