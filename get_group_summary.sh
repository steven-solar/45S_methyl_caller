#!/bin/bash

SCRIPT_DIR=$1
out_dir=$2

rm -f $out_dir/final_analysis/group_summary.txt
touch $out_dir/final_analysis/group_summary.txt

genome_cov=$(cat $out_dir/final_analysis/genome_cov.txt)

tot_weighted_meth_pct=0
tot_count=0
for bam in $out_dir/alignment/*.bam; do
    group=$(basename $bam | cut -d. -f1)
    echo "$group"
    if [[ -f $out_dir/get_methylation/modkit_beds/$group.whole_region.bed && -f $out_dir/alignment/18S/$group.18S_cov.txt ]]; then
        meth_pct=$(awk '{sum+=$11} END {print sum/NR}' $out_dir/get_methylation/modkit_beds/$group.whole_region.bed)
        count=$(samtools view -c $bam)
        weighted_meth_pct=$(echo a | awk -v meth_pct=$meth_pct -v count=$count 'END { print meth_pct*count }')
        tot_weighted_meth_pct=$(echo a | awk -v tot=$tot_weighted_meth_pct -v weighted_meth_pct=$weighted_meth_pct 'END { print tot+weighted_meth_pct }')
        tot_count=$(echo a | awk -v tot=$tot_count -v count=$count 'END { print tot+count }')
        eighteen_S_cov=$(cat $out_dir/alignment/18S/$group.18S_cov.txt)
        eighteen_S_cn=$(echo a | awk -v gene_cov=$eighteen_S_cov -v genome_cov=$genome_cov 'END {print gene_cov/genome_cov}')
        echo -e "$group\t$eighteen_S_cn\t$meth_pct" >> $out_dir/final_analysis/group_summary.txt
    fi
done

avg_meth_pct=$(echo a | awk -v tot_weighted_meth_pct=$tot_weighted_meth_pct -v tot_count=$tot_count 'END { print tot_weighted_meth_pct/tot_count }')
tot_eighteen_S_cn=$(awk '{sum+=($2*2)} END { print sum }' $out_dir/final_analysis/group_summary.txt)
active_18S=$(echo a | awk -v avg_meth_pct=$avg_meth_pct -v tot_eighteen_S_cn=$tot_eighteen_S_cn 'END { print tot_eighteen_S_cn*avg_meth_pct }')
echo -e "18S_CN: $tot_eighteen_S_cn\nmeth_pct: $avg_meth_pct\nactive_18S: $active_18S" > $out_dir/final_analysis/summary.txt
