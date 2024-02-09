#!/bin/bash

chimeras=$(awk '{print $1,$4}' $1 | sort | uniq | awk '{print $1}' | sort | uniq -c | awk '{if($1>1) print $2;}')

if [[ ${chimeras[0]} == "" ]]; then
    echo ""
else
    for chimera in ${chimeras[@]}; do
        echo $chimera
    done
fi 
