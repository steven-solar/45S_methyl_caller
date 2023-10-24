#!/bin/bash

MODKIT=$my_tools/modkit

ref=$1

mkdir -p modkit_beds modkit_beds/logs read_breakdown

for bam in ../alignment/*.bam; do
    group=$(basename $bam | cut -d. -f1)
    echo "-----$group-----"
    $MODKIT/modkit pileup \
        --threads 32 \
        --ref $ref \
        --cpg \
        --combine-strands \
        --ignore h \
        --only-tabs \
        --log modkit_beds/logs/$group.log \
        ../alignment/$group.bam \
        modkit_beds/$group.bed

    mkdir -p read_breakdown/$group read_breakdown/$group

    for fp in ../alignment/read_breakdown/$group/*; do
        readname=$(basename $fp)
        echo $readname
        mkdir -p read_breakdown/$group/$readname/modkit_beds read_breakdown/$group/$readname/modkit_beds/logs
        for aln in ../alignment/read_breakdown/$group/$readname/*.bam; do
            num=$(basename $aln | cut -d. -f1)
            echo $num
            $MODKIT/modkit pileup \
                --threads 32 \
                --ref $ref \
                --cpg \
                --combine-strands \
                --ignore h \
                --only-tabs \
                --log read_breakdown/$group/$readname/modkit_beds/logs/$num.log \
                $aln \
                read_breakdown/$group/$readname/modkit_beds/$num.bed
        done
    done
done
