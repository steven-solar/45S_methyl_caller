import sys
import re

def parse_cigar(cigar):
    

sam_no_header_f = open(sys.argv[1])
paf_f = open(sys.argv[2])
output_type = sys.argv[3]
subregion=(int(sys.argv[4]), int(sys.argv[5]))

regex_str = 'de:f:(0|\d+\.\d+)'
for paf_line, sam_line in zip(paf_f, sam_no_header_f):
    paf_line_split = paf_line.strip().split('\t')
    sam_line_split = sam_line.strip().split('\t')
    q_start, q_end, t_start, t_end = int(paf_line_split[2]), int(paf_line_split[3]), int(paf_line_split[7]), int(paf_line_split[8])
    q_len, matching_bases, aln_block = int(paf_line_split[6]), int(paf_line_split[9]), int(paf_line_split[10])
    de_flag = re.findall(regex_str, sam_line)[0]
    ani = 1 - float(de_flag)
    if aln_block >= 0.9 * q_len and ani >= 0.9:
        if output_type == 'sam':
            print(sam_line.strip())
        elif output_type == 'paf':
            print(paf_line.strip())
