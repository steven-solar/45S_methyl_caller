import sys

prefix = sys.argv[1]
header_f = open(sys.argv[2])

header=''
for line in header_f:
    header+=line
header_f.close()

readname_to_counts=dict()
for line in sys.stdin:
    line_split = line.strip().split('\t')
    flag = int(line_split[1])
    if flag >= 2048:
        line_split[1] = str(flag-2048)
    read = line_split[0]
    if read in readname_to_counts:
        readname_to_counts[read]+=1
    else:
        readname_to_counts[read]=1
    out_f = open(prefix + '/' + read + '/' + str(readname_to_counts[read]) + '.sam', 'w')
    out_f.write(header)
    out_f.write('\t'.join(line_split))
    out_f.close()
