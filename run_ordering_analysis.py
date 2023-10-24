import sys
import random

read_summary_f = open(sys.argv[1])

read_to_units = dict()
read_to_chr = dict()
read_to_randnum = dict()
randnum_to_read = dict()

c=0

for line in read_summary_f:
    line_split = line.strip().split('\t')
    chr, readname, num, meth_pct = line_split[0], line_split[1], int(line_split[2]), float(line_split[3])
    if readname in read_to_units:
        read_to_units[readname][num] = meth_pct
    else:
        read_to_units[readname] = {num:meth_pct}
    if readname not in read_to_chr:
        read_to_chr[readname] = chr
    if readname not in read_to_randnum:
        read_to_randnum[readname] = c
        randnum_to_read[c] = readname
        c+=1

neighbor_diff_sum = 0
neighbor_count = 0
random_diff_sum = 0
random_count = 0

random_diff_diffchr_sum = 0
random_diffchr_count = 0

random_diff_samechr_sum = 0
random_samechr_count = 0

for k,v in read_to_units.items():
    for i in range(len(v) - 1):
        idx = i+1
        neighbor_diff_sum += (abs(v[idx] - v[idx+1]))
        neighbor_count += 1
    for i in range(len(v)):
        idx = i+1

        rand_read = randnum_to_read[random.randrange(c)]
        while rand_read == k:
            rand_read = randnum_to_read[random.randrange(c)]
        read_units = read_to_units[rand_read]
        rand_meth_pct = read_units[random.randint(1, len(read_units))]
        random_diff_sum += (abs(v[idx] - rand_meth_pct))
        random_count += 1

        rand_read = randnum_to_read[random.randrange(c)]
        while read_to_chr[rand_read] != read_to_chr[k]:
            rand_read = randnum_to_read[random.randrange(c)]
        read_units = read_to_units[rand_read]
        rand_meth_pct = read_units[random.randint(1, len(read_units))]
        random_diff_samechr_sum += (abs(v[idx] - rand_meth_pct))
        random_samechr_count += 1

        rand_read = randnum_to_read[random.randrange(c)]
        while read_to_chr[rand_read] == read_to_chr[k]:
            rand_read = randnum_to_read[random.randrange(c)]
        read_units = read_to_units[rand_read]
        rand_meth_pct = read_units[random.randint(1, len(read_units))]
        random_diff_diffchr_sum += (abs(v[idx] - rand_meth_pct))
        random_diffchr_count += 1


print('Avg diff adjacent units: ', neighbor_diff_sum/neighbor_count)
print('Avg diff random units: ', random_diff_sum/random_count)
print('Avg diff random units, enforce same chr: ', random_diff_samechr_sum/random_samechr_count)
print('Avg diff random units, enforce diff chr: ', random_diff_diffchr_sum/random_diffchr_count)
