#!/bin/bash

rm -f read_summary.txt
touch read_summary.txt

for bam in ../alignment/*.bam; do
    group=$(basename $bam | cut -d. -f1)
    echo "$group"
    for bed in ../get_methylation/read_breakdown/$group/*/modkit_beds/*.bed; do
        readname=$(echo $bed | cut -d \/ -f5)
        num=$(basename $bed | cut -d. -f1)
        meth_pct=$(awk '{sum+=$12} END {print sum/NR}' $bed)
        echo -e "$group\t$readname\t$num\t$meth_pct" >> read_summary.txt
    done
done

rm -f group_summary.txt
touch group_summary.txt

for bam in ../alignment/*.bam; do
    group=$(basename $bam | cut -d. -f1)
    echo "$group"
    avg_meth_pct=$(grep $group read_summary.txt | awk '{sum+=$4} END {print sum/NR}')
    echo -e "$group\t$avg_meth_pct" >> group_summary.txt
done

avg_meth_pct=$(awk '{sum+=$4} END {print sum/NR}' read_summary.txt)
echo -e "all\t$avg_meth_pct" >> group_summary.txt

