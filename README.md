# 45S_methyl_caller
Call as:
```
bash pipeline.sh $fastq_path $45S_ref $out_dir
```

`fastq_path` should contain fastq/fasta files (can be compressed or uncompressed) labeled with their group names (ie. `hap1.fasta`, `chr14.fastq.gz`, `species.fq`, `individual.fa`), these group names will be carried through the rest of the analysis.

General pipeline:
1. makes file structure for outputs
2. maps ONT reads to 45S ref (or any ref you give it)
3. splits up the alignments to get one alignment per file (filters out suspected chimeric reads with inverted 45S units)
4. calls modkit on these split alignments, getting per read methylation info (also calls on all reads per category)
5. summarizes data at the per group level, and the per unit level
6. ordering analysis: are neighboring units methylated more similarly than random units?
7. generates a per category violin plot

