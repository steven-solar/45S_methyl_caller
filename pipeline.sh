#!/bin/bash

BASE_DIR=/data/Phillippy/projects/chm13_rdna_methylation_reanalysis
fastq_path=$1
ref=$2
out_dir=$3

prefix=$(basename $ref | cut -d. -f1)

mkdir -p $out_dir $out_dir/alignment $out_dir/get_methylation $out_dir/methylation_analysis

cd $out_dir/alignment

bash $BASE_DIR/map_to_ref.sh $BASE_DIR/$fastq_path $BASE_DIR/$ref $prefix $BASE_DIR
bash $BASE_DIR/split_alignments.sh $BASE_DIR

cd ../get_methylation

bash $BASE_DIR/get_methylation.sh $BASE_DIR/$ref

cd ../methylation_analysis

bash $BASE_DIR/get_read_summary.sh

python $BASE_DIR/run_ordering_analysis.py read_summary.txt > ordering_analysis.out
python $BASE_DIR/violin_plot.py read_summary.txt $prefix
