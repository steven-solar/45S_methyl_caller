#!/bin/bash

SCRIPT_DIR=$1
samples=$2
info=$3
out=$4

# rm -f $out
rm -f all_read_summary.txt
touch all_read_summary.txt

while read -r sample; do
# 	echo $sample
# 	eighteen_S_cn=$(grep "18S_CN" $sample/final_analysis/summary.txt | awk '{print $2}')
# 	meth_pct=$(grep "meth_pct" $sample/final_analysis/summary.txt | awk '{print $2}')
# 	sex=$(grep -w $sample $info | awk '{print $2}')
# 	age=$(grep -w $sample $info | awk '{print $3}')
# 	echo -e "$sample\t$sex\t$age\t$eighteen_S_cn\t$meth_pct" >> $out
	cat $sample/final_analysis/read_summary.txt >> all_read_summary.txt
done < $samples

python $SCRIPT_DIR/get_sample_distribution.py all_read_summary.txt all_methylation_distribution.png