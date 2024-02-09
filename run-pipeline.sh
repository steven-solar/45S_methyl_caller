#!/bin/bash

fastq_path="../remap/chr_specific/fastqs"
ref="refs/KY962518-ROT.fa"
out_dir="KY962518-ROT_only45S"
gene_bed="../45S_on_KY-ROT.bed"

bash pipeline.sh $fastq_path $ref $out_dir $gene_bed
