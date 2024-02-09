import sys
import seaborn
import pandas as pd
import matplotlib.pyplot as plt

prefix = sys.argv[1]
doing_TR = len(sys.argv) > 2

if doing_TR:
	df = pd.read_csv(prefix + '/read_summary.txt', sep='\t', names=['group', 'read', 'num', 'meth_pct', 'TR_cn'])
else:
	df = pd.read_csv(prefix + '/read_summary.txt', sep='\t', names=['group', 'read', 'num', 'meth_pct'])
df_filtered = df[df['group'] != 'none']

if doing_TR:
	hist = dict()
	uniq_counts = sorted(df['TR_cn'].unique())
	for count in uniq_counts:
		hist[count] = len(df.loc[df['TR_cn'] == count])
	plt.bar(range(len(hist)), list(hist.values()), align='center')
	plt.xticks(range(len(hist)), list(hist.keys()))
	plt.savefig(prefix+'/TR_cn.hist.png')
	plt.close()
	meth_by_TR = dict()
	uniq_counts = sorted(df['TR_cn'].unique())
	for count in uniq_counts:
		l = df.loc[df['TR_cn'] == count]['meth_pct']
		meth_by_TR[count] = sum(l)/len(l)
	plt.bar(range(len(meth_by_TR)), list(meth_by_TR.values()), align='center')
	plt.xticks(range(len(meth_by_TR)), list(meth_by_TR.keys()))
	plt.savefig(prefix+'/meth_by_TR_cn.bar.png')
	plt.close()
	meth_plot_by_TR_cn = seaborn.violinplot(x='group', y='meth_pct', hue='TR_cn', data=df_filtered, linewidth=0.5, inner='point', cut=0)
	meth_plot_by_TR_cn.figure.savefig(prefix+'/methylation.violin.by_TR_cn.chr_breakdown.png')
	chrs_uniq = sorted(df_filtered['group'].unique())
	for chrom in chrs_uniq:
		data = df_filtered.loc[df_filtered['group'] == chrom]
		meth_plot_by_TR_cn = seaborn.violinplot(x='TR_cn', y='meth_pct', data=data, linewidth=0.5, inner='point', cut=0)
		meth_plot_by_TR_cn.figure.savefig(prefix+'/methylation.violin.by_TR_cn.' + chrom + '.png')
else:
	seaborn.set(style = 'whitegrid') 
	meth_plot_by_chr = seaborn.violinplot(x='group', y='meth_pct', data=df_filtered, linewidth=0.5, inner='point', cut=0)
	meth_plot_by_chr.figure.savefig(prefix+'/methylation.violin.by_chr.png')
