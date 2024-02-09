import sys
import re

def overlap(curr_region, wanted_region):
	if curr_region[1] < wanted_region[0] or curr_region[0] > wanted_region[1]:
		return 0
	overlap = min(curr_region[1], wanted_region[1]) - max(curr_region[0], wanted_region[0])
	return overlap / (wanted_region[1] - wanted_region[0])

def subregion_ani(t_region, wanted_region, cigar):
	cigar_pattern = r'(\d+)([MIDNSHP=X])'
	cigar_tuples = re.findall(cigar_pattern, cigar)
	ops, lengths = zip(*cigar_tuples)
	curr_pos = t_region[0]
	matching_bases = 0
	for i in range(len(ops)):
		op, length = ops[i], lengths[i]
		if curr_pos >= wanted_region[0] and curr_pos <= wanted_region[1]:
			if op in ['M', '==', 'X']:
				matching_bases += length
		if op in ['M', '=', 'X', 'D', 'N']:
			curr_pos += length
	return matching_bases / (wanted_region[1] - wanted_region[0])

sam_no_header_f = open(sys.argv[1])
paf_f = open(sys.argv[2])
output_type = sys.argv[3]

want_subregion=False
verbose=False
if len(sys.argv) > 4:
	if '.bed' in sys.argv[4]:
		want_subregion=True
		bed_f = open(sys.argv[4])
		for line in bed_f:
			line_split = line.strip().split('\t')
			subregion = (int(line_split[1]), int(line_split[2]))
		if len(sys.argv) > 5:
			verbose=True
	else:
		verbose=True

sam_lines = []
paf_lines = []
regex_str = 'de:f:((0|\d+)\.\d+)'
for paf_line, sam_line in zip(paf_f, sam_no_header_f):
	paf_line_split = paf_line.strip().split('\t')
	sam_line_split = sam_line.strip().split('\t')
	t_start, t_end = int(paf_line_split[7]), int(paf_line_split[8])
	cigar = re.findall('cg:Z:(\w+)', paf_line)[0]
	if want_subregion:
		if overlap((t_start, t_end), subregion) >= 0.9:
			if subregion_ani((t_start, t_end), subregion, cigar) >= 0.9:
				sam_lines.append(sam_line.strip())
				paf_lines.append(paf_line.strip())
	else:
		q_len, matching_bases, aln_block = int(paf_line_split[6]), int(paf_line_split[9]), int(paf_line_split[10])
		try:
			de_flag = re.findall(regex_str, sam_line)[0][0]
			ani = 1 - float(de_flag)
		except:
			ani = 0
		if verbose:
			print(paf_line.strip())
			print(aln_block, 0.75*q_len, ani)
		if aln_block >= 0.7 * q_len and ani >= 0.8:
			if verbose:
				print('keep')
			sam_lines.append(sam_line.strip())
			paf_lines.append(paf_line.strip())
		if verbose:
			print('-----')

if output_type == 'sam':
	for line in sam_lines:
		print(line)
if output_type == 'paf':
	for line in paf_lines:
		print(line)

# intervals = []
# for i in range(len(paf_lines)):
# 	paf_line_split = paf_lines[i].split('\t')
# 	start, end = int(paf_line_split[2]), int(paf_line_split[3])
# 	overlaps = False
# 	for interval in intervals:
# 		if verbose:
# 			print((start,end), interval, overlap((start,end), interval))
# 		if overlap((start,end), interval) >= 0.75:
# 			overlaps = True
# 	intervals.append((start,end))
# 	if not overlaps:
# 		if output_type == 'sam':
# 			print(sam_lines[i].strip())
# 		elif output_type == 'paf':
# 			print(paf_lines[i].strip())
# 	if verbose:
# 		print('-----')
