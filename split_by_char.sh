#!/bin/bash

if [ -z ${SLURM_CPUS_PER_TASK+x} ]; then
    cpus=32
else
    cpus=$SLURM_CPUS_PER_TASK
fi

SCRIPT_DIR=$1
breakdown_dir=$2
prefix=$3
temp_prefix=$4
fastq=$5
first_char=$6

echo "SCRIPT_DIR=$1
breakdown_dir=$2
prefix=$3
temp_prefix=$4
fastq=$5
first_char=$6"

while read line; do
  readname=$(echo $line | awk '{print $1}')
  if [ -f $breakdown_dir/$readname/$readname.fa ]; then
    continue
  fi
  flag=$(echo $line | awk '{print $2}')
  echo $readname
  mkdir -p $breakdown_dir/$readname
  echo $readname > $breakdown_dir/$readname/$readname.lst
  if [[ $flag -eq 16 ]]; then
		seqtk subseq $fastq $breakdown_dir/$readname/$readname.lst | seqtk seq -r | bgzip -@$cpus > $breakdown_dir/$readname/$readname.fq.gz
    echo "True" > $breakdown_dir/$readname/$readname.reverse
  else
		seqtk subseq $fastq $breakdown_dir/$readname/$readname.lst | bgzip -@$cpus > $breakdown_dir/$readname/$readname.fq.gz
    echo "False" > $breakdown_dir/$readname/$readname.reverse
  fi
  seqtk seq -a $breakdown_dir/$readname/$readname.fq.gz > $breakdown_dir/$readname/$readname.fa
  samtools faidx $breakdown_dir/$readname/$readname.fa
done <  <(samtools view -@$cpus $prefix.bam | grep "^$first_char")

samtools view -@$cpus $prefix.bam | grep "^$first_char" | python $SCRIPT_DIR/split.py $breakdown_dir $temp_prefix.just_header.sam

if [[ $(ls $breakdown_dir/$first_char*/*.sam | wc -l) -gt 0 ]]; then
  for sam in $breakdown_dir/$first_char*/*.sam; do
      sam_path=$(echo $sam | cut -d. -f 1)
      readname=$(echo $sam | cut -d/ -f 5)
      readlen=$(awk '{print $2}' $breakdown_dir/$readname/$readname.fa.fai)
      samtools view -@$cpus -h -O BAM --write-index -o $sam_path.bam##idx##$sam_path.bam.bai $sam
      if [[ $(cat $breakdown_dir/$readname/$readname.reverse) == "True" ]]; then
        echo "$readname is reversed"
        paftools.js sam2paf $sam_path.sam | awk -v OFS='\t' -v len=$readlen '{print $1,len-$4,len-$3}' > $sam_path.bed
      else
        echo "$readname is already forward"
        paftools.js sam2paf $sam_path.sam | awk -v OFS='\t' '{print $1,$3,$4}' > $sam_path.bed
      fi
      bedtools getfasta -fi $breakdown_dir/$readname/$readname.fa -bed $sam_path.bed -fo $sam_path.fa
  done
fi
