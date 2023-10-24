#!/bin/bash

MODKIT=$my_tools/modkit

ref=$1

chrs=("chr13" "chr14" "chr15" "chr21" "chr22" "none")

mkdir -p modkit_beds modkit_beds/logs read_breakdown

for chr in ${chrs[@]}; do
    echo "-----$chr-----"
    $MODKIT/modkit pileup \
        --threads 32 \
        --ref $ref \
        --cpg \
        --combine-strands \
        --ignore h \
        --only-tabs \
        --log modkit_beds/logs/$chr.log \
        ../alignment/$chr.bam \
        modkit_beds/$chr.bed

    mkdir -p read_breakdown/$chr read_breakdown/$chr

    for fp in ../alignment/read_breakdown/$chr/*; do
        readname=$(basename $fp)
        echo $readname
        mkdir -p read_breakdown/$chr/$readname/modkit_beds read_breakdown/$chr/$readname/modkit_beds/logs
        for aln in ../alignment/read_breakdown/$chr/$readname/*.bam; do
            num=$(basename $aln | cut -d. -f1)
            echo $num
            $MODKIT/modkit pileup \
                --threads 32 \
                --ref $ref \
                --cpg \
                --combine-strands \
                --ignore h \
                --only-tabs \
                --log read_breakdown/$chr/$readname/modkit_beds/logs/$num.log \
                $aln \
                read_breakdown/$chr/$readname/modkit_beds/$num.bed
        done
    done
done
