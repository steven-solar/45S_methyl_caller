#!/bin/bash

ml load bedtools minimap2 samtools seqtk

SCRIPT_DIR=/data/Phillippy2/projects/chm13_rdna_methylation_reanalysis/final_45S_caller_scripts

fastq_path=$1
ref=$2
out_dir=$3
optional_subregion_bed=$4

echo "fastq_path $1"
echo "ref $2"
echo "out_dir $3"
echo "optional_subregion_bed $4"
echo $#

if [[ $# -gt 4 ]]; then
	TR_bed=$5
	echo $TR_bed
	TR_fa="${TR_bed%.*}.fa"
	echo $TR_fa
	bedtools getfasta -fi $ref -fo $TR_fa -bed $TR_bed
	samtools faidx $TR_fa
	echo "done"
fi

mkdir -p $out_dir $out_dir/alignment $out_dir/alignment/read_breakdown $out_dir/get_methylation $out_dir/get_methylation/logs $out_dir/methylation_analysis

cd $out_dir/alignment
for fastq in $fastq_path/unmap.fq.gz; do
	echo $fastq
    group=$(basename $fastq | cut -d. -f1)
    echo $group
    jid="$(sbatch --time=04:00:00 --partition=norm,quick --mem=64g --cpus-per-task=16 -o $group.out $SCRIPT_DIR/map_to_ref_and_split_per_group.sh $fastq $ref)"
	# bash $SCRIPT_DIR/map_to_ref_and_split_per_group.sh $fastq $ref &> $group.out 
	cd ../get_methylation
	if [[ $# -eq 3 ]]; then
		# bash $SCRIPT_DIR/get_methylation_per_group.sh $ref &> $group.out 
		# jids+=":$(sbatch --time=04:00:00 --partition=norm,quick --mem=64g --cpus-per-task=16 -o $group.out --dependency=afterok:$jid $SCRIPT_DIR/get_methylation_per_group.sh $ref $group)"
		echo "eq3"
	elif [[ $# -gt 3 ]]; then
		# jids+=":$(sbatch --time=04:00:00 --partition=norm,quick --mem=64g --cpus-per-task=16 -o $group.out --dependency=afterok:$jid $SCRIPT_DIR/get_methylation_per_group.sh $ref $group $optional_subregion_bed $TR_fa $fastq_path)"
		jids+=":$(sbatch --time=1-00:00:00 --mem=16g --cpus-per-task=16 -o $group.out $SCRIPT_DIR/get_methylation_per_group.sh $ref $group $optional_subregion_bed $TR_fa $fastq_path)"
		# bash $SCRIPT_DIR/get_methylation_per_group.sh $ref $group $optional_subregion_bed $TR_fa $fastq_path
	else
		echo "lt 3"
		# jids+=":$(sbatch --time=04:00:00 --partition=norm,quick --mem=64g --cpus-per-task=16 -o $group.out --dependency=afterok:$jid $SCRIPT_DIR/get_methylation_per_group.sh $ref $group $optional_subregion_bed)"
	fi
	cd ../alignment
done

cd ../methylation_analysis

if [[ $# -gt 3 ]]; then
	# bash $SCRIPT_DIR/summary_and_analysis.sh 1
	sbatch --time=04:00:00 --mem=32g --cpus-per-task=4 -o out.txt --dependency=afterok$jids $SCRIPT_DIR/summary_and_analysis.sh 1
else
	# bash $SCRIPT_DIR/summary_and_analysis.sh
	sbatch --time=04:00:00 --mem=32g --cpus-per-task=4 -o out.txt --dependency=afterok$jids $SCRIPT_DIR/summary_and_analysis.sh
fi
