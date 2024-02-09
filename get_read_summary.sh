#!/bin/bash

SCRIPT_DIR=$1
out_dir=$2
doing_tr=$3

rm -f $out_dir/final_analysis/read_summary.txt
touch $out_dir/final_analysis/read_summary.txt

for bam in $out_dir/alignment/*.bam; do
    group=$(basename $bam | cut -d. -f1)
    echo "$group"
    ls $out_dir/alignment/read_breakdown/$group | wc -l
    if [[ $(ls $out_dir/alignment/read_breakdown/$group | wc -l) -gt 0 ]]; then
        for bed in $out_dir/get_methylation/read_breakdown/$group/*/modkit_beds/*.bed; do
            readname=$(echo $bed | cut -d \/ -f5)
            num=$(basename $bed | cut -d. -f1)
            meth_pct=$(awk '{sum+=$12} END {print sum/NR}' $bed)
            if [[ $# -gt 2 ]]; then
                tr_cn=$(awk '{print $2}' $out_dir/get_TR/read_breakdown/$group/$readname/$num.TR_CN.txt)
                echo -e "$group\t$readname\t$num\t$meth_pct\t$tr_cn" >> $out_dir/final_analysis/read_summary.txt
            else
                echo -e "$group\t$readname\t$num\t$meth_pct" >> $out_dir/final_analysis/read_summary.txt
            fi
        done
    fi
done

python $SCRIPT_DIR/get_sample_distribution.py $out_dir/final_analysis/read_summary.txt $out_dir/final_analysis/methylation_distribution.png

rm -f $out_dir/final_analysis/group_summary.txt
touch $out_dir/final_analysis/group_summary.txt

for bam in $out_dir/alignment/*.bam; do
    group=$(basename $bam | cut -d. -f1)
    echo "$group"
    if [ -d $out_dir/alignment/read_breakdown/$group ]; then
        if [[ $(ls $out_dir/alignment/read_breakdown/$group | wc -l) -gt 0 ]]; then
            avg_meth_pct=$(grep $group $out_dir/final_analysis/read_summary.txt | awk '{sum+=$4} END {print sum/NR}')
            echo $avg_meth_pct
            eighteen_S_cov=$(cat $out_dir/alignment/18S/$group.18S_cov.txt)
            echo $eighteen_S_cov
            genome_cov=$(cat $out_dir/final_analysis/genome_cov.txt)
            echo $genome_cov
            eighteen_S_cn=$(echo "1" | awk -v gene_cov=$eighteen_S_cov -v genome_cov=$genome_cov 'END {print gene_cov/genome_cov}')
            echo $eighteen_S_cn
            if [[ $# -gt 2 ]]; then
                avg_tr_cn=$(grep $group $out_dir/final_analysis/read_summary.txt | awk '{sum+=$5} END {print sum/NR}')
                echo $avg_tr_cn
                echo -e "$group\t$eighteen_S_cn\t$avg_meth_pct\t$avg_tr_cn" >> $out_dir/final_analysis/group_summary.txt
            else
                echo -e "$group\t$eighteen_S_cn\t$avg_meth_pct" >> $out_dir/final_analysis/group_summary.txt
            fi
        fi
    else
        echo "no reads in group $group"
    fi
done

avg_meth_pct=$(awk '{sum+=$4} END {print sum/NR}' $out_dir/final_analysis/read_summary.txt)
if [[ $# -gt 2 ]]; then
    avg_tr_cn=$(awk '{sum+=$5} END {print sum/NR}' $out_dir/final_analysis/read_summary.txt)
    tot_eighteen_S_cn=$(awk '{sum+=($2*2)}' $out_dir/final_analysis/group_summary.txt)
    echo -e "all\t$tot_eighteen_S_cn\t$avg_meth_pct\t$avg_tr_cn" >> $out_dir/final_analysis/group_summary.txt
else
    echo -e "all\t$tot_eighteen_S_cn\t$avg_meth_pct" >> $out_dir/final_analysis/group_summary.txt
fi

if [[ $# -gt 2 ]]; then
    rm -f $out_dir/final_analysis/tr_summary.txt
    touch $out_dir/final_analysis/tr_summary.txt
    while read -r tr; do
        avg_meth_pct=$(awk -v tr=$tr '$5 == tr { sum+=$4; count++ } END { print sum/count }' $out_dir/final_analysis/read_summary.txt)
        echo -e "$tr\t$avg_meth_pct" >> $out_dir/final_analysis/tr_summary.txt
    done < <(awk '{print $5}' $out_dir/final_analysis/read_summary.txt | sort | uniq)
fi
