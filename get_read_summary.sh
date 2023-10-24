#!/bin/bash

chrs=("chr13" "chr14" "chr15" "chr21" "chr22" "none")

rm -f read_summary.txt
touch read_summary.txt

for chr in ${chrs[@]}; do
    echo "$chr"
    for bed in ../get_methylation/read_breakdown/$chr/*/modkit_beds/*.bed; do
        readname=$(echo $bed | cut -d \/ -f5)
        num=$(basename $bed | cut -d. -f1)
        meth_pct=$(awk '{sum+=$12} END {print sum/NR}' $bed)
        echo -e "$chr\t$readname\t$num\t$meth_pct" >> read_summary.txt
    done
done

rm -f chr_summary.txt
touch chr_summary.txt

for chr in ${chrs[@]}; do
    echo "$chr"
    avg_meth_pct=$(grep $chr read_summary.txt | awk '{sum+=$4} END {print sum/NR}')
    echo -e "$chr\t$avg_meth_pct" >> chr_summary.txt
done

avg_meth_pct=$(awk '{sum+=$4} END {print sum/NR}' read_summary.txt)
echo -e "all\t$avg_meth_pct" >> chr_summary.txt

