#!/bin/bash

SCRIPT_DIR=$1
out_dir=$2
doing_subregion=$3
doing_tr=$4

rm -f $out_dir/final_analysis/read_summary.txt

if [[ $doing_tr -eq 1 ]]; then
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
fi

rm -f $out_dir/final_analysis/group_summary.matched_windows.txt
touch $out_dir/final_analysis/group_summary.matched_windows.txt

for bam in $out_dir/alignment/*.bam; do
    group=$(basename $bam | cut -d. -f1)
    echo "$group"
    if [ -d $out_dir/alignment/read_breakdown/$group ]; then
        if [[ $(ls $out_dir/alignment/read_breakdown/$group | wc -l) -gt 0 ]]; then
            if [[ $doing_tr -eq 1 ]]; then
                avg_meth_pct=$(grep $group $out_dir/final_analysis/read_summary.txt | awk '{sum+=$4} END {print sum/NR}')
                echo $avg_meth_pct
            fi
        fi
    else
        if [[ $doing_subregion -eq 1 ]]; then
            avg_meth_pct=$(awk '{sum+=($11/100)} END {print sum/NR}' $out_dir/get_methylation/modkit_beds/$group.subregion.bed)
        else
            avg_meth_pct=$(awk '{sum+=($11/100)} END {print sum/NR}' $out_dir/get_methylation/modkit_beds/$group.whole_region.bed)
        fi
        echo $avg_meth_pct
    fi
    eighteen_S_cov=$(cat $out_dir/alignment/18S/$group.18S_cov.txt)
    echo $eighteen_S_cov
    genome_cov=$(cat $out_dir/final_analysis/genome_cov.matched_windows.txt)
    echo $genome_cov
    eighteen_S_cn=$(echo "1" | awk -v eighteen_S_cov=$eighteen_S_cov -v genome_cov=$genome_cov 'END {print 4*eighteen_S_cov/genome_cov}')
    echo $eighteen_S_cn
    active_18S=$(echo a | awk -v avg_meth_pct=$avg_meth_pct -v eighteen_S_cn=$eighteen_S_cn 'END { print eighteen_S_cn - (eighteen_S_cn*avg_meth_pct) }')
    if [[ $# -gt 2 ]]; then
        avg_tr_cn=$(grep $group $out_dir/final_analysis/read_summary.txt | awk '{sum+=$5} END {print sum/NR}')
        echo $avg_tr_cn
        echo -e "$group\t$eighteen_S_cn\t$avg_meth_pct\t$active_18S\t$avg_tr_cn" >> $out_dir/final_analysis/group_summary.matched_windows.txt
    else
        echo -e "$group\t$eighteen_S_cn\t$avg_meth_pct\t$active_18S" >> $out_dir/final_analysis/group_summary.matched_windows.txt
    fi
done

if [[ $doing_tr -eq 1 ]]; then
    avg_meth_pct=$(awk '{sum+=$4} END {print sum/NR}' $out_dir/final_analysis/read_summary.txt)
else
    avg_meth_pct=$(awk '{cn+=$2; weighted_meth+=($3*$2)} END {print weighted_meth/cn}' $out_dir/final_analysis/group_summary.matched_windows.txt)
fi

tot_eighteen_S_cn=$(awk '{sum+=$2} END { print sum }' $out_dir/final_analysis/group_summary.matched_windows.txt)
active_18S=$(awk '{sum+=$4} END {print sum}' $out_dir/final_analysis/group_summary.matched_windows.txt)

if [[ $# -gt 2 ]]; then
    avg_tr_cn=$(awk '{sum+=$5} END {print sum/NR}' $out_dir/final_analysis/read_summary.txt)
    echo -e "all\t$tot_eighteen_S_cn\t$avg_meth_pct\t$active_18S\t$avg_tr_cn" >> $out_dir/final_analysis/group_summary.matched_windows.txt
else
    echo -e "all\t$tot_eighteen_S_cn\t$avg_meth_pct\t$active_18S" >> $out_dir/final_analysis/group_summary.matched_windows.txt
fi

if [[ $# -gt 2 ]]; then
    rm -f $out_dir/final_analysis/tr_summary.txt
    touch $out_dir/final_analysis/tr_summary.txt
    while read -r tr; do
        avg_meth_pct=$(awk -v tr=$tr '$5 == tr { sum+=$4; count++ } END { print sum/count }' $out_dir/final_analysis/read_summary.txt)
        echo -e "$tr\t$avg_meth_pct" >> $out_dir/final_analysis/tr_summary.txt
    done < <(awk '{print $5}' $out_dir/final_analysis/read_summary.txt | sort | uniq)
fi

echo $active_18S > $out_dir/final_analysis/active_45S.txt
