#!/bin/bash

MAX_JOBS=32

if [ -z ${SLURM_CPUS_PER_TASK+x} ]; then
    cpus=32
else
    cpus=$SLURM_CPUS_PER_TASK
fi

get_TRs_read()
{
	SCRIPT_DIR=$1
	group=$2
	out_dir=$3
	TR_fa=$4
	readname=$5
	echo $readname
	path=$out_dir/get_TR/read_breakdown/$group/$readname
	mkdir -p $path
	for aln in $out_dir/alignment/read_breakdown/$group/$readname/*.bam; do
		num=$(basename $aln | cut -d. -f1)
		echo $num
		minimap2 \
			-t 1 \
			-a \
			-x map-ont \
			--MD \
			-n 2 \
			-m 25 \
			-P \
			$TR_fa \
			$out_dir/alignment/read_breakdown/$group/$readname/$num.fa > $path/$num.sam
		paftools.js sam2paf $path/$num.sam > $path/$num.paf
		samtools view -@$cpus $path/$num.sam > $path/$num.no_header.sam
		samtools view -@$cpus -H $path/$num.sam > $path/$num.just_header.sam
		python $SCRIPT_DIR/filter_both_TR.py $path/$num.no_header.sam $path/$num.paf sam > $path/$num.filtered.sam
		python $SCRIPT_DIR/filter_both_TR.py $path/$num.no_header.sam $path/$num.paf paf > $path/$num.filtered.paf
		echo -e "$readname\t$(python $SCRIPT_DIR/get_TR_cn.py $path/$num.filtered.paf)" > $path/$num.TR_CN.txt
	done
}

SCRIPT_DIR=$1
group=$2
out_dir=$3
TR_fa=$4
echo $group

if [[ $(ls $out_dir/alignment/read_breakdown/$group | wc -l) -gt 0 ]]; then
	for fp in $out_dir/alignment/read_breakdown/$group/*; do
		readname=$(basename $fp)
		while [ `jobs -p | wc -l` -ge ${MAX_JOBS} ]
		do
			sleep 5
		done
		get_TRs_read $SCRIPT_DIR $group $out_dir $TR_fa $readname &
		# echo $readname
		# path=$out_dir/get_TR/read_breakdown/$group/$readname
		# mkdir -p $path
		# for aln in $out_dir/alignment/read_breakdown/$group/$readname/*.bam; do
		# 	num=$(basename $aln | cut -d. -f1)
		# 	echo $num
		# 	minimap2 \
		# 		-t $cpus \
		# 		-a \
		# 		-x map-ont \
		# 		--MD \
		# 		-n 2 \
		# 		-m 25 \
		# 		-P \
		# 		$TR_fa \
		# 		$out_dir/alignment/read_breakdown/$group/$readname/$num.fa > $path/$num.sam
		# 	paftools.js sam2paf $path/$num.sam > $path/$num.paf
		# 	samtools view -@$cpus $path/$num.sam > $path/$num.no_header.sam
		# 	samtools view -@$cpus -H $path/$num.sam > $path/$num.just_header.sam
		# 	python $SCRIPT_DIR/filter_both_TR.py $path/$num.no_header.sam $path/$num.paf sam > $path/$num.filtered.sam
		# 	python $SCRIPT_DIR/filter_both_TR.py $path/$num.no_header.sam $path/$num.paf paf > $path/$num.filtered.paf
		# 	echo -e "$readname\t$(python $SCRIPT_DIR/get_TR_cn.py $path/$num.filtered.paf)" > $path/$num.TR_CN.txt
		# done
	done
	wait `jobs -p`
fi
