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

meth_jids=""
TR_jids=""
eighteen_S_jids=""

for fastq in $out_dir/fastqs/*.fq.gz; do
	echo $fastq
    group=$(basename $fastq | cut -d. -f1)
    echo "calling on $group"
	if [ ! -s $out_dir/alignment/logs/$group.success.txt ]; then
    	map_jid="$(sbatch \
			--time=3-00:00:00 \
			--partition=norm \
			--mem=64g \
			--cpus-per-task=8 \
			-o $out_dir/alignment/logs/$group.out \
			$SCRIPT_DIR/map_to_ref_and_split_per_group.sh \
				$SCRIPT_DIR \
				$fastq \
				$ref \
				$out_dir)"

		echo "$group map job id : $map_jid"
	fi

	eighteen_S_jid="$(sbatch \
				--time=04:00:00 \
				--mem=32g \
				--partition=norm,quick \
				--cpus-per-task=8 \
				--dependency=afterok:$map_jid \
				-o $out_dir/alignment/18S/logs/$group.out \
				$SCRIPT_DIR/get_18S_cov.sh \
					$SCRIPT_DIR \
					$fastq \
					$eighteen_S_fa \
					$out_dir)"

	echo "$group 18S job id : $eighteen_S_jid"
	eighteen_S_jids+=":$eighteen_S_jid"

	if [[ ${#map_jid} -gt 0 ]]; then
		meth_jid="$(sbatch \
						--time=04:00:00 \
						--partition=norm,quick \
						--mem=32g \
						--cpus-per-task=8 \
						-o $out_dir/get_methylation/logs/$group.whole_region.out \
						--dependency=afterok:$map_jid \
						$SCRIPT_DIR/get_methylation_whole_group.sh \
							$SCRIPT_DIR \
							$ref \
							$group \
							$out_dir)"

		echo "$group methylation job id : $meth_jid"
		meth_jids+=":$meth_jid"
	else
		meth_jid="$(sbatch \
						--time=04:00:00 \
						--partition=norm,quick \
						--mem=32g \
						--cpus-per-task=8 \
						-o $out_dir/get_methylation/logs/$group.whole_region.out \
						$SCRIPT_DIR/get_methylation_whole_group.sh \
							$SCRIPT_DIR \
							$ref \
							$group \
							$out_dir)"
		echo "$group methylation job id : $meth_jid"
		meth_jids+=":$meth_jid"
	fi

	if [[ $# -gt 7 ]]; then # get methylation breakdown of the subregion
		if [[ ${#map_jid} -gt 0 ]]; then
			meth_jid="$(sbatch \
						--time=1-00:00:00 \
						--mem=64g \
						--cpus-per-task=32 \
						-o $out_dir/get_methylation/logs/$group.breakdown.out \
						--dependency=afterok:$map_jid \
						$SCRIPT_DIR/get_methylation_breakdown.sh \
							$SCRIPT_DIR \
							$ref \
							$group \
							$out_dir \
							$fortyfive_S_bed)"

			echo "$group methylation breakdown job id : $meth_jid"
			meth_jids+=":$meth_jid"
		else
			meth_jid="$(sbatch \
						--time=1-00:00:00 \
						--mem=64g \
						--cpus-per-task=32 \
						-o $out_dir/get_methylation/logs/$group.breakdown.out \
						$SCRIPT_DIR/get_methylation_breakdown.sh \
							$SCRIPT_DIR \
							$ref \
							$group \
							$out_dir \
							$fortyfive_S_bed)"
			echo "$group methylation breakdown job id : $meth_jid"
			meth_jids+=":$meth_jid"
		fi
	fi

	if [[ $# -eq 9 ]]; then # get TR copy num
		if [[ ${#map_jids} -gt 0 ]]; then
			TR_jid="$(sbatch \
							--time=04:00:00 \
							--partition=norm,quick \
							--mem=8g \
							-o $out_dir/get_TR/logs/$group.out \
							--dependency=afterok$map_jids \
							$SCRIPT_DIR/get_TR_breakdown.sh \
								$SCRIPT_DIR \
								$group \
								$out_dir \
								$TR_fa)"
			echo "$group TR job id : $TR_jid"
			TR_jids+=":$TR_jid"
		else
			TR_jid="$(sbatch \
							--time=04:00:00 \
							--partition=norm,quick \
							--mem=8g \
							-o $out_dir/get_TR/logs/$group.out \
							$SCRIPT_DIR/get_TR_breakdown.sh \
								$SCRIPT_DIR \
								$group \
								$out_dir \
								$TR_fa)"
			echo "$group TR job id : $TR_jid"
			TR_jids+=":$TR_jid"
		fi
	fi
done

all_jids=""
all_jids=$genome_cov_jid
all_jids+=$eighteen_S_jids
all_jids+=$meth_jids
all_jids+=$TR_jids

if [[ ${all_jids:0:1} == ":" ]]; then
	all_jids="${all_jids:1}"
fi

echo "all dependency job ids - $all_jids"

if [[ ${#all_jids} -gt 0 ]]; then
	if [[ $# -gt 8 ]]; then
		sbatch --time=04:00:00 --mem=16g --partition=norm,quick --cpus-per-task=4 -o $out_dir/logs/summary.txt --dependency=afterok:$all_jids $SCRIPT_DIR/summary_and_analysis.sh $SCRIPT_DIR $out_dir 1
	else
		sbatch --time=04:00:00 --mem=16g --partition=norm,quick --cpus-per-task=4 -o $out_dir/logs/summary.txt --dependency=afterok:$all_jids $SCRIPT_DIR/summary_and_analysis.sh $SCRIPT_DIR $out_dir
	fi
else
	if [[ $# -gt 8 ]]; then
		sbatch --time=04:00:00 --mem=16g --partition=norm,quick --cpus-per-task=4 -o $out_dir/logs/summary.txt $SCRIPT_DIR/summary_and_analysis.sh $SCRIPT_DIR $out_dir 1
	else
		sbatch --time=04:00:00 --mem=16g --partition=norm,quick --cpus-per-task=4 -o $out_dir/logs/summary.txt $SCRIPT_DIR/summary_and_analysis.sh $SCRIPT_DIR $out_dir
	fi
fi
