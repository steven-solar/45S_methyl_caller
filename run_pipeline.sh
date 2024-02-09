#!/bin/bash

SCRIPT_DIR=$1
bam=$2
chr_list_f=$3
ref=$4
out_dir=$5
genome_bed=$6
eighteen_S_fa=$7
fortyfive_S_bed=$8
TR_fa=$9

echo "SCRIPT_DIR=$1
bam=$2
chr_list_f=$3
ref=$4
out_dir=$5
genome_bed=$6
eighteen_S_fa=$7
fortyfive_S_bed=$8
TR_fa=$9"

mkdir -p $out_dir $out_dir/logs $out_dir/fastqs
mkdir -p $out_dir/alignment $out_dir/alignment/logs $out_dir/alignment/temp $out_dir/alignment/read_breakdown 
mkdir -p $out_dir/alignment/18S $out_dir/alignment/18S/logs $out_dir/alignment/18S/temp
mkdir -p $out_dir/get_methylation $out_dir/get_methylation/modkit_beds $out_dir/get_methylation/logs $out_dir/get_methylation/read_breakdown
mkdir -p $out_dir/final_analysis

if [[ $# -eq 9 ]]; then
	mkdir -p $out_dir/get_TR $out_dir/get_TR/logs $out_dir/get_TR/read_breakdown
fi

fq_jids="" 

echo "out_dir $out_dir"

while read -r chr; do
	if [ ! -f $out_dir/fastqs/$chr.fq.gz ]; then
		echo $chr
		echo "sbatch --time=04:00:00 --partition=norm,quick --mem=16g --cpus-per-task=8 -o $out_dir/logs/setup_fqs.$chr.out $SCRIPT_DIR/setup_fqs_from_bam_per_group.sh $bam $chr $out_dir/fastqs"
		fq_jids+=":$(sbatch --time=04:00:00 --partition=norm,quick --mem=16g --cpus-per-task=8 -o $out_dir/logs/setup_fqs.$chr.out $SCRIPT_DIR/setup_fqs_from_bam_per_group.sh $bam $chr $out_dir/fastqs)"
	else
		echo "$chr fq exists"
	fi
done < $chr_list_f

if [ ! -f $out_dir/fastqs/unmap.fq.gz ]; then
	echo "sbatch --time=04:00:00 --partition=norm,quick --mem=16g --cpus-per-task=8 -o $out_dir/logs/setup_fqs.unmap.out $SCRIPT_DIR/get_unmapped.sh $bam $out_dir/fastqs"
	fq_jids+=":$(sbatch --time=04:00:00 --partition=norm,quick --mem=16g --cpus-per-task=8 -o $out_dir/logs/setup_fqs.unmap.out $SCRIPT_DIR/get_unmapped.sh $bam $out_dir/fastqs)"
else
	echo "unmapped fq exists"
fi

if [[ ${#fq_jids} -gt 0 ]]; then
	echo $fq_jids
fi

if [ ! -f $out_dir/final_analysis/genome_cov.txt ]; then
	echo "calculating genome cov..."
	genome_cov_jid=$(sbatch \
		--time=04:00:00 \
		--partition=norm,quick \
		--mem=8g \
		--cpus-per-task=16 \
		-o $out_dir/logs/get_cov.out \
		$SCRIPT_DIR/get_cov.sh \
			$bam \
			$genome_bed \
			$out_dir/final_analysis/genome_cov.txt)
	echo $genome_cov_jid
	echo "$genome_cov_jid" > $out_dir/genome_cov_jid.txt
else
	echo "genome_cov.txt exists"
fi

if [[ ${#fq_jids} -gt 0 ]]; then
	sbatch --time=01:00:00 --partition=norm,quick -o $out_dir/pipeline.out --dependency=afterok$fq_jids $SCRIPT_DIR/pipeline.sh $1 $2 $3 $4 $5 $6 $7 $8 $9
else
	sbatch --time=01:00:00 --partition=norm,quick -o $out_dir/pipeline.out $SCRIPT_DIR/pipeline.sh $1 $2 $3 $4 $5 $6 $7 $8 $9
fi

bash $SCRIPT_DIR/pipeline.sh $1 $2 $3 $4 $5 $6 $7 $8 $9
