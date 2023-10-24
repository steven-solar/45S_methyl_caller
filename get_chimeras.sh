#!/bin/bash

chimeras=$(awk '{print $1,$4}' $1 | sort | uniq | awk '{print $1}' | sort | uniq -c | awk '{if($1>1) print $2;}')

if [[ ${chimeras[0]} == "" ]]; then
    echo ""
else
    grep_str=""
    for chimera in ${chimeras[@]}; do
        grep_str+="$chimera|"
    done
    grep_str=${grep_str::-1}
    echo $grep_str
fi 
