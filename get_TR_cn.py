import sys
import re

def remove_overlapping_intervals(intervals):
    result = []
    current_interval = intervals[0]

    for interval in intervals[1:]:
        # Check for overlap
        if interval[0] < current_interval[1]:
            # Overlapping intervals, keep the longest one
            current_interval = max(current_interval, interval, key=lambda x: x[1] - x[0])
        else:
            # Non-overlapping intervals, add the current interval to the result
            result.append(current_interval)
            current_interval = interval

    # Add the last interval to the result
    result.append(current_interval)

    return result

paf_f = open(sys.argv[1])

min_start = -1
max_end = -1
unit_len = 1

tot_aln_block = 0
for line in paf_f:
	paf_line = line.strip().split('\t')
	start, end = float(paf_line[2]), float(paf_line[3])
	unit_len = float(paf_line[6])
	if min_start == -1:
		min_start = start
	if max_end == -1:
		max_end = end
	min_start = min(min_start, start)
	max_end = max(max_end, end)

# print(min_start, max_end)
window = max_end - min_start
est_cn = round((max_end - min_start) / unit_len)
# print(est_cn)


paf_f = open(sys.argv[1])

units = []
for line in paf_f:
	paf_line = line.strip().split('\t')
	start, end, aln_block = float(paf_line[2]), float(paf_line[3]), float(paf_line[10])
	unit_len = float(paf_line[6])
	units.append((start, end, aln_block))

if len(units) == 0:
	print(est_cn)
	print(0)
	exit()

tot_units = 0
units.sort(key=lambda x: x[0])
# print(units)
units = remove_overlapping_intervals(units)
# print(units)


for u in units:
	aln_block = u[2]
	if aln_block - unit_len > 0:
		window -= (aln_block - unit_len)

est_cn = round(window / unit_len)
# print(est_cn)

for i in range(len(units) - 1):
	# print(units[i], units[i+1])
	# print(units[i+1][0] - units[i][1])
	# print(units[i+1][0] - units[i][1] >= unit_len * 0.9)
	if units[i+1][0] - units[i][1] >= unit_len * 0.9:
		tot_units += 1
	# print(tot_units)

tot_units += len(units)

# print(est_cn)
# print(tot_units)
# print(est_cn == tot_units)

if est_cn >= 5 or tot_units >= 5:
	print(tot_units)
else:
	print(est_cn)
